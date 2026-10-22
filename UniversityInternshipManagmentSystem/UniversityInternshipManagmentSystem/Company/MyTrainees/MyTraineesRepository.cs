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
        internal string StudentKey { get; set; }
        internal string OpportunityId { get; set; }
        public string CompanyName { get; internal set; }
        public string OpportunityTitle { get; internal set; }
        public string Status { get; internal set; }
        public string StatusClass => Status == ApplicationStatus.Confirmed ? "trainees-status" : "trainees-status trainees-status-accepted";
        public string StatusText => Status == ApplicationStatus.Confirmed ? "Confirmed" : "Accepted — awaiting confirmation";
        public string ConfirmationDate { get; internal set; }
        public string AcademicSupervisor { get; internal set; }
        public int? AssignedTasks { get; internal set; }
        public int? SubmittedTasks { get; internal set; }
        public int? EvaluatedTasks { get; internal set; }
        public int? TaskProgressPercent { get; internal set; }
        public string AssignedText => AssignedTasks.HasValue ? AssignedTasks.Value.ToString() : "Not available";
        public string SubmittedText => SubmittedTasks.HasValue ? SubmittedTasks.Value.ToString() : "Not available";
        public string EvaluatedText => EvaluatedTasks.HasValue ? EvaluatedTasks.Value.ToString() : "Not available";
        public string ProgressText => TaskProgressPercent.HasValue ? TaskProgressPercent.Value + "% task submission progress" : "Progress not available";
        public string ProgressNote { get; internal set; } = "Progress not available.";
        public string ProgressValue => (TaskProgressPercent ?? 0).ToString(System.Globalization.CultureInfo.InvariantCulture);
        public string ProgressMeterClass => TaskProgressPercent.HasValue ? "trainees-progress-meter" : "trainees-progress-meter trainees-progress-unavailable";

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
                long validSince;
                if ((string)header["alg"] != "RS256" || (string)claims["sub"] != uid
                    || (string)claims["aud"] != project || (string)claims["iss"] != "https://securetoken.google.com/" + project
                    || claims["exp"] == null || claims["exp"].Type != JTokenType.Integer
                    || claims["iat"] == null || claims["iat"].Type != JTokenType.Integer
                    || claims["auth_time"] == null || claims["auth_time"].Type != JTokenType.Integer
                    || (long)claims["exp"] <= now || (long)claims["iat"] > now || (long)claims["iat"] < 0
                    || (long)claims["exp"] <= (long)claims["iat"] || (long)claims["auth_time"] > now || (long)claims["auth_time"] < 0
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

        public async Task<IList<TraineeRow>> GetTraineesAsync(VerifiedCompany company)
        {
            if (company == null || company.Expires <= DateTimeOffset.UtcNow)
                throw new UnauthorizedAccessException("Your verified company session has expired. Sign in again.");
            var applications = await ReadCompanyApplicationsAsync(company).ConfigureAwait(false);
            var apps = ReadObject<ApplicationRecord>(applications);
            if (apps.Values.Any(a => a == null || a.CompanyId != company.RecordKey))
                throw new UnauthorizedAccessException("Firebase returned applications outside your company scope.");
            var keys = apps.Values.Where(a => EligibleStatus(a.Status)).Select(a => a.StudentId)
                .Where(id => !string.IsNullOrWhiteSpace(id)).Distinct(StringComparer.Ordinal).ToList();
            if (keys.Count > 100) throw new TraineesUnavailableException("More than 100 eligible students exceeds this test-data read limit. A paged company-scoped query is required.");
            // Accepted students can be unassigned until confirmation. Read only application-linked IDs,
            // using this supervisor's token; never request an unfiltered Students collection.
            var students = new JObject();
            using (var slots = new System.Threading.SemaphoreSlim(4))
            {
                var reads = keys.Select(async key =>
                {
                    TraineesValidation.RequireKey(key);
                    await slots.WaitAsync().ConfigureAwait(false);
                    try { return new KeyValuePair<string, JToken>(key, await ReadAsync("Students/" + Uri.EscapeDataString(key), company.Token, null).ConfigureAwait(false)); }
                    finally { slots.Release(); }
                });
                foreach (var student in await Task.WhenAll(reads).ConfigureAwait(false))
                    if (student.Value.Type != JTokenType.Null) students[student.Key] = student.Value;
            }
            var rows = SelectEligible(students, applications, company.RecordKey, company.CompanyName);
            if (rows.Count == 0) return rows;
            // Optional enrichment failures must not erase a legitimately authorized directory.
            foreach (var row in rows.Where(r => r.OpportunityTitle == "Not available" && !string.IsNullOrWhiteSpace(r.OpportunityId)))
            {
                try
                {
                    TraineesValidation.RequireKey(row.OpportunityId);
                    var opportunity = await ReadAsync("Opportunities/" + Uri.EscapeDataString(row.OpportunityId), company.Token, null).ConfigureAwait(false);
                    if (opportunity.Type == JTokenType.Object && (string)opportunity["CompanyId"] == company.RecordKey)
                        row.OpportunityTitle = string.IsNullOrWhiteSpace((string)opportunity["Title"]) ? "Not available" : (string)opportunity["Title"];
                }
                catch (TraineesUnavailableException) { }
                catch (UnauthorizedAccessException) { }
            }
            Dictionary<string, Tasks> tasks;
            try
            {
                tasks = ReadObject<Tasks>(await ReadAsync("Tasks", company.Token, Query("CompanyId", company.RecordKey)).ConfigureAwait(false));
                if (tasks.Values.Any(t => t == null || t.CompanyId != company.RecordKey))
                    throw new UnauthorizedAccessException("Task scope mismatch.");
            }
            catch (Exception error) when (error is TraineesUnavailableException || error is UnauthorizedAccessException || error is JsonException)
            {
                foreach (var row in rows) row.ProgressNote = error is TraineesUnavailableException
                    ? "Progress not available: " + error.Message
                    : "Progress not available: company-scoped task reads or data format need team review.";
                return rows;
            }
            using (var slots = new System.Threading.SemaphoreSlim(4))
            {
                await Task.WhenAll(rows.Select(async row =>
                {
                    await slots.WaitAsync().ConfigureAwait(false);
                    try
                    {
                        var assigned = tasks.Where(t => InProgressScope(t.Value, row.StudentKey)).ToDictionary(t => t.Key, t => t.Value);
                        row.AssignedTasks = assigned.Count;
                        var submissions = assigned.Count == 0 ? JValue.CreateNull()
                            : await ReadAsync("TaskSubmissions", company.Token, Query("StudentId", row.StudentKey)).ConfigureAwait(false);
                        ApplyProgress(row, assigned, submissions);
                    }
                    catch (Exception error) when (error is TraineesUnavailableException || error is UnauthorizedAccessException || error is JsonException || error is ArgumentException)
                    { row.ProgressNote = error is TraineesUnavailableException
                        ? "Progress not available: " + error.Message
                        : "Progress not available: student-scoped submission access or data format needs team review."; }
                    finally { slots.Release(); }
                })).ConfigureAwait(false);
            }
            return rows;
        }

        // Small-test-dataset path explicitly authorized for this module. The unfiltered
        // collection never leaves this method, enters ViewState, or reaches page bindings.
        private async Task<JObject> ReadCompanyApplicationsAsync(VerifiedCompany company)
        {
            const int maxBytes = 512 * 1024;
            const int maxRecords = 1000;
            using (var timeout = new System.Threading.CancellationTokenSource(TimeSpan.FromSeconds(15)))
            using (var request = new HttpRequestMessage(HttpMethod.Get, new Uri(database,
                "Applications.json?auth=" + Uri.EscapeDataString(company.Token))))
            {
                try
                {
                    using (var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, timeout.Token).ConfigureAwait(false))
                    {
                        if (!response.IsSuccessStatusCode)
                            throw new TraineesUnavailableException("Firebase refused the authenticated full Applications read (HTTP "
                                + (int)response.StatusCode + "). The Firebase owner must review permission; no fallback or bypass was attempted.");
                        if (response.Content.Headers.ContentLength.HasValue && response.Content.Headers.ContentLength.Value > maxBytes)
                            throw new TraineesUnavailableException("Applications exceeds the 512 KiB test-data limit. A company-scoped indexed query is required.");
                        using (var input = await response.Content.ReadAsStreamAsync().ConfigureAwait(false))
                        using (var output = new System.IO.MemoryStream())
                        {
                            byte[] buffer = new byte[8192];
                            int count;
                            while ((count = await input.ReadAsync(buffer, 0, buffer.Length, timeout.Token).ConfigureAwait(false)) > 0)
                            {
                                if (output.Length + count > maxBytes)
                                    throw new TraineesUnavailableException("Applications exceeds the 512 KiB test-data limit. A company-scoped indexed query is required.");
                                output.Write(buffer, 0, count);
                            }
                            var raw = JToken.Parse(new UTF8Encoding(false, true).GetString(output.ToArray()),
                                new JsonLoadSettings { DuplicatePropertyNameHandling = DuplicatePropertyNameHandling.Error });
                            if (raw.Type == JTokenType.Null) return new JObject();
                            var all = raw as JObject;
                            if (all == null || all.Count > maxRecords)
                                throw new TraineesUnavailableException("Applications has an unsupported format or exceeds the 1000-record test-data limit. The read was stopped.");
                            var own = new JObject();
                            foreach (var entry in all.Properties())
                            {
                                var application = entry.Value as JObject;
                                if (application == null)
                                    throw new TraineesUnavailableException("Applications contains an invalid record. The read was stopped.");
                                if (application["CompanyId"]?.Type != JTokenType.String
                                    || (string)application["CompanyId"] != company.RecordKey
                                    || application["Status"]?.Type != JTokenType.String
                                    || !EligibleStatus((string)application["Status"])) continue;
                                own[entry.Name] = application.DeepClone();
                            }
                            return own;
                        }
                    }
                }
                catch (HttpRequestException) { throw new TraineesUnavailableException("Firebase could not be reached for the Applications read."); }
                catch (OperationCanceledException) { throw new TraineesUnavailableException("The bounded Applications read timed out. No trainee data was displayed."); }
                catch (System.IO.IOException) { throw new TraineesUnavailableException("The Applications response could not be read safely."); }
                catch (JsonException) { throw new TraineesUnavailableException("Firebase returned an invalid Applications response. No trainee data was displayed."); }
                catch (DecoderFallbackException) { throw new TraineesUnavailableException("Firebase returned invalid text in Applications."); }
            }
        }

        private static string Query(string field, string value)
        {
            return "&orderBy=" + Uri.EscapeDataString(JsonConvert.SerializeObject(field))
                + "&equalTo=" + Uri.EscapeDataString(JsonConvert.SerializeObject(value));
        }
        private static bool EligibleStatus(string status)
        {
            return status == ApplicationStatus.Accepted || status == ApplicationStatus.Confirmed;
        }
        internal static IList<TraineeRow> SelectEligible(JToken students, JToken applications, string companyKey, string companyName)
        {
            var people = ReadObject<StudentRecord>(students);
            var apps = ReadObject<ApplicationRecord>(applications);
            if (apps.Values.Any(a => a == null || a.CompanyId != companyKey))
                throw new UnauthorizedAccessException("Firebase returned applications outside your authorized company scope.");
            var result = new List<TraineeRow>();
            foreach (var group in apps.Where(a => EligibleStatus(a.Value.Status) && !string.IsNullOrWhiteSpace(a.Value.StudentId))
                .GroupBy(a => a.Value.StudentId, StringComparer.Ordinal))
            {
                StudentRecord student;
                if (!people.TryGetValue(group.Key, out student) || student == null) continue;
                // A stale acceptance never authorizes disclosure of a student assigned elsewhere.
                if (!string.IsNullOrWhiteSpace(student.CompanyId) && student.CompanyId != companyKey) continue;
                var chosen = group.Where(a => a.Value.Status != ApplicationStatus.Confirmed || student.CompanyId == companyKey)
                    .OrderByDescending(a => a.Value.Status == ApplicationStatus.Confirmed)
                    .ThenByDescending(a => a.Value.ConfirmedAt).ThenByDescending(a => a.Value.ReviewedAt)
                    .ThenByDescending(a => a.Value.AppliedAt).ThenBy(a => a.Key, StringComparer.Ordinal).FirstOrDefault();
                if (chosen.Value == null) continue;
                var application = chosen.Value;
                result.Add(new TraineeRow
                {
                    StudentKey = group.Key,
                    Name = string.IsNullOrWhiteSpace(student.Name) ? "Name unavailable" : student.Name,
                    Major = string.IsNullOrWhiteSpace(student.Major) ? "Major unavailable" : student.Major,
                    Contact = "", // Email disclosure was not approved by this requirement.
                    CompanyName = companyName,
                    OpportunityId = application.OpportunityId,
                    OpportunityTitle = string.IsNullOrWhiteSpace(application.OpportunityTitle) ? "Not available" : application.OpportunityTitle,
                    Status = application.Status,
                    ConfirmationDate = application.Status == ApplicationStatus.Confirmed ? ConfirmationDate(application.ConfirmedAt) : "Awaiting confirmation",
                    AcademicSupervisor = string.IsNullOrWhiteSpace(student.AcademicSupervisorId)
                        ? "No assignment recorded" : "Assignment recorded; details not available"
                });
            }
            return result.OrderBy(r => r.Name, StringComparer.OrdinalIgnoreCase).ToList();
        }
        private static string ConfirmationDate(long timestamp)
        {
            if (timestamp <= 0) return "Not available";
            try { return DateTimeOffset.FromUnixTimeMilliseconds(timestamp).ToString("dd MMM yyyy HH:mm 'UTC'", System.Globalization.CultureInfo.InvariantCulture); }
            catch (ArgumentOutOfRangeException) { return "Not available"; }
        }
        // Same task window and latest-version selection as Student/MyProgress. This is task
        // submission progress, not approved training hours or a claim that a closed task was passed.
        private static bool InProgressScope(Tasks task, string studentKey)
        {
            return task.WeekNumber >= 1 && task.WeekNumber <= 6 && task.StudentIds != null && task.StudentIds.Contains(studentKey);
        }
        internal static void ApplyProgress(TraineeRow row, IDictionary<string, Tasks> tasks, JToken submissions)
        {
            var assigned = tasks.Where(t => InProgressScope(t.Value, row.StudentKey)).ToDictionary(t => t.Key, t => t.Value);
            var raw = ReadObject<JObject>(submissions);
            if (raw.Values.Any(s => s == null || (string)s["StudentId"] != row.StudentKey))
                throw new UnauthorizedAccessException("Submissions outside the selected student scope.");
            var latest = new List<TaskSubmission>();
            foreach (var entry in raw)
            {
                string taskId = (string)entry.Value["TaskId"];
                if (taskId == null || !assigned.ContainsKey(taskId)) continue;
                if (entry.Value["Status"] == null || entry.Value["Version"] == null || entry.Value["Version"].Type != JTokenType.Integer
                    || entry.Value["SubmittedAt"] == null)
                    throw new TraineesUnavailableException("Submission progress fields are incomplete.");
                var submission = entry.Value.ToObject<TaskSubmission>();
                if (!Enum.IsDefined(typeof(SubmissionState), submission.Status) || submission.Version < 0 || submission.SubmittedAt == DateTime.MinValue)
                    throw new TraineesUnavailableException("Submission progress fields are invalid.");
                submission.Id = entry.Key;
                latest.Add(submission);
            }
            var final = latest.GroupBy(s => s.TaskId).Select(g => g.OrderByDescending(s => s.Version)
                .ThenByDescending(s => s.SubmittedAt).ThenBy(s => s.Id, StringComparer.Ordinal).First()).ToList();
            row.AssignedTasks = assigned.Count;
            row.SubmittedTasks = final.Count(s => s.Status == SubmissionState.Submitted || s.Status == SubmissionState.Evaluated);
            row.EvaluatedTasks = final.Count(s => s.Status == SubmissionState.Evaluated);
            row.TaskProgressPercent = assigned.Count == 0 ? 0 : (int)Math.Round(100d * row.SubmittedTasks.Value / assigned.Count, MidpointRounding.AwayFromZero);
            row.ProgressNote = assigned.Count == 0 ? "No assigned tasks in weeks 1–6."
                : "Latest Submitted or Evaluated submissions / assigned tasks, weeks 1–6 (MyProgress definition).";
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
                        string resource = request.RequestUri.AbsolutePath.Split('/').Skip(1).FirstOrDefault() ?? "";
                        if (resource.EndsWith(".json", StringComparison.Ordinal)) resource = resource.Substring(0, resource.Length - 5);
                        var known = new[] { "CompanySupervisors", "Applications", "Students", "Opportunities", "Tasks", "TaskSubmissions" };
                        string label = known.Contains(resource) ? resource : "requested resource";
                        if (response.StatusCode == HttpStatusCode.Forbidden || response.StatusCode == HttpStatusCode.Unauthorized)
                            throw new TraineesUnavailableException("Firebase denied the " + label + " read (HTTP " + (int)response.StatusCode + "). The Firebase owner must verify access for this supervisor.");
                        if (response.StatusCode == HttpStatusCode.BadRequest)
                        {
                            string body = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                            string field = resource == "Applications" || resource == "Tasks" ? "CompanyId"
                                : resource == "TaskSubmissions" ? "StudentId" : null;
                            if (field != null && body.IndexOf("Index not defined", StringComparison.OrdinalIgnoreCase) >= 0)
                                throw new TraineesUnavailableException("Firebase requires an index on " + field + " for " + label + " queries. Ask the Firebase owner to add that index; no database Rules were changed by this page.");
                        }
                        throw new TraineesUnavailableException("Firebase could not read " + label + " (HTTP " + (int)response.StatusCode + "). Please try again later or ask the Firebase owner to review the query.");
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
