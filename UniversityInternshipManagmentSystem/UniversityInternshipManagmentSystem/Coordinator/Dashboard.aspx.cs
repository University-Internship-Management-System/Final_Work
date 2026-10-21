using System;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.Coordinator
{
    public partial class Dashboard : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            AuthHelper.RequireAuth(this, AuthHelper.RoleCoordinator);

            if (!IsPostBack)
            {
                litCoordinatorName.Text = Server.HtmlEncode(AuthHelper.UserName ?? "Training Coordinator");
            }
        }
    }
}
