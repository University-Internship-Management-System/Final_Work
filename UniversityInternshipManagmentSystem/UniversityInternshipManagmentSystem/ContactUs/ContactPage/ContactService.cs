using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Mail;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.ContactModule
{
    public sealed class ContactMessage
    {
        public string FullName { get; set; }
        public string Email { get; set; }
        public string Subject { get; set; }
        public string Message { get; set; }
        public string CreatedUtc { get; set; }
    }

    public static class ContactValidation
    {
        public static IDictionary<string, string> Validate(ContactMessage value)
        {
            var errors = new Dictionary<string, string>();
            Check(errors, "FullName", value.FullName, "Full name", 100);
            Check(errors, "Email", value.Email, "Email address", 254);
            Check(errors, "Subject", value.Subject, "Subject", 150);
            Check(errors, "Message", value.Message, "Message", 4000, true);
            if (!errors.ContainsKey("Email"))
            {
                try
                {
                    var address = new MailAddress(value.Email);
                    if (address.Address != value.Email || !address.Host.Contains("."))
                        errors["Email"] = "Enter a valid email address.";
                }
                catch (FormatException) { errors["Email"] = "Enter a valid email address."; }
            }
            return errors;
        }

        private static void Check(IDictionary<string, string> errors, string field, string value, string label, int max, bool multiline = false)
        {
            if (string.IsNullOrWhiteSpace(value)) errors[field] = label + " is required.";
            else if (value.Length > max) errors[field] = label + " must be " + max + " characters or fewer.";
            else if (value.Any(c => char.IsControl(c) && !(multiline && (c == '\r' || c == '\n' || c == '\t')))
                || value.IndexOfAny(new[] { '<', '>' }) >= 0)
                errors[field] = label + " must contain plain text without HTML or control characters.";
        }
    }

    // Registered SERVER-SIDE by the team after backend identity, schema and Rules approval.
    // Never populate from request fields, browser tokens, or the isolated Student test session.
    public interface IContactBackendAuthorization
    {
        bool ContactMessagesApproved { get; }
        Task<string> GetOAuthAccessTokenAsync();
    }

    public sealed class ContactRepository
    {
        private static readonly HttpClient Client = new HttpClient(new HttpClientHandler { AllowAutoRedirect = false, UseCookies = false })
        { Timeout = TimeSpan.FromSeconds(15) };
        private readonly IContactBackendAuthorization authorization;
        private readonly HttpClient client;
        private readonly Uri database;

        private readonly HttpSessionStateBase sender;
        private readonly string apiKey;

        public static ContactRepository ForSignedInUser(HttpSessionStateBase session)
        {
            return new ContactRepository(session, Client, AppConfig.DbUrl, AppConfig.ApiKey);
        }
        internal ContactRepository(HttpSessionStateBase session, HttpClient transport, string url, string key)
            : this((IContactBackendAuthorization)null, transport, url)
        { sender = session; apiKey = key; }

        public ContactRepository(IContactBackendAuthorization authorization)
            : this(authorization, Client, AppConfig.DbUrl) { }

        internal ContactRepository(IContactBackendAuthorization authorization, HttpClient client, string databaseUrl)
        {
            this.authorization = authorization;
            this.client = client;
            Uri parsed;
            if (Uri.TryCreate(databaseUrl, UriKind.Absolute, out parsed) && parsed.Scheme == "https"
                && parsed.IsDefaultPort && string.IsNullOrEmpty(parsed.UserInfo)
                && string.IsNullOrEmpty(parsed.Query) && string.IsNullOrEmpty(parsed.Fragment)
                && parsed.AbsolutePath == "/"
                && (parsed.Host.EndsWith(".firebasedatabase.app", StringComparison.OrdinalIgnoreCase)
                    || parsed.Host.EndsWith(".firebaseio.com", StringComparison.OrdinalIgnoreCase))) database = parsed;
        }

        public bool SignInRequired
        {
            get
            {
                if (sender == null) return false;
                string uid = sender["userId"] as string, token = sender["idToken"] as string;
                bool firstLogin;
                return string.IsNullOrWhiteSpace(uid) || uid.Length > 128 || uid.Any(char.IsControl)
                    || string.IsNullOrWhiteSpace(token) || token.Length > 16384
                    || !new[] { "student", "company", "academic", "coordinator" }.Contains((sender["role"] as string ?? "").ToLowerInvariant())
                    || (bool.TryParse(Convert.ToString(sender["firstLogin"]), out firstLogin) && firstLogin);
            }
        }
        public bool IsAvailable
        {
            get { return database != null && (sender != null ? !SignInRequired && !string.IsNullOrWhiteSpace(apiKey)
                : authorization != null && authorization.ContactMessagesApproved); }
        }

        private async Task<string> VerifiedSenderTokenAsync()
        {
            if (SignInRequired) throw new ContactSubmissionException("Sign in through the UIMS team login before sending a message.");
            string uid = (string)sender["userId"], token = (string)sender["idToken"];
            string host = database.Host.Split('.')[0];
            const string suffix = "-default-rtdb";
            if (database.Host.EndsWith(".firebasedatabase.app", StringComparison.OrdinalIgnoreCase) && !host.EndsWith(suffix, StringComparison.Ordinal))
                throw new ContactSubmissionException("The configured Firebase project needs team review. Your message was not sent.");
            string project = host.EndsWith(suffix, StringComparison.Ordinal) ? host.Substring(0, host.Length - suffix.Length) : host;
            JObject account;
            using (var request = new HttpRequestMessage(HttpMethod.Post,
                "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=" + Uri.EscapeDataString(apiKey)))
            {
                request.Content = new StringContent(JsonConvert.SerializeObject(new { idToken = token }), Encoding.UTF8, "application/json");
                using (var response = await client.SendAsync(request))
                {
                    if (!response.IsSuccessStatusCode) throw new ContactSubmissionException("Firebase could not verify your login. Sign in again before sending a message.");
                    var users = JObject.Parse(await response.Content.ReadAsStringAsync())["users"] as JArray;
                    account = users != null && users.Count == 1 ? users[0] as JObject : null;
                    if (account == null || (string)account["localId"] != uid || (bool?)account["disabled"] == true)
                        throw new ContactSubmissionException("Your verified Firebase identity does not match the UIMS session. Sign in again.");
                }
            }
            // Local claims are checked only AFTER Google verifies the signed token.
            try
            {
                var parts = token.Split('.');
                if (parts.Length != 3 || string.IsNullOrEmpty(parts[2])) throw new FormatException();
                var header = DecodeTokenPart(parts[0]); var claims = DecodeTokenPart(parts[1]);
                long now = DateTimeOffset.UtcNow.ToUnixTimeSeconds(), revoked;
                if ((string)header["alg"] != "RS256" || (string)claims["sub"] != uid || (string)claims["aud"] != project
                    || (string)claims["iss"] != "https://securetoken.google.com/" + project
                    || claims["exp"]?.Type != JTokenType.Integer || claims["iat"]?.Type != JTokenType.Integer
                    || claims["auth_time"]?.Type != JTokenType.Integer || (long)claims["exp"] <= now
                    || (long)claims["iat"] < 0 || (long)claims["iat"] > now + 300
                    || (long)claims["auth_time"] < 0 || (long)claims["auth_time"] > now + 300
                    || (long)claims["exp"] <= (long)claims["iat"]
                    || (long.TryParse((string)account["validSince"], out revoked) && (long)claims["auth_time"] < revoked))
                    throw new FormatException();
            }
            catch (Exception error) when (error is FormatException || error is JsonException || error is ArgumentException || error is InvalidCastException || error is OverflowException)
            { throw new ContactSubmissionException("Your Firebase session is expired or belongs to a different project. Sign in again."); }
            return token;
        }
        private static JObject DecodeTokenPart(string part)
        {
            if (part.Any(c => !(char.IsLetterOrDigit(c) || c == '-' || c == '_'))) throw new FormatException();
            string text = part.Replace('-', '+').Replace('_', '/');
            return JObject.Parse(Encoding.UTF8.GetString(Convert.FromBase64String(text.PadRight((text.Length + 3) / 4 * 4, '='))),
                new JsonLoadSettings { DuplicatePropertyNameHandling = DuplicatePropertyNameHandling.Error });
        }

        public async Task SaveAsync(Guid submissionId, ContactMessage message)
        {
            if (!IsAvailable) throw new InvalidOperationException("Secure contact submission is not configured.");
            if (submissionId == Guid.Empty || ContactValidation.Validate(message).Count != 0)
                throw new ArgumentException("Invalid contact message.");
            var token = sender != null ? await VerifiedSenderTokenAsync() : await authorization.GetOAuthAccessTokenAsync();
            if (string.IsNullOrWhiteSpace(token)) throw new InvalidOperationException("Backend authorization unavailable.");
            // Fixed collection, server-generated id, explicit allowlisted payload. No browser database access.
            var payload = new ContactMessage { FullName = message.FullName, Email = message.Email,
                Subject = message.Subject, Message = message.Message, CreatedUtc = DateTime.UtcNow.ToString("o") };
            var json = JsonConvert.SerializeObject(payload);
            using (var request = new HttpRequestMessage(HttpMethod.Put, new Uri(database, "ContactMessages/" + submissionId.ToString("N") + ".json"
                + (sender != null ? "?auth=" + Uri.EscapeDataString(token) : ""))))
            {
                if (sender == null) request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
                request.Headers.TryAddWithoutValidation("if-match", "null_etag"); // Create only; no overwrites/replay.
                request.Content = new StringContent(json, Encoding.UTF8, "application/json");
                using (var response = await client.SendAsync(request))
                {
                    if (response.StatusCode == HttpStatusCode.Forbidden || response.StatusCode == HttpStatusCode.Unauthorized)
                        throw new ContactSubmissionException("Firebase denied permission to create this contact message. The Firebase owner must approve authenticated message creation; no permissions were bypassed. Your message was not saved.");
                    if (response.StatusCode == HttpStatusCode.PreconditionFailed)
                        throw new ContactSubmissionException("This submission already exists. It was not overwritten. Avoid resending; reload the form for a new message.");
                    if (!response.IsSuccessStatusCode) throw new HttpRequestException("Contact persistence was not confirmed.");
                    var confirmed = JToken.Parse(await response.Content.ReadAsStringAsync());
                    if (!JToken.DeepEquals(JToken.Parse(json), confirmed))
                        throw new HttpRequestException("Contact persistence was not confirmed.");
                }
            }
        }
    }
    public sealed class ContactSubmissionException : HttpRequestException
    {
        public ContactSubmissionException(string message) : base(message) { }
    }

}
