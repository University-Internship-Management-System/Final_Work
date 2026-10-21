using System;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.login
{
    /// <summary>
    /// Clears authenticated session state and redirects the user safely to the unified login portal.
    /// </summary>
    public partial class Logout : Page
    {
        private const string LoginUrl = "~/login/Login.aspx";

        protected void Page_Load(object sender, EventArgs e)
        {
            AuthHelper.SignOut();
            Response.Redirect(LoginUrl + "?msg=" + Server.UrlEncode("You have been signed out successfully."), false);
            Context.ApplicationInstance.CompleteRequest();
        }
    }
}
