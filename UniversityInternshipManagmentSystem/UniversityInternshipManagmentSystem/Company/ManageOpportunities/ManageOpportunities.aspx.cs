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

namespace UniversityInternshipManagmentSystem.Company.ManageOpportunities
{
    public partial class ManageOpportunities : System.Web.UI.Page
    {
        // The company's key in CompanySupervisors: the same id MyTrainees uses, and the CompanyId saved on its opportunities
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
                RegisterAsyncTask(new PageAsyncTask(LoadPageDataAsync));
            }
        }

        private async Task LoadPageDataAsync()
        {
            try
            {
                // 1. جلب بيانات الشركة من جدول CompanySupervisors لتعبئة الاسم والموقع تلقائياً
                CompanySupervisor company = await LoadCompanyAsync();
                if (company == null)
                {
                    // No made-up name or location: without a company profile nothing can be saved
                    ShowMessage("Your company profile could not be found, so you cannot add opportunities. Please contact the coordinator.");
                    phAddButton.Visible = false;
                }
                else
                {
                    txtCompanyName.Text = company.CompanyName;
                    txtLocation.Text = company.Location ?? "";
                }

                // 2. جلب الفرص الخاصة بالشركة الحالية فقط وعرضها في الجدول
                await BindOpportunitiesAsync();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error loading data: " + ex.Message);
                ShowMessage("Could not load your opportunities. Please refresh the page.");
            }
        }

        // This company's opportunities, newest first
        private async Task BindOpportunitiesAsync()
        {
            // Firebase returns the text "null" when the table is empty
            var dict = JsonConvert.DeserializeObject<Dictionary<string, Opportunity>>(await ReadAsync("Opportunities"))
                       ?? new Dictionary<string, Opportunity>();

            var list = new List<Opportunity>();
            foreach (var pair in dict)
            {
                var opp = pair.Value;
                if (opp == null) continue;
                opp.Id = pair.Key;

                if (string.Equals(opp.CompanyId, CompanyId, StringComparison.Ordinal))
                {
                    list.Add(opp);
                }
            }
            list = list.OrderByDescending(o => o.CreatedAt).ToList();

            rptOpportunities.DataSource = list;
            rptOpportunities.DataBind();
            rptOpportunities.Visible = list.Count > 0;      // no empty table header above "No opportunities found"
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
            bool editing = !string.IsNullOrEmpty(editingId);

            string title = txtTitle.Text.Trim();
            string description = txtDescription.Text.Trim();
            string deadlineText = txtDeadline.Text.Trim();

            // جمع التخصصات المحددة من الـ CheckBoxList
            List<string> selectedMajors = new List<string>();
            foreach (ListItem item in chkMajors.Items)
            {
                if (item.Selected)
                {
                    selectedMajors.Add(item.Value);
                }
            }

            // 1. Checks that do not need the database (the browser checks can be skipped, so they are done here too)
            int seats = 0;
            DateTime deadlineDate = default(DateTime);
            string error = null;
            if (title.Length == 0) error = "Enter the opportunity title.";
            else if (description.Length == 0) error = "Enter a description.";
            else if (!int.TryParse(txtSeats.Text.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out seats) || seats < 1)
                error = "Available seats must be a whole number of 1 or more.";
            else if (!DateTime.TryParseExact(deadlineText, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out deadlineDate))
                error = "Choose the application deadline.";
            else if (selectedMajors.Count == 0) error = "Choose at least one major, otherwise no student will see this opportunity.";

            if (error != null)
            {
                ShowFormError(error, editing);
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

                // The end of the chosen day (23:59 UTC), the same as the seed data:
                // the date shown never shifts, and students can still apply on the deadline day itself
                long deadline = new DateTimeOffset(deadlineDate.Year, deadlineDate.Month, deadlineDate.Day, 23, 59, 0, TimeSpan.Zero).ToUnixTimeMilliseconds();
                long now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

                HttpResponseMessage response;
                if (editing)
                {
                    Opportunity existing = await LoadOpportunityAsync(editingId);

                    // Only this company's own opportunities can be changed (the editing id comes from the browser)
                    if (existing == null || !string.Equals(existing.CompanyId, CompanyId, StringComparison.Ordinal))
                    {
                        ShowMessage("This opportunity was not found in your company's list.");
                        return;
                    }

                    int confirmed = existing.ConfirmedStudents == null ? 0 : existing.ConfirmedStudents.Count;
                    if (seats < confirmed)
                    {
                        ShowFormError(confirmed + " students already confirmed this opportunity, so it needs at least " + confirmed + " seats.", true);
                        return;
                    }

                    // Deadline date not changed: keep the stored value exactly as it is (this also allows editing an expired opportunity)
                    if (deadlineText == FormatDate(existing.ApplicationDeadline))
                    {
                        deadline = existing.ApplicationDeadline;
                    }
                    else if (deadline <= now)
                    {
                        ShowFormError("The deadline must be today or a later date.", true);
                        return;
                    }

                    // === استخدام PATCH لتحديث الحقول المحددة فقط دون مسح باقي البيانات في السجل ===
                    var updatedFields = new
                    {
                        Title = title,
                        Description = description,
                        Seats = seats,
                        Majors = selectedMajors,
                        ApplicationDeadline = deadline,
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

                    // === إضافة فرصة جديدة (Create) باستخدام POST ===
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
                        ApplicationDeadline = deadline
                    };

                    response = await FirebaseDb.Post("Opportunities", newOpp);
                }

                // Only go back to the list when Firebase really saved it
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

            string oppId = Convert.ToString(e.CommandArgument);

            try
            {
                Opportunity opp = await LoadOpportunityAsync(oppId);

                // Only this company's own opportunities can be closed, opened or edited
                if (opp == null || !string.Equals(opp.CompanyId, CompanyId, StringComparison.Ordinal))
                {
                    ShowMessage("This opportunity was not found in your company's list.");
                    return;
                }

                if (e.CommandName == "ToggleStatus")
                {
                    string newStatus = IsStatusOpen(opp) ? OpportunityStatus.Closed : OpportunityStatus.Open;

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
                    txtSeats.Text = opp.Seats.ToString(CultureInfo.InvariantCulture);
                    txtDeadline.Text = opp.ApplicationDeadline > 0 ? FormatDate(opp.ApplicationDeadline) : "";

                    // A major that is not in the list (older data) is added as a ticked box,
                    // so saving does not silently remove it; the company can untick it
                    foreach (string major in opp.Majors ?? new List<string>())
                    {
                        if (!string.IsNullOrWhiteSpace(major) && chkMajors.Items.FindByValue(major) == null)
                        {
                            chkMajors.Items.Add(new ListItem(major, major));
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

        // تنسيق التاريخ من ميللي ثانية إلى تاريخ مقروء (always Gregorian, the same date the students see)
        protected string FormatDate(object millisObj)
        {
            if (millisObj != null && long.TryParse(millisObj.ToString(), out long millis) && millis > 0)
            {
                return DateTimeOffset.FromUnixTimeMilliseconds(millis).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            }
            return "-";
        }

        // "open" in any letter case
        protected static bool IsStatusOpen(object dataItem)
        {
            var opp = dataItem as Opportunity;
            return opp != null && string.Equals(opp.Status, OpportunityStatus.Open, StringComparison.OrdinalIgnoreCase);
        }

        // What students see: Active only when they can really apply
        protected static string StatusText(object dataItem)
        {
            var opp = (Opportunity)dataItem;
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

        // Shows the reason inside the form and opens it again, with what the company typed still in it
        private void ShowFormError(string message, bool editing)
        {
            lblFormError.Text = HttpUtility.HtmlEncode(message);
            pnlFormError.Visible = true;
            OpenModal(editing ? "edit" : "add");
        }

        // ManageOpportunities.js opens the form when the page has loaded (Bootstrap is loaded after this script)
        private void OpenModal(string mode)
        {
            ClientScript.RegisterStartupScript(GetType(), "OpenOpportunityModal", "window.opportunityModalMode = '" + mode + "';", true);
        }

        // FirebaseDb.Get returns null when Firebase refuses the request
        private static async Task<string> ReadAsync(string table, string id = null)
        {
            string json = await FirebaseDb.Get(table, id);
            if (json == null) throw new Exception("Firebase refused to read " + table + ".");
            return json;
        }

        // The signed-in company's profile, or null when it has no CompanySupervisors record with a company name
        private async Task<CompanySupervisor> LoadCompanyAsync()
        {
            var company = JsonConvert.DeserializeObject<CompanySupervisor>(await ReadAsync("CompanySupervisors", CompanyId));
            return company == null || string.IsNullOrWhiteSpace(company.CompanyName) ? null : company;
        }

        // One opportunity with its Id filled in, or null when it does not exist (Firebase ids only use letters, digits, "-" and "_")
        private static async Task<Opportunity> LoadOpportunityAsync(string opportunityId)
        {
            if (string.IsNullOrEmpty(opportunityId) || !Regex.IsMatch(opportunityId, "^[A-Za-z0-9_-]+$")) return null;

            var opp = JsonConvert.DeserializeObject<Opportunity>(await ReadAsync("Opportunities", opportunityId));
            if (opp != null) opp.Id = opportunityId;
            return opp;
        }
    }
}