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
                    savedMessage.Text = "Academic supervisor saved successfully." + EmailVerification.MessageFor(Request.QueryString["verify"]);
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
            addSupervisor.NavigateUrl = "ManageAcademicSupervisors.aspx?add=1&q=" + Server.UrlEncode(supervisorSearch.Text);
            // Request a partial update while typing. The filtering runs below in C#.
            supervisorSearch.Attributes["oninput"] = "clearTimeout(window.academicSearchTimer);window.academicSearchTimer=setTimeout(function(){__doPostBack('"
                + supervisorSearch.UniqueID + "','');},300);";
        }

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
            page = resetPage ? 1 : Math.Max(1, Math.Min(page, (rows.Count + 7) / 8));
            directory.DataSource = rows.Skip((page - 1) * 8).Take(8);
            directory.DataBind();
            total.Text = records.Count.ToString();
            emptyDirectory.Visible = rows.Count == 0;
            pageSummary.Text = rows.Count == 0 ? "0 results" : "Page " + page + " of " + ((rows.Count + 7) / 8) + " · " + rows.Count + " results";
            previousPage.Visible = page > 1;
            nextPage.Visible = page * 8 < rows.Count;
            previousPage.NavigateUrl = "ManageAcademicSupervisors.aspx?page=" + (page - 1) + "&q=" + Server.UrlEncode(supervisorSearch.Text);
            nextPage.NavigateUrl = "ManageAcademicSupervisors.aspx?page=" + (page + 1) + "&q=" + Server.UrlEncode(supervisorSearch.Text);
        }

        protected void SearchChanged(object sender, EventArgs e) { resetPage = true; }

        protected string EditUrl(string id)
        {
            return "ManageAcademicSupervisors.aspx?edit=" + Server.UrlEncode(id) + "&q=" + Server.UrlEncode(supervisorSearch.Text);
        }

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
            phone.Text = number.StartsWith("+9627") && number.Length == 13 ? "0" + number.Substring(4) : number;
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

        protected async void SaveClick(object sender, EventArgs e)
        {
            if (!allowed) return;
            openEditor.Value = "1";
            var person = new AcademicSupervisor
            {
                Name = fullName.Text.Trim(), Email = email.Text.Trim(),
                UniversityEmail = universityEmail.Text.Trim(), Major = major.SelectedValue,
                PhoneNumber = phone.Text.Trim(), Role = "AcademicSupervisor", FirstLogin = true, ProfilePicUrl = ""
            };
            if (person.Name.Length < 2 || person.Name.Length > 100 || !ValidEmail(person.Email)
                || !ValidEmail(person.UniversityEmail) || person.Major == "")
            {
                Tell("Enter a name, valid login and university emails, and select a major.");
                return;
            }
            if (!Regex.IsMatch(person.PhoneNumber, @"\A07[0-9]{8}\z"))
            {
                Tell("Enter a 10-digit mobile number starting with 07, for example 0791234567.");
                return;
            }
            string id = EditingId;
            if (id != null && !records.ContainsKey(id)) { Tell("This supervisor no longer exists."); return; }
            if (records.Any(item => item.Key != id && (String.Equals(item.Value.Email, person.Email, StringComparison.OrdinalIgnoreCase)
                || String.Equals(item.Value.UniversityEmail, person.UniversityEmail, StringComparison.OrdinalIgnoreCase))))
            {
                Tell("A supervisor with this login or university email already exists.");
                return;
            }
            string createdToken = null, verifyResult = null;
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
                    Notify.AccountCreated(person.Name, "academic", person.Email, temporaryPassword.Text);
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
            Response.Redirect("ManageAcademicSupervisors.aspx?saved=1" + (verifyResult == null ? "" : "&verify=" + verifyResult), false);
            Context.ApplicationInstance.CompleteRequest();
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
