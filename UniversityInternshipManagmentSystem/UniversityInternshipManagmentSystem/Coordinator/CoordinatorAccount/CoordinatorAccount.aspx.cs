using System;
using System.Collections.Generic;
using System.Linq;
using System.IO;
using System.Net.Http;
using System.Security.Cryptography;
using System.Globalization;
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
        protected Panel workspace, noticePanel, imagePanel, initialsPanel, passwordNoticePanel, profileEditor, photoEditor;
        protected Literal notice, displayName, displayEmail, initials, passwordNotice;
        protected Image avatar;
        protected TextBox fullName, email, phone, currentPassword, newPassword, confirmPassword;
        protected HiddenField openPassword;
        protected FileUpload profilePhoto;
        protected Button editProfile, saveProfile, cancelProfile;
        private Admin admin;
        private string recordId;
        private bool allowed;
        private bool EditingProfile
        {
            get { return (bool)(ViewState["EditingProfile"] ?? false); }
            set { ViewState["EditingProfile"] = value; }
        }

        protected void Page_Init(object sender, EventArgs e)
        {
            ViewStateUserKey = Session.SessionID;
            Form.Enctype = "multipart/form-data";
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

        // Show profile details, using the first two initials when no HTTPS photo is available.
        private void BindOverview()
        {
            displayName.Text = admin.Name;
            displayEmail.Text = admin.Email;
            string[] names = (admin.Name ?? "Coordinator").Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            initials.Text = "";
            for (int index = 0; index < names.Length && index < 2; index++)
                initials.Text += names[index].Substring(0, 1).ToUpperInvariant();
            Uri imageUri;
            bool hasImage = Uri.TryCreate(admin.ProfilePicUrl, UriKind.Absolute, out imageUri) && imageUri.Scheme == "https";
            imagePanel.Visible = hasImage;
            initialsPanel.Visible = !hasImage;
            if (hasImage) avatar.ImageUrl = admin.ProfilePicUrl;
        }

        // Fill the editable fields from the saved coordinator record.
        private void BindForm()
        {
            fullName.Text = admin.Name;
            email.Text = admin.Email;
            string savedPhone = admin.PhoneNumber ?? "";
            if (savedPhone.StartsWith("+9627") && savedPhone.Length == 13)
                savedPhone = "0" + savedPhone.Substring(4);
            phone.Text = savedPhone;
        }

        protected async void SaveProfile(object sender, EventArgs e)
        {
            if (!allowed || !EditingProfile) return;
            string name = fullName.Text.Trim(), number = phone.Text.Trim();
            string photo = admin.ProfilePicUrl, uploadedId = null;
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
            try
            {
                if (profilePhoto.HasFile)
                {
                    byte[] imageBytes;
                    try { imageBytes = ReadPhoto(); }
                    catch
                    {
                        ShowMessage("Choose a valid JPG or PNG image up to 2 MB.", true);
                        return;
                    }
                    uploadedId = "uims/coordinator-profiles/" + Guid.NewGuid().ToString("N");
                    var uploaded = await CloudinaryRequest("upload", uploadedId, imageBytes);
                    photo = (string)uploaded["secure_url"];
                    Uri photoUri;
                    if (!Uri.TryCreate(photo, UriKind.Absolute, out photoUri) || photoUri.Scheme != "https") throw new Exception();
                }
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
                if (uploadedId != null)
                {
                    try { await CloudinaryRequest("destroy", uploadedId); }
                    catch { /* The current profile stays unchanged if saving fails. */ }
                }
                ShowMessage("Changes were not saved. Check your connection and the local image-upload settings, then select the image again.", true);
            }
        }

        private byte[] ReadPhoto()
        {
            string extension = Path.GetExtension(profilePhoto.FileName).ToLowerInvariant();
            if (profilePhoto.PostedFile.ContentLength > 2 * 1024 * 1024
                || (extension != ".jpg" && extension != ".jpeg" && extension != ".png")) throw new Exception();
            byte[] bytes = profilePhoto.FileBytes;
            bool png = bytes.Length >= 8 && bytes.Take(8).SequenceEqual(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 });
            bool jpeg = bytes.Length >= 3 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255;
            if (!png && !jpeg) throw new Exception();
            return bytes;
        }

        private async Task<JObject> CloudinaryRequest(string action, string publicId, byte[] image = null)
        {
            // App_Data/keys/cloudinary.json (team file) or the Windows variable, see Config/TeamKeys.cs
            string path = TeamKeys.FindFile(TeamKeys.CloudinaryVariable, TeamKeys.CloudinaryFile);
            if (path == null) throw new InvalidOperationException("The Cloudinary key file was not found.");
            var settings = JObject.Parse(File.ReadAllText(path));
            string cloud = ((string)settings["cloud_name"] ?? "").Trim();
            string key = ((string)settings["api_key"] ?? "").Trim();
            string secret = ((string)settings["api_secret"] ?? "").Trim();
            if (String.IsNullOrWhiteSpace(cloud) || !Regex.IsMatch(cloud, @"\A[a-zA-Z0-9_-]+\z")
                || String.IsNullOrWhiteSpace(key) || String.IsNullOrWhiteSpace(secret)) throw new Exception();
            string timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString(CultureInfo.InvariantCulture);
            string parameters = "public_id=" + publicId + "&timestamp=" + timestamp;
            if (image != null) parameters = "allowed_formats=jpg,png&" + parameters + "&transformation=c_limit,h_512,w_512";
            string signature;
            using (var hash = SHA256.Create())
                signature = BitConverter.ToString(hash.ComputeHash(Encoding.UTF8.GetBytes(
                    parameters + secret))).Replace("-", "").ToLowerInvariant();
            using (var body = new MultipartFormDataContent())
            {
                body.Add(new StringContent(publicId), "public_id");
                body.Add(new StringContent(timestamp), "timestamp");
                body.Add(new StringContent(key), "api_key");
                body.Add(new StringContent(signature), "signature");
                if (image != null)
                {
                    body.Add(new StringContent("jpg,png"), "allowed_formats");
                    body.Add(new StringContent("c_limit,h_512,w_512"), "transformation");
                    bool png = image[0] == 137;
                    var file = new ByteArrayContent(image);
                    file.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(png ? "image/png" : "image/jpeg");
                    body.Add(file, "file", png ? "profile.png" : "profile.jpg");
                }
                using (var response = await FirebaseDb.client.PostAsync("https://api.cloudinary.com/v1_1/" + cloud + "/image/" + action, body))
                {
                    if (!response.IsSuccessStatusCode) throw new Exception();
                    return JObject.Parse(await response.Content.ReadAsStringAsync());
                }
            }
        }

        protected void EditProfile(object sender, EventArgs e)
        {
            if (!allowed) return;
            EditingProfile = true;
            BindForm();
        }

        protected void CancelChanges(object sender, EventArgs e)
        {
            if (!allowed) return;
            EditingProfile = false;
            BindForm();
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

        // Check the password fields, then use the existing Firebase password flow.
        protected async void ChangePassword(object sender, EventArgs e)
        {
            if (!allowed) return;
            openPassword.Value = "1";
            passwordNoticePanel.Visible = true;
            string error = null;
            if (String.IsNullOrEmpty(currentPassword.Text)) error = "Enter your current password.";
            else if (newPassword.Text.Length < 6) error = "Your new password must be at least 6 characters.";
            else if (newPassword.Text != confirmPassword.Text) error = "The new password and confirmation do not match.";
            else if (newPassword.Text == currentPassword.Text) error = "Choose a password different from your current password.";
            if (error != null)
            {
                passwordNotice.Text = error;
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
            noticePanel.CssClass = "ca-notice";
            if (error) noticePanel.CssClass += " ca-error";
            notice.Text = text;
        }

        protected void Page_PreRender(object sender, EventArgs e)
        {
            if (!allowed) return;
            // Start in view mode. Edit unlocks the form; Save and Cancel return to view mode.
            fullName.ReadOnly = phone.ReadOnly = !EditingProfile;
            profilePhoto.Enabled = EditingProfile;
            photoEditor.Visible = EditingProfile;
            editProfile.Visible = !EditingProfile;
            saveProfile.Visible = cancelProfile.Visible = EditingProfile;
            profileEditor.DefaultButton = EditingProfile ? "saveProfile" : "editProfile";
            if (!IsPostBack && Request.QueryString["saved"] == "1") ShowMessage("Your profile has been updated successfully.");
        }
    }
}
