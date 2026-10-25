using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.Coordinator
{
    // Server-only Firebase account administration. The key stays outside the repository.
    internal static class CompanyAccountAccess
    {
        private static string CredentialsPath
        {
            // App_Data/keys/firebase-admin.json (team file) or the Windows variable, see Config/TeamKeys.cs
            get { return TeamKeys.FindFile(TeamKeys.FirebaseAdminVariable, TeamKeys.FirebaseAdminFile); }
        }

        public static bool IsConfigured
        {
            get { return !String.IsNullOrWhiteSpace(CredentialsPath) && File.Exists(CredentialsPath); }
        }

        public static async Task<Dictionary<string, bool>> GetDisabledAccounts(string[] ids)
        {
            var states = new Dictionary<string, bool>();
            if (ids.Length == 0) return states;
            // Firebase lookup accepts at most 100 identifiers per request.
            for (int offset = 0; offset < ids.Length; offset += 100)
            {
                var batch = new string[Math.Min(100, ids.Length - offset)];
                Array.Copy(ids, offset, batch, 0, batch.Length);
                var result = await Send("lookup", new { localId = batch });
                var users = result["users"] as JArray;
                if (users == null) continue;
                foreach (var user in users)
                    states[(string)user["localId"]] = (bool?)user["disabled"] ?? false;
            }
            return states;
        }

        public static async Task SetDisabled(string id, bool disabled)
        {
            await Send("update", new { localId = id, disableUser = disabled });
        }

        // Asks Firebase Authentication. When it fails, error.Data["Step"] says which step (the page shows it to the coordinator).
        private static async Task<JObject> Send(string action, object data)
        {
            string step = "reading the admin key file";
            try
            {
                if (!IsConfigured) throw new InvalidOperationException("The Firebase admin key file was not found.");
                string projectId = (string)JObject.Parse(File.ReadAllText(CredentialsPath))["project_id"];
                string host = new Uri(AppConfig.DbUrl).Host;
                if (String.IsNullOrWhiteSpace(projectId)
                    || !(host.StartsWith(projectId + "-", StringComparison.OrdinalIgnoreCase)
                         || host.StartsWith(projectId + ".", StringComparison.OrdinalIgnoreCase)))
                    throw new InvalidOperationException("The admin key does not belong to the configured Firebase project.");

                step = "getting a Google token with the admin key";
                string accessToken = await FirebaseAdmin.AccountToken();

                step = "asking Firebase Authentication";
                string url = "https://identitytoolkit.googleapis.com/v1/projects/" + Uri.EscapeDataString(projectId) + "/accounts:" + action;
                using (var request = new HttpRequestMessage(HttpMethod.Post, url))
                {
                    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
                    request.Content = new StringContent(JsonConvert.SerializeObject(data), Encoding.UTF8, "application/json");
                    using (var response = await FirebaseDb.client.SendAsync(request))
                    {
                        if (!response.IsSuccessStatusCode) throw new HttpRequestException("Firebase account administration failed.");
                        return JObject.Parse(await response.Content.ReadAsStringAsync());
                    }
                }
            }
            catch (Exception error)
            {
                error.Data["Step"] = step;
                throw;
            }
        }
    }
}
