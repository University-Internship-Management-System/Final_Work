using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;
using UniversityInternshipManagmentSystem.Student.StudentTasksPage;   // TaskLogic (latest submission, weeks count)

namespace UniversityInternshipManagmentSystem.Company.FinalEvaluationPage
{
    public partial class FinalEvaluationListForm : System.Web.UI.Page
    {
        protected async void Page_Load(object sender, EventArgs e)
        {
            // Not logged in, or not a company supervisor -> RequireAuth redirects
            AuthHelper.RequireAuth(this, AuthHelper.RoleCompany, AuthHelper.RoleCoordinator);
            if (Response.IsRequestBeingRedirected) return;

            string companyId = (string)(Session["dbRecordId"] ?? Session["userId"]);   // dbRecordId = the CompanySupervisors table key set by the login
            await LoadPage(companyId);
        }

        // Loads from Firebase and fills the numbers and the table (one line per trainee)
        private async Task LoadPage(string companyId)
        {
            List<Tasks> tasks = await TaskDb.GetCompanyTasks(companyId);
            List<TaskSubmission> subs = await TaskDb.GetSubmissionsOfTasks(tasks);
            Dictionary<string, FinalEvaluation> evaluations = await TaskDb.GetFinalEvaluations(companyId);

            // my trainees = the students whose CompanyId is my company
            Dictionary<string, Models.Student> all = await TaskDb.GetStudents();
            List<KeyValuePair<string, Models.Student>> trainees = all.Where(x => x.Value.CompanyId == companyId).OrderBy(x => x.Value.Name).ToList();

            int notStarted = 0, draft = 0, sent = 0;
            var rows = new List<object>();
            foreach (var trainee in trainees)
            {
                string id = trainee.Key;
                FinalEvaluation evaluation = evaluations.ContainsKey(id) ? evaluations[id] : null;

                // the tasks of this trainee (a closed task was cancelled: it is not in the report)
                int planned = 0, done = 0;
                foreach (Tasks task in tasks)
                {
                    if (task.Status != TaskState.Open || !task.StudentIds.Contains(id)) continue;

                    planned += task.HoursFor(id);
                    List<TaskSubmission> theirs = subs.Where(s => s.StudentId == id).ToList();
                    TaskSubmission last = TaskLogic.LatestSubmission(task.TaskId, theirs);
                    if (last != null && last.Status == SubmissionState.Evaluated)
                        done += task.HoursFor(id);
                }

                string statusText, badge;
                if (evaluation == null) { statusText = "Not started"; badge = "st-badge-closed"; notStarted++; }
                else if (evaluation.Status == FinalEvaluation.Sent) { statusText = "Sent"; badge = "badge-approved"; sent++; }
                else { statusText = "Draft"; badge = "badge-pending"; draft++; }

                int signed = evaluation == null ? 0 : evaluation.ApprovedWeeks.Count;
                rows.Add(new
                {
                    Id = id,
                    Name = trainee.Value.Name,
                    Major = trainee.Value.Major,
                    HoursText = done + " h done of " + planned + " h",
                    WeeksText = signed + " / " + TaskLogic.WeeksCount,
                    StatusText = statusText,
                    Badge = badge
                });
            }

            lblTrainees.Text = trainees.Count.ToString();
            lblNotStarted.Text = notStarted.ToString();
            lblDraft.Text = draft.ToString();
            lblSent.Text = sent.ToString();

            rptTrainees.DataSource = rows;
            rptTrainees.DataBind();
            rptTrainees.Visible = rows.Count > 0;
            pnlEmpty.Visible = rows.Count == 0;
        }
    }
}
