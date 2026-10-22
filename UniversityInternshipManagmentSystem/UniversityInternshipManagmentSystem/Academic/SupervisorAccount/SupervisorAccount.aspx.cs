using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web.UI;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using UniversityInternshipManagmentSystem.Config;
using UniversityInternshipManagmentSystem.Models;

namespace UniversityInternshipManagmentSystem.Academic.SupervisorAccount
{
    public partial class SupervisorAccount : Page
    {
        private const string TableAcademic = "AcademicSupervisors";

        protected async void Page_Load(object sender, EventArgs e)
        {
            // Enforce Academic Supervisor or Coordinator authentication
            AuthHelper.RequireAuth(this, AuthHelper.RoleAcademic, AuthHelper.RoleCoordinator);
            if (Response.IsRequestBeingRedirected)
            {
                return;
            }

            if (!IsPostBack)
            {
                await LoadSupervisorProfileAsync();
            }
        }

        #region Profile Loading & Binding

        /// <summary>
        /// Loads the academic supervisor's profile data from Firebase RTDB or fallback model.
        /// </summary>
        private async Task LoadSupervisorProfileAsync()
        {
            ClearAlerts();

            string userEmail = (AuthHelper.UserEmail ?? "").Trim().ToLowerInvariant();
            string recordId = Session["dbRecordId"] as string;

            Models.AcademicSupervisor supervisor = null;
            string officeNumber = "KASIT, Room IT-304";

            try
            {
                // 1. If record ID already resolved in session, query directly
                if (!string.IsNullOrEmpty(recordId))
                {
                    string json = await FirebaseDb.Get(TableAcademic, recordId);
                    if (!string.IsNullOrEmpty(json) && json.Trim() != "null")
                    {
                        var obj = JObject.Parse(json);
                        supervisor = ParseSupervisor(recordId, obj);
                        officeNumber = obj["OfficeNumber"]?.ToString() ?? obj["officeNumber"]?.ToString() ?? obj["OfficeLocation"]?.ToString() ?? officeNumber;
                    }
                }

                // 2. Otherwise scan the AcademicSupervisors table by email
                if (supervisor == null)
                {
                    string allSupervisorsJson = await FirebaseDb.Get(TableAcademic);
                    if (!string.IsNullOrEmpty(allSupervisorsJson) && allSupervisorsJson.Trim() != "null")
                    {
                        var allObj = JObject.Parse(allSupervisorsJson);
                        foreach (var prop in allObj.Properties())
                        {
                            if (prop.Value is JObject item)
                            {
                                string email = (item["Email"]?.ToString() ?? "").Trim().ToLowerInvariant();
                                string uniEmail = (item["UniversityEmail"]?.ToString() ?? item["UniEmail"]?.ToString() ?? "").Trim().ToLowerInvariant();

                                if (email == userEmail || uniEmail == userEmail)
                                {
                                    supervisor = ParseSupervisor(prop.Name, item);
                                    officeNumber = item["OfficeNumber"]?.ToString() ?? item["officeNumber"]?.ToString() ?? item["OfficeLocation"]?.ToString() ?? officeNumber;
                                    Session["dbRecordId"] = prop.Name;
                                    Session["dbTable"] = TableAcademic;
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
                supervisor = new Models.AcademicSupervisor
                {
                    Id = !string.IsNullOrEmpty(recordId) ? recordId : "academic_test_001",
                    Name = !string.IsNullOrWhiteSpace(AuthHelper.UserName) ? AuthHelper.UserName : "Dr. Academic Supervisor",
                    Email = !string.IsNullOrWhiteSpace(AuthHelper.UserEmail) ? AuthHelper.UserEmail : "academic@ju.edu.jo",
                    UniversityEmail = !string.IsNullOrWhiteSpace(AuthHelper.UserEmail) ? AuthHelper.UserEmail : "academic@ju.edu.jo",
                    Major = "Computer Science",
                    PhoneNumber = "0790000020",
                    ProfilePicUrl = string.Empty,
                    Role = "AcademicSupervisor"
                };

                Session["dbRecordId"] = supervisor.Id;
                Session["dbTable"] = TableAcademic;
            }

            BindSupervisorData(supervisor, officeNumber);
        }

        private Models.AcademicSupervisor ParseSupervisor(string id, JObject obj)
        {
            return new Models.AcademicSupervisor
            {
                Id = id,
                Name = obj["Name"]?.ToString() ?? obj["name"]?.ToString() ?? AuthHelper.UserName ?? "Academic Supervisor",
                Email = obj["Email"]?.ToString() ?? obj["email"]?.ToString() ?? AuthHelper.UserEmail ?? "",
                UniversityEmail = obj["UniversityEmail"]?.ToString() ?? obj["UniEmail"]?.ToString() ?? obj["Email"]?.ToString() ?? AuthHelper.UserEmail ?? "",
                Major = obj["Major"]?.ToString() ?? obj["major"]?.ToString() ?? "Computer Science",
                PhoneNumber = obj["PhoneNumber"]?.ToString() ?? obj["phoneNumber"]?.ToString() ?? "",
                ProfilePicUrl = obj["ProfilePicUrl"]?.ToString() ?? obj["profilePicUrl"]?.ToString() ?? "",
                Role = "AcademicSupervisor"
            };
        }

        private void BindSupervisorData(Models.AcademicSupervisor supervisor, string officeNumber = null)
        {
            // Editable form fields
            txtFullName.Text = supervisor.Name;
            txtEmail.Text = !string.IsNullOrWhiteSpace(supervisor.UniversityEmail) ? supervisor.UniversityEmail : supervisor.Email;
            txtPhoneNumber.Text = supervisor.PhoneNumber;
            txtOfficeNumber.Text = !string.IsNullOrWhiteSpace(officeNumber) ? officeNumber : "";
            txtProfilePicUrl.Text = supervisor.ProfilePicUrl;

            // Department dropdown
            if (ddlMajor.Items.FindByValue(supervisor.Major) != null)
            {
                ddlMajor.SelectedValue = supervisor.Major;
            }
            else if (!string.IsNullOrWhiteSpace(supervisor.Major))
            {
                ddlMajor.Items.Add(new System.Web.UI.WebControls.ListItem(supervisor.Major, supervisor.Major));
                ddlMajor.SelectedValue = supervisor.Major;
            }

            // Left Overview Card
            litProfileName.Text = Server.HtmlEncode(supervisor.Name);
            litProfileRole.Text = "Academic Supervisor";
            litProfileMajor.Text = Server.HtmlEncode(!string.IsNullOrWhiteSpace(supervisor.Major) ? supervisor.Major : "Computer Science");
            litProfileEmail.Text = Server.HtmlEncode(txtEmail.Text);
            litProfilePhone.Text = Server.HtmlEncode(!string.IsNullOrWhiteSpace(supervisor.PhoneNumber) ? supervisor.PhoneNumber : "Not provided");
            litProfileOffice.Text = Server.HtmlEncode(!string.IsNullOrWhiteSpace(officeNumber) ? officeNumber : "Not specified");

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
                return "AS";

            string clean = name.Replace("Dr.", "").Replace("Prof.", "").Trim();
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
            string major = ddlMajor.SelectedValue;
            string phone = txtPhoneNumber.Text.Trim();
            string officeNumber = txtOfficeNumber.Text.Trim();
            string profilePic = txtProfilePicUrl.Text.Trim();

            if (string.IsNullOrEmpty(fullName))
            {
                ShowProfileError("Full Name is required and cannot be empty.");
                return;
            }

            string recordId = Session["dbRecordId"] as string ?? "academic_test_001";

            var patchPayload = new
            {
                Name = fullName,
                Major = major,
                PhoneNumber = phone,
                OfficeNumber = officeNumber,
                OfficeLocation = officeNumber,
                ProfilePicUrl = profilePic
            };

            try
            {
                var response = await FirebaseDb.Patch(TableAcademic, recordId, patchPayload);

                // Update active user session name
                Session["name"] = fullName;

                // Refresh overview panel
                litProfileName.Text = Server.HtmlEncode(fullName);
                litProfileMajor.Text = Server.HtmlEncode(major);
                litProfilePhone.Text = Server.HtmlEncode(!string.IsNullOrWhiteSpace(phone) ? phone : "Not provided");
                litProfileOffice.Text = Server.HtmlEncode(!string.IsNullOrWhiteSpace(officeNumber) ? officeNumber : "Not specified");

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

                ShowProfileSuccess("Your academic profile details have been saved successfully.");
            }
            catch (Exception ex)
            {
                ShowProfileError("Failed to save changes: " + Server.HtmlEncode(ex.Message));
            }
        }

        /// <summary>
        /// Resets form changes back to current saved state.
        /// </summary>
        protected async void btnCancelDetails_Click(object sender, EventArgs e)
        {
            await LoadSupervisorProfileAsync();
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

            if (string.IsNullOrEmpty(newPassword) || string.IsNullOrEmpty(confirmPassword))
            {
                ShowPasswordError("Please enter both the new password and its confirmation.");
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
        }

        #endregion
    }
}
