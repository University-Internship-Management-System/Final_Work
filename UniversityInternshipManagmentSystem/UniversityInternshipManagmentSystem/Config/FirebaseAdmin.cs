using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace UniversityInternshipManagmentSystem.Config
{
    // Talks to Firebase as the project (admin), using the Firebase admin key file (see Config/TeamKeys.cs).
    // Used for things that happen without a signed-in person: the deadline alert emails read the database with it.
    // It can also create a password reset link (not used now: Firebase sends the reset email).
    public static class FirebaseAdmin
    {
        const string IdentityScope = "https://www.googleapis.com/auth/identitytoolkit";
        const string DatabaseScope = "https://www.googleapis.com/auth/firebase.database https://www.googleapis.com/auth/userinfo.email";

        static readonly HttpClient Http = new HttpClient();
        static readonly Dictionary<string, string> cachedTokens = new Dictionary<string, string>();
        static readonly Dictionary<string, DateTime> cachedUntil = new Dictionary<string, DateTime>();

        static string KeyFile
        {
            get { return TeamKeys.FindFile(TeamKeys.FirebaseAdminVariable, TeamKeys.FirebaseAdminFile); }
        }

        public static bool IsConfigured
        {
            get { return KeyFile != null; }
        }

        // A token that lets the server read and write the Realtime Database as the project. Valid for about one hour.
        // Use it in the address as ?access_token=...
        public static async Task<string> DatabaseToken()
        {
            return await GetAccessToken(JObject.Parse(File.ReadAllText(KeyFile)), DatabaseScope);
        }

        // Returns the password reset link of the account, or "" when no account has this email.
        // Throws when Firebase can not be reached or refuses the request.
        public static async Task<string> CreateResetLink(string email)
        {
            var key = JObject.Parse(File.ReadAllText(KeyFile));
            string token = await GetAccessToken(key, IdentityScope);

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
        static async Task<string> GetAccessToken(JObject key, string scope)
        {
            lock (cachedTokens)
            {
                if (cachedTokens.ContainsKey(scope) && DateTime.UtcNow < cachedUntil[scope]) return cachedTokens[scope];
            }

            string tokenUrl = (string)key["token_uri"];
            long now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            string header = Base64Url(Encoding.UTF8.GetBytes("{\"alg\":\"RS256\",\"typ\":\"JWT\"}"));
            string claims = Base64Url(Encoding.UTF8.GetBytes(JsonConvert.SerializeObject(new
            {
                iss = (string)key["client_email"],
                scope = scope,
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
                string token = (string)result["access_token"];
                lock (cachedTokens)
                {
                    cachedTokens[scope] = token;
                    cachedUntil[scope] = DateTime.UtcNow.AddSeconds((int)result["expires_in"] - 300);
                }
                return token;
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
