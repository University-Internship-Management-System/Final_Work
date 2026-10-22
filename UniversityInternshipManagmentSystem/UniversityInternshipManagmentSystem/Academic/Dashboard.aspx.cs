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
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.Academic
{
    public partial class Dashboard : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            AuthHelper.RequireAuth(this, AuthHelper.RoleAcademic, AuthHelper.RoleCoordinator);
            if (Response.IsRequestBeingRedirected) return;

            RegisterAsyncTask(new PageAsyncTask(LoadDashboardAsync));
        }

        private async Task LoadDashboardAsync()
        {
            litAcademicName.Text = HttpUtility.HtmlEncode(AuthHelper.UserName ?? "Academic Supervisor");
            try
            {
                JObject supervisors = null;
                string supervisorId = Convert.ToString(Session["dbRecordId"] ?? Session["userId"]);
                JToken supervisor = null;

                if (!String.IsNullOrWhiteSpace(supervisorId))
                {
                    string supervisorJson = await FirebaseDb.Get("AcademicSupervisors", supervisorId);
                    if (supervisorJson != null && supervisorJson.Trim() != "null")
                        supervisor = JObject.Parse(supervisorJson);
                }

                if (supervisor == null)
                {
                    supervisors = await ReadTable("AcademicSupervisors");
                    string email = (AuthHelper.UserEmail ?? String.Empty).Trim();
                    foreach (JProperty entry in supervisors.Properties())
                    {
                        if (EmailMatches(entry.Value, email))
                        {
                            supervisorId = entry.Name;
                            supervisor = entry.Value;
                            Session["dbRecordId"] = supervisorId;
                            Session["dbTable"] = "AcademicSupervisors";
                            break;
                        }
                    }
                }

                if (supervisor == null || String.IsNullOrWhiteSpace(supervisorId))
                    throw new InvalidOperationException("We couldn't match this login to an academic supervisor record.");

                JObject students = await ReadTable("Students");
                JObject tasks = await ReadTable("Tasks");
                JObject submissions = await ReadTable("TaskSubmissions");
                JObject evaluations = await ReadTable("FinalEvaluations");
                JObject companies = await ReadTable("CompanySupervisors");

                var assignedStudents = students.Properties()
                    .Where(p => p.Value != null && String.Equals((string)p.Value["AcademicSupervisorId"], supervisorId, StringComparison.Ordinal))
                    .OrderBy(p => (string)p.Value["Name"] ?? String.Empty, StringComparer.CurrentCultureIgnoreCase)
                    .ToList();
                var assignedStudentIds = new HashSet<string>(assignedStudents.Select(p => p.Name), StringComparer.Ordinal);

                var assignedTasks = tasks.Properties()
                    .Where(task => IsAssignedToAnyStudent(task.Value, assignedStudentIds))
                    .ToList();
                var assignedTaskIds = new HashSet<string>(assignedTasks.Select(t => t.Name), StringComparer.Ordinal);
                var assignedPairs = new HashSet<string>(StringComparer.Ordinal);
                foreach (JProperty task in assignedTasks)
                {
                    JArray studentIds = task.Value["StudentIds"] as JArray;
                    if (studentIds == null) continue;
                    foreach (JToken id in studentIds)
                    {
                        string studentId = (string)id;
                        if (assignedStudentIds.Contains(studentId))
                            assignedPairs.Add(studentId + "|" + task.Name);
                    }
                }
                var latestSubmissions = GetLatestSubmissions(submissions, assignedStudentIds, assignedPairs);
                int pendingSubmissions = latestSubmissions.Count(s => String.Equals((string)s["Status"], "Submitted", StringComparison.OrdinalIgnoreCase));
                int sentEvaluations = assignedStudents.Count(student => IsSentEvaluation(evaluations[student.Name], (string)student.Value["CompanyId"]));

                litStudentCount.Text = assignedStudents.Count.ToString(CultureInfo.InvariantCulture);
                litTaskCount.Text = assignedTaskIds.Count.ToString(CultureInfo.InvariantCulture);
                litSubmissionCount.Text = pendingSubmissions.ToString(CultureInfo.InvariantCulture);
                litEvaluationCount.Text = sentEvaluations.ToString(CultureInfo.InvariantCulture);
                litStudentRows.Text = BuildStudentRows(assignedStudents, evaluations, companies);
            }
            catch (Exception ex) when (ex is HttpRequestException || ex is JsonException || ex is InvalidOperationException)
            {
                pnlError.Visible = true;
                litError.Text = HttpUtility.HtmlEncode("Could not load dashboard data from Firebase. " + ex.Message);
                litStudentRows.Text = "<tr><td colspan=\"5\" class=\"ad-muted\">Dashboard data is unavailable.</td></tr>";
                SetCountsToZero();
            }
        }

        private static async Task<JObject> ReadTable(string name)
        {
            string json = await FirebaseDb.Get(name);
            if (json == null) throw new HttpRequestException("A Firebase read was denied or failed for " + name + ".");
            if (json.Trim() == "null") return new JObject();
            return JsonConvert.DeserializeObject<JObject>(json) ?? new JObject();
        }

        private static bool EmailMatches(JToken record, string email)
        {
            if (record == null || String.IsNullOrWhiteSpace(email)) return false;
            return Matches((string)record["Email"], email) ||
                   Matches((string)record["UniversityEmail"], email) ||
                   Matches((string)record["UniEmail"], email);
        }

        private static bool Matches(string candidate, string email)
        {
            return String.Equals((candidate ?? String.Empty).Trim(), email, StringComparison.OrdinalIgnoreCase);
        }

        private static bool IsAssignedToAnyStudent(JToken task, HashSet<string> studentIds)
        {
            JArray ids = task == null ? null : task["StudentIds"] as JArray;
            return ids != null && ids.Any(id => studentIds.Contains((string)id));
        }

        private static List<JToken> GetLatestSubmissions(JObject submissions, HashSet<string> studentIds, HashSet<string> assignedPairs)
        {
            var latest = new Dictionary<string, JToken>(StringComparer.Ordinal);
            foreach (JProperty entry in submissions.Properties())
            {
                JToken submission = entry.Value;
                string studentId = (string)submission?["StudentId"];
                string taskId = (string)submission?["TaskId"];
                if (String.IsNullOrWhiteSpace(studentId) || String.IsNullOrWhiteSpace(taskId) ||
                    !studentIds.Contains(studentId)) continue;

                string key = studentId + "|" + taskId;
                if (!assignedPairs.Contains(key)) continue;
                JToken previous;
                int version = (int?)submission["Version"] ?? 0;
                int previousVersion = latest.TryGetValue(key, out previous) ? (int?)previous["Version"] ?? 0 : -1;
                string submittedAt = (string)submission["SubmittedAt"] ?? String.Empty;
                string previousSubmittedAt = previous == null ? String.Empty : (string)previous["SubmittedAt"] ?? String.Empty;
                if (previous == null || version > previousVersion ||
                    (version == previousVersion && String.CompareOrdinal(submittedAt, previousSubmittedAt) > 0))
                    latest[key] = submission;
            }
            return latest.Values.ToList();
        }

        private static bool IsSentEvaluation(JToken evaluation, string studentCompanyId)
        {
            if (evaluation == null || !String.Equals((string)evaluation["Status"], "Sent", StringComparison.OrdinalIgnoreCase)) return false;
            string evaluationCompanyId = (string)evaluation["CompanyId"];
            return String.IsNullOrWhiteSpace(evaluationCompanyId) || String.Equals(evaluationCompanyId, studentCompanyId, StringComparison.Ordinal);
        }

        private string BuildStudentRows(IEnumerable<JProperty> students, JObject evaluations, JObject companies)
        {
            var rows = new System.Text.StringBuilder();
            foreach (JProperty student in students)
            {
                string name = (string)student.Value["Name"] ?? "Name unavailable";
                string major = (string)student.Value["Major"] ?? "Not specified";
                string companyId = (string)student.Value["CompanyId"];
                JToken company = String.IsNullOrWhiteSpace(companyId) ? null : companies[companyId];
                string companyName = (string)company?["CompanyName"] ?? (string)company?["Name"] ?? "Not assigned";
                string evaluationStatus = IsSentEvaluation(evaluations[student.Name], companyId) ? "Sent for academic review" : "Not sent";
                string progressUrl = ResolveUrl("~/Academic/StudentProgress/StudentProgress.aspx") + "?student=" + HttpUtility.UrlEncode(student.Name);

                rows.Append("<tr><td><strong>").Append(HttpUtility.HtmlEncode(name)).Append("</strong></td><td>")
                    .Append(HttpUtility.HtmlEncode(major)).Append("</td><td>").Append(HttpUtility.HtmlEncode(companyName))
                    .Append("</td><td>").Append(HttpUtility.HtmlEncode(evaluationStatus)).Append("</td><td><a href=\"")
                    .Append(HttpUtility.HtmlAttributeEncode(progressUrl)).Append("\">Open progress</a></td></tr>");
            }

            if (rows.Length == 0)
                return "<tr><td colspan=\"5\" class=\"ad-muted\">No students are currently assigned to this supervisor.</td></tr>";
            return rows.ToString();
        }

        private void SetCountsToZero()
        {
            litStudentCount.Text = "0";
            litTaskCount.Text = "0";
            litSubmissionCount.Text = "0";
            litEvaluationCount.Text = "0";
        }
    }
}
