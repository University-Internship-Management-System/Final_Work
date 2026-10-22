using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net.Http;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;

namespace UniversityInternshipManagmentSystem.Company.ApplicationsReview
{
    public partial class ApplicationsReview : System.Web.UI.Page
    {
        // The company's key in CompanySupervisors (the same id ManageOpportunities saves as CompanyId)
        private string CompanyId => (string)(Session["dbRecordId"] ?? Session["userId"]);

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            if (!IsPostBack)
            {
                // The status filter is kept in the address (?status=Pending), so it stays after Accept / Reject
                ListItem selected = ddlStatus.Items.FindByValue(Request.QueryString["status"] ?? "");
                if (selected != null)
                {
                    ddlStatus.SelectedValue = selected.Value;
                }

                RegisterAsyncTask(new PageAsyncTask(LoadApplicationsAsync));
            }
        }

        // The table: every application sent to this company's opportunities, with the chosen status
        private async Task LoadApplicationsAsync()
        {
            try
            {
                // 1. This company's opportunities (id -> opportunity)
                var allOpportunities = JsonConvert.DeserializeObject<Dictionary<string, Opportunity>>(await ReadAsync("Opportunities"))
                                       ?? new Dictionary<string, Opportunity>();

                var myOpportunities = new Dictionary<string, Opportunity>();
                foreach (var pair in allOpportunities)
                {
                    if (pair.Value != null && pair.Value.CompanyId == CompanyId)
                    {
                        myOpportunities[pair.Key] = pair.Value;
                    }
                }

                // 2. All students, to show each applicant's name and major (found by StudentId)
                var students = JsonConvert.DeserializeObject<Dictionary<string, Models.Student>>(await ReadAsync("Students"))
                               ?? new Dictionary<string, Models.Student>();

                // 3. The applications for those opportunities (found by OpportunityId)
                var applications = JsonConvert.DeserializeObject<Dictionary<string, Application>>(await ReadAsync("Applications"))
                                   ?? new Dictionary<string, Application>();

                var allRows = new List<ApplicationRow>();
                foreach (var pair in applications)
                {
                    Application app = pair.Value;
                    if (app == null || app.OpportunityId == null || !myOpportunities.ContainsKey(app.OpportunityId))
                    {
                        continue;
                    }

                    Models.Student student = null;
                    if (app.StudentId != null)
                    {
                        students.TryGetValue(app.StudentId, out student);
                    }

                    allRows.Add(MakeRow(pair.Key, app, myOpportunities[app.OpportunityId], student));
                }

                // 4. How many applications have each status (shown in the filter, e.g. "Pending (3)")
                foreach (ListItem item in ddlStatus.Items)
                {
                    int count = 0;
                    foreach (var row in allRows)
                    {
                        if (item.Value == "" || row.Status == item.Value) count++;
                    }
                    item.Text = (item.Value == "" ? "All" : item.Value) + " (" + count + ")";
                }

                // 5. Only the chosen status, Pending first (they need a decision), then the newest
                var rows = new List<ApplicationRow>();
                foreach (var row in allRows)
                {
                    if (ddlStatus.SelectedValue == "" || row.Status == ddlStatus.SelectedValue)
                    {
                        rows.Add(row);
                    }
                }
                rows = rows.OrderBy(r => r.IsPending ? 0 : 1).ThenByDescending(r => r.AppliedAt).ToList();

                rptApplications.DataSource = rows;
                rptApplications.DataBind();
                rptApplications.Visible = rows.Count > 0;       // no empty table header
                pnlEmpty.Visible = (rows.Count == 0);

                int pending = allRows.Count(r => r.IsPending);
                lblCount.Text = pending + " waiting for a decision";
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error loading applications: " + ex.Message);
                ShowMessage("Could not load the applications. Please refresh the page.");
            }
        }

        // Everything the table and the application window show
        private static ApplicationRow MakeRow(string id, Application app, Opportunity opportunity, Models.Student student)
        {
            var row = new ApplicationRow();
            row.Id = id;
            row.OpportunityTitle = opportunity.Title;          // the current title, found by OpportunityId
            row.Status = app.Status;
            row.IsPending = (app.Status == ApplicationStatus.Pending);
            row.RejectionReason = app.RejectionReason;
            row.CoverLetter = app.CoverLetter;
            row.AppliedAt = app.AppliedAt;
            row.AppliedDate = FormatDate(app.AppliedAt);

            // The CV and portfolio the student sent with this application
            row.CvLink = WebLink(app.CvUrl);
            row.PortfolioLink = WebLink(app.PortfolioUrl);

            if (student != null)
            {
                row.StudentName = student.Name;
                row.Major = student.Major;
                row.Gpa = student.GPA > 0 ? student.GPA.ToString("0.00", CultureInfo.InvariantCulture) : "-";
                row.Email = string.IsNullOrWhiteSpace(student.UniEmail) ? student.Email : student.UniEmail;
                row.Phone = student.PhoneNumber;
                row.Skills = student.SkillsList == null ? "" : string.Join(", ", student.SkillsList);
            }
            else
            {
                row.StudentName = "Unknown student";
            }

            return row;
        }

        // Filter changed: open the page again with the chosen status in the address
        protected void ddlStatus_SelectedIndexChanged(object sender, EventArgs e)
        {
            string url = "ApplicationsReview.aspx";
            if (ddlStatus.SelectedValue != "")
            {
                url += "?status=" + ddlStatus.SelectedValue;
            }

            Response.Redirect(url, false);
            Context.ApplicationInstance.CompleteRequest();
        }

        // "View" button in the table: show that application in the window
        protected async void rptApplications_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            if (e.CommandName != "ViewApp") return;

            try
            {
                // Read the application again, so the window shows its current status
                string applicationId = Convert.ToString(e.CommandArgument);
                Application app = await LoadApplicationAsync(applicationId);
                Opportunity opportunity = app == null ? null : await LoadOpportunityAsync(app.OpportunityId);

                // Only applications for this company's own opportunities
                if (app == null || opportunity == null || opportunity.CompanyId != CompanyId)
                {
                    ShowMessage("This application was not found in your company's list.");
                    return;
                }

                Models.Student student = null;
                if (IsFirebaseId(app.StudentId))
                {
                    student = JsonConvert.DeserializeObject<Models.Student>(await ReadAsync("Students", app.StudentId));
                }

                ShowApplication(MakeRow(applicationId, app, opportunity, student));
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error opening the application: " + ex.Message);
                ShowMessage("Could not open the application. Please try again.");
            }
        }

        // Fills the application window and opens it
        private void ShowApplication(ApplicationRow row)
        {
            hfApplicationId.Value = row.Id;

            litOpportunity.Text = row.OpportunityTitle;
            litApplied.Text = row.AppliedDate;
            lblStatus.Text = HttpUtility.HtmlEncode(row.Status);
            lblStatus.CssClass = "badge px-3 py-2 " + StatusBadgeClass(row.Status);

            litStudent.Text = Dash(row.StudentName);
            litMajor.Text = Dash(row.Major);
            litEmail.Text = Dash(row.Email);
            litPhone.Text = Dash(row.Phone);
            litGpa.Text = Dash(row.Gpa);
            litSkills.Text = Dash(row.Skills);
            litCover.Text = Dash(row.CoverLetter);

            // A link only when it is a real web address
            lnkCv.NavigateUrl = row.CvLink;
            lnkCv.Text = row.CvLink != null ? "Open CV" : "No CV link";
            lnkPortfolio.NavigateUrl = row.PortfolioLink;
            lnkPortfolio.Text = row.PortfolioLink != null ? "Open portfolio" : "No portfolio link";

            // What happens next, for an application that was already answered
            lblNextStep.Text = HttpUtility.HtmlEncode(NextStep(row));
            lblNextStep.Visible = (lblNextStep.Text != "");

            // Accept / Reject only while the application is Pending
            pnlDecision.Visible = row.IsPending;
            txtReason.Text = "";

            OpenModal();
        }

        private static string NextStep(ApplicationRow row)
        {
            switch (row.Status)
            {
                case "Accepted": return "Waiting for the student to confirm or decline the offer.";
                case "Confirmed": return "The student confirmed. They are now your trainee.";
                case "Rejected": return "Reason for rejection: " + row.RejectionReason;
                default: return "";
            }
        }

        // Accept button in the window
        protected async void btnAccept_Click(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            await DecideAsync(true, "");
        }

        // Reject button in the window
        protected async void btnReject_Click(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            // Reject needs a reason (the student sees it on My Applications)
            string reason = txtReason.Text.Trim();
            if (reason.Length == 0)
            {
                ShowModalError("Please write the reason for rejection.");
                return;
            }
            if (reason.Length > 300)
            {
                ShowModalError("The reason is too long (300 characters at most).");
                return;
            }

            await DecideAsync(false, reason);
        }

        // Saves the decision for the application open in the window, then reloads the page
        private async Task DecideAsync(bool accept, string reason)
        {
            try
            {
                string problem = await SaveDecisionAsync(hfApplicationId.Value, accept, reason);
                if (problem == null)
                {
                    // Reload the page (the same filter) to show the new status
                    Response.Redirect(Request.RawUrl, false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }

                ShowModalError(problem);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error saving the decision: " + ex.Message);
                ShowModalError("Could not save the decision. Please try again.");
            }
        }

        // Saves Accepted or Rejected. Returns null when it worked, otherwise why it was refused.
        private async Task<string> SaveDecisionAsync(string applicationId, bool accept, string reason)
        {
            // Read the application again: it may have changed since the page was opened
            Application app = await LoadApplicationAsync(applicationId);
            if (app == null)
            {
                return "This application no longer exists.";
            }

            // Only applications for this company's own opportunities (the id comes from the browser)
            Opportunity opportunity = await LoadOpportunityAsync(app.OpportunityId);
            if (opportunity == null || opportunity.CompanyId != CompanyId)
            {
                return "This application is not for one of your opportunities.";
            }

            // A decision is made once, while the application is still Pending
            if (app.Status != ApplicationStatus.Pending)
            {
                return "This application was already answered (" + app.Status + ").";
            }

            long now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
            HttpResponseMessage response;

            if (accept)
            {
                // Students take the seats when they confirm. With no seat left, an accepted offer could never be confirmed.
                if (opportunity.SeatsLeft <= 0)
                {
                    return "There are no seats left in \"" + opportunity.Title + "\". Add seats in Manage Opportunities, or reject the application.";
                }

                // PATCH changes only these fields of the application
                response = await FirebaseDb.Patch("Applications", applicationId, new
                {
                    Status = ApplicationStatus.Accepted,
                    ReviewedAt = now
                });
            }
            else
            {
                response = await FirebaseDb.Patch("Applications", applicationId, new
                {
                    Status = ApplicationStatus.Rejected,
                    RejectionReason = reason,
                    ReviewedAt = now
                });
            }

            if (!response.IsSuccessStatusCode)
            {
                return "Could not save the decision. Please try again.";
            }

            // Tell the student (Config/Notify.cs does nothing when email is not set up)
            Notify.ApplicationDecided(app.StudentId, opportunity.Title, opportunity.CompanyName, accept, reason);
            return null;
        }

        // Badge color for each status
        protected string StatusBadgeClass(object status)
        {
            switch (Convert.ToString(status))
            {
                case "Accepted": return "bg-success";
                case "Confirmed": return "bg-primary";
                case "Rejected": return "bg-danger";
                default: return "bg-warning text-dark";      // Pending
            }
        }

        // تنسيق التاريخ من ميللي ثانية إلى تاريخ مقروء (always Gregorian)
        private static string FormatDate(long millis)
        {
            if (millis <= 0) return "-";
            return DateTimeOffset.FromUnixTimeMilliseconds(millis).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
        }

        // "www.site.com" becomes "https://www.site.com". Anything that is not a web link gives null, so no link is shown.
        private static string WebLink(string url)
        {
            if (string.IsNullOrWhiteSpace(url)) return null;

            url = url.Trim();
            if (!url.StartsWith("http://", StringComparison.OrdinalIgnoreCase) && !url.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            {
                url = "https://" + url;
            }

            Uri uri;
            if (Uri.TryCreate(url, UriKind.Absolute, out uri) && (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps))
            {
                return uri.AbsoluteUri;
            }
            return null;
        }

        // "-" instead of an empty field
        private static string Dash(string value)
        {
            return string.IsNullOrWhiteSpace(value) ? "-" : value;
        }

        private void ShowMessage(string message)
        {
            lblMessage.Text = HttpUtility.HtmlEncode(message);
            pnlMessage.Visible = true;
        }

        // Shows the reason inside the application window and opens it again
        private void ShowModalError(string message)
        {
            lblModalError.Text = HttpUtility.HtmlEncode(message);
            pnlModalError.Visible = true;
            OpenModal();
        }

        // ApplicationsReview.js opens the window when the page has loaded (Bootstrap is loaded after this script)
        private void OpenModal()
        {
            ClientScript.RegisterStartupScript(GetType(), "OpenApplicationModal", "window.openApplicationModal = true;", true);
        }

        // FirebaseDb.Get returns null when Firebase refuses the request
        private static async Task<string> ReadAsync(string table, string id = null)
        {
            string json = await FirebaseDb.Get(table, id);
            if (json == null) throw new Exception("Firebase refused to read " + table + ".");
            return json;
        }

        // Firebase ids only use letters, digits, "-" and "_"
        private static bool IsFirebaseId(string id)
        {
            return !string.IsNullOrEmpty(id) && Regex.IsMatch(id, "^[A-Za-z0-9_-]+$");
        }

        private static async Task<Application> LoadApplicationAsync(string id)
        {
            if (!IsFirebaseId(id)) return null;
            return JsonConvert.DeserializeObject<Application>(await ReadAsync("Applications", id));
        }

        private static async Task<Opportunity> LoadOpportunityAsync(string id)
        {
            if (!IsFirebaseId(id)) return null;
            return JsonConvert.DeserializeObject<Opportunity>(await ReadAsync("Opportunities", id));
        }
    }

    // One application, with only what the table and the window show
    public class ApplicationRow
    {
        public string Id { get; set; }
        public string OpportunityTitle { get; set; }
        public string StudentName { get; set; }
        public string Major { get; set; }
        public string Gpa { get; set; }
        public string Email { get; set; }
        public string Phone { get; set; }
        public string Skills { get; set; }
        public string CvLink { get; set; }
        public string PortfolioLink { get; set; }
        public string CoverLetter { get; set; }
        public string Status { get; set; }
        public bool IsPending { get; set; }
        public string RejectionReason { get; set; }
        public long AppliedAt { get; set; }
        public string AppliedDate { get; set; }
    }
}