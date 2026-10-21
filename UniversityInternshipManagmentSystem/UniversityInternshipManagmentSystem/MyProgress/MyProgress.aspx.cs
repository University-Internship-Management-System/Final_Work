
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.UI;
using Newtonsoft.Json;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;

namespace UniversityInternshipManagmentSystem.Student
{
    public partial class MyProgress : Page
    {
        private const int TotalWeeks = 6;

        public class WeekProgress
        {
            public int WeekNumber { get; set; }
            public int TaskCount { get; set; }
            public int SubmittedCount { get; set; }
            public int ProgressPercentage { get; set; }
        }

        //protected void Page_Load(object sender, EventArgs e)
        //{
        //    // Temporary test session ONLY
        //    // Remove after implementing real login
        //    if (Session["studentId"] == null)
        //        Session["studentId"] = "student001";

        //    Session["role"] = "student";
        //    Session["name"] = "Ahmad Ali";

        //    if (!IsPostBack)
        //    {
        //        RegisterAsyncTask(
        //            new PageAsyncTask(LoadProgressAsync));
        //    }
        //}

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // Get logged-in student ID from Session
                string studentId =
                    Session["studentId"] as string;

                // Check if student is logged in
                if (string.IsNullOrWhiteSpace(studentId))
                {
                    Response.Redirect("~/Login.aspx", false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }

                // Load tasks asynchronously
                RegisterAsyncTask(
                    new PageAsyncTask(LoadProgressAsync));
            }
        }

        private async Task LoadProgressAsync()
        {
            try
            {
                string studentId =
                    Session["studentId"] as string;

                if (string.IsNullOrWhiteSpace(studentId))
                    return;

                // Get Tasks from Firebase
                string tasksJson =
                    await FirebaseDb.Get("Tasks");

                var allTasks =
                    JsonConvert.DeserializeObject<
                        Dictionary<string, Tasks>>(tasksJson)
                    ?? new Dictionary<string, Tasks>();

                // Get Task Submissions from Firebase
                string submissionsJson =
                    await FirebaseDb.Get("TaskSubmissions");

                var allSubmissions =
                    JsonConvert.DeserializeObject<
                        Dictionary<string, TaskSubmission>>(submissionsJson)
                    ?? new Dictionary<string, TaskSubmission>();

                // Tasks assigned to this student
                List<Tasks> studentTasks = allTasks
                    .Where(item =>
                        item.Value != null &&
                        item.Value.StudentIds != null &&
                        item.Value.StudentIds.Contains(studentId))
                    .Select(item =>
                    {
                        item.Value.TaskId = item.Key;
                        return item.Value;
                    })
                    .Where(task =>
                        task.WeekNumber >= 1 &&
                        task.WeekNumber <= TotalWeeks)
                    .ToList();

                // Submissions belonging to this student
                var studentSubmissions = allSubmissions
                    .Where(item =>
                        item.Value != null &&
                        item.Value.StudentId == studentId &&
                        !string.IsNullOrWhiteSpace(
                            item.Value.TaskId))
                    .Select(item => item.Value)
                    .ToList();

                // Latest submission for each Task
                var latestSubmissions = studentSubmissions
                    .GroupBy(s => s.TaskId)
                    .ToDictionary(
                        group => group.Key,
                        group => group
                            .OrderByDescending(s => s.Version)
                            .ThenByDescending(s => s.SubmittedAt)
                            .First()
                    );

                // Display total assigned tasks
                litTotalTasks.Text =
                    studentTasks.Count.ToString();

                List<WeekProgress> weeks =
                    new List<WeekProgress>();

                for (int week = 1; week <= TotalWeeks; week++)
                {
                    var weeklyTasks = studentTasks
                        .Where(t => t.WeekNumber == week)
                        .ToList();

                    int total = weeklyTasks.Count;
                    int submitted = 0;

                    foreach (var task in weeklyTasks)
                    {
                        TaskSubmission submission;

                        if (latestSubmissions.TryGetValue(
                            task.TaskId, out submission))
                        {
                            if (submission.Status ==
                                SubmissionState.Submitted)
                            {
                                submitted++;
                            }
                        }
                    }

                    int percentage = total == 0
                        ? 0
                        : (int)Math.Round(
                            (double)submitted * 100 / total,
                            MidpointRounding.AwayFromZero);

                    weeks.Add(new WeekProgress
                    {
                        WeekNumber = week,
                        TaskCount = total,
                        SubmittedCount = submitted,
                        ProgressPercentage = percentage
                    });
                }

                rptWeeks.DataSource = weeks;
                rptWeeks.DataBind();

                pnlError.Visible = false;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(
                    "Progress Error: " + ex.ToString());

                pnlError.Visible = true;
                litError.Text =
                    "Unable to load your progress. Please try again later.";

                // Do not display fake progress if loading fails.
                rptWeeks.DataSource = null;
                rptWeeks.DataBind();
            }
        }
    }
}
