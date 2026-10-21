using System;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.Academic
{
    public partial class Dashboard : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            AuthHelper.RequireAuth(this, AuthHelper.RoleAcademic, AuthHelper.RoleCoordinator);

            if (!IsPostBack)
            {
                litAcademicName.Text = Server.HtmlEncode(AuthHelper.UserName ?? "Academic Supervisor");
            }
        }
    }
}
