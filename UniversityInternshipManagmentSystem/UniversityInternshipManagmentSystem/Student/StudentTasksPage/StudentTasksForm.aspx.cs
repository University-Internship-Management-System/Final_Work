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

            string studentId = (string)Session["userId"];

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
