using System;
using System.Globalization;
using System.Threading.Tasks;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Student.Data;

namespace UniversityInternshipManagmentSystem.Student.StudentDashboardPage
{
    public partial class Dashboard : StudentPage
    {
        protected StudentOverview Overview { get; private set; } = new StudentOverview();
        protected string ActivityError { get; private set; }
        protected bool ActivityAvailable { get; private set; }
        protected string HoursText => Overview.ApprovedHours.HasValue ? Overview.ApprovedHours.Value.ToString("0.##") : "—";
        protected string CompanyText => Workspace.Profile.CompanyName ?? (string.IsNullOrEmpty(Workspace.Profile.Student.CompanyId) ? "No company assigned" : "Assigned company · name unavailable");
        protected int? ProgressPercent => Overview.ProgressPercent;

        protected void Page_Load(object sender, EventArgs e)
        {

            RegisterAsyncTask(new PageAsyncTask(LoadDashboardAsync));
        }

        private async Task LoadDashboardAsync()
        {
            await LoadWorkspaceAsync();
            if (Workspace == null) return;
            try
            {
                Overview = await StudentModule.GetOverviewAsync(Workspace);
                ActivityAvailable = StudentModule.ActivityProvider != null;
            }
            catch (Exception) { ActivityAvailable = false; ActivityError = "Activity summaries could not be loaded. Please try again later."; }
            ApplicationsList.DataSource = Overview.Applications;
            TasksList.DataSource = Overview.Tasks;
            DeadlinesList.DataSource = Overview.Deadlines;
            EvaluationsList.DataSource = Overview.Evaluations;
            ApplicationsList.DataBind();
            TasksList.DataBind();
            DeadlinesList.DataBind();
            EvaluationsList.DataBind();
        }

        protected string ActivityCount(int count) => ActivityAvailable ? count.ToString(CultureInfo.InvariantCulture) : "—";
        protected string RecordCount(int count) => ActivityAvailable ? count.ToString(CultureInfo.InvariantCulture) + " records" : "Not connected";

        protected string FormatDeadline(object value)
        {
            return value is DateTimeOffset ? ((DateTimeOffset)value).ToUniversalTime().ToString("dd MMM yyyy HH:mm 'UTC'", CultureInfo.InvariantCulture) : "Not provided";
        }
    }
}
