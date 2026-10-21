using System;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;

namespace UniversityInternshipManagmentSystem.Student.Dashboard
{
    public partial class Dashboard : Page
    {
        // Student domain model reference
        protected Models.Student CurrentStudent { get; private set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            // 1. Enforce Student authentication
            AuthHelper.RequireAuth(this, AuthHelper.RoleStudent, AuthHelper.RoleCoordinator);

            if (!IsPostBack)
            {
                LoadStudentData();
            }
        }

        /// <summary>
        /// Loads student profile and field training progress using the Student Model.
        /// </summary>
        private void LoadStudentData()
        {
            // Instantiate and populate the Student Model
            CurrentStudent = new Models.Student
            {
                Name = AuthHelper.UserName,
                Email = AuthHelper.UserEmail,
                UniEmail = AuthHelper.UserEmail,
                Major = "Software Engineering",
                GPA = 3.65,
                CompanyId = "Umniah Telecom - Innovation & Cloud Center",
                AcademicSupervisorId = "Dr. Mohammad Al-Radaideh"
            };

            // Bind model properties to web form controls
            litStudentName.Text = Server.HtmlEncode(CurrentStudent.Name);
            litUniEmail.Text = Server.HtmlEncode(CurrentStudent.UniEmail);
            litMajor.Text = Server.HtmlEncode(CurrentStudent.Major);
            litGPA.Text = CurrentStudent.GPA.ToString("0.00");
            litCompany.Text = Server.HtmlEncode(CurrentStudent.CompanyId);
            litSupervisor.Text = Server.HtmlEncode(CurrentStudent.AcademicSupervisorId);
        }
    }
}
