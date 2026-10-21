using System;
using System.Web;
using System.Web.Optimization;
using System.Web.Routing;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem
{
    public class Global : HttpApplication
    {
        void Application_Start(object sender, EventArgs e)
        {
            // Code that runs on application startup
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);
        }

        protected void Application_PostAcquireRequestState(object sender, EventArgs e)
        {
            var app = (HttpApplication)sender;
            var context = app.Context;
            var session = context.Session;

            if (session == null)
                return;

            string path = context.Request.AppRelativeCurrentExecutionFilePath ?? "";

            // Skip static files and handlers
            if (path.EndsWith(".css", StringComparison.OrdinalIgnoreCase) ||
                path.EndsWith(".js", StringComparison.OrdinalIgnoreCase) ||
                path.EndsWith(".map", StringComparison.OrdinalIgnoreCase) ||
                path.EndsWith(".png", StringComparison.OrdinalIgnoreCase) ||
                path.EndsWith(".jpg", StringComparison.OrdinalIgnoreCase) ||
                path.EndsWith(".jpeg", StringComparison.OrdinalIgnoreCase) ||
                path.EndsWith(".gif", StringComparison.OrdinalIgnoreCase) ||
                path.EndsWith(".svg", StringComparison.OrdinalIgnoreCase) ||
                path.EndsWith(".ico", StringComparison.OrdinalIgnoreCase) ||
                path.EndsWith(".woff", StringComparison.OrdinalIgnoreCase) ||
                path.EndsWith(".woff2", StringComparison.OrdinalIgnoreCase) ||
                path.EndsWith(".ttf", StringComparison.OrdinalIgnoreCase) ||
                path.EndsWith(".axd", StringComparison.OrdinalIgnoreCase))
            {
                return;
            }

            bool isAuth = AuthHelper.IsAuthenticated;
            bool isFirstLogin = isAuth && AuthHelper.IsFirstLogin;

            bool isLoginArea = path.IndexOf("/login/", StringComparison.OrdinalIgnoreCase) >= 0;
            bool isStudentArea = path.StartsWith("~/Student", StringComparison.OrdinalIgnoreCase);
            bool isCompanyArea = path.StartsWith("~/Company", StringComparison.OrdinalIgnoreCase);
            bool isAcademicArea = path.StartsWith("~/Academic", StringComparison.OrdinalIgnoreCase);
            bool isCoordinatorArea = path.StartsWith("~/Coordinator", StringComparison.OrdinalIgnoreCase);
            bool isProtectedArea = isStudentArea || isCompanyArea || isAcademicArea || isCoordinatorArea;

            bool isFirstLoginPage = path.IndexOf("FirstLogin", StringComparison.OrdinalIgnoreCase) >= 0;
            bool isLoginPage = (path.IndexOf("Login", StringComparison.OrdinalIgnoreCase) >= 0) && !isFirstLoginPage;
            bool isLogoutPage = path.IndexOf("Logout", StringComparison.OrdinalIgnoreCase) >= 0;

            // 1. Unauthenticated user trying to access protected role area -> redirect to Login
            if (isProtectedArea && !isAuth)
            {
                context.Response.Redirect("~/login/Login.aspx?ReturnUrl=" + HttpUtility.UrlEncode(path), false);
                context.ApplicationInstance.CompleteRequest();
                return;
            }

            // 2. First login enforcement: If authenticated but first login is pending, FORCE FirstLogin.aspx
            if (isAuth && isFirstLogin)
            {
                if (!isFirstLoginPage && !isLogoutPage)
                {
                    context.Response.Redirect("~/login/FirstLogin.aspx", false);
                    context.ApplicationInstance.CompleteRequest();
                    return;
                }
            }

            // 3. User with completed first login trying to access FirstLogin.aspx -> redirect to their dashboard
            if (isAuth && !isFirstLogin && isFirstLoginPage)
            {
                context.Response.Redirect(AuthHelper.GetDashboardUrl(AuthHelper.UserRole), false);
                context.ApplicationInstance.CompleteRequest();
                return;
            }

            // 4. Authenticated user visiting Login.aspx -> redirect to dashboard (or FirstLogin)
            if (isAuth && isLoginPage)
            {
                if (isFirstLogin)
                {
                    context.Response.Redirect("~/login/FirstLogin.aspx", false);
                }
                else
                {
                    context.Response.Redirect(AuthHelper.GetDashboardUrl(AuthHelper.UserRole), false);
                }
                context.ApplicationInstance.CompleteRequest();
                return;
            }

            // 5. Role-based authorization: Prevent users from visiting other roles' pages
            if (isAuth && !isFirstLogin && isProtectedArea)
            {
                string role = AuthHelper.UserRole;
                bool isAuthorized = false;

                if (isStudentArea && (role == AuthHelper.RoleStudent || role == AuthHelper.RoleCoordinator))
                {
                    isAuthorized = true;
                }
                else if (isCompanyArea && (role == AuthHelper.RoleCompany || role == AuthHelper.RoleCoordinator))
                {
                    isAuthorized = true;
                }
                else if (isAcademicArea && (role == AuthHelper.RoleAcademic || role == AuthHelper.RoleCoordinator))
                {
                    isAuthorized = true;
                }
                else if (isCoordinatorArea && role == AuthHelper.RoleCoordinator)
                {
                    isAuthorized = true;
                }

                if (!isAuthorized)
                {
                    // Redirect to the user's appropriate dashboard
                    context.Response.Redirect(AuthHelper.GetDashboardUrl(role), false);
                    context.ApplicationInstance.CompleteRequest();
                    return;
                }
            }
        }
    }
}
