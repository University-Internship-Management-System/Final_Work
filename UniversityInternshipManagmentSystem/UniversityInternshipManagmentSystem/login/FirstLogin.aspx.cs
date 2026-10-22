using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.login
{
    /// <summary>
    /// Forces first-time users to set a permanent password before gaining access
    /// to role-specific system dashboards.
    /// </summary>
    public partial class FirstLogin : Page
    {
        #region Fields & Constants

        private static readonly HttpClient HttpClient = new HttpClient();

        private const int MinimumPasswordLength = 6;
        private const string LoginUrl = "~/login/Login.aspx";

        private static readonly string[] ProfileTables = new[]
        {
            "Users",
            "Students",
            "AcademicSupervisors",
            "CompanySupervisors",
            "Admins",
            "Coordinators"
        };

        #endregion

        #region Page Lifecycle

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                ValidateAccessPreconditions();
            }
        }

        #endregion

        #region User Actions

        /// <summary>
        /// Validates and updates user password in Firebase Auth and clears the FirstLogin flag in Realtime Database.
        /// </summary>
        protected async void btnSavePassword_Click(object sender, EventArgs e)
        {
            string newPassword = txtNewPassword.Text;
            string confirmPassword = txtConfirmPassword.Text;

            // 1. Client input validation
            if (!ValidatePasswordInput(newPassword, confirmPassword))
            {
                return;
            }

            string idToken = AuthHelper.IdToken;
            string uid = AuthHelper.UserId;

            // 2. Handle demo mock accounts
            if (uid != null && uid.StartsWith("demo-", StringComparison.OrdinalIgnoreCase))
            {
                if (uid == "demo-student-new")
                {
                    Session["demo_student_new_pwd"] = newPassword;
                    Session["demo_student_new_pwd_set"] = true;
                }
                else if (uid == "demo-student1")
                {
                    Session["demo_student1_pwd"] = newPassword;
                    Session["demo_student1_pwd_set"] = true;
                }
                else if (uid == "demo-student5")
                {
                    Session["demo_student5_pwd"] = newPassword;
                    Session["demo_student5_pwd_set"] = true;
                }
                else if (uid == "demo-company2")
                {
                    Session["demo_supervisor2_pwd"] = newPassword;
                    Session["demo_supervisor2_pwd_set"] = true;
                }

                CompleteFirstLoginSession();
                RedirectAfterFirstLogin();
                return;
            }

            // 3. Verify session validity
            if (string.IsNullOrEmpty(idToken) || string.IsNullOrEmpty(uid))
            {
                DisplayAlert("Your session has expired. Please sign in again to continue.", "alert-warning");
                return;
            }

            // 4. Update password via Firebase Auth REST
            await UpdatePasswordInFirebaseAsync(uid, idToken, newPassword);
        }

        /// <summary>
        /// Allows the user to abandon the password update session and return to Login.
        /// </summary>
        protected void btnCancelLogout_Click(object sender, EventArgs e)
        {
            AuthHelper.SignOut();
            SafeRedirect("~/index.aspx");
        }

        #endregion

        #region Firebase Update Logic

        private async Task UpdatePasswordInFirebaseAsync(string uid, string idToken, string newPassword)
        {
            try
            {
                var payload = new
                {
                    idToken = idToken,
                    password = newPassword,
                    returnSecureToken = true
                };

                var content = new StringContent(JsonConvert.SerializeObject(payload), Encoding.UTF8, "application/json");
                var response = await HttpClient.PostAsync(AppConfig.UpdateAccountUrl, content);
                string responseJson = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    string rawError = ExtractErrorMessage(responseJson);
                    DisplayAlert(AuthHelper.GetFriendlyAuthError(rawError), "alert-danger");
                    return;
                }

                // Refresh session idToken if Firebase returned a new secure token
                TryRefreshSessionToken(responseJson, ref idToken);

                // Update FirstLogin flag to false across database tables
                await ClearFirstLoginFlagInDatabaseAsync(uid, idToken);

                // Update active user session state
                CompleteFirstLoginSession();

                // Proceed to role dashboard or preserved return URL
                RedirectAfterFirstLogin();
            }
            catch (System.Threading.ThreadAbortException)
            {
                // Normal ASP.NET thread termination during redirect
            }
            catch (Exception ex)
            {
                DisplayAlert("Error updating password: " + Server.HtmlEncode(ex.Message), "alert-danger");
            }
        }

        private async Task ClearFirstLoginFlagInDatabaseAsync(string uid, string idToken)
        {
            var updatePayload = new { FirstLogin = false, firstLogin = false };

            string recordId = Session["dbRecordId"] as string;
            string tableName = Session["dbTable"] as string;

            // Direct update to known matched table and record id (e.g. "Students/student_001")
            if (!string.IsNullOrEmpty(recordId) && !string.IsNullOrEmpty(tableName))
            {
                try
                {
                    await FirebaseDb.Patch(tableName, recordId, updatePayload, idToken);
                }
                catch
                {
                    // Continue with general pass
                }
            }

            // Also patch under uid across standard tables
            foreach (string table in ProfileTables)
            {
                try
                {
                    string existing = await FirebaseDb.Get(table, uid, idToken);
                    if (string.IsNullOrEmpty(existing) || existing.Trim() == "null") continue;   // no record here: do not create an empty one

                    await FirebaseDb.Patch(table, uid, updatePayload, idToken);
                }
                catch
                {
                    // Proceed to next table
                }
            }
        }

        #endregion

        #region Helper & Validation Methods

        private void SafeRedirect(string url)
        {
            Response.Redirect(url, false);
            Context.ApplicationInstance.CompleteRequest();
        }

        private void RedirectAfterFirstLogin()
        {
            string postReturnUrl = Session["PostFirstLoginReturnUrl"] as string;
            Session.Remove("PostFirstLoginReturnUrl");

            if (!string.IsNullOrEmpty(postReturnUrl) && AuthHelper.IsLocalUrl(postReturnUrl))
            {
                SafeRedirect(postReturnUrl);
                return;
            }

            SafeRedirect(AuthHelper.GetDashboardUrl(AuthHelper.UserRole));
        }

        private void ValidateAccessPreconditions()
        {
            if (!AuthHelper.IsAuthenticated)
            {
                SafeRedirect(LoginUrl);
                return;
            }

            if (!AuthHelper.IsFirstLogin)
            {
                SafeRedirect(AuthHelper.GetDashboardUrl(AuthHelper.UserRole));
            }
        }

        private bool ValidatePasswordInput(string newPassword, string confirmPassword)
        {
            if (string.IsNullOrEmpty(newPassword) || string.IsNullOrEmpty(confirmPassword))
            {
                DisplayAlert("Please enter and confirm your new password.", "alert-danger");
                return false;
            }

            if (newPassword != confirmPassword)
            {
                DisplayAlert("Passwords do not match. Please verify and re-enter.", "alert-danger");
                return false;
            }

            if (newPassword.Length < MinimumPasswordLength)
            {
                DisplayAlert($"Password must be at least {MinimumPasswordLength} characters long.", "alert-danger");
                return false;
            }

            return true;
        }

        private void TryRefreshSessionToken(string responseJson, ref string idToken)
        {
            try
            {
                var updatedAuth = JObject.Parse(responseJson);
                string newToken = updatedAuth["idToken"]?.ToString();
                if (!string.IsNullOrEmpty(newToken))
                {
                    Session["idToken"] = newToken;
                    idToken = newToken;
                }
            }
            catch
            {
                // Fall back to original token
            }
        }

        private void CompleteFirstLoginSession()
        {
            AuthHelper.UpdateFirstLoginSession(false);
        }

        private void DisplayAlert(string message, string alertCssClass)
        {
            pnlAlert.CssClass = "alert small d-flex align-items-center gap-2 mb-3 " + alertCssClass;
            litAlertMessage.Text = message;
            pnlAlert.Visible = true;
        }

        private static string ExtractErrorMessage(string rawJson)
        {
            try
            {
                var errObj = JObject.Parse(rawJson);
                return errObj["error"]?["message"]?.ToString() ?? rawJson;
            }
            catch
            {
                return rawJson;
            }
        }

        #endregion
    }
}
