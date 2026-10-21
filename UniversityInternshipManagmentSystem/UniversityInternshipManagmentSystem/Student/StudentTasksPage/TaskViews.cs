using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Web;
using UniversityInternshipManagmentSystem.Models;

namespace UniversityInternshipManagmentSystem.Student.StudentTasksPage
{
    // ---------------------------------------------------------------------
    // Small objects that the Repeaters on the two pages show.
    // The property names must match the Eval("...") names in the .aspx files.
    // ---------------------------------------------------------------------

    // One card on the "My Tasks" page
    public class WeekSummary
    {
        public int WeekNumber { get; set; }
        public string DatesText { get; set; }
        public string StatusText { get; set; }
        public string BadgeClass { get; set; }
        public int TaskCount { get; set; }
        public int PercentDone { get; set; }
        public string FootText { get; set; }
        public bool IsCurrent { get; set; }
        public int ToDoCount { get; set; }
        public int OverdueCount { get; set; }
        public int ReviseCount { get; set; }
        public int InReviewCount { get; set; }
    }

    // One task card on the week page
    public class TaskCard
    {
        public string TaskId { get; set; }
        public int WeekNumber { get; set; }
        public string TaskName { get; set; }
        public string TaskDescription { get; set; }
        public string StateKey { get; set; }        // todo, overdue, submitted, revision, evaluated, closed (used by the filter)
        public string StateText { get; set; }
        public string BadgeClass { get; set; }
        public string DueText { get; set; }
        public string DueCssClass { get; set; }
        public string CompanyName { get; set; }
        public string ButtonText { get; set; }
        public bool CanSubmit { get; set; }
    }

    // One line of "My submissions" in the popup
    public class SubmissionRow
    {
        public int Version { get; set; }
        public string DateText { get; set; }
        public bool IsLate { get; set; }
        public string Description { get; set; }
        public string Link { get; set; }
    }

    // How many tasks are in each state
    public class StateCounts
    {
        public int Total { get; set; }
        public int Todo { get; set; }
        public int Overdue { get; set; }
        public int Submitted { get; set; }
        public int Revision { get; set; }
        public int Evaluated { get; set; }
    }

    // What the STUDENT sees for a task (not the same as Tasks.Status, which is only Open / Closed)
    public enum TaskViewState { Todo, Overdue, Submitted, Revision, Evaluated, Closed }

    // ---------------------------------------------------------------------
    // The rules of the page, in one place.
    // ---------------------------------------------------------------------
    public static class TaskLogic
    {
        public const int WeeksCount = 6;    // University of Jordan: 6 training weeks

        // The newest version of my work for a task (null = nothing submitted yet)
        public static TaskSubmission LatestSubmission(string taskId, List<TaskSubmission> subs)
        {
            TaskSubmission latest = null;
            foreach (TaskSubmission s in subs)
            {
                if (s.TaskId == taskId && (latest == null || s.Version > latest.Version))
                    latest = s;
            }
            return latest;
        }

        // The state comes from the latest submission. If there is none: closed, overdue or to do.
        public static TaskViewState GetState(Tasks task, List<TaskSubmission> subs)
        {
            TaskSubmission last = LatestSubmission(task.TaskId, subs);
            if (last != null)
            {
                if (last.Status == SubmissionState.Evaluated) return TaskViewState.Evaluated;
                if (last.Status == SubmissionState.RevisionRequested) return TaskViewState.Revision;
                return TaskViewState.Submitted;
            }

            if (task.Status == TaskState.Closed) return TaskViewState.Closed;
            if (task.DeadLine < DateTime.Now) return TaskViewState.Overdue;
            return TaskViewState.Todo;
        }

        // The student may send work only when it is not waiting for review or already graded
        public static bool CanSubmit(TaskViewState state)
        {
            return state == TaskViewState.Todo || state == TaskViewState.Overdue || state == TaskViewState.Revision;
        }

        public static string StateKey(TaskViewState state)
        {
            return state.ToString().ToLower();
        }

        public static string StateText(TaskViewState state)
        {
            switch (state)
            {
                case TaskViewState.Todo: return "To do";
                case TaskViewState.Overdue: return "Overdue";
                case TaskViewState.Submitted: return "Submitted";
                case TaskViewState.Revision: return "Needs revision";
                case TaskViewState.Evaluated: return "Evaluated";
                default: return "Closed";
            }
        }

        // css class from Shared/uims.css
        public static string BadgeClass(TaskViewState state)
        {
            switch (state)
            {
                case TaskViewState.Todo: return "badge-pending";
                case TaskViewState.Overdue: return "badge-rejected";
                case TaskViewState.Submitted: return "badge-submitted";
                case TaskViewState.Revision: return "badge-pending";
                case TaskViewState.Evaluated: return "badge-approved";
                default: return "st-badge-closed";
            }
        }

        public static string Format(DateTime date)
        {
            return date.ToString("dd MMM yyyy", CultureInfo.InvariantCulture);
        }

        // "Due 15 Oct 2026 (3 days left)"  and the css class that colors it
        public static string DueText(Tasks task, TaskViewState state, out string cssClass)
        {
            cssClass = "";
            string date = Format(task.DeadLine);

            if (state == TaskViewState.Submitted || state == TaskViewState.Evaluated)
                return "Due " + date;

            int days = (int)Math.Ceiling((task.DeadLine - DateTime.Now).TotalDays);
            if (days < 0)
            {
                cssClass = "st-due-late";
                int late = -days;
                return "Due " + date + " (" + late + (late == 1 ? " day" : " days") + " late)";
            }
            if (days <= 3)
            {
                cssClass = "st-due-soon";
                return "Due " + date + " (" + (days == 0 ? "today" : days + (days == 1 ? " day left" : " days left")) + ")";
            }
            return "Due " + date;
        }

        public static StateCounts CountStates(List<Tasks> tasks, List<TaskSubmission> subs)
        {
            StateCounts c = new StateCounts();
            foreach (Tasks task in tasks)
            {
                c.Total++;
                switch (GetState(task, subs))
                {
                    case TaskViewState.Todo: c.Todo++; break;
                    case TaskViewState.Overdue: c.Overdue++; break;
                    case TaskViewState.Submitted: c.Submitted++; break;
                    case TaskViewState.Revision: c.Revision++; break;
                    case TaskViewState.Evaluated: c.Evaluated++; break;
                }
            }
            return c;
        }

        // Week 1 starts on the earliest task start date.
        // TODO: later use the real start date of the student's placement.
        public static DateTime TrainingStart(List<Tasks> tasks)
        {
            if (tasks.Count == 0) return DateTime.Today;
            return tasks.Min(t => t.StartDate).Date;
        }

        // The 6 cards of the "My Tasks" page
        public static List<WeekSummary> BuildWeeks(List<Tasks> tasks, List<TaskSubmission> subs)
        {
            List<WeekSummary> weeks = new List<WeekSummary>();
            DateTime trainingStart = TrainingStart(tasks);

            for (int week = 1; week <= WeeksCount; week++)
            {
                List<Tasks> weekTasks = tasks.Where(t => t.WeekNumber == week).ToList();
                StateCounts c = CountStates(weekTasks, subs);

                DateTime start = trainingStart.AddDays(7 * (week - 1));
                DateTime end = start.AddDays(6);
                bool isCurrent = DateTime.Today >= start && DateTime.Today <= end;

                WeekSummary w = new WeekSummary();
                w.WeekNumber = week;
                w.DatesText = start.ToString("dd MMM", CultureInfo.InvariantCulture) + " - " + end.ToString("dd MMM", CultureInfo.InvariantCulture);
                w.TaskCount = c.Total;
                w.PercentDone = c.Total == 0 ? 0 : c.Evaluated * 100 / c.Total;
                w.FootText = c.Total == 0 ? "Nothing assigned yet" : c.Evaluated + " of " + c.Total + " evaluated";
                w.IsCurrent = isCurrent;
                w.ToDoCount = c.Todo;
                w.OverdueCount = c.Overdue;
                w.ReviseCount = c.Revision;
                w.InReviewCount = c.Submitted;

                if (c.Total == 0) { w.StatusText = "No tasks"; w.BadgeClass = "st-badge-closed"; }
                else if (c.Evaluated == c.Total) { w.StatusText = "Completed"; w.BadgeClass = "badge-approved"; }
                else if (c.Overdue > 0 || c.Revision > 0) { w.StatusText = "Needs attention"; w.BadgeClass = "badge-rejected"; }
                else if (isCurrent) { w.StatusText = "Current week"; w.BadgeClass = "badge-submitted"; }
                else if (start > DateTime.Today) { w.StatusText = "Upcoming"; w.BadgeClass = "st-badge-closed"; }
                else { w.StatusText = "Waiting for review"; w.BadgeClass = "badge-submitted"; }

                weeks.Add(w);
            }
            return weeks;
        }

        // The task cards of one week. Text that came from the database is HTML-encoded because the
        // Repeater writes it into the page as it is.
        public static List<TaskCard> BuildCards(List<Tasks> weekTasks, List<TaskSubmission> subs, Dictionary<string, string> companyNames)
        {
            List<TaskCard> cards = new List<TaskCard>();
            foreach (Tasks task in weekTasks)
            {
                TaskViewState state = GetState(task, subs);
                string cssClass;
                string dueText = DueText(task, state, out cssClass);

                TaskCard card = new TaskCard();
                card.TaskId = task.TaskId;
                card.WeekNumber = task.WeekNumber;
                card.TaskName = HttpUtility.HtmlEncode(task.TaskName);
                card.TaskDescription = HttpUtility.HtmlEncode(task.TaskDescription);
                card.StateKey = StateKey(state);
                card.StateText = StateText(state);
                card.BadgeClass = BadgeClass(state);
                card.DueText = dueText;
                card.DueCssClass = cssClass;
                card.CompanyName = HttpUtility.HtmlEncode(companyNames.ContainsKey(task.CompanyId ?? "") ? companyNames[task.CompanyId] : "");
                card.CanSubmit = CanSubmit(state);
                card.ButtonText = state == TaskViewState.Revision ? "Resubmit" : (card.CanSubmit ? "Submit work" : "View details");
                cards.Add(card);
            }
            return cards;
        }

        // Only normal web links are allowed (no javascript: links)
        public static bool IsWebLink(string link)
        {
            Uri uri;
            return Uri.TryCreate(link, UriKind.Absolute, out uri)
                   && (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps);
        }

        // "My submissions" list, newest first
        public static List<SubmissionRow> BuildHistory(List<TaskSubmission> history)
        {
            List<SubmissionRow> rows = new List<SubmissionRow>();
            foreach (TaskSubmission s in history.OrderByDescending(x => x.Version))
            {
                SubmissionRow row = new SubmissionRow();
                row.Version = s.Version;
                row.DateText = Format(s.SubmittedAt);
                row.IsLate = s.IsLate;
                row.Description = HttpUtility.HtmlEncode(s.Description);
                row.Link = (!string.IsNullOrEmpty(s.Link) && IsWebLink(s.Link)) ? s.Link : "";
                rows.Add(row);
            }
            return rows;
        }
    }
}
