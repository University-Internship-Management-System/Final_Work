using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace UniversityInternshipManagmentSystem.Config
{
    // "A task is due soon" emails. A timer starts with the website (Global.asax) and every 30 minutes it looks for:
    //   an OPEN task, whose deadline is in the next 24 hours, for a trainee who has not sent work yet
    //   (or who was asked to change the work and did not send the new version).
    // That trainee gets one email per task (the task remembers it in Tasks/<id>/RemindersSent/<studentId>).
    //
    // It runs without a signed-in person, so it reads the database with the Firebase admin key (Config/FirebaseAdmin.cs).
    // It does nothing when SMTP or the admin key is missing. It only runs while the website is running.
    public static class DeadlineReminders
    {
        // Remind when the deadline is this close
        const int HoursBefore = 24;

        static Timer timer;
        static int running;

        public static void Start()
        {
            if (timer != null) return;
            timer = new Timer(state => Check(), null, TimeSpan.FromMinutes(2), TimeSpan.FromMinutes(30));
        }

        static void Check()
        {
            // never two runs at the same time
            if (Interlocked.Exchange(ref running, 1) == 1) return;
            try
            {
                RunOnce().GetAwaiter().GetResult();
            }
            catch (Exception ex)
            {
                EmailSender.Log("deadline reminders failed | " + ex.Message);
            }
            finally
            {
                Interlocked.Exchange(ref running, 0);
            }
        }

        // One check. Returns how many emails were sent. (Public so a test can run it without waiting for the timer.)
        public static async Task<int> RunOnce()
        {
            if (!EmailSender.IsConfigured || !FirebaseAdmin.IsConfigured) return 0;

            string token = await FirebaseAdmin.DatabaseToken();
            JObject tasks = await ReadTable("Tasks", token);
            JObject submissions = await ReadTable("TaskSubmissions", token);
            JObject students = await ReadTable("Students", token);

            DateTime now = DateTime.Now;
            int sent = 0;
            foreach (var entry in tasks.Properties())
            {
                var task = entry.Value as JObject;
                if (task == null || !string.Equals((string)task["Status"], "Open", StringComparison.OrdinalIgnoreCase)) continue;

                DateTime deadline;
                if (!DateTime.TryParse((string)task["DeadLine"], System.Globalization.CultureInfo.InvariantCulture,
                        System.Globalization.DateTimeStyles.None, out deadline)) continue;
                if (deadline <= now || deadline > now.AddHours(HoursBefore)) continue;

                string taskId = entry.Name;
                string taskName = (string)task["TaskName"] ?? "your task";
                var already = task["RemindersSent"] as JObject;

                foreach (string studentId in IdsOf(task["StudentIds"]))
                {
                    if (already != null && already[studentId] != null) continue;
                    if (HasSentWork(submissions, taskId, studentId)) continue;

                    var student = students[studentId] as JObject;
                    string email = student == null ? null : (string)student["Email"];
                    if (string.IsNullOrWhiteSpace(email)) continue;

                    string id = taskId, who = studentId;
                    await Notify.TaskDeadlineReminder((string)student["Name"], email, taskName, deadline, async () =>
                    {
                        // remember it, so the trainee gets this reminder only once
                        string url = AppConfig.DbUrl.TrimEnd('/') + "/Tasks/" + id + "/RemindersSent.json?access_token=" + Uri.EscapeDataString(token);
                        var request = new HttpRequestMessage(new HttpMethod("PATCH"), url)
                        {
                            Content = new StringContent(JsonConvert.SerializeObject(new JObject { { who, true } }), Encoding.UTF8, "application/json")
                        };
                        using (await FirebaseDb.client.SendAsync(request)) { }
                        sent++;
                    });
                }
            }

            EmailSender.Log("deadline reminders: checked " + tasks.Count + " task(s), sent " + sent);
            return sent;
        }

        // The trainee already sent work that waits for the supervisor, or that was scored: no reminder needed.
        // (No work at all, or "changes requested" as the newest version: the trainee still has to act.)
        static bool HasSentWork(JObject submissions, string taskId, string studentId)
        {
            JObject newest = null;
            foreach (var item in submissions.Properties())
            {
                var s = item.Value as JObject;
                if (s == null || (string)s["TaskId"] != taskId || (string)s["StudentId"] != studentId) continue;
                if (newest == null || ((int?)s["Version"] ?? 0) > ((int?)newest["Version"] ?? 0)) newest = s;
            }
            if (newest == null) return false;
            string status = (string)newest["Status"];
            return !string.Equals(status, "RevisionRequested", StringComparison.OrdinalIgnoreCase);
        }

        // Firebase stores a list as an array, or as an object when some numbers are missing
        static IEnumerable<string> IdsOf(JToken token)
        {
            if (token is JArray) return token.Values<string>().Where(v => !string.IsNullOrEmpty(v));
            if (token is JObject) return ((JObject)token).Properties().Select(p => (string)p.Value).Where(v => !string.IsNullOrEmpty(v));
            return Enumerable.Empty<string>();
        }

        static async Task<JObject> ReadTable(string table, string token)
        {
            string url = AppConfig.DbUrl.TrimEnd('/') + "/" + table + ".json?access_token=" + Uri.EscapeDataString(token);
            using (var response = await FirebaseDb.client.GetAsync(url))
            {
                if (!response.IsSuccessStatusCode) throw new HttpRequestException("Could not read " + table + ".");
                string json = await response.Content.ReadAsStringAsync();
                return string.IsNullOrWhiteSpace(json) || json.Trim() == "null" ? new JObject() : JObject.Parse(json);
            }
        }
    }
}
