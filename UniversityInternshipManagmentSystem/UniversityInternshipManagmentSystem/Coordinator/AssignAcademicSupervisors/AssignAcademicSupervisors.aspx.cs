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
        protected Panel messagePanel, workspace, reviewPanel, reviewNotice, emptyStudents, savedPanel;
        protected Literal message, groupCaption, supervisorHelp, reviewSummary, selectedCount, reviewError;
        protected DropDownList assignMajor, assignSupervisor;
        protected TextBox assignSearch;
        protected Repeater students, reviewStudents;
        protected CheckBox selectAll;
        protected Button reviewButton, clearSelection;
        protected HiddenField openReview;
        private Dictionary<string, StudentModel> records;
        private Dictionary<string, AcademicSupervisor> supervisors;
        private List<string> SelectedIds { get; set; } = new List<string>();
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
            messagePanel.Visible = reviewNotice.Visible = false;
            openReview.Value = "0";
            SelectedIds = ViewState["SelectedIds"] as List<string> ?? new List<string>();
            if (String.IsNullOrWhiteSpace(AuthHelper.IdToken) || AuthHelper.IdToken == "mock-token")
            {
                ShowMessage("Sign in with a real coordinator account to assign supervisors.");
                return;
            }
            try
            {
                string json = await FirebaseDb.Get("Students");
                string supervisorJson = await FirebaseDb.Get("AcademicSupervisors");
                if (json == null || supervisorJson == null) throw new HttpRequestException();
                records = JsonConvert.DeserializeObject<Dictionary<string, StudentModel>>(json) ?? new Dictionary<string, StudentModel>();
                supervisors = JsonConvert.DeserializeObject<Dictionary<string, AcademicSupervisor>>(supervisorJson) ?? new Dictionary<string, AcademicSupervisor>();
                foreach (var item in records) item.Value.Id = item.Key;
                allowed = workspace.Visible = true;
                if (!IsPostBack)
                {
                    PopulateSupervisors();
                    savedPanel.Visible = Request.QueryString["saved"] == "1";
                }
            }
            catch
            {
                allowed = workspace.Visible = reviewPanel.Visible = false;
                ShowMessage("Could not load students and supervisors. Check the connection or sign in again.");
            }
        }

        protected void Page_PreRender(object sender, EventArgs e)
        {
            if (!allowed) return;
            BindStudents();
            selectedCount.Text = SelectedIds.Count + " selected";
            clearSelection.Enabled = SelectedIds.Count > 0;
            reviewButton.Enabled = ValidAssignment(SelectedIds.ToArray(), assignSupervisor.SelectedValue, assignMajor.SelectedValue);
            ViewState["SelectedIds"] = SelectedIds;
            // This starts a partial update; searching and selection stay in C#.
            assignSearch.Attributes["oninput"] = "clearTimeout(window.assignSearchTimer);window.assignSearchTimer=setTimeout(function(){__doPostBack('"
                + assignSearch.UniqueID + "','');},300);";
        }

        // Show students from the chosen major, filtered by name or university email.
        private void BindStudents()
        {
            var rows = new List<StudentModel>();
            string query = assignSearch.Text.Trim();
            foreach (var student in records.Values.OrderBy(item => item.Name))
            {
                if (student.Major != assignMajor.SelectedValue) continue;
                string text = String.Join(" ", student.Name, student.UniEmail);
                if (text.IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0) rows.Add(student);
            }
            students.DataSource = rows;
            students.DataBind();
            foreach (RepeaterItem item in students.Items)
            {
                string id = ((HiddenField)item.FindControl("studentId")).Value;
                var checkbox = (CheckBox)item.FindControl("selectedStudent");
                checkbox.Checked = SelectedIds.Contains(id);
                ScriptManager.GetCurrent(this).RegisterAsyncPostBackControl(checkbox);
            }
            selectAll.Enabled = rows.Count > 0;
            selectAll.Checked = rows.Count > 0;
            foreach (var student in rows)
                if (!SelectedIds.Contains(student.Id)) { selectAll.Checked = false; break; }
            emptyStudents.Visible = rows.Count == 0;
            if (assignMajor.SelectedValue == "") groupCaption.Text = "Choose a major to display students.";
            else groupCaption.Text = rows.Count + " student(s) shown · " + assignMajor.SelectedValue;
        }

        protected string SupervisorName(string id)
        {
            AcademicSupervisor person;
            if (supervisors.TryGetValue(id ?? "", out person)) return person.Name;
            return "Not assigned";
        }

        private void PopulateSupervisors()
        {
            assignSupervisor.Items.Clear();
            assignSupervisor.Items.Add(new ListItem("Select an academic supervisor", ""));
            foreach (var item in supervisors.OrderBy(item => item.Value.Name))
                if (item.Value.Major == assignMajor.SelectedValue)
                    assignSupervisor.Items.Add(new ListItem(item.Value.Name, item.Key));
            assignSupervisor.Enabled = assignMajor.SelectedValue != "" && assignSupervisor.Items.Count > 1;
            if (assignMajor.SelectedValue == "") supervisorHelp.Text = "Choose a major first.";
            else if (assignSupervisor.Enabled) supervisorHelp.Text = "Only supervisors with the same major are listed.";
            else supervisorHelp.Text = "No supervisors are available for this major. Create one before assigning students.";
        }

        // Changing the major clears the previous group and supervisor.
        protected void MajorChanged(object sender, EventArgs e)
        {
            if (!allowed) return;
            SelectedIds.Clear();
            InvalidateReview();
            PopulateSupervisors();
        }

        // Read only the displayed checkboxes; searching keeps any selections hidden by the search.
        private void ReadSelection()
        {
            foreach (RepeaterItem item in students.Items)
            {
                string id = ((HiddenField)item.FindControl("studentId")).Value;
                SelectedIds.Remove(id);
                if (((CheckBox)item.FindControl("selectedStudent")).Checked) SelectedIds.Add(id);
            }
        }

        protected void SelectionChanged(object sender, EventArgs e)
        {
            if (!allowed) return;
            ReadSelection();
            InvalidateReview();
        }

        protected void SelectAllChanged(object sender, EventArgs e)
        {
            if (!allowed) return;
            foreach (RepeaterItem item in students.Items)
                ((CheckBox)item.FindControl("selectedStudent")).Checked = selectAll.Checked;
            SelectionChanged(sender, e);
        }

        protected void ClearSelection(object sender, EventArgs e)
        {
            if (!allowed) return;
            SelectedIds.Clear();
            InvalidateReview();
        }

        // Any selection change requires a new review before saving.
        private void InvalidateReview()
        {
            reviewPanel.Visible = false;
            ViewState.Remove("ReviewIds");
        }

        // Every selected student and the new supervisor must have the same major.
        private bool ValidAssignment(string[] ids, string supervisorId, string major)
        {
            if (ids == null || ids.Length == 0 || major == "") return false;
            AcademicSupervisor person;
            if (!supervisors.TryGetValue(supervisorId, out person)) return false;
            if (person.Major != major) return false;
            foreach (string id in ids)
            {
                StudentModel student;
                if (!records.TryGetValue(id, out student)) return false;
                if (student.Major != major) return false;
            }
            return true;
        }

        protected void ReviewAssignment(object sender, EventArgs e)
        {
            if (!allowed) return;
            ReadSelection();
            if (!ValidAssignment(SelectedIds.ToArray(), assignSupervisor.SelectedValue, assignMajor.SelectedValue))
            {
                ShowMessage("Select students and a supervisor with the same major.");
                return;
            }
            ViewState["ReviewIds"] = SelectedIds.ToArray();
            ViewState["SupervisorId"] = assignSupervisor.SelectedValue;
            ViewState["Major"] = assignMajor.SelectedValue;
            reviewSummary.Text = SelectedIds.Count + " student(s) in " + assignMajor.SelectedValue
                + " will be assigned to " + supervisors[assignSupervisor.SelectedValue].Name + ".";
            var reviewedStudents = new List<StudentModel>();
            foreach (string id in SelectedIds) reviewedStudents.Add(records[id]);
            reviewStudents.DataSource = reviewedStudents;
            reviewStudents.DataBind();
            reviewPanel.Visible = true;
            openReview.Value = "1";
        }

        protected async void ConfirmAssignment(object sender, EventArgs e)
        {
            if (!allowed) return;
            string[] ids = ViewState["ReviewIds"] as string[];
            string supervisorId = ViewState["SupervisorId"] as string ?? "";
            string major = ViewState["Major"] as string ?? "";
            // Page_Load fetched fresh Firebase records. Recheck them before saving the reviewed group.
            if (!ValidAssignment(ids, supervisorId, major))
            {
                InvalidateReview();
                ShowMessage("The students or supervisor have changed. Review a matching group again before saving.");
                PopulateSupervisors();
                return;
            }
            try
            {
                var updates = new Dictionary<string, object>();
                foreach (string id in ids) updates[id + "/AcademicSupervisorId"] = supervisorId;
                using (var response = await FirebaseDb.Patch("Students", null, updates))
                    if (!response.IsSuccessStatusCode) throw new HttpRequestException();
                Notify.SupervisorAssigned(ids, supervisorId);
                Response.Redirect("AssignAcademicSupervisors.aspx?saved=1", false);
                Context.ApplicationInstance.CompleteRequest();
            }
            catch
            {
                reviewNotice.Visible = true;
                reviewError.Text = "Assignments could not be saved. Check the connection and try again.";
                openReview.Value = "1";
            }
        }

        private void ShowMessage(string text) { messagePanel.Visible = true; message.Text = text; }
    }
}
