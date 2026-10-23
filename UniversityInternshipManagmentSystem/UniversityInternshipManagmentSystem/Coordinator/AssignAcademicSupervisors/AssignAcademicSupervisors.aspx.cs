using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Web.UI;
using System.Web.UI.WebControls;
using Newtonsoft.Json;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;
using StudentModel = UniversityInternshipManagmentSystem.Models.Student;

namespace UniversityInternshipManagmentSystem.Coordinator
{
    public partial class AssignAcademicSupervisorsPage : Page
    {
        protected Panel messagePanel, workspace, reviewPanel;
        protected Literal message, groupCaption, supervisorHelp, reviewSummary;
        protected DropDownList assignMajor, assignStatus, assignSupervisor;
        protected Repeater students, reviewStudents;
        private Dictionary<string, StudentModel> records;
        private Dictionary<string, AcademicSupervisor> supervisors;
        private bool allowed;

        protected void Page_Init(object sender, EventArgs e)
        {
            ViewStateUserKey = Session.SessionID;
        }

        protected async void Page_Load(object sender, EventArgs e)
        {
            if (Session["userId"] == null)
            {
                Response.Redirect("~/login/Login.aspx", false);
                return;
            }
            AuthHelper.RequireAuth(this, AuthHelper.RoleCoordinator);
            if (Response.IsRequestBeingRedirected) return;
            if (String.IsNullOrWhiteSpace(AuthHelper.IdToken) || AuthHelper.IdToken == "mock-token")
            {
                ShowMessage("Sign in with a real coordinator account to assign supervisors.", true);
                return;
            }
            try
            {
                string json = await FirebaseDb.Get("Students");
                string supervisorJson = await FirebaseDb.Get("AcademicSupervisors");
                if (json == null || supervisorJson == null) throw new HttpRequestException();
                records = JsonConvert.DeserializeObject<Dictionary<string, StudentModel>>(json)
                    ?? new Dictionary<string, StudentModel>();
                supervisors = JsonConvert.DeserializeObject<Dictionary<string, AcademicSupervisor>>(supervisorJson)
                    ?? new Dictionary<string, AcademicSupervisor>();
                allowed = workspace.Visible = true;
                if (!IsPostBack)
                {
                    BindStudents();
                    PopulateSupervisors();
                    if (Request.QueryString["saved"] == "1") ShowMessage("Academic supervisor assignments saved to Firebase successfully.");
                }
            }
            catch
            {
                workspace.Visible = false;
                ShowMessage("Could not load students and supervisors. Check the connection, permissions or sign in again.", true);
            }
        }

        private void BindStudents()
        {
            var group = records.Where(item => item.Value.Major == assignMajor.SelectedValue
                && (assignStatus.SelectedValue == "All"
                    || (assignStatus.SelectedValue == "Assigned") == !String.IsNullOrEmpty(item.Value.AcademicSupervisorId)));
            students.DataSource = group.OrderBy(item => item.Value.Name).Select(item => new
            {
                Id = item.Key, item.Value.Name, item.Value.UniEmail, item.Value.Major,
                SupervisorName = SupervisorName(item.Value.AcademicSupervisorId)
            });
            students.DataBind();
            groupCaption.Text = assignMajor.SelectedValue == "" ? "Choose a major to display students." : assignMajor.SelectedValue;
        }

        private string SupervisorName(string id)
        {
            AcademicSupervisor supervisor;
            return !String.IsNullOrEmpty(id) && supervisors.TryGetValue(id, out supervisor)
                ? supervisor.Name : "Not assigned";
        }

        private void PopulateSupervisors()
        {
            assignSupervisor.Items.Clear();
            assignSupervisor.Items.Add(new ListItem("Select an academic supervisor", ""));
            foreach (var item in supervisors.Where(item => item.Value.Major == assignMajor.SelectedValue)
                .OrderBy(item => item.Value.Name))
                assignSupervisor.Items.Add(new ListItem(item.Value.Name, item.Key));
            assignSupervisor.Enabled = assignMajor.SelectedValue != "" && assignSupervisor.Items.Count > 1;
            supervisorHelp.Text = assignMajor.SelectedValue == "" ? "Choose a major first."
                : assignSupervisor.Enabled ? "Only supervisors with the same major are listed."
                : "No academic supervisors are available for this major. Create one before assigning students.";
        }

        protected void FiltersChanged(object sender, EventArgs e)
        {
            if (!allowed) return;
            reviewPanel.Visible = false;
            ViewState.Remove("StudentIds");
            BindStudents();
            PopulateSupervisors();
        }

        private bool ValidAssignment(string[] ids, string supervisorId, string major)
        {
            AcademicSupervisor supervisor;
            return ids != null && ids.Length > 0 && major != ""
                && supervisors.TryGetValue(supervisorId, out supervisor) && supervisor.Major == major
                && ids.All(id => records.ContainsKey(id) && records[id].Major == major);
        }

        protected void ReviewAssignment(object sender, EventArgs e)
        {
            if (!allowed) return;
            var ids = new List<string>();
            foreach (RepeaterItem item in students.Items)
            {
                if (((CheckBox)item.FindControl("selectedStudent")).Checked)
                    ids.Add(((HiddenField)item.FindControl("studentId")).Value);
            }
            string[] selected = ids.Distinct().ToArray();
            if (!ValidAssignment(selected, assignSupervisor.SelectedValue, assignMajor.SelectedValue))
            {
                ShowMessage("Select students and an academic supervisor with the same major.", true);
                return;
            }
            ViewState["StudentIds"] = selected;
            ViewState["SupervisorId"] = assignSupervisor.SelectedValue;
            ViewState["Major"] = assignMajor.SelectedValue;
            reviewSummary.Text = selected.Length + " student(s) in " + assignMajor.SelectedValue
                + " will be assigned to " + supervisors[assignSupervisor.SelectedValue].Name + ".";
            reviewStudents.DataSource = selected.Select(id => new { records[id].Name, Previous = SupervisorName(records[id].AcademicSupervisorId) });
            reviewStudents.DataBind();
            reviewPanel.Visible = true;
        }

        protected async void ConfirmAssignment(object sender, EventArgs e)
        {
            if (!allowed) return;
            string[] ids = ViewState["StudentIds"] as string[];
            string supervisorId = ViewState["SupervisorId"] as string ?? "";
            string major = ViewState["Major"] as string ?? "";
            // Recheck the current Firebase records before saving the reviewed selection.
            if (!ValidAssignment(ids, supervisorId, major))
            {
                reviewPanel.Visible = false;
                ShowMessage("The students or supervisor have changed. Review a matching group again before saving.", true);
                BindStudents();
                PopulateSupervisors();
                return;
            }
            try
            {
                var updates = new Dictionary<string, object>();
                foreach (string id in ids) updates[id + "/AcademicSupervisorId"] = supervisorId;
                // One multi-location update changes only the selected students' assignments.
                using (var response = await FirebaseDb.Patch("Students", null, updates))
                {
                    if (!response.IsSuccessStatusCode) throw new HttpRequestException();
                }
                Notify.SupervisorAssigned(ids, supervisorId);
                Response.Redirect("AssignAcademicSupervisors.aspx?saved=1", false);
                Context.ApplicationInstance.CompleteRequest();
            }
            catch
            {
                ShowMessage("Assignments could not be saved. Check the connection and try again.", true);
            }
        }

        protected void CancelReview(object sender, EventArgs e)
        {
            reviewPanel.Visible = false;
            ViewState.Remove("StudentIds");
        }

        private void ShowMessage(string text, bool error = false)
        {
            messagePanel.Visible = true;
            messagePanel.CssClass = "assign-notice" + (error ? " assign-error" : "");
            message.Text = text;
        }
    }
}
