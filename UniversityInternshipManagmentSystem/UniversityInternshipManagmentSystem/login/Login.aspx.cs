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

            // Check if demo evaluation credentials match
            if (TryAuthenticateDemoAccount(email, password))
            {
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
                        if (obj.HasValues)
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

        #region Evaluation Demo Accounts

        /// <summary>
        /// Provides mock accounts for evaluation and academic demo presentation.
        /// Supports first-time login testing with temporary password enforcement.
        /// </summary>
        private bool TryAuthenticateDemoAccount(string email, string password)
        {
            string normalizedEmail = email.ToLowerInvariant();

            // First-time login demo account (Ahmad - New Student)
            if (normalizedEmail == "student.new@ju.edu.jo" && (password == "TempPassword123!" || password == (Session["demo_student_new_pwd"] as string)))
            {
                bool isFirst = Session["demo_student_new_pwd_set"] == null;
                AuthHelper.SetUserSession("demo-student-new", "mock-token", email, "Ahmad (First-Time Student)", AuthHelper.RoleStudent, isFirst);
                PreserveReturnUrlIfPresent();

                if (isFirst)
                {
                    SafeRedirect(FirstLoginUrl);
                }
                else
                {
                    if (TryRedirectToReturnUrl()) return true;
                    SafeRedirect(AuthHelper.GetDashboardUrl(AuthHelper.RoleStudent));
                }
                return true;
            }

            // Also support Firebase RTDB sample accounts with FirstLogin = true as demo accounts
            if (normalizedEmail == "student1@example.com" && (password == "TempPassword123!" || password == "password123" || password == (Session["demo_student1_pwd"] as string)))
            {
                bool isFirst = Session["demo_student1_pwd_set"] == null;
                AuthHelper.SetUserSession("demo-student1", "mock-token", email, "Ahmad Ali", AuthHelper.RoleStudent, isFirst);
                Session["dbRecordId"] = "student_001";
                Session["dbTable"] = TableStudents;
                PreserveReturnUrlIfPresent();

                if (isFirst)
                {
                    SafeRedirect(FirstLoginUrl);
                }
                else
                {
                    if (TryRedirectToReturnUrl()) return true;
                    SafeRedirect(AuthHelper.GetDashboardUrl(AuthHelper.RoleStudent));
                }
                return true;
            }

            if (normalizedEmail == "student5@example.com" && (password == "TempPassword123!" || password == "password123" || password == (Session["demo_student5_pwd"] as string)))
            {
                bool isFirst = Session["demo_student5_pwd_set"] == null;
                AuthHelper.SetUserSession("demo-student5", "mock-token", email, "Zaid Omar", AuthHelper.RoleStudent, isFirst);
                Session["dbRecordId"] = "student_005";
                Session["dbTable"] = TableStudents;
                PreserveReturnUrlIfPresent();

                if (isFirst)
                {
                    SafeRedirect(FirstLoginUrl);
                }
                else
                {
                    if (TryRedirectToReturnUrl()) return true;
                    SafeRedirect(AuthHelper.GetDashboardUrl(AuthHelper.RoleStudent));
                }
                return true;
            }

            if (normalizedEmail == "supervisor2@example.com" && (password == "TempPassword123!" || password == "password123" || password == (Session["demo_supervisor2_pwd"] as string)))
            {
                bool isFirst = Session["demo_supervisor2_pwd_set"] == null;
                AuthHelper.SetUserSession("demo-company2", "mock-token", email, "Hala Saleh (Demo Irbid Digital)", AuthHelper.RoleCompany, isFirst);
                Session["dbRecordId"] = "company_002";
                Session["dbTable"] = TableCompany;
                PreserveReturnUrlIfPresent();

                if (isFirst)
                {
                    SafeRedirect(FirstLoginUrl);
                }
                else
                {
                    if (TryRedirectToReturnUrl()) return true;
                    SafeRedirect(AuthHelper.GetDashboardUrl(AuthHelper.RoleCompany));
                }
                return true;
            }

            // Standard student demo account (already completed first login)
            if (normalizedEmail == "student@ju.edu.jo" && password == "password123")
            {
                AuthHelper.SetUserSession("demo-student", "mock-token", email, "Ahmad Mohammad", AuthHelper.RoleStudent, false);
                if (TryRedirectToReturnUrl()) return true;
                SafeRedirect(AuthHelper.GetDashboardUrl(AuthHelper.RoleStudent));
                return true;
            }

            // Company supervisor demo account
            if (normalizedEmail == "company@umniah.com" && password == "password123")
            {
                AuthHelper.SetUserSession("demo-company", "mock-token", email, "Eng. Khaled (Umniah)", AuthHelper.RoleCompany, false);
                if (TryRedirectToReturnUrl()) return true;
                SafeRedirect(AuthHelper.GetDashboardUrl(AuthHelper.RoleCompany));
                return true;
            }

            // Academic supervisor demo account
            if (normalizedEmail == "academic@ju.edu.jo" && password == "password123")
            {
                AuthHelper.SetUserSession("demo-academic", "mock-token", email, "Dr. Omar Abdullah", AuthHelper.RoleAcademic, false);
                if (TryRedirectToReturnUrl()) return true;
                SafeRedirect(AuthHelper.GetDashboardUrl(AuthHelper.RoleAcademic));
                return true;
            }

            // Coordinator demo account
            if (normalizedEmail == "coordinator@ju.edu.jo" && password == "password123")
            {
                AuthHelper.SetUserSession("demo-coordinator", "mock-token", email, "Dr. Samer (Coordinator)", AuthHelper.RoleCoordinator, false);
                if (TryRedirectToReturnUrl()) return true;
                SafeRedirect(AuthHelper.GetDashboardUrl(AuthHelper.RoleCoordinator));
                return true;
            }

            return false;
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
