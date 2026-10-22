using System.Configuration;

namespace UniversityInternshipManagmentSystem.Config
{
    public static class AppConfig
    {
        public static string ApiKey = ConfigurationManager.AppSettings["ApiKey"];
        public static string DbUrl = ConfigurationManager.AppSettings["DbUrl"];

        public static string SignUpUrl =
            "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + ApiKey;

        public static string SignInUrl =
            "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + ApiKey;

        public static string PasswordResetUrl =
            "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=" + ApiKey;

        // Same address as PasswordResetUrl: sendOobCode sends the "confirm your email" email when requestType is VERIFY_EMAIL.
        public static string SendOobCodeUrl =
            "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=" + ApiKey;

        public static string AccountLookupUrl =
            "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=" + ApiKey;

        public static string UpdateAccountUrl =
            "https://identitytoolkit.googleapis.com/v1/accounts:update?key=" + ApiKey;
    }
}
