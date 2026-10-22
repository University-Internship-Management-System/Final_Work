using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;

namespace UniversityInternshipManagmentSystem.Student.StudentTasksPage
{
    public partial class StudentTasksForm : System.Web.UI.Page
    {
        protected async void Page_Load(object sender, EventArgs e)
        {
            // Not logged in -> go to the login page.
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }

            string studentId = (string)(Session["dbRecordId"] ?? Session["userId"]);   // dbRecordId = the Students table key set by the login

            List<Tasks> tasks = await TaskDb.GetMyTasks(studentId);
            List<TaskSubmission> subs = await TaskDb.GetMySubmissions(studentId);

            // The 5 number cards
            StateCounts c = TaskLogic.CountStates(tasks, subs);
            lblTotal.Text = c.Total.ToString();
            lblTodo.Text = (c.Todo + c.Overdue).ToString();
            lblReview.Text = c.Submitted.ToString();
            lblRevision.Text = c.Revision.ToString();
            lblEvaluated.Text = c.Evaluated.ToString();

            // The 6 week cards
            rptWeeks.DataSource = TaskLogic.BuildWeeks(tasks, subs);
            rptWeeks.DataBind();
        }
    }
}
