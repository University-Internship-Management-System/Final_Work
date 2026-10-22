using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net.Http;
using System.Net.Mail;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web.UI;
using System.Web.UI.WebControls;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;
using StudentModel = UniversityInternshipManagmentSystem.Models.Student;

namespace UniversityInternshipManagmentSystem.Coordinator
{
    public partial class ManageStudentsPage : Page
    {
        protected Panel messagePanel, workspace, emptyDirectory, editorPanel, passwordSection;
        protected Literal message, studentCount, editorHeading, supervisorHelp;
        protected Repeater students;
        protected LinkButton addStudent;
        protected TextBox studentSearch, studentName, loginEmail, universityEmail, phoneNumber, gpa, temporaryPassword;
        protected DropDownList majorFilter, studentMajor, academicSupervisor;
        protected Button saveButton, searchButton;
        private Dictionary<string, StudentModel> records;
        private Dictionary<string, AcademicSupervisor> supervisors;
        private bool allowed;
        private string EditingId
        {
            get { return ViewState["EditingId"] as string; }
            set { ViewState["EditingId"] = value; }
        }

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
                ShowMessage("Sign in with a real coordinator account to manage students.", true);
                return;
            }
            try
            {
                string json = await FirebaseDb.Get("Students");
                string supervisorJson = await FirebaseDb.Get("AcademicSupervisors");
                if (json == null || supervisorJson == null) throw new HttpRequestException();
                records = JsonConvert.DeserializeObject<Dictionary<string, StudentModel>>(json) ?? new Dictionary<string, StudentModel>();
                supervisors = JsonConvert.DeserializeObject<Dictionary<string, AcademicSupervisor>>(supervisorJson)
                    ?? new Dictionary<string, AcademicSupervisor>();
                foreach (var item in records) item.Value.Id = item.Key;
                foreach (var item in supervisors) item.Value.Id = item.Key;
                allowed = true;
                workspace.Visible = addStudent.Visible = true;
                BindStudents();
                if (!IsPostBack && Request.QueryString["saved"] == "1")
                    ShowMessage("Student saved to Firebase successfully." + EmailSender.MessageFor(Request.QueryString["mail"]));
            }
            catch
            {
                ShowMessage("Could not load students and supervisors. Check the connection, permissions or sign in again.", true);
            }
        }

        private string SupervisorName(StudentModel student)
        {
            AcademicSupervisor supervisor;
            return !String.IsNullOrEmpty(student.AcademicSupervisorId) && supervisors.TryGetValue(student.AcademicSupervisorId, out supervisor)
                ? supervisor.Name : "Not assigned";
        }

        private void BindStudents()
        {
            string query = studentSearch.Text.Trim();
            var result = records.Values.Where(student => (majorFilter.SelectedValue == "" || student.Major == majorFilter.SelectedValue)
                && (query == "" || (student.Name ?? "").IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0
                || (student.Email ?? "").IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0
                || (student.UniEmail ?? "").IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0
                || (SupervisorName(student) ?? "").IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0))
                .OrderBy(student => student.Name).ToList();
            students.DataSource = result.Select(student => new
            {
                student.Id, student.Name, student.Email, student.UniEmail, student.Major,
                GPA = student.GPA.ToString("0.00", CultureInfo.InvariantCulture), SupervisorName = SupervisorName(student)
            });
            students.DataBind();
            studentCount.Text = records.Count.ToString();
            emptyDirectory.Visible = result.Count == 0;
        }

        private void PopulateSupervisors()
        {
            string selected = academicSupervisor.SelectedValue;
            academicSupervisor.Items.Clear();
            academicSupervisor.Items.Add(new ListItem("Select an academic supervisor", ""));
            foreach (var person in supervisors.Values.Where(person => String.Equals(person.Major, studentMajor.SelectedValue, StringComparison.OrdinalIgnoreCase)).OrderBy(person => person.Name))
                academicSupervisor.Items.Add(new ListItem(person.Name, person.Id));
            if (academicSupervisor.Items.FindByValue(selected) != null) academicSupervisor.SelectedValue = selected;
            academicSupervisor.Enabled = academicSupervisor.Items.Count > 1;
            supervisorHelp.Text = studentMajor.SelectedValue == "" ? "Choose a major first."
                : !academicSupervisor.Enabled ? "No supervisor is available for this major. Create one before saving the student."
                : "Only supervisors with the same major are listed.";
        }

        protected void MajorChanged(object sender, EventArgs e)
        {
            if (!allowed) return;
            PopulateSupervisors();
        }

        protected void SearchClick(object sender, EventArgs e)
        {
            if (!allowed) return;
            BindStudents();
            studentSearch.Focus();
        }

        protected void AddClick(object sender, EventArgs e)
        {
            if (!allowed) return;
            CancelClick(sender, e);
            editorPanel.Visible = true;
            studentName.Focus();
        }

        protected void StudentsCommand(object sender, RepeaterCommandEventArgs e)
        {
            if (!allowed || e.CommandName != "EditStudent") return;
            StudentModel student;
            if (!records.TryGetValue(Convert.ToString(e.CommandArgument), out student)) return;
            if (studentMajor.Items.FindByValue(student.Major) == null)
            {
                ShowMessage("This student's major is not in the agreed major list. Check it before editing.", true);
                return;
            }
            EditingId = student.Id;
            editorPanel.Visible = true;
            studentName.Text = student.Name;
            loginEmail.Text = student.Email;
            loginEmail.ReadOnly = true;
            universityEmail.Text = student.UniEmail;
            phoneNumber.Text = student.PhoneNumber;
            gpa.Text = student.GPA.ToString("0.00", CultureInfo.InvariantCulture);
            studentMajor.SelectedValue = student.Major;
            PopulateSupervisors();
            if (academicSupervisor.Items.FindByValue(student.AcademicSupervisorId ?? "") != null)
                academicSupervisor.SelectedValue = student.AcademicSupervisorId ?? "";
            passwordSection.Visible = false;
            editorHeading.Text = "Edit student";
            saveButton.Text = "Save changes";
            studentName.Focus();
        }

        protected async void SaveClick(object sender, EventArgs e)
        {
            if (!allowed) return;
            string name = studentName.Text.Trim(), email = loginEmail.Text.Trim(), uniEmail = universityEmail.Text.Trim();
            string phone = phoneNumber.Text.Trim(), major = studentMajor.SelectedValue, supervisorId = academicSupervisor.SelectedValue;
            double grade;
            if (name.Length < 2 || name.Length > 100 || !ValidEmail(email) || !ValidEmail(uniEmail)
                || !Regex.IsMatch(phone, @"^\+?[0-9 ()-]{7,25}$")
                || !Double.TryParse(gpa.Text, NumberStyles.Number, CultureInfo.InvariantCulture, out grade) || !(grade >= 0 && grade <= 4))
            {
                ShowMessage("Enter a name, valid emails and phone number, and a GPA between 0 and 4.", true);
                return;
            }
            AcademicSupervisor supervisor;
            if (major == "" || !supervisors.TryGetValue(supervisorId, out supervisor)
                || !String.Equals(supervisor.Major, major, StringComparison.OrdinalIgnoreCase))
            {
                PopulateSupervisors();
                ShowMessage("Choose an academic supervisor with the same major before saving.", true);
                return;
            }
            string id = EditingId;
            if (id != null && !records.ContainsKey(id)) { ShowMessage("Student no longer exists. Reload the directory.", true); return; }
            if (records.Any(item => item.Key != id && (String.Equals(item.Value.Email, email, StringComparison.OrdinalIgnoreCase)
                || String.Equals(item.Value.UniEmail, uniEmail, StringComparison.OrdinalIgnoreCase))))
            {
                ShowMessage("A student with this login or university email already exists.", true);
                return;
            }
            if (id == null && temporaryPassword.Text.Length < 12) { ShowMessage("Use a temporary password of at least 12 characters.", true); return; }
            string newAccountToken = null;
            string mailResult = null;
            try
            {
                if (id == null)
                {
                    var auth = await AuthenticationRequest(AppConfig.SignUpUrl,
                        new { email = email, password = temporaryPassword.Text, returnSecureToken = true });
                    id = (string)auth["localId"];
                    newAccountToken = (string)auth["idToken"];
                    var student = new StudentModel(name, email, true, phone, "", uniEmail, major, "", supervisorId, grade, "", "", new List<string>());
                    using (var response = await FirebaseDb.Put("Students", id, student))
                        if (!response.IsSuccessStatusCode) throw new HttpRequestException();
                    mailResult = await EmailSender.SendWelcome(name, "Student", email);
                }
                else
                {
                    var changes = new { Name = name, PhoneNumber = phone, UniEmail = uniEmail, Major = major, GPA = grade, AcademicSupervisorId = supervisorId };
                    using (var response = await FirebaseDb.Patch("Students", id, changes))
                        if (!response.IsSuccessStatusCode) throw new HttpRequestException();
                }
            }
            catch
            {
                if (newAccountToken != null)
                {
                    try { await AuthenticationRequest("https://identitytoolkit.googleapis.com/v1/accounts:delete?key=" + AppConfig.ApiKey, new { idToken = newAccountToken }); }
                    catch { ShowMessage("Login created, but the profile could not be confirmed. Check Authentication before retrying.", true); return; }
                }
                ShowMessage("Could not save the student. Check email availability, the password policy and database permissions.", true);
                return;
            }
            Response.Redirect(Request.AppRelativeCurrentExecutionFilePath + "?saved=1" + (mailResult == null ? "" : "&mail=" + mailResult), false);
            Context.ApplicationInstance.CompleteRequest();
        }

        protected void CancelClick(object sender, EventArgs e)
        {
            if (!allowed) return;
            EditingId = null;
            editorPanel.Visible = false;
            studentName.Text = loginEmail.Text = universityEmail.Text = phoneNumber.Text = gpa.Text = temporaryPassword.Text = "";
            loginEmail.ReadOnly = false;
            studentMajor.SelectedIndex = 0;
            PopulateSupervisors();
            passwordSection.Visible = true;
            editorHeading.Text = "Add student";
            saveButton.Text = "Create account";
        }

        private static bool ValidEmail(string value)
        {
            try { return value.Length <= 254 && new MailAddress(value).Address == value; }
            catch { return false; }
        }

        private static async Task<JObject> AuthenticationRequest(string url, object data)
        {
            using (var response = await FirebaseDb.client.PostAsync(url, new StringContent(JsonConvert.SerializeObject(data), Encoding.UTF8, "application/json")))
            {
                if (!response.IsSuccessStatusCode) throw new HttpRequestException();
                return JObject.Parse(await response.Content.ReadAsStringAsync());
            }
        }

        private void ShowMessage(string text, bool error = false)
        {
            messagePanel.Visible = true;
            messagePanel.CssClass = error ? "student-preview student-error" : "student-preview";
            message.Text = text;
        }
    }
}
