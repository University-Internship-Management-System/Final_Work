<%@ Page Title="My Profile" Language="C#" ResponseEncoding="utf-8" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" Async="true" AsyncTimeout="90" CodeBehind="Profile.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Student.StudentProfilePage.Profile" %>
<asp:Content ID="PageHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/Student/Content/Student.css") %>" />
    <link rel="stylesheet" href="<%= ResolveUrl("~/Student/StudentProfilePage/Profile.css") %>" />
</asp:Content>
<asp:Content ID="ProfileContent" ContentPlaceHolderID="MainContent" runat="server">
    <div class="student-dashboard student-profile">
        <a class="sd-skip" href="#page-content">Skip to page content</a>
        <div id="student-request-status" class="sd-message" role="status" aria-live="polite" hidden></div>
        <% if (!string.IsNullOrEmpty(DataError)) { %><div class="sd-message" role="alert"><%: DataError %></div><% } %>
        <div id="page-content" tabindex="-1">
            <div class="sd-heading">
                <div><span class="sd-eyebrow">Your student identity</span><h1>My Profile</h1>
                    <p class="sd-muted">Your personal, academic and professional information, together.</p></div>
                <span class="sd-demo"><%: ModeLabel %></span>
            </div>
            <input type="hidden" name="StudentCsrf" value="<%: CsrfToken %>" />
            <asp:Label ID="SaveMessage" runat="server" CssClass="sd-save-message" role="status" aria-live="polite" />
            <% if (Workspace != null) { %>
            <section class="sd-profile-banner" aria-labelledby="profile-name">
                <div class="sd-avatar-shell">
                    <span class="sd-profile-avatar" aria-hidden="true"><%: DisplayName.Substring(0, 1).ToUpperInvariant() %></span>
                    <% if (SafeAvatarUrl != null) { %><img class="sd-profile-photo" src="<%: SafeAvatarUrl %>" alt="Student profile photo" referrerpolicy="no-referrer" /><% } %>
                </div>
                <div class="sd-profile-identity">
                    <h2 id="profile-name"><%: DisplayName %></h2><p><%: Show(Record.Major) %></p>
                    <span class="sd-badge mt-2">The University of Jordan &#183; &#1575;&#1604;&#1580;&#1575;&#1605;&#1593;&#1577; &#1575;&#1604;&#1571;&#1585;&#1583;&#1606;&#1610;&#1577;</span>
                </div>
                <span class="sd-count"><%: IsEditing ? "Editing draft" : "Profile overview" %></span>
            </section>
            <div class="sd-profile-actions" aria-label="Profile actions">
                <asp:Button ID="EditButton" runat="server" CssClass="sd-save-button" Text="Edit Profile" OnClick="EditButton_Click" CausesValidation="false" />
                <asp:Button ID="ValidateButton" runat="server" CssClass="sd-save-button" Text="Validate Changes" OnClick="ValidateButton_Click" CausesValidation="false" />
                <asp:Button ID="SaveButton" runat="server" CssClass="sd-save-button" Text="Save Changes" OnClick="SaveButton_Click" CausesValidation="false" aria-describedby="save-policy" />
                <asp:Button ID="CancelButton" runat="server" CssClass="btn btn-outline-primary sd-cancel-button" Text="Cancel" OnClick="CancelButton_Click" CausesValidation="false" />
            </div>
            <p id="save-policy" class="sd-mode-note">Edit your phone, skills and professional links, then choose Save Changes. Firebase permissions are enforced. Validate Changes checks without saving; Cancel discards unsaved changes.</p>
            <div class="row g-4">
                <div class="col-lg-6">
                    <section class="sd-panel" aria-labelledby="personal-title">
                        <div class="sd-panel-head"><h2 id="personal-title">Personal Information</h2><span class="sd-count">Identity read-only</span></div>
                        <div class="sd-panel-body">
                            <dl class="sd-details"><dt>Full name</dt><dd><%: Show(Record.Name) %></dd><dt>Account email</dt><dd><%: Show(Record.Email) %></dd></dl>
                            <asp:Label runat="server" AssociatedControlID="PhoneNumberInput" CssClass="form-label" Text="Phone number" />
                            <asp:TextBox ID="PhoneNumberInput" runat="server" EnableViewState="false" CssClass="form-control" MaxLength="30" TextMode="Phone" aria-describedby="phone-help PhoneError" />
                            <span id="phone-help" class="sd-note">Optional. Use 7–30 characters; include a country code where applicable.</span>
                            <asp:Label ID="PhoneError" runat="server" ClientIDMode="Static" CssClass="sd-field-error" />
                        </div>
                    </section>
                </div>
                <div class="col-lg-6">
                    <section class="sd-panel" aria-labelledby="academic-title">
                        <div class="sd-panel-head"><h2 id="academic-title">Academic Information</h2><span class="sd-count">Read-only</span></div>
                        <div class="sd-panel-body">
                            <dl class="sd-details">
                                <dt>University email</dt><dd><%: Show(Record.UniEmail) %></dd>
                                <dt>Major</dt><dd><%: Show(Record.Major) %></dd>
                                <dt>GPA</dt><dd><%: StudentGpa.HasValue ? StudentGpa.Value.ToString("0.##") : "Not provided" %><span class="sd-note d-block">As recorded; no grading scale is assumed.</span></dd>
                            </dl>
                            <p class="sd-note">Academic and account information is maintained by the university. Contact your coordinator for corrections.</p>
                        </div>
                    </section>
                </div>
                <div class="col-12">
                    <section class="sd-panel" aria-labelledby="training-title">
                        <div class="sd-panel-head"><h2 id="training-title">Training Information</h2><span class="sd-count">Read-only</span></div>
                        <div class="sd-panel-body">
                            <dl class="sd-training-grid">
                                <div><dt>Company</dt><dd><%: CompanyText %></dd></div>
                                <div><dt>Academic supervisor</dt><dd><%: SupervisorText %></dd></div>
                                <div><dt>Placement status</dt><dd><%: PlacementText %></dd></div>
                                <div><dt>Internship opportunity</dt><dd><%: OpportunityText %></dd></div>
                                <div><dt>Confirmation date</dt><dd><%: ConfirmationText %></dd></div>
                                <div><dt>Required training hours</dt><dd>Not available</dd></div>
                                <div><dt>Approved training hours</dt><dd>Not available</dd></div>
                            </dl>
                            <p class="sd-note"><%: TrainingNote %></p>
                        </div>
                    </section>
                </div>
                <div class="col-lg-6">
                    <section class="sd-panel" aria-labelledby="skills-title">
                        <div class="sd-panel-head"><h2 id="skills-title">Skills &amp; Competencies</h2></div>
                        <div class="sd-panel-body">
                            <asp:Label runat="server" AssociatedControlID="SkillsInput" CssClass="form-label" Text="Skills" />
                            <asp:TextBox ID="SkillsInput" runat="server" EnableViewState="false" CssClass="form-control" TextMode="MultiLine" Rows="7" aria-describedby="skills-help SkillsError" />
                            <span class="sd-note" id="skills-help">One skill per line. Up to 20 skills, 60 characters each. Empty means no skills listed; no proficiency level is assumed.</span>
                            <asp:Label ID="SkillsError" runat="server" ClientIDMode="Static" CssClass="sd-field-error" />
                        </div>
                    </section>
                </div>
                <div class="col-lg-6">
                    <section class="sd-panel" aria-labelledby="documents-title">
                        <div class="sd-panel-head"><h2 id="documents-title">CV &amp; Professional Portfolio</h2></div>
                        <div class="sd-panel-body">
                            <div class="mb-4">
                                <asp:Label runat="server" AssociatedControlID="CvInput" CssClass="form-label" Text="CV link" />
                                <asp:TextBox ID="CvInput" runat="server" EnableViewState="false" CssClass="form-control" MaxLength="2048" aria-describedby="cv-help CvError" />
                                <span id="cv-help" class="sd-note">Optional web link, up to 2048 characters. Use a shareable link to your CV; direct file upload is not configured.</span>
                                <asp:Label ID="CvError" runat="server" ClientIDMode="Static" CssClass="sd-field-error" />
                                <% if (SafeCvUrl != null) { %><a class="sd-document-link" href="<%: SafeCvUrl %>" target="_blank" rel="noopener noreferrer">Open saved CV &#8599;</a><% } else { %><p class="sd-note">No valid saved CV link provided.</p><% } %>
                            </div>
                            <asp:Label runat="server" AssociatedControlID="PortfolioInput" CssClass="form-label" Text="Portfolio link" />
                            <asp:TextBox ID="PortfolioInput" runat="server" EnableViewState="false" CssClass="form-control" MaxLength="2048" aria-describedby="portfolio-help PortfolioError" />
                            <span id="portfolio-help" class="sd-note">HTTP/HTTPS links accepted. Missing protocols become HTTPS; embedded credentials are rejected.</span>
                            <asp:Label ID="PortfolioError" runat="server" ClientIDMode="Static" CssClass="sd-field-error" />
                            <% if (SafePortfolioUrl != null) { %><a class="sd-document-link" href="<%: SafePortfolioUrl %>" target="_blank" rel="noopener noreferrer">Open saved portfolio &#8599;</a><% } else { %><p class="sd-note">No valid saved portfolio link provided.</p><% } %>
                        </div>
                    </section>
                </div>
            </div>
            <p class="mt-3"><a class="sd-document-link" href="<%= ResolveUrl("~/Student/StudentDashboardPage/Dashboard.aspx") %>">Open Student Dashboard</a></p>
            <section class="sd-panel sd-security-panel mt-4" aria-labelledby="security-title">
                <div class="sd-panel-head"><h2 id="security-title"><i class="bi bi-shield-lock" aria-hidden="true"></i> Account Security</h2></div>
                <div class="sd-panel-body sd-security-body">
                    <div><p class="mb-1">Keep your account secure by updating your password when needed.</p>
                        <asp:Label ID="PasswordSuccess" runat="server" CssClass="sd-save-message sd-save-success" role="status" aria-live="polite" /></div>
                    <button type="button" class="btn btn-outline-primary" data-bs-toggle="modal" data-bs-target="#resetPasswordModal">Reset Password</button>
                </div>
            </section>
            <div class="modal fade" id="resetPasswordModal" tabindex="-1" aria-labelledby="resetPasswordTitle" aria-hidden="true">
                <div class="modal-dialog modal-dialog-centered"><div class="modal-content">
                    <div class="modal-header"><h2 class="modal-title fs-5" id="resetPasswordTitle">Reset Password</h2>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button></div>
                    <div class="modal-body">
                        <p class="sd-note">Enter your current password, then choose a new password.</p>
                        <asp:Label ID="PasswordError" runat="server" CssClass="sd-save-message sd-save-error" role="alert" />
                        <div class="mb-3"><asp:Label runat="server" AssociatedControlID="CurrentPasswordInput" CssClass="form-label" Text="Current password" />
                            <asp:TextBox ID="CurrentPasswordInput" runat="server" TextMode="Password" CssClass="form-control" MaxLength="128" autocomplete="current-password" /></div>
                        <div class="mb-3"><asp:Label runat="server" AssociatedControlID="NewPasswordInput" CssClass="form-label" Text="New password" />
                            <asp:TextBox ID="NewPasswordInput" runat="server" TextMode="Password" CssClass="form-control" MaxLength="128" autocomplete="new-password" />
                            <small class="sd-note">Use at least 6 characters.</small></div>
                        <div><asp:Label runat="server" AssociatedControlID="ConfirmPasswordInput" CssClass="form-label" Text="Confirm new password" />
                            <asp:TextBox ID="ConfirmPasswordInput" runat="server" TextMode="Password" CssClass="form-control" MaxLength="128" autocomplete="new-password" /></div>
                    </div>
                    <div class="modal-footer"><button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                        <asp:Button ID="ResetPasswordButton" runat="server" CssClass="sd-save-button" Text="Update Password" OnClick="ResetPasswordButton_Click" CausesValidation="false" /></div>
                </div></div>
            </div>
            <section class="sd-panel sd-security-panel mt-4" aria-labelledby="security-title">
                <div class="sd-panel-head"><h2 id="security-title"><i class="bi bi-shield-lock" aria-hidden="true"></i> Account Security</h2></div>
                <div class="sd-panel-body sd-security-body">
                    <div><p class="mb-1">Keep your account secure by updating your password when needed.</p>
                        <asp:Label ID="PasswordSuccess" runat="server" CssClass="sd-save-message sd-save-success" role="status" aria-live="polite" /></div>
                    <button type="button" class="btn btn-outline-primary" data-bs-toggle="modal" data-bs-target="#resetPasswordModal">Reset Password</button>
                </div>
            </section>
            <div class="modal fade" id="resetPasswordModal" tabindex="-1" aria-labelledby="resetPasswordTitle" aria-hidden="true">
                <div class="modal-dialog modal-dialog-centered"><div class="modal-content">
                    <div class="modal-header"><h2 class="modal-title fs-5" id="resetPasswordTitle">Reset Password</h2>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button></div>
                    <div class="modal-body">
                        <p class="sd-note">Enter your current password, then choose a new password.</p>
                        <asp:Label ID="PasswordError" runat="server" CssClass="sd-save-message sd-save-error" role="alert" />
                        <div class="mb-3"><asp:Label runat="server" AssociatedControlID="CurrentPasswordInput" CssClass="form-label" Text="Current password" />
                            <asp:TextBox ID="CurrentPasswordInput" runat="server" TextMode="Password" CssClass="form-control" MaxLength="128" autocomplete="current-password" /></div>
                        <div class="mb-3"><asp:Label runat="server" AssociatedControlID="NewPasswordInput" CssClass="form-label" Text="New password" />
                            <asp:TextBox ID="NewPasswordInput" runat="server" TextMode="Password" CssClass="form-control" MaxLength="128" autocomplete="new-password" />
                            <small class="sd-note">Use at least 6 characters.</small></div>
                        <div><asp:Label runat="server" AssociatedControlID="ConfirmPasswordInput" CssClass="form-label" Text="Confirm new password" />
                            <asp:TextBox ID="ConfirmPasswordInput" runat="server" TextMode="Password" CssClass="form-control" MaxLength="128" autocomplete="new-password" /></div>
                    </div>
                    <div class="modal-footer"><button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                        <asp:Button ID="ResetPasswordButton" runat="server" CssClass="sd-save-button" Text="Update Password" OnClick="ResetPasswordButton_Click" CausesValidation="false" /></div>
                </div></div>
            </div>
            <% } %>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Student/Content/Student.js") %>" defer></script>
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            var root = document.querySelector('.student-profile');
            root.querySelectorAll('.sd-profile-photo').forEach(function (image) {
                function fallback() { image.hidden = true; }
                image.addEventListener('error', fallback);
                if (image.complete && image.naturalWidth === 0) fallback();
            });
            root.closest('form').addEventListener('submit', function (event) {
                var button = event.submitter;
                if (!button || !root.contains(button) || button.disabled) return;
                var status = document.getElementById('student-request-status');
                status.hidden = false;
                status.textContent = button.value === 'Validate Changes' ? 'Validating your draft; nothing will be saved…'
                    : button.value === 'Edit Profile' ? 'Loading your verified profile for editing…'
                    : button.value === 'Cancel' ? 'Discarding changes and reloading your profile…'
                    : button.value === 'Update Password' ? 'Verifying your account and updating your password…'
                    : button.value === 'Save Changes' ? 'Saving and verifying your profile in Firebase…' : 'Processing your request…';
                root.setAttribute('aria-busy', 'true');
            });
        });
    </script>
</asp:Content>
