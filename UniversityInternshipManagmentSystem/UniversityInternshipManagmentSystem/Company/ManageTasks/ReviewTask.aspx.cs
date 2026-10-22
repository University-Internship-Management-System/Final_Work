using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;
using UniversityInternshipManagmentSystem.Student.StudentTasksPage;   // TaskLogic (date format, due text, links, history)

namespace UniversityInternshipManagmentSystem.Company.ManageTasksPage
{
    public partial class ReviewTaskForm : System.Web.UI.Page
    {
        // Filled by LoadTask() on every request, then used by the button events below
        private string _companyId;
        private Tasks _task;
        private List<TaskSubmission> _subs = new List<TaskSubmission>();
        private Dictionary<string, Models.Student> _students = new Dictionary<string, Models.Student>();

        protected async void Page_Load(object sender, EventArgs e)
        {
            // Not logged in, or not a company supervisor -> RequireAuth redirects
            AuthHelper.RequireAuth(this, AuthHelper.RoleCompany, AuthHelper.RoleCoordinator);
            if (Response.IsRequestBeingRedirected) return;

            pnlMessage.Visible = false;     // the green message lives for one request only
            _companyId = (string)(Session["dbRecordId"] ?? Session["userId"]);   // dbRecordId = the CompanySupervisors table key set by the login

            bool found = await LoadTask();
            if (!found)
            {
                // wrong address, or this task belongs to another company
                Response.Redirect("ManageTasks.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
            }
        }

        // Loads from Firebase, fills the header and numbers, and binds the table.
        // Returns false when the task does not exist or is not mine.
        private async Task<bool> LoadTask()
        {
            string taskId = Request.QueryString["taskId"];

            // Only tasks of my company are in this list, so I can never open the task of another company
            List<Tasks> mine = await TaskDb.GetCompanyTasks(_companyId);
            _task = mine.FirstOrDefault(t => t.TaskId == taskId);
            if (_task == null) return false;

            _subs = await TaskDb.GetSubmissionsOfTasks(new List<Tasks> { _task });
            _students = await TaskDb.GetStudents();

            // ---- header ----
            bool isOpen = _task.Status == TaskState.Open;
            Page.Title = "Review - " + _task.TaskName;
            lblCrumb.Text = Server.HtmlEncode(_task.TaskName);
            lblTitle.Text = Server.HtmlEncode(_task.TaskName);
            lblStatusBadge.Text = isOpen ? "Open" : "Closed";
            lblStatusBadge.CssClass = "badge " + (isOpen ? "badge-submitted" : "st-badge-closed");
            lblDescription.Text = Server.HtmlEncode(_task.TaskDescription);

            string dueCss;
            string dueText = TaskLogic.DueText(_task, TaskViewState.Todo, out dueCss);
            lblInfo.Text = "Week " + _task.WeekNumber + " | " + dueText + " | Max score " + _task.MaxScore
                           + (_task.HoursText() != "No hours set" ? " | " + _task.HoursText() : "");

            // ---- the 5 numbers: one pass over the trainees ----
            int notSent = 0, waiting = 0, revision = 0, evaluated = 0;
            foreach (string studentId in _task.StudentIds)
            {
                TaskSubmission last = LastOf(studentId);
                if (last == null) notSent++;
                else if (last.Status == SubmissionState.Submitted) waiting++;
                else if (last.Status == SubmissionState.RevisionRequested) revision++;
                else evaluated++;
            }
            lblAssigned.Text = _task.StudentIds.Count.ToString();
            lblNotSent.Text = notSent.ToString();
            lblWaiting.Text = waiting.ToString();
            lblRevision.Text = revision.ToString();
            lblEvaluated.Text = evaluated.ToString();

            // ---- table: one line per trainee of the task (the Repeater gets the student ids) ----
            rptRows.DataSource = _task.StudentIds;
            rptRows.DataBind();
            rptRows.Visible = _task.StudentIds.Count > 0;
            pnlEmpty.Visible = _task.StudentIds.Count == 0;

            return true;
        }

        private string H(string text)
        {
            return Server.HtmlEncode(text ?? "");
        }

        // ---------------------------------------------------------------------
        // Small helpers the table calls from the .aspx file (<%# StateText(Container.DataItem) %>)
        // Container.DataItem is the student id.
        // ---------------------------------------------------------------------

        // The newest version that this student sent for this task (null = nothing sent yet)
        private TaskSubmission LastOf(string studentId)
        {
            List<TaskSubmission> theirs = _subs.Where(s => s.StudentId == studentId).ToList();
            return TaskLogic.LatestSubmission(_task.TaskId, theirs);
        }

        protected string StudentName(object item)
        {
            string id = (string)item;
            return _students.ContainsKey(id) ? _students[id].Name : id;
        }

        // The hours this task has for this trainee (his own number, or the default)
        protected string HoursOf(object item)
        {
            int hours = _task.HoursFor((string)item);
            return hours == 0 ? "-" : hours + " h";
        }

        protected string StateText(object item)
        {
            TaskSubmission last = LastOf((string)item);
            if (last == null) return "Not submitted";
            if (last.Status == SubmissionState.Evaluated) return "Evaluated";
            if (last.Status == SubmissionState.RevisionRequested) return "Changes requested";
            return "Waiting for review";
        }

        protected string StateBadge(object item)
        {
            TaskSubmission last = LastOf((string)item);
            if (last == null) return "st-badge-closed";
            if (last.Status == SubmissionState.Evaluated) return "badge-approved";
            if (last.Status == SubmissionState.RevisionRequested) return "badge-pending";
            return "badge-submitted";
        }

        protected string SentText(object item)
        {
            TaskSubmission last = LastOf((string)item);
            if (last == null) return "Nothing sent yet";
            return "Version " + last.Version + " - " + TaskLogic.Format(last.SubmittedAt) + (last.IsLate ? " (late)" : "");
        }

        protected bool HasSubmission(object item)
        {
            return LastOf((string)item) != null;
        }

        // The newest version is waiting for the supervisor
        protected bool CanReview(object item)
        {
            TaskSubmission last = LastOf((string)item);
            return last != null && last.Status == SubmissionState.Submitted;
        }

        protected string SubmissionIdOf(object item)
        {
            TaskSubmission last = LastOf((string)item);
            return last == null ? "" : last.Id;
        }

        // ---- A "Review" / "View" button was clicked: open the popup for that submission ----

        protected void rptRows_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "open")
                OpenReview((string)e.CommandArgument);
        }

        private void OpenReview(string submissionId)
        {
            // Only submissions of THIS task are in _subs
            TaskSubmission sub = _subs.FirstOrDefault(s => s.Id == submissionId);
            if (sub == null) return;

            Models.Student student = _students.ContainsKey(sub.StudentId) ? _students[sub.StudentId] : null;
            List<TaskSubmission> history = _subs.Where(s => s.StudentId == sub.StudentId).ToList();

            hfSubmissionId.Value = submissionId;

            lblStudent.Text = H(student != null ? student.Name : sub.StudentId);
            lblVersion.Text = sub.Version.ToString();
            lblSent.Text = TaskLogic.Format(sub.SubmittedAt);
            lblLate.Visible = sub.IsLate;
            lblMax.Text = _task.MaxScore.ToString();
            lblWork.Text = H(sub.Description);

            bool hasLink = !string.IsNullOrEmpty(sub.Link) && TaskLogic.IsWebLink(sub.Link);
            hlLink.Visible = hasLink;
            hlLink.NavigateUrl = hasLink ? sub.Link : "";
            hlLink.Text = H(sub.Link);

            pnlHistory.Visible = history.Count > 1;
            rptHistory.DataSource = TaskLogic.BuildHistory(history);
            rptHistory.DataBind();

            // the decision part: the form (waiting), or the decision that was already made
            // (use normal variables: reading pnl.Visible gives false while the popup itself is still hidden)
            bool isNewest = sub.Version == history.Max(s => s.Version);
            bool canReview = sub.Status == SubmissionState.Submitted && isNewest;

            if (sub.Status == SubmissionState.Evaluated) { lblRevBadge.Text = "Evaluated"; lblRevBadge.CssClass = "badge badge-approved"; }
            else if (sub.Status == SubmissionState.RevisionRequested) { lblRevBadge.Text = "Changes requested"; lblRevBadge.CssClass = "badge badge-pending"; }
            else { lblRevBadge.Text = "Waiting for review"; lblRevBadge.CssClass = "badge badge-submitted"; }

            pnlForm.Visible = canReview;
            lblMaxHint.Text = _task.MaxScore.ToString();
            txtScore.Text = "";
            txtFeedback.Text = "";
            lblFormError.Text = "";

            bool hasResult = sub.Status != SubmissionState.Submitted;
            pnlResult.Visible = hasResult;
            if (hasResult)
            {
                bool revision = sub.Status == SubmissionState.RevisionRequested;
                pnlResultBox.CssClass = revision ? "st-feedback revision" : "st-feedback";
                lblResultScore.Text = sub.Score.HasValue ? "Score: " + sub.Score + " / " + _task.MaxScore : "";
                lblResultFeedback.Text = (revision ? "<strong>Changes requested:</strong> " : "") + H(sub.Feedback);
            }

            pnlReview.Visible = true;
        }

        protected void btnClose_Click(object sender, EventArgs e)
        {
            pnlReview.Visible = false;
        }

        // ---- Save the score ----

        protected async void btnApprove_Click(object sender, EventArgs e)
        {
            TaskSubmission sub = GetSubmissionToReview();
            if (sub == null) return;

            double score;
            if (!double.TryParse(txtScore.Text, NumberStyles.Float, CultureInfo.InvariantCulture, out score) || score < 0 || score > _task.MaxScore)
            {
                lblFormError.Text = "The score must be a number from 0 to " + _task.MaxScore + ".";
                return;
            }

            await Save(sub, SubmissionState.Evaluated, score, txtFeedback.Text.Trim(), "Score saved");
        }

        // ---- Ask the trainee to change something ----

        protected async void btnRevise_Click(object sender, EventArgs e)
        {
            TaskSubmission sub = GetSubmissionToReview();
            if (sub == null) return;

            string feedback = txtFeedback.Text.Trim();
            if (feedback == "")
            {
                lblFormError.Text = "Please write what the trainee must change.";
                return;
            }

            await Save(sub, SubmissionState.RevisionRequested, null, feedback, "The trainee was asked to change the work");
        }

        // Check again on the server: it must be a submission of this task, the newest one, and still waiting
        private TaskSubmission GetSubmissionToReview()
        {
            TaskSubmission sub = _subs.FirstOrDefault(s => s.Id == hfSubmissionId.Value);
            if (sub == null || sub.Status != SubmissionState.Submitted || sub.Version != LastOf(sub.StudentId).Version)
            {
                pnlReview.Visible = false;
                return null;
            }
            return sub;
        }

        private async Task Save(TaskSubmission sub, SubmissionState status, double? score, string feedback, string doneText)
        {
            bool saved = await TaskDb.SaveEvaluation(sub.Id, status, score, feedback);
            if (!saved)
            {
                lblFormError.Text = "Could not save. Please try again.";
                return;
            }

            pnlReview.Visible = false;
            await LoadTask();               // reload so the table and the numbers show the new state
            lblMessage.Text = doneText;
            pnlMessage.Visible = true;
        }
    }
}
