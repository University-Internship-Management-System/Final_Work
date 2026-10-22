using System;
using System.Collections.Generic;
using System.Linq;
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
        private static readonly HttpClient Client = new HttpClient(new HttpClientHandler { AllowAutoRedirect = false })
        { Timeout = TimeSpan.FromSeconds(15) };
        private readonly IContactBackendAuthorization authorization;
        private readonly HttpClient client;
        private readonly Uri database;

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

        public bool IsAvailable { get { return database != null && authorization != null && authorization.ContactMessagesApproved; } }

        public async Task SaveAsync(Guid submissionId, ContactMessage message)
        {
            if (!IsAvailable) throw new InvalidOperationException("Secure contact submission is not configured.");
            if (submissionId == Guid.Empty || ContactValidation.Validate(message).Count != 0)
                throw new ArgumentException("Invalid contact message.");
            var token = await authorization.GetOAuthAccessTokenAsync();
            if (string.IsNullOrWhiteSpace(token)) throw new InvalidOperationException("Backend authorization unavailable.");
            // Fixed collection, server-generated id, explicit allowlisted payload. No browser database access.
            var payload = new ContactMessage { FullName = message.FullName, Email = message.Email,
                Subject = message.Subject, Message = message.Message, CreatedUtc = DateTime.UtcNow.ToString("o") };
            var json = JsonConvert.SerializeObject(payload);
            using (var request = new HttpRequestMessage(HttpMethod.Put, new Uri(database, "ContactMessages/" + submissionId.ToString("N") + ".json")))
            {
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
                request.Headers.TryAddWithoutValidation("if-match", "null_etag"); // Create only; no overwrites/replay.
                request.Content = new StringContent(json, Encoding.UTF8, "application/json");
                using (var response = await client.SendAsync(request))
                {
                    if (!response.IsSuccessStatusCode) throw new HttpRequestException("Contact persistence was not confirmed.");
                    var confirmed = JToken.Parse(await response.Content.ReadAsStringAsync());
                    if (!JToken.DeepEquals(JToken.Parse(json), confirmed))
                        throw new HttpRequestException("Contact persistence was not confirmed.");
                }
            }
        }
    }
}
