<%@ Page Title="Account Settings" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" Async="true" CodeBehind="SupervisorAccount.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Academic.SupervisorAccount.SupervisorAccount" %>

<asp:Content ID="HeadContent" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/Academic/SupervisorAccount/css/supervisor-account.css") %>" />
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid px-0">

        <!-- Page Header -->
        <div class="account-header d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3">
            <div>
                <span class="account-eyebrow">Academic Supervision Portal</span>
                <h1 class="account-title">Account &amp; Profile Settings</h1>
                <p class="account-subtitle">View and update your personal details, faculty profile, and change your password.</p>
            </div>
            <div class="d-flex align-items-center gap-2">
                <span class="badge badge-approved py-2 px-3">
                    <i class="bi bi-shield-check me-1"></i>Faculty Supervisor
                </span>
            </div>
        </div>

        <!-- Global Alert Notifications -->
        <asp:Panel ID="pnlProfileSuccess" runat="server" Visible="false" CssClass="uims-alert uims-alert-success">
            <i class="bi bi-check-circle-fill uims-alert-icon"></i>
            <div>
                <asp:Literal ID="litProfileSuccess" runat="server" /></div>
        </asp:Panel>

        <asp:Panel ID="pnlProfileError" runat="server" Visible="false" CssClass="uims-alert uims-alert-danger">
            <i class="bi bi-exclamation-triangle-fill uims-alert-icon"></i>
            <div>
                <asp:Literal ID="litProfileError" runat="server" /></div>
        </asp:Panel>

        <asp:Panel ID="pnlPasswordSuccess" runat="server" Visible="false" CssClass="uims-alert uims-alert-success">
            <i class="bi bi-check-circle-fill uims-alert-icon"></i>
            <div>
                <asp:Literal ID="litPasswordSuccess" runat="server" /></div>
        </asp:Panel>

        <asp:Panel ID="pnlPasswordError" runat="server" Visible="false" CssClass="uims-alert uims-alert-danger">
            <i class="bi bi-exclamation-triangle-fill uims-alert-icon"></i>
            <div>
                <asp:Literal ID="litPasswordError" runat="server" /></div>
        </asp:Panel>

        <div class="row g-4">

            <!-- Left Column: Profile Summary Overview -->
            <div class="col-lg-4">
                <div class="uims-card profile-overview-card">
                    <div class="profile-avatar-wrapper">
                        <asp:Panel ID="pnlImageAvatar" runat="server" Visible="false">
                            <asp:Image ID="imgAvatar" runat="server" CssClass="profile-avatar-image" AlternateText="Supervisor Avatar" />
                        </asp:Panel>
                        <asp:Panel ID="pnlInitialsAvatar" runat="server" Visible="true">
                            <div class="profile-avatar-circle">
                                <asp:Literal ID="litAvatarInitials" runat="server">AS</asp:Literal>
                            </div>
                        </asp:Panel>
                        <span class="profile-role-badge" title="Faculty of Information Technology (KASIT)">
                            <i class="bi bi-award-fill"></i>
                        </span>
                    </div>

                    <h2 class="profile-name">
                        <asp:Literal ID="litProfileName" runat="server" />
                    </h2>
                    <div class="profile-role-text">
                        <i class="bi bi-mortarboard me-1"></i>
                        <asp:Literal ID="litProfileRole" runat="server">Academic Supervisor</asp:Literal>
                    </div>

                    <div class="d-flex justify-content-center gap-2 mb-3">
                        <span class="badge badge-submitted">
                            <i class="bi bi-building me-1"></i>KASIT - JU
                        </span>
                    </div>

                    <div class="profile-meta-list">
                        <div class="profile-meta-item">
                            <i class="bi bi-grid-fill profile-meta-icon"></i>
                            <div>
                                <div class="profile-meta-label">Department</div>
                                <div class="profile-meta-value">
                                    <asp:Literal ID="litProfileMajor" runat="server" />
                                </div>
                            </div>
                        </div>

                        <div class="profile-meta-item">
                            <i class="bi bi-envelope-fill profile-meta-icon"></i>
                            <div>
                                <div class="profile-meta-label">Institutional Email</div>
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
                                <div class="profile-meta-label">Office Location</div>
                                <div class="profile-meta-value">
                                    <asp:Literal ID="litProfileOffice" runat="server" />
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="notice-box mt-4">
                        <i class="bi bi-info-circle-fill"></i>
                        <div>
                            <strong>Departmental Assignment</strong>
                            Trainee allocations and academic supervision loads are coordinated directly by the KASIT Field Training Committee.
                        </div>
                    </div>
                </div>
            </div>

            <!-- Right Column: Edit Details & Change Password -->
            <div class="col-lg-8">

                <!-- Section 1: View & Update Personal / Academic Details -->
                <div class="uims-card">
                    <div class="uims-card-header">
                        <div class="uims-card-header-icon">
                            <i class="bi bi-person-gear"></i>
                        </div>
                        <div>
                            <h2 class="uims-card-header-title">Personal &amp; Faculty Information</h2>
                            <p class="uims-card-header-subtitle">Update your official contact information and academic specialization.</p>
                        </div>
                    </div>

                    <div class="uims-card-body">
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label for="<%= txtFullName.ClientID %>" class="form-label">
                                    Full Name <span class="text-danger">*</span>
                                </label>
                                <asp:TextBox ID="txtFullName" runat="server" CssClass="form-control" placeholder="Dr. First Last" MaxLength="100" />
                                <span class="input-hint">Displayed across supervised student diaries and reviews.</span>
                            </div>

                            <div class="col-md-6">
                                <label for="<%= ddlMajor.ClientID %>" class="form-label">
                                    Academic Department <span class="text-danger">*</span>
                                </label>
                                <asp:DropDownList ID="ddlMajor" runat="server" CssClass="form-select">
                                    <asp:ListItem Text="Computer Science" Value="Computer Science" />
                                    <asp:ListItem Text="Software Engineering" Value="Software Engineering" />
                                    <asp:ListItem Text="Computer Information Systems" Value="Computer Information Systems" />
                                    <asp:ListItem Text="Artificial Intelligence" Value="Artificial Intelligence" />
                                    <asp:ListItem Text="Cyber Security" Value="Cyber Security" />
                                    <asp:ListItem Text="Data Science" Value="Data Science" />
                                </asp:DropDownList>
                                <span class="input-hint">Your primary department within KASIT.</span>
                            </div>

                            <div class="col-md-6">
                                <label for="<%= txtEmail.ClientID %>" class="form-label">
                                    University Email Address
                                </label>
                                <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control" ReadOnly="true" />
                                <span class="input-hint"><i class="bi bi-lock me-1"></i>Institutional login identity (Managed by UJ IT Center).</span>
                            </div>

                            <div class="col-md-6">
                                <label for="<%= txtPhoneNumber.ClientID %>" class="form-label">
                                    Phone Number
                                </label>
                                <asp:TextBox ID="txtPhoneNumber" runat="server" CssClass="form-control" placeholder="e.g. 0790000000" MaxLength="20" />
                                <span class="input-hint">Used for urgent notifications and coordinator contact.</span>
                            </div>

                            <div class="col-md-6">
                                <label for="<%= txtOfficeNumber.ClientID %>" class="form-label">
                                    Office Number
                                </label>
                                <asp:TextBox ID="txtOfficeNumber" runat="server" CssClass="form-control" placeholder="e.g. IT-304" MaxLength="50" />
                                <span class="input-hint">KASIT building room number for student consultations.</span>
                            </div>

                            <div class="col-12">
                                <label for="<%= txtProfilePicUrl.ClientID %>" class="form-label">
                                    Profile Picture URL
                                </label>
                                <asp:TextBox ID="txtProfilePicUrl" runat="server" CssClass="form-control" placeholder="https://example.com/avatar.jpg" MaxLength="500" />
                                <span class="input-hint">Enter an image URL or leave blank to display your name initials.</span>
                            </div>
                        </div>

                        <div class="form-actions">
                            <asp:Button ID="btnSaveDetails" runat="server" CssClass="btn-uims-primary" Text="Save Details" OnClick="btnSaveDetails_Click" />
                            <asp:Button ID="btnCancelDetails" runat="server" CssClass="btn-uims-secondary" Text="Reset Changes" OnClick="btnCancelDetails_Click" CausesValidation="false" />
                        </div>
                    </div>
                </div>

                <!-- Section 2: Change Account Password -->
                <div class="uims-card">
                    <div class="uims-card-header">
                        <div class="uims-card-header-icon">
                            <i class="bi bi-shield-lock"></i>
                        </div>
                        <div>
                            <h2 class="uims-card-header-title">Change Password</h2>
                            <p class="uims-card-header-subtitle">Update your password to keep your academic supervisor account secure.</p>
                        </div>
                    </div>

                    <div class="uims-card-body">
                        <div class="row g-3">
                            <div class="col-md-12">
                                <label for="<%= txtCurrentPassword.ClientID %>" class="form-label">
                                    Current Password
                                </label>
                                <div class="password-toggle-group">
                                    <asp:TextBox ID="txtCurrentPassword" runat="server" CssClass="form-control" TextMode="Password" placeholder="Enter current password" autocomplete="current-password" />
                                    <button type="button" class="password-toggle-btn" data-target="<%= txtCurrentPassword.ClientID %>" aria-label="Show password">
                                        <i class="bi bi-eye"></i>
                                    </button>
                                </div>
                                <span class="input-hint">Required to verify your authorization before applying updates.</span>
                            </div>

                            <div class="col-md-6">
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

                            <div class="col-md-6">
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
                        </div>

                        <!-- Security Checklist -->
                        <div class="security-checklist mt-3">
                            <div class="security-checklist-title">Password Security Requirements</div>
                            <ul class="security-checklist-items">
                                <li id="ruleLength"><i class="bi bi-circle text-muted"></i>At least 6 characters long</li>
                                <li id="ruleMatch"><i class="bi bi-circle text-muted"></i>New password and confirmation match</li>
                            </ul>
                        </div>

                        <div class="form-actions">
                            <asp:Button ID="btnSavePassword" runat="server" CssClass="btn-uims-primary" Text="Update Password" OnClick="btnSavePassword_Click" />
                        </div>
                    </div>
                </div>

            </div>

        </div>

    </div>

    <!-- Supervisor Account Scripts -->
    <script src="<%= ResolveUrl("~/Academic/SupervisorAccount/javascript/supervisor-account.js") %>"></script>
</asp:Content>
