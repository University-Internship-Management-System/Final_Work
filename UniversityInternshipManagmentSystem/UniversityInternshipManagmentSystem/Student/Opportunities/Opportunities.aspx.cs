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
        {// لما يجهز الـ login:
         // if (Session["userId"] == null) { Response.Redirect("~/Forms/LoginForm/LoginForm.aspx", false); return; }

            if (!IsPostBack)
            {
                RegisterAsyncTask(new PageAsyncTask(LoadPageAsync));
            }



        }
        private List<Opportunity> ParseOpportunities(string json)
        {
            var list = new List<Opportunity>();

            // 1) فاضي أو "null" → قائمة فاضية
            if (string.IsNullOrWhiteSpace(json) || json.Trim() == "null")
            {
                return list;
            }

            // 2) تحويل الـ JSON لقاموس: المفتاح = id الفرصة، القيمة = الفرصة
            var dict = JsonConvert.DeserializeObject<Dictionary<string, Opportunity>>(json);

            // 3) لفّي على القاموس وعبّي Id من المفتاح
            if (dict != null)
            {
                foreach (var pair in dict)
                {
                    pair.Value.Id = pair.Key;
                    list.Add(pair.Value);
                }
            }

            // 4) رجّعي القائمة
            return list;
        }

     
            private async Task LoadPageAsync()
        {
            string json = await FirebaseDb.Get("Opportunities");
            List<Opportunity> all = ParseOpportunities(json);

            oppGrid.InnerHtml = ""; // تفريغ الحاوية قبل الإضافة

            foreach (var opp in all)
            {
                // تحويل مصفوفة التخصصات إلى وسوم HTML
                string majorsHtml = "";
                if (opp.Majors != null)
                {
                    foreach (var major in opp.Majors)
                    {
                        majorsHtml += $"<span class='badge bg-light text-dark me-1 mb-1 border'>{major}</span>";
                    }
                }

                // التحقق مما إذا كانت الفرصة مغلقة أو انتهى موعدها
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

                // تحويل الـ Milliseconds الخاص بـ ApplicationDeadline إلى تاريخ بتنسيق سهل القراءة (مثلاً يوم/شهر/سنة)
                string deadlineFormatted = "";
                if (opp.ApplicationDeadline > 0)
                {
                    System.DateTimeOffset dateTimeOffset = System.DateTimeOffset.FromUnixTimeMilliseconds(opp.ApplicationDeadline);
                    deadlineFormatted = dateTimeOffset.ToString("yyyy-MM-dd"); // تنسيق التاريخ
                }

                // بناء الهيكل البرمجي للبطاقة
                oppGrid.InnerHtml += $@"
        <div class='col-md-6'>
            <div class='card opp-card h-100 p-3'>
                <div class='card-body d-flex flex-column'>
                    
                    <!-- الهيدر: اسم الشركة والموقع -->
                    <div class='mb-2'>
                        <span class='opp-company d-block fw-bold'>{opp.CompanyName}</span>
                        <small class='text-muted'><i class='bi bi-geo-alt'></i> {opp.Location}</small>
                    </div>

                    <!-- عنوان الفرصة والوصف -->
                    <h5 class='card-title mt-1'>{opp.Title}</h5>
                    <p class='opp-desc mb-3'>{opp.Description}</p>

                    <!-- قسم التخصصات المطلوبة -->
                    <div class='mb-3'>
                        <small class='text-muted d-block mb-1 font-weight-bold'>Required Majors:</small>
                        <div class='d-flex flex-wrap'>
                            {majorsHtml}
                        </div>
                    </div>

                    <!-- عرض آخر موعد للتقديم إذا توفر -->
                    {(string.IsNullOrEmpty(deadlineFormatted) ? "" : $"<div class='mb-2 text-muted small'><i class='bi bi-calendar-event'></i> Deadline: <strong>{deadlineFormatted}</strong></div>")}

                    <!-- أسفل البطاقة: المقاعد المتبقية وأزرار التقديم -->
                    <div class='mt-auto pt-2 border-top d-flex justify-content-between align-items-center'>
                        <span class='opp-tag'>{opp.SeatsLeft} Seats Left</span>
                        {actionButtonOrBadge}
                    </div>

                </div>
            </div>
        </div>";
            }

            lblCount.Text = all.Count + " opportunities";
            pnlEmpty.Visible = (all.Count == 0);
        
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
   