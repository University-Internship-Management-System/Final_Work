<%@ Page Title="Account Settings" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" Async="true" CodeBehind="SupervisorAccount.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Company.SupervisorAccount.SupervisorAccount" %>

<asp:Content ID="HeadContent" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/Company/SupervisorAccount/css/supervisor-account.css") %>" />
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid px-0">

        <!-- Page Header -->
        <div class="account-header d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3">
            <div>
                <span class="account-eyebrow">Corporate Supervision Portal</span>
                <h1 class="account-title uims-page-title">Account &amp; Profile Settings</h1>
                <p class="account-subtitle">View and update your personal details, corporate profile, and change your password.</p>
            </div>
            <div class="d-flex align-items-center gap-2">
                <span class="badge badge-approved py-2 px-3">
                    <i class="bi bi-briefcase-fill me-1"></i> Company Supervisor
                </span>
            </div>
        </div>

        <!-- Global Alert Notifications -->
        <asp:Panel ID="pnlProfileSuccess" runat="server" Visible="false" CssClass="uims-alert uims-alert-success">
            <i class="bi bi-check-circle-fill uims-alert-icon"></i>
            <div><asp:Literal ID="litProfileSuccess" runat="server" /></div>
        </asp:Panel>

        <asp:Panel ID="pnlProfileError" runat="server" Visible="false" CssClass="uims-alert uims-alert-danger">
            <i class="bi bi-exclamation-triangle-fill uims-alert-icon"></i>
            <div><asp:Literal ID="litProfileError" runat="server" /></div>
        </asp:Panel>

        <asp:Panel ID="pnlPasswordSuccess" runat="server" Visible="false" CssClass="uims-alert uims-alert-success">
            <i class="bi bi-check-circle-fill uims-alert-icon"></i>
            <div><asp:Literal ID="litPasswordSuccess" runat="server" /></div>
        </asp:Panel>

        <div class="row g-4">

            <!-- Left Column: Profile Summary Overview -->
            <div class="col-lg-4">
                <div class="uims-card profile-overview-card">
                    <div class="profile-avatar-wrapper">
                        <asp:Panel ID="pnlImageAvatar" runat="server" Visible="false">
                            <asp:Image ID="imgAvatar" runat="server" CssClass="profile-avatar-image" AlternateText="Company logo" />
                        </asp:Panel>
                        <asp:Panel ID="pnlInitialsAvatar" runat="server" Visible="true">
                            <div class="profile-avatar-circle">
                                <asp:Literal ID="litAvatarInitials" runat="server">CS</asp:Literal>
                            </div>
                        </asp:Panel>
                        <span class="profile-role-badge" title="Corporate Training Partner">
                            <i class="bi bi-briefcase-fill"></i>
                        </span>
                    </div>

                    <h2 class="profile-name">
                        <asp:Literal ID="litProfileName" runat="server" />
                    </h2>
                    <div class="profile-role-text">
                        <i class="bi bi-person-badge me-1"></i>
                        <asp:Literal ID="litProfileRole" runat="server">Company Supervisor</asp:Literal>
                    </div>

                    <div class="d-flex justify-content-center gap-2 mb-3">
                        <span class="badge badge-submitted">
                            <i class="bi bi-building me-1"></i>
                            <asp:Literal ID="litBadgeCompanyName" runat="server">Partner Company</asp:Literal>
                        </span>
                    </div>

                    <div class="profile-meta-list">
                        <div class="profile-meta-item">
                            <i class="bi bi-building profile-meta-icon"></i>
                            <div>
                                <div class="profile-meta-label">Company / Organization</div>
                                <div class="profile-meta-value">
                                    <asp:Literal ID="litProfileCompany" runat="server" />
                                </div>
                            </div>
                        </div>

                        <div class="profile-meta-item">
                            <i class="bi bi-envelope-fill profile-meta-icon"></i>
                            <div>
                                <div class="profile-meta-label">Corporate Email</div>
                                <div class="profile-meta-value">
                                    <asp:Literal ID="litProfileEmail" runat="server" />
                                </div>
                            </div>
                        </div>

                        <div class="profile-meta-item">
                            <i class="bi bi-telephone-fill profile-meta-icon"></i>
                            <div>
                                <div class="profile-meta-label">Phone Number</div>
                                <div class="profile-meta-value">
                                    <asp:Literal ID="litProfilePhone" runat="server" />
                                </div>
                            </div>
                        </div>

                        <div class="profile-meta-item">
                            <i class="bi bi-geo-alt-fill profile-meta-icon"></i>
                            <div>
                                <div class="profile-meta-label">Office / Headquarters Location</div>
                                <div class="profile-meta-value">
                                    <asp:Literal ID="litProfileLocation" runat="server" />
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="notice-box mt-4">
                        <i class="bi bi-info-circle-fill"></i>
                        <div>
                            <strong>Corporate Partnership</strong>
                            Internship vacancies, trainee progress diaries, and final evaluations are coordinated directly with the KASIT Field Training Committee.
                        </div>
                    </div>
                </div>
            </div>

            <!-- Right Column: Edit Details & Change Password -->
            <div class="col-lg-8">

                <!-- Section 1: View & Update Personal / Corporate Details -->
                <div class="uims-card">
                    <div class="uims-card-header">
                        <div class="uims-card-header-icon">
                            <i class="bi bi-building-gear"></i>
                        </div>
                        <div>
                            <h2 class="uims-card-header-title">Personal &amp; Company Information</h2>
                            <p class="uims-card-header-subtitle">Update your corporate contact information and organization details.</p>
                        </div>
                    </div>

                    <div class="uims-card-body">
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label for="<%= txtFullName.ClientID %>" class="form-label">
                                    Full Name <span class="text-danger">*</span>
                                </label>
                                <asp:TextBox ID="txtFullName" runat="server" CssClass="form-control" placeholder="e.g. Omar Al-Khatib" MaxLength="100" />
                                <span class="input-hint">Supervisor contact person name displayed on student evaluations.</span>
                            </div>

                            <div class="col-md-6">
                                <label for="<%= txtCompanyName.ClientID %>" class="form-label">
                                    Company / Organization Name <span class="text-danger">*</span>
                                </label>
                                <asp:TextBox ID="txtCompanyName" runat="server" CssClass="form-control" placeholder="e.g. ProgressSoft Corporation" MaxLength="150" />
                                <span class="input-hint">Official commercial name registered with the university.</span>
                            </div>

                            <div class="col-md-6">
                                <label for="<%= txtEmail.ClientID %>" class="form-label">
                                    Corporate Email Address
                                </label>
                                <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control" ReadOnly="true" />
                                <span class="input-hint"><i class="bi bi-lock me-1"></i> Primary login identity (Verified by UIMS).</span>
                            </div>

                            <div class="col-md-6">
                                <label for="<%= txtPhoneNumber.ClientID %>" class="form-label">
                                    Contact Phone Number
                                </label>
                                <asp:TextBox ID="txtPhoneNumber" runat="server" CssClass="form-control" placeholder="e.g. 0790000000" MaxLength="20" />
                                <span class="input-hint">Used for urgent university inquiries and trainee coordination.</span>
                            </div>

                            <div class="col-md-12">
                                <label for="<%= txtLocation.ClientID %>" class="form-label">
                                    Office / Headquarters Location
                                </label>
                                <asp:TextBox ID="txtLocation" runat="server" CssClass="form-control" placeholder="e.g. King Hussein Business Park, Bldg 23, Amman" MaxLength="150" />
                                <span class="input-hint">Physical company location where students undergo onsite training.</span>
                            </div>

                            <div class="col-12">
                                <label for="<%= fuLogo.ClientID %>" class="form-label">
                                    Company Logo
                                </label>
                                <asp:FileUpload ID="fuLogo" runat="server" CssClass="form-control" accept=".jpg,.jpeg,.png,image/jpeg,image/png" />
                                <span class="input-hint">JPG or PNG, up to 2 MB. Students see it on the opportunity cards. Leave empty to keep the current logo.</span>
                            </div>
                        </div>

                        <div class="form-actions">
                            <asp:Button ID="btnSaveDetails" runat="server" CssClass="btn-uims-primary" Text="Save Details" OnClick="btnSaveDetails_Click" />
                            <asp:Button ID="btnCancelDetails" runat="server" CssClass="btn-uims-secondary" Text="Reset Changes" OnClick="btnCancelDetails_Click" CausesValidation="false" />
                        </div>
                    </div>
                </div>

                <!-- Section 2: Account Security & Password -->
                <div class="uims-card">
                    <div class="uims-card-header">
                        <div class="uims-card-header-icon">
                            <i class="bi bi-shield-lock"></i>
                        </div>
                        <div>
                            <h2 class="uims-card-header-title">Account Security</h2>
                            <p class="uims-card-header-subtitle">Update your password to keep your company supervisor account secure.</p>
                        </div>
                    </div>

                    <div class="uims-card-body">
                        <div class="d-flex flex-column flex-sm-row justify-content-between align-items-sm-center gap-3">
                            <div>
                                <h3 class="security-action-title">Supervisor Account Password</h3>
                                <p class="security-action-desc">
                                    Regularly updating your password ensures the security of your corporate account, company profile, and assigned student evaluations.
                                </p>
                            </div>
                            <div>
                                <button type="button" class="btn-uims-primary text-nowrap d-inline-flex align-items-center gap-2" data-bs-toggle="modal" data-bs-target="#changePasswordModal">
                                    <i class="bi bi-key-fill"></i>
                                    <span>Change Password</span>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

        </div>

    </div>

    <!-- Change Password Popup Modal -->
    <div class="modal fade" id="changePasswordModal" tabindex="-1" aria-labelledby="changePasswordModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content modal-uims-card">
                <div class="modal-header">
                    <div class="d-flex align-items-center gap-2">
                        <div class="modal-header-icon">
                            <i class="bi bi-shield-lock-fill"></i>
                        </div>
                        <div>
                            <h5 class="modal-title fw-bold" id="changePasswordModalLabel">Change Password</h5>
                            <p class="modal-subtitle mb-0">Update your password to keep your supervisor account secure.</p>
                        </div>
                    </div>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>

                <div class="modal-body p-4">
                    <!-- In-Modal Alert for Password Errors -->
                    <asp:Panel ID="pnlPasswordError" runat="server" Visible="false" CssClass="uims-alert uims-alert-danger mb-3">
                        <i class="bi bi-exclamation-triangle-fill uims-alert-icon"></i>
                        <div><asp:Literal ID="litPasswordError" runat="server" /></div>
                    </asp:Panel>

                    <div class="mb-3">
                        <label for="<%= txtCurrentPassword.ClientID %>" class="form-label">
                            Current Password
                        </label>
                        <div class="password-toggle-group">
                            <asp:TextBox ID="txtCurrentPassword" runat="server" CssClass="form-control" TextMode="Password" placeholder="Enter current password" autocomplete="current-password" />
                            <button type="button" class="password-toggle-btn" data-target="<%= txtCurrentPassword.ClientID %>" aria-label="Show password">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                        <span class="input-hint">Required to verify your identity before applying password updates.</span>
                    </div>

                    <div class="mb-3">
                        <label for="<%= txtNewPassword.ClientID %>" class="form-label">
                            New Password <span class="text-danger">*</span>
                        </label>
                        <div class="password-toggle-group">
                            <asp:TextBox ID="txtNewPassword" runat="server" CssClass="form-control" TextMode="Password" placeholder="Minimum 6 characters" data-role="new-password" autocomplete="new-password" />
                            <button type="button" class="password-toggle-btn" data-target="<%= txtNewPassword.ClientID %>" aria-label="Show password">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label for="<%= txtConfirmPassword.ClientID %>" class="form-label">
                            Confirm New Password <span class="text-danger">*</span>
                        </label>
                        <div class="password-toggle-group">
                            <asp:TextBox ID="txtConfirmPassword" runat="server" CssClass="form-control" TextMode="Password" placeholder="Repeat new password" data-role="confirm-password" autocomplete="new-password" />
                            <button type="button" class="password-toggle-btn" data-target="<%= txtConfirmPassword.ClientID %>" aria-label="Show password">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                    </div>

                    <!-- Security Checklist -->
                    <div class="security-checklist mt-3">
                        <div class="security-checklist-title">Password Security Requirements</div>
                        <ul class="security-checklist-items">
                            <li id="ruleLength"><i class="bi bi-circle text-muted"></i> At least 6 characters long</li>
                            <li id="ruleMatch"><i class="bi bi-circle text-muted"></i> New password and confirmation match</li>
                        </ul>
                    </div>
                </div>

                <div class="modal-footer">
                    <button type="button" class="btn-uims-secondary" data-bs-dismiss="modal">Cancel</button>
                    <asp:Button ID="btnSavePassword" runat="server" CssClass="btn-uims-primary" Text="Update Password" OnClick="btnSavePassword_Click" />
                </div>
            </div>
        </div>
    </div>

    <!-- Supervisor Account Scripts -->
    <script src="<%= ResolveUrl("~/Company/SupervisorAccount/javascript/supervisor-account.js") %>"></script>
</asp:Content>
