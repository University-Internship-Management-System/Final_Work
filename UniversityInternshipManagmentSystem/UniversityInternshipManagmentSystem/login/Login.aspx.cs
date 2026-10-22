using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.login
{
    /// <summary>
    /// Unified authentication portal supporting Firebase Auth, role redirection,
    /// temporary password enforcement, and evaluation demo accounts.
    /// </summary>
    public partial class Login : Page
    {
        #region Fields & Constants

        private static readonly HttpClient HttpClient = new HttpClient();

        private const string TableUsers = "Users";
        private const string TableStudents = "Students";
        private const string TableAcademic = "AcademicSupervisors";
        private const string TableCompany = "CompanySupervisors";
        private const string TableAdmins = "Admins";
        private const string TableCoordinators = "Coordinators";

        private const string FirstLoginUrl = "~/login/FirstLogin.aspx";

        #endregion

        #region Navigation Helpers

        protected bool IsSignedIn
        {
            get { return AuthHelper.IsAuthenticated; }
        }

        protected string DashboardHref
        {
            get
            {
                return ResolveUrl(IsSignedIn
                    ? AuthHelper.GetDashboardUrl(AuthHelper.UserRole)
                    : "~/login/Login.aspx");
            }
        }

        #endregion

        #region Page Lifecycle

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                RedirectIfAlreadyAuthenticated();
                DisplayUrlQueryMessage();
            }
        }

        #endregion

        #region Authentication Actions

        /// <summary>
        /// Handles the primary Sign In button click.
        /// </summary>
        protected async void btnLogin_Click(object sender, EventArgs e)
        {
            ClearNotifications();

            string email = txtEmail.Text.Trim();
            string password = txtPassword.Text;

            if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(password))
            {
                DisplayError("Please enter both university email address and password.");
                return;
            }

            // Perform live Firebase Authentication
            await AuthenticateWithFirebaseAsync(email, password);
        }

        /// <summary>
        /// Handles the password reset request via Firebase Authentication REST API.
        /// </summary>
        protected async void btnSendRecovery_Click(object sender, EventArgs e)
        {
            string email = txtRecoveryEmail.Text.Trim();
            if (string.IsNullOrEmpty(email))
            {
                DisplayRecoveryResult("Please enter your university email address first.", false);
                return;
            }

            try
            {
                // Our own email (full UIMS design) when it is set up; otherwise Firebase sends its default email.
                if (await SendOwnResetEmail(email))
                {
                    DisplayRecoveryResult("If this email has an account, a password reset link was sent to it. Please check your inbox or spam folder.", true);
                    txtRecoveryEmail.Text = string.Empty;
                    return;
                }

                var payload = new
                {
                    requestType = "PASSWORD_RESET",
                    email = email
                };

                var content = new StringContent(JsonConvert.SerializeObject(payload), Encoding.UTF8, "application/json");
                var response = await HttpClient.PostAsync(AppConfig.PasswordResetUrl, content);
                string responseJson = await response.Content.ReadAsStringAsync();

                if (response.IsSuccessStatusCode)
                {
                    DisplayRecoveryResult("Password reset link has been sent to your email successfully via Firebase Authentication. Please check your inbox or spam folder.", true);
                    txtRecoveryEmail.Text = string.Empty;
                }
                else
                {
                    string rawError = ExtractErrorMessage(responseJson);
                    DisplayRecoveryResult(AuthHelper.GetFriendlyAuthError(rawError), false);
                }
            }
            catch (Exception ex)
            {
                DisplayRecoveryResult("Error sending password reset link: " + Server.HtmlEncode(ex.Message), false);
            }
        }

        // Creates the reset link with the service account and sends it with our own email design.
        // Returns false when it is not set up or something failed, so the caller uses Firebase's email.
        private async Task<bool> SendOwnResetEmail(string email)
        {
            if (!FirebaseAdmin.IsConfigured || !EmailSender.IsConfigured) return false;
            try
            {
                string link = await FirebaseAdmin.CreateResetLink(email);
                if (link != "") await EmailSender.SendPasswordReset(email, link);   // "" = no account, send nothing
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        #endregion

        #region Firebase REST Logic

        /// <summary>
        /// Authenticates credentials with Firebase Auth REST endpoint and resolves role/profile data.
        /// </summary>
        private async Task AuthenticateWithFirebaseAsync(string email, string password)
        {
            try
            {
                var payload = new
                {
                    email = email,
                    password = password,
                    returnSecureToken = true
                };

                var content = new StringContent(JsonConvert.SerializeObject(payload), Encoding.UTF8, "application/json");
                var response = await HttpClient.PostAsync(AppConfig.SignInUrl, content);
                string responseJson = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    string rawError = ExtractErrorMessage(responseJson);
                    DisplayError(AuthHelper.GetFriendlyAuthError(rawError));
                    return;
                }

                // Parse Firebase Auth Success payload
                var authObj = JObject.Parse(responseJson);
                string localId = authObj["localId"]?.ToString();
                string idToken = authObj["idToken"]?.ToString();
                string returnedEmail = authObj["email"]?.ToString() ?? email;

                // Retrieve Profile metadata from Firebase Realtime Database
                var userProfile = await FetchUserProfileAsync(localId, returnedEmail, idToken);

                // A new account must confirm its email first (Config/EmailVerification.cs). Nothing is signed in until then.
                if (await EmailVerification.IsBlocked(userProfile.Table, userProfile.RecordId, idToken))
                {
                    await EmailVerification.Send(idToken);   // a fresh link, because the first one may be lost
                    DisplayError("Please confirm your email first. We sent a new confirmation link to " + HttpUtility.HtmlEncode(returnedEmail) + ". Open it, then sign in again.");
                    return;
                }

                // Welcome email (once) and "password changed" email. Does nothing when SMTP is not set up (Config/Notify.cs).
                await Notify.AfterSignIn(userProfile.Table, userProfile.RecordId, userProfile.Name, userProfile.Role, returnedEmail, idToken);

                if (!string.IsNullOrEmpty(userProfile.RecordId))
                {
                    Session["dbRecordId"] = userProfile.RecordId;
                    Session["dbTable"] = userProfile.Table;
                }

                // Initialize secure session state
                AuthHelper.SetUserSession(localId, idToken, returnedEmail, userProfile.Name, userProfile.Role, userProfile.FirstLogin);

                // Enforce mandatory password update if flagged for first login
                if (userProfile.FirstLogin)
                {
                    PreserveReturnUrlIfPresent();
                    SafeRedirect(FirstLoginUrl);
                    return;
                }

                // Follow ReturnUrl query parameter if safe and authorized
                if (TryRedirectToReturnUrl())
                {
                    return;
                }

                // Navigate directly to the corresponding role dashboard
                SafeRedirect(AuthHelper.GetDashboardUrl(userProfile.Role));
            }
            catch (System.Threading.ThreadAbortException)
            {
                // Normal ASP.NET thread termination during redirect
            }
            catch (Exception ex)
            {
                DisplayError("An error occurred during sign in: " + Server.HtmlEncode(ex.Message));
            }
        }

        /// <summary>
        /// Queries the Realtime Database tables to locate the user's name, role, and firstLogin flag.
        /// Searches first by UID key, then scans records by Email / UniEmail / CompEmail.
        /// </summary>
        private async Task<(string Name, string Role, bool FirstLogin, string RecordId, string Table)> FetchUserProfileAsync(string uid, string email, string idToken)
        {
            string[] databaseTables = new[] { TableUsers, TableStudents, TableAcademic, TableCompany, TableAdmins, TableCoordinators };
            string normalizedEmail = (email ?? string.Empty).Trim().ToLowerInvariant();

            // 1. Direct lookup by Firebase Auth UID in each table
            foreach (string table in databaseTables)
            {
                try
                {
                    string json = await FirebaseDb.Get(table, uid, idToken);
                    if (!string.IsNullOrEmpty(json) && json.Trim() != "null")
                    {
                        var obj = JObject.Parse(json);
                        // A record with no Name and no Role is only a leftover FirstLogin flag, not a real profile
                        if (obj.HasValues && (obj["Name"] != null || obj["Role"] != null || obj["name"] != null || obj["role"] != null))
                        {
                            string name = obj["Name"]?.ToString() ?? obj["name"]?.ToString() ?? "";
                            string rawRole = obj["Role"]?.ToString() ?? obj["role"]?.ToString() ?? "";
                            string role = ResolveRoleFromTable(table, rawRole);
                            bool firstLogin = ParseFirstLoginFlag(obj);

                            return (name, role, firstLogin, uid, table);
                        }
                    }
                }
                catch
                {
                    // Continue searching subsequent tables
                }
            }

            // 2. Scan tables to match record by email fields (e.g. student_001, company_001)
            foreach (string table in databaseTables)
            {
                try
                {
                    string tableJson = await FirebaseDb.Get(table, null, idToken);
                    if (string.IsNullOrEmpty(tableJson) || tableJson.Trim() == "null")
                    {
                        continue;
                    }

                    var tableObj = JObject.Parse(tableJson);
                    foreach (var prop in tableObj.Properties())
                    {
                        if (prop.Value is JObject item)
                        {
                            string itemEmail = (item["Email"]?.ToString() ?? "").Trim().ToLowerInvariant();
                            string itemUniEmail = (item["UniEmail"]?.ToString() ?? item["UniversityEmail"]?.ToString() ?? "").Trim().ToLowerInvariant();
                            string itemCompEmail = (item["CompEmail"]?.ToString() ?? "").Trim().ToLowerInvariant();

                            if (itemEmail == normalizedEmail || itemUniEmail == normalizedEmail || itemCompEmail == normalizedEmail)
                            {
                                string name = item["Name"]?.ToString() ?? item["name"]?.ToString() ?? "";
                                string rawRole = item["Role"]?.ToString() ?? item["role"]?.ToString() ?? "";
                                string role = ResolveRoleFromTable(table, rawRole);
                                bool firstLogin = ParseFirstLoginFlag(item);

                                return (name, role, firstLogin, prop.Name, table);
                            }
                        }
                    }
                }
                catch
                {
                    // Continue searching subsequent tables
                }
            }

            // Default fallback if no profile record found
            return (string.Empty, AuthHelper.RoleStudent, false, null, null);
        }

        private static bool ParseFirstLoginFlag(JObject obj)
        {
            if (obj == null) return false;
            var token = obj["FirstLogin"] ?? obj["firstLogin"];
            if (token == null) return false;

            if (token.Type == JTokenType.Boolean)
            {
                return (bool)token;
            }

            string strVal = token.ToString().Trim().ToLowerInvariant();
            return strVal == "true" || strVal == "1";
        }

        private static string ResolveRoleFromTable(string table, string rawRole)
        {
            if (!string.IsNullOrEmpty(rawRole))
            {
                return AuthHelper.NormalizeRole(rawRole);
            }

            if (table.Contains("Student")) return AuthHelper.RoleStudent;
            if (table.Contains("Company")) return AuthHelper.RoleCompany;
            if (table.Contains("Academic")) return AuthHelper.RoleAcademic;
            if (table.Contains("Admin") || table.Contains("Coordinator")) return AuthHelper.RoleCoordinator;
            return AuthHelper.RoleStudent;
        }

        #endregion

        #region Navigation & UI Helpers

        /// <summary>
        /// Safely redirects the response without throwing ThreadAbortException in async handlers.
        /// </summary>
        private void SafeRedirect(string url)
        {
            Response.Redirect(url, false);
            Context.ApplicationInstance.CompleteRequest();
        }

        private void RedirectIfAlreadyAuthenticated()
        {
            if (AuthHelper.IsAuthenticated)
            {
                if (AuthHelper.IsFirstLogin)
                {
                    SafeRedirect(FirstLoginUrl);
                }
                else
                {
                    SafeRedirect(AuthHelper.GetDashboardUrl(AuthHelper.UserRole));
                }
            }
        }

        private void DisplayUrlQueryMessage()
        {
            // sent by the guard in Global.asax.cs when the Firebase token expired
            if (Request.QueryString["expired"] == "1")
            {
                DisplayError("Your session expired. Please sign in again.");
                return;
            }

            string msg = Request.QueryString["msg"];
            if (!string.IsNullOrEmpty(msg))
            {
                DisplaySuccess(HttpUtility.HtmlEncode(msg));
            }
        }

        private void PreserveReturnUrlIfPresent()
        {
            string returnUrl = Request.QueryString["ReturnUrl"] ?? Request.QueryString["returnUrl"];
            if (!string.IsNullOrEmpty(returnUrl) &&
                !returnUrl.Contains("Login.aspx") &&
                !returnUrl.Contains("FirstLogin.aspx") &&
                !returnUrl.Contains("Logout.aspx") &&
                AuthHelper.IsLocalUrl(returnUrl))
            {
                Session["PostFirstLoginReturnUrl"] = returnUrl;
            }
        }

        private bool TryRedirectToReturnUrl()
        {
            string returnUrl = Request.QueryString["ReturnUrl"] ?? Request.QueryString["returnUrl"];
            if (!string.IsNullOrEmpty(returnUrl) &&
                !returnUrl.Contains("Login.aspx") &&
                !returnUrl.Contains("FirstLogin.aspx") &&
                !returnUrl.Contains("Logout.aspx") &&
                AuthHelper.IsLocalUrl(returnUrl))
            {
                SafeRedirect(returnUrl);
                return true;
            }

            return false;
        }

        private void ClearNotifications()
        {
            pnlError.Visible = false;
            pnlSuccess.Visible = false;
        }

        private void DisplayError(string message)
        {
            pnlError.Visible = true;
            litErrorMsg.Text = message;
            pnlSuccess.Visible = false;
        }

        private void DisplaySuccess(string message)
        {
            pnlSuccess.Visible = true;
            litSuccessMsg.Text = message;
            pnlError.Visible = false;
        }

        private void DisplayRecoveryResult(string message, bool isSuccess)
        {
            pnlRecoveryResult.Visible = true;
            pnlRecoveryResult.CssClass = isSuccess
                ? "alert alert-success small p-2 mt-2"
                : "alert alert-danger small p-2 mt-2";
            litRecoveryMsg.Text = message;

            // Re-open modal cleanly via registered helper
            string script = "if (window.openForgotModal) { window.openForgotModal(); }";
            ClientScript.RegisterStartupScript(GetType(), "OpenRecoveryModal", script, true);
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
