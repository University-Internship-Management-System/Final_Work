using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;

namespace UniversityInternshipManagmentSystem.Student.Opportunities
{
    public partial class Opportunities : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/Default.aspx", false);
                return;
            }

            if (!IsPostBack)
            {
                RegisterAsyncTask(new PageAsyncTask(LoadPageAsync));
            }
        }

        private List<Opportunity> ParseOpportunities(string json, string studentMajor = null)
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
                    opp.Id = pair.Key;

                    // إذا تم تمرير تخصص الطالب، نتحقق فقط أن تخصصه ضمن تخصصات الفرصة (Majors)
                    bool matchesMajor = string.IsNullOrEmpty(studentMajor) ||
                                        (opp.Majors != null && opp.Majors.Contains(studentMajor));

                    // إضافة الفرصة للقائمة إذا تطابق التخصص (بغض النظر عن حالتها open أو closed)
                    if (matchesMajor)
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
            string studentId = (string)Session["userId"];

            // جلب بيانات الطالب لمعرفة تخصصه (Major)
            string studentJson = await FirebaseDb.Get("Students", studentId);
            var student = JsonConvert.DeserializeObject<UniversityInternshipManagmentSystem.Models.Student>(studentJson);
            string studentMajor = student?.Major ?? "";

            string json = await FirebaseDb.Get("Opportunities");
            List<Opportunity> all = ParseOpportunities(json, studentMajor);

            // === تعبئة القائمة المنسدلة للشركات (بدون تكرار) ===
            if (!IsPostBack || ddlCompany.Items.Count <= 1)
            {
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
            }

            RenderOpportunities(all);
        }

        // دالة مسؤولة عن بناء وعرض البطاقات (تم فصلها لتسهيل الاستخدام عند البحث والفلترة لاحقاً)
        private void RenderOpportunities(List<Opportunity> opportunities)
        {
            oppGrid.InnerHtml = ""; // تفريغ الحاوية قبل الإضافة

            foreach (var opp in opportunities)
            {
                string majorsHtml = "";
                if (opp.Majors != null)
                {
                    foreach (var major in opp.Majors)
                    {
                        majorsHtml += $"<span class='badge bg-light text-dark me-1 mb-1 border'>{major}</span>";
                    }
                }

                bool isClosedOrExpired = !opp.IsOpenForApplications;

                string actionButtonOrBadge = "";
                if (isClosedOrExpired)
                {
                    actionButtonOrBadge = "<span class='badge bg-danger'>Closed / Deadline Passed</span>";
                }
                else
                {
                    actionButtonOrBadge = $@"
                    <div class='d-flex gap-2'>
                        <a href='../ApplicationForm/ApplicationForm.aspx?opportunityId={opp.Id}' class='btn btn-sm btn-primary'>Apply</a>
                    </div>";
                }

                string deadlineFormatted = "";
                if (opp.ApplicationDeadline > 0)
                {
                    System.DateTimeOffset dateTimeOffset = System.DateTimeOffset.FromUnixTimeMilliseconds(opp.ApplicationDeadline);
                    deadlineFormatted = dateTimeOffset.ToString("yyyy-MM-dd");
                }

                oppGrid.InnerHtml += $@"
                <div class='col-md-6 opp-item' data-company='{opp.CompanyName?.ToLower()}'>
                    <div class='card opp-card h-100 p-3'>
                        <div class='card-body d-flex flex-column'>
                            
                            <div class='mb-2'>
                                <span class='opp-company d-block fw-bold'>{opp.CompanyName}</span>
                                <small class='text-muted'><i class='bi bi-geo-alt'></i> {opp.Location}</small>
                            </div>

                            <h5 class='card-title mt-1'>{opp.Title}</h5>
                            <p class='opp-desc mb-3'>{opp.Description}</p>

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
                </div>";
            }

            lblCount.Text = opportunities.Count + " opportunities";
            pnlEmpty.Visible = (opportunities.Count == 0);
        }

        protected string BadgeClass(object status)
        {
            switch ((Convert.ToString(status) ?? "").ToLower())
            {
                case "accepted":
                case "confirmed": return "badge-approved";
                case "rejected": return "badge-rejected";
                case "pending": return "badge-pending";
                default: return "badge-submitted";
            }
        }
    }
}