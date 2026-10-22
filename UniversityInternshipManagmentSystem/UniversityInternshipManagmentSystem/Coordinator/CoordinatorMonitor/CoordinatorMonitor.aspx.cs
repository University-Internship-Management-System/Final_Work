using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.Coordinator
{
    public partial class CoordinatorMonitor : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            RegisterAsyncTask(new PageAsyncTask(LoadMonitorAsync));
        }

        private async Task LoadMonitorAsync()
        {
            try
            {
                JObject students = await ReadTable("Students");
                JObject supervisors = await ReadTable("AcademicSupervisors");
                JObject companies = await ReadTable("CompanySupervisors");
                JObject tasks = await ReadTable("Tasks");
                JObject submissions = await ReadTable("TaskSubmissions");

                litStudentRows.Text = BuildStudentRows(students, supervisors, companies);
                litStudentDetails.Text = BuildStudentDrawerData(students, supervisors, companies, tasks, submissions);
                litMajorOptions.Text = BuildMajorOptions(students);
                litAcademicRows.Text = BuildAcademicRows(supervisors);
                litCompanyRows.Text = BuildCompanyRows(companies);

                string academicId = Request.QueryString["academic"];
                string companyId = Request.QueryString["company"];
                if (!string.IsNullOrWhiteSpace(academicId))
                    ShowSupervisorDetail(supervisors, academicId, true);
                else if (!string.IsNullOrWhiteSpace(companyId))
                    ShowSupervisorDetail(companies, companyId, false);
            }
            catch (HttpRequestException)
            {
                lblError.Text = "Data could not be loaded. Check your Firebase rules and connection.";
                lblError.Visible = true;
            }
            catch (InvalidOperationException ex)
            {
                lblError.Text = ex.Message;
                lblError.Visible = true;
            }
            catch (JsonException)
            {
                lblError.Text = "Firebase returned data in an unexpected format.";
                lblError.Visible = true;
            }
        }

        private static async Task<JObject> ReadTable(string name)
        {
            string json = await FirebaseDb.Get(name);
            if (json == null) throw new HttpRequestException();
            return JsonConvert.DeserializeObject<JObject>(json) ?? new JObject();
        }

        private void ShowSupervisorDetail(JObject supervisors, string id, bool isAcademic)
        {
            JToken supervisor = supervisors[id];
            if (supervisor == null)
            {
                lblError.Text = "Supervisor record was not found.";
                lblError.Visible = true;
                return;
            }
            if (isAcademic)
            {
                litDetailTitle.Text = "Academic supervisor details";
            }
            else
            {
                litDetailTitle.Text = "Company supervisor details";
            }
            litUserDetail.Text = BuildSupervisorDetail(id, supervisor, isAcademic);
            pnlUserDetail.Visible = true;
        }

        private static string BuildStudentRows(JObject students, JObject supervisors, JObject companies)
        {
            string rows = "";
            foreach (JProperty studentEntry in students.Properties())
            {
                JToken student = studentEntry.Value;
                string name = (string)student["Name"];
                string email = (string)student["Email"];
                string major = (string)student["Major"];
                string companyId = (string)student["CompanyId"];
                string supervisorId = (string)student["AcademicSupervisorId"];
                string companyName = null;
                string supervisorName = null;
                if (!string.IsNullOrEmpty(companyId) && companies[companyId] != null)
                    companyName = (string)companies[companyId]["CompanyName"];
                if (!string.IsNullOrEmpty(supervisorId) && supervisors[supervisorId] != null)
                    supervisorName = (string)supervisors[supervisorId]["Name"];

                string placement = "unassigned";
                if (!string.IsNullOrEmpty(companyId))
                {
                    placement = "assigned";
                }
                string studentId = HttpUtility.HtmlAttributeEncode(studentEntry.Name);
                string search = HttpUtility.HtmlAttributeEncode(((name ?? "") + " " + (email ?? "")).ToLowerInvariant());
                rows += "<tr class=\"student-row\" data-search=\"" + search +
                    "\" data-major=\"" + HttpUtility.HtmlAttributeEncode(major) +
                    "\" data-placement=\"" + placement + "\">" +
                    "<td class=\"student-name\"><strong>" + Encode(name) + "</strong><br><small class=\"text-muted\">" + Encode(major) + "</small></td>" +
                    "<td>" + Encode(companyName) + "</td><td>" + Encode(supervisorName) + "</td>" +
                    "<td><span class=\"text-muted\">Not recorded</span><div class=\"hours-track\"></div></td>" +
                    "<td><span class=\"status-badge\">Not tracked</span></td>" +
                    "<td><div class=\"student-actions\">" +
                    "<button type=\"button\" class=\"btn btn-outline-primary btn-sm view-student\" data-student=\"" + studentId + "\">&#128065; View Details</button>" +
                    "<button type=\"button\" class=\"btn btn-outline-primary btn-sm more-button\" data-student=\"" + studentId +
                    "\" aria-label=\"More actions for " + HttpUtility.HtmlAttributeEncode(name) +
                    "\" aria-haspopup=\"menu\" aria-expanded=\"false\">&#8943;</button></div></td></tr>";
            }
            if (rows == "")
            {
                return "<tr><td colspan=\"6\" class=\"text-muted\">No students found.</td></tr>";
            }
            return rows;
        }

        private static string BuildStudentDrawerData(JObject students, JObject academic, JObject company, JObject tasks, JObject submissions)
        {
            StringBuilder html = new StringBuilder();
            foreach (JProperty item in students.Properties())
            {
                JToken student = item.Value;
                string academicId = (string)student["AcademicSupervisorId"];
                string companyId = (string)student["CompanyId"];
                JToken supervisor = null;
                JToken employer = null;
                if (!string.IsNullOrEmpty(academicId))
                {
                    supervisor = academic[academicId];
                }
                if (!string.IsNullOrEmpty(companyId))
                {
                    employer = company[companyId];
                }
                html.Append("<div class=\"drawer-record\" data-student=\"" + HttpUtility.HtmlAttributeEncode(item.Name) +
                    "\" data-name=\"" + HttpUtility.HtmlAttributeEncode((string)student["Name"]) +
                    "\" data-major=\"" + HttpUtility.HtmlAttributeEncode((string)student["Major"]) + "\">");
                html.Append("<section data-detail-section=\"overview\">");
                html.Append("<div class=\"drawer-section\"><h3>Student information</h3><div class=\"row student-detail\">");
                AddDetail(html, "Student ID", item.Name);
                AddDetail(html, "Name", (string)student["Name"]);
                AddDetail(html, "Major", (string)student["Major"]);
                AddDetail(html, "Email", (string)student["Email"]);
                AddDetail(html, "University email", (string)student["UniEmail"]);
                AddDetail(html, "Phone", (string)student["PhoneNumber"]);
                AddDetail(html, "GPA", (string)student["GPA"]);
                JArray skills = student["SkillsList"] as JArray;
                string skillNames = null;
                if (skills != null)
                {
                    skillNames = "";
                    foreach (JToken skill in skills)
                    {
                        if (skillNames != "")
                        {
                            skillNames += ", ";
                        }
                        skillNames += (string)skill;
                    }
                }
                AddDetail(html, "Skills", skillNames);
                AddLinkDetail(html, "CV", (string)student["CvUrl"]);
                AddLinkDetail(html, "Portfolio", (string)student["PortfolioUrl"]);
                html.Append("</div></div><div class=\"drawer-section\"><h3>Placement and progress</h3><div class=\"row student-detail\">");
                string companyName = null;
                string supervisorName = null;
                if (employer != null)
                {
                    companyName = (string)employer["CompanyName"];
                }
                if (supervisor != null)
                {
                    supervisorName = (string)supervisor["Name"];
                }
                AddDetail(html, "Training company", companyName);
                AddDetail(html, "Academic supervisor", supervisorName);
                string placementStatus = "Unassigned";
                if (!string.IsNullOrEmpty(companyId))
                {
                    placementStatus = "Assigned";
                }
                AddDetail(html, "Placement status", placementStatus);
                AddDetail(html, "Training hours", "Not recorded");
                AddDetail(html, "Company evaluation", "Not recorded");
                AddDetail(html, "Academic evaluation", "Not recorded");
                AddDetail(html, "Final status", "Not tracked");
                html.Append("</div></div></section>");
                html.Append("<section data-detail-section=\"tasks\"><div class=\"drawer-section\"><h3>Tasks</h3>");
                int taskCount = 0;
                foreach (JProperty taskEntry in tasks.Properties())
                {
                    JToken task = taskEntry.Value;
                    JArray studentIds = task?["StudentIds"] as JArray;
                    if (studentIds == null || !ContainsStudent(studentIds, item.Name)) continue;
                    taskCount++;
                    JToken latest = LatestSubmission(submissions, item.Name, taskEntry.Name);
                    html.Append("<div class=\"mb-3\"><strong>" + Encode((string)task["TaskName"]) + "</strong>");
                    html.Append("<div class=\"text-muted small\">Week " + Encode((string)task["WeekNumber"]) +
                        " · " + Encode(latest == null ? "Not submitted" : (string)latest["Status"]) + "</div></div>");
                }
                if (taskCount == 0) html.Append("<p class=\"drawer-empty\">No tasks assigned.</p>");
                html.Append("</div></section>");
                html.Append("<section data-detail-section=\"hours\"><div class=\"drawer-section\"><h3>Training hours</h3><div class=\"row student-detail\">");
                AddDetail(html, "Approved hours", "Not recorded");
                AddDetail(html, "Pending hours", "Not recorded");
                AddDetail(html, "Required hours", "Not recorded");
                html.Append("</div><p class=\"drawer-empty\">Progress will appear when training hours are recorded.</p></div></section>");
                html.Append("<section data-detail-section=\"evaluations\"><div class=\"drawer-section\"><h3>Task evaluations</h3>");
                int evaluationCount = 0;
                foreach (JProperty taskEntry in tasks.Properties())
                {
                    JArray studentIds = taskEntry.Value?["StudentIds"] as JArray;
                    if (studentIds == null || !ContainsStudent(studentIds, item.Name)) continue;
                    JToken latest = LatestSubmission(submissions, item.Name, taskEntry.Name);
                    if (latest == null || (string)latest["Status"] != "Evaluated" || latest["Score"] == null) continue;
                    evaluationCount++;
                    html.Append("<div class=\"mb-3\"><strong>" + Encode((string)taskEntry.Value["TaskName"]) + "</strong><div>" +
                        Encode((string)latest["Score"]) + " / " + Encode((string)taskEntry.Value["MaxScore"]) + "</div>");
                    if (!string.IsNullOrWhiteSpace((string)latest["Feedback"]))
                        html.Append("<div class=\"text-muted small\">" + Encode((string)latest["Feedback"]) + "</div>");
                    html.Append("</div>");
                }
                if (evaluationCount == 0) html.Append("<p class=\"drawer-empty\">No evaluated task submissions.</p>");
                html.Append("</div><div class=\"drawer-section\"><h3>Final evaluations</h3><p class=\"drawer-empty\">Final evaluations are not connected to this page yet.</p></div></section></div>");
            }
            return html.ToString();
        }

        private static bool ContainsStudent(JArray studentIds, string studentId)
        {
            foreach (JToken id in studentIds)
                if (string.Equals((string)id, studentId, StringComparison.Ordinal)) return true;
            return false;
        }

        private static JToken LatestSubmission(JObject submissions, string studentId, string taskId)
        {
            JToken latest = null;
            foreach (JProperty entry in submissions.Properties())
            {
                JToken submission = entry.Value;
                if ((string)submission?["StudentId"] != studentId || (string)submission["TaskId"] != taskId) continue;
                if (latest == null || (int?)submission["Version"] > (int?)latest["Version"])
                    latest = submission;
            }
            return latest;
        }

        private static string BuildMajorOptions(JObject students)
        {
            string options = "";
            System.Collections.Generic.List<string> majors = new System.Collections.Generic.List<string>();
            foreach (JProperty student in students.Properties())
            {
                string major = (string)student.Value["Major"];
                if (!string.IsNullOrWhiteSpace(major) && !majors.Contains(major))
                {
                    majors.Add(major);
                }
            }
            majors.Sort();
            foreach (string major in majors)
            {
                options += "<option value=\"" + HttpUtility.HtmlAttributeEncode(major) + "\">" + Encode(major) + "</option>";
            }
            return options;
        }

        private static string BuildSupervisorDetail(string id, JToken supervisor, bool isAcademic)
        {
            StringBuilder html = new StringBuilder("<div class=\"row student-detail\">");
            AddDetail(html, "Supervisor ID", id);
            AddDetail(html, "Name", (string)supervisor["Name"]);
            AddDetail(html, "Email", (string)supervisor["Email"]);
            AddDetail(html, "Phone", (string)supervisor["PhoneNumber"]);
            if (isAcademic)
            {
                AddDetail(html, "University email", (string)supervisor["UniversityEmail"]);
                AddDetail(html, "Major", (string)supervisor["Major"]);
            }
            else
            {
                AddDetail(html, "Company email", (string)supervisor["CompEmail"]);
                AddDetail(html, "Company", (string)supervisor["CompanyName"]);
                AddDetail(html, "Location", (string)supervisor["Location"]);
            }
            string firstLogin = "No";
            if ((bool?)supervisor["FirstLogin"] == true)
            {
                firstLogin = "Yes";
            }
            AddDetail(html, "First login", firstLogin);
            AddLinkDetail(html, "Profile picture", (string)supervisor["ProfilePicUrl"]);
            return html.Append("</div>").ToString();
        }

        private static string ViewLink(string kind, string id)
        {
            return "<a class=\"btn btn-outline-primary btn-sm\" href=\"CoordinatorMonitor.aspx?" +
                kind + "=" + HttpUtility.UrlEncode(id) + "\">View</a>";
        }

        private static void AddDetail(StringBuilder html, string label, string value)
        {
            html.Append("<div class=\"col-sm-6 col-xl-4\"><dl class=\"mb-0\"><dt>" +
                Encode(label) + "</dt><dd>" + Encode(value) + "</dd></dl></div>");
        }

        private static void AddLinkDetail(StringBuilder html, string label, string value)
        {
            Uri uri;
            if (!Uri.TryCreate(value, UriKind.Absolute, out uri) ||
                (uri.Scheme != Uri.UriSchemeHttps && uri.Scheme != Uri.UriSchemeHttp))
            {
                AddDetail(html, label, null);
                return;
            }
            html.Append("<div class=\"col-sm-6 col-xl-4\"><dl class=\"mb-0\"><dt>" +
                Encode(label) + "</dt><dd><a target=\"_blank\" rel=\"noopener noreferrer\" href=\"" +
                HttpUtility.HtmlAttributeEncode(uri.AbsoluteUri) + "\">Open " +
                Encode(label) + "</a></dd></dl></div>");
        }

        private static string BuildAcademicRows(JObject academic)
        {
            string rows = "";
            foreach (JProperty item in academic.Properties())
            {
                rows += "<tr><td>" + Encode((string)item.Value["Name"]) +
                    "</td><td>" + Encode((string)item.Value["Email"]) +
                    "</td><td>" + Encode((string)item.Value["Major"]) +
                    "</td><td>" + ViewLink("academic", item.Name) + "</td></tr>";
            }
            if (rows == "")
            {
                return "<tr><td colspan=\"4\" class=\"text-muted\">No academic supervisors found.</td></tr>";
            }
            return rows;
        }

        private static string BuildCompanyRows(JObject company)
        {
            string rows = "";
            foreach (JProperty item in company.Properties())
            {
                rows += "<tr><td>" + Encode((string)item.Value["Name"]) +
                    "</td><td>" + Encode((string)item.Value["CompanyName"]) +
                    "</td><td>" + Encode((string)item.Value["Location"]) +
                    "</td><td>" + ViewLink("company", item.Name) + "</td></tr>";
            }
            if (rows == "")
            {
                return "<tr><td colspan=\"4\" class=\"text-muted\">No company supervisors found.</td></tr>";
            }
            return rows;
        }

        private static string Encode(string value)
        {
            return HttpUtility.HtmlEncode(string.IsNullOrWhiteSpace(value) ? "—" : value);
        }
    }
}




