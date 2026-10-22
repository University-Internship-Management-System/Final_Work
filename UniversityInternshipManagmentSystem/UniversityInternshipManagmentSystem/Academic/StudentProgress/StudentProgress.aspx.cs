using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.Academic.StudentProgress
{
    public partial class StudentProgress : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            AuthHelper.RequireAuth(this, AuthHelper.RoleAcademic);
            if (Response.IsRequestBeingRedirected) return;
            RegisterAsyncTask(new PageAsyncTask(LoadProgressAsync));
        }

        private async Task LoadProgressAsync()
        {
            try
            {
                string supervisorId = Convert.ToString(Session["dbRecordId"] ?? Session["userId"]);
                if (String.IsNullOrWhiteSpace(supervisorId)) throw new InvalidOperationException();
                JObject students = await ReadTable("Students");
                JObject companies = await ReadTable("CompanySupervisors");
                JObject tasks = await ReadTable("Tasks");
                JObject submissions = await ReadTable("TaskSubmissions");

                var assigned = new List<JProperty>();
                foreach (JProperty student in students.Properties())
                    if ((string)student.Value["AcademicSupervisorId"] == supervisorId) assigned.Add(student);
                assigned.Sort((a, b) => String.Compare((string)a.Value["Name"], (string)b.Value["Name"], StringComparison.CurrentCultureIgnoreCase));
                if (assigned.Count == 0)
                {
                    pnlStudent.Visible = false;
                    lblMessage.Text = "No students are currently assigned to this academic supervisor account.";
                    lblMessage.Visible = true;
                    return;
                }

                string requestedId = Request.QueryString["student"];
                JProperty selected = assigned.Find(item => item.Name == requestedId) ?? assigned[0];
                var options = new StringBuilder();
                foreach (JProperty student in assigned)
                {
                    options.Append("<option value=\"").Append(HttpUtility.HtmlAttributeEncode(student.Name)).Append("\"");
                    if (student.Name == selected.Name) options.Append(" selected");
                    options.Append(">").Append(Show((string)student.Value["Name"])).Append(" — ")
                        .Append(Show((string)student.Value["Major"])).Append("</option>");
                }
                litStudentOptions.Text = options.ToString();

                JToken record = selected.Value;
                litStudentName.Text = Show((string)record["Name"]);
                litStudentEmail.Text = Show((string)record["UniEmail"]);
                litStudentMajor.Text = Show((string)record["Major"]);
                litStudentPhone.Text = Show((string)record["PhoneNumber"]);
                string companyId = (string)record["CompanyId"];
                JToken company = String.IsNullOrWhiteSpace(companyId) ? null : companies[companyId];
                litCompanyName.Text = Show(company == null ? null : (string)company["CompanyName"]);
                litSupervisorName.Text = Show(company == null ? null : (string)company["Name"]);
                litSupervisorContact.Text = Show(company == null ? null : (string)company["PhoneNumber"]);

                var latest = new Dictionary<string, JToken>();
                foreach (JProperty entry in submissions.Properties())
                {
                    JToken sub = entry.Value;
                    if (sub == null || (string)sub["StudentId"] != selected.Name) continue;
                    string taskId = (string)sub["TaskId"];
                    if (String.IsNullOrEmpty(taskId)) continue;
                    JToken previous;
                    if (!latest.TryGetValue(taskId, out previous) || (int?)sub["Version"] > (int?)previous["Version"] ||
                        ((int?)sub["Version"] == (int?)previous["Version"] &&
                         String.Compare((string)sub["SubmittedAt"], (string)previous["SubmittedAt"], StringComparison.Ordinal) > 0))
                        latest[taskId] = sub;
                }

                var studentTasks = new List<JProperty>();
                foreach (JProperty task in tasks.Properties())
                {
                    JArray ids = task.Value == null ? null : task.Value["StudentIds"] as JArray;
                    if (ids == null) continue;
                    foreach (JToken id in ids)
                        if ((string)id == selected.Name) { studentTasks.Add(task); break; }
                }
                studentTasks.Sort((a, b) => String.Compare((string)a.Value["DeadLine"], (string)b.Value["DeadLine"], StringComparison.Ordinal));
                litTaskCount.Text = studentTasks.Count.ToString(CultureInfo.InvariantCulture);
                var rows = new StringBuilder();
                foreach (JProperty task in studentTasks)
                {
                    JToken sub;
                    latest.TryGetValue(task.Name, out sub);
                    string state = sub == null ? "" : (string)sub["Status"];
                    string score = state == "Evaluated" && sub["Score"] != null
                        ? Show((string)sub["Score"]) + " / " + Show((string)task.Value["MaxScore"])
                        : state == "Submitted" ? "Pending review" : "—";
                    rows.Append("<tr><td><strong>").Append(Show((string)task.Value["TaskName"]))
                        .Append("</strong></td><td>").Append(Show(FormatDate((string)task.Value["DeadLine"])))
                        .Append("</td><td><span class=\"sp-badge ").Append(StatusClass(state)).Append("\">")
                        .Append(StatusText(state)).Append("</span></td><td>").Append(score)
                        .Append("</td><td>").Append(Show(sub == null ? null : (string)sub["Feedback"]))
                        .Append("</td></tr>");
                }
                litTaskRows.Text = rows.Length == 0
                    ? "<tr><td colspan=\"5\" class=\"sp-empty\">No tasks are currently assigned to this student.</td></tr>"
                    : rows.ToString();
            }
            catch (Exception ex) when (ex is HttpRequestException || ex is JsonException || ex is InvalidOperationException)
            {
                pnlStudent.Visible = false;
                lblMessage.Text = "Could not load progress data from Firebase. Check the connection and permissions, then try again.";
                lblMessage.Visible = true;
            }
        }

        private static async Task<JObject> ReadTable(string name)
        {
            string json = await FirebaseDb.Get(name);
            if (json == null) throw new HttpRequestException();
            return JsonConvert.DeserializeObject<JObject>(json) ?? new JObject();
        }
        private static string Show(string value) { return HttpUtility.HtmlEncode(String.IsNullOrWhiteSpace(value) ? "Not available" : value); }
        private static string FormatDate(string value)
        {
            DateTimeOffset date;
            return DateTimeOffset.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.None, out date)
                ? date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) : value;
        }
        private static string StatusText(string value)
        {
            switch (value) { case "Submitted": return "Pending review"; case "RevisionRequested": return "Revision requested"; case "Evaluated": return "Evaluated"; case "": return "Not submitted"; default: return Show(value); }
        }
        private static string StatusClass(string value)
        {
            switch (value) { case "Submitted": return "sp-pending"; case "RevisionRequested": return "sp-revision"; case "Evaluated": return "sp-done"; default: return "sp-muted"; }
        }
    }
}
