using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
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
                JObject students = await ReadTable("Students");
                JObject supervisors = await ReadTable("AcademicSupervisors");
                JObject companies = await ReadTable("CompanySupervisors");
                JObject submissions = await ReadTable("TaskSubmissions");
                JObject opportunities = await ReadTable("Opportunities");

                var majors = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
                var placedCompanies = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
                var opportunityCompanies = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
                var companyNames = new List<string>();
                int placedStudents = 0;
                int openOpportunities = 0;
                int closedOpportunities = 0;

                foreach (JProperty entry in students.Properties())
                {
                    JToken student = entry.Value;
                    string major = (string)student["Major"];
                    if (string.IsNullOrWhiteSpace(major)) major = "Unspecified major";
                    AddCount(majors, major);

                    string companyId = (string)student["CompanyId"];
                    if (string.IsNullOrWhiteSpace(companyId)) continue;
                    placedStudents++;
                    JToken company = companies[companyId];
                    string name = null;
                    if (company != null) name = (string)company["CompanyName"];
                    if (string.IsNullOrWhiteSpace(name)) name = "Unknown company (" + companyId + ")";
                    AddCount(placedCompanies, name);
                }

                // قد يعمل أكثر من مشرف في الشركة نفسها، لذلك تُحسب الشركة مرة واحدة.
                foreach (JProperty entry in companies.Properties())
                {
                    string name = (string)entry.Value["CompanyName"];
                    if (string.IsNullOrWhiteSpace(name)) continue;
                    bool found = false;
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

                foreach (JProperty entry in opportunities.Properties())
                {
                    JToken opportunity = entry.Value;
                    string status = (string)opportunity["Status"];
                    if (string.Equals(status, "open", StringComparison.OrdinalIgnoreCase)) openOpportunities++;
                    if (string.Equals(status, "closed", StringComparison.OrdinalIgnoreCase)) closedOpportunities++;

                    string name = (string)opportunity["CompanyName"];
                    string companyId = (string)opportunity["CompanyId"];
                    if (string.IsNullOrWhiteSpace(name) && !string.IsNullOrWhiteSpace(companyId))
                    {
                        JToken company = companies[companyId];
                        if (company != null) name = (string)company["CompanyName"];
                    }
                    if (string.IsNullOrWhiteSpace(name)) name = "Unknown company";
                    AddCount(opportunityCompanies, name.Trim());
                }

                litStudents.Text = students.Count.ToString();
                litAssigned.Text = placedStudents.ToString();
                litCompanies.Text = companyNames.Count.ToString();
                litAcademic.Text = supervisors.Count.ToString();
                litEvaluations.Text = CountEvaluatedSubmissions(submissions).ToString();
                litTotalOpportunities.Text = opportunities.Count.ToString();
                litOpenOpportunities.Text = openOpportunities.ToString();
                litClosedOpportunities.Text = closedOpportunities.ToString();
                litChartData.Text = JsonConvert.SerializeObject(new
                {
                    Majors = majors,
                    PlacedCompanies = placedCompanies,
                    OpportunityCompanies = opportunityCompanies,
                    TotalOpportunities = opportunities.Count
                }, new JsonSerializerSettings { StringEscapeHandling = StringEscapeHandling.EscapeHtml });
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
            JObject table = JsonConvert.DeserializeObject<JObject>(json);
            if (table == null) table = new JObject();
            return table;
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