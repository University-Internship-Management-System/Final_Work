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
public partial class CoordinatorAcademicAccounts : Page
{
    // Page controls are declared here so this feature does not need a separate designer file.
    protected Panel notice;
    protected Literal noticeText;
    protected Panel workspace;
    protected Literal total;
    protected Repeater directory;
    protected Label emptyDirectory;
    protected Literal editorTitle;
    protected TextBox fullName;
    protected TextBox email;
    protected TextBox universityEmail;
    protected DropDownList major;
    protected TextBox phone;
    protected Panel passwordArea;
    protected TextBox temporaryPassword;
    protected Button save;
    protected System.Web.UI.HtmlControls.HtmlAnchor addSupervisor;
    private Dictionary<string, AcademicSupervisor> records = new Dictionary<string, AcademicSupervisor>();
    private bool allowed;
    private string EditingId { get { return ViewState["EditingId"] as string; } set { ViewState["EditingId"] = value; } }
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

        await LoadAccounts();
    }
    private void Tell(string message, bool error = false)
    {
        notice.Visible = true;
        notice.CssClass = "academic-notice" + (error ? " error" : "");
        noticeText.Text = message;
    }
    private async Task LoadAccounts()
    {
        try
        {
            if (!String.Equals(Session["role"] as string, "coordinator", StringComparison.OrdinalIgnoreCase))
            {
                Tell("Sign in as the coordinator to manage academic supervisor accounts.");
                return;
            }
            var json = await ReadNode("AcademicSupervisors");
            records = json == null
                ? new Dictionary<string, AcademicSupervisor>()
                : json.ToObject<Dictionary<string, AcademicSupervisor>>();
            allowed = true;
            workspace.Visible = true;
            addSupervisor.Visible = true;
            foreach (var item in records) item.Value.Id = item.Key;
            BindDirectory();
        }
        catch (Exception)
        {
            allowed = false;
            workspace.Visible = false;
            addSupervisor.Visible = false;
            Tell("Firebase could not load the accounts. Check the connection and database permissions.", true);
        }
    }
    private void BindDirectory()
    {
        directory.DataSource = records.Values.OrderBy(x => x.Name).ToList();
        directory.DataBind();
        total.Text = records.Count.ToString();
        emptyDirectory.Visible = records.Count == 0;
    }
    protected void DirectoryCommand(object sender, RepeaterCommandEventArgs e)
    {
        if (!allowed || e.CommandName != "EditSupervisor") return;

        AcademicSupervisor person;
        string id = Convert.ToString(e.CommandArgument);
        if (!records.TryGetValue(id, out person))
        {
            Tell("Supervisor no longer exists. Reload the directory.", true);
            return;
        }

        EditingId = id;
        fullName.Text = person.Name;
        email.Text = person.Email;
        email.ReadOnly = true;
        universityEmail.Text = person.UniversityEmail;
        phone.Text = person.PhoneNumber;
        major.SelectedIndex = 0;
        if (major.Items.FindByValue(person.Major) != null)
            major.SelectedValue = person.Major;
        passwordArea.Visible = false;
        editorTitle.Text = "Edit supervisor";
        save.Text = "Save changes";
    }
    private static bool ValidEmail(string value)
    {
        try { return !String.IsNullOrWhiteSpace(value) && value.Length <= 254 && new MailAddress(value).Address == value; }
        catch { return false; }
    }
    protected void SaveClick(object sender, EventArgs e)
    {
        RegisterAsyncTask(new PageAsyncTask(async () =>
        {
            try { await SaveAccount(); }
            catch { Tell("Unable to save right now. Check the Firebase connection and reload the page before retrying.", true); }
        }));
    }
    private async Task SaveAccount()
    {
        if (!allowed) { Tell("A coordinator login is required.", true); return; }
        Page.Validate("Supervisor");
        string name = fullName.Text.Trim(), login = email.Text.Trim(), uni = universityEmail.Text.Trim(), phoneValue = phone.Text.Trim();
        if (!Page.IsValid || name.Length < 2 || name.Length > 100 || !ValidEmail(login) || !ValidEmail(uni) || String.IsNullOrWhiteSpace(major.SelectedValue)
            || !Regex.IsMatch(phoneValue, @"^\+?[0-9 ()-]{7,25}$"))
        { Tell("Enter a name, valid login and university emails, an available major, and a valid phone number.", true); return; }
        string id = EditingId;
        AcademicSupervisor existing = null;
        if (id != null && !records.TryGetValue(id, out existing)) { Tell("This supervisor no longer exists. Reload the page.", true); return; }
        if (existing != null && !String.Equals(existing.Major, major.SelectedValue, StringComparison.OrdinalIgnoreCase))
        {
            var students = await ReadNode("Students") as JObject;
            bool assigned = students != null && students.Properties()
                .Any(p => (string)p.Value["AcademicSupervisorId"] == id);
            if (assigned) { Tell("Reassign this supervisor's students before changing their major.", true); return; }
        }
        if (records.Any(x => x.Key != id && (String.Equals(x.Value.Email, login, StringComparison.OrdinalIgnoreCase) || String.Equals(x.Value.UniversityEmail, uni, StringComparison.OrdinalIgnoreCase))))
        { Tell("A supervisor with this email already exists.", true); return; }
        if (existing == null && temporaryPassword.Text.Length < 12) { Tell("Use a temporary password of at least 12 characters.", true); return; }
        var person = new AcademicSupervisor(name, existing == null ? login : existing.Email,
            existing == null || existing.FirstLogin, phoneValue, existing == null ? "" : existing.ProfilePicUrl, uni, major.SelectedValue);
        string createdToken = null;
        try
        {
            if (id == null)
            {
                var auth = await AuthRequest(AppConfig.SignUpUrl,
                    new { email = login, password = temporaryPassword.Text, returnSecureToken = true });
                id = (string)auth["localId"];
                createdToken = (string)auth["idToken"];
            }
            using (var response = await FirebaseDb.Put("AcademicSupervisors", id, person))
                if (!response.IsSuccessStatusCode)
                    throw new HttpRequestException("Firebase could not save the supervisor profile.");
            person.Id = id;
            records[id] = person;
            ResetEditor();
            BindDirectory();
            Tell("Supervisor account saved to Firebase successfully.");
        }
        catch (Exception)
        {
            bool cleaned = true;
            if (createdToken != null)
            {
                try { await AuthRequest("https://identitytoolkit.googleapis.com/v1/accounts:delete?key=" + AppConfig.ApiKey, new { idToken = createdToken }); }
                catch { cleaned = false; }
            }
            Tell(cleaned ? "Account could not be saved. Check email availability, password policy and Firebase permissions, then retry."
                : "The login account was created but its profile could not be saved. Ask the authentication owner to check Firebase Authentication before retrying.", true);
        }
    }
    protected void CancelClick(object sender, EventArgs e)
    {
        ResetEditor();
    }
    private void ResetEditor()
    {
        EditingId = null;
        fullName.Text = email.Text = universityEmail.Text = phone.Text = temporaryPassword.Text = "";
        email.ReadOnly = false;
        major.SelectedIndex = 0;
        passwordArea.Visible = true;
        editorTitle.Text = "Add supervisor";
        save.Text = "Create account";
    }
    private async Task<JToken> ReadNode(string table)
    {
        string json = await FirebaseDb.Get(table);
        var value = JToken.Parse(json);
        return value.Type == JTokenType.Null ? null : value;
    }
    private static StringContent JsonContent(object data) { return new StringContent(JsonConvert.SerializeObject(data), Encoding.UTF8, "application/json"); }
    private static async Task<JObject> AuthRequest(string url, object data)
    {
        using (var response = await FirebaseDb.client.PostAsync(url, JsonContent(data)))
        {
            response.EnsureSuccessStatusCode();
            return JObject.Parse(await response.Content.ReadAsStringAsync());
        }
    }
}

}
