using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net.Http;
using System.Net.Mail;
using System.Security.Cryptography;
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
        protected Panel workspace, messagePanel, emptyDirectory, editorPanel, editorNotice, passwordSection;
        protected Literal message, studentCount, editorHeading, editorMessage, supervisorHelp, pageSummary, savedMessage, phoneHelp;
        protected Panel savedPanel;
        protected HyperLink previousPage, nextPage;
        protected Repeater students;
        protected HyperLink addStudent;
        protected TextBox studentSearch, studentName, loginEmail, universityEmail, phoneNumber, gpa, temporaryPassword;
        protected DropDownList majorFilter, studentMajor, academicSupervisor, phoneCountry;
        protected Button saveButton, searchButton;
        protected HiddenField openEditor;
        private Dictionary<string, StudentModel> records;
        private Dictionary<string, AcademicSupervisor> supervisors;
        private bool allowed;
        private string EditingId { get; set; }
        private bool resetPage;

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
            EditingId = Request.QueryString["edit"];
            openEditor.Value = "0";
            messagePanel.Visible = editorNotice.Visible = false;
            if (String.IsNullOrWhiteSpace(AuthHelper.IdToken) || AuthHelper.IdToken == "mock-token")
            {
                ShowMessage("Sign in with a real coordinator account to manage students.");
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
                allowed = workspace.Visible = addStudent.Visible = true;
                if (!IsPostBack)
                {
                    studentSearch.Text = Request.QueryString["q"] ?? "";
                    if (majorFilter.Items.FindByValue(Request.QueryString["major"] ?? "") != null)
                        majorFilter.SelectedValue = Request.QueryString["major"] ?? "";
                    if (EditingId != null) EditStudent(EditingId);
                    else if (Request.QueryString["add"] == "1") AddClick(sender, e);
                    if (Request.QueryString["saved"] == "1")
                    {
                        savedPanel.Visible = true;
                        savedMessage.Text = "Student saved successfully." + EmailVerification.MessageFor(Request.QueryString["verify"]) + Notify.AccountMailMessage(Request.QueryString["mail"]);
                    }
                }
            }
            catch
            {
                allowed = workspace.Visible = addStudent.Visible = editorPanel.Visible = false;
                ShowMessage("Could not load students and supervisors. Check the connection or sign in again.");
            }
        }

        protected void Page_PreRender(object sender, EventArgs e)
        {
            if (!allowed) return;
            BindStudents();
            phoneNumber.MaxLength = Int32.Parse(phoneCountry.SelectedItem.Attributes["data-length"]);
            phoneHelp.Text = "Enter " + phoneCountry.SelectedItem.Attributes["data-digits"] + " digits, without the country code or leading zero.";
            addStudent.NavigateUrl = "ManageStudents.aspx?add=1&q=" + Server.UrlEncode(studentSearch.Text)
                + "&major=" + Server.UrlEncode(majorFilter.SelectedValue);
            // The input starts a partial postback; filtering itself stays in C#.
            studentSearch.Attributes["oninput"] = "clearTimeout(window.studentSearchTimer);window.studentSearchTimer=setTimeout(function(){__doPostBack('"
                + studentSearch.UniqueID + "','');},300);";
        }

        // Search, major filter and eight students per page.
        private void BindStudents()
        {
            var rows = new List<StudentModel>();
            string query = studentSearch.Text.Trim();
            foreach (var student in records.Values.OrderBy(item => item.Name))
            {
                if (majorFilter.SelectedValue != "" && student.Major != majorFilter.SelectedValue) continue;
                string supervisorName = SupervisorName(student.AcademicSupervisorId);
                string text = String.Join(" ", student.Name, student.Email, student.UniEmail, supervisorName);
                if (query != "" && text.IndexOf(query, StringComparison.OrdinalIgnoreCase) < 0) continue;
                rows.Add(student);
            }
            int page;
            Int32.TryParse(Request.QueryString["page"], out page);
            page = resetPage ? 1 : Math.Max(1, Math.Min(page, (rows.Count + 7) / 8));
            students.DataSource = rows.Skip((page - 1) * 8).Take(8);
            pageSummary.Text = rows.Count == 0 ? "0 results" : "Page " + page + " of " + ((rows.Count + 7) / 8) + " · " + rows.Count + " results";
            string filter = "ManageStudents.aspx?q=" + Server.UrlEncode(studentSearch.Text) + "&major=" + Server.UrlEncode(majorFilter.SelectedValue);
            previousPage.NavigateUrl = filter + "&page=" + (page - 1);
            nextPage.NavigateUrl = filter + "&page=" + (page + 1);
            previousPage.Visible = page > 1;
            nextPage.Visible = page * 8 < rows.Count;
            students.DataBind();
            studentCount.Text = records.Count.ToString();
            emptyDirectory.Visible = rows.Count == 0;
        }

        protected void SearchChanged(object sender, EventArgs e)
        {
            resetPage = true;
        }

        protected string SupervisorName(string id)
        {
            return supervisors.ContainsKey(id ?? "") ? supervisors[id].Name : "Not assigned";
        }

        protected string EditUrl(string id)
        {
            return "ManageStudents.aspx?edit=" + Server.UrlEncode(id)
                + "&q=" + Server.UrlEncode(studentSearch.Text) + "&major=" + Server.UrlEncode(majorFilter.SelectedValue);
        }

        private void PopulateSupervisors()
        {
            string selected = academicSupervisor.SelectedValue;
            academicSupervisor.Items.Clear();
            academicSupervisor.Items.Add(new ListItem("Select an academic supervisor", ""));
            foreach (var person in supervisors.Values.OrderBy(item => item.Name))
                if (String.Equals(person.Major, studentMajor.SelectedValue, StringComparison.OrdinalIgnoreCase))
                    academicSupervisor.Items.Add(new ListItem(person.Name, person.Id));
            if (academicSupervisor.Items.FindByValue(selected) != null) academicSupervisor.SelectedValue = selected;
            academicSupervisor.Enabled = studentMajor.SelectedValue != "" && academicSupervisor.Items.Count > 1;
            supervisorHelp.Text = studentMajor.SelectedValue == "" ? "Choose a major first."
                : academicSupervisor.Enabled ? "Only supervisors with the same major are listed."
                : "No matching supervisor is available. Create one before saving the student.";
        }

        protected void PhoneCountryChanged(object sender, EventArgs e)
        {
            if (allowed) openEditor.Value = "1";
        }

        protected void MajorChanged(object sender, EventArgs e)
        {
            if (!allowed) return;
            PopulateSupervisors();
            openEditor.Value = "1";
        }

        protected void AddClick(object sender, EventArgs e)
        {
            if (!allowed) return;
            studentName.Text = loginEmail.Text = universityEmail.Text = phoneNumber.Text = gpa.Text = "";
            loginEmail.ReadOnly = false;
            studentMajor.SelectedIndex = 0;
            academicSupervisor.SelectedIndex = -1;
            PopulateSupervisors();
            editorHeading.Text = "Add student";
            saveButton.Text = "Create account";
            editorPanel.Visible = passwordSection.Visible = true;
            GeneratePassword(sender, e);
        }

        protected void GeneratePassword(object sender, EventArgs e)
        {
            if (!allowed) return;
            byte[] bytes = new byte[12];
            using (var random = RandomNumberGenerator.Create()) random.GetBytes(bytes);
            temporaryPassword.Text = "Ua7!" + Convert.ToBase64String(bytes);
            openEditor.Value = "1";
        }

        private void EditStudent(string id)
        {
            StudentModel student;
            if (!records.TryGetValue(id, out student)) { ShowMessage("Student no longer exists."); return; }
            if (studentMajor.Items.FindByValue(student.Major) == null)
            {
                ShowMessage("This student's major is not in the agreed major list. Check it before editing.");
                return;
            }
            EditingId = id;
            studentName.Text = student.Name;
            loginEmail.Text = student.Email;
            loginEmail.ReadOnly = true;
            universityEmail.Text = student.UniEmail;
            string phone = Regex.Replace(student.PhoneNumber ?? "", @"[ ()-]", "");
            var country = phoneCountry.Items.Cast<ListItem>().FirstOrDefault(item => phone.StartsWith(item.Value));
            if (country != null) phoneCountry.SelectedValue = country.Value;
            if (country != null) phone = phone.Substring(country.Value.Length);
            else if (phone.StartsWith("0")) phone = phone.Substring(1);
            phoneNumber.Text = phone;
            gpa.Text = student.GPA.ToString("0.00", CultureInfo.InvariantCulture);
            studentMajor.SelectedValue = student.Major;
            PopulateSupervisors();
            if (academicSupervisor.Items.FindByValue(student.AcademicSupervisorId ?? "") != null)
                academicSupervisor.SelectedValue = student.AcademicSupervisorId ?? "";
            editorHeading.Text = "Edit student";
            saveButton.Text = "Save changes";
            passwordSection.Visible = false;
            editorPanel.Visible = true;
            openEditor.Value = "1";
        }

        // Create an Authentication account for a new student; patch only our fields when editing.
        protected async void SaveClick(object sender, EventArgs e)
        {
            if (!allowed) return;
            openEditor.Value = "1";
            string name = studentName.Text.Trim(), email = loginEmail.Text.Trim();
            string uniEmail = email;   // "Confirmed email" is read-only on the page: it always equals the login email
            string phone = phoneNumber.Text.Trim(), major = studentMajor.SelectedValue, supervisorId = academicSupervisor.SelectedValue;
            double grade;
            if (name.Length < 2 || name.Length > 100 || !ValidEmail(email)
                || !Double.TryParse(gpa.Text, NumberStyles.Number, CultureInfo.InvariantCulture, out grade) || !(grade >= 0 && grade <= 4))
            {
                ShowMessage("Enter a name, a valid email and phone number, and a GPA between 0 and 4.");
                return;
            }
            phone = Regex.Replace(phone, @"[ ()-]", "");
            if (!Regex.IsMatch(phone, "^(?:" + phoneCountry.SelectedItem.Attributes["data-pattern"] + ")$"))
            {
                ShowMessage("Enter " + phoneCountry.SelectedItem.Attributes["data-digits"] + " digits for " + phoneCountry.SelectedItem.Text
                    + ", without the country code or leading zero. Check the mobile prefix too.");
                return;
            }
            phone = phoneCountry.SelectedValue + phone;
            AcademicSupervisor supervisor;
            if (major == "" || !supervisors.TryGetValue(supervisorId, out supervisor)
                || !String.Equals(supervisor.Major, major, StringComparison.OrdinalIgnoreCase))
            {
                PopulateSupervisors();
                ShowMessage("Choose an academic supervisor with the same major before saving.");
                return;
            }
            string id = EditingId;
            if (id != null && !records.ContainsKey(id)) { ShowMessage("Student no longer exists."); return; }
            if (records.Any(item => item.Key != id && (String.Equals(item.Value.Email, email, StringComparison.OrdinalIgnoreCase)
                || String.Equals(item.Value.UniEmail, uniEmail, StringComparison.OrdinalIgnoreCase))))
            {
                ShowMessage("A student with this login or university email already exists.");
                return;
            }
            string newAccountToken = null, verifyResult = null, mailResult = null;
            try
            {
                if (id == null)
                {
                    if (temporaryPassword.Text.Length < 12) { ShowMessage("Generate a temporary password before saving."); return; }
                    var auth = await AuthenticationRequest(AppConfig.SignUpUrl,
                        new { email, password = temporaryPassword.Text, returnSecureToken = true });
                    id = (string)auth["localId"];
                    newAccountToken = (string)auth["idToken"];
                    var student = new StudentModel
                    {
                        Name = name, Email = email, Role = "Student", FirstLogin = true,
                        PhoneNumber = phone, UniEmail = uniEmail, Major = major,
                        AcademicSupervisorId = supervisorId, GPA = grade,
                        CompanyId = "", ProfilePicUrl = "", CvUrl = "", PortfolioUrl = ""
                    };
                    using (var response = await FirebaseDb.Put("Students", id, student))
                        if (!response.IsSuccessStatusCode) throw new HttpRequestException();
                    verifyResult = await EmailVerification.RequireAndSend("Students", id, newAccountToken);
                    mailResult = await Notify.AccountCreated(name, "student", email, temporaryPassword.Text);
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
                    catch { ShowMessage("Login created, but the profile could not be confirmed. Check Authentication before retrying."); return; }
                }
                ShowMessage("Could not save the student. Check email availability and database permissions.");
                return;
            }
            Response.Redirect("ManageStudents.aspx?saved=1" + (verifyResult == null ? "" : "&verify=" + verifyResult) + (mailResult == null ? "" : "&mail=" + mailResult), false);
            Context.ApplicationInstance.CompleteRequest();
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

        private void ShowMessage(string text)
        {
            if (openEditor.Value == "1" && editorPanel.Visible)
            {
                editorNotice.Visible = true;
                editorMessage.Text = text;
                return;
            }
            messagePanel.Visible = true;
            messagePanel.CssClass = "student-notice student-error";
            message.Text = text;
        }
    }
}
