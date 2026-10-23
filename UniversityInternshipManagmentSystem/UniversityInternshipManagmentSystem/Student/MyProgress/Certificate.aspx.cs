using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using Newtonsoft.Json;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;
using InternshipApplication = UniversityInternshipManagmentSystem.Models.Application;

namespace UniversityInternshipManagmentSystem.Student
{
    public partial class CompletionCertificate : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (string.IsNullOrWhiteSpace(Session["userId"] as string))
            {
                Response.Redirect("~/login/Login.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            RegisterAsyncTask(new PageAsyncTask(LoadCertificateAsync));
        }

        private async Task LoadCertificateAsync()
        {
            try
            {
                string studentId = Session["dbRecordId"] as string;
                if (string.IsNullOrWhiteSpace(studentId))
                    studentId = Session["userId"] as string;

                if (string.IsNullOrWhiteSpace(studentId))
                    throw new InvalidOperationException("Student information is missing from your session.");

                string studentJson = await FirebaseDb.Get("Students", studentId);
                UniversityInternshipManagmentSystem.Models.Student student = string.IsNullOrWhiteSpace(studentJson)
                    ? null
                    : JsonConvert.DeserializeObject<UniversityInternshipManagmentSystem.Models.Student>(studentJson);
                if (student == null)
                    throw new InvalidOperationException("Your student record could not be found.");

                string certificatesJson = await FirebaseDb.Get("Certificate");
                var certificates = JsonConvert.DeserializeObject<Dictionary<string, Certificate>>(certificatesJson ?? "null")
                    ?? new Dictionary<string, Certificate>();
                var approved = certificates
                    .Where(item => item.Value != null && item.Value.StudentId == studentId && item.Value.IsPassAdmin)
                    .OrderByDescending(item => item.Value.ApprovedAt ?? DateTime.MinValue)
                    .ToList();

                if (approved.Count == 0)
                    throw new InvalidOperationException("The university training coordinator has not approved your completion yet.");

                string certificateKey = approved[0].Key;
                Certificate certificate = approved[0].Value;
                string certificateId = First(certificate.CertificateId, certificateKey);

                string evaluationJson = await FirebaseDb.Get("FinalEvaluations", studentId);
                FinalEvaluation evaluation = string.IsNullOrWhiteSpace(evaluationJson)
                    ? null
                    : JsonConvert.DeserializeObject<FinalEvaluation>(evaluationJson);

                string applicationsJson = await FirebaseDb.Get("Applications");
                var applications = JsonConvert.DeserializeObject<Dictionary<string, InternshipApplication>>(applicationsJson ?? "null")
                    ?? new Dictionary<string, InternshipApplication>();
                InternshipApplication application = applications.Values
                    .Where(item => item != null && item.StudentId == studentId &&
                        item.OpportunityId == certificate.OpportunityId &&
                        item.Status == ApplicationStatus.Confirmed)
                    .OrderByDescending(item => item.ConfirmedAt)
                    .FirstOrDefault();

                Opportunity opportunity = null;
                if (!string.IsNullOrWhiteSpace(certificate.OpportunityId))
                {
                    string opportunityJson = await FirebaseDb.Get("Opportunities", certificate.OpportunityId);
                    opportunity = string.IsNullOrWhiteSpace(opportunityJson)
                        ? null
                        : JsonConvert.DeserializeObject<Opportunity>(opportunityJson);
                }

                string companyId = First(
                    evaluation == null ? null : evaluation.CompanyId,
                    application == null ? null : application.CompanyId,
                    student.CompanyId,
                    opportunity == null ? null : opportunity.CompanyId);

                string companyName = First(
                    application == null ? null : application.CompanyName,
                    opportunity == null ? null : opportunity.CompanyName);
                if (string.IsNullOrWhiteSpace(companyName) && !string.IsNullOrWhiteSpace(companyId))
                {
                    string companyJson = await FirebaseDb.Get("CompanySupervisors", companyId);
                    CompanySupervisor company = string.IsNullOrWhiteSpace(companyJson)
                        ? null
                        : JsonConvert.DeserializeObject<CompanySupervisor>(companyJson);
                    companyName = company == null ? null : company.CompanyName;
                }

                List<Tasks> tasks = await LoadStudentTasksAsync(studentId, companyId);
                DateTime? startDate = evaluation == null ? null : evaluation.StartDate;
                DateTime? endDate = evaluation == null ? null : evaluation.EndDate;
                if (!startDate.HasValue && tasks.Count > 0)
                    startDate = tasks.Min(task => task.StartDate).Date;
                if (!endDate.HasValue && tasks.Count > 0)
                    endDate = tasks.Max(task => task.DeadLine).Date;

                int weeks = evaluation != null && evaluation.ApprovedWeeks != null && evaluation.ApprovedWeeks.Count > 0
                    ? evaluation.ApprovedWeeks.Count
                    : tasks.Where(task => task.WeekNumber > 0).Select(task => task.WeekNumber).Distinct().Count();
                if (weeks == 0 && startDate.HasValue && endDate.HasValue && endDate.Value >= startDate.Value)
                    weeks = Math.Max(1, (int)Math.Ceiling((endDate.Value.Date - startDate.Value.Date).TotalDays / 7.0));

                int hours = evaluation == null ? 0 : evaluation.TotalHours;
                if (hours <= 0 && evaluation != null && evaluation.ApprovedWeeks != null)
                    hours = evaluation.ApprovedWeeks.Values.Sum();
                if (hours <= 0)
                    hours = tasks.Sum(task => task.HoursFor(studentId));

                litStudent.Text = Enc(First(student.Name, "Student"));
                litMajor.Text = Enc(string.IsNullOrWhiteSpace(student.Major) ? "" : student.Major);
                litCompany.Text = Enc(First(companyName, "Training company"));
                litCompanyDetail.Text = Enc(First(companyName, "Not recorded"));
                litOpportunity.Text = Enc(First(
                    application == null ? null : application.OpportunityTitle,
                    opportunity == null ? null : opportunity.Title,
                    "Not recorded"));
                litPeriod.Text = Enc(FormatDate(startDate) + " – " + FormatDate(endDate));
                litWeeks.Text = weeks > 0 ? weeks + (weeks == 1 ? " week" : " weeks") : "Not recorded";
                litHours.Text = hours > 0 ? hours + (hours == 1 ? " hour" : " hours") : "Not recorded";
                litApprovalDate.Text = Enc(certificate.ApprovedAt.HasValue
                    ? certificate.ApprovedAt.Value.ToString("dd MMM yyyy", CultureInfo.InvariantCulture)
                    : "Not recorded");
                litCertificateId.Text = Enc(certificateId);

                pnlCertificate.Visible = true;
                pnlError.Visible = false;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Certificate Error: " + ex);
                pnlCertificate.Visible = false;
                pnlError.Visible = true;
                litError.Text = Enc(ex is InvalidOperationException
                    ? ex.Message
                    : "Certificate details could not be loaded. Please try again later.");
            }
        }

        private static async Task<List<Tasks>> LoadStudentTasksAsync(string studentId, string companyId)
        {
            string tasksJson = await FirebaseDb.Get("Tasks");
            var allTasks = JsonConvert.DeserializeObject<Dictionary<string, Tasks>>(tasksJson ?? "null")
                ?? new Dictionary<string, Tasks>();

            return allTasks
                .Where(item => item.Value != null && item.Value.StudentIds != null && item.Value.StudentIds.Contains(studentId) &&
                    (string.IsNullOrWhiteSpace(companyId) || string.IsNullOrWhiteSpace(item.Value.CompanyId) || item.Value.CompanyId == companyId))
                .Select(item => item.Value)
                .ToList();
        }

        private static string First(params string[] values)
        {
            return values.FirstOrDefault(value => !string.IsNullOrWhiteSpace(value));
        }

        private static string FormatDate(DateTime? date)
        {
            return date.HasValue ? date.Value.ToString("dd MMM yyyy", CultureInfo.InvariantCulture) : "Not recorded";
        }

        private static string Enc(string value)
        {
            return HttpUtility.HtmlEncode(value ?? "");
        }
    }
}
