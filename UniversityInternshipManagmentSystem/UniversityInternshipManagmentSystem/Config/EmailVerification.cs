using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace UniversityInternshipManagmentSystem.Config
{
    // "Confirm your email" with Firebase Authentication only (no SMTP): Firebase sends the email and keeps
    // the "verified" flag of the account.
    // A new account made by the coordinator gets the field RequireEmailVerification = true in its record.
    // Such an account can not sign in until the link in the email is opened. Older accounts do not have the
    // field, so they sign in as before.
    public static class EmailVerification
    {
        public const string RequiredField = "RequireEmailVerification";

        // Marks a new account as "must confirm its email", then asks Firebase to email the link.
        // idToken = the token that Firebase gave when the login account was created.
        // Returns "sent" or "failed". It never throws, so it can not break the creation of the account.
        public static async Task<string> RequireAndSend(string table, string recordId, string idToken)
        {
            try
            {
                var marked = await FirebaseDb.Patch(table, recordId, new JObject { { RequiredField, true } });
                if (!marked.IsSuccessStatusCode) return "failed";
                return await Send(idToken) ? "sent" : "failed";
            }
            catch (Exception)
            {
                return "failed";
            }
        }

        // Asks Firebase to email the confirmation link to the account that owns this token.
        public static async Task<bool> Send(string idToken)
        {
            var content = new StringContent(
                JsonConvert.SerializeObject(new { requestType = "VERIFY_EMAIL", idToken = idToken }),
                Encoding.UTF8, "application/json");
            using (var response = await FirebaseDb.client.PostAsync(AppConfig.SendOobCodeUrl, content))
                return response.IsSuccessStatusCode;
        }

        // True when this account must confirm its email and has not done it yet.
        public static async Task<bool> IsBlocked(string table, string recordId, string idToken)
        {
            if (string.IsNullOrEmpty(table) || string.IsNullOrEmpty(recordId)) return false;

            string json = await FirebaseDb.Get(table, recordId, idToken);
            if (string.IsNullOrEmpty(json) || json.Trim() == "null") return false;
            var required = JObject.Parse(json)[RequiredField];
            if (required == null || required.Type != JTokenType.Boolean || !(bool)required) return false;

            return !await IsVerified(idToken);
        }

        // Firebase keeps "emailVerified" on the login account (not in our database).
        static async Task<bool> IsVerified(string idToken)
        {
            var content = new StringContent(JsonConvert.SerializeObject(new { idToken = idToken }), Encoding.UTF8, "application/json");
            using (var response = await FirebaseDb.client.PostAsync(AppConfig.AccountLookupUrl, content))
            {
                if (!response.IsSuccessStatusCode) throw new HttpRequestException("Could not check the email confirmation.");
                var users = JObject.Parse(await response.Content.ReadAsStringAsync())["users"] as JArray;
                return users != null && users.Count > 0 && (bool?)users[0]["emailVerified"] == true;
            }
        }

        // The sentence the coordinator pages add to the "saved" message.
        public static string MessageFor(string result)
        {
            if (result == "sent") return " A confirmation email was sent. The person must open it before signing in.";
            if (result == "failed") return " The confirmation email could not be sent. It will be sent again when the person tries to sign in.";
            return "";
        }
    }
}
