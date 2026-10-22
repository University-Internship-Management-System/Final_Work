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
        // dbRecordId = the Students table key set by the login (the same id ApplicationForm saves as StudentId)
        private string StudentId => (string)(Session["dbRecordId"] ?? Session["userId"]);

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
                // فلترة الطلبات الخاصة بالطالب الحالي فقط (الأحدث أولاً)
                await ShowApplicationsAsync(await LoadMyApplicationsAsync(StudentId));
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error loading applications: " + ex.Message);
                ShowMessage("Could not load your applications. Please refresh the page, or sign in again if this keeps happening.");
            }
        }

        // The table shows only when there are applications; otherwise the "No applications" panel shows
        private async Task ShowApplicationsAsync(List<Application> list)
        {
            await UseCurrentOpportunityNamesAsync(list);

            rptApplications.DataSource = list;
            rptApplications.DataBind();

            rptApplications.Visible = list.Count > 0;
            pnlEmpty.Visible = list.Count == 0;
        }

        // معالجة الأزرار داخل الجدول (مثل زر الـ Confirm وزر الـ Reject)
        protected async void rptApplications_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            try
            {
                // Fresh data, not what the page showed when it was opened (another tab may have changed it)
                List<Application> myApplications = await LoadMyApplicationsAsync(StudentId);
                string problem = await HandleOfferAsync(e.CommandName, Convert.ToString(e.CommandArgument), myApplications);

                if (problem == null)
                {
                    // إعادة تحميل الصفحة لتحديث الجدول
                    Response.Redirect(Request.RawUrl, false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }

                ShowMessage(problem);
                await ShowApplicationsAsync(myApplications);   // show the current statuses, so old buttons disappear
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error processing application action: " + ex.Message);
                ShowMessage("Something went wrong. Please refresh the page and try again.");
            }
        }

        // An application keeps a copy of the title and company from the day it was sent.
        // Show the opportunity's current ones instead (found by OpportunityId), so a company's edit shows here too.
        // The saved copy is only shown when the opportunity was deleted or cannot be read.
        private static async Task UseCurrentOpportunityNamesAsync(List<Application> list)
        {
            if (list.Count == 0) return;

            try
            {
                // One request for all opportunities, instead of one request per application
                var opportunities = JsonConvert.DeserializeObject<Dictionary<string, Opportunity>>(await ReadAsync("Opportunities"))
                                    ?? new Dictionary<string, Opportunity>();

                foreach (var app in list)
                {
                    Opportunity opportunity;
                    if (app.OpportunityId != null && opportunities.TryGetValue(app.OpportunityId, out opportunity) && opportunity != null)
                    {
                        if (!string.IsNullOrWhiteSpace(opportunity.Title)) app.OpportunityTitle = opportunity.Title;
                        if (!string.IsNullOrWhiteSpace(opportunity.CompanyName)) app.CompanyName = opportunity.CompanyName;
                    }
                }
            }
            catch (Exception ex)
            {
                // The list still shows, with the saved copies
                System.Diagnostics.Debug.WriteLine("Could not read the current opportunity names: " + ex.Message);
            }
        }

        // Confirms or rejects one offer. Returns null when it worked, otherwise why it was refused.
        private async Task<string> HandleOfferAsync(string command, string applicationId, List<Application> myApplications)
        {
            // Looking only inside this student's own applications is the ownership check
            var offer = myApplications.FirstOrDefault(a => a.Id == applicationId);

            // An offer can only be confirmed or rejected while it is still Accepted
            if (offer == null || offer.Status != ApplicationStatus.Accepted)
                return "This offer can no longer be changed. The list below shows its current status.";

            if (command == "RejectOffer")
            {
                // إذا أراد الطالب رفض العرض المقدم من الشركة (Accepted -> Rejected): PATCH changes only these two fields
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

            var student = JsonConvert.DeserializeObject<Models.Student>(await ReadAsync("Students", StudentId));
            if (student == null) return "Your student profile could not be found. Please contact the coordinator.";
            if (IsPlaced(student, myApplications)) return "You have already confirmed a training, so you cannot confirm another offer.";

            var opportunity = await LoadOpportunityAsync(offer.OpportunityId);
            if (opportunity == null) return "This opportunity no longer exists, so the offer cannot be confirmed.";

            // A seat = one entry in ConfirmedStudents (SeatsLeft is calculated from it)
            if (opportunity.SeatsLeft <= 0) return "There are no seats left in this opportunity, so the offer cannot be confirmed.";

            if (!await ConfirmOfferAsync(StudentId, offer, opportunity, myApplications))
                return "Could not confirm the offer. Please try again.";

            // Tell the student and the company (Config/Notify.cs does nothing when email is not set up)
            Notify.OfferConfirmed(student.Name, student.Email, opportunity.Title, opportunity.CompanyName, opportunity.CompanyId);
            return null;
        }

        // Saves the whole confirmation in ONE request to the database root, so Firebase stores all of it or none of it:
        // 1. the offer becomes Confirmed  2. the student takes a seat  3. the student is linked to the company
        // 4. the student's other open applications are cancelled automatically
        private static async Task<bool> ConfirmOfferAsync(string studentId, Application offer, Opportunity opportunity, List<Application> myApplications)
        {
            var changes = new Dictionary<string, object>
            {
                ["Applications/" + offer.Id + "/Status"] = ApplicationStatus.Confirmed,
                ["Applications/" + offer.Id + "/ConfirmedAt"] = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds(),
                ["Opportunities/" + opportunity.Id + "/ConfirmedStudents/" + studentId] = true,
                ["Students/" + studentId + "/CompanyId"] = opportunity.CompanyId
            };

            // رفض أو إلغاء باقي طلبات الطالب الأخرى تلقائياً
            foreach (var other in myApplications)
            {
                if (other.Id != offer.Id &&
                    (other.Status == ApplicationStatus.Pending || other.Status == ApplicationStatus.Accepted))
                {
                    changes["Applications/" + other.Id + "/Status"] = ApplicationStatus.Rejected;
                    changes["Applications/" + other.Id + "/RejectionReason"] = "Automatically cancelled due to confirming another offer.";
                }
            }

            // "" = the database root, so one PATCH can change the Applications, Opportunities and Students tables together
            var response = await FirebaseDb.Patch("", null, changes);
            return response.IsSuccessStatusCode;
        }

        // تنسيق ألوان الحالات في الجدول
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

        // تنسيق التاريخ من ميللي ثانية إلى تاريخ مقروء (always Gregorian, also in Arabic browsers)
        protected string FormatDate(object millisObj)
        {
            if (millisObj != null && long.TryParse(millisObj.ToString(), out long millis) && millis > 0)
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

        // ===== The helpers below are the same in Opportunities.aspx.cs and ApplicationForm.aspx.cs: change them together =====

        // FirebaseDb.Get returns null when Firebase refuses the request (for example an expired sign-in)
        private static async Task<string> ReadAsync(string table, string id = null)
        {
            string json = await FirebaseDb.Get(table, id);
            if (json == null) throw new Exception("Firebase refused to read " + table + ".");
            return json;
        }

        // One opportunity with its Id filled in, or null when it does not exist
        private static async Task<Opportunity> LoadOpportunityAsync(string opportunityId)
        {
            var opportunity = JsonConvert.DeserializeObject<Opportunity>(await ReadAsync("Opportunities", opportunityId));
            if (opportunity != null) opportunity.Id = opportunityId;
            return opportunity;
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
    }
}