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
            addCompany.NavigateUrl = "ManageCompanySupervisors.aspx?add=1&q=" + Server.UrlEncode(companySearch.Text);
            // This event requests a partial update. The filtering below runs in C#.
            companySearch.Attributes["oninput"] = "clearTimeout(window.companySearchTimer);window.companySearchTimer=setTimeout(function(){__doPostBack('"
                + companySearch.UniqueID + "','');},300);";
        }

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
            page = resetPage ? 1 : Math.Max(1, Math.Min(page, (rows.Count + 7) / 8));
            companies.DataSource = rows.Skip((page - 1) * 8).Take(8);
            companies.DataBind();
            companyCount.Text = accounts.Count.ToString();
            emptyDirectory.Visible = rows.Count == 0;
            pageSummary.Text = rows.Count == 0 ? "0 results" : "Page " + page + " of " + ((rows.Count + 7) / 8) + " · " + rows.Count + " results";
            previousPage.Visible = page > 1;
            nextPage.Visible = page * 8 < rows.Count;
            previousPage.NavigateUrl = "ManageCompanySupervisors.aspx?page=" + (page - 1) + "&q=" + Server.UrlEncode(companySearch.Text);
            nextPage.NavigateUrl = "ManageCompanySupervisors.aspx?page=" + (page + 1) + "&q=" + Server.UrlEncode(companySearch.Text);
        }

        protected void SearchChanged(object sender, EventArgs e) { resetPage = true; }

        protected string AccountStatus(string id)
        {
            if (disabledAccounts == null) return "Not checked";
            if (!disabledAccounts.ContainsKey(id)) return "No login linked";
            return disabledAccounts[id] ? "Inactive" : "Active";
        }

        protected bool CanToggle(string id) { return disabledAccounts != null && disabledAccounts.ContainsKey(id); }

        protected string AccountUrl(string id, bool toggle)
        {
            if (toggle && !CanToggle(id)) return "";
            return "ManageCompanySupervisors.aspx?" + (toggle ? "toggle=" : "edit=") + Server.UrlEncode(id)
                + (toggle ? "&disable=" + (disabledAccounts[id] ? "0" : "1") : "") + "&q=" + Server.UrlEncode(companySearch.Text);
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
            phoneNumber.Text = phone.StartsWith("+9627") && phone.Length == 13 ? "0" + phone.Substring(4) : phone;
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

        protected async void SaveClick(object sender, EventArgs e)
        {
            if (!allowed) return;
            openEditor.Value = "1";
            var person = new CompanySupervisor
            {
                Name = supervisorName.Text.Trim(), Email = loginEmail.Text.Trim(),
                CompanyName = companyName.Text.Trim(), CompEmail = loginEmail.Text.Trim(),
                Location = companyLocation.Text.Trim(), PhoneNumber = phoneNumber.Text.Trim(),
                Role = "CompanySupervisor", FirstLogin = true, ProfilePicUrl = ""
            };
            if (person.Name.Length < 2 || person.Name.Length > 100 || person.CompanyName.Length < 2 || person.CompanyName.Length > 150
                || person.Location.Length < 2 || person.Location.Length > 200 || !ValidEmail(person.Email))
            {
                ShowMessage("Enter a name, company, location and a valid company email.");
                return;
            }
            if (!Regex.IsMatch(person.PhoneNumber, @"\A07[0-9]{8}\z"))
            {
                ShowMessage("Enter a 10-digit mobile number starting with 07, for example 0791234567.");
                return;
            }
            string id = EditingId;
            if (id != null && !accounts.ContainsKey(id)) { ShowMessage("This account no longer exists."); return; }
            if (accounts.Any(item => item.Key != id && String.Equals(item.Value.Email, person.Email, StringComparison.OrdinalIgnoreCase)))
            {
                ShowMessage("A supervisor with this login email already exists.");
                return;
            }
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
