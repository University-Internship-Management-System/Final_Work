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
    }
}
