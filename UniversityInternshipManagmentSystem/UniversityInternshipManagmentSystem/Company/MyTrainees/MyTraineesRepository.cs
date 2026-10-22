using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;
using ApplicationRecord = UniversityInternshipManagmentSystem.Models.Application;
using StudentRecord = UniversityInternshipManagmentSystem.Models.Student;

namespace UniversityInternshipManagmentSystem.Company.MyTraineesModule
{
    public sealed class TraineesUnavailableException : Exception
    {
        public TraineesUnavailableException(string message) : base(message) { }
    }

    // Proposed deployment gate, NOT a claim about existing Rules or confirmation policy.
    // Only trusted server startup may provide this after the team approves BOTH queries,
    // the confirmation policy, and any student contact disclosure. Never read from HTTP/Session.
    public sealed class MyTraineesReadApproval
    {
        public bool CompanyScopedQueriesApproved { get; private set; }
        public bool ConfirmedApplicationAndAssignmentApproved { get; private set; }
        public bool UniversityEmailDisclosureApproved { get; private set; }
        public MyTraineesReadApproval(bool queries, bool confirmation, bool universityEmail)
        {
            CompanyScopedQueriesApproved = queries;
            ConfirmedApplicationAndAssignmentApproved = confirmation;
            UniversityEmailDisclosureApproved = universityEmail;
        }
    }

    public sealed class VerifiedCompany
    {
        public string RecordKey { get; private set; }
        public string CompanyName { get; private set; }
        internal string Uid { get; private set; }
        internal string Token { get; private set; }
        internal DateTimeOffset Expires { get; private set; }
        internal VerifiedCompany(string key, string name, string uid, string token, DateTimeOffset expires)
        { RecordKey = key; CompanyName = name; Uid = uid; Token = token; Expires = expires; }
    }

    public sealed class TraineeRow
    {
        public string Name { get; internal set; }
        public string Major { get; internal set; }
        public string Contact { get; internal set; }
    }

    public static class TraineesValidation
    {
        public static bool TrySearch(string input, out string normalized)
        {
            normalized = (input ?? "").Trim();
            return normalized.Length <= 100 && !normalized.Any(c => char.IsControl(c) || c == '<' || c == '>');
        }
        internal static void RequireKey(string key)
        {
            if (string.IsNullOrWhiteSpace(key) || key.Length > 128
                || key.Any(c => char.IsControl(c) || ".#$[]/\\?%".IndexOf(c) >= 0))
                throw new UnauthorizedAccessException("The company record mapping is invalid. Sign in again or contact the account administrator.");
        }
    }

    public sealed class MyTraineesRepository
    {
        private static readonly HttpClient Client = new HttpClient(new HttpClientHandler
        { AllowAutoRedirect = false, UseCookies = false }) { Timeout = TimeSpan.FromSeconds(15) };
        private readonly HttpClient client;
        private readonly Uri database;
        private readonly string apiKey;
        private readonly string project;
        public MyTraineesRepository() : this(Client, AppConfig.DbUrl, AppConfig.ApiKey) { }
        // Offline tests may supply a fake transport; no request can choose a transport or database.
        internal MyTraineesRepository(HttpClient client, string databaseUrl, string apiKey)
        {
            Uri parsed;
            if (!Uri.TryCreate(databaseUrl, UriKind.Absolute, out parsed) || parsed.Scheme != "https"
                || !parsed.IsDefaultPort || parsed.AbsolutePath != "/" || !string.IsNullOrEmpty(parsed.Query)
                || !string.IsNullOrEmpty(parsed.Fragment) || !string.IsNullOrEmpty(parsed.UserInfo)
                || !(parsed.Host.EndsWith(".firebasedatabase.app", StringComparison.OrdinalIgnoreCase)
                    || parsed.Host.EndsWith(".firebaseio.com", StringComparison.OrdinalIgnoreCase)))
                throw new TraineesUnavailableException("The team Firebase HTTPS database configuration is unavailable.");
            database = parsed;
            var name = parsed.Host.Split('.')[0];
            const string suffix = "-default-rtdb";
            if (parsed.Host.EndsWith(".firebasedatabase.app", StringComparison.OrdinalIgnoreCase) && !name.EndsWith(suffix, StringComparison.Ordinal))
                throw new TraineesUnavailableException("A named database needs an approved Firebase project mapping before activation.");
            project = name.EndsWith(suffix, StringComparison.Ordinal) ? name.Substring(0, name.Length - suffix.Length) : name;
            if (string.IsNullOrWhiteSpace(apiKey)) throw new TraineesUnavailableException("The team's Firebase API configuration is unavailable.");
            this.client = client;
            this.apiKey = apiKey;
        }

        public async Task<VerifiedCompany> VerifySupervisorAsync(HttpContextBase context)
        {
            var session = context == null ? null : context.Session;
            if (session == null || string.IsNullOrWhiteSpace(session["userId"] as string))
                throw new UnauthorizedAccessException("Sign in through the team login with your company supervisor account.");
            if (!string.Equals(session["role"] as string, AuthHelper.RoleCompany, StringComparison.OrdinalIgnoreCase))
                throw new UnauthorizedAccessException("Only an authorized company supervisor can access this trainee list.");
            bool firstLogin;
            if (bool.TryParse(Convert.ToString(session["firstLogin"]), out firstLogin) && firstLogin)
                throw new UnauthorizedAccessException("Complete the team's first-login steps before opening My Trainees.");
            var table = session["dbTable"] as string;
            if (!string.IsNullOrEmpty(table) && table != "CompanySupervisors")
                throw new UnauthorizedAccessException("Your session is not mapped to a company supervisor account.");
            var uid = session["userId"] as string;
            var key = (session["dbRecordId"] as string) ?? uid;
            TraineesValidation.RequireKey(uid);
            TraineesValidation.RequireKey(key);
            var token = session["idToken"] as string;
            if (string.IsNullOrWhiteSpace(token) || token.Length > 16384)
                throw new UnauthorizedAccessException("Your Firebase session is unavailable. Sign in again.");
            // Firebase validates the existing token server-side; this is account lookup, NOT sign-in.
            var account = await LookupAccountAsync(token).ConfigureAwait(false);
            if ((string)account["localId"] != uid || (bool?)account["disabled"] == true)
                throw new UnauthorizedAccessException("The Firebase account does not match your team session.");
            var expires = ValidateVerifiedClaims(token, uid, account);
            var record = await ReadAsync("CompanySupervisors/" + Uri.EscapeDataString(key), token, null).ConfigureAwait(false);
            if (record.Type != JTokenType.Object || !OwnsCompany(record, key, uid)
                || !string.Equals((string)record["Role"], "CompanySupervisor", StringComparison.OrdinalIgnoreCase))
                throw new UnauthorizedAccessException("Your company record cannot be linked to your verified Firebase UID. Ask the account owner to correct the mapping.");
            var company = record.ToObject<CompanySupervisor>();
            return new VerifiedCompany(key, string.IsNullOrWhiteSpace(company.CompanyName) ? "Company name unavailable" : company.CompanyName,
                uid, token, expires);
        }

        private async Task<JToken> LookupAccountAsync(string token)
        {
            using (var request = new HttpRequestMessage(HttpMethod.Post,
                "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=" + Uri.EscapeDataString(apiKey)))
            {
                request.Content = new StringContent(JsonConvert.SerializeObject(new { idToken = token }), Encoding.UTF8, "application/json");
                var payload = await SendAsync(request, true).ConfigureAwait(false);
                var users = payload["users"] as JArray;
                if (users == null || users.Count != 1) throw new UnauthorizedAccessException("Your Firebase identity could not be verified. Sign in again.");
                return users[0];
            }
        }

        private DateTimeOffset ValidateVerifiedClaims(string token, string uid, JToken account)
        {
            // Claims are trusted only AFTER Firebase accepts the token above. Local decoding alone is never proof.
            try
            {
                var parts = token.Split('.');
                if (parts.Length != 3) throw new FormatException();
                var header = JObject.Parse(Decode(parts[0]));
                var claims = JObject.Parse(Decode(parts[1]), new JsonLoadSettings { DuplicatePropertyNameHandling = DuplicatePropertyNameHandling.Error });
                var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
                // A computer clock that is a few seconds behind Google's would reject a token that was JUST issued,
                // so "issued in the future" gets 5 minutes of room.
                const long skew = 300;
                long validSince;
                if ((string)header["alg"] != "RS256" || (string)claims["sub"] != uid
                    || (string)claims["aud"] != project || (string)claims["iss"] != "https://securetoken.google.com/" + project
                    || claims["exp"] == null || claims["exp"].Type != JTokenType.Integer
                    || claims["iat"] == null || claims["iat"].Type != JTokenType.Integer
                    || claims["auth_time"] == null || claims["auth_time"].Type != JTokenType.Integer
                    || (long)claims["exp"] <= now || (long)claims["iat"] > now + skew || (long)claims["iat"] < 0
                    || (long)claims["exp"] <= (long)claims["iat"] || (long)claims["auth_time"] > now + skew || (long)claims["auth_time"] < 0
                    || (long.TryParse((string)account["validSince"], out validSince) && (long)claims["auth_time"] < validSince))
                    throw new FormatException();
                return DateTimeOffset.FromUnixTimeSeconds((long)claims["exp"]);
            }
            catch (Exception error) when (error is FormatException || error is JsonException || error is ArgumentException || error is InvalidCastException)
            { throw new UnauthorizedAccessException("Your Firebase token project, identity or lifetime could not be verified. Sign in again."); }
        }

        private static string Decode(string part)
        {
            if (part.Any(c => !(char.IsLetterOrDigit(c) || c == '-' || c == '_'))) throw new FormatException();
            var text = part.Replace('-', '+').Replace('_', '/');
            return Encoding.UTF8.GetString(Convert.FromBase64String(text.PadRight((text.Length + 3) / 4 * 4, '=')));
        }

        internal static bool OwnsCompany(JToken record, string key, string uid)
        {
            var owner = record["AuthUid"];
            if (owner != null && owner.Type != JTokenType.Null)
                return owner.Type == JTokenType.String && (string)owner == uid;
            return key == uid;
        }

        public async Task<IList<TraineeRow>> GetConfirmedTraineesAsync(VerifiedCompany company, MyTraineesReadApproval approval)
        {
            if (company == null || company.Expires <= DateTimeOffset.UtcNow)
                throw new UnauthorizedAccessException("Your verified company session has expired. Sign in again.");
            if (approval == null || !approval.CompanyScopedQueriesApproved || !approval.ConfirmedApplicationAndAssignmentApproved)
                throw new TraineesUnavailableException("Trainee reads are not enabled: the team must approve company-scoped permissions and the trainee confirmation policy.");
            var query = "&orderBy=" + Uri.EscapeDataString(JsonConvert.SerializeObject("CompanyId"))
                + "&equalTo=" + Uri.EscapeDataString(JsonConvert.SerializeObject(company.RecordKey));
            var students = await ReadAsync("Students", company.Token, query).ConfigureAwait(false);
            var applications = await ReadAsync("Applications", company.Token, query).ConfigureAwait(false);
            return SelectConfirmed(students, applications, company.RecordKey, approval.UniversityEmailDisclosureApproved);
        }

        internal static IList<TraineeRow> SelectConfirmed(JToken students, JToken applications, string companyKey, bool contactApproved)
        {
            var people = ReadObject<StudentRecord>(students);
            var apps = ReadObject<ApplicationRecord>(applications);
            if (people.Values.Any(s => s == null || s.CompanyId != companyKey)
                || apps.Values.Any(a => a == null || a.CompanyId != companyKey))
                throw new UnauthorizedAccessException("Firebase returned records outside your authorized company scope.");
            var confirmed = new HashSet<string>(apps.Values.Where(a => a.Status == ApplicationStatus.Confirmed
                && !string.IsNullOrWhiteSpace(a.StudentId)).Select(a => a.StudentId), StringComparer.Ordinal);
            return people.Where(p => confirmed.Contains(p.Key)).Select(p => new TraineeRow
            {
                Name = string.IsNullOrWhiteSpace(p.Value.Name) ? "Name unavailable" : p.Value.Name,
                Major = string.IsNullOrWhiteSpace(p.Value.Major) ? "Major unavailable" : p.Value.Major,
                Contact = contactApproved && !string.IsNullOrWhiteSpace(p.Value.UniEmail) ? p.Value.UniEmail : ""
            }).OrderBy(row => row.Name, StringComparer.OrdinalIgnoreCase).ToList();
        }

        private static Dictionary<string, T> ReadObject<T>(JToken token)
        {
            if (token.Type == JTokenType.Null) return new Dictionary<string, T>();
            if (token.Type != JTokenType.Object) throw new TraineesUnavailableException("Firebase returned an invalid trainee data format.");
            return token.ToObject<Dictionary<string, T>>();
        }

        private async Task<JToken> ReadAsync(string path, string token, string query)
        {
            using (var request = new HttpRequestMessage(HttpMethod.Get, new Uri(database,
                path + ".json?auth=" + Uri.EscapeDataString(token) + (query ?? ""))))
                return await SendAsync(request, false).ConfigureAwait(false);
        }

        private async Task<JToken> SendAsync(HttpRequestMessage request, bool authentication)
        {
            try
            {
                using (var response = await client.SendAsync(request).ConfigureAwait(false))
                {
                    if (!response.IsSuccessStatusCode)
                    {
                        if (authentication) throw new UnauthorizedAccessException("Firebase could not verify your existing login. Sign in again.");
                        if (response.StatusCode == HttpStatusCode.Forbidden || response.StatusCode == HttpStatusCode.Unauthorized)
                            throw new TraineesUnavailableException("Firebase denied this read. The account mapping, company query permissions and indexes require team review.");
                        throw new TraineesUnavailableException("The trainee data service is unavailable. Please try again later.");
                    }
                    return JToken.Parse(await response.Content.ReadAsStringAsync().ConfigureAwait(false));
                }
            }
            catch (HttpRequestException) { throw new TraineesUnavailableException("Firebase could not be reached. Please try again later."); }
            catch (TaskCanceledException) { throw new TraineesUnavailableException("The request timed out. Please try again later."); }
            catch (JsonException) { throw new TraineesUnavailableException("Firebase returned an unreadable response."); }
        }
    }
}
