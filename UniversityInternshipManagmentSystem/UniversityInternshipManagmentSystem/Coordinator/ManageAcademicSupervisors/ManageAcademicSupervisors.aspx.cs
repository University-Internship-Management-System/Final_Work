using System;
using System.Collections.Generic;
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
    public partial class CoordinatorAcademicAccounts : Page
    {
        protected Panel notice, workspace, emptyDirectory, editorPanel, editorNotice, passwordArea, savedPanel;
        protected Literal noticeText, total, editorTitle, editorMessage, savedMessage, pageSummary;
        protected Repeater directory;
        protected TextBox supervisorSearch, fullName, email, universityEmail, phone, temporaryPassword;
        protected DropDownList major;
        protected Button save;
        protected HyperLink addSupervisor, previousPage, nextPage;
        protected HiddenField openEditor;
        private Dictionary<string, AcademicSupervisor> records;
        private string EditingId { get; set; }
        private bool allowed, resetPage;
        private const string PageUrl = "ManageAcademicSupervisors.aspx";

        protected void Page_Init(object sender, EventArgs e)
        {
            ViewStateUserKey = Session.SessionID;
        }

        // Check coordinator access and load academic supervisors from Firebase.
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
            notice.Visible = editorNotice.Visible = false;
            if (String.IsNullOrWhiteSpace(AuthHelper.IdToken) || AuthHelper.IdToken == "mock-token")
            {
                Tell("Sign in with a real coordinator account.");
                return;
            }
            try
            {
                string json = await FirebaseDb.Get("AcademicSupervisors");
                if (json == null) throw new HttpRequestException();
                records = JsonConvert.DeserializeObject<Dictionary<string, AcademicSupervisor>>(json)
                    ?? new Dictionary<string, AcademicSupervisor>();
                foreach (var item in records) item.Value.Id = item.Key;
                allowed = workspace.Visible = addSupervisor.Visible = true;
                if (IsPostBack) return;
                supervisorSearch.Text = Request.QueryString["q"] ?? "";
                if (EditingId != null || Request.QueryString["add"] == "1") OpenEditor();
                if (Request.QueryString["saved"] == "1")
                {
                    savedPanel.Visible = true;
                    savedMessage.Text = "Academic supervisor saved successfully." + EmailVerification.MessageFor(Request.QueryString["verify"]) + Notify.AccountMailMessage(Request.QueryString["mail"]);
                }
            }
            catch
            {
                allowed = workspace.Visible = addSupervisor.Visible = editorPanel.Visible = false;
                Tell("Could not load academic supervisors. Check the connection or sign in again.");
            }
        }

        protected void Page_PreRender(object sender, EventArgs e)
        {
            if (!allowed) return;
            BindDirectory();
            addSupervisor.NavigateUrl = DirectoryUrl() + "&add=1";
            // Request a partial update while typing. The filtering runs below in C#.
            supervisorSearch.Attributes["oninput"] = "clearTimeout(window.academicSearchTimer);window.academicSearchTimer=setTimeout(function(){__doPostBack('"
                + supervisorSearch.UniqueID + "','');},300);";
        }

        // Search the loaded records and show eight supervisors per page.
        private void BindDirectory()
        {
            var rows = new List<AcademicSupervisor>();
            string query = supervisorSearch.Text.Trim();
            foreach (var person in records.Values.OrderBy(item => item.Name))
            {
                string text = String.Join(" ", person.Name, person.Email, person.UniversityEmail, person.Major);
                if (text.IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0) rows.Add(person);
            }
            int page;
            Int32.TryParse(Request.QueryString["page"], out page);
            int totalPages = (int)Math.Ceiling(rows.Count / 8.0);
            if (page > totalPages) page = totalPages;
            if (page < 1 || resetPage) page = 1;
            directory.DataSource = rows.Skip((page - 1) * 8).Take(8);
            directory.DataBind();
            total.Text = records.Count.ToString();
            emptyDirectory.Visible = rows.Count == 0;
            pageSummary.Text = rows.Count == 0 ? "0 results" : "Page " + page + " of " + totalPages + " · " + rows.Count + " results";
            previousPage.Visible = page > 1;
            nextPage.Visible = page * 8 < rows.Count;
            previousPage.NavigateUrl = DirectoryUrl() + "&page=" + (page - 1);
            nextPage.NavigateUrl = DirectoryUrl() + "&page=" + (page + 1);
        }

        protected void SearchChanged(object sender, EventArgs e) { resetPage = true; }

        protected string EditUrl(string id)
        {
            return DirectoryUrl() + "&edit=" + Server.UrlEncode(id);
        }

        // Keep the search when opening Add, Edit or another results page.
        private string DirectoryUrl()
        {
            return PageUrl + "?q=" + Server.UrlEncode(supervisorSearch.Text);
        }

        // Add generates a password; Edit fills the same form with existing details.
        private void OpenEditor()
        {
            if (EditingId != null && !records.ContainsKey(EditingId)) { Tell("This supervisor no longer exists."); return; }
            editorPanel.Visible = true;
            openEditor.Value = "1";
            if (EditingId == null) { GeneratePassword(null, EventArgs.Empty); return; }
            var person = records[EditingId];
            fullName.Text = person.Name;
            email.Text = person.Email;
            email.ReadOnly = true;
            universityEmail.Text = person.UniversityEmail;
            string number = person.PhoneNumber ?? "";
            if (number.StartsWith("+9627") && number.Length == 13) number = "0" + number.Substring(4);
            phone.Text = number;
            if (major.Items.FindByValue(person.Major) == null && !String.IsNullOrWhiteSpace(person.Major))
                major.Items.Add(new ListItem(person.Major, person.Major));
            major.SelectedValue = person.Major ?? "";
            passwordArea.Visible = false;
            editorTitle.Text = "Edit academic supervisor";
            save.Text = "Save changes";
        }

        protected void GeneratePassword(object sender, EventArgs e)
        {
            if (!allowed) return;
            byte[] bytes = new byte[12];
            using (var random = RandomNumberGenerator.Create()) random.GetBytes(bytes);
            temporaryPassword.Text = "Ua7!" + Convert.ToBase64String(bytes);
            openEditor.Value = "1";
        }

        // Read the form, check the details and duplicates, then save.
        protected async void SaveClick(object sender, EventArgs e)
        {
            if (!allowed) return;
            openEditor.Value = "1";
            var person = new AcademicSupervisor
            {
                Name = fullName.Text.Trim(), Email = email.Text.Trim(),
                UniversityEmail = email.Text.Trim(), Major = major.SelectedValue,
                PhoneNumber = phone.Text.Trim(), Role = "AcademicSupervisor", FirstLogin = true, ProfilePicUrl = ""
            };
            string id = EditingId;
            string error = ValidateSupervisor(person, id);
            if (error != null) { Tell(error); return; }
            string createdToken = null, verifyResult = null, mailResult = null;
            try
            {
                // A supervisor's major must continue to match their assigned students.
                if (id != null && !String.Equals(records[id].Major, person.Major, StringComparison.OrdinalIgnoreCase))
                {
                    string json = await FirebaseDb.Get("Students");
                    if (json == null) throw new HttpRequestException();
                    var students = JsonConvert.DeserializeObject<Dictionary<string, StudentModel>>(json) ?? new Dictionary<string, StudentModel>();
                    foreach (var student in students.Values)
                        if (student != null && student.AcademicSupervisorId == id)
                        {
                            Tell("Reassign this supervisor's students before changing their major.");
                            return;
                        }
                }
                if (id == null)
                {
                    if (temporaryPassword.Text.Length < 12) { Tell("Generate a temporary password before saving."); return; }
                    var auth = await AuthRequest(AppConfig.SignUpUrl,
                        new { email = person.Email, password = temporaryPassword.Text, returnSecureToken = true });
                    id = (string)auth["localId"];
                    createdToken = (string)auth["idToken"];
                    using (var response = await FirebaseDb.Put("AcademicSupervisors", id, person))
                        if (!response.IsSuccessStatusCode) throw new HttpRequestException();
                    verifyResult = await EmailVerification.RequireAndSend("AcademicSupervisors", id, createdToken);
                    mailResult = await Notify.AccountCreated(person.Name, "academic", person.Email, temporaryPassword.Text);
                }
                else
                {
                    // Leave FirstLogin, profile photo and other pages' fields unchanged.
                    var changes = new { person.Name, person.UniversityEmail, person.PhoneNumber, person.Major };
                    using (var response = await FirebaseDb.Patch("AcademicSupervisors", id, changes))
                        if (!response.IsSuccessStatusCode) throw new HttpRequestException();
                }
            }
            catch
            {
                if (createdToken != null)
                {
                    try { await AuthRequest("https://identitytoolkit.googleapis.com/v1/accounts:delete?key=" + AppConfig.ApiKey, new { idToken = createdToken }); }
                    catch { Tell("Login created, but the profile could not be confirmed. Check Authentication before retrying."); return; }
                }
                Tell("Could not save the supervisor. Check email availability and Firebase permissions.");
                return;
            }
            Response.Redirect("ManageAcademicSupervisors.aspx?saved=1" + (verifyResult == null ? "" : "&verify=" + verifyResult) + (mailResult == null ? "" : "&mail=" + mailResult), false);
            Context.ApplicationInstance.CompleteRequest();
        }

        // Check the form before creating or updating a supervisor.
        private string ValidateSupervisor(AcademicSupervisor person, string id)
        {
            string detailsError = "Enter a name, a valid university email, and select a major.";
            if (person.Name.Length < 2 || person.Name.Length > 100) return detailsError;
            if (!ValidEmail(person.Email) || person.Major == "") return detailsError;
            if (!Regex.IsMatch(person.PhoneNumber, @"\A07[0-9]{8}\z"))
                return "Enter a 10-digit mobile number starting with 07, for example 0791234567.";
            if (id != null && !records.ContainsKey(id)) return "This supervisor no longer exists.";
            foreach (var existing in records)
            {
                if (existing.Key == id) continue;
                bool loginUsed = String.Equals(existing.Value.Email, person.Email, StringComparison.OrdinalIgnoreCase);
                bool universityUsed = String.Equals(existing.Value.UniversityEmail, person.UniversityEmail, StringComparison.OrdinalIgnoreCase);
                if (loginUsed || universityUsed)
                    return "A supervisor with this login or university email already exists.";
            }
            return null;
        }

        private static bool ValidEmail(string value)
        {
            try { return value.Length <= 254 && new MailAddress(value).Address == value; }
            catch { return false; }
        }

        private static async Task<JObject> AuthRequest(string url, object data)
        {
            using (var response = await FirebaseDb.client.PostAsync(url, new StringContent(JsonConvert.SerializeObject(data), Encoding.UTF8, "application/json")))
            {
                if (!response.IsSuccessStatusCode) throw new HttpRequestException();
                return JObject.Parse(await response.Content.ReadAsStringAsync());
            }
        }

        private void Tell(string message)
        {
            if (openEditor.Value == "1" && editorPanel.Visible) { editorNotice.Visible = true; editorMessage.Text = message; }
            else { notice.Visible = true; noticeText.Text = message; }
        }
    }
}
