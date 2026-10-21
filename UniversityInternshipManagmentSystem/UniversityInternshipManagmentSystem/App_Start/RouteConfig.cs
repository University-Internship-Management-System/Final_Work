using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Routing;
using Microsoft.AspNet.FriendlyUrls;

namespace UniversityInternshipManagmentSystem
{
    public static class RouteConfig
    {
        public static void RegisterRoutes(RouteCollection routes)
        {
            var settings = new FriendlyUrlSettings();
            settings.AutoRedirectMode = RedirectMode.Off;

            routes.MapPageRoute("RootLoginRoute", "Login", "~/login/Login.aspx");
            routes.MapPageRoute("RootFirstLoginRoute", "FirstLogin", "~/login/FirstLogin.aspx");
            routes.MapPageRoute("RootLogoutRoute", "Logout", "~/login/Logout.aspx");

            routes.EnableFriendlyUrls(settings);
        }
    }
}
