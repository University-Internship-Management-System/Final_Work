using System;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.login
{
    /// <summary>
    /// Clears authenticated session state and redirects the user to the public home page.
    /// </summary>
    public partial class Logout : Page
    {
        private const string HomeUrl = "~/index.aspx";

        protected void Page_Load(object sender, EventArgs e)
        {
            AuthHelper.SignOut();
            Response.Redirect(HomeUrl, false);
            Context.ApplicationInstance.CompleteRequest();
        }
    }
}
