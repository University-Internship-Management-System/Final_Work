using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.IO;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web;
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
            if (!Request.IsLocal)
            {
                lblDataError.Text = "Live data preview is available only from this computer.";
                lblDataError.Visible = true;
                return;
            }

            try
            {
                // Each call reads one section from Firebase.
                JObject students = JsonConvert.DeserializeObject<JObject>(await FirebaseDb.Get("Students")) ?? new JObject();
                JObject supervisors = JsonConvert.DeserializeObject<JObject>(await FirebaseDb.Get("AcademicSupervisors")) ?? new JObject();
                JObject companies = JsonConvert.DeserializeObject<JObject>(await FirebaseDb.Get("CompanySupervisors")) ?? new JObject();
                JObject evaluations = JsonConvert.DeserializeObject<JObject>(await FirebaseDb.Get("Evaluations")) ?? new JObject();
                JObject opportunities = JsonConvert.DeserializeObject<JObject>(await FirebaseDb.Get("Opportunities")) ?? new JObject();

                int studentCount = 0;
                int assignedStudents = 0;
                string studentRows = "";
                foreach (JProperty student in students.Properties())
                {
                    studentCount++;
                    string companyId = (string)student.Value["CompanyId"];
                    string placement = "Unassigned";
                    if (!string.IsNullOrWhiteSpace(companyId))
                    {
                        assignedStudents++;
                        placement = "Assigned";
                    }
                    if (studentCount <= 5)
                    {
                        studentRows += "<tr><td>" + Encode((string)student.Value["Name"]) +
                            "</td><td>" + Encode((string)student.Value["Major"]) +
                            "</td><td>" + placement + "</td></tr>";
                    }
                }

                int academicCount = 0;
                foreach (JProperty supervisor in supervisors.Properties())
                {
                    academicCount++;
                }

                int evaluationCount = 0;
                string evaluationRows = "";
                foreach (JProperty evaluation in evaluations.Properties())
                {
                    evaluationCount++;
                    if (evaluationCount <= 5)
                    {
                        string studentId = (string)evaluation.Value["StudentId"];
                        string studentName = (string)evaluation.Value["StudentName"];
                        if (!string.IsNullOrEmpty(studentId) && students[studentId] != null)
                        {
                            studentName = (string)students[studentId]["Name"];
                        }
                        evaluationRows += "<tr><td>" + Encode(studentName) +
                            "</td><td>" + Encode((string)evaluation.Value["Score"]) +
                            "</td><td>" + Encode((string)evaluation.Value["Status"]) + "</td></tr>";
                    }
                }

                // Several supervisors can belong to the same company.
                var companyNames = new System.Collections.Generic.List<string>();
                int companyCount = 0;
                string companyRows = "";
                int companyRowCount = 0;
                foreach (JProperty company in companies.Properties())
                {
                    companyRowCount++;
                    string companyName = (string)company.Value["CompanyName"];
                    if (companyRowCount <= 5)
                    {
                        companyRows += "<tr><td>" + Encode(companyName) +
                            "</td><td>" + Encode((string)company.Value["Name"]) +
                            "</td><td>" + Encode((string)company.Value["Location"]) + "</td></tr>";
                    }
                    if (string.IsNullOrWhiteSpace(companyName))
                    {
                        continue;
                    }

                    bool alreadyCounted = false;
                    foreach (string savedName in companyNames)
                    {
                        if (string.Equals(savedName, companyName, StringComparison.OrdinalIgnoreCase))
                        {
                            alreadyCounted = true;
                            break;
                        }
                    }

                    if (!alreadyCounted)
                    {
                        companyNames.Add(companyName);
                        companyCount++;
                    }
                }

                string opportunityRows = "";
                int opportunityCount = 0;
                foreach (JProperty opportunity in opportunities.Properties())
                {
                    opportunityCount++;
                    if (opportunityCount <= 5)
                    {
                        opportunityRows += "<tr><td>" + Encode((string)opportunity.Value["Title"]) +
                            "</td><td>" + Encode((string)opportunity.Value["CompanyName"]) +
                            "</td><td>" + Encode((string)opportunity.Value["Status"]) + "</td></tr>";
                    }
                }

                litStudents.Text = studentCount.ToString();
                litAssigned.Text = assignedStudents.ToString();
                litAcademic.Text = academicCount.ToString();
                litEvaluations.Text = evaluationCount.ToString();
                litCompanies.Text = companyCount.ToString();
                litStudentPreview.Text = studentRows == "" ? EmptyRow("No students yet.") : studentRows;
                litEvaluationPreview.Text = evaluationRows == "" ? EmptyRow("No evaluations in Firebase yet.") : evaluationRows;
                litCompanyPreview.Text = companyRows == "" ? EmptyRow("No companies yet.") : companyRows;
                litOpportunityPreview.Text = opportunityRows == "" ? EmptyRow("No opportunities in Firebase yet.") : opportunityRows;
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

        private static string EmptyRow(string message)
        {
            return "<tr><td colspan=\"3\" class=\"text-muted py-3\">" + Encode(message) + "</td></tr>";
        }

        private static string Encode(string value)
        {
            return HttpUtility.HtmlEncode(string.IsNullOrWhiteSpace(value) ? "—" : value);
        }
    }

}


