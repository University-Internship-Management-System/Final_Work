using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.Academic.StudentProgress
{
    public partial class StudentProgress : Page
    {
        private const int RequiredTrainingHours = 90;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            RegisterAsyncTask(new PageAsyncTask(LoadProgressAsync));
        }
        private async Task LoadProgressAsync()
        {
            try
            {
                string supervisorId = Convert.ToString(Session["dbRecordId"] ?? Session["userId"]);
                if (String.IsNullOrWhiteSpace(supervisorId)) throw new InvalidOperationException();
                JObject supervisors = await ReadTable("AcademicSupervisors");
                JObject students = await ReadTable("Students");
                JObject companies = await ReadTable("CompanySupervisors");
                JObject tasks = await ReadTable("Tasks");
                JObject submissions = await ReadTable("TaskSubmissions");
                JObject evaluations = await ReadTable("FinalEvaluations");
                JObject academicEvaluations = await ReadTable("AcademicEvaluations");

                JToken supervisor = ResolveSupervisor(supervisors, ref supervisorId);
                string supervisorMajor = supervisor == null ? null : (string)supervisor["Major"];
                if (String.IsNullOrWhiteSpace(supervisorMajor))
                {
                    ShowMessage("The academic supervisor's major is not available.");
                    return;
                }
                supervisorMajor = supervisorMajor.Trim();

                var assignedStudents = new List<JProperty>();
                foreach (JProperty student in students.Properties())
                {
                    string studentMajor = (string)student.Value["Major"];
                    if (studentMajor == null) continue;
                    // لا يظهر الطالب إلا إذا كان معيناً لهذا المشرف وكان تخصصه مطابقاً لتخصص المشرف.
                    if ((string)student.Value["AcademicSupervisorId"] == supervisorId &&
                        String.Equals(studentMajor.Trim(), supervisorMajor, StringComparison.OrdinalIgnoreCase))
                        assignedStudents.Add(student);
                }
                assignedStudents.Sort((a, b) => String.Compare((string)a.Value["Name"], (string)b.Value["Name"], StringComparison.CurrentCultureIgnoreCase));
                if (assignedStudents.Count == 0)
                {
                    ShowMessage("No students with your major are currently assigned to this academic supervisor account.");
                    return;
                }

                string requestedId = Request.QueryString["student"];
                JProperty selected = assignedStudents[0];
                foreach (JProperty student in assignedStudents)
                {
                    if (student.Name == requestedId) selected = student;
                }
                hidSelectedStudent.Value = selected.Name;
                JToken record = selected.Value;
                string companyId = (string)record["CompanyId"];
                JToken company = null;
                if (!String.IsNullOrWhiteSpace(companyId)) company = companies[companyId];

                JToken evaluation = evaluations[selected.Name];
                if (evaluation != null && (string)evaluation["CompanyId"] != companyId) evaluation = null;
                int approvedHours = 0;
                JObject approvedWeeks = null;
                if (evaluation != null) approvedWeeks = evaluation["ApprovedWeeks"] as JObject;
                if (approvedWeeks != null)
                {
                    // الساعات المعتمدة تأتي من الأسابيع التي وقّعها مشرف الشركة.
                    foreach (JProperty week in approvedWeeks.Properties())
                    {
                        int hours;
                        if (Int32.TryParse((string)week.Value, NumberStyles.Integer, CultureInfo.InvariantCulture, out hours) && hours > 0)
                            approvedHours += hours;
                    }
                }

                var latestSubmissions = new Dictionary<string, JToken>();
                foreach (JProperty entry in submissions.Properties())
                {
                    JToken submission = entry.Value;
                    if (submission == null || (string)submission["StudentId"] != selected.Name) continue;
                    string taskId = (string)submission["TaskId"];
                    if (String.IsNullOrEmpty(taskId)) continue;
                    JToken previous;
                    if (!latestSubmissions.TryGetValue(taskId, out previous) ||
                        (int?)submission["Version"] > (int?)previous["Version"] ||
                        ((int?)submission["Version"] == (int?)previous["Version"] &&
                         String.Compare((string)submission["SubmittedAt"], (string)previous["SubmittedAt"], StringComparison.Ordinal) > 0))
                        latestSubmissions[taskId] = submission;
                }

                var studentTasks = new List<JProperty>();
                foreach (JProperty task in tasks.Properties())
                {
                    if (task.Value == null || task.Value.Type == JTokenType.Null) continue;
                    // المهمة المغلقة تبقى ظاهرة إذا كان للطالب تسليم سابق فيها.
                    if (String.Equals((string)task.Value["Status"], "Closed", StringComparison.OrdinalIgnoreCase) &&
                        !latestSubmissions.ContainsKey(task.Name)) continue;
                    JArray ids = task.Value["StudentIds"] as JArray;
                    if (ids == null) continue;
                    foreach (JToken id in ids)
                    {
                        if ((string)id != selected.Name) continue;
                        studentTasks.Add(task);
                        break;
                    }
                }
                studentTasks.Sort((a, b) => String.Compare((string)a.Value["DeadLine"], (string)b.Value["DeadLine"], StringComparison.Ordinal));

                int submittedTasks = 0;
                int assignedHours = 0;
                int evaluatedHours = 0;
                var taskData = new List<object>();
                foreach (JProperty task in studentTasks)
                {
                    int hours = TaskHours(task.Value, selected.Name);
                    assignedHours += hours;
                    JToken submission = null;
                    latestSubmissions.TryGetValue(task.Name, out submission);
                    string status = submission == null ? null : (string)submission["Status"];
                    if (String.Equals(status, "Submitted", StringComparison.OrdinalIgnoreCase) ||
                        String.Equals(status, "Evaluated", StringComparison.OrdinalIgnoreCase)) submittedTasks++;
                    if (String.Equals(status, "Evaluated", StringComparison.OrdinalIgnoreCase)) evaluatedHours += hours;
                    taskData.Add(new
                    {
                        Name = (string)task.Value["TaskName"],
                        Hours = hours,
                        Deadline = (string)task.Value["DeadLine"],
                        Status = status,
                        Score = submission == null ? null : (string)submission["Score"],
                        MaxScore = (string)task.Value["MaxScore"],
                        Feedback = submission == null ? null : (string)submission["Feedback"],
                        SubmissionId = submission == null ? null : latestSubmissions[task.Name].Parent is JProperty
                            ? ((JProperty)latestSubmissions[task.Name].Parent).Name : null,
                        AcademicFeedback = submission == null ? null : (string)submission["AcademicFeedback"]
                    });
                }

                var studentsForPicker = new List<object>();
                foreach (JProperty student in assignedStudents)
                    studentsForPicker.Add(new { Id = student.Name, Name = (string)student.Value["Name"], Major = (string)student.Value["Major"] });
                string companyStatus = "Not started";
                if (evaluation != null) companyStatus = "In progress at company";
                if (evaluation != null && String.Equals((string)evaluation["Status"], "Sent", StringComparison.OrdinalIgnoreCase))
                    companyStatus = "Sent to academic supervisor";
                litProgressData.Text = JsonConvert.SerializeObject(new
                {
                    Students = studentsForPicker,
                    SelectedId = selected.Name,
                    Name = (string)record["Name"],
                    UniversityEmail = (string)record["UniEmail"],
                    Major = (string)record["Major"],
                    Phone = (string)record["PhoneNumber"],
                    CompanyName = company == null ? null : (string)company["CompanyName"],
                    SupervisorName = company == null ? null : (string)company["Name"],
                    SupervisorPhone = company == null ? null : (string)company["PhoneNumber"],
                    ApprovedHours = approvedHours,
                    AssignedHours = assignedHours,
                    EvaluatedHours = evaluatedHours,
                    RequiredHours = RequiredTrainingHours,
                    SubmittedTasks = submittedTasks,
                    Tasks = taskData,
                    FeedbackLocked = String.Equals((string)academicEvaluations[selected.Name]?["Status"], "Sent", StringComparison.OrdinalIgnoreCase),
                    CompanyStatus = companyStatus
                }, new JsonSerializerSettings { StringEscapeHandling = StringEscapeHandling.EscapeHtml });

                string noteJson = await FirebaseDb.Get("AcademicStudentNotes", selected.Name);
                if (noteJson == null)
                {
                    litNoteUpdated.Text = "Notes could not be loaded from Firebase.";
                    btnSaveNote.Enabled = false;
                }
                else
                {
                    JObject notes = JsonConvert.DeserializeObject<JObject>(noteJson) ?? new JObject();
                    JToken note = notes[supervisorId];
                    if (!IsPostBack) txtAcademicNote.Text = note == null ? "" : (string)note["Text"];
                    litNoteUpdated.Text = note == null ? "No academic note saved for this student yet." : NoteUpdatedText((string)note["UpdatedAt"]);
                }
            }
            catch (Exception ex) when (ex is HttpRequestException || ex is JsonException || ex is InvalidOperationException)
            {
                ShowMessage("Could not load progress data from Firebase. Check the connection and permissions, then try again.");
            }
        }

        private void ShowMessage(string message)
        {
            pnlStudent.Visible = false;
            lblMessage.Text = message;
            lblMessage.Visible = true;
        }

        private static async Task<JObject> ReadTable(string name)
        {
            string json = await FirebaseDb.Get(name);
            if (json == null) throw new HttpRequestException();
            JObject table = JsonConvert.DeserializeObject<JObject>(json);
            if (table == null) table = new JObject();
            return table;
        }

        private static JToken ResolveSupervisor(JObject supervisors, ref string supervisorId)
        {
            JToken supervisor = supervisors[supervisorId];
            if (supervisor != null || String.IsNullOrWhiteSpace(AuthHelper.UserEmail)) return supervisor;
            // عند غياب رقم السجل في الجلسة نبحث عن المشرف باستخدام بريده.
            foreach (JProperty entry in supervisors.Properties())
            {
                string email = (string)entry.Value["Email"];
                string universityEmail = (string)entry.Value["UniversityEmail"];
                if (!String.Equals(email?.Trim(), AuthHelper.UserEmail.Trim(), StringComparison.OrdinalIgnoreCase) &&
                    !String.Equals(universityEmail?.Trim(), AuthHelper.UserEmail.Trim(), StringComparison.OrdinalIgnoreCase)) continue;
                supervisorId = entry.Name;
                return entry.Value;
            }
            return null;
        }

        protected async void btnSaveNote_Click(object sender, EventArgs e)
        {
            if (!AuthHelper.IsAuthenticated || AuthHelper.UserRole != AuthHelper.RoleAcademic)
            {
                lblNoteStatus.Text = "Only an academic supervisor can save notes.";
                return;
            }
            string studentId = hidSelectedStudent.Value;
            string noteText = (txtAcademicNote.Text ?? "").Trim();
            if (String.IsNullOrWhiteSpace(studentId) || noteText.Length == 0 || noteText.Length > 2000)
            {
                lblNoteStatus.Text = "Enter a note of up to 2,000 characters.";
                return;
            }
            try
            {
                string supervisorId = Convert.ToString(Session["dbRecordId"] ?? Session["userId"]);
                JObject supervisors = await ReadTable("AcademicSupervisors");
                JToken supervisor = ResolveSupervisor(supervisors, ref supervisorId);
                JObject students = await ReadTable("Students");
                JToken student = students[studentId];
                string supervisorMajor = ((string)supervisor?["Major"])?.Trim();
                string studentMajor = ((string)student?["Major"])?.Trim();
                // نتحقق مرة ثانية وقت الحفظ حتى لا تُكتب ملاحظة لطالب خارج قائمة المشرف.
                if (student == null || String.IsNullOrWhiteSpace(supervisorMajor) ||
                    !String.Equals((string)student["AcademicSupervisorId"], supervisorId, StringComparison.Ordinal) ||
                    !String.Equals(studentMajor, supervisorMajor, StringComparison.OrdinalIgnoreCase))
                {
                    lblNoteStatus.Text = "You cannot save a note for this student.";
                    return;
                }
                string updatedAt = DateTimeOffset.UtcNow.ToString("o", CultureInfo.InvariantCulture);
                using (HttpResponseMessage response = await FirebaseDb.Put("AcademicStudentNotes/" + studentId, supervisorId,
                    new { StudentId = studentId, SupervisorId = supervisorId, Text = noteText, UpdatedAt = updatedAt }))
                {
                    if (!response.IsSuccessStatusCode)
                    {
                        lblNoteStatus.Text = "The note could not be saved. Check Firebase write permissions.";
                        return;
                    }
                }
                lblNoteStatus.Text = "Note saved.";
                litNoteUpdated.Text = NoteUpdatedText(updatedAt);
            }
            catch (Exception ex) when (ex is HttpRequestException || ex is JsonException || ex is InvalidOperationException)
            {
                lblNoteStatus.Text = "The note could not be saved. Try again.";
            }
        }

        protected async void btnSaveTaskFeedback_Click(object sender, EventArgs e)
        {
            if (!AuthHelper.IsAuthenticated || AuthHelper.UserRole != AuthHelper.RoleAcademic)
            {
                lblTaskFeedbackStatus.Text = "Only an academic supervisor can save feedback.";
                return;
            }

            string studentId = hidSelectedStudent.Value;
            string submissionId = hidSubmissionId.Value;
            string feedback = (txtTaskFeedback.Text ?? "").Trim();
            if (String.IsNullOrWhiteSpace(studentId) || String.IsNullOrWhiteSpace(submissionId) || feedback.Length > 2000)
            {
                lblTaskFeedbackStatus.Text = "Select a task and enter feedback of up to 2,000 characters.";
                return;
            }

            try
            {
                string supervisorId = Convert.ToString(Session["dbRecordId"] ?? Session["userId"]);
                JObject supervisors = await ReadTable("AcademicSupervisors");
                JToken supervisor = ResolveSupervisor(supervisors, ref supervisorId);
                JObject students = await ReadTable("Students");
                JToken student = students[studentId];
                string supervisorMajor = ((string)supervisor?["Major"])?.Trim();
                string studentMajor = ((string)student?["Major"])?.Trim();
                if (student == null || String.IsNullOrWhiteSpace(supervisorMajor) ||
                    !String.Equals((string)student["AcademicSupervisorId"], supervisorId, StringComparison.Ordinal) ||
                    !String.Equals(studentMajor, supervisorMajor, StringComparison.OrdinalIgnoreCase))
                    throw new InvalidOperationException("You cannot save feedback for this student.");

                JObject academicEvaluations = await ReadTable("AcademicEvaluations");
                if (String.Equals((string)academicEvaluations[studentId]?["Status"], "Sent", StringComparison.OrdinalIgnoreCase))
                    throw new InvalidOperationException("This academic evaluation has already been sent and is locked.");

                JObject submissions = await ReadTable("TaskSubmissions");
                JToken submission = submissions[submissionId];
                string taskId = (string)submission?["TaskId"];
                JObject tasks = await ReadTable("Tasks");
                JArray studentIds = taskId == null ? null : tasks[taskId]?["StudentIds"] as JArray;
                bool assigned = false;
                if (studentIds != null)
                    foreach (JToken id in studentIds)
                        if (String.Equals((string)id, studentId, StringComparison.Ordinal)) { assigned = true; break; }
                if (submission == null || (string)submission["StudentId"] != studentId || !assigned)
                    throw new InvalidOperationException("This task submission is not available for this student.");

                foreach (JProperty entry in submissions.Properties())
                {
                    if (entry.Name == submissionId || (string)entry.Value["StudentId"] != studentId ||
                        (string)entry.Value["TaskId"] != taskId) continue;
                    int version = (int?)entry.Value["Version"] ?? 0;
                    int selectedVersion = (int?)submission["Version"] ?? 0;
                    if (version > selectedVersion || (version == selectedVersion &&
                        String.Compare((string)entry.Value["SubmittedAt"], (string)submission["SubmittedAt"], StringComparison.Ordinal) > 0))
                        throw new InvalidOperationException("A newer submission is available. Reload the page and try again.");
                }

                bool saved;
                using (HttpResponseMessage response = await FirebaseDb.Patch("TaskSubmissions", submissionId,
                    new { AcademicFeedback = feedback, AcademicFeedbackAt = DateTime.UtcNow, AcademicFeedbackBy = supervisorId }))
                    saved = response.IsSuccessStatusCode;
                lblTaskFeedbackStatus.Text = saved ? "Academic task feedback saved." : "Could not save task feedback. Check Firebase permissions and try again.";
                if (saved) await LoadProgressAsync();
            }
            catch (Exception ex) when (ex is HttpRequestException || ex is JsonException || ex is InvalidOperationException)
            {
                lblTaskFeedbackStatus.Text = ex is InvalidOperationException ? ex.Message : "Could not save task feedback. Try again.";
            }
        }

        private static string NoteUpdatedText(string value)
        {
            DateTimeOffset updated;
            if (!DateTimeOffset.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.None, out updated))
                return "Note saved in Firebase.";
            return "Last saved: " + updated.UtcDateTime.ToString("yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture) + " UTC";
        }

        private static int TaskHours(JToken task, string studentId)
        {
            JObject studentHours = task["StudentHours"] as JObject;
            JToken value = null;
            if (studentHours != null) value = studentHours[studentId];
            if (value == null) value = task["Hours"];
            int hours;
            if (!Int32.TryParse((string)value, NumberStyles.Integer, CultureInfo.InvariantCulture, out hours)) return 0;
            return Math.Max(0, hours);
        }
    }
}
