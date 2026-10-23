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

namespace UniversityInternshipManagmentSystem.Student.MyApplications
{
    public partial class MyApplications : System.Web.UI.Page
    {
        // key of the student in the Students table (ApplicationForm saves it as StudentId)
        private string StudentId
        {
            get { return (string)(Session["dbRecordId"] ?? Session["userId"]); }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            if (!IsPostBack)
            {
                RegisterAsyncTask(new PageAsyncTask(LoadStudentApplicationsAsync));
            }
        }

        private async Task LoadStudentApplicationsAsync()
        {
            try
            {
                List<Application> myApplications = await LoadMyApplicationsAsync(StudentId);
                await ShowApplicationsAsync(myApplications);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error loading applications: " + ex.Message);
                ShowMessage("Could not load your applications. Please refresh the page, or sign in again if this keeps happening.");
            }
        }

        // no applications -> show the empty panel instead of the table
        private async Task ShowApplicationsAsync(List<Application> list)
        {
            await UseCurrentOpportunityNamesAsync(list);
            await UseCurrentCompanyNamesAsync(list);

            // a confirmed training gets its own card on top
            Application confirmed = null;
            foreach (var app in list)
            {
                if (confirmed == null && app.Status == ApplicationStatus.Confirmed)
                {
                    confirmed = app;
                }
            }

            // the table shows everything else
            List<Application> others = new List<Application>();
            foreach (var app in list)
            {
                if (app != confirmed) others.Add(app);
            }

            if (confirmed != null)
            {
                await ShowConfirmedAsync(confirmed);

                // the other applications are only history now
                pnlHistoryHead.Visible = (others.Count > 0);
                pnlList.Visible = (others.Count > 0);
                pnlList.CssClass = "card app-table-card app-history";
            }

            rptApplications.DataSource = others;
            rptApplications.DataBind();

            rptApplications.Visible = (others.Count > 0);
            pnlEmpty.Visible = (list.Count == 0);
        }

        // fills the "Your training" card
        private async Task ShowConfirmedAsync(Application confirmed)
        {
            litConfirmedTitle.Text = confirmed.OpportunityTitle;
            litConfirmedCompany.Text = confirmed.CompanyName;

            // the training start date is saved on the opportunity (older ones don't have it)
            try
            {
                if (!string.IsNullOrEmpty(confirmed.OpportunityId))
                {
                    Opportunity opportunity = await LoadOpportunityAsync(confirmed.OpportunityId);
                    if (opportunity != null && opportunity.TrainingStartDate > 0)
                    {
                        litTrainingStart.Text = FormatDate(opportunity.TrainingStartDate);
                        pnlTrainingStart.Visible = true;
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Could not read the training start date: " + ex.Message);
            }

            pnlConfirmed.Visible = true;
        }

        // Confirm / Reject buttons
        protected async void rptApplications_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            try
            {
                // load again, something may have changed since the page was opened
                List<Application> myApplications = await LoadMyApplicationsAsync(StudentId);
                string problem = await HandleOfferAsync(e.CommandName, e.CommandArgument.ToString(), myApplications);

                if (problem == null)
                {
                    // reload the page
                    Response.Redirect(Request.RawUrl, false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }

                ShowMessage(problem);
                await ShowApplicationsAsync(myApplications);   // rebind so the old buttons go away
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error processing application action: " + ex.Message);
                ShowMessage("Something went wrong. Please refresh the page and try again.");
            }
        }

        // use the opportunity's current title and company (by OpportunityId) so company edits show here.
        // the copy saved in the application is only a fallback
        private static async Task UseCurrentOpportunityNamesAsync(List<Application> list)
        {
            if (list.Count == 0) return;

            try
            {
                // read all opportunities once, not once per application
                var opportunities = JsonConvert.DeserializeObject<Dictionary<string, Opportunity>>(await ReadAsync("Opportunities"));
                if (opportunities == null) return;

                foreach (var app in list)
                {
                    if (app.OpportunityId == null || !opportunities.ContainsKey(app.OpportunityId)) continue;

                    Opportunity opportunity = opportunities[app.OpportunityId];
                    if (opportunity == null) continue;

                    if (!string.IsNullOrWhiteSpace(opportunity.Title)) app.OpportunityTitle = opportunity.Title;
                    if (!string.IsNullOrWhiteSpace(opportunity.CompanyName)) app.CompanyName = opportunity.CompanyName;
                }
            }
            catch (Exception ex)
            {
                // keep the saved names
                System.Diagnostics.Debug.WriteLine("Could not read the current opportunity names: " + ex.Message);
            }
        }

        // takes the company name from the company's profile (by CompanyId),
        // if the profile can't be read the name above stays
        private static async Task UseCurrentCompanyNamesAsync(List<Application> list)
        {
            if (list.Count == 0) return;

            try
            {
                var companies = JsonConvert.DeserializeObject<Dictionary<string, CompanySupervisor>>(await ReadAsync("CompanySupervisors"));
                if (companies == null) return;

                foreach (var app in list)
                {
                    if (app.CompanyId == null || !companies.ContainsKey(app.CompanyId)) continue;

                    CompanySupervisor company = companies[app.CompanyId];
                    if (company != null && !string.IsNullOrWhiteSpace(company.CompanyName))
                    {
                        app.CompanyName = company.CompanyName;
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Could not read the company names: " + ex.Message);
            }
        }

        // returns null if it worked, otherwise the error message
        private async Task<string> HandleOfferAsync(string command, string applicationId, List<Application> myApplications)
        {
            // only look in this student's applications
            Application offer = null;
            foreach (var app in myApplications)
            {
                if (app.Id == applicationId)
                {
                    offer = app;
                }
            }

            // only Accepted offers can be confirmed or rejected
            if (offer == null || offer.Status != ApplicationStatus.Accepted)
            {
                return "This offer can no longer be changed. The list below shows its current status.";
            }

            if (command == "RejectOffer")
            {
                // student rejected the offer, only these two fields change
                var response = await FirebaseDb.Patch("Applications", offer.Id, new
                {
                    Status = ApplicationStatus.Rejected,
                    RejectionReason = "Rejected by student."
                });

                if (!response.IsSuccessStatusCode) return "Could not reject the offer. Please try again.";

                Notify.OfferDeclined((string)Session["name"], offer.OpportunityTitle, offer.CompanyId);
                return null;
            }

            if (command != "ConfirmApp") return "Unknown action.";

            Models.Student student = JsonConvert.DeserializeObject<Models.Student>(await ReadAsync("Students", StudentId));
            if (student == null) return "Your student profile could not be found. Please contact the coordinator.";
            if (IsPlaced(student, myApplications)) return "You have already confirmed a training, so you cannot confirm another offer.";

            Opportunity opportunity = await LoadOpportunityAsync(offer.OpportunityId);
            if (opportunity == null) return "This opportunity no longer exists, so the offer cannot be confirmed.";

            // SeatsLeft is counted from ConfirmedStudents
            if (opportunity.SeatsLeft <= 0) return "There are no seats left in this opportunity, so the offer cannot be confirmed.";

            bool saved = await ConfirmOfferAsync(StudentId, offer, opportunity, myApplications);
            if (!saved) return "Could not confirm the offer. Please try again.";

            // Tell the student and the company (Config/Notify.cs does nothing when email is not set up)
            Notify.OfferConfirmed(student.Name, student.Email, opportunity.Title, opportunity.CompanyName, opportunity.CompanyId);
            return null;
        }

        // everything is saved in one request so it's all or nothing.
        // each key is a path in the database
        private static async Task<bool> ConfirmOfferAsync(string studentId, Application offer, Opportunity opportunity, List<Application> myApplications)
        {
            var changes = new Dictionary<string, object>();

            // confirm the offer
            changes.Add("Applications/" + offer.Id + "/Status", ApplicationStatus.Confirmed);
            changes.Add("Applications/" + offer.Id + "/ConfirmedAt", DateTimeOffset.UtcNow.ToUnixTimeMilliseconds());

            // take a seat
            changes.Add("Opportunities/" + opportunity.Id + "/ConfirmedStudents/" + studentId, true);

            // link the student to the company
            changes.Add("Students/" + studentId + "/CompanyId", opportunity.CompanyId);

            // cancel the other open applications
            foreach (var other in myApplications)
            {
                bool stillOpen = (other.Status == ApplicationStatus.Pending || other.Status == ApplicationStatus.Accepted);
                if (other.Id != offer.Id && stillOpen)
                {
                    changes.Add("Applications/" + other.Id + "/Status", ApplicationStatus.Rejected);
                    changes.Add("Applications/" + other.Id + "/RejectionReason", "Automatically cancelled due to confirming another offer.");
                }
            }

            // "" = database root, so one patch can update the three tables
            var response = await FirebaseDb.Patch("", null, changes);
            return response.IsSuccessStatusCode;
        }

        // css class for each status
        protected string GetStatusBadgeClass(object status)
        {
            string st = Convert.ToString(status);
            switch (st)
            {
                case "Accepted": return "badge-accepted";
                case "Confirmed": return "badge-confirmed";
                case "Rejected": return "badge-rejected";
                default: return "badge-pending";
            }
        }

        // InvariantCulture so arabic browsers don't get hijri dates
        protected string FormatDate(object millisObj)
        {
            long millis;
            if (long.TryParse(Convert.ToString(millisObj), out millis) && millis > 0)
            {
                return DateTimeOffset.FromUnixTimeMilliseconds(millis).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            }
            return "-";
        }

        private void ShowMessage(string message)
        {
            lblMessage.Text = HttpUtility.HtmlEncode(message);
            pnlMessage.Visible = true;
        }

        // same helpers as in Opportunities and ApplicationForm

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
    }
}