using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Linq;
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

                var timer = System.Diagnostics.Stopwatch.StartNew();   // only for the timing line in App_Data/email-log.txt
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

                long passwordMs = timer.ElapsedMilliseconds;

                // Retrieve Profile metadata from Firebase Realtime Database
                var userProfile = await FetchUserProfileAsync(localId, returnedEmail, idToken);
                long profileMs = timer.ElapsedMilliseconds - passwordMs;

                // A Firebase account that has no profile record in our database is not a UIMS user: do not let it in as a student
                if (string.IsNullOrEmpty(userProfile.Table) || string.IsNullOrEmpty(userProfile.RecordId))
                {
                    DisplayError("Your account is not registered in UIMS. Please contact the internship coordinator.");
                    return;
                }

                // A new account must confirm its email first (Config/EmailVerification.cs). Nothing is signed in until then.
                if (await EmailVerification.IsBlocked(userProfile.Table, userProfile.RecordId, idToken))
                {
                    await EmailVerification.Send(idToken);   // a fresh link, because the first one may be lost
                    DisplayError("Please confirm your email first. We sent a new confirmation link to " + HttpUtility.HtmlEncode(returnedEmail) + ". Open it, then sign in again.");
                    return;
                }

                // If a sign-in feels slow, this line shows which step took the time
                EmailSender.Log("sign-in timing of " + returnedEmail + ": password check " + passwordMs + " ms, profile " + profileMs
                    + " ms, confirmation check " + (timer.ElapsedMilliseconds - passwordMs - profileMs) + " ms, total " + timer.ElapsedMilliseconds + " ms");

                // Welcome email (once) and "password changed" email. Does nothing when SMTP is not set up (Config/Notify.cs).
                Notify.AfterSignIn(userProfile.Table, userProfile.RecordId, userProfile.Name, userProfile.Role, returnedEmail, idToken);

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
        /// Searches first by UID key, then scans records by their Email.
        /// </summary>
        private async Task<(string Name, string Role, bool FirstLogin, string RecordId, string Table)> FetchUserProfileAsync(string uid, string email, string idToken)
        {
            string[] databaseTables = new[] { TableUsers, TableStudents, TableAcademic, TableCompany, TableAdmins, TableCoordinators };
            string normalizedEmail = (email ?? string.Empty).Trim().ToLowerInvariant();

            // 1. Direct lookup by Firebase Auth UID in each table.
            //    All the tables are asked at the same time (one wait instead of six); the first table in the list that has the record wins.
            var byUid = await Task.WhenAll(databaseTables.Select(table => TryReadAsync(table, uid, idToken)));
            for (int i = 0; i < databaseTables.Length; i++)
            {
                var obj = byUid[i] as JObject;
                // A record with no Name and no Role is only a leftover FirstLogin flag, not a real profile
                if (obj != null && obj.HasValues && (obj["Name"] != null || obj["Role"] != null || obj["name"] != null || obj["role"] != null))
                {
                    string name = obj["Name"]?.ToString() ?? obj["name"]?.ToString() ?? "";
                    string rawRole = obj["Role"]?.ToString() ?? obj["role"]?.ToString() ?? "";
                    string role = ResolveRoleFromTable(databaseTables[i], rawRole);
                    bool firstLogin = ParseFirstLoginFlag(obj);

                    return (name, role, firstLogin, uid, databaseTables[i]);
                }
            }

            // 2. Scan tables to match the record by its Email (e.g. student_001, company_001), also all tables at the same time
            var tables = await Task.WhenAll(databaseTables.Select(table => TryReadAsync(table, null, idToken)));
            for (int t = 0; t < databaseTables.Length; t++)
            {
                string table = databaseTables[t];
                try
                {
                    var tableObj = tables[t] as JObject;
                    if (tableObj == null)
                    {
                        continue;
                    }

                    foreach (var prop in tableObj.Properties())
                    {
                        if (prop.Value is JObject item)
                        {
                            string itemEmail = (item["Email"]?.ToString() ?? "").Trim().ToLowerInvariant();

                            if (itemEmail == normalizedEmail)
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

        // One record (or a whole table when id is null) as JSON; null when it is missing or can not be read
        private static async Task<JToken> TryReadAsync(string table, string id, string idToken)
        {
            try
            {
                string json = await FirebaseDb.Get(table, id, idToken);
                if (string.IsNullOrEmpty(json) || json.Trim() == "null") return null;
                return JToken.Parse(json);
            }
            catch
            {
                return null;
            }
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
            // The role is decided by the TABLE the record is in (Students, CompanySupervisors, ...), never by a "Role" field inside
            // the record: a person who can edit his own record must not be able to make himself a coordinator.
            if (table.Contains("Student")) return AuthHelper.RoleStudent;
            if (table.Contains("Company")) return AuthHelper.RoleCompany;
            if (table.Contains("Academic")) return AuthHelper.RoleAcademic;
            if (table.Contains("Admin") || table.Contains("Coordinator")) return AuthHelper.RoleCoordinator;

            // Any other table (for example "Users"): the Role field may name a student, company or academic role, but never the coordinator
            if (!string.IsNullOrEmpty(rawRole))
            {
                string role = AuthHelper.NormalizeRole(rawRole);
                return role == AuthHelper.RoleCoordinator ? AuthHelper.RoleStudent : role;
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
