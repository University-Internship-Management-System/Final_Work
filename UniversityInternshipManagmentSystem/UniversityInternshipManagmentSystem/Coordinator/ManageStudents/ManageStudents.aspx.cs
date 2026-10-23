using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.IO;
using System.Web;
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
        protected FileUpload importFile;
        protected Panel importNotice, importPreview;
        protected Literal importMessage, importSummary;
        protected Repeater importRows, importSupervisors;
        protected Button confirmImport;
        protected HiddenField openImport, importToken;
        private bool downloadingTemplate;
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
            if (Request.QueryString["template"] == "1")
            {
                DownloadTemplate();
                return;
            }
            EditingId = Request.QueryString["edit"];
            openEditor.Value = "0";
            openImport.Value = "0";
            importNotice.Visible = false;
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
                if (!IsPostBack && Request.QueryString["import"] == "1") openImport.Value = "1";
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
                        savedMessage.Text = "Student saved successfully." + EmailVerification.MessageFor(Request.QueryString["verify"]);
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
            importSupervisors.DataSource = supervisors.Values.OrderBy(item => item.Major).ThenBy(item => item.Name);
            importSupervisors.DataBind();
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
            temporaryPassword.Text = NewPassword();
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
            double grade;
            if (!Double.TryParse(gpa.Text, NumberStyles.Number, CultureInfo.InvariantCulture, out grade)) grade = Double.NaN;
            var student = new StudentModel
            {
                Name = studentName.Text.Trim(), Email = loginEmail.Text.Trim(), UniEmail = universityEmail.Text.Trim(),
                PhoneNumber = phoneCountry.SelectedValue + Regex.Replace(phoneNumber.Text.Trim(), @"[ ()-]", ""),
                Major = studentMajor.SelectedValue, AcademicSupervisorId = academicSupervisor.SelectedValue, GPA = grade
            };
            string error = ValidateStudent(student, EditingId);
            if (error != null) { ShowMessage(error); return; }
            string verifyResult = null;
            if (EditingId == null)
            {
                if (temporaryPassword.Text.Length < 12) { ShowMessage("Generate a temporary password before saving."); return; }
                AccountResult result = await CreateStudent(student, temporaryPassword.Text);
                if (!result.Success) { ShowMessage(result.Message); return; }
                verifyResult = result.Verification;
            }
            else
            {
                try
                {
                    var changes = new { student.Name, student.PhoneNumber, student.UniEmail, student.Major, student.GPA, student.AcademicSupervisorId };
                    using (var response = await FirebaseDb.Patch("Students", EditingId, changes))
                        if (!response.IsSuccessStatusCode) throw new HttpRequestException();
                }
                catch { ShowMessage("Could not save the student. Check the connection and database permissions."); return; }
            }
            Response.Redirect("ManageStudents.aspx?saved=1" + (verifyResult == null ? "" : "&verify=" + verifyResult), false);
            Context.ApplicationInstance.CompleteRequest();
        }


        // Both the form and the CSV import use these same rules.
        private string ValidateStudent(StudentModel student, string editingId = null)
        {
            if (student.Name.Length < 2 || student.Name.Length > 100 || !ValidEmail(student.Email) || !ValidEmail(student.UniEmail)
                || !(student.GPA >= 0 && student.GPA <= 4))
                return "Enter a name, valid emails, and a GPA between 0 and 4.";
            ListItem country = phoneCountry.Items.Cast<ListItem>().FirstOrDefault(item => student.PhoneNumber.StartsWith(item.Value));
            if (country == null || !Regex.IsMatch(student.PhoneNumber.Substring(country.Value.Length),
                @"\A(?:" + country.Attributes["data-pattern"] + @")\z"))
                return "Enter a valid mobile number with a supported country code and no leading zero after the code.";
            AcademicSupervisor supervisor;
            if (studentMajor.Items.FindByValue(student.Major) == null || student.Major == ""
                || !supervisors.TryGetValue(student.AcademicSupervisorId ?? "", out supervisor)
                || !String.Equals(supervisor.Major, student.Major, StringComparison.OrdinalIgnoreCase))
                return "Choose an academic supervisor with the same major.";
            if (editingId != null && !records.ContainsKey(editingId)) return "Student no longer exists.";
            if (records.Any(item => item.Key != editingId && (SameEmail(item.Value.Email, student.Email)
                || SameEmail(item.Value.UniEmail, student.UniEmail) || SameEmail(item.Value.Email, student.UniEmail)
                || SameEmail(item.Value.UniEmail, student.Email))))
                return "A student with this login or university email already exists.";
            return null;
        }

        private static bool SameEmail(string first, string second)
        {
            return String.Equals((first ?? "").Trim(), (second ?? "").Trim(), StringComparison.OrdinalIgnoreCase);
        }

        private static string NewPassword()
        {
            byte[] bytes = new byte[12];
            using (var random = RandomNumberGenerator.Create()) random.GetBytes(bytes);
            return "Ua7!" + Convert.ToBase64String(bytes);
        }

        private class AccountResult
        {
            public bool Success { get; set; }
            public string Message { get; set; }
            public string Verification { get; set; }
        }

        private async Task<AccountResult> CreateStudent(StudentModel student, string password)
        {
            string token = null, id = null;
            bool profileSaved = false;
            try
            {
                JObject auth = await AuthenticationRequest(AppConfig.SignUpUrl,
                    new { email = student.Email, password, returnSecureToken = true });
                id = (string)auth["localId"];
                token = (string)auth["idToken"];
                if (String.IsNullOrWhiteSpace(id) || String.IsNullOrWhiteSpace(token)) throw new HttpRequestException();
                student.Role = "Student";
                student.FirstLogin = true;
                student.CompanyId = student.ProfilePicUrl = student.CvUrl = student.PortfolioUrl = "";
                JObject data = JObject.FromObject(student);
                data[EmailVerification.RequiredField] = true;
                using (var response = await FirebaseDb.Put("Students", id, data))
                {
                    if (!response.IsSuccessStatusCode)
                    {
                        await AuthenticationRequest("https://identitytoolkit.googleapis.com/v1/accounts:delete?key=" + AppConfig.ApiKey,
                            new { idToken = token });
                        return new AccountResult { Message = "Profile was rejected; the new login was removed. Check permissions before retrying." };
                    }
                }
                profileSaved = true;
                student.Id = id;
                records[id] = student;
            }
            catch
            {
                return new AccountResult { Message = token == null
                    ? "Could not create the login. The email may already be registered, or the connection failed. Check Authentication before retrying."
                    : "Could not confirm the account save. Ask the coordinator to check Authentication and Students before retrying." };
            }
            string verification = await EmailVerification.RequireAndSend("Students", id, token);
            Notify.AccountCreated(student.Name, "student", student.Email, password);
            return new AccountResult { Success = profileSaved, Verification = verification,
                Message = verification == "sent" ? "Created. Verification email sent; welcome email queued."
                    : "Created. Verification email needs retry at sign-in; welcome email queued." };
        }

        // Preview stays on the server. Confirmation consumes it once, so refreshing cannot add it again.
        public class ImportRow
        {
            public int RowNumber { get; set; }
            public StudentModel Student { get; set; }
            public string Error { get; set; }
            public string Status { get; set; }
        }

        private class ImportDraft
        {
            public string Token { get; set; }
            public DateTime Created { get; set; }
            public List<ImportRow> Rows { get; set; }
        }

        private const string CsvHeader = "FullName,LoginEmail,UniversityEmail,CountryCode,PhoneNumber,Major,GPA,AcademicSupervisorEmail";

        private void DownloadTemplate()
        {
            downloadingTemplate = true;
            Response.Clear();
            Response.ContentType = "text/csv";
            Response.ContentEncoding = Encoding.UTF8;
            Response.AddHeader("Content-Disposition", "attachment; filename=students-template.csv");
            Response.BinaryWrite(Encoding.UTF8.GetPreamble());
            Response.Write(CsvHeader + "\r\n");
            Context.ApplicationInstance.CompleteRequest();
        }

        protected override void Render(HtmlTextWriter writer)
        {
            if (!downloadingTemplate) base.Render(writer);
        }

        protected void PreviewImport(object sender, EventArgs e)
        {
            if (!allowed) return;
            openImport.Value = "1";
            Session.Remove("StudentImportDraft");
            importPreview.Visible = confirmImport.Visible = false;
            try
            {
                if (!importFile.HasFile || !String.Equals(Path.GetExtension(importFile.FileName), ".csv", StringComparison.OrdinalIgnoreCase))
                    throw new FormatException("Choose a CSV file. In Excel, save it as CSV UTF-8 first.");
                if (importFile.PostedFile.ContentLength > 256 * 1024)
                    throw new FormatException("Use a CSV file smaller than 256 KB, with at most 25 students.");
                string text;
                using (var reader = new StreamReader(importFile.FileContent, new UTF8Encoding(false, true), true)) text = reader.ReadToEnd();
                List<string[]> lines = ReadCsv(text);
                if (lines.Count < 2 || !lines[0].SequenceEqual(CsvHeader.Split(','), StringComparer.OrdinalIgnoreCase))
                    throw new FormatException("Use the template headers in the same order, followed by at least one student.");
                var rows = new List<ImportRow>();
                var emails = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                for (int index = 1; index < lines.Count; index++)
                {
                    string[] cells = lines[index];
                    if (cells.Length != 8) throw new FormatException("Row " + (index + 1) + ": expected 8 columns. Use the template.");
                    double grade;
                    if (!Double.TryParse(cells[6], NumberStyles.Number, CultureInfo.InvariantCulture, out grade)) grade = Double.NaN;
                    var matches = supervisors.Values.Where(person => SameEmail(person.Email, cells[7]) || SameEmail(person.UniversityEmail, cells[7])).ToList();
                    var student = new StudentModel { Name = cells[0], Email = cells[1], UniEmail = cells[2],
                        PhoneNumber = (cells[3].StartsWith("+") ? cells[3] : "+" + cells[3]) + cells[4], Major = cells[5], GPA = grade,
                        AcademicSupervisorId = matches.Count == 1 ? matches[0].Id : "" };
                    string error = ValidateStudent(student);
                    if (matches.Count != 1) error = "Supervisor email must match exactly one existing academic supervisor.";
                    if (emails.Contains(student.Email) || emails.Contains(student.UniEmail)) error = "Email is repeated in this file.";
                    emails.Add(student.Email);
                    emails.Add(student.UniEmail);
                    rows.Add(new ImportRow { RowNumber = index + 1, Student = student, Error = error,
                        Status = error ?? "Ready" });
                }
                var draft = new ImportDraft { Token = Guid.NewGuid().ToString("N"), Created = DateTime.UtcNow, Rows = rows };
                importToken.Value = draft.Token;
                Session["StudentImportDraft"] = draft;
                ShowImportRows(rows, false);
            }
            catch (FormatException ex) { ImportMessage(ex.Message); }
            catch (DecoderFallbackException) { ImportMessage("Save the file as CSV UTF-8 in Excel, then upload it again."); }
            catch { ImportMessage("Could not read this file. Use the CSV template and try again."); }
        }

        protected async void ConfirmImport(object sender, EventArgs e)
        {
            if (!allowed) return;
            openImport.Value = "1";
            var draft = Session["StudentImportDraft"] as ImportDraft;
            if (draft == null || draft.Token != importToken.Value || draft.Created < DateTime.UtcNow.AddMinutes(-20))
            {
                importPreview.Visible = confirmImport.Visible = false;
                ImportMessage("This preview expired or was already used. Upload the file again.");
                return;
            }
            // Recheck fresh database data before creating any accounts.
            foreach (ImportRow row in draft.Rows)
            {
                row.Error = row.Error ?? ValidateStudent(row.Student);
                row.Status = row.Error ?? "Ready";
            }
            if (draft.Rows.Any(row => row.Error != null)) { ShowImportRows(draft.Rows, false); return; }
            Session.Remove("StudentImportDraft");
            foreach (ImportRow row in draft.Rows)
            {
                AccountResult result = await CreateStudent(row.Student, NewPassword());
                row.Error = result.Success ? null : result.Message;
                row.Status = result.Message;
            }
            ShowImportRows(draft.Rows, true);
        }

        private void ShowImportRows(List<ImportRow> rows, bool completed)
        {
            importPreview.Visible = true;
            importRows.DataSource = rows;
            importRows.DataBind();
            int failed = rows.Count(row => row.Error != null);
            importSummary.Text = completed ? (rows.Count - failed) + " created · " + failed + " not created. Do not re-import successful rows."
                : rows.Count + " students · " + failed + " rows need correction. No accounts have been created yet.";
            confirmImport.Visible = !completed && failed == 0;
        }

        private void ImportMessage(string text)
        {
            importNotice.Visible = true;
            importMessage.Text = text;
        }

        // Commas (or Excel's semicolons), quoted fields, escaped quotes and line breaks.
        private static List<string[]> ReadCsv(string text)
        {
            char separator = text.Split('\n')[0].Contains(";") ? ';' : ',';
            var rows = new List<string[]>();
            var cells = new List<string>();
            var field = new StringBuilder();
            bool quoted = false, closedQuote = false;
            text = text.TrimStart('\uFEFF') + "\n";
            for (int index = 0; index < text.Length; index++)
            {
                char letter = text[index];
                if (quoted)
                {
                    if (letter != '"') field.Append(letter);
                    else if (index + 1 < text.Length && text[index + 1] == '"') { field.Append('"'); index++; }
                    else { quoted = false; closedQuote = true; }
                    continue;
                }
                if (letter == '"' && field.Length == 0 && !closedQuote) { quoted = true; continue; }
                if (letter == separator || letter == '\r' || letter == '\n')
                {
                    cells.Add(field.ToString().Trim());
                    field.Clear();
                    closedQuote = false;
                    if (cells.Count > 8) throw new FormatException("Each row must contain the 8 template columns.");
                    if (letter == separator) continue;
                    if (letter == '\r' && index + 1 < text.Length && text[index + 1] == '\n') index++;
                    if (cells.Any(cell => cell != "")) rows.Add(cells.ToArray());
                    cells.Clear();
                    if (rows.Count > 26) throw new FormatException("Import at most 25 students at a time.");
                }
                else
                {
                    if (letter == '"' || (closedQuote && !Char.IsWhiteSpace(letter))) throw new FormatException("Invalid CSV quotes. Save the file as CSV UTF-8 in Excel.");
                    if (!closedQuote) field.Append(letter);
                }
            }
            if (quoted) throw new FormatException("A quoted CSV field was not closed.");
            return rows;
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
