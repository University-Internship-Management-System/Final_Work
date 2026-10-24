using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.UI;
using Newtonsoft.Json;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;

using InternshipApplication =
    UniversityInternshipManagmentSystem.Models.Application;

namespace UniversityInternshipManagmentSystem.Student
{
    public partial class MyProgress : Page
    {
        private const int TotalWeeks = 6;

        protected bool CoursePassed { get; private set; }

        protected string CertificateDownloadUrl { get; set; }

        protected string CurrentCertificateId { get; private set; }

        protected int? CurrentTrainingWeek { get; private set; }

        protected bool TrainingWeeksFinished { get; private set; }

        private readonly HashSet<int> completedTrainingWeeks = new HashSet<int>();

        protected int CompletedTrainingWeekCount { get { return completedTrainingWeeks.Count; } }

        public class WeekProgress
        {
            public int WeekNumber { get; set; }
            public int TaskCount { get; set; }
            public int SubmittedCount { get; set; }
            public int ProgressPercentage { get; set; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            string userId = Session["userId"] as string;

            if (string.IsNullOrWhiteSpace(userId))
            {
                Response.Redirect("~/login/Login.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            RegisterAsyncTask(
                new PageAsyncTask(LoadProgressAsync));
        }

        private async Task LoadProgressAsync()
        {
            try
            {
                string studentId =
                    Session["dbRecordId"] as string;

                if (string.IsNullOrWhiteSpace(studentId))
                {
                    studentId = Session["userId"] as string;
                }

                if (string.IsNullOrWhiteSpace(studentId))
                    return;

                CoursePassed = false;
                CertificateDownloadUrl = string.Empty;
                CurrentCertificateId = null;

                // Read the student's current confirmed opportunity.
                string opportunityId =
                    await GetCurrentOpportunityIdAsync(studentId);

                // Read the actual administrator approval.
                await LoadCertificateAsync(
                    studentId,
                    opportunityId);

                // Load tasks.
                string tasksJson =
                    await FirebaseDb.Get("Tasks");

                if (string.IsNullOrWhiteSpace(tasksJson))
                {
                    throw new InvalidOperationException(
                        "Unable to read tasks from Firebase.");
                }

                var allTasks =
                    JsonConvert.DeserializeObject<
                        Dictionary<string, Tasks>>(tasksJson)
                    ?? new Dictionary<string, Tasks>();

                // Load submissions.
                string submissionsJson =
                    await FirebaseDb.Get("TaskSubmissions");

                if (string.IsNullOrWhiteSpace(submissionsJson))
                {
                    throw new InvalidOperationException(
                        "Unable to read submissions from Firebase.");
                }

                var allSubmissions =
                    JsonConvert.DeserializeObject<
                        Dictionary<string, TaskSubmission>>(
                            submissionsJson)
                    ?? new Dictionary<string, TaskSubmission>();

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

                completedTrainingWeeks.Clear();

var studentSubmissions = allSubmissions
                    .Where(item =>
                        item.Value != null &&
                        item.Value.StudentId == studentId &&
                        !string.IsNullOrWhiteSpace(
                            item.Value.TaskId))
                    .Select(item =>
                    {
                        item.Value.Id = item.Key;
                        return item.Value;
                    })
                    .ToList();

                var latestSubmissions = studentSubmissions
                    .GroupBy(submission => submission.TaskId)
                    .ToDictionary(
                        group => group.Key,
                        group => group
                            .OrderByDescending(
                                submission => submission.Version)
                            .ThenByDescending(
                                submission => submission.SubmittedAt)
                            .First());

                litTotalTasks.Text =
                    studentTasks.Count.ToString();

                List<WeekProgress> weeks =
                    new List<WeekProgress>();

                for (int week = 1; week <= TotalWeeks; week++)
                {
                    var weeklyTasks = studentTasks
                        .Where(task => task.WeekNumber == week)
                        .ToList();

                    int total = weeklyTasks.Count;
                    int submitted = 0;

                    foreach (Tasks task in weeklyTasks)
                    {
                        TaskSubmission submission;

                        if (latestSubmissions.TryGetValue(
                            task.TaskId,
                            out submission))
                        {
                            if (submission.Status ==
                                    SubmissionState.Submitted ||
                                submission.Status ==
                                    SubmissionState.Evaluated)
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

                CalculateTrainingWeek(weeks);

                rptWeeks.DataSource = weeks;
                rptWeeks.DataBind();

                pnlError.Visible = false;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(
                    "Progress Error: " + ex);

                CoursePassed = false;
                CurrentCertificateId = null;
                CertificateDownloadUrl = string.Empty;
                CurrentTrainingWeek = null;
                TrainingWeeksFinished = false;
                completedTrainingWeeks.Clear();

                pnlError.Visible = true;

                litError.Text =
                    "Unable to load your progress. " +
                    "Please try again later.";

                rptWeeks.DataSource = null;
                rptWeeks.DataBind();
            }
        }

        private async Task<string> GetCurrentOpportunityIdAsync(
            string studentId)
        {
            string json =
                await FirebaseDb.Get("Applications");

            if (string.IsNullOrWhiteSpace(json))
            {
                throw new InvalidOperationException(
                    "Unable to read applications from Firebase.");
            }

            var applications =
                JsonConvert.DeserializeObject<
                    Dictionary<string, InternshipApplication>>(json)
                ?? new Dictionary<string, InternshipApplication>();

            var confirmed = applications.Values
                .Where(application =>
                    application != null &&
                    application.StudentId == studentId &&
                    application.Status ==
                        ApplicationStatus.Confirmed &&
                    !string.IsNullOrWhiteSpace(
                        application.OpportunityId))
                .ToList();

            if (confirmed.Count == 0)
                return null;

            var opportunityIds = confirmed
                .Select(application => application.OpportunityId)
                .Distinct()
                .ToList();

            if (opportunityIds.Count == 1)
                return opportunityIds[0];

            // Multiple confirmed opportunities:
            // use the most recently confirmed one.
            long latestConfirmedAt = confirmed
                .Max(application => application.ConfirmedAt);

            if (latestConfirmedAt <= 0)
            {
                throw new InvalidOperationException(
                    "The current internship could not be identified.");
            }

            var latestOpportunityIds = confirmed
                .Where(application =>
                    application.ConfirmedAt == latestConfirmedAt)
                .Select(application => application.OpportunityId)
                .Distinct()
                .ToList();

            if (latestOpportunityIds.Count != 1)
            {
                throw new InvalidOperationException(
                    "Multiple current internships were found.");
            }

            return latestOpportunityIds[0];
        }

        private async Task LoadCertificateAsync(
            string studentId,
            string opportunityId)
        {
            CoursePassed = false;
            CurrentCertificateId = null;
            CertificateDownloadUrl = string.Empty;

            if (string.IsNullOrWhiteSpace(studentId) ||
                string.IsNullOrWhiteSpace(opportunityId))
            {
                return;
            }

            string json =
                await FirebaseDb.Get("Certificate");

            if (string.IsNullOrWhiteSpace(json))
            {
                throw new InvalidOperationException(
                    "Unable to read the certificate result.");
            }

            var certificates =
                JsonConvert.DeserializeObject<
                    Dictionary<string, Certificate>>(json)
                ?? new Dictionary<string, Certificate>();

            var matchingCertificates = certificates
                .Where(item =>
                    item.Value != null &&
                    item.Value.StudentId == studentId &&
                    item.Value.OpportunityId == opportunityId)
                .Select(item =>
                {
                    item.Value.CertificateId = item.Key;
                    return item.Value;
                })
                .ToList();

            // Do not select an arbitrary result when records conflict.
            if (matchingCertificates.Count > 1)
            {
                throw new InvalidOperationException(
                    "Multiple certificate records exist " +
                    "for the same student and opportunity.");
            }

            Certificate certificate =
                matchingCertificates.SingleOrDefault();

            if (certificate == null)
                return;

            CurrentCertificateId =
                certificate.CertificateId;

            // The administrator's decision is the final pass result.
            CoursePassed = certificate.IsPassAdmin;

            if (CoursePassed)
            {
                CertificateDownloadUrl =
                    ResolveUrl("~/Student/MyProgress/Certificate.aspx");
            }
            else
            {
                CertificateDownloadUrl = "";
            }
        }
    

        private void CalculateTrainingWeek(List<WeekProgress> weeks)
        {
            completedTrainingWeeks.Clear();
            foreach (WeekProgress week in weeks)
            {
                // Use exact task counts, not the rounded percentage or elapsed time.
                if (week.TaskCount > 0 && week.SubmittedCount == week.TaskCount)
                    completedTrainingWeeks.Add(week.WeekNumber);
            }

            TrainingWeeksFinished = completedTrainingWeeks.Count == TotalWeeks;
            WeekProgress nextWeek = weeks
                .Where(week => week.TaskCount > 0 && !IsJourneyWeekComplete(week.WeekNumber))
                .OrderBy(week => week.WeekNumber)
                .FirstOrDefault();
            CurrentTrainingWeek = nextWeek == null ? (int?)null : nextWeek.WeekNumber;
        }

        protected bool IsJourneyWeekComplete(int week)
        {
            return completedTrainingWeeks.Contains(week);
        }

        protected string GetJourneyWeekClass(int week)
        {
            if (IsJourneyWeekComplete(week))
                return "mp-step mp-step-done";
            if (CurrentTrainingWeek.HasValue && week == CurrentTrainingWeek.Value)
                return "mp-step mp-step-current";
            return "mp-step";
        }

        protected string GetJourneyWeekStatus(int week)
        {
            if (IsJourneyWeekComplete(week))
                return "Completed";
            if (CurrentTrainingWeek.HasValue && week == CurrentTrainingWeek.Value)
                return "In progress";
            return "Pending";
        }

        protected string GetCertificateDownloadUrl()
        {
            if (!CoursePassed ||
                string.IsNullOrWhiteSpace(
                    CertificateDownloadUrl))
            {
                return string.Empty;
            }

            string url = CertificateDownloadUrl.Trim();

            if (url.StartsWith(
                "~/",
                StringComparison.Ordinal))
            {
                url = ResolveUrl(url);
            }

            if (!url.StartsWith(
                    "/",
                    StringComparison.Ordinal) ||
                url.StartsWith(
                    "//",
                    StringComparison.Ordinal) ||
                url.IndexOf('\\') >= 0 ||
                url.IndexOf('\r') >= 0 ||
                url.IndexOf('\n') >= 0)
            {
                return string.Empty;
            }

            return url;
        }
    }
}
