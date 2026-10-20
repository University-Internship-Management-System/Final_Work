using Newtonsoft.Json;
using System.Net.Http;
using System.Threading.Tasks;

namespace UniversityInternshipManagmentSystem.Config
{
    // Simple Firebase Realtime Database requests.
    // "table" is the name of the node, for example "Students" or "Supervisors".
    public static class FirebaseDb
    {
        public static HttpClient client = new HttpClient();

        // GET all records of a table:  string json = await FirebaseDb.Get("Students");
        public static async Task<string> Get(string table)
        {
            return await client.GetStringAsync(AppConfig.DbUrl + table + ".json");
        }

        // GET one record by id:  string json = await FirebaseDb.Get("Students", id);
        public static async Task<string> Get(string table, string id)
        {
            return await client.GetStringAsync(AppConfig.DbUrl + table + "/" + id + ".json");
        }

        // POST adds a new record and Firebase makes the id.
        // The response body looks like { "name": "-Nxyz..." } and "name" is the new id.
        public static async Task<HttpResponseMessage> Post(string table, object data)
        {
            return await client.PostAsync(AppConfig.DbUrl + table + ".json",
                new StringContent(JsonConvert.SerializeObject(data)));
        }

        // PUT saves a record under the id you give (replaces it if it exists).
        public static async Task<HttpResponseMessage> Put(string table, string id, object data)
        {
            return await client.PutAsync(AppConfig.DbUrl + table + "/" + id + ".json",
                new StringContent(JsonConvert.SerializeObject(data)));
        }

        // DELETE removes the record with that id.
        public static async Task<HttpResponseMessage> Delete(string table, string id)
        {
            return await client.DeleteAsync(AppConfig.DbUrl + table + "/" + id + ".json");
        }
    }
}
