using System;
using System.Collections.Generic;
using System.Linq;
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
    public partial class CoordinatorAccountPage : Page
    {
        protected Panel workspace, noticePanel, imagePanel, initialsPanel, passwordNoticePanel;
        protected Literal notice, displayName, displayEmail, initials, passwordNotice;
        protected Image avatar;
        protected TextBox fullName, email, phone, pictureUrl, currentPassword, newPassword, confirmPassword;
        protected HiddenField openPassword;
        private Admin admin;
        private string recordId;
        private bool allowed;

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
            openPassword.Value = "0";
            passwordNoticePanel.Visible = false;
            if (String.IsNullOrWhiteSpace(AuthHelper.IdToken) || AuthHelper.IdToken == "mock-token")
            {
                ShowMessage("Sign in with your real coordinator account to manage your profile.", true);
                return;
            }
            try
            {
                string json = await FirebaseDb.Get("Admins");
                if (json == null) throw new Exception();
                var admins = JsonConvert.DeserializeObject<Dictionary<string, Admin>>(json) ?? new Dictionary<string, Admin>();
                recordId = AuthHelper.UserId;
                if (!admins.TryGetValue(recordId, out admin))
                {
                    var matches = admins.Where(item => !String.IsNullOrWhiteSpace(AuthHelper.UserEmail)
                        && String.Equals(item.Value.Email, AuthHelper.UserEmail, StringComparison.OrdinalIgnoreCase)).ToList();
                    if (matches.Count != 1) throw new Exception();
                    recordId = matches[0].Key;
                    admin = matches[0].Value;
                }
                allowed = workspace.Visible = true;
                BindOverview();
                if (!IsPostBack) BindForm();
            }
            catch
            {
                ShowMessage("Your coordinator profile could not be loaded. Check the connection or sign in again.", true);
            }
        }

        private void BindOverview()
        {
            displayName.Text = admin.Name;
            displayEmail.Text = admin.Email;
            initials.Text = String.Concat((admin.Name ?? "Coordinator").Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries)
                .Take(2).Select(part => part.Substring(0, 1).ToUpperInvariant()));
            Uri imageUri;
            bool hasImage = Uri.TryCreate(admin.ProfilePicUrl, UriKind.Absolute, out imageUri) && imageUri.Scheme == "https";
            imagePanel.Visible = hasImage;
            initialsPanel.Visible = !hasImage;
            if (hasImage) avatar.ImageUrl = admin.ProfilePicUrl;
        }

        private void BindForm()
        {
            fullName.Text = admin.Name;
            email.Text = admin.Email;
            string savedPhone = admin.PhoneNumber ?? "";
            phone.Text = savedPhone.StartsWith("+9627") && savedPhone.Length == 13
                ? "0" + savedPhone.Substring(4) : savedPhone;
            pictureUrl.Text = admin.ProfilePicUrl;
        }

        protected async void SaveProfile(object sender, EventArgs e)
        {
            if (!allowed) return;
            string name = fullName.Text.Trim(), number = phone.Text.Trim(), photo = pictureUrl.Text.Trim();
            Uri photoUri;
            if (name.Length < 2 || name.Length > 100)
            {
                ShowMessage("Enter a full name between 2 and 100 characters.", true);
                return;
            }
            if (number != "" && !Regex.IsMatch(number, @"\A07[0-9]{8}\z"))
            {
                ShowMessage("Enter a 10-digit mobile number starting with 07, for example 0791234567.", true);
                return;
            }
            if (photo != "" && (!Uri.TryCreate(photo, UriKind.Absolute, out photoUri) || photoUri.Scheme != "https"))
            {
                ShowMessage("Use an HTTPS image link, or leave the image field blank.", true);
                return;
            }
            try
            {
                using (var response = await FirebaseDb.Patch("Admins", recordId,
                    new { Name = name, PhoneNumber = number, ProfilePicUrl = photo }))
                {
                    if (!response.IsSuccessStatusCode) throw new Exception();
                }
                admin.Name = name; admin.PhoneNumber = number; admin.ProfilePicUrl = photo;
                Session["name"] = name;
                Response.Redirect("CoordinatorAccount.aspx?saved=1", false);
                Context.ApplicationInstance.CompleteRequest();
            }
            catch
            {
                ShowMessage("Changes were not saved. Check the connection and try again.", true);
            }
        }

        protected void CancelChanges(object sender, EventArgs e)
        {
            if (allowed) BindForm();
        }

        private async Task VerifyPassword(string password)
        {
            if (String.IsNullOrEmpty(password)) throw new Exception();
            var result = await AuthRequest(AppConfig.SignInUrl,
                new { email = admin.Email, password, returnSecureToken = true });
            if ((string)result["localId"] != AuthHelper.UserId) throw new Exception();
            Session["idToken"] = (string)result["idToken"];
        }

        private async Task<JObject> AuthRequest(string url, object data)
        {
            using (var body = new System.Net.Http.StringContent(JsonConvert.SerializeObject(data), Encoding.UTF8, "application/json"))
            using (var response = await FirebaseDb.client.PostAsync(url, body))
            {
                if (!response.IsSuccessStatusCode) throw new Exception();
                return JObject.Parse(await response.Content.ReadAsStringAsync());
            }
        }

        protected async void ChangePassword(object sender, EventArgs e)
        {
            if (!allowed) return;
            openPassword.Value = "1";
            passwordNoticePanel.Visible = true;
            if (String.IsNullOrEmpty(currentPassword.Text))
            {
                passwordNotice.Text = "Enter your current password.";
                return;
            }
            if (newPassword.Text.Length < 6)
            {
                passwordNotice.Text = "Your new password must be at least 6 characters.";
                return;
            }
            if (newPassword.Text != confirmPassword.Text)
            {
                passwordNotice.Text = "The new password and confirmation do not match.";
                return;
            }
            if (newPassword.Text == currentPassword.Text)
            {
                passwordNotice.Text = "Choose a password different from your current password.";
                return;
            }
            try
            {
                await VerifyPassword(currentPassword.Text);
                var result = await AuthRequest(AppConfig.UpdateAccountUrl,
                    new { idToken = AuthHelper.IdToken, password = newPassword.Text, returnSecureToken = true });
                Session["idToken"] = (string)result["idToken"];
                currentPassword.Text = newPassword.Text = confirmPassword.Text = "";
                openPassword.Value = "0";
                passwordNoticePanel.Visible = false;
                ShowMessage("Your password has been changed successfully.");
            }
            catch
            {
                passwordNotice.Text = "Password could not be changed. Check your current password and connection, then try again.";
            }
        }

        private void ShowMessage(string text, bool error = false)
        {
            noticePanel.Visible = true;
            noticePanel.CssClass = "ca-notice" + (error ? " ca-error" : "");
            notice.Text = text;
        }

        protected void Page_PreRender(object sender, EventArgs e)
        {
            if (allowed && !IsPostBack && Request.QueryString["saved"] == "1") ShowMessage("Your profile has been updated successfully.");
        }
    }
}
