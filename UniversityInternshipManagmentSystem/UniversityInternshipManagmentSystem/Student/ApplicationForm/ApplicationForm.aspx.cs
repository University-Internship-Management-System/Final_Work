using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;

namespace UniversityInternshipManagmentSystem.Student.ApplicationForm
{
    public partial class ApplicationForm : System.Web.UI.Page
    {
        protected async void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                if (Session["userId"] == null)
                {
                    Response.Redirect("~/login/Login.aspx", false);
                    return;
                }

                string studentId = (string)(Session["dbRecordId"] ?? Session["userId"]);   // dbRecordId = the Students table key set by the login
                string opportunityId = Request.QueryString["opportunityId"];

                if (string.IsNullOrEmpty(opportunityId))
                {
                    Response.Redirect("../Opportunities/Opportunities.aspx", false);
                    return;
                }

                await LoadStudentDataToForm(studentId);
            }
        }

        private async Task LoadStudentDataToForm(string studentId)
        {
            try
            {
                string jsonResponse = await FirebaseDb.Get("Students", studentId);

                if (!string.IsNullOrEmpty(jsonResponse) && jsonResponse != "null")
                {
                    var student = JsonConvert.DeserializeObject<UniversityInternshipManagmentSystem.Models.Student>(jsonResponse);

                    if (student != null)
                    {
                        txtName.Text = student.Name ?? "";
                        txtMajor.Text = student.Major ?? "";
                        txtEmail.Text = student.Email ?? "";
                        txtPhone.Text = student.PhoneNumber ?? "";

                        if (student.SkillsList != null && student.SkillsList.Count > 0)
                        {
                            txtSkills.Text = string.Join(", ", student.SkillsList);
                        }

                        txtCvUrl.Text = student.CvUrl ?? "";
                        txtPortfolioUrl.Text = student.PortfolioUrl ?? "";

                        txtCvUrl.ReadOnly = true;
                        txtPortfolioUrl.ReadOnly = true;
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error loading student data: " + ex.Message);
            }
        }

        // حدث زر تأكيد الطلب الحقيقي
        protected async void btnSubmit_Click(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            string studentId = (Session["dbRecordId"] ?? Session["userId"]).ToString();
            string opportunityId = Request.QueryString["opportunityId"];

            if (string.IsNullOrEmpty(opportunityId))
            {
                return;
            }

            try
            {
                // 1. جلب معلومات الفرصة للتأكد من اسم الشركة وعنوان الفرصة و CompanyId
                string oppJson = await FirebaseDb.Get("Opportunities", opportunityId);
                if (!string.IsNullOrEmpty(oppJson) && oppJson != "null")
                {
                    var opportunity = JsonConvert.DeserializeObject<Opportunity>(oppJson);

                    if (opportunity != null)
                    {
                        // 2. إنشاء كائن Application مطابقة للـ Model الخاص بك
                        var newApplication = new UniversityInternshipManagmentSystem.Models.Application(
                            studentId: studentId,
                            opportunityId: opportunityId,
                            companyId: opportunity.CompanyId,
                            opportunityTitle: opportunity.Title,
                            companyName: opportunity.CompanyName,
                            cvUrl: txtCvUrl.Text.Trim(),
                            portfolioUrl: txtPortfolioUrl.Text.Trim(),
                            coverLetter: txtCoverLetter.Text.Trim(),
                            appliedAt: DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
                        );

                        // 3. حفظ الطلب في قاعدة بيانات Firebase تحت جدول "Applications"
                        var response = await FirebaseDb.Post("Applications", newApplication);

                        // 4. إظهار الـ Pop-up Modal (نجاح العملية) من خلال تشغيل السكريبت أو إظهار رسالة
                        if (response.IsSuccessStatusCode)
                            ScriptManager.RegisterStartupScript(this, GetType(), "saved", "window.applicationSaved = true;", true);
                        else
                            ScriptManager.RegisterStartupScript(this, GetType(), "failed", "alert('Could not save your application. Please try again.');", true);
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("Error submitting application: " + ex.Message);
            }
        }
    }
}