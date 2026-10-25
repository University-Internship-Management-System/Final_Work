using System;
using System.Collections.Generic;
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
using StudentModel = UniversityInternshipManagmentSystem.Models.Student;

namespace UniversityInternshipManagmentSystem.Student
{
    public sealed class StudentDataException : Exception
    {
        public StudentDataException(string message) : base(message) { }
    }

    // Only the owned Dashboard/Profile pages use this adapter; team login/configuration stay authoritative.
    public class StudentPage : Page
    {
        private static readonly HttpClient Client = new HttpClient(new HttpClientHandler
        { AllowAutoRedirect = false, UseCookies = false }) { Timeout = TimeSpan.FromSeconds(10) };
        private bool requestAllowed;
        private string verifiedToken;
        protected string VerifiedStudentId { get; private set; }
        public StudentModel Workspace { get; protected set; }
        public string DataError { get; protected set; }
        protected double? StudentGpa { get; private set; }
        public string DisplayName => Show(Workspace?.Name, "Student");
        public string ModeLabel => Workspace != null ? "Authenticated student" : "Student data unavailable";
        public string CsrfToken => Session["Student.Csrf"] as string;

        protected override void OnInit(EventArgs e)
        {
            AuthHelper.RequireAuth(this, AuthHelper.RoleStudent);
            requestAllowed = AuthHelper.IsAuthenticated && AuthHelper.UserRole == AuthHelper.RoleStudent && !AuthHelper.IsFirstLogin;
            if (requestAllowed)
            {
                ViewStateUserKey = Session.SessionID;
                if (Session["Student.Csrf"] == null) Session["Student.Csrf"] = Guid.NewGuid().ToString("N");
            }
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            Response.Cache.SetNoStore();
            base.OnInit(e);
        }

        protected async Task LoadWorkspaceAsync()
        {
            Workspace = null;
            StudentGpa = null;
            VerifiedStudentId = verifiedToken = null;
            if (!requestAllowed) return;
            try
            {
                var uid = Session["userId"] as string;
                var key = Session["dbRecordId"] as string;
                var token = Session["idToken"] as string;
                if ((Session["dbTable"] as string) != "Students") throw new UnauthorizedAccessException("Your team login is not linked to a Students record.");
                ValidateRecordKey(uid);
                ValidateRecordKey(key);
                if (string.IsNullOrWhiteSpace(token) || token.Length > 16384) throw new UnauthorizedAccessException("Your Firebase session is unavailable. Sign in through the team login again.");
                await VerifyExistingTokenAsync(uid, token);
                var raw = await ReadJsonAsync("Students/" + Uri.EscapeDataString(key), token, null);
                if (!OwnsStudent(raw, key, uid)) throw new UnauthorizedAccessException("Students/" + key + " is not linked to your verified Firebase UID. The database owner must correct AuthUid; email alone cannot establish ownership.");
                if (!string.Equals((string)raw["Role"], "Student", StringComparison.OrdinalIgnoreCase)) throw new UnauthorizedAccessException("The mapped record is not a Student account.");
                Workspace = raw.ToObject<StudentModel>();
                StudentGpa = raw["GPA"] != null && (raw["GPA"].Type == JTokenType.Integer || raw["GPA"].Type == JTokenType.Float) ? (double?)raw["GPA"] : null;
                VerifiedStudentId = key;
                verifiedToken = token;
                DataError = null;
            }
            catch (UnauthorizedAccessException error) { DataError = error.Message; }
            catch (StudentDataException error) { DataError = error.Message; }
            catch (Exception) { DataError = "Student information is temporarily unavailable. Please try again later."; }
        }

        internal static void ValidateRecordKey(string key)
        {
            if (string.IsNullOrWhiteSpace(key) || key.Length > 128 || key.Any(c => char.IsControl(c) || ".#$[]/\\?%".IndexOf(c) >= 0)) throw new UnauthorizedAccessException("The student identity mapping is missing or invalid. Sign in through the team login.");
        }
        internal static bool OwnsStudent(JToken raw, string key, string uid)
        {
            if (raw == null || raw.Type != JTokenType.Object || string.IsNullOrWhiteSpace(uid) || string.IsNullOrWhiteSpace(key)) return false;
            var mappings = new[] { raw["AuthUid"], raw["authUid"] }.Where(value => value != null && value.Type != JTokenType.Null).ToList();
            return mappings.Count == 0 ? string.Equals(key, uid, StringComparison.Ordinal)
                : mappings.All(value => value.Type == JTokenType.String && string.Equals((string)value, uid, StringComparison.Ordinal));
        }
        private static Uri Database()
        {
            Uri uri;
            if (!Uri.TryCreate(AppConfig.DbUrl, UriKind.Absolute, out uri) || uri.Scheme != "https" || !uri.IsDefaultPort || uri.AbsolutePath != "/" || uri.Query.Length != 0 || uri.Fragment.Length != 0 || uri.UserInfo.Length != 0
                || !(uri.Host.EndsWith(".firebaseio.com", StringComparison.OrdinalIgnoreCase) || uri.Host.EndsWith(".firebasedatabase.app", StringComparison.OrdinalIgnoreCase))) throw new StudentDataException("The team's Firebase HTTPS configuration is unavailable.");
            return uri;
        }
        private static async Task VerifyExistingTokenAsync(string uid, string token)
        {
            if (string.IsNullOrWhiteSpace(AppConfig.ApiKey)) throw new StudentDataException("The team's Firebase authentication configuration is unavailable.");
            using (var request = new HttpRequestMessage(HttpMethod.Post, "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=" + Uri.EscapeDataString(AppConfig.ApiKey)))
            {
                request.Content = new StringContent(JsonConvert.SerializeObject(new { idToken = token }), Encoding.UTF8, "application/json");
                var account = await SendJsonAsync(request, true);
                var users = account["users"] as JArray;
                if (users == null || users.Count != 1 || (string)users[0]["localId"] != uid || (bool?)users[0]["disabled"] == true) throw new UnauthorizedAccessException("Your Firebase identity does not match the team session. Sign in again.");
                // Decode only AFTER Firebase accepts the existing token; this is not a sign-in flow.
                try
                {
                    var parts = token.Split('.');
                    if (parts.Length != 3) throw new FormatException();
                    var part = parts[1].Replace('-', '+').Replace('_', '/');
                    var claims = JObject.Parse(Encoding.UTF8.GetString(Convert.FromBase64String(part.PadRight((part.Length + 3) / 4 * 4, '='))), new JsonLoadSettings { DuplicatePropertyNameHandling = DuplicatePropertyNameHandling.Error });
                    var host = Database().Host.Split('.')[0];
                    const string suffix = "-default-rtdb";
                    if (Database().Host.EndsWith(".firebasedatabase.app", StringComparison.OrdinalIgnoreCase) && !host.EndsWith(suffix, StringComparison.Ordinal)) throw new FormatException();
                    var project = host.EndsWith(suffix, StringComparison.Ordinal) ? host.Substring(0, host.Length - suffix.Length) : host;
                    var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
                    // A computer clock that is a few seconds behind Google's would reject a token that was JUST issued
                    // (the page failed after login and worked after a refresh), so "issued in the future" gets 5 minutes of room.
                    const long skew = 300;
                    long validSince;
                    if ((string)claims["sub"] != uid || (string)claims["aud"] != project || (string)claims["iss"] != "https://securetoken.google.com/" + project
                        || claims["exp"]?.Type != JTokenType.Integer || claims["iat"]?.Type != JTokenType.Integer || claims["auth_time"]?.Type != JTokenType.Integer
                        || (long)claims["exp"] <= now || (long)claims["iat"] > now + skew || (long)claims["iat"] < 0 || (long)claims["exp"] <= (long)claims["iat"]
                        || (long)claims["auth_time"] > now + skew || (long)claims["auth_time"] < 0
                        || (long.TryParse((string)users[0]["validSince"], out validSince) && (long)claims["auth_time"] < validSince)) throw new FormatException();
                }
                catch (Exception error) when (error is FormatException || error is JsonException || error is InvalidCastException || error is ArgumentException)
                { throw new UnauthorizedAccessException("Your Firebase token project or lifetime could not be verified. Sign in again."); }
            }
        }
        protected async Task<JToken> ReadOwnApplicationsAsync()
        {
            return await ReadOwnRowsAsync("Applications");
        }
        protected async Task<JToken> ReadOwnSubmissionsAsync()
        {
            return await ReadOwnRowsAsync("TaskSubmissions");
        }
        private async Task<JToken> ReadOwnRowsAsync(string table)
        {
            RequireStudentWorkspace();
            var query = "&orderBy=" + Uri.EscapeDataString(JsonConvert.SerializeObject("StudentId")) + "&equalTo=" + Uri.EscapeDataString(JsonConvert.SerializeObject(VerifiedStudentId));
            var rows = await ReadJsonAsync(table, verifiedToken, query);
            if (rows.Type != JTokenType.Null && (rows.Type != JTokenType.Object || rows.Children<JProperty>().Any(row => row.Value.Type != JTokenType.Object || (string)row.Value["StudentId"] != VerifiedStudentId))) throw new UnauthorizedAccessException("Records could not be restricted to your student account.");
            return rows;
        }
        protected async Task<Dictionary<string, Models.Tasks>> ReadOwnTasksAsync()
        {
            RequireStudentWorkspace();
            if (string.IsNullOrWhiteSpace(Workspace.CompanyId)) return new Dictionary<string, Models.Tasks>();
            ValidateRecordKey(Workspace.CompanyId);
            var query = "&orderBy=" + Uri.EscapeDataString(JsonConvert.SerializeObject("CompanyId"))
                + "&equalTo=" + Uri.EscapeDataString(JsonConvert.SerializeObject(Workspace.CompanyId));
            var rows = await ReadJsonAsync("Tasks", verifiedToken, query);
            return SelectAssignedTasks(rows, VerifiedStudentId, Workspace.CompanyId);
        }
        // Tasks.StudentIds and Tasks.CompanyId are the existing model's assignment fields.
        internal static Dictionary<string, Models.Tasks> SelectAssignedTasks(JToken rows, string studentId, string companyId)
        {
            var selected = new Dictionary<string, Models.Tasks>();
            if (rows.Type == JTokenType.Null) return selected;
            if (rows.Type != JTokenType.Object) throw new StudentDataException("Firebase returned invalid tasks.");
            foreach (var entry in rows.Children<JProperty>())
            {
                if (entry.Value.Type != JTokenType.Object || (string)entry.Value["CompanyId"] != companyId)
                    throw new UnauthorizedAccessException("Tasks could not be restricted to your current placement.");
                var task = entry.Value.ToObject<Models.Tasks>();
                if (task.StudentIds == null || !task.StudentIds.Contains(studentId)) continue;
                task.TaskId = entry.Name;
                selected[entry.Name] = task;
            }
            return selected;
        }
        protected async Task<JToken> ReadOwnRecordAsync(string table)
        {
            RequireStudentWorkspace();
            return await ReadJsonAsync(table + "/" + Uri.EscapeDataString(VerifiedStudentId), verifiedToken, null);
        }
        protected async Task<string> ReadPlacementCompanyNameAsync()
        {
            RequireStudentWorkspace();
            if (string.IsNullOrWhiteSpace(Workspace.CompanyId)) return null;
            ValidateRecordKey(Workspace.CompanyId);
            // Read only the public display name, never another supervisor's complete profile.
            var name = await ReadJsonAsync("CompanySupervisors/" + Uri.EscapeDataString(Workspace.CompanyId) + "/CompanyName", verifiedToken, null);
            return name.Type == JTokenType.String ? (string)name : null;
        }
        private void RequireStudentWorkspace()
        {
            if (Workspace == null || verifiedToken == null || VerifiedStudentId == null) throw new UnauthorizedAccessException("Student authorization is required.");
        }
        protected async Task SaveProfileFieldsAsync(IDictionary<string, object> patch)
        {
            if (!requestAllowed) throw new UnauthorizedAccessException("An authenticated Student session is required to save your profile.");
            StudentProfilePage.ProfileValidation.ValidatePatch(patch, StudentProfilePage.ProfileValidation.EditableFields);
            await LoadWorkspaceAsync();
            if (Workspace == null) throw new UnauthorizedAccessException(DataError ?? "Student authorization is required.");
            var address = new Uri(Database(), "Students/" + Uri.EscapeDataString(VerifiedStudentId) + ".json?auth=" + Uri.EscapeDataString(verifiedToken));
            using (var request = new HttpRequestMessage(new HttpMethod("PATCH"), address))
            {
                request.Content = new StringContent(JsonConvert.SerializeObject(patch), Encoding.UTF8, "application/json");
                await SendJsonAsync(request, false);
            }
            await LoadWorkspaceAsync();
            if (Workspace == null || !StudentProfilePage.ProfileValidation.MatchesPatch(Workspace, patch)) throw new StudentDataException("The save could not be confirmed by reading Firebase again. Reload before retrying.");
        }
        private static async Task<JToken> ReadJsonAsync(string path, string token, string query)
        {
            using (var request = new HttpRequestMessage(HttpMethod.Get, new Uri(Database(), path + ".json?auth=" + Uri.EscapeDataString(token) + (query ?? "")))) return await SendJsonAsync(request, false);
        }
        private static async Task<JToken> SendJsonAsync(HttpRequestMessage request, bool authentication)
        {
            try
            {
                using (var response = await Client.SendAsync(request))
                {
                    if (!response.IsSuccessStatusCode)
                    {
                        if (authentication) throw new UnauthorizedAccessException("Firebase could not verify your current login. Sign in again.");
                        if (response.StatusCode == HttpStatusCode.Unauthorized || response.StatusCode == HttpStatusCode.Forbidden) throw new StudentDataException("Firebase denied this operation. The account mapping and database permissions need team review.");
                        throw new StudentDataException("The student data service is temporarily unavailable.");
                    }
                    return JToken.Parse(await response.Content.ReadAsStringAsync());
                }
            }
            catch (HttpRequestException) { throw new StudentDataException("Firebase could not be reached. Please try again later."); }
            catch (TaskCanceledException) { throw new StudentDataException("The Firebase request timed out. Please try again later."); }
            catch (JsonException) { throw new StudentDataException("Firebase returned an invalid student data response."); }
        }
        protected override void OnPreRender(EventArgs e)
        {
            if (Header != null) Header.Title = (this is StudentProfilePage.Profile ? "My Profile" : "Student Dashboard") + " | The University of Jordan";
            base.OnPreRender(e);
        }
        public string Show(string value, string empty = "Not provided") => string.IsNullOrWhiteSpace(value) ? empty : value;
    }
}
