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
        protected override void OnInit(EventArgs e)
        {
            base.OnInit(e);
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            Response.Cache.SetNoStore();
            btnSaveDetails.Enabled = btnCancelDetails.Enabled = btnSavePassword.Enabled = false;
            txtFullName.ReadOnly = txtEmail.ReadOnly = txtPhoneNumber.ReadOnly = txtOfficeNumber.ReadOnly = txtProfilePicUrl.ReadOnly = true;
            ddlMajor.Enabled = false;
            txtCurrentPassword.Enabled = txtNewPassword.Enabled = txtConfirmPassword.Enabled = false;
            pnlAccountContent.Visible = false;
            SetStatus("Loading your verified account...", "loading");
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            // Revalidate on every request. Never render account values restored from ViewState.
            RegisterAsyncTask(new PageAsyncTask(LoadSupervisorProfileAsync));
        }

        private async Task LoadSupervisorProfileAsync()
        {
            try
            {
                var session = new HttpSessionStateWrapper(Session);
                var reader = new AcademicAccountReader();
                JObject profile = await reader.LoadAsync(session);
                BindSupervisorData(profile);
                pnlAccountContent.Visible = true;
                SetStatus("Your verified account is displayed below. Profile editing and password changes are disabled pending team approval.", "loaded");
            }
            catch (AccountAccessException ex)
            {
                pnlAccountContent.Visible = false;
                Response.StatusCode = ex.StatusCode;
                Response.TrySkipIisCustomErrors = true;
                Response.SuppressFormsAuthenticationRedirect = true;
                SetStatus(ex.Message, ex.StatusCode == 401 || ex.StatusCode == 403 ? "unauthorized" : "unavailable");
            }
            catch (Exception)
            {
                pnlAccountContent.Visible = false;
                Response.StatusCode = 503;
                Response.TrySkipIisCustomErrors = true;
                SetStatus("Account information could not be loaded. Please try again later.", "error");
            }
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
            txtFullName.Text = name;
            txtEmail.Text = email;
            txtPhoneNumber.Text = AcademicAccountReader.Display(profile, "PhoneNumber");
            txtOfficeNumber.Text = AcademicAccountReader.Display(profile, "UniversityEmail");
            txtProfilePicUrl.Text = AcademicAccountReader.Display(profile, "ProfilePicUrl");
            ddlMajor.Items.Clear();
            ddlMajor.Items.Add(new System.Web.UI.WebControls.ListItem(major, major));
            litProfileName.Text = Server.HtmlEncode(name);
            litProfileMajor.Text = Server.HtmlEncode(major);
            litProfileRole.Text = Server.HtmlEncode(AcademicAccountReader.Display(profile, "Role"));
            litProfileEmail.Text = Server.HtmlEncode(email);
            litProfilePhone.Text = Server.HtmlEncode(txtPhoneNumber.Text);
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

        // Defense in depth: crafted postbacks cannot enable either write workflow.
        protected void btnSaveDetails_Click(object sender, EventArgs e)
        {
            SetStatus("Profile editing is disabled pending approval of field permissions.", "unavailable");
        }
        protected void btnCancelDetails_Click(object sender, EventArgs e) { }
        protected void btnSavePassword_Click(object sender, EventArgs e)
        {
            SetStatus("Password changes are disabled pending the approved authentication workflow.", "unavailable");
        }
    }

    internal sealed class AccountAccessException : Exception
    {
        internal int StatusCode { get; private set; }
        internal AccountAccessException(int status, string message) : base(message) { StatusCode = status; }
    }

    // Module-local, read-only access. Does not change shared sessions or Firebase configuration.
    internal sealed class AcademicAccountReader
    {
        private static readonly HttpClient Client = new HttpClient(new HttpClientHandler { AllowAutoRedirect = false })
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
