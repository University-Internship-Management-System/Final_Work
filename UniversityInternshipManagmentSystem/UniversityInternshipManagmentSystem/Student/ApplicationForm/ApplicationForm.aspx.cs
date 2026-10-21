using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using UniversityInternshipManagmentSystem.Config;

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
                    Response.Redirect("~/Default.aspx", false);
                    return;
                }

                string studentId = (string)Session["userId"];

                // إضافة await لانتظار تحميل البيانات من فايربيز بنجاح
                await LoadStudentDataToForm(studentId);
            }
        }
        private async Task LoadStudentDataToForm(string studentId)
        {
            try
            {
                // استخدام كلاس FirebaseDb الجاهز لجلب بيانات الطالب بناءً على الـ ID
                string jsonResponse = await FirebaseDb.Get("Students", studentId);

                if (!string.IsNullOrEmpty(jsonResponse) && jsonResponse != "null")
                {
                    // تحويل الـ JSON إلى كلاس Student الموجود في مجلد Models
                    var student = JsonConvert.DeserializeObject<UniversityInternshipManagmentSystem.Models.Student>(jsonResponse);

                    if (student != null)
                    {
                        // 1, 2, 3, 4: تعبئة المعلومات الأساسية
                        txtName.Text = student.Name ?? "";
                        txtMajor.Text = student.Major ?? "";
                        txtEmail.Text = student.Email ?? "";
                        txtPhone.Text = student.PhoneNumber ?? "";

                        // 5: دمج المهارات (SkillsList) وعرضها كنص مفصول بفواصل
                        if (student.SkillsList != null && student.SkillsList.Count > 0)
                        {
                            txtSkills.Text = string.Join(", ", student.SkillsList);
                        }

                        // 6 & 7: جلب روابط الـ CV والـ Portfolio المخزنة مسبقاً في ملفه الشخصي
                        txtCvUrl.Text = student.CvUrl ?? "";
                        txtPortfolioUrl.Text = student.PortfolioUrl ?? "";

                        // قفل الحقول لعدم التعديل
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
        // حدث زر تأكيد الطلب
        protected void btnSubmit_Click(object sender, EventArgs e)
        {
            string studentId = Session["userId"].ToString();
            string coverLetter = txtCoverLetter.Text.Trim();
            string cvUrl = txtCvUrl.Text.Trim();
            string portfolioUrl = txtPortfolioUrl.Text.Trim();

            // هنا يتم حفظ الطلب في جدول Applications في Firebase مع بيانات الطالب والـ CoverLetter
        }
    }

    }
