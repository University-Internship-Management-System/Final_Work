using System;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.Company
{
    public partial class Dashboard : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            AuthHelper.RequireAuth(this, AuthHelper.RoleCompany, AuthHelper.RoleCoordinator);

            if (!IsPostBack)
            {
                litSupervisorName.Text = Server.HtmlEncode(AuthHelper.UserName ?? "Company Mentor");
            }
        }
    }
}
