using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using System.Web.UI;
using System.Web.UI.WebControls;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;
using UniversityInternshipManagmentSystem.Student.StudentTasksPage;   // TaskLogic (date format, due text, latest submission)

namespace UniversityInternshipManagmentSystem.Company.ManageTasksPage
{
    public partial class ManageTasksForm : System.Web.UI.Page
    {
        // One trainee can have at most 15 hours of tasks in one week
        private const int MaxHoursPerWeek = 15;

        // Filled by LoadPage() on every request, then used by the button events below
        private string _companyId;
        private List<Tasks> _tasks = new List<Tasks>();
        private List<TaskSubmission> _subs = new List<TaskSubmission>();
        private Dictionary<string, Models.Student> _trainees = new Dictionary<string, Models.Student>();
        private Dictionary<string, Models.Student> _allStudents = new Dictionary<string, Models.Student>();

        protected async void Page_Load(object sender, EventArgs e)
        {
            // Not logged in, or not a company supervisor -> RequireAuth redirects
            AuthHelper.RequireAuth(this, AuthHelper.RoleCompany, AuthHelper.RoleCoordinator);
            if (Response.IsRequestBeingRedirected) return;

            pnlMessage.Visible = false;     // the green message lives for one request only
            _companyId = (string)(Session["dbRecordId"] ?? Session["userId"]);   // dbRecordId = the CompanySupervisors table key set by the login
            await LoadPage();
        }

        // Loads from Firebase, fills the numbers, and binds the task cards.
        // It also runs on every click, because the week filter keeps its value.
        private async Task LoadPage()
        {
            _tasks = await TaskDb.GetCompanyTasks(_companyId);
            _subs = await TaskDb.GetSubmissionsOfTasks(_tasks);

            // my trainees = the students whose CompanyId is my company (the coordinator sets it)
            _allStudents = await TaskDb.GetStudents();
            _trainees = _allStudents.Where(x => x.Value.CompanyId == _companyId).ToDictionary(x => x.Key, x => x.Value);

            // ---- the 3 number cards (all weeks) ----
            lblTotal.Text = _tasks.Count.ToString();
            lblOpen.Text = _tasks.Count(t => t.Status == TaskState.Open).ToString();
            lblWaiting.Text = _tasks.Sum(t => WaitingCount(t)).ToString();
            litWeekHours.Text = WeekHoursHtml(null);

            // ---- task cards, with the week filter ----
            int week = int.Parse(ddlWeekFilter.SelectedValue);          // 0 = all weeks
            List<Tasks> shown = _tasks
                .Where(t => week == 0 || t.WeekNumber == week)
                .OrderBy(t => t.WeekNumber).ThenBy(t => t.DeadLine)
                .ToList();

            rptTasks.DataSource = shown;
            rptTasks.DataBind();

            pnlEmpty.Visible = shown.Count == 0;
            lblEmpty.Text = _tasks.Count == 0
                ? "You have not created any task yet. Click \"New task\" to create the first one."
                : "No task in this week.";
        }

        // ---------------------------------------------------------------------
        // Small helpers the task cards call from the .aspx file (<%# StatusText(Container.DataItem) %>)
        // ---------------------------------------------------------------------

        // The newest version that this student sent for this task (null = nothing sent yet)
        private TaskSubmission LatestOf(Tasks task, string studentId)
        {
            List<TaskSubmission> theirs = _subs.Where(s => s.StudentId == studentId).ToList();
            return TaskLogic.LatestSubmission(task.TaskId, theirs);
        }

        // How many trainees of this task have a newest version that still waits for the supervisor
        private int WaitingCount(Tasks task)
        {
            int count = 0;
            foreach (string studentId in task.StudentIds)
            {
                TaskSubmission last = LatestOf(task, studentId);
                if (last != null && last.Status == SubmissionState.Submitted)
                    count++;
            }
            return count;
        }

        // ---------------------------------------------------------------------
        // The 15 hours per week rule
        // ---------------------------------------------------------------------

        // Hours that this trainee already has in this week. A closed (cancelled) task does not count.
        // skipTaskId = a task to leave out (used when the task itself is being reopened).
        private int HoursUsed(string studentId, int week, string skipTaskId)
        {
            int total = 0;
            foreach (Tasks t in _tasks)
            {
                if (t.WeekNumber == week && t.Status == TaskState.Open && t.TaskId != skipTaskId && t.StudentIds.Contains(studentId))
                    total += t.HoursFor(studentId);
            }
            return total;
        }

        // The first trainee who would go over 15 hours if this task is added to the week.
        // hoursOf = studentId -> the hours this task has for HIM. Returns a message, or null when everybody still fits.
        private string FirstTraineeOverLimit(Dictionary<string, int> hoursOf, int week, string skipTaskId)
        {
            foreach (var item in hoursOf)
            {
                int used = HoursUsed(item.Key, week, skipTaskId);
                if (used + item.Value > MaxHoursPerWeek)
                {
                    return "Week " + week + ": " + Server.HtmlEncode(NameOf(item.Key)) + " already has " + used + " of " + MaxHoursPerWeek +
                           " hours, and this task needs " + item.Value + " (only " + (MaxHoursPerWeek - used) + " left).";
                }
            }
            return null;
        }

        // studentId -> the hours of this existing task for him
        private Dictionary<string, int> HoursOfTask(Tasks task)
        {
            return task.StudentIds.ToDictionary(id => id, id => task.HoursFor(id));
        }

        private string NameOf(string studentId)
        {
            return _allStudents.ContainsKey(studentId) ? _allStudents[studentId].Name : studentId;
        }

        // "Week 1: 13 / 15 h" for the 6 weeks. The number is the busiest trainee of that week.
        // Only numbers and fixed words go in, so it is safe to write as HTML.
        private string WeekHoursHtml(string skipTaskId)
        {
            List<string> ids = _trainees.Keys.ToList();
            foreach (Tasks t in _tasks)
                foreach (string id in t.StudentIds)
                    if (!ids.Contains(id)) ids.Add(id);

            string html = "";
            for (int week = 1; week <= TaskLogic.WeeksCount; week++)
            {
                int busiest = 0;
                foreach (string id in ids)
                    busiest = Math.Max(busiest, HoursUsed(id, week, skipTaskId));

                string css = busiest >= MaxHoursPerWeek ? "mt-hw full" : "mt-hw";
                html += "<span class='" + css + "'>Week " + week + ": " + busiest + " / " + MaxHoursPerWeek + " h</span>";
            }
            return html;
        }

        protected string HoursText(object item)
        {
            return ((Tasks)item).HoursText();
        }

        protected string StatusText(object item)
        {
            return ((Tasks)item).Status == TaskState.Open ? "Open" : "Closed";
        }

        protected string StatusBadge(object item)
        {
            return ((Tasks)item).Status == TaskState.Open ? "badge-submitted" : "st-badge-closed";
        }

        protected string DueText(object item)
        {
            string css;
            return TaskLogic.DueText((Tasks)item, TaskViewState.Todo, out css);
        }

        protected string DueCss(object item)
        {
            string css;
            TaskLogic.DueText((Tasks)item, TaskViewState.Todo, out css);
            return css;
        }

        protected string TraineeText(object item)
        {
            int count = ((Tasks)item).StudentIds.Count;
            return count + (count == 1 ? " trainee" : " trainees");
        }

        protected string ReviewText(object item)
        {
            int waiting = WaitingCount((Tasks)item);
            return waiting == 0 ? "Nothing to review" : waiting + " waiting for review";
        }

        protected string ReviewBadge(object item)
        {
            return WaitingCount((Tasks)item) == 0 ? "st-badge-closed" : "badge-pending";
        }

        protected string ToggleText(object item)
        {
            return ((Tasks)item).Status == TaskState.Open ? "Close task" : "Reopen task";
        }

        // ---- Week filter: Page_Load already reloaded the list with the new value ----

        protected void ddlWeekFilter_SelectedIndexChanged(object sender, EventArgs e)
        {
        }

        // ---- Open / close a task ----

        protected async void rptTasks_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            // Only tasks of my company are in _tasks
            Tasks task = _tasks.FirstOrDefault(t => t.TaskId == (string)e.CommandArgument);
            if (task == null) return;

            if (e.CommandName == "edit")
            {
                OpenEdit(task);
                return;
            }
            if (e.CommandName != "toggle") return;

            TaskState newStatus = task.Status == TaskState.Open ? TaskState.Closed : TaskState.Open;

            // Reopening puts the hours back into the week, so every trainee must still fit in 15 hours
            if (newStatus == TaskState.Open)
            {
                string tooMany = FirstTraineeOverLimit(HoursOfTask(task), task.WeekNumber, task.TaskId);
                if (tooMany != null)
                {
                    lblMessage.Text = "Cannot reopen the task. " + tooMany;
                    pnlMessage.Visible = true;
                    return;
                }
            }

            bool saved = await TaskDb.SetTaskStatus(task.TaskId, newStatus);
            if (saved)
            {
                foreach (string id in task.StudentIds)
                    if (_allStudents.ContainsKey(id))
                        Notify.TaskNews(_allStudents[id].Name, _allStudents[id].Email, task.TaskName, newStatus == TaskState.Closed ? "was closed" : "was opened again");
            }

            await LoadPage();               // reload so the card shows the new status
            lblMessage.Text = saved
                ? (newStatus == TaskState.Closed ? "Task closed" : "Task reopened")
                : "Could not change the task. Please try again.";
            pnlMessage.Visible = true;
        }

        // ---- New task popup ----

        protected void btnNew_Click(object sender, EventArgs e)
        {
            hfEditId.Value = "";                      // empty = a new task
            lblPopupTitle.Text = "New task";
            btnSave.Text = "Create task";
            txtName.Text = "";
            txtDescription.Text = "";
            ddlWeek.SelectedValue = "1";
            txtMax.Text = "10";
            txtHours.Text = "1";
            litPopupHours.Text = WeekHoursHtml(null);
            txtStart.Text = DateTime.Today.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            txtDeadline.Text = DateTime.Today.AddDays(7).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            txtTools.Text = "";
            lblFormError.Text = "";

            // one row per trainee of my company: all ticked, hours boxes empty (= the default hours)
            BindTrainees(_trainees.Keys.ToList(), null);

            pnlNew.Visible = true;
        }

        // Fills the trainee list of the popup: one row per trainee = a check box + an optional hours box.
        // task = null for a new task (all ticked, boxes empty).
        private void BindTrainees(List<string> ids, Tasks task)
        {
            var rows = ids.OrderBy(id => NameOf(id)).Select(id => new
            {
                Id = id,
                Name = NameOf(id),
                Ticked = task == null || task.StudentIds.Contains(id),
                Hours = (task != null && task.StudentHours != null && task.StudentHours.ContainsKey(id)) ? task.StudentHours[id].ToString() : ""
            }).ToList();

            rptTrainees.DataSource = rows;
            rptTrainees.DataBind();
            lblNoTrainees.Visible = rows.Count == 0;
        }

        // ---- Edit popup: the same popup as "New task", filled with the task ----

        private void OpenEdit(Tasks task)
        {
            hfEditId.Value = task.TaskId;             // not empty = we are editing this task
            lblPopupTitle.Text = "Edit task";
            btnSave.Text = "Save changes";
            txtName.Text = task.TaskName;
            txtDescription.Text = task.TaskDescription;
            ddlWeek.SelectedValue = task.WeekNumber.ToString();
            txtMax.Text = task.MaxScore.ToString(CultureInfo.InvariantCulture);
            txtHours.Text = (task.Hours < 1 ? 1 : task.Hours).ToString();      // old tasks have no hours yet
            litPopupHours.Text = WeekHoursHtml(task.TaskId);                  // the hours of the OTHER tasks of each week
            txtStart.Text = task.StartDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            txtDeadline.Text = task.DeadLine.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            txtTools.Text = task.ToolsUsed ?? "";
            lblFormError.Text = "";

            // my trainees, plus anybody who already has this task (so nobody is dropped by accident)
            List<string> ids = _trainees.Keys.ToList();
            foreach (string id in task.StudentIds)
                if (!ids.Contains(id)) ids.Add(id);

            BindTrainees(ids, task);

            pnlNew.Visible = true;
        }

        protected void btnClose_Click(object sender, EventArgs e)
        {
            pnlNew.Visible = false;
        }

        protected async void btnSave_Click(object sender, EventArgs e)
        {
            string name = txtName.Text.Trim();
            string description = txtDescription.Text.Trim();
            string tools = txtTools.Text.Trim();

            if (name == "") { lblFormError.Text = "Please write the task name."; return; }
            if (description == "") { lblFormError.Text = "Please write the description."; return; }

            // the date boxes give "2026-10-24"
            DateTime start, deadlineDay;
            if (!DateTime.TryParseExact(txtStart.Text, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out start)) { lblFormError.Text = "Please choose the start date."; return; }
            if (!DateTime.TryParseExact(txtDeadline.Text, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out deadlineDay)) { lblFormError.Text = "Please choose the deadline."; return; }
            if (deadlineDay < start) { lblFormError.Text = "The deadline cannot be before the start date."; return; }
            DateTime deadline = deadlineDay.AddHours(23).AddMinutes(59);        // the whole last day counts

            double maxScore;
            if (!double.TryParse(txtMax.Text, NumberStyles.Float, CultureInfo.InvariantCulture, out maxScore) || maxScore < 1 || maxScore > 100)
            {
                lblFormError.Text = "The max score must be a number from 1 to 100.";
                return;
            }

            int hours;
            if (!int.TryParse(txtHours.Text, NumberStyles.Integer, CultureInfo.InvariantCulture, out hours) || hours < 1 || hours > MaxHoursPerWeek)
            {
                lblFormError.Text = "The hours must be a whole number from 1 to " + MaxHoursPerWeek + ".";
                return;
            }

            // Editing? Only a task of MY company can be edited (the id comes from the hidden box, so check it again)
            string editId = hfEditId.Value;
            Tasks editing = null;
            if (editId != "")
            {
                editing = _tasks.FirstOrDefault(t => t.TaskId == editId);
                if (editing == null) { lblFormError.Text = "This task was not found. Close the window and try again."; return; }
            }

            // Check again on the server: only trainees of MY company can get the task
            // (when editing, the trainees who already have the task stay allowed)
            List<string> studentIds = new List<string>();
            Dictionary<string, int> studentHours = new Dictionary<string, int>();     // only the trainees whose hours differ from the default
            foreach (RepeaterItem row in rptTrainees.Items)
            {
                string id = ((HiddenField)row.FindControl("hfTraineeId")).Value;
                bool ticked = ((CheckBox)row.FindControl("chkTrainee")).Checked;
                bool allowed = _trainees.ContainsKey(id) || (editing != null && editing.StudentIds.Contains(id));
                if (!ticked || !allowed) continue;

                studentIds.Add(id);

                string own = ((TextBox)row.FindControl("txtTraineeHours")).Text.Trim();
                if (own == "") continue;                                  // an empty box = the default hours
                int ownHours;
                if (!int.TryParse(own, NumberStyles.Integer, CultureInfo.InvariantCulture, out ownHours) || ownHours < 1 || ownHours > MaxHoursPerWeek)
                {
                    lblFormError.Text = "The hours of " + Server.HtmlEncode(NameOf(id)) + " must be a whole number from 1 to " + MaxHoursPerWeek + ".";
                    return;
                }
                if (ownHours != hours) studentHours[id] = ownHours;        // the same number as the default is not an exception
            }
            if (studentIds.Count == 0) { lblFormError.Text = "Choose at least one trainee."; return; }

            // Work that was already sent must not be lost by the change
            if (editing != null)
            {
                foreach (string oldId in editing.StudentIds)
                {
                    if (!studentIds.Contains(oldId) && _subs.Any(s => s.TaskId == editId && s.StudentId == oldId))
                    {
                        string who = _allStudents.ContainsKey(oldId) ? _allStudents[oldId].Name : oldId;
                        lblFormError.Text = Server.HtmlEncode(who) + " already sent work for this task, so you cannot remove this trainee.";
                        return;
                    }
                }
                double highestScore = _subs.Where(s => s.TaskId == editId && s.Score.HasValue).Select(s => s.Score.Value).DefaultIfEmpty(0).Max();
                if (maxScore < highestScore)
                {
                    lblFormError.Text = "A score of " + highestScore + " was already given, so the max score cannot be lower than that.";
                    return;
                }
            }

            // The 15 hours rule: every chosen trainee must still fit in this week.
            // The task itself is left out of the count (editId), and a closed task does not count at all.
            int week = int.Parse(ddlWeek.SelectedValue);
            Dictionary<string, int> hoursOf = studentIds.ToDictionary(id => id, id => studentHours.ContainsKey(id) ? studentHours[id] : hours);
            if (editing == null || editing.Status == TaskState.Open)
            {
                string tooMany = FirstTraineeOverLimit(hoursOf, week, editId);
                if (tooMany != null) { lblFormError.Text = tooMany; return; }
            }

            // Who gets the "new task" email: everybody on a new task, only the added trainees when editing
            List<string> newcomers = editing == null ? studentIds : studentIds.Where(id => !editing.StudentIds.Contains(id)).ToList();

            bool saved;
            if (editing == null)
            {
                Tasks task = new Tasks("", name, description, TaskState.Open, start, deadline, studentIds,
                                       _companyId, week, tools, maxScore, hours);
                task.StudentHours = studentHours;
                saved = await TaskDb.SaveTask(task);
            }
            else
            {
                editing.TaskName = name;
                editing.TaskDescription = description;
                editing.WeekNumber = week;
                editing.StartDate = start;
                editing.DeadLine = deadline;
                editing.StudentIds = studentIds;
                editing.ToolsUsed = tools;
                editing.MaxScore = maxScore;
                editing.Hours = hours;
                editing.StudentHours = studentHours;       // a removed trainee loses his own hours here too
                saved = await TaskDb.UpdateTask(editing);
            }
            if (!saved)
            {
                lblFormError.Text = "Could not save the task. Please try again.";
                return;
            }

            foreach (string id in newcomers)
            {
                if (!_allStudents.ContainsKey(id)) continue;
                Notify.TaskAssigned(_allStudents[id].Name, _allStudents[id].Email, name, week, deadline);
            }
            if (editing != null)
            {
                // The trainees who already had the task hear that it changed
                foreach (string id in studentIds.Except(newcomers))
                    if (_allStudents.ContainsKey(id)) Notify.TaskNews(_allStudents[id].Name, _allStudents[id].Email, name, "was updated");
            }

            pnlNew.Visible = false;
            await LoadPage();               // reload so the card shows the saved task
            lblMessage.Text = editing == null ? "Task created" : "Task updated";
            pnlMessage.Visible = true;
        }
    }
}
