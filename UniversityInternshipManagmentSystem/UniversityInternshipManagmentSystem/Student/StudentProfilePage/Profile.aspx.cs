using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using UniversityInternshipManagmentSystem.Student.Data;

namespace UniversityInternshipManagmentSystem.Student.StudentProfilePage
{
    public partial class Profile : StudentPage
    {
        protected StudentRecord Record => Workspace.Profile.Student;
        protected bool CanUpdate => ProfileValidation.EditableFields.Any(f => Workspace != null && Workspace.CanEdit(f));
        protected string CompanyText => Workspace.Profile.CompanyName ?? (string.IsNullOrEmpty(Record.CompanyId) ? "Not assigned" : "Assigned · company name unavailable");
        protected string SupervisorText => Workspace.Profile.AcademicSupervisorName ?? (string.IsNullOrEmpty(Record.AcademicSupervisorId) ? "Not assigned" : "Assigned · supervisor name unavailable");
        protected string SafeCvUrl => ProfileValidation.IsSafeUrl(Record.CvUrl) ? Record.CvUrl : null;
        protected string SafePortfolioUrl => ProfileValidation.IsSafeUrl(Record.PortfolioUrl) ? Record.PortfolioUrl : null;

        protected void Page_Load(object sender, EventArgs e)
        {

            RegisterAsyncTask(new PageAsyncTask(LoadProfileAsync));
        }

        private async Task LoadProfileAsync()
        {
            await LoadWorkspaceAsync();
            TestSignInPanel.Visible = StudentModule.SessionProvider == null && Workspace == null
                && StudentDevelopmentSignIn.IsAvailable(new HttpContextWrapper(Context));
            TestSignOutButton.Visible = StudentModule.SessionProvider == null && Workspace != null
                && StudentDevelopmentSignIn.IsAvailable(new HttpContextWrapper(Context));
            if (Workspace == null) { SaveButton.Visible = false; CancelButton.Visible = false; return; }
            ApplyPermissions();
            if (!IsPostBack) BindFields();
        }

        protected void TestSignIn_Click(object sender, EventArgs e)
        {
            RegisterAsyncTask(new PageAsyncTask(async () =>
            {
                try
                {
                    if (!string.Equals(Request.Form["StudentCsrf"], CsrfToken, StringComparison.Ordinal))
                        throw new UnauthorizedAccessException("Your sign-in form expired. Reload the page.");
                    var configuredKey = Environment.GetEnvironmentVariable("UIMS_STUDENT_FIREBASE_API_KEY");
                    Workspace = await StudentDevelopmentSignIn.SignInAsync(new HttpContextWrapper(Context),
                        string.IsNullOrWhiteSpace(configuredKey) ? TestApiKeyInput.Text.Trim() : configuredKey,
                        TestEmailInput.Text, TestPasswordInput.Text);
                    DataError = null;
                    TestSignInPanel.Visible = false;
                    TestSignOutButton.Visible = true;
                    ApplyPermissions();
                    BindFields();
                    SetMessage("Live Firebase read verified: your signed-in user matches this student's AuthUid. "
                        + (FirebaseStudentRepository.ProfileWritesEnabled ? "Only approved personal fields can be saved." : "You can prepare profile changes; saving awaits approved Firebase permissions."), false);
                }
                catch (ArgumentException ex) { DataError = ex.Message; }
                catch (UnauthorizedAccessException ex) { DataError = ex.Message; }
                catch (StudentDataException ex) { DataError = ex.Message; }
                catch (Exception) { DataError = "Student sign-in could not be completed securely. Please try again later."; }
                finally { TestPasswordInput.Text = ""; }
            }));
        }

        protected void TestSignOut_Click(object sender, EventArgs e)
        {
            if (!StudentDevelopmentSignIn.IsAvailable(new HttpContextWrapper(Context))
                || !string.Equals(Request.Form["StudentCsrf"], CsrfToken, StringComparison.Ordinal))
            { DataError = "Your local sign-out request could not be verified. Reload the page."; return; }
            StudentDevelopmentSignIn.SignOut(new HttpContextWrapper(Context));
            Response.Redirect(ResolveUrl("~/Student/StudentProfilePage/Profile.aspx"), false);
            Context.ApplicationInstance.CompleteRequest();
        }

        private void ApplyPermissions()
        {
            PhoneNumberInput.ReadOnly = !Workspace.CanEdit("PhoneNumber");
            SkillsInput.ReadOnly = !Workspace.CanEdit("SkillsList");
            CvInput.ReadOnly = !Workspace.CanEdit("CvUrl");
            PortfolioInput.ReadOnly = !Workspace.CanEdit("PortfolioUrl");
            SaveButton.Visible = CanUpdate;
            CancelButton.Visible = CanUpdate;
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
                    Workspace = await StudentModule.OpenAsync(new HttpContextWrapper(Context));
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
                Workspace = await StudentModule.OpenAsync(new HttpContextWrapper(Context));
                if (!CanUpdate) throw new UnauthorizedAccessException("Profile updates are not authorized in this session.");
                var fields = new HashSet<string>(ProfileValidation.EditableFields.Where(Workspace.CanEdit), StringComparer.Ordinal);
                var patch = ProfileValidation.CreatePatch(PhoneNumberInput.Text, SkillsInput.Text, CvInput.Text, PortfolioInput.Text, fields);
                await Workspace.Repository.UpdateProfileAsync(patch);
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
    }
}
