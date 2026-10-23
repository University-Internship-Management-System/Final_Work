using Newtonsoft.Json;
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

namespace UniversityInternshipManagmentSystem.Company.ApplicationsReview
{
    public partial class ApplicationsReview : System.Web.UI.Page
    {
        // key of the company in CompanySupervisors (same as CompanyId on its opportunities)
        private string CompanyId
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
                // the filter is kept in the url (?status=Pending) so it stays after accept / reject
                string status = Request.QueryString["status"];
                if (status != null && ddlStatus.Items.FindByValue(status) != null)
                {
                    ddlStatus.SelectedValue = status;
                }

                RegisterAsyncTask(new PageAsyncTask(LoadApplicationsAsync));
            }
        }

        // fills the table with this company's applications for the chosen status
        private async Task LoadApplicationsAsync()
        {
            try
            {
                // read opportunities, students (for the names) and applications
                var opportunities = JsonConvert.DeserializeObject<Dictionary<string, Opportunity>>(await ReadAsync("Opportunities"));
                var students = JsonConvert.DeserializeObject<Dictionary<string, Models.Student>>(await ReadAsync("Students"));
                var applications = JsonConvert.DeserializeObject<Dictionary<string, Application>>(await ReadAsync("Applications"));

                // an empty table comes back as "null"
                if (opportunities == null) opportunities = new Dictionary<string, Opportunity>();
                if (students == null) students = new Dictionary<string, Models.Student>();
                if (applications == null) applications = new Dictionary<string, Application>();

                // one row per application to this company's opportunities
                var allRows = new List<ApplicationRow>();
                foreach (var pair in applications)
                {
                    Application app = pair.Value;
                    if (app == null || app.OpportunityId == null || !opportunities.ContainsKey(app.OpportunityId)) continue;

                    Opportunity opportunity = opportunities[app.OpportunityId];
                    if (opportunity == null || opportunity.CompanyId != CompanyId) continue;     // not ours

                    Models.Student student = null;
                    if (app.StudentId != null && students.ContainsKey(app.StudentId))
                    {
                        student = students[app.StudentId];
                    }

                    allRows.Add(MakeRow(pair.Key, app, opportunity, student));
                }

                // count per status for the filter, e.g. "Pending (3)"
                foreach (ListItem item in ddlStatus.Items)
                {
                    int count = 0;
                    foreach (var row in allRows)
                    {
                        if (item.Value == "" || row.Status == item.Value) count++;
                    }

                    if (item.Value == "") item.Text = "All (" + count + ")";
                    else item.Text = item.Value + " (" + count + ")";
                }

                // chosen status only, pending first, then newest
                var newestFirst = allRows.OrderByDescending(r => r.AppliedAt).ToList();
                var rows = new List<ApplicationRow>();
                foreach (var row in newestFirst)
                {
                    if (row.IsPending && IsChosenStatus(row.Status)) rows.Add(row);
                }
                foreach (var row in newestFirst)
                {
                    if (!row.IsPending && IsChosenStatus(row.Status)) rows.Add(row);
                }

                rptApplications.DataSource = rows;
                rptApplications.DataBind();
                rptApplications.Visible = (rows.Count > 0);       // no empty table header
                pnlEmpty.Visible = (rows.Count == 0);

                int pending = 0;
                foreach (var row in allRows)
                {
                    if (row.IsPending) pending++;
                }
                lblCount.Text = pending + " waiting for a decision";
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error loading applications: " + ex.Message);
                ShowMessage("Could not load the applications. Please refresh the page.");
            }
        }

        // true if the filter is All or this status
        private bool IsChosenStatus(string status)
        {
            return ddlStatus.SelectedValue == "" || ddlStatus.SelectedValue == status;
        }

        // everything the table and the popup need
        private static ApplicationRow MakeRow(string id, Application app, Opportunity opportunity, Models.Student student)
        {
            var row = new ApplicationRow();
            row.Id = id;
            row.OpportunityTitle = opportunity.Title;          // current title (by OpportunityId)
            row.Status = app.Status;
            row.IsPending = (app.Status == ApplicationStatus.Pending);
            row.RejectionReason = app.RejectionReason;
            row.CoverLetter = app.CoverLetter;
            row.AppliedAt = app.AppliedAt;
            row.AppliedDate = FormatDate(app.AppliedAt);

            // cv and portfolio sent with this application
            row.CvLink = WebLink(app.CvUrl);
            row.PortfolioLink = WebLink(app.PortfolioUrl);

            if (student == null)
            {
                row.StudentName = "Unknown student";
                return row;
            }

            row.StudentName = student.Name;
            row.Major = student.Major;
            row.Gpa = "-";
            if (student.GPA > 0)
            {
                row.Gpa = student.GPA.ToString("0.00", CultureInfo.InvariantCulture);
            }
            row.Email = student.UniEmail;
            if (string.IsNullOrWhiteSpace(row.Email))
            {
                row.Email = student.Email;
            }
            row.Phone = student.PhoneNumber;
            row.Skills = "";
            if (student.SkillsList != null)
            {
                row.Skills = string.Join(", ", student.SkillsList);
            }
            return row;
        }

        // reload with the new status in the url
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

        // View button
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
                // read it again to get the current status
                string applicationId = e.CommandArgument.ToString();
                Application app = await LoadApplicationAsync(applicationId);

                Opportunity opportunity = null;
                if (app != null)
                {
                    opportunity = await LoadOpportunityAsync(app.OpportunityId);
                }

                // only this company's applications
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

        // fill the popup and open it
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

            // only link real web addresses
            lnkCv.NavigateUrl = row.CvLink;
            lnkCv.Text = "No CV link";
            if (row.CvLink != null) lnkCv.Text = "Open CV";

            lnkPortfolio.NavigateUrl = row.PortfolioLink;
            lnkPortfolio.Text = "No portfolio link";
            if (row.PortfolioLink != null) lnkPortfolio.Text = "Open portfolio";

            // already answered, show what happens next
            lblNextStep.Text = HttpUtility.HtmlEncode(NextStep(row));
            lblNextStep.Visible = (lblNextStep.Text != "");

            // accept / reject only while pending
            pnlDecision.Visible = row.IsPending;
            txtReason.Text = "";

            OpenModal();
        }

        private static string NextStep(ApplicationRow row)
        {
            if (row.Status == "Accepted") return "Waiting for the student to confirm or decline the offer.";
            if (row.Status == "Confirmed") return "The student confirmed. They are now your trainee.";
            if (row.Status == "Rejected") return "Reason for rejection: " + row.RejectionReason;
            return "";
        }

        // Accept button
        protected async void btnAccept_Click(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            await DecideAsync(true, "");
        }

        // Reject button
        protected async void btnReject_Click(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            // reject needs a reason, the student sees it in My Applications
            string reason = txtReason.Text.Trim();
            if (reason == "")
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

        // save the decision for the open application and reload
        private async Task DecideAsync(bool accept, string reason)
        {
            try
            {
                string problem = await SaveDecisionAsync(hfApplicationId.Value, accept, reason);
                if (problem != null)
                {
                    ShowModalError(problem);
                    return;
                }

                // reload with the same filter
                Response.Redirect(Request.RawUrl, false);
                Context.ApplicationInstance.CompleteRequest();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error saving the decision: " + ex.Message);
                ShowModalError("Could not save the decision. Please try again.");
            }
        }

        // returns null if it worked, otherwise the error message
        private async Task<string> SaveDecisionAsync(string applicationId, bool accept, string reason)
        {
            // read it again, it may have changed since the page was opened
            Application app = await LoadApplicationAsync(applicationId);
            if (app == null)
            {
                return "This application no longer exists.";
            }

            // only this company's applications (the id comes from the browser)
            Opportunity opportunity = await LoadOpportunityAsync(app.OpportunityId);
            if (opportunity == null || opportunity.CompanyId != CompanyId)
            {
                return "This application is not for one of your opportunities.";
            }

            // only pending applications can be answered
            if (app.Status != ApplicationStatus.Pending)
            {
                return "This application was already answered (" + app.Status + ").";
            }

            long now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
            HttpResponseMessage response;

            if (accept)
            {
                // no seats left means the student could never confirm, so don't accept
                if (opportunity.SeatsLeft <= 0)
                {
                    return "There are no seats left in \"" + opportunity.Title + "\". Add seats in Manage Opportunities, or reject the application.";
                }

                // patch only these fields
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
            return null;
        }

        // badge color per status
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

        // InvariantCulture so arabic browsers don't get hijri dates
        private static string FormatDate(long millis)
        {
            if (millis <= 0) return "-";
            return DateTimeOffset.FromUnixTimeMilliseconds(millis).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
        }

        // "www.site.com" becomes "https://www.site.com", null if it's not a link
        private static string WebLink(string url)
        {
            if (string.IsNullOrWhiteSpace(url)) return null;

            url = url.Trim();
            if (!url.StartsWith("http://", StringComparison.OrdinalIgnoreCase) && !url.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            {
                url = "https://" + url;
            }

            Uri uri;
            if (Uri.TryCreate(url, UriKind.Absolute, out uri) && (uri.Scheme == "http" || uri.Scheme == "https"))
            {
                return uri.AbsoluteUri;
            }
            return null;
        }

        // "-" for empty fields
        private static string Dash(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return "-";
            return value;
        }

        private void ShowMessage(string message)
        {
            lblMessage.Text = HttpUtility.HtmlEncode(message);
            pnlMessage.Visible = true;
        }

        // show the error inside the popup and open it again
        private void ShowModalError(string message)
        {
            lblModalError.Text = HttpUtility.HtmlEncode(message);
            pnlModalError.Visible = true;
            OpenModal();
        }

        // ApplicationsReview.js opens it after the page loads
        private void OpenModal()
        {
            ClientScript.RegisterStartupScript(GetType(), "OpenApplicationModal", "window.openApplicationModal = true;", true);
        }

        // Get returns null when firebase refuses the request
        private static async Task<string> ReadAsync(string table, string id = null)
        {
            string json = await FirebaseDb.Get(table, id);
            if (json == null) throw new Exception("Firebase refused to read " + table + ".");
            return json;
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

    // one row of the table
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