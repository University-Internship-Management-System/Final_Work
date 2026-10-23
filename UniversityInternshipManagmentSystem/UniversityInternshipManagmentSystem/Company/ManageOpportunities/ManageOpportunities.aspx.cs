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

namespace UniversityInternshipManagmentSystem.Company.ManageOpportunities
{
    public partial class ManageOpportunities : System.Web.UI.Page
    {
        // key of the company in CompanySupervisors (saved as CompanyId on its opportunities)
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
                RegisterAsyncTask(new PageAsyncTask(LoadPageDataAsync));
            }
        }

        private async Task LoadPageDataAsync()
        {
            try
            {
                // load the company so the name and location are filled in
                CompanySupervisor company = await LoadCompanyAsync();
                if (company == null)
                {
                    // no company profile = nothing can be saved
                    ShowMessage("Your company profile could not be found, so you cannot add opportunities. Please contact the coordinator.");
                    phAddButton.Visible = false;
                }
                else
                {
                    txtCompanyName.Text = company.CompanyName;
                    txtLocation.Text = company.Location ?? "";
                }

                // this company's opportunities
                await BindOpportunitiesAsync(company);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error loading data: " + ex.Message);
                ShowMessage("Could not load your opportunities. Please refresh the page.");
            }
        }

        // this company's opportunities, newest first
        private async Task BindOpportunitiesAsync(CompanySupervisor company)
        {
            // an empty table comes back as "null"
            var all = JsonConvert.DeserializeObject<Dictionary<string, Opportunity>>(await ReadAsync("Opportunities"));

            var list = new List<Opportunity>();
            if (all != null)
            {
                foreach (var pair in all)
                {
                    Opportunity opp = pair.Value;
                    if (opp != null && opp.CompanyId == CompanyId)
                    {
                        opp.Id = pair.Key;
                        // show the company's current name, the one saved in the opportunity can be old
                        if (company != null) opp.CompanyName = company.CompanyName;
                        list.Add(opp);
                    }
                }
            }
            list = list.OrderByDescending(o => o.CreatedAt).ToList();

            rptOpportunities.DataSource = list;
            rptOpportunities.DataBind();
            rptOpportunities.Visible = (list.Count > 0);      // hide the table header when empty
            pnlEmpty.Visible = (list.Count == 0);
        }

        protected async void btnSaveOpportunity_Click(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            string editingId = hfEditingOpportunityId.Value;
            bool editing = (editingId != "");

            string title = txtTitle.Text.Trim();
            string description = txtDescription.Text.Trim();
            string deadlineText = txtDeadline.Text.Trim();
            string startText = txtStartDate.Text.Trim();

            // selected majors
            List<string> selectedMajors = new List<string>();
            foreach (ListItem item in chkMajors.Items)
            {
                if (item.Selected)
                {
                    selectedMajors.Add(item.Value);
                }
            }

            // check the form here too, the browser checks can be skipped
            if (title == "")
            {
                ShowFormError("Enter the opportunity title.", editing);
                return;
            }
            if (description == "")
            {
                ShowFormError("Enter a description.", editing);
                return;
            }

            int seats;
            if (!int.TryParse(txtSeats.Text.Trim(), out seats) || seats < 1)
            {
                ShowFormError("Available seats must be a whole number of 1 or more.", editing);
                return;
            }

            DateTime deadlineDate;
            if (!DateTime.TryParseExact(deadlineText, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out deadlineDate))
            {
                ShowFormError("Choose the application deadline.", editing);
                return;
            }

            DateTime startDate;
            if (!DateTime.TryParseExact(startText, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out startDate))
            {
                ShowFormError("Choose the training start date.", editing);
                return;
            }
            // training starts after the applications close
            if (startDate <= deadlineDate)
            {
                ShowFormError("The training start date must be after the application deadline.", editing);
                return;
            }

            if (selectedMajors.Count == 0)
            {
                ShowFormError("Choose at least one major, otherwise no student will see this opportunity.", editing);
                return;
            }

            try
            {
                CompanySupervisor company = await LoadCompanyAsync();
                if (company == null)
                {
                    ShowMessage("Your company profile could not be found, so the opportunity was not saved. Please contact the coordinator.");
                    return;
                }

                // save the deadline as the end of that day (23:59 UTC) like the seed data,
                // so the date doesn't shift and students can still apply on the last day
                long deadline = new DateTimeOffset(deadlineDate.Year, deadlineDate.Month, deadlineDate.Day, 23, 59, 0, TimeSpan.Zero).ToUnixTimeMilliseconds();
                // start date is saved as the start of that day (00:00 UTC)
                long trainingStart = new DateTimeOffset(startDate.Year, startDate.Month, startDate.Day, 0, 0, 0, TimeSpan.Zero).ToUnixTimeMilliseconds();
                long now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

                HttpResponseMessage response;
                if (editing)
                {
                    Opportunity existing = await LoadOpportunityAsync(editingId);

                    // the id comes from the browser, so make sure it's this company's opportunity
                    if (existing == null || existing.CompanyId != CompanyId)
                    {
                        ShowMessage("This opportunity was not found in your company's list.");
                        return;
                    }

                    int confirmed = 0;
                    if (existing.ConfirmedStudents != null)
                    {
                        confirmed = existing.ConfirmedStudents.Count;
                    }
                    if (seats < confirmed)
                    {
                        ShowFormError(confirmed + " students already confirmed this opportunity, so it needs at least " + confirmed + " seats.", true);
                        return;
                    }

                    // date not changed, keep the old value (this also lets you edit an expired one)
                    if (deadlineText == FormatDate(existing.ApplicationDeadline))
                    {
                        deadline = existing.ApplicationDeadline;
                    }
                    else if (deadline <= now)
                    {
                        ShowFormError("The deadline must be today or a later date.", true);
                        return;
                    }

                    // patch only these fields, the rest stays the same
                    var updatedFields = new
                    {
                        Title = title,
                        Description = description,
                        Seats = seats,
                        Majors = selectedMajors,
                        ApplicationDeadline = deadline,
                        TrainingStartDate = trainingStart,
                        CompanyName = company.CompanyName,
                        Location = company.Location ?? ""
                    };

                    response = await FirebaseDb.Patch("Opportunities", editingId, updatedFields);
                }
                else
                {
                    if (deadline <= now)
                    {
                        ShowFormError("The deadline must be today or a later date.", false);
                        return;
                    }

                    // new opportunity
                    var newOpp = new Opportunity
                    {
                        CompanyId = CompanyId,
                        CompanyName = company.CompanyName,
                        Location = company.Location ?? "",
                        Title = title,
                        Description = description,
                        Majors = selectedMajors,
                        Seats = seats,
                        Status = OpportunityStatus.Open,
                        CreatedAt = now,
                        ApplicationDeadline = deadline,
                        TrainingStartDate = trainingStart
                    };

                    response = await FirebaseDb.Post("Opportunities", newOpp);
                }

                // back to the list only if it was saved
                if (!response.IsSuccessStatusCode)
                {
                    ShowFormError("Could not save the opportunity. Please try again.", editing);
                    return;
                }

                Response.Redirect(Request.RawUrl, false);
                Context.ApplicationInstance.CompleteRequest();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error saving opportunity: " + ex.Message);
                ShowFormError("Could not save the opportunity. Please try again.", editing);
            }
        }

        protected async void rptOpportunities_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            string oppId = e.CommandArgument.ToString();

            try
            {
                Opportunity opp = await LoadOpportunityAsync(oppId);

                // only this company's own opportunities
                if (opp == null || opp.CompanyId != CompanyId)
                {
                    ShowMessage("This opportunity was not found in your company's list.");
                    return;
                }

                if (e.CommandName == "ToggleStatus")
                {
                    string newStatus = OpportunityStatus.Open;
                    if (IsStatusOpen(opp))
                    {
                        newStatus = OpportunityStatus.Closed;
                    }

                    var response = await FirebaseDb.Patch("Opportunities", oppId, new { Status = newStatus });
                    if (!response.IsSuccessStatusCode)
                    {
                        ShowMessage("Could not change the status. Please try again.");
                        return;
                    }

                    Response.Redirect(Request.RawUrl, false);
                    Context.ApplicationInstance.CompleteRequest();
                }
                else if (e.CommandName == "EditOpp")
                {
                    hfEditingOpportunityId.Value = oppId;
                    txtTitle.Text = opp.Title;
                    txtDescription.Text = opp.Description;
                    txtSeats.Text = opp.Seats.ToString();
                    txtDeadline.Text = "";
                    if (opp.ApplicationDeadline > 0)
                    {
                        txtDeadline.Text = FormatDate(opp.ApplicationDeadline);
                    }
                    txtStartDate.Text = "";
                    if (opp.TrainingStartDate > 0)
                    {
                        txtStartDate.Text = FormatDate(opp.TrainingStartDate);
                    }

                    // a saved major that isn't in the list (old data) is added as checked
                    // so saving doesn't remove it
                    if (opp.Majors != null)
                    {
                        foreach (string major in opp.Majors)
                        {
                            if (!string.IsNullOrWhiteSpace(major) && chkMajors.Items.FindByValue(major) == null)
                            {
                                chkMajors.Items.Add(new ListItem(major, major));
                            }
                        }
                    }

                    foreach (ListItem item in chkMajors.Items)
                    {
                        item.Selected = (opp.Majors != null && opp.Majors.Contains(item.Value));
                    }

                    OpenModal("edit");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error handling command: " + ex.Message);
                ShowMessage("Something went wrong. Please refresh the page and try again.");
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

        // "open" in any case
        protected static bool IsStatusOpen(object dataItem)
        {
            Opportunity opp = dataItem as Opportunity;
            if (opp == null) return false;
            return string.Equals(opp.Status, OpportunityStatus.Open, StringComparison.OrdinalIgnoreCase);
        }

        // what students see: Active only if they can really apply
        protected static string StatusText(object dataItem)
        {
            Opportunity opp = (Opportunity)dataItem;
            if (!IsStatusOpen(opp)) return "Closed";
            if (opp.IsDeadlinePassed) return "Deadline passed";
            if (opp.SeatsLeft <= 0) return "Full";
            return "Active";
        }

        protected static string StatusBadgeClass(object dataItem)
        {
            switch (StatusText(dataItem))
            {
                case "Active": return "bg-success";
                case "Closed": return "bg-danger";
                default: return "bg-warning text-dark";
            }
        }

        private void ShowMessage(string message)
        {
            lblMessage.Text = HttpUtility.HtmlEncode(message);
            pnlMessage.Visible = true;
        }

        // show the error inside the popup and open it again with what was typed
        private void ShowFormError(string message, bool editing)
        {
            lblFormError.Text = HttpUtility.HtmlEncode(message);
            pnlFormError.Visible = true;

            if (editing) OpenModal("edit");
            else OpenModal("add");
        }

        // ManageOpportunities.js opens it after the page loads
        private void OpenModal(string mode)
        {
            ClientScript.RegisterStartupScript(GetType(), "OpenOpportunityModal", "window.opportunityModalMode = '" + mode + "';", true);
        }

        // Get returns null when firebase refuses the request
        private static async Task<string> ReadAsync(string table, string id = null)
        {
            string json = await FirebaseDb.Get(table, id);
            if (json == null) throw new Exception("Firebase refused to read " + table + ".");
            return json;
        }

        // null if the company has no profile or no company name
        private async Task<CompanySupervisor> LoadCompanyAsync()
        {
            CompanySupervisor company = JsonConvert.DeserializeObject<CompanySupervisor>(await ReadAsync("CompanySupervisors", CompanyId));
            if (company == null || string.IsNullOrWhiteSpace(company.CompanyName)) return null;
            return company;
        }

        // null if the opportunity doesn't exist
        private static async Task<Opportunity> LoadOpportunityAsync(string opportunityId)
        {
            if (!IsFirebaseId(opportunityId)) return null;

            Opportunity opp = JsonConvert.DeserializeObject<Opportunity>(await ReadAsync("Opportunities", opportunityId));
            if (opp != null)
            {
                opp.Id = opportunityId;
            }
            return opp;
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
    }
}