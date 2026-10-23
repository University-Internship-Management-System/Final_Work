using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net.Http;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;

namespace UniversityInternshipManagmentSystem.Coordinator
{
    public partial class FinalCompletionReview : Page
    {
        private JObject _students, _companyEvaluations, _academicEvaluations, _companies, _academics, _submissions, _tasks, _applications, _certificates;
        private string _studentId;

        protected async void Page_Load(object sender, EventArgs e)
        {
            AuthHelper.RequireAuth(this, AuthHelper.RoleCoordinator);
            if (Response.IsRequestBeingRedirected) return;
            await LoadPageAsync();
        }

        private async Task LoadDataAsync()
        {
            _students = await ReadTable("Students");
            _companyEvaluations = await ReadTable("FinalEvaluations");
            _academicEvaluations = await ReadTable("AcademicEvaluations");
            _companies = await ReadTable("CompanySupervisors");
            _academics = await ReadTable("AcademicSupervisors");
            _submissions = await ReadTable("TaskSubmissions");
            _tasks = await ReadTable("Tasks");
            _applications = await ReadTable("Applications");
            _certificates = await ReadTable("Certificate");
            _studentId = Request.QueryString["studentId"];
        }

        private async Task LoadPageAsync()
        {
            try
            {
                await LoadDataAsync();
                BindCandidates();
                BindSelectedStudent();
            }
            catch (Exception ex) when (ex is HttpRequestException || ex is JsonException || ex is InvalidOperationException)
            {
                pnlError.Visible = true;
                litError.Text = HttpUtility.HtmlEncode("Could not load completion reviews: " + ex.Message);
            }
        }

        private static async Task<JObject> ReadTable(string name)
        {
            string json = await FirebaseDb.Get(name);
            if (json == null) throw new HttpRequestException("Firebase read failed for " + name + ".");
            if (json.Trim() == "null") return new JObject();
            return JsonConvert.DeserializeObject<JObject>(json) ?? new JObject();
        }

        private IEnumerable<JProperty> Candidates()
        {
            return _students.Properties().Where(student =>
                IsCompanyPassed(_companyEvaluations[student.Name], (string)student.Value["CompanyId"]) &&
                IsAcademicPassed(_academicEvaluations[student.Name]) &&
                IsAcademicEvaluationForStudent(_academicEvaluations[student.Name], student.Value));
        }

        private static bool IsCompanyPassed(JToken evaluation, string companyId)
        {
            if (evaluation == null) return false;
            bool passed = (bool?)evaluation["IsPassCompany"] == true || String.Equals((string)evaluation["Status"], FinalEvaluation.Sent, StringComparison.OrdinalIgnoreCase);
            string linkedCompany = (string)evaluation["CompanyId"];
            return passed && (String.IsNullOrWhiteSpace(linkedCompany) || String.Equals(linkedCompany, companyId, StringComparison.Ordinal));
        }

        private static bool IsAcademicEvaluationForStudent(JToken evaluation, JToken student)
        {
            string savedCompany = (string)evaluation["CompanyId"];
            string savedSupervisor = (string)evaluation["AcademicSupervisorId"];
            return (String.IsNullOrWhiteSpace(savedCompany) || String.Equals(savedCompany, (string)student["CompanyId"], StringComparison.Ordinal)) &&
                   (String.IsNullOrWhiteSpace(savedSupervisor) || String.Equals(savedSupervisor, (string)student["AcademicSupervisorId"], StringComparison.Ordinal));
        }
        private static bool IsAcademicPassed(JToken evaluation)
        {
            return evaluation != null && (bool?)evaluation["IsPassAcademic"] == true && String.Equals((string)evaluation["Status"], AcademicEvaluation.Sent, StringComparison.OrdinalIgnoreCase);
        }

        private void BindCandidates()
        {
            var html = new System.Text.StringBuilder();
            foreach (JProperty student in Candidates().OrderBy(s => (string)s.Value["Name"], StringComparer.CurrentCultureIgnoreCase))
            {
                string companyId = (string)student.Value["CompanyId"];
                string certState = FindCertificate(student.Name, CurrentOpportunityId(student.Name)) == null ? "Awaiting coordinator" : "Approved";
                string url = ResolveUrl("~/Coordinator/FinalCompletionReview/FinalCompletionReview.aspx") + "?studentId=" + HttpUtility.UrlEncode(student.Name);
                html.Append("<tr><td>").Append(Encode((string)student.Value["Name"])).Append("</td><td>").Append(Encode(CompanyName(companyId)))
                    .Append("</td><td><span class=\"cr-badge\">Pass</span></td><td><span class=\"cr-badge\">Pass</span></td><td>").Append(Encode(certState))
                    .Append("</td><td><a href=\"").Append(HttpUtility.HtmlAttributeEncode(url)).Append("\">Review</a></td></tr>");
            }
            litCandidateRows.Text = html.Length == 0 ? "<tr><td colspan=\"6\" class=\"text-muted\">No students have both company and academic approval yet.</td></tr>" : html.ToString();
        }

        private void BindSelectedStudent()
        {
            if (String.IsNullOrWhiteSpace(_studentId)) return;
            JProperty entry = Candidates().FirstOrDefault(s => s.Name == _studentId);
            if (entry == null) throw new InvalidOperationException("This student does not have both required passing evaluations.");
            JToken student = entry.Value;
            JToken companyEvaluation = _companyEvaluations[_studentId];
            JToken academicEvaluation = _academicEvaluations[_studentId];
            pnlReview.Visible = true;
            litStudentName.Text = Encode((string)student["Name"] ?? "Student");
            litStudentInfo.Text = Encode((string)student["Major"] ?? "") + " · " + Encode((string)student["UniEmail"] ?? (string)student["Email"] ?? "");
            litCompanyHours.Text = Encode(((int?)companyEvaluation["TotalHours"] ?? 0).ToString(CultureInfo.InvariantCulture));
            litCompanyRatings.Text = BuildRatings(companyEvaluation["Ratings"] as JObject);
            litCompanyComment.Text = Encode((string)companyEvaluation["Comments"] ?? "—");
            string academicId = (string)academicEvaluation["AcademicSupervisorId"];
            litAcademicSupervisor.Text = Encode((string)_academics[academicId]?["Name"] ?? academicId ?? "—");
            litAcademicComment.Text = Encode((string)academicEvaluation["Comments"] ?? "—");
            litTaskRows.Text = BuildTaskRows(_studentId);

            Certificate certificate = FindCertificate(_studentId, CurrentOpportunityId(_studentId));
            btnApprove.Visible = certificate == null || !certificate.IsPassAdmin;
            if (certificate != null && certificate.IsPassAdmin)
            {
                btnApprove.Visible = false;
                ShowMessage("This student's certificate has already been approved.", false);
            }
        }

        private string BuildTaskRows(string studentId)
        {
            var rows = new System.Text.StringBuilder();
            foreach (JProperty task in _tasks.Properties().Where(p => HasStudent(p.Value, studentId)).OrderBy(p => (int?)p.Value["WeekNumber"] ?? 0))
            {
                JProperty latest = _submissions.Properties().Where(s => String.Equals((string)s.Value["TaskId"], task.Name, StringComparison.Ordinal) && String.Equals((string)s.Value["StudentId"], studentId, StringComparison.Ordinal))
                    .OrderByDescending(s => (int?)s.Value["Version"] ?? 0).ThenByDescending(s => (string)s.Value["SubmittedAt"] ?? String.Empty).FirstOrDefault();
                rows.Append("<tr><td>").Append(Encode((string)task.Value["TaskName"] ?? "Task")).Append("</td><td class=\"cr-note\">")
                    .Append(Encode(latest == null ? "—" : (string)latest.Value["Feedback"] ?? "—")).Append("</td><td class=\"cr-note\">")
                    .Append(Encode(latest == null ? "—" : (string)latest.Value["AcademicFeedback"] ?? "—")).Append("</td></tr>");
            }
            return rows.Length == 0 ? "<tr><td colspan=\"3\" class=\"text-muted\">No tasks found.</td></tr>" : rows.ToString();
        }

        protected async void btnApprove_Click(object sender, EventArgs e)
        {
            string adminComment = txtAdminComment.Text.Trim();
            try
            {
                await LoadDataAsync();
                JProperty entry = Candidates().FirstOrDefault(s => s.Name == _studentId);
                if (entry == null) throw new InvalidOperationException("Both company and academic approvals are required before coordinator approval.");
                string opportunityId = CurrentOpportunityId(_studentId);
                if (String.IsNullOrWhiteSpace(opportunityId)) throw new InvalidOperationException("No confirmed internship opportunity was found for this student, so a certificate cannot be approved.");
                Certificate existing = FindCertificate(_studentId, opportunityId);
                if (existing != null && existing.IsPassAdmin) throw new InvalidOperationException("This student already has an approved certificate.");

                var taskIds = _tasks.Properties().Where(p => HasStudent(p.Value, _studentId)).Select(p => p.Name).ToList();
                var certificate = new Certificate
                {
                    CertificateId = existing == null ? CertificateKey(_studentId, opportunityId) : existing.CertificateId,
                    StudentId = _studentId,
                    OpportunityId = opportunityId,
                    TaskId = taskIds,
                    IsPassCompany = true,
                    IsPassAcademic = true,
                    IsPassAdmin = true,
                    AdminComments = adminComment,
                    ApprovedAt = DateTime.UtcNow,
                    ApprovedBy = AuthHelper.UserId
                };
                string key = existing == null ? certificate.CertificateId : existing.CertificateId;
                HttpResponseMessage response = await FirebaseDb.Put("Certificate", key, certificate);
                if (!response.IsSuccessStatusCode) throw new HttpRequestException("Firebase refused to save the coordinator's certificate decision.");
                Notify.CertificateApproved((string)entry.Value["Name"], (string)entry.Value["Email"], adminComment);
                ShowMessage(String.IsNullOrWhiteSpace(adminComment) ? "Completion approved and certificate record saved." : "Completion approved. Coordinator comment: " + adminComment, false);
                await LoadPageAsync();
            }
            catch (Exception ex) when (ex is HttpRequestException || ex is JsonException || ex is InvalidOperationException)
            {
                ShowMessage(ex.Message, true);
                await LoadPageAsync();
            }
        }

        private string CurrentOpportunityId(string studentId)
        {
            var confirmed = _applications.Properties().Where(p => String.Equals((string)p.Value["StudentId"], studentId, StringComparison.Ordinal) &&
                String.Equals((string)p.Value["Status"], ApplicationStatus.Confirmed, StringComparison.OrdinalIgnoreCase) && !String.IsNullOrWhiteSpace((string)p.Value["OpportunityId"])).ToList();
            if (confirmed.Count == 0) return null;
            long latest = confirmed.Max(p => (long?)p.Value["ConfirmedAt"] ?? 0);
            var latestIds = confirmed.Where(p => ((long?)p.Value["ConfirmedAt"] ?? 0) == latest).Select(p => (string)p.Value["OpportunityId"]).Distinct().ToList();
            return latestIds.Count == 1 ? latestIds[0] : null;
        }

        private Certificate FindCertificate(string studentId, string opportunityId)
        {
            if (String.IsNullOrWhiteSpace(opportunityId)) return null;
            var matches = _certificates.Properties().Where(p => String.Equals((string)p.Value["StudentId"], studentId, StringComparison.Ordinal) && String.Equals((string)p.Value["OpportunityId"], opportunityId, StringComparison.Ordinal)).ToList();
            if (matches.Count > 1) throw new InvalidOperationException("Multiple certificates exist for this student and opportunity.");
            if (matches.Count == 0) return null;
            Certificate certificate = matches[0].Value.ToObject<Certificate>();
            certificate.CertificateId = matches[0].Name;
            return certificate;
        }

        private static string CertificateKey(string studentId, string opportunityId)
        {
            string key = "cert_" + studentId + "_" + opportunityId;
            return Regex.Replace(key, "[.#$\\[\\]/]", "_");
        }

        private string CompanyName(string id)
        {
            return (string)_companies[id]?["CompanyName"] ?? (string)_companies[id]?["Name"] ?? id ?? "—";
        }

        private static bool HasStudent(JToken task, string studentId)
        {
            JArray ids = task == null ? null : task["StudentIds"] as JArray;
            return ids != null && ids.Any(id => String.Equals((string)id, studentId, StringComparison.Ordinal));
        }

        private static string BuildRatings(JObject ratings)
        {
            return ratings == null ? "—" : String.Join(" · ", ratings.Properties().Select(p => Encode(p.Name) + ": " + Encode(p.Value.ToString())));
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
