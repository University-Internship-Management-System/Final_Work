using System;
using System.Linq;
using System.Web;
using System.Web.UI;

namespace UniversityInternshipManagmentSystem.Config
{
    public static class AuthHelper
    {
        public const string RoleStudent = "student";
        public const string RoleCompany = "company";
        public const string RoleAcademic = "academic";
        public const string RoleCoordinator = "coordinator";

        public static bool IsAuthenticated
        {
            get
            {
                var session = HttpContext.Current?.Session;
                return session != null && session["userId"] != null && !string.IsNullOrEmpty(session["userId"].ToString());
            }
        }

        public static string UserId => HttpContext.Current?.Session?["userId"] as string;
        public static string UserEmail => HttpContext.Current?.Session?["email"] as string;
        public static string UserName => HttpContext.Current?.Session?["name"] as string;
        public static string UserRole => (HttpContext.Current?.Session?["role"] as string)?.ToLowerInvariant();
        public static string IdToken => HttpContext.Current?.Session?["idToken"] as string;

        public static bool IsFirstLogin
        {
            get
            {
                var val = HttpContext.Current?.Session?["firstLogin"];
                if (val == null) return false;
                if (val is bool b) return b;
                bool parsed;
                return bool.TryParse(val.ToString(), out parsed) && parsed;
            }
        }

        public static string NormalizeRole(string role)
        {
            if (string.IsNullOrWhiteSpace(role))
                return RoleStudent;

            role = role.Trim().ToLowerInvariant();

            if (role.Contains("student"))
                return RoleStudent;
            if (role.Contains("company"))
                return RoleCompany;
            if (role.Contains("academic"))
                return RoleAcademic;
            if (role.Contains("coordinator") || role.Contains("admin"))
                return RoleCoordinator;

            return role;
        }

        public static string GetDashboardUrl(string role)
        {
            string norm = NormalizeRole(role);
            switch (norm)
            {
                case RoleStudent:
                    return "~/Student/StudentDashboardPage/Dashboard.aspx";
                case RoleCompany:
                    return "~/Company/CompanyDashboard/Dashboard.aspx";
                case RoleAcademic:
                    return "~/Academic/Dashboard.aspx";
                case RoleCoordinator:
                    return "~/Coordinator/CoordinatorDashbord/CoordinatorDashbord.aspx";
                default:
                    return "~/Default.aspx";
            }
        }

        public static void SetUserSession(string userId, string idToken, string email, string name, string role, bool firstLogin)
        {
            var session = HttpContext.Current.Session;
            session["userId"] = userId;
            session["idToken"] = idToken;
            session["email"] = email;
            session["name"] = string.IsNullOrWhiteSpace(name) ? email.Split('@')[0] : name;
            session["role"] = NormalizeRole(role);
            session["firstLogin"] = firstLogin;
        }

        public static void UpdateFirstLoginSession(bool firstLogin)
        {
            var session = HttpContext.Current?.Session;
            if (session != null)
            {
                session["firstLogin"] = firstLogin;
            }
        }

        public static void SignOut()
        {
            var session = HttpContext.Current?.Session;
            if (session != null)
            {
                session.Clear();
                session.Abandon();
            }
        }

        public static void RequireAuth(Page page, params string[] allowedRoles)
        {
            if (!IsAuthenticated)
            {
                string returnUrl = page.Request.AppRelativeCurrentExecutionFilePath;
                page.Response.Redirect("~/login/Login.aspx?ReturnUrl=" + HttpUtility.UrlEncode(returnUrl), false);
                HttpContext.Current?.ApplicationInstance.CompleteRequest();
                return;
            }

            string currentPath = page.Request.AppRelativeCurrentExecutionFilePath ?? "";
            bool isFirstLoginPage = currentPath.IndexOf("FirstLogin", StringComparison.OrdinalIgnoreCase) >= 0;

            if (IsFirstLogin && !isFirstLoginPage)
            {
                page.Response.Redirect("~/login/FirstLogin.aspx", false);
                HttpContext.Current?.ApplicationInstance.CompleteRequest();
                return;
            }

            if (allowedRoles != null && allowedRoles.Length > 0)
            {
                string currentRole = UserRole;
                bool authorized = allowedRoles.Any(r => NormalizeRole(r).Equals(currentRole, StringComparison.OrdinalIgnoreCase));
                if (!authorized)
                {
                    page.Response.Redirect(GetDashboardUrl(currentRole), false);
                    HttpContext.Current?.ApplicationInstance.CompleteRequest();
                }
            }
        }

        public static string GetFriendlyAuthError(string rawError)
        {
            if (string.IsNullOrWhiteSpace(rawError))
                return "An unexpected error occurred during login. Please try again.";

            string upper = rawError.ToUpperInvariant();

            if (upper.Contains("INVALID_LOGIN_CREDENTIALS") || upper.Contains("INVALID_PASSWORD") || upper.Contains("EMAIL_NOT_FOUND"))
                return "Invalid email address or password. Please verify and try again.";

            if (upper.Contains("USER_DISABLED"))
                return "This account has been disabled by the administrator.";

            if (upper.Contains("TOO_MANY_ATTEMPTS_TRY_LATER"))
                return "Too many failed attempts. Temporary security lockout active. Please try again later.";

            if (upper.Contains("INVALID_EMAIL"))
                return "The email address format is invalid.";

            if (upper.Contains("WEAK_PASSWORD"))
                return "Password is too weak. It must be at least 6 characters long.";

            if (upper.Contains("TOKEN_EXPIRED") || upper.Contains("USER_NOT_FOUND"))
                return "Your session has expired. Please sign in again.";

            return "Authentication Error: " + rawError;
        }

        public static bool IsLocalUrl(string url)
        {
            if (string.IsNullOrEmpty(url)) return false;
            if (url.StartsWith("~/")) return true;
            if (url.StartsWith("/") && !url.StartsWith("//") && !url.StartsWith("/\\")) return true;
            return false;
        }
    }
}
