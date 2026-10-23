using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.Coordinator
{
    public partial class CoordinatorDashbord : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }
            RegisterAsyncTask(new PageAsyncTask(ShowDashboardAsync));
        }

        private async Task ShowDashboardAsync()
        {
            try
            {
                // Each call reads one section from Firebase.
                JObject students = await ReadTable("Students");
                JObject supervisors = await ReadTable("AcademicSupervisors");
                JObject companies = await ReadTable("CompanySupervisors");
                JObject submissions = await ReadTable("TaskSubmissions");
                JObject opportunities = await ReadTable("Opportunities");

                int studentCount = 0;
                int assignedStudents = 0;
                foreach (JProperty student in students.Properties())
                {
                    studentCount++;
                    string companyId = (string)student.Value["CompanyId"];
                    if (!string.IsNullOrWhiteSpace(companyId))
                        assignedStudents++;
                }

                int academicCount = 0;
                foreach (JProperty supervisor in supervisors.Properties())
                {
                    academicCount++;
                }

                int evaluationCount = 0;
                var latestSubmissions = new System.Collections.Generic.Dictionary<string, JToken>();
                foreach (JProperty submission in submissions.Properties())
                {
                    JToken item = submission.Value;
                    if (item == null) continue;
                    string key = (string)item["StudentId"] + "|" + (string)item["TaskId"];
                    JToken previous;
                    if (!latestSubmissions.TryGetValue(key, out previous) ||
                        (int?)item["Version"] > (int?)previous["Version"])
                        latestSubmissions[key] = item;
                }
                foreach (JToken item in latestSubmissions.Values)
                {
                    if (item == null || (string)item["Status"] != "Evaluated" || item["Score"] == null) continue;
                    evaluationCount++;
                }

                // Several supervisors can belong to the same company.
                var companyNames = new System.Collections.Generic.List<string>();
                int companyCount = 0;
                foreach (JProperty company in companies.Properties())
                {
                    string companyName = (string)company.Value["CompanyName"];
                    if (string.IsNullOrWhiteSpace(companyName))
                    {
                        continue;
                    }

                    bool alreadyCounted = false;
                    foreach (string savedName in companyNames)
                    {
                        if (string.Equals(savedName, name, StringComparison.OrdinalIgnoreCase))
                        {
                            found = true;
                            break;
                        }
                    }
                    if (!found) companyNames.Add(name);
                }

                int opportunityCount = 0;
                int openOpportunityCount = 0;
                int closedOpportunityCount = 0;
                var opportunityCompanies = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
                foreach (JProperty opportunity in opportunities.Properties())
                {
                    opportunityCount++;
                    string opportunityStatus = (string)opportunity.Value["Status"];
                    if (string.Equals(opportunityStatus, "open", StringComparison.OrdinalIgnoreCase)) openOpportunityCount++;
                    if (string.Equals(opportunityStatus, "closed", StringComparison.OrdinalIgnoreCase)) closedOpportunityCount++;
                    string opportunityCompanyId = (string)opportunity.Value["CompanyId"];
                    string opportunityCompanyName = (string)opportunity.Value["CompanyName"];
                    if (string.IsNullOrWhiteSpace(opportunityCompanyName) && !string.IsNullOrWhiteSpace(opportunityCompanyId) && companies[opportunityCompanyId] != null)
                        opportunityCompanyName = (string)companies[opportunityCompanyId]["CompanyName"];
                    if (string.IsNullOrWhiteSpace(opportunityCompanyName)) opportunityCompanyName = "Unknown company";
                    opportunityCompanyName = opportunityCompanyName.Trim();
                    opportunityCompanies[opportunityCompanyName] = opportunityCompanies.ContainsKey(opportunityCompanyName)
                        ? opportunityCompanies[opportunityCompanyName] + 1 : 1;
                }

                litStudents.Text = studentCount.ToString();
                litAssigned.Text = assignedStudents.ToString();
                litAcademic.Text = academicCount.ToString();
                litEvaluations.Text = evaluationCount.ToString();
                litCompanies.Text = companyCount.ToString();
                litMajorChart.Text = BuildMajorChart(students);
                litCompanyChart.Text = BuildCompanyChart(students, companies);
                litTotalOpportunities.Text = opportunityCount.ToString();
                litOpenOpportunities.Text = openOpportunityCount.ToString();
                litClosedOpportunities.Text = closedOpportunityCount.ToString();
                litOpportunityCompanies.Text = BuildOpportunityCharts(opportunityCompanies, opportunityCount);
            }
            catch (HttpRequestException)
            {
                lblDataError.Text = "Data could not be loaded. Check your Firebase Realtime Database rules and connection.";
                lblDataError.Visible = true;
            }
            catch (InvalidOperationException ex)
            {
                lblDataError.Text = ex.Message;
                lblDataError.Visible = true;
            }
            catch (JsonException)
            {
                lblDataError.Text = "Firebase returned data in an unexpected format.";
                lblDataError.Visible = true;
            }
        }

        private static async Task<JObject> ReadTable(string name)
        {
            string json = await FirebaseDb.Get(name);
            if (json == null) throw new HttpRequestException();
            return JsonConvert.DeserializeObject<JObject>(json) ?? new JObject();
        }

        private static string BuildMajorChart(JObject students)
        {
            var counts = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            foreach (JProperty entry in students.Properties())
            {
                string major = (string)entry.Value["Major"];
                if (string.IsNullOrWhiteSpace(major)) major = "Unspecified major";
                counts[major] = counts.ContainsKey(major) ? counts[major] + 1 : 1;
            }
            if (counts.Count == 0) return "<p class=\"chart-empty\">No student majors to display.</p>";

            var rows = new List<KeyValuePair<string, int>>(counts);
            rows.Sort((a, b) => b.Value != a.Value ? b.Value.CompareTo(a.Value) : StringComparer.OrdinalIgnoreCase.Compare(a.Key, b.Key));
            string[] colors = { "#2563eb", "#0d9488", "#f59e0b", "#8b5cf6", "#e55371", "#0891b2", "#65a30d", "#ea580c" };
            int maximum = rows[0].Value;
            var html = new StringBuilder();
            html.Append("<div class=\"major-chart\" role=\"img\" aria-label=\"Number of students in each major\">")
                .Append("<div class=\"major-y-axis\"><span>").Append(maximum)
                .Append("</span><span>").Append((int)Math.Round(maximum / 2.0, MidpointRounding.AwayFromZero))
                .Append("</span><span>0</span></div><div class=\"major-chart-scroll\"><div class=\"major-columns\">");
            for (int index = 0; index < rows.Count; index++)
            {
                var row = rows[index];
                int height = (int)Math.Round(170.0 * row.Value / maximum);
                // لكل تخصص لون مستقل، ويتكرر ترتيب الألوان إذا زاد عدد التخصصات.
                html.Append("<div class=\"major-column\" title=\"")
                    .Append(HttpUtility.HtmlAttributeEncode(row.Key + ": " + row.Value + " students"))
                    .Append("\"><div class=\"major-bar-space\"><strong class=\"major-bar-value\">")
                    .Append(row.Value).Append("</strong><span class=\"major-bar\" style=\"height:")
                    .Append(height).Append("px;background-color:").Append(colors[index % colors.Length])
                    .Append("\"></span></div><span class=\"major-name\">").Append(Encode(row.Key))
                    .Append("</span></div>");
            }
            html.Append("</div></div></div>");
            return html.ToString();
        }

        private static string BuildCompanyChart(JObject students, JObject companies)
        {
            var counts = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            foreach (JProperty entry in students.Properties())
            {
                string companyId = (string)entry.Value["CompanyId"];
                if (string.IsNullOrWhiteSpace(companyId)) continue;
                JToken company = companies[companyId];
                string name = company == null ? null : (string)company["CompanyName"];
                if (string.IsNullOrWhiteSpace(name)) name = "Unknown company (" + companyId + ")";
                counts[name] = counts.ContainsKey(name) ? counts[name] + 1 : 1;
            }
            return BuildBarRows(counts, "company", "No students are assigned to companies yet.");
        }

        private static string BuildBarRows(Dictionary<string, int> counts, string kind, string emptyMessage)
        {
            if (counts.Count == 0) return "<p class=\"chart-empty\">" + Encode(emptyMessage) + "</p>";
            var rows = new List<KeyValuePair<string, int>>(counts);
            rows.Sort((a, b) => b.Value != a.Value ? b.Value.CompareTo(a.Value) : StringComparer.OrdinalIgnoreCase.Compare(a.Key, b.Key));
            int maximum = rows[0].Value;
            var html = new StringBuilder();
            foreach (var row in rows)
            {
                int width = (int)Math.Round(100.0 * row.Value / maximum);
                html.Append("<div class=\"chart-row\"><div class=\"chart-row-label\"><span title=\"")
                    .Append(HttpUtility.HtmlAttributeEncode(row.Key)).Append("\">").Append(Encode(row.Key))
                    .Append("</span><strong>").Append(row.Value).Append("</strong></div>")
                    .Append("<div class=\"chart-track\" aria-hidden=\"true\"><span class=\"chart-fill ")
                    .Append(kind).Append("\" style=\"width:").Append(width).Append("%\"></span></div></div>");
            }
            return html.ToString();
        }

        private static string BuildOpportunityCharts(Dictionary<string, int> counts, int total)
        {
            if (total == 0) return "<p class=\"chart-empty\">No opportunities in Firebase yet.</p>";

            var rows = new List<KeyValuePair<string, int>>(counts);
            rows.Sort((a, b) => b.Value != a.Value ? b.Value.CompareTo(a.Value) : StringComparer.OrdinalIgnoreCase.Compare(a.Key, b.Key));
            var html = new StringBuilder();
            html.Append("<div class=\"opportunity-charts\"><div class=\"opportunity-bars-panel\"><h4>Opportunities by company</h4><div class=\"opportunity-bars-scroll\"><div class=\"opportunity-bars\">");
            int maximum = rows.Count == 0 ? 1 : rows[0].Value;
            for (int index = 0; index < rows.Count; index++)
            {
                var row = rows[index];
                int height = (int)Math.Round(160.0 * row.Value / maximum);
                string color = "hsl(" + ((index * 137 + 205) % 360) + ", 68%, 56%)";
                // الأعمدة تعرض عدد الفرص لكل شركة فقط، وتطابق ألوان أجزاء الدائرة.
                html.Append("<div class=\"opportunity-bar-column\" title=\"")
                    .Append(HttpUtility.HtmlAttributeEncode(row.Key + ": " + row.Value + " opportunities"))
                    .Append("\"><div class=\"opportunity-bar-space\"><strong>").Append(row.Value)
                    .Append("</strong><span class=\"opportunity-bar\" style=\"height:").Append(height)
                    .Append("px;background-color:").Append(color)
                    .Append("\"></span></div><span class=\"opportunity-bar-name\">")
                    .Append(Encode(row.Key)).Append("</span></div>");
            }
            html.Append("</div></div></div><div class=\"opportunity-pie-panel\"><h4>Opportunities by company</h4>");
            // كل جزء من الدائرة يمثل حصة شركة من جميع الفرص، مع لون مطابق في القائمة.
            var gradient = new StringBuilder("conic-gradient(");
            int cumulative = 0;
            for (int index = 0; index < rows.Count; index++)
            {
                if (index > 0) gradient.Append(',');
                string color = "hsl(" + ((index * 137 + 205) % 360) + ", 68%, 56%)";
                int start = cumulative;
                cumulative += rows[index].Value;
                gradient.Append(color).Append(' ')
                    .Append((100.0 * start / total).ToString("0.####", System.Globalization.CultureInfo.InvariantCulture))
                    .Append("% ")
                    .Append((100.0 * cumulative / total).ToString("0.####", System.Globalization.CultureInfo.InvariantCulture))
                    .Append('%');
            }
            gradient.Append(')');
            html.Append("<div class=\"opportunity-pie\" role=\"img\" aria-label=\"Share of opportunities by company\" style=\"background:")
                .Append(gradient).Append("\"></div><div class=\"opportunity-pie-legend\">");
            for (int index = 0; index < rows.Count; index++)
            {
                var row = rows[index];
                string color = "hsl(" + ((index * 137 + 205) % 360) + ", 68%, 56%)";
                html.Append("<span title=\"").Append(HttpUtility.HtmlAttributeEncode(row.Key))
                    .Append("\"><i style=\"background-color:").Append(color).Append("\"></i><span class=\"pie-company-name\">")
                    .Append(Encode(row.Key)).Append("</span><strong>").Append(row.Value).Append("</strong></span>");
            }
            html.Append("</div></div></div>");
            return html.ToString();
        }

        private static void AddCount(Dictionary<string, int> counts, string name)
        {
            if (!counts.ContainsKey(name)) counts[name] = 0;
            counts[name]++;
        }

        private static int CountEvaluatedSubmissions(JObject submissions)
        {
            var latest = new Dictionary<string, JToken>();
            foreach (JProperty entry in submissions.Properties())
            {
                JToken submission = entry.Value;
                if (submission == null) continue;
                string key = (string)submission["StudentId"] + "|" + (string)submission["TaskId"];
                JToken previous;
                if (!latest.TryGetValue(key, out previous) ||
                    (int?)submission["Version"] > (int?)previous["Version"])
                    latest[key] = submission;
            }
            int count = 0;
            foreach (JToken submission in latest.Values)
            {
                if ((string)submission["Status"] == "Evaluated" && submission["Score"] != null)
                    count++;
            }
            return count;
        }
    }
}