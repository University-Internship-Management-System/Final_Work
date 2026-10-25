
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using System.Web.UI;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using UniversityInternshipManagmentSystem.Config;
using StudentModel = UniversityInternshipManagmentSystem.Models.Student;
using UniversityInternshipManagmentSystem.Models;
using UniversityInternshipManagmentSystem.Student.StudentTasksPage;

namespace UniversityInternshipManagmentSystem.Student.StudentDashboardPage
{
    public partial class Dashboard : StudentPage
    {
        protected string ActivityError { get; private set; }
        protected bool ActivityAvailable { get; private set; }
        protected bool TasksAvailable { get; private set; }
        protected string CompanyText => Overview.CompanyName ?? (string.IsNullOrWhiteSpace(Workspace?.CompanyId) ? "No company assigned" : "Company name unavailable");
        protected string HoursText => Overview.ApprovedHours.HasValue ? Overview.ApprovedHours.Value.ToString("0.##", CultureInfo.InvariantCulture) + " / 90 h" : "—";
        protected int? ProgressPercent => Overview.ProgressPercent;

        protected DashboardOverview Overview { get; private set; }
            = new DashboardOverview();

        protected void Page_Load(object sender, EventArgs e)
        {
            RegisterAsyncTask(new PageAsyncTask(LoadDashboardAsync));
        }

        private async Task LoadDashboardAsync()
        {
            await LoadWorkspaceAsync();
            if (Workspace == null) return;
            await LoadActivitiesAsync(VerifiedStudentId);
            ApplicationsList.DataSource = Overview.Applications;
            ApplicationsList.DataBind();
            TasksList.DataSource = Overview.Tasks;
            TasksList.DataBind();
            DeadlinesList.DataSource = Overview.Deadlines;
            DeadlinesList.DataBind();
            EvaluationsList.DataSource = Overview.Evaluations;
            EvaluationsList.DataBind();
        }

        private async Task LoadActivitiesAsync(string studentId)
        {
            try
            {
                var data = await ReadOwnApplicationsAsync();
                var applications = data.Type == JTokenType.Null
                    ? new Dictionary<string, UniversityInternshipManagmentSystem.Models.Application>()
                    : data.ToObject<Dictionary<string, UniversityInternshipManagmentSystem.Models.Application>>();

                foreach (var item in applications.OrderByDescending(entry => entry.Value.AppliedAt))
                {
                    var application = item.Value;

                    if (application == null ||
                        application.StudentId != studentId)
                        continue;

                    Overview.Applications.Add(new ActivityItem
                    {
                        Title = application.OpportunityTitle ??
                                "Internship application",
                        Detail = application.CompanyName ?? "",
                        Status = application.Status ?? "Status unavailable"
                    });
                }

                ActivityAvailable = true;
            }
            catch (Exception error) when (error is StudentDataException || error is UnauthorizedAccessException || error is JsonException)
            {
                ActivityError = "Applications could not be loaded. " + error.Message;
            }
            try
            {
                var tasks = await ReadOwnTasksAsync();
                var rawSubmissions = await ReadOwnSubmissionsAsync();
                var submissions = rawSubmissions.Type == JTokenType.Null ? new Dictionary<string, TaskSubmission>()
                    : rawSubmissions.ToObject<Dictionary<string, TaskSubmission>>();
                var companyRaw = await ReadOwnRecordAsync("FinalEvaluations");
                var academicRaw = await ReadOwnRecordAsync("AcademicEvaluations");
                var company = companyRaw.Type == JTokenType.Null ? null : companyRaw.ToObject<FinalEvaluation>();
                var academic = academicRaw.Type == JTokenType.Null ? null : academicRaw.ToObject<AcademicEvaluation>();
                var name = await ReadPlacementCompanyNameAsync();
                PopulateTrainingOverview(Overview, studentId, Workspace.CompanyId, tasks, submissions.Values.ToList(), company, academic, name, DateTime.UtcNow);
                TasksAvailable = true;
            }
            catch (Exception error) when (error is StudentDataException || error is UnauthorizedAccessException || error is JsonException)
            {
                ActivityError = (ActivityError == null ? "" : ActivityError + " ") + "Training summaries could not be loaded. " + error.Message;
            }
        }

        // The callers supply only verified student-scoped reads. Recheck ownership before producing any visible summary.
        private static void PopulateTrainingOverview(DashboardOverview overview, string studentId, string companyId,
            Dictionary<string, Tasks> tasks, List<TaskSubmission> submissions, FinalEvaluation company, AcademicEvaluation academic,
            string companyName, DateTime nowUtc)
        {
            if (tasks.Values.Any(task => task.StudentIds == null || !task.StudentIds.Contains(studentId) || task.CompanyId != companyId)
                || submissions.Any(sub => sub.StudentId != studentId)
                || (company != null && company.CompanyId != companyId)
                || (academic != null && (academic.StudentId != studentId || academic.CompanyId != companyId)))
                throw new UnauthorizedAccessException("Training records do not belong to your current placement.");

            var active = tasks.Where(entry => entry.Value.Status == TaskState.Open).OrderBy(entry => entry.Value.WeekNumber).ThenBy(entry => entry.Value.DeadLine).ToList();
            var latest = submissions.GroupBy(sub => sub.TaskId).ToDictionary(group => group.Key,
                group => group.OrderByDescending(sub => sub.Version).ThenByDescending(sub => sub.SubmittedAt).First());
            foreach (var entry in active)
            {
                var task = entry.Value;
                TaskSubmission last;
                latest.TryGetValue(entry.Key, out last);
                var state = last == null ? (task.DeadLine.ToUniversalTime() < nowUtc ? "Overdue" : "To do")
                    : last.Status == SubmissionState.Evaluated ? "Evaluated" : last.Status == SubmissionState.RevisionRequested ? "Changes requested" : "Waiting for review";
                var activity = new ActivityItem { Title = task.TaskName, Detail = "Week " + task.WeekNumber + " · " + task.HoursFor(studentId) + " training hours", Status = state, DueUtc = new DateTimeOffset(task.DeadLine.ToUniversalTime()) };
                overview.Tasks.Add(activity);
                if ((last == null || last.Status == SubmissionState.RevisionRequested) && task.DeadLine.ToUniversalTime() >= nowUtc)
                    overview.Deadlines.Add(activity);
                if (last != null && last.Status != SubmissionState.Submitted && (!string.IsNullOrWhiteSpace(last.Feedback) || last.Score.HasValue))
                    overview.Evaluations.Add(new ActivityItem { Title = task.TaskName, Status = state,
                        Detail = (last.Score.HasValue ? "Score: " + last.Score.Value.ToString("0.##", CultureInfo.InvariantCulture) + " / " + task.MaxScore.ToString("0.##", CultureInfo.InvariantCulture) + ". " : "") + (last.Feedback ?? ""), DueUtc = activity.DueUtc });
            }
            overview.Deadlines = overview.Deadlines.OrderBy(item => item.DueUtc).ToList();
            overview.CompanyName = companyName;
            overview.RequiredHours = 90; // Same six-week training requirement used by the company evaluation form.
            overview.ApprovedHours = company?.ApprovedWeeks == null ? 0 : company.ApprovedWeeks.Values.Sum();
            overview.ProgressPercent = Math.Max(0, Math.Min(100, (int)Math.Round(overview.ApprovedHours.Value * 100 / 90)));
            overview.InternshipStatus = string.IsNullOrWhiteSpace(companyId) ? "Waiting for a confirmed placement" : "Training in progress";
            if (company != null && company.Status == FinalEvaluation.Sent)
            {
                overview.InternshipStatus = "Company evaluation sent for academic review";
                overview.Evaluations.Add(new ActivityItem { Title = "Company final evaluation", Status = "Sent", Detail = company.Comments ?? "Company evaluation submitted." });
            }
            if (academic != null && academic.Status == AcademicEvaluation.Sent)
            {
                overview.InternshipStatus = "Academic review sent. See My Progress for final completion approval.";
                overview.Evaluations.Add(new ActivityItem { Title = "Academic final evaluation", Status = "Sent", Detail = academic.Comments ?? "Academic evaluation submitted." });
            }
        }

        protected string ActivityCount(int count, bool available)
        {
            return available
                ? count.ToString(CultureInfo.InvariantCulture)
                : "—";
        }

        protected string RecordCount(int count)
        {
            return ActivityAvailable
                ? count + " records"
                : "Not connected";
        }

        protected string FormatDeadline(object value)
        {
            if (value is DateTimeOffset)
            {
                return ((DateTimeOffset)value)
                    .ToUniversalTime()
                    .ToString("dd MMM yyyy HH:mm 'UTC'",
                        CultureInfo.InvariantCulture);
            }

            return "Not provided";
        }

        protected class ActivityItem
        {
            public string Title { get; set; }
            public string Detail { get; set; }
            public string Status { get; set; }
            public DateTimeOffset? DueUtc { get; set; }
        }

        protected class DashboardOverview
        {
            public string CompanyName { get; set; }
            public List<ActivityItem> Applications { get; set; }
                = new List<ActivityItem>();

            public List<ActivityItem> Tasks { get; set; }
                = new List<ActivityItem>();

            public List<ActivityItem> Deadlines { get; set; }
                = new List<ActivityItem>();

            public List<ActivityItem> Evaluations { get; set; }
                = new List<ActivityItem>();

            public double? ApprovedHours { get; set; }
            public double? RequiredHours { get; set; }
            public string InternshipStatus { get; set; }
            public int? ProgressPercent { get; set; }
        }
    }
}
