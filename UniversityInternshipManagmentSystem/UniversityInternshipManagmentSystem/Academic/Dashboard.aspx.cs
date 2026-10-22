using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;
using StudentModel = UniversityInternshipManagmentSystem.Models.Student;
using ApplicationModel = UniversityInternshipManagmentSystem.Models.Application;

namespace UniversityInternshipManagmentSystem.Academic
{
    public partial class Dashboard : Page
    {
        protected Panel workspace, noticePanel, emptyPanel;
        protected Literal notice, supervisorMajor, totalCount, confirmedCount, waitingCount;
        protected TextBox studentSearch;
        protected Repeater students;
        private Dictionary<string, StudentModel> assigned;
        private Dictionary<string, ApplicationModel> confirmed;
        private Dictionary<string, CompanySupervisor> companies;
        private AcademicSupervisor supervisor;

        protected void Page_Init(object sender, EventArgs e)
        {
            ViewStateUserKey = Session.SessionID;
        }

        protected async void Page_Load(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }
            AuthHelper.RequireAuth(this, AuthHelper.RoleAcademic);
            if (Response.IsRequestBeingRedirected) return;
            if (String.IsNullOrWhiteSpace(AuthHelper.IdToken) || AuthHelper.IdToken == "mock-token")
            {
                ShowError("Sign in with a real academic supervisor account to view your students.");
                return;
            }
            try
            {
                var supervisors = await ReadTable<AcademicSupervisor>("AcademicSupervisors");
                string supervisorId = AuthHelper.UserId;
                if (!supervisors.TryGetValue(supervisorId, out supervisor))
                {
                    var matches = supervisors.Where(item => String.Equals(item.Value.Email, AuthHelper.UserEmail,
                        StringComparison.OrdinalIgnoreCase) && !String.IsNullOrWhiteSpace(AuthHelper.UserEmail)).ToList();
                    if (matches.Count != 1)
                    {
                        ShowError("Your academic supervisor profile could not be identified. Contact the coordinator.");
                        return;
                    }
                    supervisorId = matches[0].Key;
                    supervisor = matches[0].Value;
                }
                var allStudents = await ReadTable<StudentModel>("Students");
                assigned = allStudents.Where(item => item.Value.AcademicSupervisorId == supervisorId && SameMajor(item.Value.Major))
                    .ToDictionary(item => item.Key, item => item.Value);
                var applications = await ReadTable<ApplicationModel>("Applications");
                confirmed = applications.Values.Where(item => assigned.ContainsKey(item.StudentId ?? "")
                    && item.Status == ApplicationStatus.Confirmed).GroupBy(item => item.StudentId)
                    .ToDictionary(group => group.Key, group => group.OrderByDescending(item => item.ConfirmedAt).First());
                companies = await ReadTable<CompanySupervisor>("CompanySupervisors");
                litAcademicName.Text = Server.HtmlEncode(supervisor.Name);
                supervisorMajor.Text = supervisor.Major;
                totalCount.Text = assigned.Count.ToString();
                confirmedCount.Text = confirmed.Count.ToString();
                waitingCount.Text = (assigned.Count - confirmed.Count).ToString();
                // Trigger C# search after typing pauses, without reloading the page.
                studentSearch.Attributes["oninput"] = "clearTimeout(window.adSearchTimer);window.adSearchTimer=setTimeout(function(){__doPostBack(\""
                    + studentSearch.UniqueID + "\",\"\");},300);";
                workspace.Visible = true;
                BindStudents();
            }
            catch
            {
                ShowError("Could not load the dashboard. Check your connection or sign in again.");
            }
        }

        private async Task<Dictionary<string, T>> ReadTable<T>(string table)
        {
            string json = await FirebaseDb.Get(table);
            if (json == null) throw new HttpRequestException();
            return JsonConvert.DeserializeObject<Dictionary<string, T>>(json) ?? new Dictionary<string, T>();
        }

        private bool SameMajor(string major)
        {
            return String.Equals((major ?? "").Trim(), (supervisor.Major ?? "").Trim(), StringComparison.OrdinalIgnoreCase);
        }

        private void BindStudents()
        {
            string query = studentSearch.Text.Trim();
            var rows = assigned.OrderBy(item => item.Value.Name).Select(item =>
            {
                ApplicationModel placement;
                confirmed.TryGetValue(item.Key, out placement);
                CompanySupervisor company = null;
                if (placement != null) companies.TryGetValue(placement.CompanyId ?? "", out company);
                return new
                {
                    item.Value.Name, item.Value.UniEmail, item.Value.Major,
                    Company = placement == null ? "Not confirmed" : company != null ? company.CompanyName : placement.CompanyName,
                    Opportunity = placement == null ? "" : placement.OpportunityTitle,
                    ProgressUrl = ResolveUrl("~/Academic/StudentProgress/StudentProgress.aspx")
                        + "?studentId=" + Server.UrlEncode(item.Key)
                };
            }).Where(item => (query == "" || ((item.Name ?? "") + " " + (item.UniEmail ?? "") + " " + (item.Company ?? ""))
                    .IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0)).ToList();
            students.DataSource = rows;
            students.DataBind();
            emptyPanel.Visible = rows.Count == 0;
        }

        private void ShowError(string text)
        {
            workspace.Visible = false;
            noticePanel.Visible = true;
            notice.Text = text;
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
