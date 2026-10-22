using System;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.Academic.SupervisorAccount
{
    public partial class SupervisorAccount : Page
    {
        private string action;
        protected string AccountCsrf => Session["Academic.Account.Csrf"] as string;
        protected override void OnInit(EventArgs e)
        {
            base.OnInit(e);
            ViewStateUserKey = Session.SessionID;
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            Response.Cache.SetNoStore();
            if (string.IsNullOrEmpty(AccountCsrf)) Session["Academic.Account.Csrf"] = Guid.NewGuid().ToString("N");
            foreach (var input in new[] { txtFullName, txtPhoneNumber, txtProfilePicUrl })
            {
                input.EnableViewState = false;
                input.ReadOnly = false;
            }
            txtOfficeNumber.ReadOnly = true;
            pnlAccountContent.Visible = false;
            SetStatus("Loading your verified account...", "loading");
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            RegisterAsyncTask(new PageAsyncTask(LoadSupervisorProfileAsync));
        }

        internal static void RequireCsrf(string expected, string actual)
        {
            if (string.IsNullOrEmpty(expected) || !string.Equals(expected, actual, StringComparison.Ordinal))
                throw new AccountAccessException(403, "Your form session has expired. Reload the account before trying again.");
        }

        private async Task LoadSupervisorProfileAsync()
        {
            string name = txtFullName.Text, phone = txtPhoneNumber.Text, picture = txtProfilePicUrl.Text;
            try
            {
                var session = new HttpSessionStateWrapper(Session);
                var reader = new AcademicAccountReader();
                JObject profile = await reader.LoadAsync(session);
                BindSupervisorData(profile);
                if (IsPostBack && action != "cancel")
                {
                    txtFullName.Text = name;
                    txtPhoneNumber.Text = phone;
                    txtProfilePicUrl.Text = picture;
                }
                pnlAccountContent.Visible = true;
                SetStatus("Your verified account is loaded. Changes are restricted to your own account and Firebase permissions.", "loaded");
                if (action == null) return;
                RequireCsrf(AccountCsrf, Request.Form["AcademicAccountCsrf"]);
                if (action == "cancel")
                    SetStatus("Unsaved changes discarded. Your current account has been reloaded.", "loaded");
                else if (action == "save")
                {
                    var patch = AcademicAccountReader.ProfilePatch(name, phone, picture);
                    BindSupervisorData(await reader.SaveAsync(session, patch));
                    pnlProfileSuccess.Visible = true;
                    litProfileSuccess.Text = "Your account details were saved and verified in Firebase.";
                }
                else if (action == "password")
                {
                    await reader.ChangePasswordAsync(session, txtCurrentPassword.Text, txtNewPassword.Text, txtConfirmPassword.Text);
                    pnlPasswordSuccess.Visible = true;
                    litPasswordSuccess.Text = "Your password was updated successfully.";
                }
            }
            catch (ArgumentException ex) { ShowActionError(ex.Message); }
            catch (AccountAccessException ex)
            {
                ShowActionError(ex.Message);
                if (action == null || ex.StatusCode == 401)
                {
                    pnlAccountContent.Visible = false;
                    Response.StatusCode = ex.StatusCode;
                    Response.TrySkipIisCustomErrors = true;
                    Response.SuppressFormsAuthenticationRedirect = true;
                }
            }
            catch (Exception)
            {
                ShowActionError("The request could not be completed or confirmed. Reload your account before retrying.");
                if (action == null) { pnlAccountContent.Visible = false; Response.StatusCode = 503; Response.TrySkipIisCustomErrors = true; }
            }
            finally { txtCurrentPassword.Text = txtNewPassword.Text = txtConfirmPassword.Text = ""; }
        }

        private void ShowActionError(string message)
        {
            SetStatus(message, "error");
            if (action == "password") { pnlPasswordError.Visible = true; litPasswordError.Text = Server.HtmlEncode(message); }
            else if (action == "save") { pnlProfileError.Visible = true; litProfileError.Text = Server.HtmlEncode(message); }
        }

        private void SetStatus(string message, string state)
        {
            pnlAccountStatus.Attributes["data-state"] = state;
            litAccountStatus.Text = Server.HtmlEncode(message);
        }

        private void BindSupervisorData(JObject profile)
        {
            string name = AcademicAccountReader.Display(profile, "Name");
            string major = AcademicAccountReader.Display(profile, "Major");
            string email = AcademicAccountReader.Display(profile, "Email");
            txtFullName.Text = AcademicAccountReader.StringValue(profile, "Name") ?? "";
            txtPhoneNumber.Text = AcademicAccountReader.StringValue(profile, "PhoneNumber") ?? "";
            txtOfficeNumber.Text = AcademicAccountReader.Display(profile, "UniversityEmail");
            txtProfilePicUrl.Text = AcademicAccountReader.StringValue(profile, "ProfilePicUrl") ?? "";
            litProfileName.Text = Server.HtmlEncode(name);
            litProfileMajor.Text = Server.HtmlEncode(major);
            litProfileRole.Text = Server.HtmlEncode(AcademicAccountReader.Display(profile, "Role"));
            litProfileEmail.Text = Server.HtmlEncode(email);
            litProfilePhone.Text = Server.HtmlEncode(AcademicAccountReader.Display(profile, "PhoneNumber"));
            // Reuse the existing summary slot for actual optional UniversityEmail, not an invented office.
            litProfileOffice.Text = Server.HtmlEncode(txtOfficeNumber.Text);
            litFirstLogin.Text = profile["FirstLogin"] != null && profile["FirstLogin"].Type == JTokenType.Boolean
                ? ((bool)profile["FirstLogin"] ? "Yes" : "No") : "Not provided";
            Uri image;
            string picture = AcademicAccountReader.StringValue(profile, "ProfilePicUrl");
            bool safeImage = picture != null && picture.Length <= 2048
                && Uri.TryCreate(picture, UriKind.Absolute, out image)
                && image.Scheme == Uri.UriSchemeHttps && string.IsNullOrEmpty(image.UserInfo);
            pnlImageAvatar.Visible = safeImage;
            pnlInitialsAvatar.Visible = !safeImage;
            if (safeImage) imgAvatar.ImageUrl = picture;
            litAvatarInitials.Text = Server.HtmlEncode(string.IsNullOrWhiteSpace(AcademicAccountReader.StringValue(profile, "Name"))
                ? "?" : name.Substring(0, 1).ToUpperInvariant());
        }

        protected void btnSaveDetails_Click(object sender, EventArgs e) { action = "save"; }
        protected void btnCancelDetails_Click(object sender, EventArgs e) { action = "cancel"; }
        protected void btnSavePassword_Click(object sender, EventArgs e) { action = "password"; }
    }

    internal sealed class AccountAccessException : Exception
    {
        internal int StatusCode { get; private set; }
        internal AccountAccessException(int status, string message) : base(message) { StatusCode = status; }
    }

    // Module-local own-account access. Reuses team configuration and the verified login session.
    internal sealed class AcademicAccountReader
    {
        private static readonly HttpClient Client = new HttpClient(new HttpClientHandler { AllowAutoRedirect = false, UseCookies = false })
        { Timeout = TimeSpan.FromSeconds(20) };
        private readonly HttpClient client;
        private readonly string databaseUrl;
        private readonly string apiKey;
        internal AcademicAccountReader() : this(Client, AppConfig.DbUrl, AppConfig.ApiKey) { }
        internal AcademicAccountReader(HttpClient transport, string url, string key)
        { client = transport; databaseUrl = url; apiKey = key; }

        internal async Task<JObject> LoadAsync(HttpSessionStateBase session)
        {
            string uid = session == null ? null : session["userId"] as string;
            string token = session == null ? null : session["idToken"] as string;
            if (string.IsNullOrWhiteSpace(uid) || string.IsNullOrWhiteSpace(token))
                throw new AccountAccessException(401, "Sign in through the team login to view your account.");
            if (!string.Equals(session["role"] as string, "academic", StringComparison.Ordinal)
                || !string.Equals(session["dbTable"] as string, "AcademicSupervisors", StringComparison.Ordinal)
                || !string.Equals(session["dbRecordId"] as string, uid, StringComparison.Ordinal)
                || uid.Length > 128 || uid.IndexOfAny(new[] { '.', '#', '$', '[', ']', '/', '\\' }) >= 0)
                throw new AccountAccessException(403, "Account ownership could not be verified. Your AcademicSupervisors record key must match your Firebase UID and the team session mapping.");
            if (token.Length > 16384)
                throw new AccountAccessException(401, "Your sign-in session is invalid. Please sign in again.");

            Uri database;
            if (!Uri.TryCreate(databaseUrl, UriKind.Absolute, out database)
                || database.Scheme != Uri.UriSchemeHttps || !string.IsNullOrEmpty(database.UserInfo)
                || database.AbsolutePath != "/" || !string.IsNullOrEmpty(database.Query)
                || !string.IsNullOrEmpty(database.Fragment) || !database.IsDefaultPort || string.IsNullOrWhiteSpace(apiKey))
                throw new AccountAccessException(503, "The team's Firebase configuration is unavailable.");
            var hostMatch = System.Text.RegularExpressions.Regex.Match(database.Host,
                @"^([a-z0-9-]+)-default-rtdb(?:\.[a-z0-9-]+)?\.(?:firebaseio\.com|firebasedatabase\.app)$");
            if (!hostMatch.Success)
                throw new AccountAccessException(503, "The configured Firebase project could not be determined.");
            string project = hostMatch.Groups[1].Value;

            // Google verifies the signed token server-side. Decoded claims alone are never trusted.
            using (var request = new HttpRequestMessage(HttpMethod.Post,
                "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=" + Uri.EscapeDataString(apiKey)))
            {
                request.Content = new StringContent(JsonConvert.SerializeObject(new { idToken = token }), Encoding.UTF8, "application/json");
                using (var response = await client.SendAsync(request))
                {
                    if (response.StatusCode == HttpStatusCode.BadRequest || response.StatusCode == HttpStatusCode.Unauthorized
                        || response.StatusCode == HttpStatusCode.Forbidden)
                        throw new AccountAccessException(401, "Firebase could not verify your sign-in session. Please sign in again.");
                    if (!response.IsSuccessStatusCode)
                        throw new AccountAccessException(503, "Firebase identity verification is temporarily unavailable.");
                    JObject result = JObject.Parse(await response.Content.ReadAsStringAsync());
                    var users = result["users"] as JArray;
                    var user = users != null && users.Count == 1 ? users[0] as JObject : null;
                    if (user == null || (string)user["localId"] != uid || (bool?)user["disabled"] == true)
                        throw new AccountAccessException(401, "Firebase could not verify your account.");
                    ValidateAcceptedToken(token, uid, project, (string)user["validSince"]);
                }
            }

            string url = database.AbsoluteUri.TrimEnd('/') + "/AcademicSupervisors/" + Uri.EscapeDataString(uid) + ".json?auth=" + Uri.EscapeDataString(token);
            using (var response = await client.GetAsync(url))
            {
                if (response.StatusCode == HttpStatusCode.Unauthorized || response.StatusCode == HttpStatusCode.Forbidden)
                    throw new AccountAccessException(403, "Firebase denied access to your account. Ask the Firebase owner to verify own-record read permissions.");
                if (response.StatusCode == HttpStatusCode.NotFound)
                    throw new AccountAccessException(404, "Your Academic Supervisor record is unavailable.");
                if (!response.IsSuccessStatusCode)
                    throw new AccountAccessException(503, "Firebase account information is temporarily unavailable.");
                JToken value = JToken.Parse(await response.Content.ReadAsStringAsync());
                if (value.Type == JTokenType.Null)
                    throw new AccountAccessException(404, "Your Academic Supervisor record is unavailable.");
                var profile = value as JObject;
                if (profile == null)
                    throw new AccountAccessException(503, "The account record has an unsupported format.");
                if (!string.Equals(StringValue(profile, "Role"), "AcademicSupervisor", StringComparison.Ordinal))
                    throw new AccountAccessException(403, "The verified account is not an Academic Supervisor.");
                return profile;
            }
        }

        internal static JObject ProfilePatch(string name, string phone, string picture)
        {
            name = (name ?? "").Trim(); phone = (phone ?? "").Trim(); picture = (picture ?? "").Trim();
            if (name.Length == 0 || name.Length > 100 || System.Text.RegularExpressions.Regex.IsMatch(name, @"[<>\p{Cc}]"))
                throw new ArgumentException("Enter your full name (1–100 characters, without markup or control characters).");
            if (phone.Length > 0 && !System.Text.RegularExpressions.Regex.IsMatch(phone, @"^(?=.{7,30}$)(?=.*[0-9])[0-9+() \-]+$"))
                throw new ArgumentException("Enter a phone number using 7–30 digits, spaces, +, parentheses or hyphens.");
            Uri image;
            if (picture.Length > 0 && (picture.Length > 2048 || System.Text.RegularExpressions.Regex.IsMatch(picture, @"\p{Cc}")
                || !Uri.TryCreate(picture, UriKind.Absolute, out image) || image.Scheme != Uri.UriSchemeHttps
                || string.IsNullOrEmpty(image.Host) || !string.IsNullOrEmpty(image.UserInfo)))
                throw new ArgumentException("Enter an absolute HTTPS profile picture URL without embedded credentials (up to 2048 characters), or leave it empty.");
            return new JObject { { "Name", name }, { "PhoneNumber", phone }, { "ProfilePicUrl", picture } };
        }

        internal async Task<JObject> SaveAsync(HttpSessionStateBase session, JObject patch)
        {
            if (patch == null || patch.Count != 3 || patch["Name"]?.Type != JTokenType.String
                || patch["PhoneNumber"]?.Type != JTokenType.String || patch["ProfilePicUrl"]?.Type != JTokenType.String)
                throw new ArgumentException("Only name, phone number and profile picture can be updated.");
            var validated = ProfilePatch((string)patch["Name"], (string)patch["PhoneNumber"], (string)patch["ProfilePicUrl"]);
            await LoadAsync(session); // Revalidate token, role and record ownership before every write.
            string uid = (string)session["userId"], token = (string)session["idToken"];
            string url = databaseUrl.TrimEnd('/') + "/AcademicSupervisors/" + Uri.EscapeDataString(uid) + ".json?auth=" + Uri.EscapeDataString(token);
            using (var request = new HttpRequestMessage(new HttpMethod("PATCH"), url))
            {
                request.Content = new StringContent(validated.ToString(Formatting.None), Encoding.UTF8, "application/json");
                using (var response = await client.SendAsync(request))
                {
                    if (response.StatusCode == HttpStatusCode.Forbidden || response.StatusCode == HttpStatusCode.Unauthorized)
                        throw new AccountAccessException(403, "Firebase denied saving account details. The Firebase owner must approve own-account updates for Name, PhoneNumber and ProfilePicUrl. No permissions were changed.");
                    if (!response.IsSuccessStatusCode)
                        throw new AccountAccessException(503, "Firebase did not confirm saving your details. Reload your account before retrying.");
                }
            }
            var saved = await LoadAsync(session);
            foreach (var field in validated.Properties())
                if (!JToken.DeepEquals(saved[field.Name], field.Value))
                    throw new AccountAccessException(503, "Firebase accepted the request, but saved values could not be confirmed. Reload your account before retrying.");
            return saved;
        }

        internal static void ValidatePassword(string current, string password, string confirm)
        {
            if (string.IsNullOrEmpty(current) || current.Length > 128)
                throw new ArgumentException("Enter your current password (up to 128 characters).");
            if (string.IsNullOrEmpty(password) || password.Length < 6 || password.Length > 128)
                throw new ArgumentException("The new password must contain 6–128 characters.");
            if (password != confirm) throw new ArgumentException("The new passwords do not match.");
            if (password == current) throw new ArgumentException("Choose a new password different from the current password.");
        }

        internal async Task ChangePasswordAsync(HttpSessionStateBase session, string current, string password, string confirm)
        {
            ValidatePassword(current, password, confirm);
            var profile = await LoadAsync(session);
            string uid = (string)session["userId"], email = StringValue(profile, "Email");
            if (string.IsNullOrWhiteSpace(email)) throw new AccountAccessException(403, "The verified account has no sign-in email. Contact the account administrator.");
            JObject signIn = await AuthPostAsync("signInWithPassword", new JObject { { "email", email }, { "password", current }, { "returnSecureToken", true } });
            if ((string)signIn["localId"] != uid || string.IsNullOrWhiteSpace((string)signIn["idToken"]))
                throw new AccountAccessException(403, "The reauthenticated account does not match your verified supervisor account.");
            var updated = await AuthPostAsync("update", new JObject { { "idToken", (string)signIn["idToken"] }, { "password", password }, { "returnSecureToken", true } });
            string refreshed = (string)updated["idToken"];
            if ((string)updated["localId"] != uid || string.IsNullOrWhiteSpace(refreshed))
            {
                session["idToken"] = null;
                throw new AccountAccessException(401, "The password may have changed. Sign in again to verify your account.");
            }
            // Google issued this token over HTTPS; verify its project, subject and lifetime too.
            string project = System.Text.RegularExpressions.Regex.Match(new Uri(databaseUrl).Host,
                @"^([a-z0-9-]+)-default-rtdb").Groups[1].Value;
            try { ValidateAcceptedToken(refreshed, uid, project, null); }
            catch { session["idToken"] = null; throw; }
            session["idToken"] = refreshed;
        }

        private async Task<JObject> AuthPostAsync(string operation, JObject data)
        {
            using (var request = new HttpRequestMessage(HttpMethod.Post,
                "https://identitytoolkit.googleapis.com/v1/accounts:" + operation + "?key=" + Uri.EscapeDataString(apiKey)))
            {
                request.Content = new StringContent(data.ToString(Formatting.None), Encoding.UTF8, "application/json");
                using (var response = await client.SendAsync(request))
                {
                    if (!response.IsSuccessStatusCode)
                        throw new AccountAccessException(403, operation == "signInWithPassword"
                            ? "The current password could not be verified. Check it and try again."
                            : "Firebase refused the password change. Check the password policy or sign in again.");
                    return JObject.Parse(await response.Content.ReadAsStringAsync());
                }
            }
        }

        private static void ValidateAcceptedToken(string token, string uid, string project, string validSince)
        {
            try
            {
                string[] parts = token.Split('.');
                if (parts.Length != 3 || string.IsNullOrEmpty(parts[2])) throw new FormatException();
                JObject header = Decode(parts[0]);
                JObject claims = Decode(parts[1]);
                long now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
                long? expires = (long?)claims["exp"], issued = (long?)claims["iat"], authenticated = (long?)claims["auth_time"];
                long revokedBefore;
                if ((string)header["alg"] != "RS256" || string.IsNullOrWhiteSpace((string)header["kid"])
                    || (string)claims["sub"] != uid || (string)claims["aud"] != project
                    || (string)claims["iss"] != "https://securetoken.google.com/" + project
                    || !expires.HasValue || expires.Value <= now || !issued.HasValue || issued.Value > now
                    || !authenticated.HasValue || authenticated.Value > now
                    || issued.Value < 0 || authenticated.Value < 0 || expires.Value <= issued.Value
                    || (long.TryParse(validSince, out revokedBefore) && authenticated.Value < revokedBefore))
                    throw new FormatException();
            }
            catch (Exception)
            {
                throw new AccountAccessException(401, "Your Firebase session does not match the configured project or has expired. Please sign in again.");
            }
        }
        private static JObject Decode(string part)
        {
            string value = part.Replace('-', '+').Replace('_', '/');
            value = value.PadRight(value.Length + (4 - value.Length % 4) % 4, '=');
            return JObject.Parse(Encoding.UTF8.GetString(Convert.FromBase64String(value)));
        }
        internal static string StringValue(JObject profile, string field)
        {
            JToken value = profile[field];
            return value != null && value.Type == JTokenType.String ? (string)value : null;
        }
        internal static string Display(JObject profile, string field)
        {
            string value = StringValue(profile, field);
            return string.IsNullOrWhiteSpace(value) ? "Not provided" : value;
        }
    }
}
