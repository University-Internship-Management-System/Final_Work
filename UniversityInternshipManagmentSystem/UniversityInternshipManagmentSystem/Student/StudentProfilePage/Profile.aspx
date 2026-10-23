<%@ Page Title="My Profile" Language="C#" ResponseEncoding="utf-8" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" Async="true" AsyncTimeout="90" CodeBehind="Profile.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Student.StudentProfilePage.Profile" %>
<%@ Import Namespace="System.Linq" %>
<asp:Content ID="PageHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/Student/Content/Student.css") %>" />
    <link rel="stylesheet" href="<%= ResolveUrl("~/Student/StudentProfilePage/Profile.css?v=2eb15d3cdc8b") %>" />
</asp:Content>
<asp:Content ID="ProfileContent" ContentPlaceHolderID="MainContent" runat="server">
    <div class="student-dashboard student-profile" data-editing="<%: IsEditing ? "true" : "false" %>">
        <a class="sd-skip" href="#page-content">Skip to page content</a>
        <div id="student-request-status" class="sd-message" role="status" aria-live="polite" hidden></div>
        <% if (!string.IsNullOrEmpty(DataError)) { %><div class="sd-message" role="alert"><i class="bi bi-info-circle" aria-hidden="true"></i> <%: DataError %></div><% } %>
        <div id="page-content" tabindex="-1">
            <div class="sp-page-heading">
                <div><a class="sp-back-link" href="<%= ResolveUrl("~/Student/StudentDashboardPage/Dashboard.aspx") %>"><i class="bi bi-arrow-left" aria-hidden="true"></i> Student workspace</a>
                    <h1>My profile<span class="sp-title-dot" aria-hidden="true">.</span></h1><p>Your academic details and professional profile, together.</p></div>
                <span class="sp-account-state<%: Workspace == null ? " sp-account-unavailable" : "" %>"><span class="sp-state-dot" aria-hidden="true"></span><%: ModeLabel %></span>
            </div>
            <input type="hidden" name="StudentCsrf" value="<%: CsrfToken %>" />
            <asp:Label ID="SaveMessage" runat="server" CssClass="sd-save-message" role="status" aria-live="polite" />
            <% if (Workspace != null) { %>
            <section class="sp-identity-card" aria-labelledby="profile-name">
                <div class="sp-identity-main">
                    <div class="sp-avatar-wrap">
                        <div class="sp-avatar-frame">
                            <svg class="sp-avatar-illustration" width="100" height="100" viewBox="0 0 120 120" role="img" aria-label="Default student avatar" aria-hidden="<%: SafeAvatarUrl != null ? "true" : "false" %>" xmlns="http://www.w3.org/2000/svg">
                                <circle cx="60" cy="60" r="60" fill="#EAF4EF" /><circle cx="96" cy="29" r="8" fill="#D5E8DF" /><circle cx="22" cy="83" r="11" fill="#D5E8DF" />
                                <path d="M20 120V106C20 85 37 74 60 74S100 85 100 106V120Z" fill="#178568" /><path d="M47 73L60 87L73 73" fill="#F8FAF9" />
                                <path d="M51 61H69V77C64 84 56 84 51 77Z" fill="#DAB995" /><ellipse cx="60" cy="47" rx="21" ry="25" fill="#E8CEAF" />
                                <path d="M39 42C39 25 48 20 60 20S82 27 81 42C76 39 72 32 70 30C61 37 48 39 39 38Z" fill="#183B31" />
                                <path d="M36 25L60 14L87 25L60 36Z" fill="#07523E" /><path d="M82 27V43" fill="none" stroke="#178568" stroke-width="3" stroke-linecap="round" />
                                <circle cx="52" cy="48" r="1.5" fill="#183B31" /><circle cx="68" cy="48" r="1.5" fill="#183B31" /><path d="M55 59Q60 63 65 59" fill="none" stroke="#9C775C" stroke-width="2" stroke-linecap="round" />
                            </svg>
                            <% if (SafeAvatarUrl != null) { %><img class="sd-profile-photo" width="100" height="100" src="<%: SafeAvatarUrl %>" alt="Student profile photo" referrerpolicy="no-referrer" /><% } %>
                            <img class="sp-avatar-preview" width="100" height="100" alt="Local profile photo preview, not saved" hidden />
                        </div>
                        <button type="button" class="sp-avatar-action" data-avatar-toggle aria-label="Preview a profile photo; changes are not saved" aria-controls="avatar-preview-panel" aria-expanded="false"><i class="bi bi-camera" aria-hidden="true"></i></button>
                        <span class="sp-avatar-preview-tag" data-avatar-preview-tag hidden>Preview only</span>
                    </div>
                    <div class="sp-identity-copy"><span class="sp-eyebrow">A UNIVERSITY OF JORDAN STUDENT</span><h2 id="profile-name"><%: DisplayName %></h2><p class="sp-major"><i class="bi bi-mortarboard" aria-hidden="true"></i><%: Show(Record.Major) %></p>
                        <div class="sp-university-line"><i class="bi bi-building" aria-hidden="true"></i><span>The University of Jordan <span class="sp-university-ar" lang="ar">&#1575;&#1604;&#1580;&#1575;&#1605;&#1593;&#1577; &#1575;&#1604;&#1571;&#1585;&#1583;&#1606;&#1610;&#1577;</span></span></div>
                    </div>
                    <div class="sp-hero-actions"><span class="sp-mode-label"><i class="bi bi-person-badge" aria-hidden="true"></i><%: IsEditing ? "Editing your profile" : "Your student identity" %></span>
                        <div class="sd-profile-actions" aria-label="Profile actions">
                            <asp:Button ID="EditButton" runat="server" CssClass="sd-save-button sp-button-primary" Text="Edit Profile" OnClick="EditButton_Click" CausesValidation="false" />
                            <asp:Button ID="ValidateButton" runat="server" CssClass="sd-save-button sp-button-secondary" Text="Validate Changes" OnClick="ValidateButton_Click" CausesValidation="false" />
                            <asp:Button ID="SaveButton" runat="server" CssClass="sd-save-button sp-button-primary" Text="Save Changes" OnClick="SaveButton_Click" CausesValidation="false" aria-describedby="save-policy" />
                            <asp:Button ID="CancelButton" runat="server" CssClass="sd-cancel-button sp-button-quiet" Text="Cancel" OnClick="CancelButton_Click" CausesValidation="false" />
                        </div>
                    </div>
                </div>
                <div id="avatar-preview-panel" class="sp-photo-panel" hidden>
                    <div><strong>A new perspective</strong><p>Try a photo on your profile. <b>Preview only — not saved.</b> Photo uploads are not connected to your account.</p></div>
                    <div class="sp-photo-controls"><label class="sp-button-secondary sp-file-label">Choose photo<input type="file" accept="image/jpeg,image/png,image/webp" data-avatar-picker aria-label="Choose a local photo for preview only" /></label><button type="button" class="sp-button-quiet" data-avatar-reset hidden>Remove preview</button></div>
                    <p class="sp-photo-help" id="avatar-preview-status" role="status" aria-live="polite">JPG, PNG or WebP · up to 3 MB. Your file stays in this browser.</p>
                </div>
            </section>
            <p id="save-policy" class="sp-edit-notice"><i class="bi bi-shield-check" aria-hidden="true"></i><span>Phone, skills and professional links are editable. Identity and academic records stay protected. Validate checks your draft; Cancel discards unsaved changes.</span></p>
            <div class="sp-overview" aria-label="Profile overview">
                <div class="sp-stat"><div class="sp-stat-top"><span>ACADEMIC GPA</span><i class="bi bi-bar-chart" aria-hidden="true"></i></div><strong><%: StudentGpa.HasValue ? StudentGpa.Value.ToString("0.##") : "Not provided" %></strong><span class="sp-stat-note">As recorded by the university</span></div>
                <div class="sp-stat"><div class="sp-stat-top"><span>YOUR PLACEMENT</span><i class="bi bi-briefcase" aria-hidden="true"></i></div><strong class="sp-stat-text"><%: PlacementText %></strong><span class="sp-stat-note">From your training records</span></div>
                <div class="sp-stat"><div class="sp-stat-top"><span>PROFESSIONAL PORTFOLIO</span><i class="bi bi-box-arrow-up-right" aria-hidden="true"></i></div><strong class="sp-stat-text"><%: SafePortfolioUrl != null ? "Ready to explore" : "Not added yet" %></strong><span class="sp-stat-note"><%: SafePortfolioUrl != null ? "A saved portfolio link is available" : "Add a link when you are ready" %></span></div>
            </div>
            <div class="sp-section-index" aria-label="Profile sections"><a href="#personal-title">Personal</a><a href="#academic-title">Academic</a><a href="#training-title">Training</a><a href="#skills-title">Skills</a><a href="#documents-title">Resources</a><a href="#security-title">Security</a></div>
            <div class="sp-profile-grid">
                <section class="sd-panel sp-card" aria-labelledby="personal-title">
                    <div class="sd-panel-head"><div class="sp-card-title"><span class="sp-section-icon"><i class="bi bi-person" aria-hidden="true"></i></span><div><h2 id="personal-title">Personal Information</h2><p>The details that make you, you.</p></div></div><span class="sp-readonly-tag"><i class="bi bi-lock" aria-hidden="true"></i>Protected identity</span></div>
                    <div class="sd-panel-body"><dl class="sp-field-grid"><div><dt>Full name</dt><dd><%: Show(Record.Name) %></dd></div><div><dt>Account email</dt><dd><%: Show(Record.Email) %></dd></div><div><dt>University email</dt><dd><%: Show(Record.UniEmail) %></dd></div></dl>
                        <div class="sp-phone-field"><asp:Label runat="server" AssociatedControlID="PhoneNumberInput" CssClass="form-label" Text="Phone number" /><asp:TextBox ID="PhoneNumberInput" runat="server" EnableViewState="false" CssClass="form-control" MaxLength="30" TextMode="Phone" placeholder="Not provided" aria-describedby="phone-help PhoneError" /><span id="phone-help" class="sd-note sp-edit-only">Optional. Use 7–30 characters; include a country code where applicable.</span><asp:Label ID="PhoneError" runat="server" ClientIDMode="Static" CssClass="sd-field-error" role="alert" /></div>
                    </div>
                </section>
                <section class="sd-panel sp-card" aria-labelledby="academic-title">
                    <div class="sd-panel-head"><div class="sp-card-title"><span class="sp-section-icon"><i class="bi bi-mortarboard" aria-hidden="true"></i></span><div><h2 id="academic-title">Academic Information</h2><p>Your university record, in one place.</p></div></div><span class="sp-readonly-tag"><i class="bi bi-lock" aria-hidden="true"></i>Read-only</span></div>
                    <div class="sd-panel-body"><dl class="sp-field-grid"><div class="sp-field-wide"><dt>Major</dt><dd><%: Show(Record.Major) %></dd></div><div><dt>GPA</dt><dd><%: StudentGpa.HasValue ? StudentGpa.Value.ToString("0.##") : "Not provided" %></dd></div><div><dt>University email</dt><dd><%: Show(Record.UniEmail) %></dd></div></dl><p class="sp-inline-note"><i class="bi bi-info-circle" aria-hidden="true"></i>Academic and account records are maintained by the university. Contact your coordinator for corrections.</p></div>
                </section>
                <section class="sd-panel sp-card sp-card-wide" aria-labelledby="training-title">
                    <div class="sd-panel-head"><div class="sp-card-title"><span class="sp-section-icon"><i class="bi bi-briefcase" aria-hidden="true"></i></span><div><h2 id="training-title">Training Information</h2><p>A little context for your professional journey.</p></div></div><span class="sp-readonly-tag"><i class="bi bi-lock" aria-hidden="true"></i>Read-only</span></div>
                    <div class="sd-panel-body"><div class="sp-training-people"><div><span class="sp-detail-icon"><i class="bi bi-buildings" aria-hidden="true"></i></span><div><span class="sp-detail-label">Training company</span><strong><%: CompanyText %></strong></div></div><div><span class="sp-detail-icon"><i class="bi bi-person-workspace" aria-hidden="true"></i></span><div><span class="sp-detail-label">Academic supervisor</span><strong><%: SupervisorText %></strong></div></div></div>
                        <dl class="sd-training-grid"><div><dt>Placement status</dt><dd><%: PlacementText %></dd></div><div><dt>Internship opportunity</dt><dd><%: OpportunityText %></dd></div><div><dt>Confirmation date</dt><dd><%: ConfirmationText %></dd></div><div><dt>Required training hours</dt><dd class="sp-unavailable">Not available</dd></div><div><dt>Approved training hours</dt><dd class="sp-unavailable">Not available</dd></div></dl><p class="sp-inline-note"><i class="bi bi-info-circle" aria-hidden="true"></i><%: TrainingNote %></p>
                    </div>
                </section>
                <section class="sd-panel sp-card" aria-labelledby="skills-title">
                    <div class="sd-panel-head"><div class="sp-card-title"><span class="sp-section-icon"><i class="bi bi-stars" aria-hidden="true"></i></span><div><h2 id="skills-title">Skills &amp; Competencies</h2><p>The strengths you bring to the table.</p></div></div></div>
                    <div class="sd-panel-body"><div class="sp-view-only"><% if (Record.SkillsList != null && Record.SkillsList.Any(skill => !string.IsNullOrWhiteSpace(skill))) { %><ul class="sp-skill-tags" aria-label="Your skills"><% foreach (var skill in Record.SkillsList.Where(skill => !string.IsNullOrWhiteSpace(skill))) { %><li><%: skill %></li><% } %></ul><p class="sp-card-footnote">Built through learning. Ready to put into practice.</p><% } else { %><div class="sp-empty-state"><span class="sp-empty-icon"><i class="bi bi-lightbulb" aria-hidden="true"></i></span><h3>Make room for your strengths</h3><p>No skills have been added. Choose Edit Profile to share what you know.</p></div><% } %></div>
                        <div class="sp-edit-only"><asp:Label runat="server" AssociatedControlID="SkillsInput" CssClass="form-label" Text="Skills" /><asp:TextBox ID="SkillsInput" runat="server" EnableViewState="false" CssClass="form-control" TextMode="MultiLine" Rows="7" aria-describedby="skills-help SkillsError" /><span class="sd-note" id="skills-help">One skill per line. Up to 20 skills, 60 characters each. Empty means no skills listed; no proficiency level is assumed.</span><asp:Label ID="SkillsError" runat="server" ClientIDMode="Static" CssClass="sd-field-error" role="alert" /></div>
                    </div>
                </section>
                <section class="sd-panel sp-card" aria-labelledby="documents-title">
                    <div class="sd-panel-head"><div class="sp-card-title"><span class="sp-section-icon"><i class="bi bi-folder2-open" aria-hidden="true"></i></span><div><h2 id="documents-title">CV &amp; Professional Portfolio</h2><p>Let your work tell the story.</p></div></div></div>
                    <div class="sd-panel-body sp-resource-list">
                        <div class="sp-resource-card"><span class="sp-resource-icon"><i class="bi bi-file-earmark-text" aria-hidden="true"></i></span><div class="sp-resource-copy"><h3>Curriculum Vitae</h3><p><%: SafeCvUrl != null ? "Your saved CV, ready to share." : "A home for your experience and achievements." %></p><span class="sp-resource-state"><span aria-hidden="true" class="sp-small-dot"></span><%: SafeCvUrl != null ? "Available" : "Not added" %></span></div><% if (SafeCvUrl != null) { %><a class="sp-resource-open" href="<%: SafeCvUrl %>" target="_blank" rel="noopener noreferrer" aria-label="Open saved CV in a new tab"><i class="bi bi-arrow-up-right" aria-hidden="true"></i><span>Open</span></a><% } %></div>
                        <div class="sp-edit-only sp-resource-input"><asp:Label runat="server" AssociatedControlID="CvInput" CssClass="form-label" Text="CV link" /><asp:TextBox ID="CvInput" runat="server" EnableViewState="false" CssClass="form-control" MaxLength="2048" aria-describedby="cv-help CvError" /><span id="cv-help" class="sd-note">Optional web link, up to 2048 characters. Use a shareable link to your CV; direct file upload is not configured.</span><asp:Label ID="CvError" runat="server" ClientIDMode="Static" CssClass="sd-field-error" role="alert" /></div>
                        <div class="sp-resource-card"><span class="sp-resource-icon"><i class="bi bi-window" aria-hidden="true"></i></span><div class="sp-resource-copy"><h3>Professional portfolio</h3><p><%: SafePortfolioUrl != null ? "Explore the work you are proud of." : "Your website, GitHub or creative work." %></p><span class="sp-resource-state"><span aria-hidden="true" class="sp-small-dot"></span><%: SafePortfolioUrl != null ? "Available" : "Not added" %></span></div><% if (SafePortfolioUrl != null) { %><a class="sp-resource-open" href="<%: SafePortfolioUrl %>" target="_blank" rel="noopener noreferrer" aria-label="Open saved portfolio in a new tab"><i class="bi bi-arrow-up-right" aria-hidden="true"></i><span>Open</span></a><% } %></div>
                        <div class="sp-edit-only sp-resource-input"><asp:Label runat="server" AssociatedControlID="PortfolioInput" CssClass="form-label" Text="Portfolio link" /><asp:TextBox ID="PortfolioInput" runat="server" EnableViewState="false" CssClass="form-control" MaxLength="2048" aria-describedby="portfolio-help PortfolioError" /><span id="portfolio-help" class="sd-note">HTTP/HTTPS links accepted. Missing protocols become HTTPS; embedded credentials are rejected.</span><asp:Label ID="PortfolioError" runat="server" ClientIDMode="Static" CssClass="sd-field-error" role="alert" /></div>
                        <div class="sp-resource-card sp-linkedin-card"><span class="sp-resource-icon"><i class="bi bi-linkedin" aria-hidden="true"></i></span><div class="sp-resource-copy"><h3>LinkedIn</h3><p>Your professional network, alongside your portfolio.</p><span class="sp-resource-state"><span aria-hidden="true" class="sp-small-dot"></span><%: SafeLinkedInUrl != null ? "Available" : "Not added" %></span></div><% if (SafeLinkedInUrl != null) { %><a class="sp-resource-open" href="<%: SafeLinkedInUrl %>" target="_blank" rel="noopener noreferrer" aria-label="Open saved LinkedIn profile in a new tab"><i class="bi bi-arrow-up-right" aria-hidden="true"></i><span>Open</span></a><% } %></div>
                        <div class="sp-edit-only sp-resource-input"><asp:Label runat="server" AssociatedControlID="LinkedInInput" CssClass="form-label" Text="LinkedIn link" /><asp:TextBox ID="LinkedInInput" runat="server" data-linkedin-input="true" EnableViewState="false" CssClass="form-control" MaxLength="2048" placeholder="https://www.linkedin.com/in/your-name" aria-describedby="linkedin-help LinkedInError" /><span id="linkedin-help" class="sd-note">Optional HTTPS LinkedIn link, up to 2048 characters. Saved separately from your portfolio.</span><a class="sp-resource-open" data-linkedin-open hidden target="_blank" rel="noopener noreferrer" aria-label="Open entered LinkedIn link in a new tab"><i class="bi bi-arrow-up-right" aria-hidden="true"></i><span>Open LinkedIn</span></a><span class="sd-note">Opening this link does not save it. Use Save Changes to request saving.</span><asp:Label ID="LinkedInError" runat="server" ClientIDMode="Static" CssClass="sd-field-error" role="alert" /></div>
                        <p class="sp-card-footnote sp-view-only">Use Edit Profile to add or update your professional links.</p>
                    </div>
                </section>
            </div>
            <section class="sd-panel sp-card sp-security-card" aria-labelledby="security-title">
                <div class="sp-security-layout"><span class="sp-security-icon"><i class="bi bi-shield-lock" aria-hidden="true"></i></span><div class="sp-security-copy"><h2 id="security-title">Account Security</h2><p>Keep your account protected with a strong password.</p><asp:Label ID="PasswordSuccess" runat="server" CssClass="sd-save-message sd-save-success" role="status" aria-live="polite" /></div><button type="button" class="sp-button-secondary" data-bs-toggle="modal" data-bs-target="#resetPasswordModal">Reset Password<i class="bi bi-arrow-up-right" aria-hidden="true"></i></button></div>
            </section>
            <p class="sp-page-footnote"><i class="bi bi-lock" aria-hidden="true"></i>Personal to you. Connected to your university journey.</p>
            <div class="modal fade" id="resetPasswordModal" tabindex="-1" aria-labelledby="resetPasswordTitle" aria-hidden="true">
                <div class="modal-dialog modal-dialog-centered"><div class="modal-content">
                    <div class="modal-header"><h2 class="modal-title fs-5" id="resetPasswordTitle">Reset Password</h2><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button></div>
                    <div class="modal-body"><p class="sd-note">Enter your current password, then choose a new password.</p><asp:Label ID="PasswordError" runat="server" CssClass="sd-save-message sd-save-error" role="alert" />
                        <div class="mb-3"><asp:Label runat="server" AssociatedControlID="CurrentPasswordInput" CssClass="form-label" Text="Current password" /><asp:TextBox ID="CurrentPasswordInput" runat="server" TextMode="Password" CssClass="form-control" MaxLength="128" autocomplete="current-password" /></div>
                        <div class="mb-3"><asp:Label runat="server" AssociatedControlID="NewPasswordInput" CssClass="form-label" Text="New password" /><asp:TextBox ID="NewPasswordInput" runat="server" TextMode="Password" CssClass="form-control" MaxLength="128" autocomplete="new-password" /><small class="sd-note">Use at least 6 characters.</small></div>
                        <div><asp:Label runat="server" AssociatedControlID="ConfirmPasswordInput" CssClass="form-label" Text="Confirm new password" /><asp:TextBox ID="ConfirmPasswordInput" runat="server" TextMode="Password" CssClass="form-control" MaxLength="128" autocomplete="new-password" /></div>
                    </div><div class="modal-footer"><button type="button" class="sp-button-quiet" data-bs-dismiss="modal">Cancel</button><asp:Button ID="ResetPasswordButton" runat="server" CssClass="sd-save-button sp-button-primary" Text="Update Password" OnClick="ResetPasswordButton_Click" CausesValidation="false" /></div>
                </div></div>
            </div>
            <% } %>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Student/Content/Student.js") %>" defer></script>
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            var root = document.querySelector('.student-profile');
            if (!root) return;
            // Draft preview only: server validation and Firebase persistence remain unchanged.
            function linkedInPreviewUrl(value) {
                if (!value || value.length > 2048 || /[\x00-\x1f\x7f]/.test(value)) return null;
                var raw = value.trim();
                if (!raw || /\s|\\/.test(raw)) return null;
                try {
                    var url = new URL(/^https?:\/\//i.test(raw) ? raw : raw.indexOf('//') === 0 ? 'https:' + raw : 'https://' + raw);
                    if (url.protocol !== 'https:' || url.username || url.password || url.href.length > 2048
                        || !(url.hostname === 'linkedin.com' || url.hostname.endsWith('.linkedin.com'))) return null;
                    return url.href;
                } catch (error) { return null; }
            }
            var linkedInInput = root.querySelector('[data-linkedin-input]');
            var linkedInOpen = root.querySelector('[data-linkedin-open]');
            function refreshLinkedInOpen() {
                var address = linkedInPreviewUrl(linkedInInput.value);
                linkedInOpen.hidden = !address;
                if (address) linkedInOpen.href = address;
                else linkedInOpen.removeAttribute('href');
            }
            if (linkedInInput && linkedInOpen) {
                linkedInInput.addEventListener('input', refreshLinkedInOpen);
                linkedInInput.addEventListener('change', refreshLinkedInOpen);
                refreshLinkedInOpen();
            }
            var illustration = root.querySelector('.sp-avatar-illustration');
            var savedImage = root.querySelector('.sd-profile-photo');
            var preview = root.querySelector('.sp-avatar-preview');
            function describeAvatar() {
                var hasPreview = preview && !preview.hidden;
                if (illustration) illustration.setAttribute('aria-hidden', String(!!hasPreview || !!(savedImage && !savedImage.hidden)));
                if (savedImage) savedImage.setAttribute('aria-hidden', String(!!hasPreview));
            }
            root.querySelectorAll('.sd-profile-photo').forEach(function (image) {
                function fallback() { image.hidden = true; describeAvatar(); }
                image.addEventListener('error', fallback);
                image.addEventListener('load', describeAvatar);
                if (image.complete && image.naturalWidth === 0) fallback();
            });
            describeAvatar();
            var form = root.closest('form');
            if (form) form.addEventListener('submit', function (event) {
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
            var toggle = root.querySelector('[data-avatar-toggle]');
            if (!toggle) return;
            var panel = document.getElementById('avatar-preview-panel');
            var picker = root.querySelector('[data-avatar-picker]');
            var previewTag = root.querySelector('[data-avatar-preview-tag]');
            var reset = root.querySelector('[data-avatar-reset]');
            var note = document.getElementById('avatar-preview-status');
            var currentUrl = null, sequence = 0;
            function discardPreview() {
                sequence++;
                preview.hidden = true;
                preview.removeAttribute('src');
                if (currentUrl) URL.revokeObjectURL(currentUrl);
                currentUrl = null; picker.value = ''; reset.hidden = true;
                previewTag.hidden = true; describeAvatar();
                note.textContent = 'JPG, PNG or WebP · up to 3 MB. Your file stays in this browser.';
                note.classList.remove('sp-photo-error');
            }
            toggle.addEventListener('click', function () { panel.hidden = !panel.hidden; toggle.setAttribute('aria-expanded', String(!panel.hidden)); });
            reset.addEventListener('click', discardPreview);
            picker.addEventListener('change', function () {
                var file = picker.files && picker.files[0], ticket = ++sequence;
                if (!file) return;
                function reject(message) { if (ticket !== sequence) return; note.textContent = message; note.classList.add('sp-photo-error'); picker.value = ''; }
                if (!/\.(jpe?g|png|webp)$/i.test(file.name) || !['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) { reject('Choose a JPG, PNG or WebP image. Nothing has been uploaded.'); return; }
                if (!file.size || file.size > 3 * 1024 * 1024) { reject('Choose an image smaller than 3 MB. Nothing has been uploaded.'); return; }
                var reader = new FileReader();
                reader.onerror = function () { reject('This image could not be read. Try another file.'); };
                reader.onload = function () {
                    if (ticket !== sequence) return;
                    var bytes = new Uint8Array(reader.result);
                    var jpeg = bytes.length >= 3 && bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255;
                    var png = bytes.length >= 8 && [137,80,78,71,13,10,26,10].every(function (value, index) { return bytes[index] === value; });
                    var webp = bytes.length >= 12 && bytes[0] === 82 && bytes[1] === 73 && bytes[2] === 70 && bytes[3] === 70 && bytes[8] === 87 && bytes[9] === 69 && bytes[10] === 66 && bytes[11] === 80;
                    if (!(file.type === 'image/jpeg' && jpeg || file.type === 'image/png' && png || file.type === 'image/webp' && webp)) { reject('The file does not match its image format. Choose another image.'); return; }
                    var candidate = URL.createObjectURL(file), probe = new Image();
                    probe.onerror = function () { URL.revokeObjectURL(candidate); reject('This image could not be displayed. Try another file.'); };
                    probe.onload = function () {
                        if (ticket !== sequence) { URL.revokeObjectURL(candidate); return; }
                        if (probe.naturalWidth > 6000 || probe.naturalHeight > 6000) { URL.revokeObjectURL(candidate); reject('Choose an image no larger than 6000 × 6000 pixels.'); return; }
                        if (currentUrl) URL.revokeObjectURL(currentUrl);
                        currentUrl = candidate; preview.src = candidate; preview.hidden = false; reset.hidden = false;
                        previewTag.hidden = false; describeAvatar();
                        note.classList.remove('sp-photo-error'); note.textContent = 'Preview only — not saved. This photo will disappear when you leave or reload the page.';
                    };
                    probe.src = candidate;
                };
                reader.readAsArrayBuffer(file.slice(0, 12));
            });
            window.addEventListener('pagehide', discardPreview);
        });
    </script>
</asp:Content>
