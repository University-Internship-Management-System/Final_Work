using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.Coordinator
{
    // CodeFile keeps this existing placeholder route runnable without editing the shared project file.
    public partial class ContactInboxPage : Page
    {
        private static readonly HttpClient Client = new HttpClient(new HttpClientHandler { AllowAutoRedirect = false, UseCookies = false })
        { Timeout = TimeSpan.FromSeconds(15), MaxResponseContentBufferSize = 1024 * 1024 };
        protected override void OnInit(EventArgs e)
        {
            ViewStateUserKey = Session.SessionID;
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            Response.Cache.SetNoStore();
            AuthHelper.RequireAuth(this, AuthHelper.RoleCoordinator);
            base.OnInit(e);
        }
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Response.IsRequestBeingRedirected) return;
            RegisterAsyncTask(new PageAsyncTask(LoadInboxAsync));
        }
        protected void Search_Click(object sender, EventArgs e) { }
        protected void Reload_Click(object sender, EventArgs e) { SearchInput.Text = ""; }
        protected async Task LoadInboxAsync()
        {
            // Keep the search controls present through every Web Forms postback.
            // Only the message results change; an error must not remove the toolbar.
            Workspace.Visible = true; NoticePanel.Visible = false; EmptyPanel.Visible = false;
            Messages.DataSource = null; Messages.DataBind();
            Summary.Text = "Loading messages...";
            try
            {
                if (IsPostBack && !IsValidPostback()) throw new InboxAccessException("Your form session has expired. Reload this page before searching.");
                var query = (SearchInput.Text ?? "").Trim();
                if (query.Length > 100) throw new InboxAccessException("Keep your search to 100 characters or fewer.");
                var rows = await ReadInboxAsync();
                var matches = ContactInboxRepository.Filter(rows, query);
                Messages.DataSource = matches; Messages.DataBind();
                Summary.Text = matches.Count.ToString(CultureInfo.InvariantCulture) + " matching messages · " + rows.Count.ToString(CultureInfo.InvariantCulture) + " saved in total";
                EmptyPanel.Visible = matches.Count == 0;
                EmptyHeading.Text = rows.Count == 0 ? "No messages yet" : "No matching messages";
                EmptyText.Text = rows.Count == 0 ? "Messages will appear here after Firebase confirms a Contact Us submission." : "Try a different name, email or subject, or choose Reload.";
                Workspace.Visible = true;
                ViewState["ContactInbox.Session"] = Session.SessionID;
            }
            catch (InboxAccessException error) { Show(error.Message); }
            catch (HttpRequestException) { Show("Firebase could not be reached or returned more data than this inbox can safely load. Try again or ask the Firebase owner to review access."); }
            catch (TaskCanceledException) { Show("The message service timed out. Please reload and try again."); }
            catch (Exception) { Show("Messages are unavailable right now. No messages were changed. Please retry or contact the Firebase owner."); }
        }
        // Production reads still perform the same token, role and record-ownership checks.
        // The virtual boundary lets offline regression tests exercise real page binding.
        protected virtual Task<List<ContactInboxRow>> ReadInboxAsync()
        {
            var repository = new ContactInboxRepository(Client, AppConfig.DbUrl, AppConfig.ApiKey);
            return repository.LoadAsync(Session["userId"] as string, Session["dbRecordId"] as string,
                Session["dbTable"] as string, Session["role"] as string, Session["idToken"] as string);
        }
        private bool IsValidPostback() { return string.Equals(ViewState["ContactInbox.Session"] as string, Session.SessionID, StringComparison.Ordinal); }
        private void Show(string text)
        {
            Notice.Text = text; NoticePanel.Visible = true;
            Summary.Text = "Messages could not be loaded. Search or reload to try again.";
        }
    }
    public sealed class InboxAccessException : Exception { public InboxAccessException(string message) : base(message) { } }
    public sealed class ContactInboxRow
    {
        public string FullName { get; set; }
        public string Email { get; set; }
        public string Subject { get; set; }
        public string Message { get; set; }
        public DateTimeOffset? Created { get; set; }
        public string DateLabel { get { return Created.HasValue ? Created.Value.UtcDateTime.ToString("dd MMM yyyy HH:mm 'UTC'", CultureInfo.InvariantCulture) : "Date not provided"; } }
    }
    public sealed class ContactInboxRepository
    {
        private readonly HttpClient client;
        private readonly Uri database;
        private readonly string apiKey;
        private readonly string project;
        public ContactInboxRepository(HttpClient client, string databaseUrl, string apiKey)
        {
            Uri uri;
            if (client == null || string.IsNullOrWhiteSpace(apiKey) || !Uri.TryCreate(databaseUrl, UriKind.Absolute, out uri)
                || uri.Scheme != Uri.UriSchemeHttps || !uri.IsDefaultPort || uri.AbsolutePath != "/" || uri.Query.Length != 0
                || uri.Fragment.Length != 0 || uri.UserInfo.Length != 0 || !(uri.Host.EndsWith(".firebaseio.com", StringComparison.OrdinalIgnoreCase)
                    || uri.Host.EndsWith(".firebasedatabase.app", StringComparison.OrdinalIgnoreCase)))
                throw new InboxAccessException("The team's Firebase HTTPS configuration is unavailable.");
            this.client = client; database = uri; this.apiKey = apiKey;
            string host = uri.Host.Split('.')[0]; const string suffix = "-default-rtdb";
            if (uri.Host.EndsWith(".firebasedatabase.app", StringComparison.OrdinalIgnoreCase) && !host.EndsWith(suffix, StringComparison.Ordinal))
                throw new InboxAccessException("The Firebase project identity needs team review.");
            project = host.EndsWith(suffix, StringComparison.Ordinal) ? host.Substring(0, host.Length - suffix.Length) : host;
        }
        public async Task<List<ContactInboxRow>> LoadAsync(string uid, string key, string table, string role, string token)
        {
            if (table != "Admins" || !string.Equals(role, AuthHelper.RoleCoordinator, StringComparison.OrdinalIgnoreCase))
                throw new InboxAccessException("Only an authenticated coordinator account can read contact messages.");
            ValidateKey(uid); ValidateKey(key);
            if (string.IsNullOrWhiteSpace(token) || token.Length > 16384 || token == "mock-token")
                throw new InboxAccessException("A verified Firebase login is required. Sign in through the team login.");
            JObject account;
            using (var request = new HttpRequestMessage(HttpMethod.Post, "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=" + Uri.EscapeDataString(apiKey)))
            {
                request.Content = new StringContent(JsonConvert.SerializeObject(new { idToken = token }), Encoding.UTF8, "application/json");
                var verified = await SendAsync(request, true);
                var users = verified["users"] as JArray;
                account = users != null && users.Count == 1 ? users[0] as JObject : null;
                if (account == null || (string)account["localId"] != uid || (bool?)account["disabled"] == true)
                    throw new InboxAccessException("Your Firebase identity does not match the coordinator session. Sign in again.");
            }
            VerifyClaims(token, uid, account);
            var admin = await ReadAsync("Admins/" + Uri.EscapeDataString(key), token);
            if (!OwnsAdmin(admin, key, uid)) throw new InboxAccessException("Admins/" + key + " is not linked to your verified Firebase UID. The Firebase owner must set its AuthUid to this account's UID, or use the UID as its record key. Email alone cannot prove ownership.");
            return Parse(await ReadAsync("ContactMessages", token));
        }
        public static bool OwnsAdmin(JToken record, string key, string uid)
        {
            if (record == null || record.Type != JTokenType.Object || string.IsNullOrWhiteSpace(uid)) return false;
            string role = (string)record["Role"], linked = (string)record["AuthUid"];
            if (!(string.Equals(role, "Admin", StringComparison.OrdinalIgnoreCase) || string.Equals(role, "Coordinator", StringComparison.OrdinalIgnoreCase))) return false;
            return !string.IsNullOrEmpty(linked) ? string.Equals(linked, uid, StringComparison.Ordinal) : string.Equals(key, uid, StringComparison.Ordinal);
        }
        private static void ValidateKey(string value)
        {
            if (string.IsNullOrWhiteSpace(value) || value.Length > 128 || value.Any(c => char.IsControl(c) || ".#$[]/\\?%".IndexOf(c) >= 0))
                throw new InboxAccessException("The coordinator record mapping is missing or invalid. Sign in through the team login.");
        }
        private void VerifyClaims(string token, string uid, JObject account)
        {
            try
            {
                var parts = token.Split('.'); if (parts.Length != 3 || string.IsNullOrEmpty(parts[2])) throw new FormatException();
                var header = Decode(parts[0]); var claims = Decode(parts[1]); long now = DateTimeOffset.UtcNow.ToUnixTimeSeconds(), revoked;
                if ((string)header["alg"] != "RS256" || (string)claims["sub"] != uid || (string)claims["aud"] != project
                    || (string)claims["iss"] != "https://securetoken.google.com/" + project || claims["exp"]?.Type != JTokenType.Integer
                    || claims["iat"]?.Type != JTokenType.Integer || claims["auth_time"]?.Type != JTokenType.Integer
                    || (long)claims["exp"] <= now || (long)claims["iat"] < 0 || (long)claims["iat"] > now + 300
                    || (long)claims["auth_time"] < 0 || (long)claims["auth_time"] > now + 300 || (long)claims["exp"] <= (long)claims["iat"]
                    || (long.TryParse((string)account["validSince"], out revoked) && (long)claims["auth_time"] < revoked)) throw new FormatException();
            }
            catch (Exception error) when (error is FormatException || error is JsonException || error is ArgumentException || error is InvalidCastException || error is OverflowException)
            { throw new InboxAccessException("Your Firebase session is expired or belongs to another project. Sign in again."); }
        }
        private static JObject Decode(string part)
        {
            if (part.Length == 0 || part.Any(c => !(char.IsLetterOrDigit(c) || c == '-' || c == '_'))) throw new FormatException();
            string value = part.Replace('-', '+').Replace('_', '/');
            return JObject.Parse(Encoding.UTF8.GetString(Convert.FromBase64String(value.PadRight((value.Length + 3) / 4 * 4, '='))), new JsonLoadSettings { DuplicatePropertyNameHandling = DuplicatePropertyNameHandling.Error });
        }
        private async Task<JToken> ReadAsync(string path, string token)
        {
            using (var request = new HttpRequestMessage(HttpMethod.Get, new Uri(database, path + ".json?auth=" + Uri.EscapeDataString(token)))) return await SendAsync(request, false);
        }
        private async Task<JToken> SendAsync(HttpRequestMessage request, bool authentication)
        {
            using (var response = await client.SendAsync(request))
            {
                if (response.StatusCode == HttpStatusCode.Unauthorized || response.StatusCode == HttpStatusCode.Forbidden)
                    throw new InboxAccessException(authentication ? "Firebase could not verify your login. Sign in again." : "Firebase denied access. The database owner must approve reads of your Admins record and ContactMessages for verified staff. No permissions were bypassed.");
                if (!response.IsSuccessStatusCode) throw new InboxAccessException("Firebase could not load messages. Please retry later; no data was changed.");
                string json = await response.Content.ReadAsStringAsync();
                if (json.Length > 1024 * 1024) throw new InboxAccessException("The message collection is too large for this inbox. Pagination must be agreed before loading more data.");
                return JToken.Parse(json, new JsonLoadSettings { DuplicatePropertyNameHandling = DuplicatePropertyNameHandling.Error });
            }
        }
        public static List<ContactInboxRow> Parse(JToken data)
        {
            var rows = new List<ContactInboxRow>();
            if (data == null || data.Type == JTokenType.Null) return rows;
            var collection = data as JObject;
            if (collection == null || collection.Count > 500) throw new InboxAccessException("The message collection has an unsupported structure or exceeds the 500-message limit. Ask the team to agree pagination.");
            foreach (var item in collection.Properties())
            {
                var row = item.Value as JObject; if (row == null) throw new InboxAccessException("A stored message has an unsupported format. Ask the database owner to review it.");
                DateTimeOffset parsed;
                rows.Add(new ContactInboxRow { FullName = Text(row, "FullName", 100), Email = Text(row, "Email", 254), Subject = Text(row, "Subject", 150), Message = Text(row, "Message", 4000),
                    Created = DateTimeOffset.TryParse((string)row["CreatedUtc"], CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal, out parsed) ? (DateTimeOffset?)parsed : null });
            }
            return rows.OrderByDescending(row => row.Created ?? DateTimeOffset.MinValue).ToList();
        }
        private static string Text(JObject row, string key, int maximum)
        {
            var value = row[key]; if (value == null || value.Type == JTokenType.Null) return "Not provided";
            if (value.Type != JTokenType.String || ((string)value).Length > maximum) throw new InboxAccessException("A stored message does not match the Contact Us field contract. Ask the database owner to review it.");
            return string.IsNullOrWhiteSpace((string)value) ? "Not provided" : (string)value;
        }
        public static List<ContactInboxRow> Filter(IEnumerable<ContactInboxRow> rows, string query)
        {
            query = (query ?? "").Trim();
            if (query.Length > 100) throw new InboxAccessException("Keep your search to 100 characters or fewer.");
            return rows.Where(row => query.Length == 0 || new[] { row.FullName, row.Email, row.Subject, row.Message }.Any(value => (value ?? "").IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0)).ToList();
        }
    }
}
