using Newtonsoft.Json;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web;

namespace UniversityInternshipManagmentSystem.Config
{
    // Firebase Realtime Database requests.
    // "table" is the name of the node, for example "Students" or "Users".
    public static class FirebaseDb
    {
        public static HttpClient client = new HttpClient();

        private static string ResolveToken(string idToken)
        {
            if (!string.IsNullOrEmpty(idToken))
                return idToken;

            if (HttpContext.Current != null && HttpContext.Current.Session != null)
            {
                return HttpContext.Current.Session["idToken"] as string;
            }

            return null;
        }

        public static string BuildUrl(string table, string id = null, string idToken = null)
        {
            string url = AppConfig.DbUrl.TrimEnd('/') + "/" + table.Trim('/');
            if (!string.IsNullOrEmpty(id))
            {
                url += "/" + id;
            }
            url += ".json";

            string token = ResolveToken(idToken);
            if (!string.IsNullOrEmpty(token))
            {
                url += "?auth=" + token;
            }

            return url;
        }

        // GET all records of a table:  string json = await FirebaseDb.Get("Students");
        public static async Task<string> Get(string table, string id = null, string idToken = null)
        {
            string url = BuildUrl(table, id, idToken);
            var response = await client.GetAsync(url);
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }
            return await response.Content.ReadAsStringAsync();
        }

        // POST adds a new record and Firebase generates the id.
        public static async Task<HttpResponseMessage> Post(string table, object data, string idToken = null)
        {
            string url = BuildUrl(table, null, idToken);
            string json = JsonConvert.SerializeObject(data);
            return await client.PostAsync(url, new StringContent(json, Encoding.UTF8, "application/json"));
        }

        // PUT saves a record under the id you specify (replaces whole node).
        public static async Task<HttpResponseMessage> Put(string table, string id, object data, string idToken = null)
        {
            string url = BuildUrl(table, id, idToken);
            string json = JsonConvert.SerializeObject(data);
            return await client.PutAsync(url, new StringContent(json, Encoding.UTF8, "application/json"));
        }

        // PATCH updates specific fields of a record without wiping other fields.
        public static async Task<HttpResponseMessage> Patch(string table, string id, object data, string idToken = null)
        {
            string url = BuildUrl(table, id, idToken);
            string json = JsonConvert.SerializeObject(data);
            var request = new HttpRequestMessage(new HttpMethod("PATCH"), url)
            {
                Content = new StringContent(json, Encoding.UTF8, "application/json")
            };
            return await client.SendAsync(request);
        }

        // DELETE removes the record with that id.
        public static async Task<HttpResponseMessage> Delete(string table, string id, string idToken = null)
        {
            string url = BuildUrl(table, id, idToken);
            return await client.DeleteAsync(url);
        }
    }
}
