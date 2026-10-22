
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.UI;
using Newtonsoft.Json;

using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;

using StudentModel =
    UniversityInternshipManagmentSystem.Models.Student;

using TaskModel =
    UniversityInternshipManagmentSystem.Models.Tasks;

namespace UniversityInternshipManagmentSystem.Company
{
    public partial class Dashboard : Page
    {
        public class StudentRow
        {
            public string Id { get; set; }
            public string Name { get; set; }
            public string Initial { get; set; }
            public string Major { get; set; }
            public string Email { get; set; }
            public int TaskCount { get; set; }
        }

        public class SubmissionRow
        {
            public string StudentName { get; set; }
            public string TaskName { get; set; }
            public string SubmittedDate { get; set; }
            public string Status { get; set; }
            public string StatusClass { get; set; }
            public string ScoreText { get; set; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/Default.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            // Login stores the company record key separately from the Firebase Auth UID.
            string companyId = (Session["dbRecordId"] as string) ?? AuthHelper.UserId;

            if (string.IsNullOrWhiteSpace(companyId))
            {
                pnlError.Visible = true;
                litError.Text =
                    "Company information is missing from your session.";
                return;
            }

            if (!IsPostBack)
            {
                RegisterAsyncTask(
                    new PageAsyncTask(LoadDashboardAsync));
            }
        }

        private async Task LoadDashboardAsync()
        {
            try
            {
                string companyId =
                    (Session["dbRecordId"] as string) ?? AuthHelper.UserId;

                if (string.IsNullOrWhiteSpace(companyId))
                    return;

                // Read Firebase tables
                string studentsJson =
                    await FirebaseDb.Get("Students");

                string tasksJson =
                    await FirebaseDb.Get("Tasks");

                string submissionsJson =
                    await FirebaseDb.Get("TaskSubmissions");

                // Deserialize Students
                var allStudents =
                    JsonConvert.DeserializeObject<
                        Dictionary<string, StudentModel>>(
                            studentsJson)
                    ?? new Dictionary<string, StudentModel>();

                // Deserialize Tasks
                var allTasks =
                    JsonConvert.DeserializeObject<
                        Dictionary<string, TaskModel>>(
                            tasksJson)
                    ?? new Dictionary<string, TaskModel>();

                // Deserialize TaskSubmissions
                var allSubmissions =
                    JsonConvert.DeserializeObject<
                        Dictionary<string, TaskSubmission>>(
                            submissionsJson)
                    ?? new Dictionary<string, TaskSubmission>();

                // Students assigned to this company
                var companyStudents = allStudents
                    .Where(item =>
                        item.Value != null &&
                        item.Value.CompanyId == companyId)
                    .ToDictionary(
                        item => item.Key,
                        item => item.Value);

                // Tasks belonging to this company
                var companyTasks = allTasks
                    .Where(item =>
                        item.Value != null &&
                        item.Value.CompanyId == companyId)
                    .ToDictionary(
                        item => item.Key,
                        item => item.Value);

                // Only valid student-task assignments
                var assignedPairs = new HashSet<string>();

                foreach (var task in companyTasks)
                {
                    if (task.Value.StudentIds == null)
                        continue;

                    foreach (string studentId in task.Value.StudentIds)
                    {
                        if (studentId != null &&
                            companyStudents.ContainsKey(studentId))
                        {
                            assignedPairs.Add(
                                studentId + "|" + task.Key);
                        }
                    }
                }

                // List of company trainees
                var students = companyStudents
                    .Select(item =>
                    {
                        string name =
                            item.Value.Name ?? "Unknown Student";

                        int taskCount = companyTasks.Count(task =>
                            task.Value.StudentIds != null &&
                            task.Value.StudentIds.Contains(item.Key));

                        return new StudentRow
                        {
                            Id = item.Key,
                            Name = name,
                            Initial = name.Length > 0
                                ? name.Substring(0, 1).ToUpper()
                                : "?",
                            Major = item.Value.Major ?? "Not specified",
                            Email = item.Value.Email ?? "",
                            TaskCount = taskCount
                        };
                    })
                    .OrderBy(s => s.Name)
                    .ToList();

                // Only submissions for assigned students
                // and tasks belonging to this company
                var relevantSubmissions = allSubmissions
                    .Where(item =>
                        item.Value != null &&
                        !string.IsNullOrWhiteSpace(
                            item.Value.StudentId) &&
                        !string.IsNullOrWhiteSpace(
                            item.Value.TaskId) &&
                        assignedPairs.Contains(
                            item.Value.StudentId + "|" +
                            item.Value.TaskId))
                    .Select(item => item.Value)
                    .ToList();

                // Count latest submission only
                var latestSubmissions = relevantSubmissions
                    .GroupBy(s => new
                    {
                        s.StudentId,
                        s.TaskId
                    })
                    .Select(group => group
                        .OrderByDescending(s => s.Version)
                        .ThenByDescending(s => s.SubmittedAt)
                        .First())
                    .ToList();

                int submittedCount =
                    latestSubmissions.Count(s =>
                        s.Status == SubmissionState.Submitted);

                int revisionCount =
                    latestSubmissions.Count(s =>
                        s.Status ==
                        SubmissionState.RevisionRequested);

                int evaluatedCount =
                    latestSubmissions.Count(s =>
                        s.Status == SubmissionState.Evaluated);

                // Summary cards
                litStudents.Text =
                    students.Count.ToString();

                litTasks.Text =
                    companyTasks.Count.ToString();

                litPending.Text =
                    submittedCount.ToString();

                litEvaluated.Text =
                    evaluatedCount.ToString();

                // Status overview
                litSubmitted.Text =
                    submittedCount.ToString();

                litRevision.Text =
                    revisionCount.ToString();

                litEvaluatedSummary.Text =
                    evaluatedCount.ToString();

                // Bind students
                rptStudents.DataSource = students;
                rptStudents.DataBind();

                pnlNoStudents.Visible =
                    students.Count == 0;

                // Recent submissions
                var recentSubmissions = latestSubmissions
                    .OrderByDescending(s => s.SubmittedAt)
                    .Take(8)
                    .Select(s =>
                    {
                        StudentModel student =
                            companyStudents[s.StudentId];

                        TaskModel task =
                            companyTasks[s.TaskId];

                        return new SubmissionRow
                        {
                            StudentName =
                                student.Name ?? "Unknown Student",

                            TaskName =
                                task.TaskName ?? "Untitled Task",

                            SubmittedDate =
                                s.SubmittedAt.ToString(
                                    "dd MMM yyyy"),

                            Status = s.Status.ToString(),

                            StatusClass =
                                GetStatusClass(s.Status),

                            ScoreText = s.Score.HasValue
                                ? s.Score.Value.ToString("0.##")
                                : "—"
                        };
                    })
                    .ToList();

                rptSubmissions.DataSource =
                    recentSubmissions;

                rptSubmissions.DataBind();

                pnlNoSubmissions.Visible =
                    recentSubmissions.Count == 0;

                pnlError.Visible = false;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(
                    "Company Dashboard Error: " +
                    ex.ToString());

                pnlError.Visible = true;

                litError.Text =
                    "Unable to load dashboard data. " +
                    "Please try again later.";
            }
        }

        private string GetStatusClass(
            SubmissionState status)
        {
            switch (status)
            {
                case SubmissionState.Submitted:
                    return "cd-badge-submitted";

                case SubmissionState.RevisionRequested:
                    return "cd-badge-revision";

                case SubmissionState.Evaluated:
                    return "cd-badge-evaluated";

                default:
                    return "";
            }
        }
    }
}
