using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.UI;
using System.Web.UI.WebControls;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;

namespace UniversityInternshipManagmentSystem.Company.ManageOpportunities
{
    public partial class ManageOpportunities : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                if (Session["userId"] == null )
                {
                    Response.Redirect("~/login/Login.aspx", false);
                    return;
                }

                RegisterAsyncTask(new PageAsyncTask(LoadPageDataAsync));
            }
        }

        private async Task LoadPageDataAsync()
        {
            try
            {
                string currentCompanyId = (string) Session["userId"];

                // 1. جلب بيانات الشركة من جدول CompanySupervisors لتعبئة الاسم والموقع تلقائياً
                if (!string.IsNullOrEmpty(currentCompanyId))
                {
                    string companyJson = await FirebaseDb.Get("CompanySupervisors", currentCompanyId);
                    if (!string.IsNullOrEmpty(companyJson) && companyJson != "null")
                    {
                        var companyData = JsonConvert.DeserializeObject<Dictionary<string, object>>(companyJson);
                        if (companyData != null)
                        {
                            if (companyData.ContainsKey("CompanyName"))
                                txtCompanyName.Text = companyData["CompanyName"]?.ToString();

                            if (companyData.ContainsKey("Location"))
                                txtLocation.Text = companyData["Location"]?.ToString();
                        }
                    }
                }

                // قيم افتراضية احتياطية إذا لم يتم جلبها
                if (string.IsNullOrEmpty(txtCompanyName.Text)) txtCompanyName.Text = "My Company";
                if (string.IsNullOrEmpty(txtLocation.Text)) txtLocation.Text = "Amman, Jordan";

                // 2. جلب الفرص الخاصة بالشركة الحالية فقط وعرضها في الجدول
                string jsonResponse = await FirebaseDb.Get("Opportunities");
                var list = new List<Opportunity>();

                if (!string.IsNullOrEmpty(jsonResponse) && jsonResponse != "null")
                {
                    var dict = JsonConvert.DeserializeObject<Dictionary<string, Opportunity>>(jsonResponse);
                    if (dict != null)
                    {
                        foreach (var pair in dict)
                        {
                            var opp = pair.Value;
                            opp.Id = pair.Key;

                            if (!string.IsNullOrEmpty(currentCompanyId) && string.Equals(opp.CompanyId, currentCompanyId, StringComparison.OrdinalIgnoreCase))
                            {
                                list.Add(opp);
                            }
                        }
                    }
                }

                rptOpportunities.DataSource = list;
                rptOpportunities.DataBind();
                pnlEmpty.Visible = (list.Count == 0);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error loading data: " + ex.Message);
            }
        }

        protected async void btnSaveOpportunity_Click(object sender, EventArgs e)
        {
            try
            {
                string companyIdToSave = (Session["companyId"] ?? Session["userId"])?.ToString() ?? "";
                if (string.IsNullOrEmpty(companyIdToSave)) return;

                int seats = 5;
                int.TryParse(txtSeats.Text.Trim(), out seats);

                long deadlineTimestamp = 0;
                if (DateTime.TryParse(txtDeadline.Text.Trim(), out DateTime dt))
                {
                    deadlineTimestamp = ((DateTimeOffset)dt).ToUnixTimeMilliseconds();
                }

                // جمع التخصصات المحددة من الـ CheckBoxList
                List<string> selectedMajors = new List<string>();
                foreach (ListItem item in chkMajors.Items)
                {
                    if (item.Selected)
                    {
                        selectedMajors.Add(item.Value);
                    }
                }

                string editingId = hfEditingOpportunityId.Value;

                if (!string.IsNullOrEmpty(editingId))
                {
                    // === استخدام PATCH لتحديث الحقول المحددة فقط دون مسح باقي البيانات في السجل ===
                    var updatedFields = new
                    {
                        Title = txtTitle.Text.Trim(),
                        Description = txtDescription.Text.Trim(),
                        Seats = seats,
                        Majors = selectedMajors,
                        ApplicationDeadline = deadlineTimestamp,
                        CompanyName = txtCompanyName.Text.Trim(),
                        Location = txtLocation.Text.Trim()
                    };

                    await FirebaseDb.Patch("Opportunities", editingId, updatedFields);
                }
                else
                {
                    // === إضافة فرصة جديدة (Create) باستخدام POST ===
                    var newOpp = new Opportunity
                    {
                        CompanyId = companyIdToSave,
                        CompanyName = txtCompanyName.Text.Trim(),
                        Location = txtLocation.Text.Trim(),
                        Title = txtTitle.Text.Trim(),
                        Description = txtDescription.Text.Trim(),
                        Majors = selectedMajors,
                        Seats = seats,
                        Status = OpportunityStatus.Open,
                        CreatedAt = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds(),
                        ApplicationDeadline = deadlineTimestamp
                    };

                    await FirebaseDb.Post("Opportunities", newOpp);
                }

                Response.Redirect(Request.RawUrl, false);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error saving opportunity: " + ex.Message);
            }
        }

        protected async void rptOpportunities_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            string oppId = e.CommandArgument.ToString();

            try
            {
                if (e.CommandName == "ToggleStatus")
                {
                    string jsonResponse = await FirebaseDb.Get("Opportunities", oppId);
                    if (string.IsNullOrEmpty(jsonResponse) || jsonResponse == "null") return;

                    var opp = JsonConvert.DeserializeObject<Opportunity>(jsonResponse);
                    if (opp == null) return;

                    string newStatus = string.Equals(opp.Status, OpportunityStatus.Open, StringComparison.OrdinalIgnoreCase)
                                       ? OpportunityStatus.Closed
                                       : OpportunityStatus.Open;

                    await FirebaseDb.Patch("Opportunities", oppId, new { Status = newStatus });
                    Response.Redirect(Request.RawUrl, false);
                }
                else if (e.CommandName == "EditOpp")
                {
                    string jsonResponse = await FirebaseDb.Get("Opportunities", oppId);
                    if (string.IsNullOrEmpty(jsonResponse) || jsonResponse == "null") return;

                    var opp = JsonConvert.DeserializeObject<Opportunity>(jsonResponse);
                    if (opp == null) return;

                    hfEditingOpportunityId.Value = oppId;
                    txtTitle.Text = opp.Title;
                    txtDescription.Text = opp.Description;
                    txtSeats.Text = opp.Seats.ToString();

                    if (opp.ApplicationDeadline > 0)
                    {
                        txtDeadline.Text = DateTimeOffset.FromUnixTimeMilliseconds(opp.ApplicationDeadline).ToString("yyyy-MM-dd");
                    }

                    foreach (ListItem item in chkMajors.Items)
                    {
                        item.Selected = (opp.Majors != null && opp.Majors.Contains(item.Value));
                    }

                    // استخدام طريقة مضمونة لتشغيل السكريبت بعد تحميل الصفحة
                    ClientScript.RegisterStartupScript(this.GetType(), "OpenEditModal", "document.getElementById('opportunityModalLabel').innerText = 'Edit Opportunity'; openModal();", true);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error handling command: " + ex.Message);
            }
        }


        protected string FormatDate(object millisObj)
        {
            if (millisObj != null && long.TryParse(millisObj.ToString(), out long millis) && millis > 0)
            {
                return DateTimeOffset.FromUnixTimeMilliseconds(millis).ToString("yyyy-MM-dd");
            }
            return "-";
        }
    }
}