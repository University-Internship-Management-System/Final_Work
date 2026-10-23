using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using System.Web.Hosting;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace UniversityInternshipManagmentSystem.Config
{
    // Talks to Firebase as the project (admin), using the service account key file.
    // Today it only creates the password reset link, so we can send our own reset email.
    // The key file is a secret: App_Data/service-account.json (not on GitHub, and IIS never serves App_Data).
    public static class FirebaseAdmin
    {
        static readonly HttpClient Http = new HttpClient();
        static string cachedToken;
        static DateTime cachedUntil = DateTime.MinValue;

        static string KeyFile
        {
            get { return HostingEnvironment.MapPath("~/App_Data/service-account.json"); }
        }

        public static bool IsConfigured
        {
            get { return File.Exists(KeyFile); }
        }

        // Returns the password reset link of the account, or "" when no account has this email.
        // Throws when Firebase can not be reached or refuses the request.
        public static async Task<string> CreateResetLink(string email)
        {
            var key = JObject.Parse(File.ReadAllText(KeyFile));
            string token = await GetAccessToken(key);

            var request = new HttpRequestMessage(HttpMethod.Post,
                "https://identitytoolkit.googleapis.com/v1/projects/" + (string)key["project_id"] + "/accounts:sendOobCode");
            request.Headers.Add("Authorization", "Bearer " + token);
            request.Content = new StringContent(
                JsonConvert.SerializeObject(new { requestType = "PASSWORD_RESET", email = email, returnOobLink = true }),
                Encoding.UTF8, "application/json");

            using (var response = await Http.SendAsync(request))
            {
                string json = await response.Content.ReadAsStringAsync();
                if (response.IsSuccessStatusCode) return (string)JObject.Parse(json)["oobLink"];
                if (json.Contains("EMAIL_NOT_FOUND")) return "";
                throw new HttpRequestException("Firebase refused the reset link request.");
            }
        }

        // Google gives an access token to whoever proves they own the service account:
        // we sign a small JWT with its private key and exchange it. A token lasts one hour.
        static async Task<string> GetAccessToken(JObject key)
        {
            if (cachedToken != null && DateTime.UtcNow < cachedUntil) return cachedToken;

            string tokenUrl = (string)key["token_uri"];
            long now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            string header = Base64Url(Encoding.UTF8.GetBytes("{\"alg\":\"RS256\",\"typ\":\"JWT\"}"));
            string claims = Base64Url(Encoding.UTF8.GetBytes(JsonConvert.SerializeObject(new
            {
                iss = (string)key["client_email"],
                scope = "https://www.googleapis.com/auth/identitytoolkit",
                aud = tokenUrl,
                iat = now,
                exp = now + 3600
            })));
            string jwt = header + "." + claims + "." + Base64Url(Sign(header + "." + claims, (string)key["private_key"]));

            var form = new FormUrlEncodedContent(new Dictionary<string, string>
            {
                { "grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer" },
                { "assertion", jwt }
            });
            using (var response = await Http.PostAsync(tokenUrl, form))
            {
                string json = await response.Content.ReadAsStringAsync();
                if (!response.IsSuccessStatusCode) throw new HttpRequestException("Google refused the service account.");
                var result = JObject.Parse(json);
                cachedToken = (string)result["access_token"];
                cachedUntil = DateTime.UtcNow.AddSeconds((int)result["expires_in"] - 300);
                return cachedToken;
            }
        }

        // The private key in the key file is a PEM text; turn it into bytes and sign with RSA + SHA256.
        static byte[] Sign(string text, string pem)
        {
            string base64 = pem.Replace("-----BEGIN PRIVATE KEY-----", "").Replace("-----END PRIVATE KEY-----", "")
                .Replace("\r", "").Replace("\n", "").Trim();
            using (var rsa = new RSACng(CngKey.Import(Convert.FromBase64String(base64), CngKeyBlobFormat.Pkcs8PrivateBlob)))
                return rsa.SignData(Encoding.UTF8.GetBytes(text), HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        }

        static string Base64Url(byte[] bytes)
        {
            return Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');
        }
    }
}
