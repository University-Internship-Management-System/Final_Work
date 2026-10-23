using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;
using UniversityInternshipManagmentSystem.Student.StudentProfilePage;

namespace UniversityInternshipManagmentSystem.Student.Opportunities
{
    public partial class Opportunities : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            if (!IsPostBack)
            {
                RegisterAsyncTask(new PageAsyncTask(LoadPageAsync));
            }
        }

        private List<Opportunity> ParseOpportunities(string json, string studentMajor)
        {
            var list = new List<Opportunity>();

            // empty table
            if (string.IsNullOrWhiteSpace(json) || json.Trim() == "null")
            {
                return list;
            }

            // key = opportunity id
            var dict = JsonConvert.DeserializeObject<Dictionary<string, Opportunity>>(json);

            if (dict != null)
            {
                foreach (var pair in dict)
                {
                    var opp = pair.Value;
                    if (opp == null) continue;
                    opp.Id = pair.Key;

                    // only opportunities for the student's major (open and closed)
                    if (opp.AcceptsMajor(studentMajor))
                    {
                        list.Add(opp);
                    }
                }
            }

            return list;
        }

        private async Task LoadPageAsync()
        {
            string studentId = (string)(Session["dbRecordId"] ?? Session["userId"]);

            try
            {
                // load the student first, we need the major
                var student = JsonConvert.DeserializeObject<Models.Student>(await ReadAsync("Students", studentId));
                List<Application> myApplications = await LoadMyApplicationsAsync(studentId);

                // if the student can't apply at all, show why once at the top
                string blocked = WhyStudentCannotApply(student, myApplications);
                if (blocked != null) ShowNotice(blocked);
                if (student == null) return;

                List<Opportunity> all = ParseOpportunities(await ReadAsync("Opportunities"), student.Major);

                // hide opportunities of deactivated companies
                all = await RemoveDeactivatedCompaniesAsync(all);

                // show the company's current name and location, the ones saved in the opportunity can be old
                await UseCurrentCompanyInfoAsync(all);

                // company dropdown
                ddlCompany.Items.Clear();
                ddlCompany.Items.Add(new ListItem("All companies", ""));

                foreach (var opp in all)
                {
                    // add each company only once
                    if (!string.IsNullOrEmpty(opp.CompanyName) && ddlCompany.Items.FindByValue(opp.CompanyName) == null)
                    {
                        ddlCompany.Items.Add(new ListItem(opp.CompanyName, opp.CompanyName));
                    }
                }

                RenderOpportunities(all, myApplications, blocked);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error loading opportunities: " + ex.Message);
                ShowNotice("Could not load the opportunities. Please refresh the page, or sign in again if this keeps happening.");
            }
        }

        // when the coordinator deactivates a company, its firebase account gets disabled
        // (see CompanyAccountAccess.cs in Coordinator/ManageCompanySupervisors).
        // this needs the admin key, without it nothing is hidden
        private static async Task<List<Opportunity>> RemoveDeactivatedCompaniesAsync(List<Opportunity> opportunities)
        {
            if (!Coordinator.CompanyAccountAccess.IsConfigured) return opportunities;

            try
            {
                // company ids, no duplicates
                var companyIds = new List<string>();
                foreach (var opp in opportunities)
                {
                    if (!string.IsNullOrEmpty(opp.CompanyId) && !companyIds.Contains(opp.CompanyId))
                    {
                        companyIds.Add(opp.CompanyId);
                    }
                }

                // companyId -> true if deactivated
                Dictionary<string, bool> disabled = await Coordinator.CompanyAccountAccess.GetDisabledAccounts(companyIds.ToArray());

                var active = new List<Opportunity>();
                foreach (var opp in opportunities)
                {
                    bool isDeactivated = opp.CompanyId != null && disabled.ContainsKey(opp.CompanyId) && disabled[opp.CompanyId];
                    if (!isDeactivated)
                    {
                        active.Add(opp);
                    }
                }
                return active;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Could not check deactivated companies: " + ex.Message);
                return opportunities;
            }
        }

        // takes the name and location from the company's profile (by CompanyId),
        // if the profile can't be read (or a field is empty) the saved one stays
        private static async Task UseCurrentCompanyInfoAsync(List<Opportunity> opportunities)
        {
            try
            {
                var companies = JsonConvert.DeserializeObject<Dictionary<string, CompanySupervisor>>(await ReadAsync("CompanySupervisors"));
                if (companies == null) return;

                foreach (var opp in opportunities)
                {
                    if (opp.CompanyId == null || !companies.ContainsKey(opp.CompanyId)) continue;

                    CompanySupervisor company = companies[opp.CompanyId];
                    if (company == null) continue;

                    if (!string.IsNullOrWhiteSpace(company.CompanyName)) opp.CompanyName = company.CompanyName;
                    if (!string.IsNullOrWhiteSpace(company.Location)) opp.Location = company.Location;
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Could not read the company info: " + ex.Message);
            }
        }

        // builds the cards html.
        // everything is encoded so a ' or < in the data can't break the page
        private void RenderOpportunities(List<Opportunity> opportunities, List<Application> myApplications, string blocked)
        {
            var html = new StringBuilder();

            foreach (var opp in opportunities)
            {
                string majorsHtml = "";
                if (opp.Majors != null)
                {
                    foreach (var major in opp.Majors)
                    {
                        majorsHtml += $"<span class='badge bg-light text-dark me-1 mb-1 border'>{Encode(major)}</span>";
                    }
                }

                // did the student already apply here?
                Application mine = null;
                foreach (var app in myApplications)
                {
                    if (mine == null && app.OpportunityId == opp.Id)
                    {
                        mine = app;
                    }
                }

                string closedReason = opp.WhyClosed();

                string actionButtonOrBadge = "";
                if (mine != null)
                {
                    actionButtonOrBadge = $"<a href='../MyApplications/MyApplications.aspx' class='badge bg-secondary text-decoration-none'>Applied &middot; {Encode(mine.Status)}</a>";
                }
                else if (closedReason != null)
                {
                    actionButtonOrBadge = $"<span class='badge bg-danger'>{Encode(closedReason)}</span>";
                }
                else if (blocked == null)
                {
                    actionButtonOrBadge = $@"
                    <div class='d-flex gap-2'>
                        <a href='../ApplicationForm/ApplicationForm.aspx?opportunityId={HttpUtility.UrlEncode(opp.Id)}' class='btn btn-sm btn-primary'>Apply</a>
                    </div>";
                }

                // deadline, if there is one
                string deadlineHtml = "";
                if (opp.ApplicationDeadline > 0)
                {
                    string deadline = DateTimeOffset.FromUnixTimeMilliseconds(opp.ApplicationDeadline).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);   // InvariantCulture so arabic browsers don't get hijri dates
                    deadlineHtml = "<div class='mb-2 text-muted small'><i class='bi bi-calendar-event'></i> Deadline: <strong>" + deadline + "</strong></div>";
                }

                // training start date, older opportunities don't have one
                string startHtml = "";
                if (opp.TrainingStartDate > 0)
                {
                    string start = DateTimeOffset.FromUnixTimeMilliseconds(opp.TrainingStartDate).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
                    startHtml = "<div class='mb-2 text-muted small'><i class='bi bi-calendar-check'></i> Training starts: <strong>" + start + "</strong></div>";
                }

                // used by Opportunities.js for the search and the company filter
                string companyKey = Encode((opp.CompanyName ?? "").Trim().ToLowerInvariant());
                // the search box only looks at the title, the description and the location
                string searchText = Encode((opp.Title + " " + opp.Description + " " + opp.Location).ToLowerInvariant());

                html.Append($@"
                <div class='col-md-6 opp-item' data-company='{companyKey}' data-search='{searchText}'>
                    <div class='card opp-card h-100 p-3'>
                        <div class='card-body d-flex flex-column'>

                            <div class='mb-2'>
                                <span class='opp-company d-block fw-bold'>{Encode(opp.CompanyName)}</span>
                                <small class='text-muted'><i class='bi bi-geo-alt'></i> {Encode(opp.Location)}</small>
                            </div>

                            <h5 class='card-title mt-1'>{Encode(opp.Title)}</h5>
                            <p class='opp-desc mb-3'>{Encode(opp.Description)}</p>

                            <div class='mb-3'>
                                <small class='text-muted d-block mb-1 font-weight-bold'>Required Majors:</small>
                                <div class='d-flex flex-wrap'>
                                    {majorsHtml}
                                </div>
                            </div>

                            {deadlineHtml}
                            {startHtml}

                            <div class='mt-auto pt-2 border-top d-flex justify-content-between align-items-center'>
                                <span class='opp-tag'>{opp.SeatsLeft} Seats Left</span>
                                {actionButtonOrBadge}
                            </div>

                        </div>
                    </div>
                </div>");
            }

            oppGrid.InnerHtml = html.ToString();
            lblCount.Text = opportunities.Count + " opportunities";
            pnlEmpty.Visible = (opportunities.Count == 0);
        }

        private void ShowNotice(string message)
        {
            lblNotice.Text = HttpUtility.HtmlEncode(message);
            pnlNotice.Visible = true;
        }

        private static string Encode(string value)
        {
            return HttpUtility.HtmlEncode(value ?? "");
        }

        // same helpers as in ApplicationForm and MyApplications

        // Get returns null when firebase refuses the request (e.g. expired login)
        private static async Task<string> ReadAsync(string table, string id = null)
        {
            string json = await FirebaseDb.Get(table, id);
            if (json == null) throw new Exception("Firebase refused to read " + table + ".");
            return json;
        }

        // this student's applications, newest first
        private static async Task<List<Application>> LoadMyApplicationsAsync(string studentId)
        {
            // an empty table comes back as "null"
            var all = JsonConvert.DeserializeObject<Dictionary<string, Application>>(await ReadAsync("Applications"))
                      ?? new Dictionary<string, Application>();

            var mine = new List<Application>();
            foreach (var pair in all)
            {
                if (pair.Value == null || pair.Value.StudentId != studentId) continue;
                pair.Value.Id = pair.Key;
                mine.Add(pair.Value);
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