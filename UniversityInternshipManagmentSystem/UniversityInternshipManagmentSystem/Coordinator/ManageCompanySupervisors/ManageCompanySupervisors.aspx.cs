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

namespace UniversityInternshipManagmentSystem.Coordinator
{
    public partial class ManageCompanySupervisorsPage : Page
    {
        protected Panel workspace, messagePanel, emptyDirectory, editorPanel, editorNotice, passwordSection, savedPanel, confirmPanel;
        protected Literal message, companyCount, editorHeading, editorMessage, savedMessage, confirmMessage, pageSummary;
        protected Repeater companies;
        protected TextBox companySearch, supervisorName, loginEmail, phoneNumber, companyName, companyEmail, companyLocation, temporaryPassword;
        protected Button saveButton, searchButton;
        protected HyperLink addCompany, previousPage, nextPage;
        protected HiddenField openEditor;
        private Dictionary<string, CompanySupervisor> accounts;
        private Dictionary<string, bool> disabledAccounts;
        private string EditingId { get; set; }
        private bool allowed, resetPage;
        private const string PageUrl = "ManageCompanySupervisors.aspx";

        protected void Page_Init(object sender, EventArgs e)
        {
            ViewStateUserKey = Session.SessionID;
        }

        // Check coordinator access and load company supervisors from Firebase.
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
            companyEmail.ReadOnly = EditingId != null;
            openEditor.Value = "0";
            messagePanel.Visible = editorNotice.Visible = false;
            if (String.IsNullOrWhiteSpace(AuthHelper.IdToken) || AuthHelper.IdToken == "mock-token")
            {
                ShowMessage("Sign in with a real coordinator account.");
                return;
            }
            try
            {
                string json = await FirebaseDb.Get("CompanySupervisors");
                if (json == null) throw new HttpRequestException();
                accounts = JsonConvert.DeserializeObject<Dictionary<string, CompanySupervisor>>(json)
                    ?? new Dictionary<string, CompanySupervisor>();
                foreach (var item in accounts) item.Value.Id = item.Key;
                allowed = workspace.Visible = addCompany.Visible = true;
                // Reuse this page's status snapshot while typing; a status change is checked again in Authentication.
                disabledAccounts = ViewState["LoginStates"] as Dictionary<string, bool>;
                if (IsPostBack) return;
                await LoadAccountStates();
                companySearch.Text = Request.QueryString["q"] ?? "";
                if (EditingId != null || Request.QueryString["add"] == "1") OpenEditor();
                string toggleId = Request.QueryString["toggle"];
                if (toggleId != null && accounts.ContainsKey(toggleId) && CanToggle(toggleId))
                {
                    confirmPanel.Visible = true;
                    confirmMessage.Text = (Request.QueryString["disable"] == "1" ? "Deactivate " : "Activate ")
                        + accounts[toggleId].Name + "? Inactive accounts cannot sign in.";
                }
                if (Request.QueryString["saved"] == "1")
                    ShowSuccess("Company supervisor saved successfully." + EmailVerification.MessageFor(Request.QueryString["verify"]) + Notify.AccountMailMessage(Request.QueryString["mail"]));
                if (Request.QueryString["status"] == "inactive") ShowSuccess("Account deactivated. The supervisor cannot sign in.");
                if (Request.QueryString["status"] == "active") ShowSuccess("Account activated. The supervisor can sign in again.");
            }
            catch
            {
                allowed = workspace.Visible = addCompany.Visible = editorPanel.Visible = false;
                ShowMessage("Could not load company accounts. Check the connection or sign in again.");
            }
        }

        protected void Page_PreRender(object sender, EventArgs e)
        {
            if (!allowed) return;
            BindCompanies();
            addCompany.NavigateUrl = DirectoryUrl() + "&add=1";
            // This event requests a partial update. The filtering below runs in C#.
            companySearch.Attributes["oninput"] = "clearTimeout(window.companySearchTimer);window.companySearchTimer=setTimeout(function(){__doPostBack('"
                + companySearch.UniqueID + "','');},300);";
        }

        // Search the loaded accounts, then show eight results per page.
        private void BindCompanies()
        {
            var rows = new List<CompanySupervisor>();
            string query = companySearch.Text.Trim();
            foreach (var person in accounts.Values.OrderBy(item => item.CompanyName))
            {
                string text = String.Join(" ", person.Name, person.CompanyName, person.Email, person.CompEmail);
                if (text.IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0) rows.Add(person);
            }
            int page;
            Int32.TryParse(Request.QueryString["page"], out page);
            int totalPages = (int)Math.Ceiling(rows.Count / 8.0);
            if (page > totalPages) page = totalPages;
            if (page < 1 || resetPage) page = 1;
            companies.DataSource = rows.Skip((page - 1) * 8).Take(8);
            companies.DataBind();
            companyCount.Text = accounts.Count.ToString();
            emptyDirectory.Visible = rows.Count == 0;
            pageSummary.Text = rows.Count == 0 ? "0 results" : "Page " + page + " of " + totalPages + " · " + rows.Count + " results";
            previousPage.Visible = page > 1;
            nextPage.Visible = page * 8 < rows.Count;
            previousPage.NavigateUrl = DirectoryUrl() + "&page=" + (page - 1);
            nextPage.NavigateUrl = DirectoryUrl() + "&page=" + (page + 1);
        }

        protected void SearchChanged(object sender, EventArgs e) { resetPage = true; }

        protected string AccountStatus(string id)
        {
            if (disabledAccounts == null) return "Not checked";
            if (!disabledAccounts.ContainsKey(id)) return "No login linked";
            return disabledAccounts[id] ? "Inactive" : "Active";
        }

        protected bool CanToggle(string id) { return disabledAccounts != null && disabledAccounts.ContainsKey(id); }

        // Edit opens the form; Activate/Deactivate opens the confirmation window.
        protected string AccountUrl(string id, bool toggle)
        {
            if (!toggle) return DirectoryUrl() + "&edit=" + Server.UrlEncode(id);
            if (!CanToggle(id)) return "";
            string disable = disabledAccounts[id] ? "0" : "1";
            return DirectoryUrl() + "&toggle=" + Server.UrlEncode(id) + "&disable=" + disable;
        }

        // Keep the search when opening a form or moving between result pages.
        private string DirectoryUrl()
        {
            return PageUrl + "?q=" + Server.UrlEncode(companySearch.Text);
        }

        private async Task LoadAccountStates()
        {
            try
            {
                if (!CompanyAccountAccess.IsConfigured) throw new InvalidOperationException();
                disabledAccounts = await CompanyAccountAccess.GetDisabledAccounts(accounts.Keys.ToArray());
                ViewState["LoginStates"] = disabledAccounts;
            }
            catch { ShowMessage("Sign-in status is unavailable. Check the Firebase admin key on this computer."); }
        }

        // Add generates a password; Edit fills the same form with saved details.
        private void OpenEditor()
        {
            if (EditingId != null && !accounts.ContainsKey(EditingId)) { ShowMessage("This account no longer exists."); return; }
            editorPanel.Visible = true;
            openEditor.Value = "1";
            if (EditingId == null) { GeneratePassword(null, EventArgs.Empty); return; }
            var person = accounts[EditingId];
            supervisorName.Text = person.Name;
            loginEmail.Text = person.Email;
            loginEmail.ReadOnly = true;
            string phone = person.PhoneNumber ?? "";
            if (phone.StartsWith("+9627") && phone.Length == 13) phone = "0" + phone.Substring(4);
            phoneNumber.Text = phone;
            companyName.Text = person.CompanyName;
            companyEmail.Text = person.CompEmail;
            companyLocation.Text = person.Location;
            passwordSection.Visible = false;
            editorHeading.Text = "Edit company supervisor";
            saveButton.Text = "Save changes";
        }

        protected void GeneratePassword(object sender, EventArgs e)
        {
            if (!allowed) return;
            byte[] bytes = new byte[12];
            using (var random = RandomNumberGenerator.Create()) random.GetBytes(bytes);
            temporaryPassword.Text = "Ua7!" + Convert.ToBase64String(bytes);
            openEditor.Value = "1";
        }

        protected async void ConfirmToggle(object sender, EventArgs e)
        {
            confirmPanel.Visible = false;
            string id = Request.QueryString["toggle"];
            if (!allowed || id == null || !accounts.ContainsKey(id) || !CompanyAccountAccess.IsConfigured) return;
            try
            {
                var current = await CompanyAccountAccess.GetDisabledAccounts(new[] { id });
                if (!current.ContainsKey(id)) { ShowMessage("No Authentication account is linked to this record."); return; }
                bool disable = Request.QueryString["disable"] == "1";
                if (current[id] != disable)
                {
                    await CompanyAccountAccess.SetDisabled(id, disable);
                    Notify.AccountStatusChanged(accounts[id].Name, accounts[id].Email, disable);
                }
                Response.Redirect("ManageCompanySupervisors.aspx?status=" + (disable ? "inactive" : "active"), false);
                Context.ApplicationInstance.CompleteRequest();
            }
            catch { ShowMessage("Account status could not be updated. Reload the directory to check its current status."); }
        }

        // Read the form, validate it, then use the existing create/update flow.
        protected async void SaveClick(object sender, EventArgs e)
        {
            if (!allowed) return;
            openEditor.Value = "1";
            if (EditingId == null && !String.Equals(loginEmail.Text.Trim(), companyEmail.Text.Trim(), StringComparison.OrdinalIgnoreCase))
            {
                ShowMessage("The email addresses do not match. Re-enter the same email address.");
                return;
            }
            var person = new CompanySupervisor
            {
                Name = supervisorName.Text.Trim(), Email = loginEmail.Text.Trim(),
                CompanyName = companyName.Text.Trim(), CompEmail = loginEmail.Text.Trim(),
                Location = companyLocation.Text.Trim(), PhoneNumber = phoneNumber.Text.Trim(),
                Role = "CompanySupervisor", FirstLogin = true, ProfilePicUrl = ""
            };
            string id = EditingId;
            string error = ValidateCompany(person, id);
            if (error != null) { ShowMessage(error); return; }
            string newAccountToken = null, verifyResult = null, mailResult = null;
            try
            {
                if (id == null)
                {
                    if (temporaryPassword.Text.Length < 12) { ShowMessage("Generate a temporary password before saving."); return; }
                    var auth = await AuthenticationRequest(AppConfig.SignUpUrl,
                        new { email = person.Email, password = temporaryPassword.Text, returnSecureToken = true });
                    id = (string)auth["localId"];
                    newAccountToken = (string)auth["idToken"];
                    using (var response = await FirebaseDb.Put("CompanySupervisors", id, person))
                        if (!response.IsSuccessStatusCode) throw new HttpRequestException();
                    verifyResult = await EmailVerification.RequireAndSend("CompanySupervisors", id, newAccountToken);
                    mailResult = await Notify.AccountCreated(person.Name, "company", person.Email, temporaryPassword.Text);
                }
                else
                {
                    // Preserve the role, FirstLogin and fields maintained by other pages.
                    var changes = new { person.Name, person.PhoneNumber, person.CompanyName, person.CompEmail, person.Location };
                    using (var response = await FirebaseDb.Patch("CompanySupervisors", id, changes))
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
                ShowMessage("Could not save the account. Check email availability and Firebase permissions.");
                return;
            }
            Response.Redirect("ManageCompanySupervisors.aspx?saved=1" + (verifyResult == null ? "" : "&verify=" + verifyResult) + (mailResult == null ? "" : "&mail=" + mailResult), false);
            Context.ApplicationInstance.CompleteRequest();
        }

        // Check the form before creating or updating any account.
        private string ValidateCompany(CompanySupervisor person, string id)
        {
            string detailsError = "Enter a name, company, location and a valid company email.";
            if (person.Name.Length < 2 || person.Name.Length > 100) return detailsError;
            if (person.CompanyName.Length < 2 || person.CompanyName.Length > 150) return detailsError;
            if (person.Location.Length < 2 || person.Location.Length > 200) return detailsError;
            if (!ValidEmail(person.Email)) return detailsError;
            if (!Regex.IsMatch(person.PhoneNumber, @"\A07[0-9]{8}\z"))
                return "Enter a 10-digit mobile number starting with 07, for example 0791234567.";
            if (id != null && !accounts.ContainsKey(id)) return "This account no longer exists.";
            foreach (var account in accounts)
            {
                if (account.Key == id) continue;
                if (String.Equals(account.Value.Email, person.Email, StringComparison.OrdinalIgnoreCase))
                    return "A supervisor with this login email already exists.";
            }
            return null;
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
            if (openEditor.Value == "1" && editorPanel.Visible) { editorNotice.Visible = true; editorMessage.Text = text; }
            else { messagePanel.Visible = true; message.Text = text; }
        }

        private void ShowSuccess(string text) { savedPanel.Visible = true; savedMessage.Text = text; }
    }
}
