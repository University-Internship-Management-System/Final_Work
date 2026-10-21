using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;

namespace UniversityInternshipManagmentSystem.Student.StudentTasksPage
{
    public partial class WeekTasksForm : System.Web.UI.Page
    {
        // Filled by LoadWeek() on every request, then used by the button events below
        private int _week;
        private List<Tasks> _tasks = new List<Tasks>();
        private List<TaskSubmission> _subs = new List<TaskSubmission>();
        private Dictionary<string, string> _companyNames = new Dictionary<string, string>();

        protected async void Page_Load(object sender, EventArgs e)
        {
#if DEBUG
            // TEMPORARY: fake logged-in student until the auth system is ready. DELETE this block later.
            // The id matches the student in FirebaseData/seed.json
            if (Session["userId"] == null)
            {
                Session["userId"] = "student_test_001";
                Session["role"] = "Student";
                Session["name"] = "Test Student";
            }
#endif

            // Not logged in -> go away. TODO: send to the login page when it exists.
            if (Session["userId"] == null)
            {
                Response.Redirect("~/Default.aspx", false);
                return;
            }

            pnlMessage.Visible = false;     // the green message lives for one request only
            _week = GetWeekFromAddress();
            await LoadWeek();
        }

        // The week number is in the address: WeekTasksForm?week=3
        private int GetWeekFromAddress()
        {
            int week;
            if (!int.TryParse(Request.QueryString["week"], out week)) week = 1;
            if (week < 1) week = 1;
            if (week > TaskLogic.WeeksCount) week = TaskLogic.WeeksCount;
            return week;
        }

        // Loads from Firebase, fills the header and numbers, and binds the task cards.
        // It also runs on every filter / search click, because the filter boxes keep their values.
        private async Task LoadWeek()
        {
            string studentId = (string)Session["userId"];

            _tasks = await TaskDb.GetMyTasks(studentId);
            _subs = await TaskDb.GetMySubmissions(studentId);
            _companyNames = await TaskDb.GetCompanyNames(_tasks);

            // ---- header ----
            WeekSummary summary = TaskLogic.BuildWeeks(_tasks, _subs)[_week - 1];
            Page.Title = "Week " + _week + " - My Tasks";
            lblCrumb.Text = "Week " + _week;
            lblWeekTitle.Text = "Week " + _week;
            lblWeekBadge.Text = summary.StatusText;
            lblWeekBadge.CssClass = "badge " + summary.BadgeClass;
            lblWeekDates.Text = summary.DatesText;

            hlPrev.Visible = _week > 1;
            hlPrev.NavigateUrl = "WeekTasksForm?week=" + (_week - 1);
            hlPrev.Text = "← Week " + (_week - 1);
            hlNext.Visible = _week < TaskLogic.WeeksCount;
            hlNext.NavigateUrl = "WeekTasksForm?week=" + (_week + 1);
            hlNext.Text = "Week " + (_week + 1) + " →";

            // ---- the 5 number cards (for the whole week, not filtered) ----
            List<Tasks> weekTasks = _tasks.Where(t => t.WeekNumber == _week).OrderBy(t => t.DeadLine).ToList();
            StateCounts c = TaskLogic.CountStates(weekTasks, _subs);
            lblTotal.Text = c.Total.ToString();
            lblTodo.Text = (c.Todo + c.Overdue).ToString();
            lblReview.Text = c.Submitted.ToString();
            lblRevision.Text = c.Revision.ToString();
            lblEvaluated.Text = c.Evaluated.ToString();

            // ---- task cards, with the status filter and the search text ----
            string filter = ddlStatus.SelectedValue;                  // all, todo, overdue, ...
            string search = txtSearch.Text.Trim().ToLower();

            List<TaskCard> shown = new List<TaskCard>();
            foreach (TaskCard card in TaskLogic.BuildCards(weekTasks, _subs, _companyNames))
            {
                if (filter != "all" && card.StateKey != filter) continue;

                string text = (HttpUtility.HtmlDecode(card.TaskName) + " " + HttpUtility.HtmlDecode(card.TaskDescription)).ToLower();
                if (search != "" && !text.Contains(search)) continue;

                shown.Add(card);
            }

            rptTasks.DataSource = shown;
            rptTasks.DataBind();

            pnlEmpty.Visible = shown.Count == 0;
            lblEmpty.Text = weekTasks.Count == 0
                ? "Your company supervisor has not assigned any task for this week yet."
                : "No task matches your filter.";
        }

        // ---- Filter and search: Page_Load already reloaded the list with the new values ----

        protected void ddlStatus_SelectedIndexChanged(object sender, EventArgs e)
        {
        }

        protected void btnSearch_Click(object sender, EventArgs e)
        {
        }

        // ---- A card button was clicked: open the popup for that task ----

        protected void rptTasks_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "open")
                OpenDetails((string)e.CommandArgument);
        }

        private string H(string text)
        {
            return Server.HtmlEncode(text ?? "");
        }

        private void OpenDetails(string taskId)
        {
            // Only tasks that were given to this student are in _tasks
            Tasks task = _tasks.FirstOrDefault(t => t.TaskId == taskId);
            if (task == null) return;

            TaskViewState state = TaskLogic.GetState(task, _subs);
            string dueCss;
            string dueText = TaskLogic.DueText(task, state, out dueCss);

            List<TaskSubmission> history = _subs.Where(s => s.TaskId == taskId).ToList();
            TaskSubmission last = TaskLogic.LatestSubmission(taskId, _subs);

            hfTaskId.Value = taskId;

            lblDetailWeek.Text = "Week " + task.WeekNumber;
            lblDetailBadge.Text = TaskLogic.StateText(state);
            lblDetailBadge.CssClass = "badge " + TaskLogic.BadgeClass(state);
            lblDetailTitle.Text = H(task.TaskName);
            lblDetailDescription.Text = H(task.TaskDescription);
            lblDetailCompany.Text = H(_companyNames.ContainsKey(task.CompanyId ?? "") ? _companyNames[task.CompanyId] : "");
            lblDetailStart.Text = TaskLogic.Format(task.StartDate);
            lblDetailDeadline.Text = dueText.Replace("Due ", "");
            lblDetailTools.Text = string.IsNullOrEmpty(task.ToolsUsed) ? "Not specified" : H(task.ToolsUsed);
            lblDetailMax.Text = task.MaxScore.ToString();

            // supervisor feedback + score
            // (use a normal variable: reading pnl.Visible gives false while the popup itself is still hidden)
            bool hasFeedback = last != null && (!string.IsNullOrEmpty(last.Feedback) || last.Score.HasValue);
            pnlFeedback.Visible = hasFeedback;
            if (hasFeedback)
            {
                bool revision = last.Status == SubmissionState.RevisionRequested;
                pnlFeedbackBox.CssClass = revision ? "st-feedback revision" : "st-feedback";
                lblFeedbackScore.Text = last.Score.HasValue ? "Score: " + last.Score + " / " + task.MaxScore : "";
                lblFeedbackText.Text = (revision ? "<strong>Changes requested:</strong> " : "") + H(last.Feedback);
            }

            // every version I sent
            pnlHistory.Visible = history.Count > 0;
            rptHistory.DataSource = TaskLogic.BuildHistory(history);
            rptHistory.DataBind();

            // the submit form (only when the student is allowed to send work)
            bool canSubmit = TaskLogic.CanSubmit(state);
            pnlSubmit.Visible = canSubmit;
            lblLateNote.Visible = canSubmit && task.DeadLine < DateTime.Now;
            btnSubmit.Text = state == TaskViewState.Revision ? "Resubmit" : "Submit";
            txtDescription.Text = "";
            txtLink.Text = "";
            lblFormError.Text = "";

            pnlDetails.Visible = true;
        }

        protected void btnClose_Click(object sender, EventArgs e)
        {
            pnlDetails.Visible = false;
        }

        // ---- Submit / resubmit ----

        protected async void btnSubmit_Click(object sender, EventArgs e)
        {
            Tasks task = _tasks.FirstOrDefault(t => t.TaskId == hfTaskId.Value);

            // Check again on the server: it must be my task and I must be allowed to submit
            if (task == null || !TaskLogic.CanSubmit(TaskLogic.GetState(task, _subs)))
            {
                pnlDetails.Visible = false;
                return;
            }

            string description = txtDescription.Text.Trim();
            string link = txtLink.Text.Trim();

            if (description == "")
            {
                lblFormError.Text = "Please describe your work.";
                return;
            }
            if (link != "" && !TaskLogic.IsWebLink(link))
            {
                lblFormError.Text = "The link must start with http:// or https://";
                return;
            }

            // A resubmit is a NEW record with the next version number. Old versions stay.
            int version = _subs.Count(s => s.TaskId == task.TaskId) + 1;
            TaskSubmission submission = new TaskSubmission(task.TaskId, (string)Session["userId"], version, description, link, task.DeadLine);

            bool saved = await TaskDb.SaveSubmission(submission);
            if (!saved)
            {
                lblFormError.Text = "Could not save your work. Please try again.";
                return;
            }

            pnlDetails.Visible = false;
            await LoadWeek();                       // reload so the card shows the new state
            lblMessage.Text = "Work submitted successfully";
            pnlMessage.Visible = true;
        }
    }
}
