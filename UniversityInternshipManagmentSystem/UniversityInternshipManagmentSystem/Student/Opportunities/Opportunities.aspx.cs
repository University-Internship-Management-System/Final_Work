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
//using UniversityInternshipManagmentSystem.Student.Data;

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

            // 1) فاضي أو "null" → قائمة فاضية
            if (string.IsNullOrWhiteSpace(json) || json.Trim() == "null")
            {
                return list;
            }

            // 2) تحويل الـ JSON لقاموس: المفتاح = id الفرصة، القيمة = الفرصة
            var dict = JsonConvert.DeserializeObject<Dictionary<string, Opportunity>>(json);

            // 3) اللف على القاموس، تعبئة الـ Id، وتطبيق فلترة التخصص فقط
            if (dict != null)
            {
                foreach (var pair in dict)
                {
                    var opp = pair.Value;
                    if (opp == null) continue;
                    opp.Id = pair.Key;

                    // إضافة الفرصة للقائمة إذا كانت تقبل تخصص الطالب (بغض النظر عن حالتها open أو closed)
                    // AcceptsMajor ignores capital letters and extra spaces; an empty major matches nothing
                    if (opp.AcceptsMajor(studentMajor))
                    {
                        list.Add(opp);
                    }
                }
            }

            // 4) رجّعي القائمة المفلترة بناءً على التخصص
            return list;
        }

        private async Task LoadPageAsync()
        {
            string studentId = (string)(Session["dbRecordId"] ?? Session["userId"]);   // dbRecordId = the Students table key set by the login

            try
            {
                // جلب بيانات الطالب لمعرفة تخصصه (Major)
                var student = JsonConvert.DeserializeObject<Models.Student>(await ReadAsync("Students", studentId));
                List<Application> myApplications = await LoadMyApplicationsAsync(studentId);

                // A reason that stops every application (no profile, placed, no major, no CV) is shown once at the top
                string blocked = WhyStudentCannotApply(student, myApplications);
                if (blocked != null) ShowNotice(blocked);
                if (student == null) return;

                List<Opportunity> all = ParseOpportunities(await ReadAsync("Opportunities"), student.Major);

                // === تعبئة القائمة المنسدلة للشركات (بدون تكرار) ===
                ddlCompany.Items.Clear();
                ddlCompany.Items.Add(new ListItem("All companies", ""));

                var uniqueCompanies = all
                    .Where(o => !string.IsNullOrEmpty(o.CompanyName))
                    .Select(o => o.CompanyName)
                    .Distinct()
                    .ToList();

                foreach (var company in uniqueCompanies)
                {
                    ddlCompany.Items.Add(new ListItem(company, company));
                }

                RenderOpportunities(all, myApplications, blocked);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error loading opportunities: " + ex.Message);
                ShowNotice("Could not load the opportunities. Please refresh the page, or sign in again if this keeps happening.");
            }
        }

        // دالة مسؤولة عن بناء وعرض البطاقات (تم فصلها لتسهيل الاستخدام عند البحث والفلترة لاحقاً)
        // Every value from Firebase is HTML-encoded, so a name like McDonald's or a "<" in a description cannot break the page
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

                // Already applied → its status. Closed → the real reason. Otherwise Apply,
                // unless the student is blocked (the notice at the top of the page says why)
                var mine = myApplications.FirstOrDefault(a => a.OpportunityId == opp.Id);
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

                string deadlineFormatted = "";
                if (opp.ApplicationDeadline > 0)
                {
                    System.DateTimeOffset dateTimeOffset = System.DateTimeOffset.FromUnixTimeMilliseconds(opp.ApplicationDeadline);
                    deadlineFormatted = dateTimeOffset.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);   // always Gregorian, also in Arabic browsers
                }

                // The company filter compares this with the dropdown value, and the search box looks only in
                // the title, company, description, location and majors (not in the labels or buttons)
                string companyKey = Encode((opp.CompanyName ?? "").Trim().ToLowerInvariant());
                string searchText = Encode(string.Join(" ", opp.Title, opp.CompanyName, opp.Description, opp.Location,
                                                       string.Join(" ", opp.Majors ?? new List<string>())).ToLowerInvariant());

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

                            {(string.IsNullOrEmpty(deadlineFormatted) ? "" : $"<div class='mb-2 text-muted small'><i class='bi bi-calendar-event'></i> Deadline: <strong>{deadlineFormatted}</strong></div>")}

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

        // HtmlEncode also encodes ' so the value is safe inside the single-quoted attributes above
        private static string Encode(string value)
        {
            return HttpUtility.HtmlEncode(value ?? "");
        }

        // ===== The helpers below are the same in ApplicationForm.aspx.cs (and MyApplications.aspx.cs): change them together =====

        // FirebaseDb.Get returns null when Firebase refuses the request (for example an expired sign-in)
        private static async Task<string> ReadAsync(string table, string id = null)
        {
            string json = await FirebaseDb.Get(table, id);
            if (json == null) throw new Exception("Firebase refused to read " + table + ".");
            return json;
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