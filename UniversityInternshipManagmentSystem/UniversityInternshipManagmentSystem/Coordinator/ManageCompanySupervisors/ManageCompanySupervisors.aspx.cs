using System;
using System.Collections.Generic;
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

namespace UniversityInternshipManagmentSystem.Coordinator
{
    public partial class ManageCompanySupervisorsPage : Page
    {
        protected Panel messagePanel, workspace, emptyDirectory, passwordSection, editorPanel;
        protected Literal message, companyCount, editorHeading;
        protected Repeater companies;
        protected TextBox companySearch, supervisorName, loginEmail, phoneNumber;
        protected TextBox companyName, companyEmail, companyLocation, temporaryPassword;
        protected Button saveButton, searchButton;
        protected LinkButton addCompany;

        private Dictionary<string, CompanySupervisor> accounts;
        private bool allowed;
        private bool canManageLogins;
        private Dictionary<string, bool> disabledAccounts = new Dictionary<string, bool>();
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
                ShowMessage("Use a real coordinator account to manage Firebase accounts.", true);
                return;
            }
            try
            {
                string json = await FirebaseDb.Get("CompanySupervisors");
                if (json == null) throw new HttpRequestException();
                accounts = JsonConvert.DeserializeObject<Dictionary<string, CompanySupervisor>>(json)
                    ?? new Dictionary<string, CompanySupervisor>();
                foreach (var item in accounts) item.Value.Id = item.Key;
                allowed = true;
                workspace.Visible = addCompany.Visible = true;
                await LoadAccountStates();
                BindCompanies();
                if (!IsPostBack && Request.QueryString["saved"] == "1")
                    ShowMessage("Company supervisor saved to Firebase successfully." + EmailVerification.MessageFor(Request.QueryString["verify"]));
            }
            catch
            {
                ShowMessage("Could not load company accounts. Sign in again or check the database connection and permissions.", true);
            }
        }

        private void BindCompanies()
        {
            string query = companySearch.Text.Trim();
            var filtered = accounts.Values.Where(person => String.IsNullOrEmpty(query)
                || (person.Name ?? "").IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0
                || (person.CompanyName ?? "").IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0
                || (person.Email ?? "").IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0
                || (person.CompEmail ?? "").IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0)
                .OrderBy(person => person.CompanyName).ToList();
            companies.DataSource = filtered.Select(person => new
            {
                person.Id, person.CompanyName, person.Location, person.Name,
                person.Email, person.CompEmail, person.PhoneNumber,
                StatusText = !canManageLogins ? "Not checked" : !disabledAccounts.ContainsKey(person.Id)
                    ? "No login linked" : disabledAccounts[person.Id] ? "Inactive" : "Active",
                StatusClass = !canManageLogins || !disabledAccounts.ContainsKey(person.Id) ? "badge badge-pending"
                    : disabledAccounts[person.Id] ? "badge badge-rejected" : "badge badge-approved",
                CanToggle = canManageLogins && disabledAccounts.ContainsKey(person.Id),
                ToggleText = !canManageLogins || !disabledAccounts.ContainsKey(person.Id) ? "Unavailable"
                    : disabledAccounts[person.Id] ? "Activate" : "Deactivate",
                ToggleClass = "btn btn-sm " + (disabledAccounts.ContainsKey(person.Id) && !disabledAccounts[person.Id]
                    ? "company-disable" : "btn-outline-primary")
            });
            companies.DataBind();
            companyCount.Text = accounts.Count.ToString();
            emptyDirectory.Visible = filtered.Count == 0;
        }

        protected void SearchClick(object sender, EventArgs e)
        {
            if (!allowed) return;
            BindCompanies();
            companySearch.Focus();
        }

        protected void AddClick(object sender, EventArgs e)
        {
            if (!allowed) return;
            CancelClick(sender, e);
            editorPanel.Visible = true;
            supervisorName.Focus();
        }

        private async Task LoadAccountStates()
        {
            canManageLogins = false;
            if (!CompanyAccountAccess.IsConfigured)
            {
                ShowMessage("Account activation needs the Firebase admin key configured on this computer.");
                return;
            }
            try
            {
                disabledAccounts = await CompanyAccountAccess.GetDisabledAccounts(accounts.Keys.ToArray());
                canManageLogins = true;
            }
            catch
            {
                ShowMessage("Sign-in status could not be checked. Verify the admin key and its Authentication permissions.", true);
            }
        }

        private async Task ToggleAccount(string id)
        {
            if (!allowed || !accounts.ContainsKey(id) || !CompanyAccountAccess.IsConfigured) return;
            try
            {
                var current = await CompanyAccountAccess.GetDisabledAccounts(new[] { id });
                if (!current.ContainsKey(id))
                {
                    ShowMessage("No Authentication account is linked to this record.", true);
                    return;
                }
                bool disable = !current[id];
                await CompanyAccountAccess.SetDisabled(id, disable);
                Notify.AccountStatusChanged(accounts[id].Name, accounts[id].Email, disable);
                await LoadAccountStates();
                BindCompanies();
                ShowMessage(disable ? "Account deactivated. The supervisor cannot sign in."
                    : "Account activated. The supervisor can sign in again.");
            }
            catch
            {
                ShowMessage("Account status could not be updated. Reload the directory to check its current status.", true);
            }
        }

        protected void CompaniesCommand(object sender, RepeaterCommandEventArgs e)
        {
            if (!allowed) return;
            if (e.CommandName == "ToggleLogin")
            {
                RegisterAsyncTask(new PageAsyncTask(() => ToggleAccount(Convert.ToString(e.CommandArgument))));
                return;
            }
            if (e.CommandName != "EditCompany") return;
            CompanySupervisor person;
            if (!accounts.TryGetValue(Convert.ToString(e.CommandArgument), out person)) return;
            editorPanel.Visible = true;
            EditingId = person.Id;
            supervisorName.Text = person.Name;
            loginEmail.Text = person.Email;
            loginEmail.ReadOnly = true;
            phoneNumber.Text = person.PhoneNumber;
            companyName.Text = person.CompanyName;
            companyEmail.Text = person.CompEmail;
            companyLocation.Text = person.Location;
            passwordSection.Visible = false;
            editorHeading.Text = "Edit company supervisor";
            saveButton.Text = "Save changes";
            supervisorName.Focus();
        }

        protected async void SaveClick(object sender, EventArgs e)
        {
            if (!allowed) return;
            string name = supervisorName.Text.Trim(), email = loginEmail.Text.Trim();
            string company = companyName.Text.Trim(), contactEmail = companyEmail.Text.Trim();
            string location = companyLocation.Text.Trim(), phone = phoneNumber.Text.Trim();
            if (name.Length < 2 || name.Length > 100 || company.Length < 2 || company.Length > 150
                || location.Length < 2 || location.Length > 200 || !ValidEmail(email) || !ValidEmail(contactEmail)
                || !Regex.IsMatch(phone, @"^\+?[0-9 ()-]{7,25}$"))
            {
                ShowMessage("Enter a name, company, location, valid emails and phone number.", true);
                return;
            }
            string id = EditingId;
            if (id != null && !accounts.ContainsKey(id))
            {
                ShowMessage("This account no longer exists. Reload the directory.", true);
                return;
            }
            if (accounts.Any(item => item.Key != id && String.Equals(item.Value.Email, email, StringComparison.OrdinalIgnoreCase)))
            {
                ShowMessage("A supervisor with this login email already exists.", true);
                return;
            }
            if (id == null && temporaryPassword.Text.Length < 12)
            {
                ShowMessage("Use a temporary password of at least 12 characters.", true);
                return;
            }

            string newAccountToken = null;
            string verifyResult = null;
            try
            {
                if (id == null)
                {
                    var data = new { email = email, password = temporaryPassword.Text, returnSecureToken = true };
                    var auth = await AuthenticationRequest(AppConfig.SignUpUrl, data);
                    id = (string)auth["localId"];
                    newAccountToken = (string)auth["idToken"];
                    var person = new CompanySupervisor(name, email, true, phone, "", company, contactEmail, location);
                    using (var response = await FirebaseDb.Put("CompanySupervisors", id, person))
                    {
                        if (!response.IsSuccessStatusCode) throw new HttpRequestException();
                    }
                    verifyResult = await EmailVerification.RequireAndSend("CompanySupervisors", id, newAccountToken);
                    Notify.AccountCreated(name, "company", email, temporaryPassword.Text);
                }
                else
                {
                    // Patch only editable fields; preserve role, FirstLogin and other teammates' fields.
                    var changes = new { Name = name, PhoneNumber = phone, CompanyName = company, CompEmail = contactEmail, Location = location };
                    using (var response = await FirebaseDb.Patch("CompanySupervisors", id, changes))
                    {
                        if (!response.IsSuccessStatusCode) throw new HttpRequestException();
                    }
                }
            }
            catch
            {
                if (newAccountToken != null)
                {
                    try
                    {
                        await AuthenticationRequest("https://identitytoolkit.googleapis.com/v1/accounts:delete?key=" + AppConfig.ApiKey,
                            new { idToken = newAccountToken });
                    }
                    catch
                    {
                        ShowMessage("Login account created, but the profile could not be confirmed. Check Firebase Authentication before retrying.", true);
                        return;
                    }
                }
                ShowMessage("Could not save the account. Check email availability, the password policy and Firebase permissions.", true);
                return;
            }
            // Refresh only after the write succeeded; never delete a created login because a refresh failed.
            Response.Redirect(Request.AppRelativeCurrentExecutionFilePath + "?saved=1" + (verifyResult == null ? "" : "&verify=" + verifyResult), false);
            Context.ApplicationInstance.CompleteRequest();
        }

        protected void CancelClick(object sender, EventArgs e)
        {
            if (!allowed) return;
            editorPanel.Visible = false;
            EditingId = null;
            supervisorName.Text = loginEmail.Text = phoneNumber.Text = companyName.Text = companyEmail.Text = companyLocation.Text = temporaryPassword.Text = "";
            loginEmail.ReadOnly = false;
            passwordSection.Visible = true;
            editorHeading.Text = "Add company supervisor";
            saveButton.Text = "Create account";
        }

        private static bool ValidEmail(string value)
        {
            try { return value.Length <= 254 && new MailAddress(value).Address == value; }
            catch { return false; }
        }

        private static async Task<JObject> AuthenticationRequest(string url, object data)
        {
            string json = JsonConvert.SerializeObject(data);
            using (var response = await FirebaseDb.client.PostAsync(url, new StringContent(json, Encoding.UTF8, "application/json")))
            {
                if (!response.IsSuccessStatusCode) throw new HttpRequestException();
                return JObject.Parse(await response.Content.ReadAsStringAsync());
            }
        }

        private void ShowMessage(string text, bool error = false)
        {
            messagePanel.Visible = true;
            messagePanel.CssClass = error ? "company-preview company-error" : "company-preview";
            message.Text = text;
        }
    }
}
