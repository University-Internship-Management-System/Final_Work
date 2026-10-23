using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Config;

namespace UniversityInternshipManagmentSystem.Coordinator
{
    public partial class CoordinatorMonitor : Page
    {
        private const int RequiredTrainingHours = 90;

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
                JObject reports = await ReadOptionalTable("FinalEvaluations");
                JObject academicReports = await ReadOptionalTable("AcademicEvaluations");
                JObject certificates = await ReadOptionalTable("Certificate");
                string studentData;
                BuildStudents(students, supervisors, companies, tasks, submissions, reports, academicReports, certificates, out studentData);
                litStudentDetails.Text = studentData;
                litAcademicRows.Text = BuildSupervisorRows(supervisors, true);
                litCompanyRows.Text = BuildSupervisorRows(companies, false);

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
            JObject table = JsonConvert.DeserializeObject<JObject>(json);
            if (table == null) table = new JObject();
            return table;
        }

        private static async Task<JObject> ReadOptionalTable(string name)
        {
            string json = await FirebaseDb.Get(name);
            if (json == null) return null;
            JObject table = JsonConvert.DeserializeObject<JObject>(json);
            if (table == null) table = new JObject();
            return table;
        }

        private static void BuildStudents(JObject students, JObject supervisors, JObject companies, JObject tasks,
            JObject submissions, JObject reports, JObject academicReports, JObject certificates,
            out string data)
        {
            var records = new List<object>();
            foreach (JProperty entry in students.Properties())
            {
                JToken student = entry.Value;
                string studentId = entry.Name;
                string name = (string)student["Name"];
                string email = (string)student["Email"];
                string major = (string)student["Major"];
                string companyId = (string)student["CompanyId"];
                string supervisorId = (string)student["AcademicSupervisorId"];
                JToken company = null;
                if (!string.IsNullOrEmpty(companyId)) company = companies[companyId];
                JToken supervisor = null;
                if (!string.IsNullOrEmpty(supervisorId)) supervisor = supervisors[supervisorId];
                string companyName = null;
                if (company != null) companyName = (string)company["CompanyName"];
                string supervisorName = null;
                if (supervisor != null) supervisorName = (string)supervisor["Name"];

                JToken report = null;
                if (reports != null) report = reports[studentId];
                if (report != null && !String.Equals((string)report["CompanyId"], companyId, StringComparison.Ordinal)) report = null;
                string companyStatus = ReportStatus(reports, report);
                JToken academicReport = null;
                if (academicReports != null) academicReport = academicReports[studentId];
                if (academicReport != null &&
                    (!String.Equals((string)academicReport["StudentId"], studentId, StringComparison.Ordinal) ||
                     !String.Equals((string)academicReport["AcademicSupervisorId"], supervisorId, StringComparison.Ordinal) ||
                     !String.Equals((string)academicReport["CompanyId"], companyId, StringComparison.Ordinal)))
                    academicReport = null;
                string academicStatus = ReportStatus(academicReports, academicReport);
                JToken certificate = null;
                if (certificates != null)
                {
                    foreach (JProperty item in certificates.Properties())
                    {
                        if ((string)item.Value["StudentId"] != studentId) continue;
                        certificate = item.Value;
                        break;
                    }
                }
                string stage = CompletionStage(certificate, reports, academicReports, certificates,
                    academicStatus, companyStatus, companyId);

                int approvedHours = 0;
                JObject signedWeeks = null;
                if (report != null) signedWeeks = report["ApprovedWeeks"] as JObject;
                if (signedWeeks != null)
                {
                    // الساعات المعتمدة تُحسب من الأسابيع الموقعة في تقرير الشركة.
                    foreach (JProperty week in signedWeeks.Properties())
                    {
                        int hours;
                        if (Int32.TryParse((string)week.Value, NumberStyles.Integer, CultureInfo.InvariantCulture, out hours) && hours > 0)
                            approvedHours += hours;
                    }
                }
                int assignedHours = 0;
                int evaluatedHours = 0;
                int pendingHours = 0;
                int submittedTasks = 0;
                var studentTasks = new List<object>();
                foreach (JProperty task in StudentTasks(tasks, studentId))
                {
                    JToken latest = LatestSubmission(submissions, studentId, task.Name);
                    string status = null;
                    string feedback = null;
                    string score = null;
                    if (latest != null)
                    {
                        status = (string)latest["Status"];
                        feedback = (string)latest["Feedback"];
                        score = (string)latest["Score"];
                    }
                    int hours = TaskHours(task.Value, studentId);
                    assignedHours += hours;
                    if (String.Equals(status, "Submitted", StringComparison.OrdinalIgnoreCase) ||
                        String.Equals(status, "Evaluated", StringComparison.OrdinalIgnoreCase)) submittedTasks++;
                    if (String.Equals(status, "Evaluated", StringComparison.OrdinalIgnoreCase))
                    {
                        evaluatedHours += hours;
                        int week = 0;
                        if (task.Value["WeekNumber"] != null) week = (int)task.Value["WeekNumber"];
                        if (signedWeeks == null || !signedWeeks.ContainsKey("w" + week)) pendingHours += hours;
                    }
                    studentTasks.Add(new
                    {
                        Name = (string)task.Value["TaskName"],
                        Week = (string)task.Value["WeekNumber"],
                        Hours = hours,
                        Status = status,
                        Feedback = feedback,
                        Score = score,
                        MaxScore = (string)task.Value["MaxScore"]
                    });
                }
                int approvedPercent = Math.Min(100, (int)Math.Round(100.0 * approvedHours / RequiredTrainingHours));
                bool isPlaced = !string.IsNullOrEmpty(companyId);
                records.Add(new
                {
                    Id = studentId, Name = name, Major = major, Email = email,
                    UniversityEmail = (string)student["UniEmail"], Phone = (string)student["PhoneNumber"],
                    Gpa = (string)student["GPA"], Skills = student["SkillsList"] as JArray,
                    CvUrl = (string)student["CvUrl"], PortfolioUrl = (string)student["PortfolioUrl"],
                    CompanyName = companyName, AcademicSupervisorName = supervisorName, Placed = isPlaced,
                    AssignedTasks = studentTasks.Count, SubmittedTasks = submittedTasks,
                    AssignedHours = assignedHours, EvaluatedHours = evaluatedHours, ApprovedHours = approvedHours,
                    PendingHours = pendingHours, ApprovedPercent = approvedPercent, RequiredHours = RequiredTrainingHours,
                    CompanyReportStatus = companyStatus, AcademicReportStatus = academicStatus, CompletionStage = stage,
                    CompanyReport = report, AcademicReport = academicReport, Certificate = certificate, Tasks = studentTasks
                });
            }
            data = JsonConvert.SerializeObject(new { Students = records, Academics = supervisors, Companies = companies }, new JsonSerializerSettings
            {
                StringEscapeHandling = StringEscapeHandling.EscapeHtml
            });
        }

        private static string ReportStatus(JObject table, JToken report)
        {
            if (table == null) return "Unavailable";
            if (report == null) return "Not started";
            if (String.Equals((string)report["Status"], "Sent", StringComparison.OrdinalIgnoreCase)) return "Sent";
            return "Draft";
        }

        private static string CompletionStage(JToken certificate, JObject reports, JObject academicReports,
            JObject certificates, string academicStatus, string companyStatus, string companyId)
        {
            if (certificate != null)
            {
                bool adminPassed = (bool?)certificate["IsPassAdmin"] == true;
                bool companyPassed = (bool?)certificate["IsPassCompany"] == true;
                bool academicPassed = (bool?)certificate["IsPassAcademic"] == true;
                if (adminPassed && companyPassed && academicPassed) return "Approved";
                return "Coordinator record";
            }
            if (reports == null || academicReports == null || certificates == null) return "Unavailable";
            if (academicStatus == "Sent") return "Academic sent";
            if (companyStatus == "Sent") return "Company sent";
            if (companyStatus == "Draft") return "Company draft";
            if (!String.IsNullOrWhiteSpace(companyId)) return "Training";
            return "Unassigned";
        }

        private static int TaskHours(JToken task, string studentId)
        {
            JObject overrides = task["StudentHours"] as JObject;
            JToken value = overrides == null ? null : overrides[studentId];
            if (value == null) value = task["Hours"];
            int hours;
            return Int32.TryParse((string)value, NumberStyles.Integer, CultureInfo.InvariantCulture, out hours)
                ? Math.Max(0, hours) : 0;
        }

        private static List<JProperty> StudentTasks(JObject tasks, string studentId)
        {
            var assigned = new List<JProperty>();
            foreach (JProperty task in tasks.Properties())
            {
                if (task.Value == null || task.Value.Type == JTokenType.Null ||
                    String.Equals((string)task.Value["Status"], "Closed", StringComparison.OrdinalIgnoreCase)) continue;
                JArray studentIds = task.Value["StudentIds"] as JArray;
                if (studentIds != null && ContainsStudent(studentIds, studentId)) assigned.Add(task);
            }
            return assigned;
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
                if (latest == null || (int?)submission["Version"] > (int?)latest["Version"] ||
                    ((int?)submission["Version"] == (int?)latest["Version"] &&
                     String.Compare((string)submission["SubmittedAt"], (string)latest["SubmittedAt"], StringComparison.Ordinal) > 0))
                    latest = submission;
            }
            return latest;
        }

        private static string ViewLink(string kind, string id)
        {
            return "<a class=\"btn btn-outline-primary btn-sm\" href=\"CoordinatorMonitor.aspx?" +
                kind + "=" + HttpUtility.UrlEncode(id) + "\">View</a>";
        }

        private static string BuildSupervisorRows(JObject supervisors, bool academic)
        {
            string rows = "";
            foreach (JProperty item in supervisors.Properties())
            {
                string secondColumn = academic ? (string)item.Value["Email"] : (string)item.Value["CompanyName"];
                string thirdColumn = academic ? (string)item.Value["Major"] : (string)item.Value["Location"];
                string linkType = academic ? "academic" : "company";
                rows += "<tr><td>" + Encode((string)item.Value["Name"]) +
                    "</td><td>" + Encode(secondColumn) +
                    "</td><td>" + Encode(thirdColumn) +
                    "</td><td>" + ViewLink(linkType, item.Name) + "</td></tr>";
            }
            if (rows == "")
            {
                string message = academic ? "No academic supervisors found." : "No company supervisors found.";
                return "<tr><td colspan=\"4\" class=\"text-muted\">" + message + "</td></tr>";
            }
            return rows;
        }

        private static string Encode(string value)
        {
            return HttpUtility.HtmlEncode(string.IsNullOrWhiteSpace(value) ? "—" : value);
        }
    }
}
