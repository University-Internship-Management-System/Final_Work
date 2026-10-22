using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Text.RegularExpressions;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using UniversityInternshipManagmentSystem.Config;
using StudentRecord = UniversityInternshipManagmentSystem.Models.Student;

namespace UniversityInternshipManagmentSystem.Student.StudentProfilePage
{
    public partial class Profile : StudentPage
    {
        private enum ProfileAction { None, Edit, Validate, Save, Cancel }
        private ProfileAction requestedAction;
        private static readonly HttpClient PasswordClient = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };
        protected StudentRecord Record => Workspace;
        protected bool IsEditing
        {
            get { return ViewState["Profile.Editing"] is bool && (bool)ViewState["Profile.Editing"]; }
            private set { ViewState["Profile.Editing"] = value; }
        }
        protected bool CanUpdate => true;
        protected string SafeCvUrl => ProfileValidation.GetSafeWebUrl(Record?.CvUrl);
        protected string SafePortfolioUrl => ProfileValidation.GetSafeWebUrl(Record?.PortfolioUrl);
        protected string SafeAvatarUrl => SafeProfileImage(Record?.ProfilePicUrl);
        protected string CompanyText => string.IsNullOrWhiteSpace(Record?.CompanyId)
            ? "No company assignment recorded" : "Assignment recorded; company details unavailable";
        protected string SupervisorText => string.IsNullOrWhiteSpace(Record?.AcademicSupervisorId)
            ? "No supervisor assignment recorded" : "Assignment recorded; supervisor details unavailable";

        protected override void OnInit(EventArgs e)
        {
            base.OnInit(e);
            PrepareCandidateControls();
        }

        private void PrepareCandidateControls()
        {
            // Accept POST data before async loading. ReadOnly is a rendering decision only.
            // Disabling control ViewState prevents a previous ReadOnly state replacing it.
            foreach (var input in CandidateInputs())
            {
                input.EnableViewState = false;
                input.ReadOnly = false;
            }
        }
        protected void Page_Load(object sender, EventArgs e)
        {
            RegisterAsyncTask(new PageAsyncTask(LoadProfileAsync));
        }
        private async Task LoadProfileAsync()
        {
            await LoadWorkspaceAsync();
            if (Workspace == null)
            {
                IsEditing = false;
                SaveMessage.Text = "";
                ClearFieldErrors();
                BindFields();
                ApplyPermissions();
                return;
            }
            try
            {
                if (requestedAction != ProfileAction.None) ValidateCsrf();
                await ProcessActionAsync();
            }
            catch (UnauthorizedAccessException ex) { SetMessage(ex.Message); }
            catch (StudentDataException ex) { SetMessage(ex.Message); }
            catch (Exception) { SetMessage("The profile action could not be completed. No changes were saved."); }
            ApplyPermissions();
        }
        // Invoked only after the shared Student adapter verifies identity and record ownership.
        private async Task ProcessActionAsync()
        {
            if (Workspace == null) throw new UnauthorizedAccessException("A verified Student account is required.");
            ClearFieldErrors();
            switch (requestedAction)
            {
                case ProfileAction.Edit:
                    IsEditing = true;
                    BindFields();
                    SetMessage("Edit your phone, skills and professional links, then press Save Changes.", false);
                    break;
                case ProfileAction.Cancel:
                    IsEditing = false;
                    BindFields();
                    SetMessage("Unsaved changes discarded. Your current Firebase profile has been reloaded.", false);
                    break;
                case ProfileAction.Validate:
                    if (!IsEditing) throw new UnauthorizedAccessException("Choose Edit Profile before validating changes.");
                    bool valid = ValidateInputs();
                    SetMessage(valid
                        ? "Your entries passed validation. Press Save Changes to save them."
                        : "Correct the highlighted fields. Nothing was saved.", !valid);
                    break;
                case ProfileAction.Save:
                    if (!IsEditing) throw new UnauthorizedAccessException("Choose Edit Profile before saving changes.");
                    if (!ValidateInputs())
                    {
                        SetMessage("Correct the highlighted fields. Nothing was saved.");
                        break;
                    }
                    // Writes only the four editable fields to this student's own record, then reads it again to confirm
                    var changes = ProfileValidation.CreatePatch(PhoneNumberInput.Text, SkillsInput.Text, CvInput.Text, PortfolioInput.Text, ProfileValidation.EditableFields);
                    await SaveProfileFieldsAsync(changes);
                    IsEditing = false;
                    BindFields();
                    SetMessage("Your profile changes were saved.", false);
                    break;
                default:
                    if (!IsEditing) BindFields();
                    break;
            }
        }
        private System.Web.UI.WebControls.TextBox[] CandidateInputs()
        {
            return new[] { PhoneNumberInput, SkillsInput, CvInput, PortfolioInput };
        }
        private void ApplyPermissions()
        {
            bool available = Workspace != null;
            foreach (var input in CandidateInputs()) input.ReadOnly = !available || !IsEditing;
            EditButton.Visible = available && !IsEditing;
            ValidateButton.Visible = CancelButton.Visible = SaveButton.Visible = available && IsEditing;
            SaveButton.Enabled = CanUpdate;
        }
        private void BindFields()
        {
            PhoneNumberInput.Text = Record?.PhoneNumber ?? "";
            SkillsInput.Text = string.Join(Environment.NewLine, Record?.SkillsList ?? new List<string>());
            CvInput.Text = Record?.CvUrl ?? "";
            PortfolioInput.Text = Record?.PortfolioUrl ?? "";
        }
        protected void EditButton_Click(object sender, EventArgs e) { requestedAction = ProfileAction.Edit; }
        protected void ValidateButton_Click(object sender, EventArgs e) { requestedAction = ProfileAction.Validate; }
        protected void SaveButton_Click(object sender, EventArgs e) { requestedAction = ProfileAction.Save; }
        protected void CancelButton_Click(object sender, EventArgs e) { requestedAction = ProfileAction.Cancel; }
        private void ValidateCsrf()
        {
            if (string.IsNullOrEmpty(CsrfToken) || !string.Equals(Request.Form["StudentCsrf"], CsrfToken, StringComparison.Ordinal))
                throw new UnauthorizedAccessException("Your form session has expired. Reload the page before continuing.");
        }
        private void ClearFieldErrors()
        {
            foreach (var label in new[] { PhoneError, SkillsError, CvError, PortfolioError }) label.Text = "";
            foreach (var input in CandidateInputs()) input.Attributes.Remove("aria-invalid");
        }
        private bool ValidateInputs()
        {
            bool valid = true;
            string[] fields = { "PhoneNumber", "SkillsList", "CvUrl", "PortfolioUrl" };
            var labels = new[] { PhoneError, SkillsError, CvError, PortfolioError };
            var inputs = CandidateInputs();
            for (int i = 0; i < fields.Length; i++)
            {
                try
                {
                    ProfileValidation.CreatePatch(PhoneNumberInput.Text, SkillsInput.Text, CvInput.Text, PortfolioInput.Text,
                        new HashSet<string>(StringComparer.Ordinal) { fields[i] });
                }
                catch (ArgumentException ex)
                {
                    valid = false;
                    labels[i].Text = HttpUtility.HtmlEncode(ex.Message);
                    inputs[i].Attributes["aria-invalid"] = "true";
                }
            }
            return valid;
        }
        internal static string SafeProfileImage(string value)
        {
            Uri url;
            return !string.IsNullOrWhiteSpace(value) && value.Length <= 2048 && !value.Any(char.IsControl)
                && Uri.TryCreate(value, UriKind.Absolute, out url) && url.Scheme == Uri.UriSchemeHttps
                && !string.IsNullOrEmpty(url.Host) && string.IsNullOrEmpty(url.UserInfo)
                ? url.AbsoluteUri : null;
        }
        private void SetMessage(string message, bool isError = true)
        {
            SaveMessage.Text = HttpUtility.HtmlEncode(message);
            SaveMessage.CssClass = "sd-save-message " + (isError ? "sd-save-error" : "sd-save-info");
            SaveMessage.Attributes["role"] = isError ? "alert" : "status";
        }

        protected void ResetPasswordButton_Click(object sender, EventArgs e)
        {
            RegisterAsyncTask(new PageAsyncTask(ResetPasswordAsync));
        }

        private async Task ResetPasswordAsync()
        {
            try
            {
                ValidateCsrf();
                await LoadWorkspaceAsync();
                if (Workspace == null || string.IsNullOrWhiteSpace(VerifiedStudentId))
                    throw new UnauthorizedAccessException(DataError ?? "Student authorization is required.");

                string currentPassword = CurrentPasswordInput.Text;
                string newPassword = NewPasswordInput.Text;
                if (string.IsNullOrEmpty(currentPassword) || string.IsNullOrEmpty(newPassword) || string.IsNullOrEmpty(ConfirmPasswordInput.Text))
                    throw new ArgumentException("Complete all password fields.");
                if (newPassword.Length < 6 || newPassword.Length > 128)
                    throw new ArgumentException("The new password must be between 6 and 128 characters.");
                if (newPassword != ConfirmPasswordInput.Text)
                    throw new ArgumentException("The new passwords do not match.");
                if (newPassword == currentPassword)
                    throw new ArgumentException("Choose a new password different from your current password.");

                string uid = Session["userId"] as string;
                string email = Record.Email;
                if (string.IsNullOrWhiteSpace(uid) || string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(AppConfig.ApiKey))
                    throw new UnauthorizedAccessException("Your account session is unavailable. Sign in again.");

                JObject signIn;
                using (var response = await PasswordClient.PostAsync(AppConfig.SignInUrl,
                    new StringContent(JsonConvert.SerializeObject(new { email, password = currentPassword, returnSecureToken = true }), Encoding.UTF8, "application/json")))
                {
                    if (!response.IsSuccessStatusCode)
                        throw new UnauthorizedAccessException("The current password is incorrect or the account cannot be verified.");
                    signIn = JObject.Parse(await response.Content.ReadAsStringAsync());
                }
                if ((string)signIn["localId"] != uid || string.IsNullOrWhiteSpace((string)signIn["idToken"]))
                    throw new UnauthorizedAccessException("The verified account does not match your student session.");

                JObject updated;
                using (var response = await PasswordClient.PostAsync(AppConfig.UpdateAccountUrl,
                    new StringContent(JsonConvert.SerializeObject(new { idToken = (string)signIn["idToken"], password = newPassword, returnSecureToken = true }), Encoding.UTF8, "application/json")))
                {
                    if (!response.IsSuccessStatusCode)
                        throw new InvalidOperationException("Firebase could not update the password. Please try again.");
                    updated = JObject.Parse(await response.Content.ReadAsStringAsync());
                }
                string newToken = (string)updated["idToken"];
                if (string.IsNullOrWhiteSpace(newToken) || (string)updated["localId"] != uid)
                {
                    AuthHelper.SignOut();
                    Response.Redirect("~/login/Login.aspx?msg=" + Server.UrlEncode("Password updated. Please sign in again."), false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }
                Session["idToken"] = newToken;
                await Notify.AfterSignIn("Students", VerifiedStudentId, Record.Name, "student", email, newToken);
                PasswordSuccess.Text = "Your password was updated successfully.";
            }
            catch (ArgumentException ex) { ShowPasswordError(ex.Message); }
            catch (UnauthorizedAccessException ex) { ShowPasswordError(ex.Message); }
            catch (HttpRequestException) { ShowPasswordError("Could not reach Firebase. Please try again."); }
            catch (TaskCanceledException) { ShowPasswordError("The request timed out. Please try again."); }
            catch (JsonException) { ShowPasswordError("Firebase returned an invalid response. Please try again."); }
            catch (InvalidOperationException ex) { ShowPasswordError(ex.Message); }
            finally
            {
                CurrentPasswordInput.Text = "";
                NewPasswordInput.Text = "";
                ConfirmPasswordInput.Text = "";
            }
        }

        private void ShowPasswordError(string message)
        {
            PasswordError.Text = HttpUtility.HtmlEncode(message);
            ClientScript.RegisterStartupScript(GetType(), "resetPasswordError",
                "document.addEventListener('DOMContentLoaded', function () { bootstrap.Modal.getOrCreateInstance(document.getElementById('resetPasswordModal')).show(); });", true);
        }

        protected void Button1_Click(object sender, EventArgs e)
        {
            string query = Request.Url.Query ?? "";
            Response.Redirect("~/login/FirstLogin.aspx" + query, false);
            Context.ApplicationInstance.CompleteRequest();
        }
    }

}

namespace UniversityInternshipManagmentSystem.Student.StudentProfilePage
{
    public static class ProfileValidation
    {
        public static IDictionary<string, object> CreatePatch(string phone, string skillsText, string cv, string portfolio, ISet<string> authorized)
        {
            var patch = new Dictionary<string, object>(StringComparer.Ordinal);
            if (authorized == null) throw new UnauthorizedAccessException("No profile fields are authorized for editing.");
            if (authorized.Contains("PhoneNumber")) patch["PhoneNumber"] = (phone ?? "").Trim();
            if (authorized.Contains("SkillsList"))
            {
                if (skillsText != null && skillsText.Length > 2000) throw new ArgumentException("The skills list is too long.");
                patch["SkillsList"] = (skillsText ?? "").Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries)
                    .Select(value => value.Trim()).Where(value => value.Length > 0)
                    .Distinct(StringComparer.OrdinalIgnoreCase).ToList();
            }
            if (authorized.Contains("CvUrl")) patch["CvUrl"] = NormalizeWebUrl(cv);
            if (authorized.Contains("PortfolioUrl")) patch["PortfolioUrl"] = NormalizeWebUrl(portfolio);
            ValidatePatch(patch, authorized);
            return patch;
        }

        public static bool MatchesPatch(StudentRecord record, IDictionary<string, object> patch)
        {
            if (record == null || patch == null) return false;
            foreach (var pair in patch)
            {
                switch (pair.Key)
                {
                    case "PhoneNumber": if (record.PhoneNumber != (string)pair.Value) return false; break;
                    case "CvUrl": if (record.CvUrl != (string)pair.Value) return false; break;
                    case "PortfolioUrl": if (record.PortfolioUrl != (string)pair.Value) return false; break;
                    // Firebase removes an empty array; null is equivalent only for an empty skills list.
                    case "SkillsList": if (!(record.SkillsList ?? new List<string>()).SequenceEqual((IList<string>)pair.Value)) return false; break;
                    default: return false;
                }
            }
            return true;
        }
        // Return a copy so callers cannot expand the module's permanent field policy.
        public static ISet<string> EditableFields => new HashSet<string>(StringComparer.Ordinal)
        { "PhoneNumber", "SkillsList", "CvUrl", "PortfolioUrl" };

        public static string NormalizeWebUrl(string value)
        {
            var raw = (value ?? "").Trim();
            if (raw.Length == 0) return "";
            const string error = "Enter a valid CV or portfolio web link, such as www.example.com, http://example.com or https://example.com (up to 2048 characters).";
            if (raw.Length > 2048 || raw.Any(char.IsControl) || raw.Any(char.IsWhiteSpace) || raw.Contains("\\")) throw new ArgumentException(error);
            bool explicitWeb = Regex.IsMatch(raw, @"\Ahttps?://", RegexOptions.IgnoreCase);
            string candidate = raw;
            if (!explicitWeb)
            {
                if (raw.StartsWith("//", StringComparison.Ordinal)) candidate = "https:" + raw;
                else
                {
                    var head = raw.Split(new[] { '/', '?', '#' }, 2)[0];
                    if (head.Contains(":") && !Regex.IsMatch(head, @"\A(?:localhost|[^\s:/@]+\.[^\s:/@]+):[0-9]{1,5}\z", RegexOptions.IgnoreCase)) throw new ArgumentException(error);
                    candidate = "https://" + raw;
                }
            }
            Uri uri;
            if (!Uri.TryCreate(candidate, UriKind.Absolute, out uri)
                || (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps)
                || string.IsNullOrEmpty(uri.Host) || !string.IsNullOrEmpty(uri.UserInfo)
                || (!explicitWeb && !uri.Host.Contains(".") && uri.Host != "localhost")
                || !Uri.IsWellFormedUriString(candidate, UriKind.Absolute) || uri.AbsoluteUri.Length > 2048)
                throw new ArgumentException(error);
            return uri.AbsoluteUri;
        }

        public static string GetSafeWebUrl(string value)
        {
            try { var normalized = NormalizeWebUrl(value); return normalized.Length == 0 ? null : normalized; }
            catch (ArgumentException) { return null; }
        }
        public static bool IsSafeUrl(string value) => GetSafeWebUrl(value) != null;

        public static void ValidatePatch(IDictionary<string, object> changes, ISet<string> authorized)
        {
            if (changes == null || changes.Count == 0) throw new ArgumentException("There are no authorized changes to save.");
            foreach (var pair in changes)
            {
                if (!EditableFields.Contains(pair.Key) || authorized == null || !authorized.Contains(pair.Key))
                    throw new UnauthorizedAccessException("This profile field is read-only.");
                if (pair.Key == "SkillsList")
                {
                    var skills = pair.Value as IList<string>;
                    if (skills == null || skills.Count > 20 || skills.Any(s => string.IsNullOrWhiteSpace(s)
                        || s.Length > 60 || s.Any(char.IsControl)))
                        throw new ArgumentException("Enter up to 20 skills, each between 1 and 60 characters.");
                }
                else
                {
                    var value = pair.Value as string;
                    if (value == null) throw new ArgumentException("Invalid profile field value.");
                    if (pair.Key == "PhoneNumber")
                    {
                        if (value.Length > 30 || value.Any(char.IsControl) || (value.Length > 0 && (!Regex.IsMatch(value, @"\A\+?[0-9 ()\-]{7,30}\z")
                            || value.Count(c => c >= '0' && c <= '9') < 7)))
                            throw new ArgumentException("Enter a phone number with 7–30 characters using digits, spaces, +, parentheses, or hyphens.");
                    }
                    else if (value.Length > 0 && (value.Length > 2048 || value.Any(char.IsControl) || !IsSafeUrl(value)))
                        throw new ArgumentException("Enter a valid CV or portfolio web link (http://, https:// or www.example.com; up to 2048 characters).");
                }
            }
        }
    }
}
