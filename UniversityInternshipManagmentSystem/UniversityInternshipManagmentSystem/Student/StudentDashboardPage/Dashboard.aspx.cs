
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

namespace UniversityInternshipManagmentSystem.Student.StudentDashboardPage
{
    public partial class Dashboard : StudentPage
    {
        protected string ActivityError { get; private set; }
        protected bool ActivityAvailable { get; private set; }
        protected bool TasksAvailable => false;
        protected string CompanyText => string.IsNullOrWhiteSpace(Workspace?.CompanyId) ? "No company assigned" : "Assigned company · name unavailable";
        protected string HoursText => "—";
        protected int? ProgressPercent => null;

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

                foreach (var item in applications)
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

                // StudentIds is a list. The existing schema has no approved student-keyed
                // task query; do not fetch another student's tasks or turn missing data into zero.
                ActivityError = "Task/deadline summaries need an approved student-scoped query. Approved hours and published evaluations are not available from a verified source.";

                ActivityAvailable = true;
            }
            catch (Exception)
            {
                ActivityError =
                    "Activity summaries could not be loaded.";
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
