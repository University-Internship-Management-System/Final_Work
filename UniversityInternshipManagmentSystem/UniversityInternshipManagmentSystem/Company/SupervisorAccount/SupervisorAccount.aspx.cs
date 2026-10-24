using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web.UI;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;

namespace UniversityInternshipManagmentSystem.Company.SupervisorAccount
{
    public partial class SupervisorAccount : Page
    {
        private const string TableCompany = "CompanySupervisors";

        protected async void Page_Load(object sender, EventArgs e)
        {
            // Enforce Company Supervisor or Coordinator authentication
            AuthHelper.RequireAuth(this, AuthHelper.RoleCompany, AuthHelper.RoleCoordinator);
            if (Response.IsRequestBeingRedirected)
            {
                return;
            }

            if (!IsPostBack)
            {
                await LoadCompanySupervisorProfileAsync();
            }
        }

        #region Profile Loading & Binding

        /// <summary>
        /// Loads the company supervisor's profile data from Firebase RTDB or fallback model.
        /// </summary>
        private async Task LoadCompanySupervisorProfileAsync()
        {
            ClearAlerts();

            string userEmail = (AuthHelper.UserEmail ?? "").Trim().ToLowerInvariant();
            string recordId = Session["dbRecordId"] as string;

            Models.CompanySupervisor supervisor = null;

            try
            {
                // 1. If record ID already resolved in session, query directly
                if (!string.IsNullOrEmpty(recordId))
                {
                    string json = await FirebaseDb.Get(TableCompany, recordId);
                    if (!string.IsNullOrEmpty(json) && json.Trim() != "null")
                    {
                        var obj = JObject.Parse(json);
                        supervisor = ParseCompanySupervisor(recordId, obj);
                    }
                }

                // 2. Otherwise scan the CompanySupervisors table by email
                if (supervisor == null)
                {
                    string allCompaniesJson = await FirebaseDb.Get(TableCompany);
                    if (!string.IsNullOrEmpty(allCompaniesJson) && allCompaniesJson.Trim() != "null")
                    {
                        var allObj = JObject.Parse(allCompaniesJson);
                        foreach (var prop in allObj.Properties())
                        {
                            if (prop.Value is JObject item)
                            {
                                string email = (item["Email"]?.ToString() ?? "").Trim().ToLowerInvariant();
                                string compEmail = (item["CompEmail"]?.ToString() ?? "").Trim().ToLowerInvariant();

                                if (email == userEmail || compEmail == userEmail)
                                {
                                    supervisor = ParseCompanySupervisor(prop.Name, item);
                                    Session["dbRecordId"] = prop.Name;
                                    Session["dbTable"] = TableCompany;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            catch
            {
                // Proceed with fallback model if database read is unavailable
            }

            // 3. Fallback to default in-memory model if no database record found
            if (supervisor == null)
            {
                // No record was found: show an empty profile (never made-up data) with the name and email of the signed-in person
                supervisor = new Models.CompanySupervisor
                {
                    Id = recordId ?? string.Empty,
                    Name = AuthHelper.UserName ?? string.Empty,
                    Email = AuthHelper.UserEmail ?? string.Empty,
                    CompanyName = string.Empty,
                    CompEmail = AuthHelper.UserEmail ?? string.Empty,
                    Location = string.Empty,
                    PhoneNumber = string.Empty,
                    ProfilePicUrl = string.Empty,
                    Role = "CompanySupervisor"
                };

                Session["dbRecordId"] = supervisor.Id;
                Session["dbTable"] = TableCompany;
            }

            BindSupervisorData(supervisor);
        }

        private Models.CompanySupervisor ParseCompanySupervisor(string id, JObject obj)
        {
            return new Models.CompanySupervisor
            {
                Id = id,
                Name = obj["Name"]?.ToString() ?? obj["name"]?.ToString() ?? AuthHelper.UserName ?? "Company Supervisor",
                Email = obj["Email"]?.ToString() ?? obj["email"]?.ToString() ?? AuthHelper.UserEmail ?? "",
                CompanyName = obj["CompanyName"]?.ToString() ?? obj["companyName"]?.ToString() ?? "Partner Company",
                CompEmail = obj["CompEmail"]?.ToString() ?? obj["compEmail"]?.ToString() ?? obj["Email"]?.ToString() ?? AuthHelper.UserEmail ?? "",
                Location = obj["Location"]?.ToString() ?? obj["location"]?.ToString() ?? "Amman, Jordan",
                PhoneNumber = obj["PhoneNumber"]?.ToString() ?? obj["phoneNumber"]?.ToString() ?? "",
                ProfilePicUrl = obj["ProfilePicUrl"]?.ToString() ?? obj["profilePicUrl"]?.ToString() ?? "",
                Role = "CompanySupervisor"
            };
        }

        private void BindSupervisorData(Models.CompanySupervisor supervisor)
        {
            // Editable form fields
            txtFullName.Text = supervisor.Name;
            txtCompanyName.Text = supervisor.CompanyName;
            txtEmail.Text = !string.IsNullOrWhiteSpace(supervisor.CompEmail) ? supervisor.CompEmail : supervisor.Email;
            txtPhoneNumber.Text = supervisor.PhoneNumber;
            txtLocation.Text = supervisor.Location;
            ViewState["logo"] = supervisor.ProfilePicUrl;   // stays as it is unless a new file is chosen

            // Left Overview Card
            litProfileName.Text = Server.HtmlEncode(supervisor.Name);
            litProfileRole.Text = "Company Supervisor";
            litBadgeCompanyName.Text = Server.HtmlEncode(!string.IsNullOrWhiteSpace(supervisor.CompanyName) ? supervisor.CompanyName : "Partner Company");
            litProfileCompany.Text = Server.HtmlEncode(!string.IsNullOrWhiteSpace(supervisor.CompanyName) ? supervisor.CompanyName : "Not specified");
            litProfileEmail.Text = Server.HtmlEncode(txtEmail.Text);
            litProfilePhone.Text = Server.HtmlEncode(!string.IsNullOrWhiteSpace(supervisor.PhoneNumber) ? supervisor.PhoneNumber : "Not provided");
            litProfileLocation.Text = Server.HtmlEncode(!string.IsNullOrWhiteSpace(supervisor.Location) ? supervisor.Location : "Not specified");

            // Avatar binding
            if (!string.IsNullOrWhiteSpace(supervisor.ProfilePicUrl) && Uri.IsWellFormedUriString(supervisor.ProfilePicUrl, UriKind.Absolute))
            {
                pnlImageAvatar.Visible = true;
                pnlInitialsAvatar.Visible = false;
                imgAvatar.ImageUrl = supervisor.ProfilePicUrl;
            }
            else
            {
                pnlImageAvatar.Visible = false;
                pnlInitialsAvatar.Visible = true;
                litAvatarInitials.Text = Server.HtmlEncode(GetInitials(supervisor.Name));
            }
        }

        private string GetInitials(string name)
        {
            if (string.IsNullOrWhiteSpace(name))
                return "CS";

            string clean = name.Replace("Eng.", "").Replace("Mr.", "").Replace("Ms.", "").Trim();
            string[] parts = clean.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);

            if (parts.Length == 1)
                return parts[0].Substring(0, Math.Min(2, parts[0].Length)).ToUpperInvariant();

            return (parts[0][0].ToString() + parts[parts.Length - 1][0].ToString()).ToUpperInvariant();
        }

        #endregion

        #region Actions

        /// <summary>
        /// Saves updated supervisor details to Firebase RTDB and refreshes the user session.
        /// </summary>
        protected async void btnSaveDetails_Click(object sender, EventArgs e)
        {
            ClearAlerts();

            string fullName = txtFullName.Text.Trim();
            string companyName = txtCompanyName.Text.Trim();
            string phone = txtPhoneNumber.Text.Trim();
            string location = txtLocation.Text.Trim();
            string profilePic = ViewState["logo"] as string ?? "";
            string uploadedId = null;

            if (string.IsNullOrEmpty(fullName))
            {
                ShowProfileError("Full Name is required and cannot be empty.");
                return;
            }

            if (string.IsNullOrEmpty(companyName))
            {
                ShowProfileError("Company / Organization Name is required.");
                return;
            }

            // Only the record of the signed-in supervisor can be changed (there is no fallback record)
            string recordId = Session["dbRecordId"] as string;
            if (string.IsNullOrEmpty(recordId))
            {
                ShowProfileError("Your supervisor record was not found, so nothing was saved. Please contact the coordinator.");
                return;
            }

            try
            {
                if (fuLogo.HasFile)
                {
                    byte[] image;
                    try { image = Cloudinary.ReadImage(fuLogo); }
                    catch (FormatException ex) { ShowProfileError(ex.Message); return; }
                    uploadedId = "uims/company-logos/" + Guid.NewGuid().ToString("N");
                    profilePic = await Cloudinary.Upload(image, uploadedId);
                }

                var patchPayload = new
                {
                    Name = fullName,
                    CompanyName = companyName,
                    Location = location,
                    PhoneNumber = phone,
                    ProfilePicUrl = profilePic
                };
                var response = await FirebaseDb.Patch(TableCompany, recordId, patchPayload);
                if (!response.IsSuccessStatusCode)
                {
                    if (uploadedId != null) await Cloudinary.Delete(uploadedId);
                    ShowProfileError("Firebase did not accept the changes, so nothing was saved. Please try again.");
                    return;
                }
                ViewState["logo"] = profilePic;

                // Update active user session
                Session["name"] = fullName;
                Session["companyName"] = companyName;

                // Refresh overview panel
                litProfileName.Text = Server.HtmlEncode(fullName);
                litBadgeCompanyName.Text = Server.HtmlEncode(companyName);
                litProfileCompany.Text = Server.HtmlEncode(companyName);
                litProfilePhone.Text = Server.HtmlEncode(!string.IsNullOrWhiteSpace(phone) ? phone : "Not provided");
                litProfileLocation.Text = Server.HtmlEncode(!string.IsNullOrWhiteSpace(location) ? location : "Not specified");

                if (!string.IsNullOrWhiteSpace(profilePic) && Uri.IsWellFormedUriString(profilePic, UriKind.Absolute))
                {
                    pnlImageAvatar.Visible = true;
                    pnlInitialsAvatar.Visible = false;
                    imgAvatar.ImageUrl = profilePic;
                }
                else
                {
                    pnlImageAvatar.Visible = false;
                    pnlInitialsAvatar.Visible = true;
                    litAvatarInitials.Text = Server.HtmlEncode(GetInitials(fullName));
                }

                ShowProfileSuccess("Your company supervisor profile has been saved successfully.");
            }
            catch (Exception ex)
            {
                if (uploadedId != null) await Cloudinary.Delete(uploadedId);
                ShowProfileError("Failed to save changes: " + Server.HtmlEncode(ex.Message));
            }
        }

        /// <summary>
        /// Resets form changes back to current saved state.
        /// </summary>
        protected async void btnCancelDetails_Click(object sender, EventArgs e)
        {
            await LoadCompanySupervisorProfileAsync();
        }

        /// <summary>
        /// Updates the supervisor password in Firebase Auth REST.
        /// </summary>
        protected async void btnSavePassword_Click(object sender, EventArgs e)
        {
            ClearAlerts();

            string currentPassword = txtCurrentPassword.Text;
            string newPassword = txtNewPassword.Text;
            string confirmPassword = txtConfirmPassword.Text;

            if (string.IsNullOrEmpty(currentPassword))
            {
                ShowPasswordError("Please enter your current password.");
                return;
            }

            if (string.IsNullOrEmpty(newPassword) || string.IsNullOrEmpty(confirmPassword))
            {
                ShowPasswordError("Please enter both the new password and its confirmation.");
                return;
            }

            if (newPassword == currentPassword)
            {
                ShowPasswordError("Choose a new password that is different from the current one.");
                return;
            }

            if (newPassword.Length < 6)
            {
                ShowPasswordError("New password must be at least 6 characters long.");
                return;
            }

            if (newPassword != confirmPassword)
            {
                ShowPasswordError("New password and confirmation password do not match.");
                return;
            }

            string idToken = AuthHelper.IdToken;

            try
            {
                // Update password in Firebase Auth if live token is present
                if (!string.IsNullOrEmpty(idToken))
                {
                    // The current password must be correct: sign in with it first (a session left open must not be enough to change it)
                    var verifyBody = new StringContent(JsonConvert.SerializeObject(new
                    {
                        email = AuthHelper.UserEmail,
                        password = currentPassword,
                        returnSecureToken = true
                    }), Encoding.UTF8, "application/json");
                    using (var verify = await FirebaseDb.client.PostAsync(AppConfig.SignInUrl, verifyBody))
                    {
                        if (!verify.IsSuccessStatusCode)
                        {
                            ShowPasswordError("The current password is not correct.");
                            return;
                        }
                    }

                    var payload = new
                    {
                        idToken = idToken,
                        password = newPassword,
                        returnSecureToken = true
                    };

                    var content = new StringContent(JsonConvert.SerializeObject(payload), Encoding.UTF8, "application/json");
                    var response = await FirebaseDb.client.PostAsync(AppConfig.UpdateAccountUrl, content);
                    string responseJson = await response.Content.ReadAsStringAsync();

                    if (!response.IsSuccessStatusCode)
                    {
                        string rawError = responseJson;
                        try
                        {
                            var errObj = JObject.Parse(responseJson);
                            rawError = errObj["error"]?["message"]?.ToString() ?? responseJson;
                        }
                        catch { }

                        ShowPasswordError(AuthHelper.GetFriendlyAuthError(rawError));
                        return;
                    }

                    // Refresh token in session
                    try
                    {
                        var authObj = JObject.Parse(responseJson);
                        string newToken = authObj["idToken"]?.ToString();
                        if (!string.IsNullOrEmpty(newToken))
                        {
                            Session["idToken"] = newToken;
                        }
                    }
                    catch { }
                }

                // Clear input controls
                txtCurrentPassword.Text = string.Empty;
                txtNewPassword.Text = string.Empty;
                txtConfirmPassword.Text = string.Empty;

                ShowPasswordSuccess("Your password has been changed successfully.");
            }
            catch (Exception ex)
            {
                ShowPasswordError("Error updating password: " + Server.HtmlEncode(ex.Message));
            }
        }

        #endregion

        #region Helpers

        private void ClearAlerts()
        {
            pnlProfileSuccess.Visible = false;
            pnlProfileError.Visible = false;
            pnlPasswordSuccess.Visible = false;
            pnlPasswordError.Visible = false;
        }

        private void ShowProfileSuccess(string message)
        {
            pnlProfileSuccess.Visible = true;
            litProfileSuccess.Text = message;
        }

        private void ShowProfileError(string message)
        {
            pnlProfileError.Visible = true;
            litProfileError.Text = message;
        }

        private void ShowPasswordSuccess(string message)
        {
            pnlPasswordSuccess.Visible = true;
            litPasswordSuccess.Text = message;
        }

        private void ShowPasswordError(string message)
        {
            pnlPasswordError.Visible = true;
            litPasswordError.Text = message;

            string script = "if (window.openPasswordModal) { window.openPasswordModal(); }";
            ClientScript.RegisterStartupScript(GetType(), "OpenPasswordModal", script, true);
        }

        #endregion
    }
}
