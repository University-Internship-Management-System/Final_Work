using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;
using UniversityInternshipManagmentSystem.Student.StudentProfilePage;

namespace UniversityInternshipManagmentSystem.Student.ApplicationForm
{
    public partial class ApplicationForm : System.Web.UI.Page
    {
        // key of the student in the Students table
        private string StudentId
        {
            get { return (string)(Session["dbRecordId"] ?? Session["userId"]); }
        }

        // from the url (?opportunityId=...)
        private string OpportunityId
        {
            get { return Request.QueryString["opportunityId"]; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            if (!IsFirebaseId(OpportunityId))
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
                Models.Student student = JsonConvert.DeserializeObject<Models.Student>(await ReadAsync("Students", StudentId));
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

                    // cv and portfolio come from the profile, read only here
                    txtCvUrl.Text = student.CvUrl ?? "";
                    txtPortfolioUrl.Text = student.PortfolioUrl ?? "";
                }

                // show which opportunity this is for
                if (opportunity != null)
                {
                    string companyName = await CurrentCompanyNameAsync(opportunity);
                    string text = "Applying for <strong>" + HttpUtility.HtmlEncode(opportunity.Title) + "</strong> at " + HttpUtility.HtmlEncode(companyName);
                    if (opportunity.ApplicationDeadline > 0)
                    {
                        text += " &middot; Deadline " + FormatDate(opportunity.ApplicationDeadline);
                    }
                    lblOpportunity.Text = text;
                }

                // can't apply (closed, already applied, no cv...)? show why and hide the form
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

        // the rules are checked again here because the js checks can be skipped
        protected async void btnSubmit_Click(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            if (!IsFirebaseId(OpportunityId))
            {
                return;
            }

            string coverLetter = txtCoverLetter.Text.Trim();
            if (coverLetter == "")
            {
                ShowMessage("Please fill out the motivation question (Cover Letter).");
                return;
            }

            try
            {
                // load everything again and make sure the student can still apply
                Models.Student student = JsonConvert.DeserializeObject<Models.Student>(await ReadAsync("Students", StudentId));
                Opportunity opportunity = await LoadOpportunityAsync(OpportunityId);
                List<Application> myApplications = await LoadMyApplicationsAsync(StudentId);

                string reason = WhyCannotApply(student, opportunity, myApplications);
                if (reason != null)
                {
                    ShowMessage(reason);
                    pnlApply.Visible = false;
                    return;
                }

                string companyName = await CurrentCompanyNameAsync(opportunity);

                // cv and portfolio are taken from the student record
                var newApplication = new UniversityInternshipManagmentSystem.Models.Application(
                    studentId: StudentId,
                    opportunityId: OpportunityId,
                    companyId: opportunity.CompanyId,
                    opportunityTitle: opportunity.Title,
                    companyName: companyName,
                    cvUrl: student.CvUrl,
                    portfolioUrl: student.PortfolioUrl ?? "",
                    coverLetter: coverLetter,
                    appliedAt: DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
                );

                // save it
                var response = await FirebaseDb.Post("Applications", newApplication);

                // show the popup and hide the form so it can't be sent twice
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

        // why the student can't apply to this opportunity, or null
        private static string WhyCannotApply(Models.Student student, Opportunity opportunity, List<Application> myApplications)
        {
            if (opportunity == null) return "This opportunity no longer exists.";

            foreach (var app in myApplications)
            {
                if (app.OpportunityId == opportunity.Id) return "You have already applied to this opportunity. You can track it in My Applications.";
            }

            string reason = WhyStudentCannotApply(student, myApplications);
            if (reason != null) return reason;

            if (!opportunity.AcceptsMajor(student.Major)) return "This opportunity is not open to your major.";
            return opportunity.WhyClosed();   // closed, deadline passed or no seats left
        }

        // the name from the company's profile (by CompanyId),
        // if the profile can't be read we use the name saved in the opportunity
        private static async Task<string> CurrentCompanyNameAsync(Opportunity opportunity)
        {
            try
            {
                if (IsFirebaseId(opportunity.CompanyId))
                {
                    CompanySupervisor company = JsonConvert.DeserializeObject<CompanySupervisor>(await ReadAsync("CompanySupervisors", opportunity.CompanyId));
                    if (company != null && !string.IsNullOrWhiteSpace(company.CompanyName))
                    {
                        return company.CompanyName;
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Could not read the company name: " + ex.Message);
            }
            return opportunity.CompanyName;
        }

        private void ShowMessage(string message, string style = "alert-warning")
        {
            lblMessage.Text = HttpUtility.HtmlEncode(message);
            pnlMessage.CssClass = "alert " + style + " d-flex flex-wrap justify-content-between align-items-center gap-2";
            pnlMessage.Visible = true;
        }

        // InvariantCulture so arabic browsers don't get hijri dates
        private static string FormatDate(long millis)
        {
            return DateTimeOffset.FromUnixTimeMilliseconds(millis).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
        }

        // firebase keys only use letters, numbers, - and _
        private static bool IsFirebaseId(string id)
        {
            if (string.IsNullOrEmpty(id)) return false;

            foreach (char c in id)
            {
                bool allowed = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-' || c == '_';
                if (!allowed) return false;
            }
            return true;
        }

        // same helpers as in Opportunities and MyApplications

        // Get returns null when firebase refuses the request (e.g. expired login)
        private static async Task<string> ReadAsync(string table, string id = null)
        {
            string json = await FirebaseDb.Get(table, id);
            if (json == null) throw new Exception("Firebase refused to read " + table + ".");
            return json;
        }

        // null if the opportunity doesn't exist
        private static async Task<Opportunity> LoadOpportunityAsync(string opportunityId)
        {
            Opportunity opportunity = JsonConvert.DeserializeObject<Opportunity>(await ReadAsync("Opportunities", opportunityId));
            if (opportunity != null)
            {
                opportunity.Id = opportunityId;
            }
            return opportunity;
        }

        // this student's applications, newest first
        private static async Task<List<Application>> LoadMyApplicationsAsync(string studentId)
        {
            // an empty table comes back as "null"
            var all = JsonConvert.DeserializeObject<Dictionary<string, Application>>(await ReadAsync("Applications"));
            var mine = new List<Application>();
            if (all == null) return mine;

            foreach (var pair in all)
            {
                if (pair.Value != null && pair.Value.StudentId == studentId)
                {
                    pair.Value.Id = pair.Key;
                    mine.Add(pair.Value);
                }
            }
            return mine.OrderByDescending(a => a.AppliedAt).ToList();
        }

        // placed = has a CompanyId or confirmed an offer
        private static bool IsPlaced(Models.Student student, List<Application> myApplications)
        {
            if (student != null && !string.IsNullOrWhiteSpace(student.CompanyId)) return true;

            foreach (var app in myApplications)
            {
                if (app.Status == ApplicationStatus.Confirmed) return true;
            }
            return false;
        }

        // why the student can't apply to anything, or null
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