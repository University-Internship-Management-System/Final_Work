using System;
using System.IO;
using System.Web.Hosting;

namespace UniversityInternshipManagmentSystem.Config
{
    // Where the secret key files come from (the Firebase admin key and the Cloudinary key).
    //
    // For team TESTING they are normal files in App_Data/keys/ and they ARE committed, so everybody gets them with git pull
    // (like the SMTP settings in Web.config). For a real deployment, do not commit them: put the files somewhere private
    // and set the Windows variable that is named below; a variable always wins over the team file.
    //
    //   Firebase admin key   file: App_Data/keys/firebase-admin.json   variable: UIMS_FIREBASE_ADMIN_CREDENTIALS
    //   Cloudinary key       file: App_Data/keys/cloudinary.json       variable: UIMS_CLOUDINARY_CREDENTIALS
    public static class TeamKeys
    {
        public const string FirebaseAdminVariable = "UIMS_FIREBASE_ADMIN_CREDENTIALS";
        public const string FirebaseAdminFile = "firebase-admin.json";
        public const string CloudinaryVariable = "UIMS_CLOUDINARY_CREDENTIALS";
        public const string CloudinaryFile = "cloudinary.json";

        // The full path of the key file, or null when there is none on this PC
        public static string FindFile(string variableName, string teamFileName)
        {
            // On a hosting server the website may not be allowed to read the Windows user settings, so the normal variable comes first
            string fromVariable = Environment.GetEnvironmentVariable(variableName);
            if (string.IsNullOrWhiteSpace(fromVariable))
            {
                try { fromVariable = Environment.GetEnvironmentVariable(variableName, EnvironmentVariableTarget.User); }
                catch (System.Security.SecurityException) { }
                catch (UnauthorizedAccessException) { }
            }
            if (!string.IsNullOrWhiteSpace(fromVariable) && File.Exists(fromVariable)) return fromVariable;

            string teamFile = HostingEnvironment.MapPath("~/App_Data/keys/" + teamFileName);
            return teamFile != null && File.Exists(teamFile) ? teamFile : null;
        }
    }
}
