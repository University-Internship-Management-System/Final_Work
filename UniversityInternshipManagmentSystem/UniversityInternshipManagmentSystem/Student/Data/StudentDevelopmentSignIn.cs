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
    // Local development adapter only. It never assigns a team principal or role/session keys.
    public static class StudentDevelopmentSignIn
    {
        public const string ProjectId = "uims-student-2026";
        private const string SessionKey = "Student.Development.VerifiedAccess";
        private const string BindingKey = "Student.Development.Binding";
        private const string BindingCookie = "UimsStudentDevelopment";
        private static readonly HttpClient AuthClient = new HttpClient(new HttpClientHandler
        { AllowAutoRedirect = false, UseCookies = false }) { Timeout = TimeSpan.FromSeconds(15) };
        private static readonly System.Threading.SemaphoreSlim CertificateLock = new System.Threading.SemaphoreSlim(1, 1);
        private static JObject certificates;
        private static DateTimeOffset certificatesExpire;

        public static bool IsAvailable(HttpContextBase context)
        {
            return context != null && context.IsDebuggingEnabled && context.Request.IsLocal
                && context.Request.IsSecureConnection && context.Request.Url != null
                && context.Request.Url.IsLoopback;
        }

        public static void SignOut(HttpContextBase context)
        {
            context.Session.Remove(SessionKey);
            context.Session.Remove(BindingKey);
            context.Response.Cookies.Add(new HttpCookie(BindingCookie, "")
            { HttpOnly = true, Secure = true, SameSite = SameSiteMode.Strict,
                Path = VirtualPathUtility.ToAbsolute("~/Student"), Expires = DateTime.UtcNow.AddDays(-1) });
            context.Session["Student.Csrf"] = Guid.NewGuid().ToString("N");
        }

        public static async Task<StudentWorkspace> OpenAsync(HttpContextBase context)
        {
            if (!IsAvailable(context)) return null;
            var access = context.Session[SessionKey] as StudentAccess;
            if (access == null) return null;
            var binding = context.Session[BindingKey] as string;
            var cookie = context.Request.Cookies[BindingCookie]?.Value;
            if (string.IsNullOrEmpty(binding) || !string.Equals(binding, cookie, StringComparison.Ordinal))
            {
                context.Session.Remove(SessionKey);
                throw new UnauthorizedAccessException("Your Student test browser session is unavailable. Sign in again.");
            }
            try
            {
                // Recheck signature/lifetime/project on every page load, using cached Google keys.
                var verified = await VerifyAsync(access.FirebaseIdToken);
                if (access.StudentId != "student_001" || verified.FirebaseUid != access.FirebaseUid)
                    throw new UnauthorizedAccessException("Your Student test session is invalid. Sign in again.");
                return await LoadAsync(verified);
            }
            catch
            {
                context.Session.Remove(SessionKey);
                throw;
            }
        }

        public static async Task<StudentWorkspace> SignInAsync(HttpContextBase context, string apiKey, string email, string password)
        {
            if (!IsAvailable(context))
                throw new UnauthorizedAccessException("Student test sign-in requires localhost, HTTPS, and a Debug build.");
            if (StudentModule.SessionProvider != null)
                throw new UnauthorizedAccessException("Team authentication is configured; use the team's sign-in flow.");
            context.Session.Remove(SessionKey);
            if (string.IsNullOrWhiteSpace(apiKey) || apiKey.Length > 256
                || !System.Text.RegularExpressions.Regex.IsMatch(apiKey, "^[A-Za-z0-9_-]+$")
                || !string.Equals(email?.Trim(), "student1@example.com", StringComparison.OrdinalIgnoreCase)
                || string.IsNullOrEmpty(password) || password.Length > 4096)
                throw new ArgumentException("Enter the uims-student-2026 Web API Key and the test student's email and password.");
            // Only Firebase receives the password. Never save it or the refresh token.
            var body = JsonConvert.SerializeObject(new { email = email.Trim(), password, returnSecureToken = true });
            try
            {
                using (var request = new HttpRequestMessage(HttpMethod.Post,
                    "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + Uri.EscapeDataString(apiKey)))
                {
                    request.Content = new StringContent(body, Encoding.UTF8, "application/json");
                    using (var response = await AuthClient.SendAsync(request).ConfigureAwait(false))
                    {
                        if (!response.IsSuccessStatusCode)
                            throw new UnauthorizedAccessException("Firebase sign-in failed. Check the project Web API Key, test account credentials, and Email/Password provider. Too many attempts may temporarily block sign-in.");
                        var result = JObject.Parse(await response.Content.ReadAsStringAsync().ConfigureAwait(false));
                        var access = await VerifyAsync((string)result["idToken"]).ConfigureAwait(false);
                        if (!string.Equals(access.FirebaseUid, (string)result["localId"], StringComparison.Ordinal))
                            throw new UnauthorizedAccessException("Firebase sign-in identity could not be verified.");
                        // Rules authorize this read; AuthUid is checked independently in the repository.
                        var workspace = await LoadAsync(access).ConfigureAwait(false);
                        var nonce = new byte[32];
                        using (var random = System.Security.Cryptography.RandomNumberGenerator.Create()) { random.GetBytes(nonce); }
                        var binding = Convert.ToBase64String(nonce);
                        context.Session[SessionKey] = access;
                        context.Session[BindingKey] = binding;
                        context.Response.Cookies.Add(new HttpCookie(BindingCookie, binding)
                        { HttpOnly = true, Secure = true, SameSite = SameSiteMode.Strict, Path = VirtualPathUtility.ToAbsolute("~/Student") });
                        context.Session["Student.Csrf"] = Guid.NewGuid().ToString("N");
                        return workspace;
                    }
                }
            }
            catch (HttpRequestException) { throw new StudentDataException("Unable to reach Firebase Authentication. Try again later."); }
            catch (TaskCanceledException) { throw new StudentDataException("Firebase sign-in timed out. Try again later."); }
            catch (JsonException) { throw new StudentDataException("Firebase returned an unreadable sign-in response."); }
        }

        private static async Task<StudentWorkspace> LoadAsync(StudentAccess access)
        {
            var repository = new FirebaseStudentRepository(access);
            return new StudentWorkspace { Access = access, Repository = repository, Profile = await repository.GetProfileAsync().ConfigureAwait(false) };
        }

        private static byte[] Decode(string value)
        {
            if (string.IsNullOrEmpty(value) || !System.Text.RegularExpressions.Regex.IsMatch(value, "^[A-Za-z0-9_-]+$"))
                throw new UnauthorizedAccessException("Invalid Firebase ID token.");
            var text = value.Replace('-', '+').Replace('_', '/');
            return Convert.FromBase64String(text.PadRight((text.Length + 3) / 4 * 4, '='));
        }

        private static async Task<StudentAccess> VerifyAsync(string token)
        {
            try
            {
                if (string.IsNullOrEmpty(token) || token.Length > 16384)
                    throw new UnauthorizedAccessException("Invalid Firebase ID token.");
                var parts = token.Split('.');
                if (parts.Length != 3) throw new UnauthorizedAccessException("Invalid Firebase ID token.");
                var settings = new JsonLoadSettings { DuplicatePropertyNameHandling = DuplicatePropertyNameHandling.Error };
                var header = JObject.Parse(Encoding.UTF8.GetString(Decode(parts[0])), settings);
                var claims = JObject.Parse(Encoding.UTF8.GetString(Decode(parts[1])), settings);
                if ((string)header["alg"] != "RS256" || header["kid"]?.Type != JTokenType.String)
                    throw new UnauthorizedAccessException("Invalid Firebase token signing algorithm.");
                var kid = (string)header["kid"];
                var keys = await GetCertificatesAsync().ConfigureAwait(false);
                var pem = keys[kid];
                if (pem?.Type != JTokenType.String) throw new UnauthorizedAccessException("Firebase token signing key is unavailable. Sign in again.");
                var der = Convert.FromBase64String(((string)pem).Replace("-----BEGIN CERTIFICATE-----", "").Replace("-----END CERTIFICATE-----", ""));
                using (var certificate = new System.Security.Cryptography.X509Certificates.X509Certificate2(der))
                using (var rsa = System.Security.Cryptography.X509Certificates.RSACertificateExtensions.GetRSAPublicKey(certificate))
                {
                    var now = DateTime.UtcNow;
                    if (certificate.NotBefore.ToUniversalTime() > now || certificate.NotAfter.ToUniversalTime() <= now || rsa == null
                        || !rsa.VerifyData(Encoding.ASCII.GetBytes(parts[0] + "." + parts[1]), Decode(parts[2]),
                            System.Security.Cryptography.HashAlgorithmName.SHA256, System.Security.Cryptography.RSASignaturePadding.Pkcs1))
                        throw new UnauthorizedAccessException("Firebase token signature verification failed.");
                }
                var seconds = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
                if (claims["exp"]?.Type != JTokenType.Integer || claims["iat"]?.Type != JTokenType.Integer
                    || claims["auth_time"]?.Type != JTokenType.Integer
                    || (long)claims["exp"] <= seconds || (long)claims["iat"] > seconds || (long)claims["iat"] < 0
                    || (long)claims["auth_time"] > seconds || (long)claims["auth_time"] < 0
                    || (long)claims["exp"] <= (long)claims["iat"]
                    || claims["aud"]?.Type != JTokenType.String || (string)claims["aud"] != ProjectId
                    || claims["iss"]?.Type != JTokenType.String || (string)claims["iss"] != "https://securetoken.google.com/" + ProjectId
                    || claims["sub"]?.Type != JTokenType.String || string.IsNullOrWhiteSpace((string)claims["sub"])
                    || ((string)claims["sub"]).Length > 128
                    || !string.Equals((string)claims["email"], "student1@example.com", StringComparison.OrdinalIgnoreCase)
                    || (string)claims["firebase"]?["sign_in_provider"] != "password")
                    throw new UnauthorizedAccessException("Firebase token project, identity, or lifetime is invalid. Sign in with the uims-student-2026 test account.");
                return new StudentAccess { StudentId = "student_001", FirebaseUid = (string)claims["sub"], FirebaseIdToken = token,
                    ExpiresUtc = DateTimeOffset.FromUnixTimeSeconds((long)claims["exp"]), EditableFields = ProfileValidation.EditableFields };
            }
            catch (FormatException) { throw new UnauthorizedAccessException("Invalid Firebase ID token encoding."); }
            catch (JsonException) { throw new UnauthorizedAccessException("Invalid Firebase ID token structure."); }
            catch (System.Security.Cryptography.CryptographicException) { throw new UnauthorizedAccessException("Firebase token signature verification failed."); }
            catch (ArgumentException) { throw new UnauthorizedAccessException("Invalid Firebase ID token claims."); }
        }

        private static async Task<JObject> GetCertificatesAsync()
        {
            await CertificateLock.WaitAsync().ConfigureAwait(false);
            try
            {
                if (certificates != null && certificatesExpire > DateTimeOffset.UtcNow) return certificates;
                using (var response = await AuthClient.GetAsync("https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com").ConfigureAwait(false))
                {
                    if (!response.IsSuccessStatusCode) throw new StudentDataException("Firebase signing keys are unavailable. Try again later.");
                    var fresh = JObject.Parse(await response.Content.ReadAsStringAsync().ConfigureAwait(false));
                    var maxAge = response.Headers.CacheControl?.MaxAge ?? TimeSpan.Zero;
                    var age = response.Headers.Age ?? TimeSpan.Zero;
                    certificates = fresh;
                    certificatesExpire = DateTimeOffset.UtcNow.AddSeconds(Math.Max(0, Math.Min(21600, (maxAge - age).TotalSeconds)));
                    return fresh;
                }
            }
            finally { CertificateLock.Release(); }
        }
    }

}
