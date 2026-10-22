using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;
using UniversityInternshipManagmentSystem.Student.StudentTasksPage;
using CompanyEvaluation = UniversityInternshipManagmentSystem.Models.FinalEvaluation;

namespace UniversityInternshipManagmentSystem.Academic.FinalEvaluation
{
    public partial class AcademicFinalEvaluation : Page
    {
        private JObject _students, _tasks, _submissions, _companyEvaluations, _academicEvaluations, _companies;
        private string _academicId, _studentId, _companyId;

        protected async void Page_Load(object sender, EventArgs e)
        {
            AuthHelper.RequireAuth(this, AuthHelper.RoleAcademic);
            if (Response.IsRequestBeingRedirected) return;
            await LoadPageAsync();
        }

        private async Task LoadPageAsync()
        {
            try
            {
                await LoadDataAsync();
                string currentPage = Request.AppRelativeCurrentExecutionFilePath ?? String.Empty;
                if (currentPage.EndsWith("Trainees.aspx", StringComparison.OrdinalIgnoreCase))
                    BindStudents();
                else if (currentPage.EndsWith("EvaluateTrainee.aspx", StringComparison.OrdinalIgnoreCase))
                    BindSelectedStudent();
                else
                    BindCompanies();
            }
            catch (Exception ex) when (ex is HttpRequestException || ex is JsonException || ex is InvalidOperationException)
            {
                pnlError.Visible = true;
                litError.Text = HttpUtility.HtmlEncode("Could not load final evaluations: " + ex.Message);
            }
        }

        private async Task LoadDataAsync()
        {
            _academicId = await ResolveAcademicIdAsync();
            if (String.IsNullOrWhiteSpace(_academicId)) throw new InvalidOperationException("Your academic supervisor record could not be matched to this account.");
            _students = await ReadTable("Students");
            _tasks = await ReadTable("Tasks");
            _submissions = await ReadTable("TaskSubmissions");
            _companyEvaluations = await ReadTable("FinalEvaluations");
            _academicEvaluations = await ReadTable("AcademicEvaluations");
            _companies = await ReadTable("CompanySupervisors");
            _studentId = Request.QueryString["studentId"];
            _companyId = Request.QueryString["companyId"];
        }

        private async Task<string> ResolveAcademicIdAsync()
        {
            string id = Convert.ToString(Session["dbRecordId"] ?? Session["userId"]);
            if (!String.IsNullOrWhiteSpace(id))
            {
                string recordJson = await FirebaseDb.Get("AcademicSupervisors", id);
                if (!String.IsNullOrWhiteSpace(recordJson) && recordJson.Trim() != "null") return id;
            }

            JObject supervisors = await ReadTable("AcademicSupervisors");
            string email = (AuthHelper.UserEmail ?? String.Empty).Trim();
            foreach (JProperty entry in supervisors.Properties())
            {
                if (EmailMatches(entry.Value, email))
                {
                    Session["dbRecordId"] = entry.Name;
                    Session["dbTable"] = "AcademicSupervisors";
                    return entry.Name;
                }
            }
            return null;
        }

        private static bool EmailMatches(JToken item, string email)
        {
            return !String.IsNullOrWhiteSpace(email) && item != null &&
                (String.Equals(((string)item["Email"])?.Trim(), email, StringComparison.OrdinalIgnoreCase) ||
                 String.Equals(((string)item["UniversityEmail"])?.Trim(), email, StringComparison.OrdinalIgnoreCase) ||
                 String.Equals(((string)item["UniEmail"])?.Trim(), email, StringComparison.OrdinalIgnoreCase));
        }

        private static async Task<JObject> ReadTable(string name)
        {
            string json = await FirebaseDb.Get(name);
            if (json == null) throw new HttpRequestException("Firebase read failed for " + name + ".");
            if (json.Trim() == "null") return new JObject();
            return JsonConvert.DeserializeObject<JObject>(json) ?? new JObject();
        }

        private List<JProperty> EligibleStudents()
        {
            return _students.Properties().Where(student =>
                String.Equals((string)student.Value["AcademicSupervisorId"], _academicId, StringComparison.Ordinal) &&
                IsCompanyPassed(_companyEvaluations[student.Name], (string)student.Value["CompanyId"]))
                .OrderBy(student => (string)student.Value["Name"] ?? String.Empty, StringComparer.CurrentCultureIgnoreCase).ToList();
        }

        private static bool IsCompanyPassed(JToken evaluation, string companyId)
        {
            if (evaluation == null) return false;
            string storedCompany = (string)evaluation["CompanyId"];
            bool passed = (bool?)evaluation["IsPassCompany"] == true || String.Equals((string)evaluation["Status"], CompanyEvaluation.Sent, StringComparison.OrdinalIgnoreCase);
            return passed && (String.IsNullOrWhiteSpace(storedCompany) || String.Equals(storedCompany, companyId, StringComparison.Ordinal));
        }

        private void BindCompanies()
        {
            var groups = EligibleStudents().GroupBy(student => (string)student.Value["CompanyId"] ?? String.Empty)
                .Select(group => new { Id = group.Key, Name = CompanyName(group.Key), Count = group.Count() })
                .OrderBy(group => group.Name, StringComparer.CurrentCultureIgnoreCase).ToList();
            if (groups.Count == 0)
            {
                litCompanyRows.Text = "<tr><td colspan=\"3\" class=\"text-muted\">No company-approved students are waiting for academic review.</td></tr>";
                return;
            }
            var html = new System.Text.StringBuilder();
            foreach (var group in groups)
            {
                string url = ResolveUrl("~/Academic/FinalEvaluation/Trainees.aspx") + "?companyId=" + HttpUtility.UrlEncode(group.Id);
                html.Append("<tr><td>").Append(Encode(group.Name)).Append("</td><td>").Append(group.Count.ToString(CultureInfo.InvariantCulture))
                    .Append("</td><td><a href=\"").Append(HttpUtility.HtmlAttributeEncode(url)).Append("\">View students</a></td></tr>");
            }
            litCompanyRows.Text = html.ToString();
        }

        private void BindStudents()
        {
            if (String.IsNullOrWhiteSpace(_companyId)) return;
            var eligible = EligibleStudents().Where(student => String.Equals((string)student.Value["CompanyId"], _companyId, StringComparison.Ordinal)).ToList();
            pnlStudents.Visible = true;
            if (eligible.Count == 0)
            {
                litStudentRows.Text = "<tr><td colspan=\"5\" class=\"text-muted\">No eligible students found for this company.</td></tr>";
                return;
            }
            var html = new System.Text.StringBuilder();
            foreach (JProperty student in eligible)
            {
                string state = AcademicStatus(_academicEvaluations[student.Name]);
                string url = ResolveUrl("~/Academic/FinalEvaluation/EvaluateTrainee.aspx") + "?companyId=" + HttpUtility.UrlEncode(_companyId) + "&studentId=" + HttpUtility.UrlEncode(student.Name);
                html.Append("<tr><td>").Append(Encode((string)student.Value["Name"])).Append("</td><td>").Append(Encode((string)student.Value["Major"]))
                    .Append("</td><td>Pass</td><td>").Append(Encode(state)).Append("</td><td><a href=\"").Append(HttpUtility.HtmlAttributeEncode(url)).Append("\">Review</a></td></tr>");
            }
            litStudentRows.Text = html.ToString();
        }

        private void BindSelectedStudent()
        {
            if (String.IsNullOrWhiteSpace(_studentId)) return;
            JToken student = _students[_studentId];
            JToken companyEvaluation = _companyEvaluations[_studentId];
            if (student == null || !EligibleStudents().Any(p => p.Name == _studentId) || !String.Equals((string)student["CompanyId"], _companyId, StringComparison.Ordinal))
                throw new InvalidOperationException("This student is not assigned to you with a company-approved final evaluation.");

            pnlReview.Visible = true;
            litStudentName.Text = Encode((string)student["Name"] ?? "Student");
            litStudentInfo.Text = Encode((string)student["Major"] ?? "") + " · " + Encode((string)student["UniEmail"] ?? (string)student["Email"] ?? "");
            litHours.Text = Encode(((int?)companyEvaluation["TotalHours"] ?? 0).ToString(CultureInfo.InvariantCulture));
            litDates.Text = Encode(FormatDate((string)companyEvaluation["StartDate"]) + " – " + FormatDate((string)companyEvaluation["EndDate"]));
            litCompanyRatings.Text = BuildRatings(companyEvaluation["Ratings"] as JObject);
            litCompanyComments.Text = Encode((string)companyEvaluation["Comments"] ?? "No company comment.");

            JToken academicEvaluation = _academicEvaluations[_studentId];
            bool locked = String.Equals((string)academicEvaluation?["Status"], AcademicEvaluation.Sent, StringComparison.OrdinalIgnoreCase);
            lblAcademicStatus.Text = AcademicStatus(academicEvaluation);
            txtFinalComment.Text = (string)academicEvaluation?["Comments"] ?? String.Empty;
            txtFinalComment.Enabled = !locked;
            btnSaveDraft.Visible = !locked;
            btnPassToCoordinator.Visible = !locked;

            BindTasks(_studentId, locked);
        }

        private void BindTasks(string studentId, bool locked)
        {
            var rows = _tasks.Properties().Where(p => HasStudent(p.Value, studentId))
                .OrderBy(p => (int?)p.Value["WeekNumber"] ?? 0)
                .ThenBy(p => (string)p.Value["TaskName"], StringComparer.CurrentCultureIgnoreCase)
                .Select(task =>
                {
                    JProperty latest = LatestSubmission(task.Name, studentId);
                    string link = latest == null ? "#" : (string)latest.Value["Link"] ?? "#";
                    return new
                    {
                        WeekNumber = (int?)task.Value["WeekNumber"] ?? 0,
                        TaskName = (string)task.Value["TaskName"] ?? "Task",
                        Deadline = FormatDate((string)task.Value["DeadLine"]),
                        SubmissionStatus = latest == null ? "Not submitted" : (string)latest.Value["Status"] ?? "Submitted",
                        SubmissionLink = SafeSubmissionUrl(link),
                        CompanyFeedbackHistory = FeedbackHistory(task.Name, studentId, "Feedback", "No company response yet"),
                        AcademicFeedback = latest == null ? String.Empty : (string)latest.Value["AcademicFeedback"] ?? String.Empty,
                        AcademicFeedbackHistory = FeedbackHistory(task.Name, studentId, "AcademicFeedback", "No academic comments saved yet"),
                        SubmissionId = latest == null ? String.Empty : latest.Name,
                        HasSubmission = latest != null,
                        CanComment = latest != null && !locked
                    };
                }).ToList();

            var weeks = Enumerable.Range(1, TaskLogic.WeeksCount).Select(week =>
            {
                var weekTasks = rows.Where(task => task.WeekNumber == week).ToList();
                return new
                {
                    WeekNumber = week,
                    TaskCount = weekTasks.Count,
                    HasTasks = weekTasks.Count > 0,
                    Tasks = weekTasks
                };
            }).ToList();
            rptTaskWeeks.DataSource = weeks;
            rptTaskWeeks.DataBind();
        }

        protected void rptTaskWeeks_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem) return;
            Repeater taskRepeater = (Repeater)e.Item.FindControl("rptWeekTasks");
            taskRepeater.DataSource = DataBinder.Eval(e.Item.DataItem, "Tasks");
            taskRepeater.DataBind();
        }

        private string FeedbackHistory(string taskId, string studentId, string field, string emptyText)
        {
            var replies = _submissions.Properties()
                .Where(sub => String.Equals((string)sub.Value["TaskId"], taskId, StringComparison.Ordinal)
                    && String.Equals((string)sub.Value["StudentId"], studentId, StringComparison.Ordinal)
                    && !String.IsNullOrWhiteSpace((string)sub.Value[field]))
                .OrderBy(sub => (int?)sub.Value["Version"] ?? 0)
                .Select(sub => "Submission v" + ((int?)sub.Value["Version"] ?? 1).ToString(CultureInfo.InvariantCulture)
                    + " · " + FormatDate((string)sub.Value["SubmittedAt"]) + "\n" + ((string)sub.Value[field]).Trim())
                .ToList();
            return replies.Count == 0 ? emptyText : String.Join("\n\n", replies);
        }
        private static bool HasStudent(JToken task, string studentId)
        {
            JArray ids = task == null ? null : task["StudentIds"] as JArray;
            return ids != null && ids.Any(id => String.Equals((string)id, studentId, StringComparison.Ordinal));
        }

        private JProperty LatestSubmission(string taskId, string studentId)
        {
            return _submissions.Properties().Where(sub => String.Equals((string)sub.Value["TaskId"], taskId, StringComparison.Ordinal) && String.Equals((string)sub.Value["StudentId"], studentId, StringComparison.Ordinal))
                .OrderByDescending(sub => (int?)sub.Value["Version"] ?? 0).ThenByDescending(sub => (string)sub.Value["SubmittedAt"] ?? String.Empty).FirstOrDefault();
        }

        protected async void rptTasks_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName != "SaveAcademicFeedback") return;
            TextBox feedbackBox = (TextBox)e.Item.FindControl("txtAcademicFeedback");
            string feedback = (Request.Form[feedbackBox.UniqueID] ?? feedbackBox.Text).Trim();
            try
            {
                await LoadDataAsync();
                if (String.IsNullOrWhiteSpace(_studentId) || !EligibleStudents().Any(p => p.Name == _studentId)) throw new InvalidOperationException("The student is no longer eligible for academic review.");
                string submissionId = Convert.ToString(e.CommandArgument);
                bool isLatest = _tasks.Properties().Where(p => HasStudent(p.Value, _studentId)).Any(task => LatestSubmission(task.Name, _studentId)?.Name == submissionId);
                if (!isLatest) throw new InvalidOperationException("That submission is no longer the latest version. Reload the page and try again.");
                if (String.Equals((string)_academicEvaluations[_studentId]?["Status"], AcademicEvaluation.Sent, StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("This academic evaluation has already been sent and is locked.");
                bool saved = await TaskDb.SaveAcademicFeedback(submissionId, feedback, _academicId);
                ShowMessage(saved ? "Academic task feedback saved." : "Could not save the task feedback. Check Firebase rules and try again.", !saved);
                await LoadPageAsync();
            }
            catch (Exception ex) when (ex is HttpRequestException || ex is JsonException || ex is InvalidOperationException)
            {
                ShowMessage(ex.Message, true);
                await LoadPageAsync();
            }
        }

        protected async void btnSaveDraft_Click(object sender, EventArgs e) { await SaveAcademicEvaluationAsync(false); }
        protected async void btnPassToCoordinator_Click(object sender, EventArgs e) { await SaveAcademicEvaluationAsync(true); }

        private async Task SaveAcademicEvaluationAsync(bool send)
        {
            string comments = (Request.Form[txtFinalComment.UniqueID] ?? txtFinalComment.Text).Trim();
            try
            {
                await LoadDataAsync();
                JToken student = _students[_studentId];
                if (student == null || !EligibleStudents().Any(p => p.Name == _studentId)) throw new InvalidOperationException("The student is no longer eligible for academic review.");
                JToken previous = _academicEvaluations[_studentId];
                if (String.Equals((string)previous?["Status"], AcademicEvaluation.Sent, StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("This academic evaluation has already been sent and is locked.");
                if (send && String.IsNullOrWhiteSpace(comments)) throw new InvalidOperationException("Add a final academic comment before passing the student.");

                var evaluation = new AcademicEvaluation
                {
                    StudentId = _studentId,
                    AcademicSupervisorId = _academicId,
                    CompanyId = (string)student["CompanyId"],
                    Comments = comments,
                    IsPassAcademic = send,
                    Status = send ? AcademicEvaluation.Sent : AcademicEvaluation.Draft,
                    UpdatedAt = DateTime.UtcNow,
                    SentAt = send ? (DateTime?)DateTime.UtcNow : null
                };
                HttpResponseMessage response = await FirebaseDb.Put("AcademicEvaluations", _studentId, evaluation);
                if (!response.IsSuccessStatusCode) throw new HttpRequestException("Firebase refused to save the academic evaluation.");
                ShowMessage(send ? "Academic evaluation passed and sent to the coordinator." : "Academic evaluation draft saved.", false);
                await LoadPageAsync();
            }
            catch (Exception ex) when (ex is HttpRequestException || ex is JsonException || ex is InvalidOperationException)
            {
                ShowMessage(ex.Message, true);
                await LoadPageAsync();
            }
        }

        private string CompanyName(string id)
        {
            if (String.IsNullOrWhiteSpace(id)) return "Company not specified";
            JToken company = _companies[id];
            return (string)company?["CompanyName"] ?? (string)company?["Name"] ?? id;
        }

        private static string SafeSubmissionUrl(string value)
        {
            Uri uri;
            return Uri.TryCreate(value, UriKind.Absolute, out uri) &&
                   (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps) ? uri.ToString() : "#";
        }
        private static string AcademicStatus(JToken evaluation)
        {
            if (evaluation == null) return "Not started";
            return String.Equals((string)evaluation["Status"], AcademicEvaluation.Sent, StringComparison.OrdinalIgnoreCase) ? "Sent to coordinator" : "Draft";
        }

        private static string BuildRatings(JObject ratings)
        {
            if (ratings == null || !ratings.Properties().Any()) return "No ratings";
            var items = ratings.Properties().Select(p => Encode(p.Name) + ": " + Encode(p.Value.ToString()));
            return String.Join(" · ", items);
        }

        private static string FormatDate(string value)
        {
            DateTime date;
            return DateTime.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.None, out date) ? date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) : value ?? "—";
        }

        private static string Encode(string value) { return HttpUtility.HtmlEncode(String.IsNullOrWhiteSpace(value) ? "—" : value); }

        private void ShowMessage(string message, bool error)
        {
            pnlMessage.Visible = true;
            pnlMessage.CssClass = error ? "alert alert-danger" : "alert alert-success";
            litMessage.Text = HttpUtility.HtmlEncode(message);
        }
    }
}






