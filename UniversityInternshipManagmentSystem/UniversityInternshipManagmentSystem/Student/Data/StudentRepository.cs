using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace UniversityInternshipManagmentSystem.Student.Data
{
    public interface IStudentSessionProvider
    {
        Task<StudentAccess> GetVerifiedStudentAsync(HttpContextBase context);
    }

    public interface IStudentRepository
    {
        Task<StudentProfile> GetProfileAsync();
        Task UpdateProfileAsync(IDictionary<string, object> changes);
    }

    public interface IStudentActivityProvider
    {
        Task<StudentOverview> GetStudentOverviewAsync(StudentAccess access);
    }

    public sealed class StudentDataException : Exception
    {
        public StudentDataException(string message) : base(message) { }
    }

    public sealed class LocalJsonStudentRepository : IStudentRepository
    {
        private readonly string path;
        public LocalJsonStudentRepository(string path) { this.path = path; }

        public Task<StudentProfile> GetProfileAsync()
        {
            // Fixed development identity, deliberately independent of all request parameters.
            var root = JObject.Parse(File.ReadAllText(path));
            var token = root["Students"]?["student_001"];
            if (token == null) throw new StudentDataException("The development student record is unavailable.");
            var record = token.ToObject<StudentRecord>();
            return Task.FromResult(new StudentProfile
            {
                Student = record,
                CompanyName = string.IsNullOrEmpty(record.CompanyId) ? null
                    : (string)root["CompanySupervisors"]?[record.CompanyId]?["CompanyName"],
                AcademicSupervisorName = string.IsNullOrEmpty(record.AcademicSupervisorId) ? null
                    : (string)root["AcademicSupervisors"]?[record.AcademicSupervisorId]?["Name"]
            });
        }

        public Task UpdateProfileAsync(IDictionary<string, object> changes)
        {
            throw new UnauthorizedAccessException("Local development data is read-only.");
        }
    }

    public sealed class FirebaseStudentRepository : IStudentRepository
    {
        // Student-specific endpoint, independent of the team's global Firebase configuration.
        // The trusted session provider must verify a user ID token for this same project.
        public const string DatabaseUrl = "https://uims-student-2026-default-rtdb.firebaseio.com/";
        // Server operator opt-in only, after the Firebase owner approves/deploys Rules.
        // No query string, form field, session value, or client setting can enable this.
        public static bool ProfileWritesEnabled => string.Equals(
            Environment.GetEnvironmentVariable("UIMS_STUDENT_PROFILE_WRITES_APPROVED"), "true", StringComparison.OrdinalIgnoreCase);
        private readonly HttpClient client;
        private static readonly HttpClient Client = new HttpClient(new HttpClientHandler
        {
            AllowAutoRedirect = false,
            UseCookies = false
        }) { Timeout = TimeSpan.FromSeconds(15) };
        private readonly StudentAccess access;

        public FirebaseStudentRepository(StudentAccess access) : this(access, Client) { }

        // Internal transport seam for offline repository tests, never chosen by a request.
        internal FirebaseStudentRepository(StudentAccess access, HttpClient client)
        {
            if (access == null) throw new ArgumentNullException(nameof(access));
            this.client = client ?? throw new ArgumentNullException(nameof(client));
            // Bind this repository to a snapshot of the verified identity and permissions.
            this.access = new StudentAccess
            {
                StudentId = access.StudentId,
                FirebaseIdToken = access.FirebaseIdToken,
                FirebaseUid = access.FirebaseUid,
                ExpiresUtc = access.ExpiresUtc,
                EditableFields = access.EditableFields == null ? new HashSet<string>(StringComparer.Ordinal)
                    : new HashSet<string>(access.EditableFields, StringComparer.Ordinal)
            };
            ValidateAccess();
        }

        private void ValidateAccess()
        {
            ValidateKey(access.StudentId);
            if (string.IsNullOrWhiteSpace(access.FirebaseIdToken) || access.ExpiresUtc <= DateTimeOffset.UtcNow)
                throw new UnauthorizedAccessException("Your student session has expired. Please sign in again.");
        }

        private static void ValidateKey(string key)
        {
            if (string.IsNullOrWhiteSpace(key) || key.Length > 128 || key.Any(c =>
                !(char.IsLetterOrDigit(c) || c == '_' || c == '-')))
                throw new StudentDataException("The student record mapping is invalid.");
        }

        private async Task<JToken> SendAsync(string path, HttpMethod method, string json = null)
        {
            ValidateAccess();
            // Firebase Auth ID token stays server-side. No admin secret or rules bypass.
            var url = DatabaseUrl + path + ".json?auth=" + Uri.EscapeDataString(access.FirebaseIdToken);
            try
            {
                using (var request = new HttpRequestMessage(method, url))
                {
                    if (json != null) request.Content = new StringContent(json, Encoding.UTF8, "application/json");
                    using (var response = await client.SendAsync(request).ConfigureAwait(false))
                    {
                        if (response.StatusCode == HttpStatusCode.Unauthorized || response.StatusCode == HttpStatusCode.Forbidden)
                            throw new StudentDataException("Firebase denied access. Please check your student session and authorized permissions.");
                        if (!response.IsSuccessStatusCode)
                            throw new StudentDataException("The student data service is temporarily unavailable.");
                        return JToken.Parse(await response.Content.ReadAsStringAsync().ConfigureAwait(false));
                    }
                }
            }
            catch (HttpRequestException) { throw new StudentDataException("Unable to reach the student data service. Please try again later."); }
            catch (TaskCanceledException) { throw new StudentDataException("The student data request timed out. Please try again."); }
            catch (JsonException) { throw new StudentDataException("The student data service returned an unreadable response."); }
        }

        public async Task<StudentProfile> GetProfileAsync()
        {
            var token = await SendAsync("Students/" + access.StudentId, HttpMethod.Get).ConfigureAwait(false);
            if (token.Type == JTokenType.Null) throw new StudentDataException("No student profile is linked to your account.");
            if (token.Type != JTokenType.Object)
                throw new StudentDataException("The student data service returned an invalid profile.");
            StudentRecord student;
            try { student = token.ToObject<StudentRecord>(); }
            catch (JsonException) { throw new StudentDataException("The student data service returned an invalid profile."); }
            if (student.Role != "Student") throw new UnauthorizedAccessException("This account is not a student account.");
            if (!string.IsNullOrEmpty(access.FirebaseUid)
                && (token["AuthUid"]?.Type != JTokenType.String
                    || !string.Equals((string)token["AuthUid"], access.FirebaseUid, StringComparison.Ordinal)))
                throw new UnauthorizedAccessException("This student record is not linked to the verified Firebase user.");
            var profile = new StudentProfile { Student = student };
            // The isolated development flow is permitted to read only its Student record.
            if (!string.IsNullOrEmpty(access.FirebaseUid)) return profile;
            // Fetch only the assigned relationship's display leaf, never an entire supervisor collection.
            if (!string.IsNullOrEmpty(student.CompanyId))
            {
                ValidateKey(student.CompanyId);
                profile.CompanyName = await ReadDisplayNameAsync("CompanySupervisors/" + student.CompanyId + "/CompanyName").ConfigureAwait(false);
            }
            if (!string.IsNullOrEmpty(student.AcademicSupervisorId))
            {
                ValidateKey(student.AcademicSupervisorId);
                profile.AcademicSupervisorName = await ReadDisplayNameAsync("AcademicSupervisors/" + student.AcademicSupervisorId + "/Name").ConfigureAwait(false);
            }
            return profile;
        }

        private async Task<string> ReadDisplayNameAsync(string path)
        {
            // Relationship lookup permissions may be narrower than student-profile permissions.
            try
            {
                var value = await SendAsync(path, HttpMethod.Get).ConfigureAwait(false);
                return value.Type == JTokenType.String ? (string)value : null;
            }
            catch (StudentDataException) { return null; }
        }

        public async Task UpdateProfileAsync(IDictionary<string, object> changes)
        {
            ValidateAccess();
            if (string.IsNullOrWhiteSpace(access.FirebaseUid))
                throw new UnauthorizedAccessException("A verified Firebase identity is required before saving.");
            // Validate and serialize the same private values, including a copy of the skills list.
            if (changes == null) throw new ArgumentException("There are no authorized changes to save.");
            var patch = changes.ToDictionary(pair => pair.Key,
                pair => pair.Value is IList<string> ? (object)new List<string>((IList<string>)pair.Value) : pair.Value,
                StringComparer.Ordinal);
            ProfileValidation.ValidatePatch(patch, access.EditableFields);
            EnsureWritesEnabled();
            // Re-read the bound record to check Role and AuthUid immediately before PATCH.
            await GetProfileAsync().ConfigureAwait(false);
            // PATCH only explicitly authorized personal fields. Never PUT/replace a student record.
            await SendAsync("Students/" + access.StudentId, new HttpMethod("PATCH"), JsonConvert.SerializeObject(patch)).ConfigureAwait(false);
            // Do not report persistence merely because PATCH returned 200.
            var confirmed = await GetProfileAsync().ConfigureAwait(false);
            if (!ProfileValidation.MatchesPatch(confirmed.Student, patch))
                throw new StudentDataException("Firebase accepted the update, but the saved values could not be confirmed. Your entries are preserved; reload the profile to check before retrying.");
        }

        private static void EnsureWritesEnabled()
        {
            if (!ProfileWritesEnabled)
                throw new UnauthorizedAccessException("Saving is not authorized yet. Firebase currently permits reads only; the database owner must approve profile-write permissions first. Your entries have been preserved.");
        }
    }

    public static class StudentModule
    {
        // Register trusted implementations once during application startup. No request toggles or config changes.
        public static IStudentSessionProvider SessionProvider { get; set; }
        public static IStudentActivityProvider ActivityProvider { get; set; }

        public static async Task<StudentWorkspace> OpenAsync(HttpContextBase context)
        {
            var provider = SessionProvider;
            if (provider == null)
            {
                var development = await StudentDevelopmentSignIn.OpenAsync(context);
                if (development != null) return development;
                if (StudentDevelopmentSignIn.IsAvailable(context))
                    throw new UnauthorizedAccessException("Sign in using the local Student Profile form to read your Firebase record.");
                // Live pages must never silently select a development identity.
                throw new UnauthorizedAccessException("Student sign-in integration is not configured. No Firebase data was loaded. Ask the authentication team to connect your verified student session.");
            }
            if (context.User?.Identity == null || !context.User.Identity.IsAuthenticated || !context.User.IsInRole("Student"))
                throw new UnauthorizedAccessException("Please sign in with an authorized student account.");
            var access = await provider.GetVerifiedStudentAsync(context);
            if (access == null) throw new UnauthorizedAccessException("Your student session is unavailable. Please sign in again.");
            var live = new FirebaseStudentRepository(access);
            return new StudentWorkspace { Repository = live, Access = access, Profile = await live.GetProfileAsync() };
        }

        public static async Task<StudentOverview> GetOverviewAsync(StudentWorkspace workspace)
        {
            if (workspace.IsDemo || ActivityProvider == null) return new StudentOverview();
            return StudentOverview.ForStudent(await ActivityProvider.GetStudentOverviewAsync(workspace.Access), DateTimeOffset.UtcNow);
        }
    }
}
