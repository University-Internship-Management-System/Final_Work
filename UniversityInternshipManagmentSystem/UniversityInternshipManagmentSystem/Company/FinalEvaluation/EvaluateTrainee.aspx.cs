using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using System.Web.UI;
using System.Web.UI.WebControls;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;
using UniversityInternshipManagmentSystem.Student.StudentTasksPage;   // TaskLogic (dates, latest submission, weeks count)

namespace UniversityInternshipManagmentSystem.Company.FinalEvaluationPage
{
    public partial class EvaluateTraineeForm : System.Web.UI.Page
    {
        // The university asks for at least 90 training hours in total (15 hours for each of the 6 weeks)
        private const int RequiredHours = 90;

        // Filled by LoadData() on every request, then used by the button events below
        private string _companyId;
        private string _studentId;
        private Models.Student _student;
        private List<Tasks> _myTasks = new List<Tasks>();              // the open tasks of THIS trainee (a closed task was cancelled)
        private List<TaskSubmission> _subs = new List<TaskSubmission>();
        private FinalEvaluation _eval;                                  // null = nothing saved yet

        protected async void Page_Load(object sender, EventArgs e)
        {
            // Not logged in, or not a company supervisor -> RequireAuth redirects
            AuthHelper.RequireAuth(this, AuthHelper.RoleCompany, AuthHelper.RoleCoordinator);
            if (Response.IsRequestBeingRedirected) return;

            pnlMessage.Visible = false;     // the message lives for one request only
            _companyId = (string)(Session["dbRecordId"] ?? Session["userId"]);   // dbRecordId = the CompanySupervisors table key set by the login

            if (!await LoadData())
            {
                // wrong address, or this student is not a trainee of my company
                Response.Redirect("FinalEvaluation.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            BindPage();
            if (!IsPostBack) FillForm();
        }

        // Loads from Firebase. Returns false when the student is not a trainee of my company.
        private async Task<bool> LoadData()
        {
            _studentId = Request.QueryString["studentId"];
            if (string.IsNullOrEmpty(_studentId)) return false;

            Dictionary<string, Models.Student> all = await TaskDb.GetStudents();
            if (!all.ContainsKey(_studentId) || all[_studentId].CompanyId != _companyId) return false;
            _student = all[_studentId];

            List<Tasks> companyTasks = await TaskDb.GetCompanyTasks(_companyId);
            _subs = await TaskDb.GetSubmissionsOfTasks(companyTasks);
            _myTasks = companyTasks.Where(t => t.Status == TaskState.Open && t.StudentIds.Contains(_studentId)).ToList();

            Dictionary<string, FinalEvaluation> evaluations = await TaskDb.GetFinalEvaluations(_companyId);
            _eval = evaluations.ContainsKey(_studentId) ? evaluations[_studentId] : null;
            return true;
        }

        private bool IsSent()
        {
            return _eval != null && _eval.Status == FinalEvaluation.Sent;
        }

        // The newest version that this trainee sent for a task (null = nothing sent yet)
        private TaskSubmission LastOf(Tasks task)
        {
            List<TaskSubmission> theirs = _subs.Where(s => s.StudentId == _studentId).ToList();
            return TaskLogic.LatestSubmission(task.TaskId, theirs);
        }

        // Numbers of one week: how many tasks, planned hours, hours done (the work was evaluated), tasks waiting for the supervisor
        private int[] WeekNumbers(int week)
        {
            int count = 0, planned = 0, done = 0, waiting = 0;
            foreach (Tasks task in _myTasks.Where(t => t.WeekNumber == week))
            {
                count++;
                planned += task.HoursFor(_studentId);

                TaskSubmission last = LastOf(task);
                if (last != null && last.Status == SubmissionState.Evaluated) done += task.HoursFor(_studentId);
                if (last != null && last.Status == SubmissionState.Submitted) waiting++;
            }
            return new[] { count, planned, done, waiting };
        }

        // ---------------------------------------------------------------------
        // Show the page
        // ---------------------------------------------------------------------

        private void BindPage()
        {
            bool sent = IsSent();

            lblCrumb.Text = Server.HtmlEncode(_student.Name);
            lblName.Text = Server.HtmlEncode(_student.Name);
            lblInfo.Text = Server.HtmlEncode(_student.Major) + " | " + Server.HtmlEncode(string.IsNullOrEmpty(_student.UniEmail) ? "-" : _student.UniEmail);
            Page.Title = "Training report - " + _student.Name;

            if (_eval == null) { lblStatus.Text = "Not started"; lblStatus.CssClass = "badge st-badge-closed"; }
            else if (sent) { lblStatus.Text = "Sent"; lblStatus.CssClass = "badge badge-approved"; }
            else { lblStatus.Text = "Draft"; lblStatus.CssClass = "badge badge-pending"; }

            pnlSentNote.Visible = sent;
            if (sent)
                lblSentNote.Text = "This evaluation was sent to the academic supervisor on " + TaskLogic.Format(_eval.SentAt ?? DateTime.Now) + ". It cannot be changed any more.";

            // ---- the 6 weeks of the weekly report ----
            DateTime trainingStart = TaskLogic.TrainingStart(_myTasks);       // week 1 starts on the earliest task start date
            int approvedWeeks = _eval == null ? 0 : _eval.ApprovedWeeks.Count;
            int approvedHours = _eval == null ? 0 : _eval.ApprovedWeeks.Values.Sum();

            var weeks = new List<object>();
            for (int week = 1; week <= TaskLogic.WeeksCount; week++)
            {
                int[] numbers = WeekNumbers(week);               // count, planned, done, waiting
                bool approved = _eval != null && _eval.ApprovedWeeks.ContainsKey("w" + week);

                string stateText, badge;
                if (approved) { stateText = "Signed (" + _eval.ApprovedWeeks["w" + week] + " h)"; badge = "badge-approved"; }
                else if (numbers[0] == 0) { stateText = "No tasks"; badge = "st-badge-closed"; }
                else if (numbers[3] > 0) { stateText = numbers[3] + " to review first"; badge = "badge-pending"; }
                else if (numbers[2] == 0) { stateText = "No hours done yet"; badge = "st-badge-closed"; }
                else { stateText = "Ready to sign"; badge = "badge-submitted"; }

                var rows = new List<object>();
                foreach (Tasks task in _myTasks.Where(t => t.WeekNumber == week).OrderBy(t => t.StartDate))
                {
                    TaskSubmission last = LastOf(task);
                    string taskState = "Not submitted", taskBadge = "st-badge-closed";
                    if (last != null && last.Status == SubmissionState.Evaluated) { taskState = "Evaluated"; taskBadge = "badge-approved"; }
                    else if (last != null && last.Status == SubmissionState.RevisionRequested) { taskState = "Changes requested"; taskBadge = "badge-pending"; }
                    else if (last != null) { taskState = "Waiting for review"; taskBadge = "badge-submitted"; }

                    rows.Add(new { Name = task.TaskName, Tools = task.ToolsUsed, Hours = task.HoursFor(_studentId), StateText = taskState, Badge = taskBadge });
                }

                weeks.Add(new
                {
                    Week = week,
                    Dates = TaskLogic.Format(trainingStart.AddDays(7 * (week - 1))) + " - " + TaskLogic.Format(trainingStart.AddDays(7 * (week - 1) + 6)),
                    StateText = stateText,
                    Badge = badge,
                    Tasks = rows,
                    TaskCount = numbers[0],
                    Planned = numbers[1],
                    Done = numbers[2],
                    CanApprove = !sent && !approved && numbers[0] > 0 && numbers[3] == 0 && numbers[2] > 0,
                    CanWithdraw = !sent && approved
                });
            }
            rptWeeks.DataSource = weeks;
            rptWeeks.DataBind();

            lblApprovedHours.Text = approvedHours + " / " + RequiredHours;
            lblApprovedWeeks.Text = approvedWeeks + " / " + TaskLogic.WeeksCount;
            lblTotalHours.Text = approvedHours.ToString();
            lblOverall.Text = _eval != null && _eval.OverallText() != "" ? _eval.OverallText() : "-";

            // after "Send" the form is read-only
            foreach (RadioButtonList box in RatingBoxes()) box.Enabled = !sent;
            txtStart.Enabled = !sent;
            txtEnd.Enabled = !sent;
            txtComments.Enabled = !sent;
            pnlButtons.Visible = !sent;
        }

        // the 6 rating boxes, in the same order as FinalEvaluation.Skills
        private RadioButtonList[] RatingBoxes()
        {
            return new[] { rblResponsibility, rblWorkingHours, rblAccuracy, rblTeamwork, rblAdaptation, rblLearningSpeed };
        }

        // Puts the saved evaluation into the form (or the starting values when nothing was saved yet)
        private void FillForm()
        {
            RadioButtonList[] boxes = RatingBoxes();
            for (int i = 0; i < boxes.Length; i++)
            {
                boxes[i].ClearSelection();
                string key = FinalEvaluation.Skills[i][0];
                if (_eval != null && _eval.Ratings.ContainsKey(key) && boxes[i].Items.FindByValue(_eval.Ratings[key]) != null)
                    boxes[i].SelectedValue = _eval.Ratings[key];
            }

            DateTime? start = _eval != null && _eval.StartDate.HasValue ? _eval.StartDate : (_myTasks.Count > 0 ? (DateTime?)_myTasks.Min(t => t.StartDate).Date : null);
            DateTime? end = _eval != null && _eval.EndDate.HasValue ? _eval.EndDate : (_myTasks.Count > 0 ? (DateTime?)_myTasks.Max(t => t.DeadLine).Date : null);
            txtStart.Text = start.HasValue ? start.Value.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) : "";
            txtEnd.Text = end.HasValue ? end.Value.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) : "";
            txtComments.Text = _eval != null ? _eval.Comments : "";
            lblFormError.Text = "";
        }

        // ---------------------------------------------------------------------
        // Sign / withdraw a week
        // ---------------------------------------------------------------------

        protected async void rptWeeks_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (IsSent()) return;                                     // a sent evaluation is final

            int week;
            if (!int.TryParse((string)e.CommandArgument, out week) || week < 1 || week > TaskLogic.WeeksCount) return;

            FinalEvaluation record = EvaluationToSave();
            int[] numbers = WeekNumbers(week);

            if (e.CommandName == "approve")
            {
                // Check again on the server: the week needs work that was done, and nothing may wait for the supervisor
                if (numbers[0] == 0 || numbers[3] > 0 || numbers[2] == 0)
                {
                    Say("Cannot sign week " + week + ": review the submissions of that week first, and the week needs hours that were done.");
                    return;
                }
                record.ApprovedWeeks["w" + week] = numbers[2];
            }
            else if (e.CommandName == "withdraw")
            {
                record.ApprovedWeeks.Remove("w" + week);
            }
            else return;

            record.TotalHours = record.ApprovedWeeks.Values.Sum();
            record.UpdatedAt = DateTime.Now;

            bool saved = await TaskDb.SaveFinalEvaluation(_studentId, record);
            await LoadData();                                         // reload so the page shows the new state
            BindPage();
            Say(saved ? (e.CommandName == "approve" ? "Week " + week + " signed" : "Signature withdrawn") : "Could not save. Please try again.");
        }

        // ---------------------------------------------------------------------
        // Save the draft / send
        // ---------------------------------------------------------------------

        protected async void btnSave_Click(object sender, EventArgs e)
        {
            if (IsSent()) return;
            await SaveForm(false);
        }

        protected async void btnSend_Click(object sender, EventArgs e)
        {
            if (IsSent()) return;
            await SaveForm(true);
        }

        private FinalEvaluation EvaluationToSave()
        {
            if (_eval != null) return _eval;

            FinalEvaluation record = new FinalEvaluation();
            record.StudentId = _studentId;
            record.CompanyId = _companyId;
            return record;
        }

        private async Task SaveForm(bool send)
        {
            // ---- read the form ----
            Dictionary<string, string> ratings = new Dictionary<string, string>();
            RadioButtonList[] boxes = RatingBoxes();
            for (int i = 0; i < boxes.Length; i++)
            {
                if (boxes[i].SelectedValue != "")
                    ratings[FinalEvaluation.Skills[i][0]] = boxes[i].SelectedValue;
            }

            DateTime start, end;
            bool startOk = DateTime.TryParseExact(txtStart.Text, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out start);
            bool endOk = DateTime.TryParseExact(txtEnd.Text, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out end);

            if (txtStart.Text != "" && !startOk) { lblFormError.Text = "The start date is not a valid date."; return; }
            if (txtEnd.Text != "" && !endOk) { lblFormError.Text = "The end date is not a valid date."; return; }
            if (startOk && endOk && end < start) { lblFormError.Text = "The end date cannot be before the start date."; return; }

            // ---- sending needs everything ----
            if (send)
            {
                if (ratings.Count < FinalEvaluation.Skills.Length) { lblFormError.Text = "Please choose a level for all 6 skills before you send."; return; }
                if (!startOk || !endOk) { lblFormError.Text = "Please choose the training start and end dates before you send."; return; }
            }

            FinalEvaluation record = EvaluationToSave();
            record.Ratings = ratings;
            record.Comments = txtComments.Text.Trim();
            record.StartDate = startOk ? (DateTime?)start : null;
            record.EndDate = endOk ? (DateTime?)end : null;
            record.TotalHours = record.ApprovedWeeks.Values.Sum();
            record.UpdatedAt = DateTime.Now;
            record.Status = send ? FinalEvaluation.Sent : FinalEvaluation.Draft;
            if (send) record.IsPassCompany = true;
            if (send) record.SentAt = DateTime.Now;

            bool saved = await TaskDb.SaveFinalEvaluation(_studentId, record);
            if (!saved)
            {
                lblFormError.Text = "Could not save. Please try again.";
                return;
            }

            await LoadData();                                         // reload so the page shows the saved state
            BindPage();
            FillForm();
            Say(send ? "Sent to the academic supervisor" : "Draft saved");
        }

        private void Say(string text)
        {
            lblMessage.Text = text;
            pnlMessage.Visible = true;
        }
    }
}
