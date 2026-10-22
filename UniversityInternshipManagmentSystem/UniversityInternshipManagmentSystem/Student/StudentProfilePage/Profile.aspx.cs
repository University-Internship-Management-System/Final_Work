using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Text.RegularExpressions;
using StudentRecord = UniversityInternshipManagmentSystem.Models.Student;

namespace UniversityInternshipManagmentSystem.Student.StudentProfilePage
{
    public partial class Profile : StudentPage
    {
        protected StudentRecord Record => Workspace;
        protected bool CanEdit => Workspace != null;
        protected bool CanUpdate => CanEdit;
        protected string CompanyText => string.IsNullOrEmpty(Record.CompanyId) ? "Not assigned" : "Assigned company · name unavailable";
        protected string SupervisorText => string.IsNullOrEmpty(Record.AcademicSupervisorId) ? "Not assigned" : "Assigned supervisor · name unavailable";
        protected string SafeCvUrl => ProfileValidation.GetSafeWebUrl(Record.CvUrl);
        protected string SafePortfolioUrl => ProfileValidation.GetSafeWebUrl(Record.PortfolioUrl);

        protected void Page_Load(object sender, EventArgs e)
        {

            RegisterAsyncTask(new PageAsyncTask(LoadProfileAsync));
        }

        private async Task LoadProfileAsync()
        {
            await LoadWorkspaceAsync();
            if (Workspace == null) { SaveButton.Visible = false; CancelButton.Visible = false; return; }
            ApplyPermissions();
            if (!IsPostBack) BindFields();
        }

        private void ApplyPermissions()
        {
            PhoneNumberInput.ReadOnly = !CanEdit;
            SkillsInput.ReadOnly = !CanEdit;
            CvInput.ReadOnly = !CanEdit;
            PortfolioInput.ReadOnly = !CanEdit;
            SaveButton.Visible = CanEdit;
            SaveButton.Enabled = CanUpdate;
            CancelButton.Visible = CanEdit;
        }

        private void BindFields()
        {
            PhoneNumberInput.Text = Record.PhoneNumber ?? "";
            SkillsInput.Text = string.Join(Environment.NewLine, Record.SkillsList ?? new List<string>());
            CvInput.Text = Record.CvUrl ?? "";
            PortfolioInput.Text = Record.PortfolioUrl ?? "";
        }

        protected void SaveButton_Click(object sender, EventArgs e)
        {
            RegisterAsyncTask(new PageAsyncTask(SaveProfileAsync));
        }

        protected void CancelButton_Click(object sender, EventArgs e)
        {
            RegisterAsyncTask(new PageAsyncTask(async () =>
            {
                try
                {
                    ValidateCsrf();
                    await LoadWorkspaceAsync();
                    if (Workspace == null) throw new UnauthorizedAccessException(DataError ?? "Student authorization is required.");
                    ApplyPermissions();
                    BindFields();
                    SetMessage("Unsaved changes discarded. Your current Firebase profile has been reloaded.", false);
                }
                catch (UnauthorizedAccessException ex) { SetMessage(ex.Message); }
                catch (StudentDataException ex) { SetMessage(ex.Message); }
                catch (Exception) { SetMessage("Your profile could not be reloaded. Your entries are still shown; try again later."); }
            }));
        }

        private void ValidateCsrf()
        {
            if (string.IsNullOrEmpty(CsrfToken) || !string.Equals(Request.Form["StudentCsrf"], CsrfToken, StringComparison.Ordinal))
                throw new UnauthorizedAccessException("Your form session has expired. Reload the page before continuing.");
        }

        private async Task SaveProfileAsync()
        {
            try
            {
                ValidateCsrf();
                // Re-resolve the trusted identity and field policy at the moment of writing.
                // LoadProfileAsync established the view; SaveProfileFieldsAsync re-verifies identity immediately before PATCH.
                if (!CanUpdate) throw new UnauthorizedAccessException("Profile updates are not authorized in this session.");
                var fields = ProfileValidation.EditableFields;
                var patch = ProfileValidation.CreatePatch(PhoneNumberInput.Text, SkillsInput.Text, CvInput.Text, PortfolioInput.Text, fields);
                await SaveProfileFieldsAsync(patch);
                // The repository has confirmed persistence with a fresh authenticated GET.
                if (patch.ContainsKey("PhoneNumber")) Record.PhoneNumber = (string)patch["PhoneNumber"];
                if (patch.ContainsKey("SkillsList")) Record.SkillsList = (List<string>)patch["SkillsList"];
                if (patch.ContainsKey("CvUrl")) Record.CvUrl = (string)patch["CvUrl"];
                if (patch.ContainsKey("PortfolioUrl")) Record.PortfolioUrl = (string)patch["PortfolioUrl"];
                ApplyPermissions();
                BindFields();
                SetMessage("Your profile changes were saved and confirmed by reading Firebase again.", false);
            }
            catch (ArgumentException ex) { SetMessage(ex.Message); }
            catch (UnauthorizedAccessException ex) { SetMessage(ex.Message); }
            catch (StudentDataException ex) { SetMessage(ex.Message); }
            catch (Exception) { SetMessage("Your changes could not be saved. Please try again later."); }
        }

        private void SetMessage(string message, bool isError = true)
        {
            SaveMessage.Text = HttpUtility.HtmlEncode(message);
            SaveMessage.CssClass = "sd-save-message " + (isError ? "sd-save-error" : "sd-save-success");
            SaveMessage.Attributes["role"] = isError ? "alert" : "status";
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
