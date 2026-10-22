using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;
using UniversityInternshipManagmentSystem.Student.Data;

namespace UniversityInternshipManagmentSystem.Student.ApplicationForm
{
    public partial class ApplicationForm : System.Web.UI.Page
    {
        private string StudentId => (string)(Session["dbRecordId"] ?? Session["userId"]);   // dbRecordId = the Students table key set by the login
        private string OpportunityId => Request.QueryString["opportunityId"];

        // Firebase ids only use letters, digits, "-" and "_"
        private bool HasValidOpportunityId => !string.IsNullOrEmpty(OpportunityId) && Regex.IsMatch(OpportunityId, "^[A-Za-z0-9_-]+$");

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            if (!HasValidOpportunityId)
            {
                Response.Redirect("../Opportunities/Opportunities.aspx", false);
                return;
            }

            if (!IsPostBack)
            {
                RegisterAsyncTask(new PageAsyncTask(LoadFormAsync));
            }
        }

        private async Task LoadFormAsync()
        {
            try
            {
                var student = JsonConvert.DeserializeObject<Models.Student>(await ReadAsync("Students", StudentId));
                Opportunity opportunity = await LoadOpportunityAsync(OpportunityId);
                List<Application> myApplications = await LoadMyApplicationsAsync(StudentId);

                if (student != null)
                {
                    txtName.Text = student.Name ?? "";
                    txtMajor.Text = student.Major ?? "";
                    txtEmail.Text = student.Email ?? "";
                    txtPhone.Text = student.PhoneNumber ?? "";

                    if (student.SkillsList != null && student.SkillsList.Count > 0)
                    {
                        txtSkills.Text = string.Join(", ", student.SkillsList);
                    }

                    // CV and portfolio come from the profile and cannot be changed here
                    txtCvUrl.Text = student.CvUrl ?? "";
                    txtPortfolioUrl.Text = student.PortfolioUrl ?? "";
                }

                // Show which opportunity this application is for
                if (opportunity != null)
                {
                    string text = "Applying for <strong>" + HttpUtility.HtmlEncode(opportunity.Title) + "</strong> at " + HttpUtility.HtmlEncode(opportunity.CompanyName);
                    if (opportunity.ApplicationDeadline > 0)
                    {
                        text += " &middot; Deadline " + DateTimeOffset.FromUnixTimeMilliseconds(opportunity.ApplicationDeadline).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
                    }
                    lblOpportunity.Text = text;
                }

                // If the student cannot apply (typed URL of a closed opportunity, already applied, no CV...), say why and hide the form
                string reason = WhyCannotApply(student, opportunity, myApplications);
                if (reason != null)
                {
                    ShowMessage(reason);
                    pnlApply.Visible = false;
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error loading the application form: " + ex.Message);
                ShowMessage("Could not load the application form. Please refresh the page, or sign in again if this keeps happening.");
                pnlApply.Visible = false;
            }
        }

        // حدث زر تأكيد الطلب الحقيقي: all the rules are checked again here, because the browser checks can be skipped
        protected async void btnSubmit_Click(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            if (!HasValidOpportunityId)
            {
                return;
            }

            string coverLetter = txtCoverLetter.Text.Trim();
            if (coverLetter.Length == 0)
            {
                ShowMessage("Please fill out the motivation question (Cover Letter).");
                return;
            }

            try
            {
                // 1. جلب معلومات جديدة للطالب والفرصة وطلباته، والتأكد أن التقديم ما زال مسموحاً
                var student = JsonConvert.DeserializeObject<Models.Student>(await ReadAsync("Students", StudentId));
                Opportunity opportunity = await LoadOpportunityAsync(OpportunityId);
                List<Application> myApplications = await LoadMyApplicationsAsync(StudentId);

                string reason = WhyCannotApply(student, opportunity, myApplications);
                if (reason != null)
                {
                    ShowMessage(reason);
                    pnlApply.Visible = false;
                    return;
                }

                // 2. إنشاء كائن Application مطابقة للـ Model الخاص بك (CV and portfolio from the student's own record)
                var newApplication = new UniversityInternshipManagmentSystem.Models.Application(
                    studentId: StudentId,
                    opportunityId: OpportunityId,
                    companyId: opportunity.CompanyId,
                    opportunityTitle: opportunity.Title,
                    companyName: opportunity.CompanyName,
                    cvUrl: student.CvUrl,
                    portfolioUrl: student.PortfolioUrl ?? "",
                    coverLetter: coverLetter,
                    appliedAt: DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
                );

                // 3. حفظ الطلب في قاعدة بيانات Firebase تحت جدول "Applications"
                var response = await FirebaseDb.Post("Applications", newApplication);

                // 4. إظهار الـ Pop-up Modal (نجاح العملية)، and hide the form so it cannot be sent twice
                if (response.IsSuccessStatusCode)
                {
                    ScriptManager.RegisterStartupScript(this, GetType(), "saved", "window.applicationSaved = true;", true);
                    pnlApply.Visible = false;
                    ShowMessage("Your application was submitted. You can track it in My Applications.", "alert-success");
                }
                else
                {
                    ShowMessage("Could not save your application. Please try again.");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error submitting application: " + ex.Message);
                ShowMessage("Could not submit your application. Please try again, or sign in again if this keeps happening.");
            }
        }

        private void ShowMessage(string message, string style = "alert-warning")
        {
            lblMessage.Text = HttpUtility.HtmlEncode(message);
            pnlMessage.CssClass = "alert " + style + " d-flex flex-wrap justify-content-between align-items-center gap-2";
            pnlMessage.Visible = true;
        }

        // The reason this student cannot apply to this opportunity, or null when they can
        private static string WhyCannotApply(Models.Student student, Opportunity opportunity, List<Application> myApplications)
        {
            if (opportunity == null) return "This opportunity no longer exists.";
            if (myApplications.Any(a => a.OpportunityId == opportunity.Id)) return "You have already applied to this opportunity. You can track it in My Applications.";

            string reason = WhyStudentCannotApply(student, myApplications);
            if (reason != null) return reason;

            if (!opportunity.AcceptsMajor(student.Major)) return "This opportunity is not open to your major.";
            return opportunity.WhyClosed();   // closed, deadline passed or no seats left
        }

        // ===== The helpers below are the same in Opportunities.aspx.cs (and MyApplications.aspx.cs): change them together =====

        // FirebaseDb.Get returns null when Firebase refuses the request (for example an expired sign-in)
        private static async Task<string> ReadAsync(string table, string id = null)
        {
            string json = await FirebaseDb.Get(table, id);
            if (json == null) throw new Exception("Firebase refused to read " + table + ".");
            return json;
        }

        // One opportunity with its Id filled in, or null when it does not exist
        private static async Task<Opportunity> LoadOpportunityAsync(string opportunityId)
        {
            var opportunity = JsonConvert.DeserializeObject<Opportunity>(await ReadAsync("Opportunities", opportunityId));
            if (opportunity != null) opportunity.Id = opportunityId;
            return opportunity;
        }

        // All applications of this student, newest first
        private static async Task<List<Application>> LoadMyApplicationsAsync(string studentId)
        {
            // Firebase returns the text "null" when the table is empty
            var all = JsonConvert.DeserializeObject<Dictionary<string, Application>>(await ReadAsync("Applications"))
                      ?? new Dictionary<string, Application>();

            var mine = new List<Application>();
            foreach (var pair in all)
            {
                if (pair.Value == null || pair.Value.StudentId != studentId) continue;
                pair.Value.Id = pair.Key;          // the key is the id
                mine.Add(pair.Value);
            }
            return mine.OrderByDescending(a => a.AppliedAt).ToList();
        }

        // Placed = the coordinator assigned a company (same rule as the coordinator dashboard) or the student confirmed an offer
        private static bool IsPlaced(Models.Student student, List<Application> myApplications)
        {
            return (student != null && !string.IsNullOrWhiteSpace(student.CompanyId))
                || myApplications.Any(a => a.Status == ApplicationStatus.Confirmed);
        }

        // A reason that stops this student from applying to ANY opportunity, or null
        private static string WhyStudentCannotApply(Models.Student student, List<Application> myApplications)
        {
            if (student == null) return "Your student profile could not be found. Please contact the coordinator.";
            if (IsPlaced(student, myApplications)) return "You already have a confirmed training, so you cannot apply to other opportunities.";
            if (string.IsNullOrWhiteSpace(student.Major)) return "Your profile has no major, so no opportunities can be matched. Please contact the coordinator.";
            if (!ProfileValidation.IsSafeUrl(student.CvUrl)) return "Add a valid CV link (https://...) in My Profile before applying.";
            return null;
        }
    }
}