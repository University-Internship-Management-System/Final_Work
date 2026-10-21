<%@ Page Title="My Profile" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" Async="true" CodeBehind="Profile.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Student.StudentProfilePage.Profile" %>
<asp:Content ID="PageHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/Student/Content/Student.css") %>" />
    <link rel="stylesheet" href="<%= ResolveUrl("~/Student/StudentProfilePage/Profile.css") %>" />
</asp:Content>
<asp:Content ID="ProfileContent" ContentPlaceHolderID="MainContent" runat="server">
    <div class="student-dashboard">
        <a class="sd-skip" href="#page-content">Skip to page content</a>
        <div id="student-request-status" class="sd-message" role="status" aria-live="polite" hidden></div>
        <% if (!string.IsNullOrEmpty(DataError)) { %><div class="sd-message" role="alert"><%: DataError %></div><% } %>
        <div id="page-content" tabindex="-1">

    <div class="sd-heading"><div><span class="sd-eyebrow">Your student identity</span><h1>My Profile</h1><p class="sd-muted">Your academic information and professional profile, together.</p></div><span class="sd-demo"><%: ModeLabel %></span></div>
    <input type="hidden" name="StudentCsrf" value="<%: CsrfToken %>" />
    <asp:Panel ID="TestSignInPanel" runat="server" Visible="false" CssClass="sd-panel mb-4">
        <div class="sd-panel-head"><h2>Student test sign-in</h2><span class="sd-count">Local HTTPS · Read-only</span></div>
        <div class="sd-panel-body">
            <p class="sd-note mb-3">Sign in to uims-student-2026 to read Students/student_001. Your verified Firebase UID must match its AuthUid. Passwords and tokens are never stored in page markup.</p>
            <div class="mb-3"><asp:Label runat="server" AssociatedControlID="TestApiKeyInput" CssClass="form-label" Text="Firebase Web API Key (uims-student-2026)" /><asp:TextBox ID="TestApiKeyInput" runat="server" CssClass="form-control" MaxLength="256" EnableViewState="false" autocomplete="off" /><span class="sd-note">May be left blank when UIMS_STUDENT_FIREBASE_API_KEY is configured for the local server process.</span></div>
            <div class="mb-3"><asp:Label runat="server" AssociatedControlID="TestEmailInput" CssClass="form-label" Text="Test student email" /><asp:TextBox ID="TestEmailInput" runat="server" CssClass="form-control" TextMode="Email" Text="student1@example.com" MaxLength="254" autocomplete="username" /></div>
            <div class="mb-3"><asp:Label runat="server" AssociatedControlID="TestPasswordInput" CssClass="form-label" Text="Password" /><asp:TextBox ID="TestPasswordInput" runat="server" CssClass="form-control" TextMode="Password" EnableViewState="false" autocomplete="current-password" MaxLength="4096" /></div>
            <asp:Button ID="TestSignInButton" runat="server" CssClass="btn btn-primary sd-signin-button" Text="Sign in and read Firebase" OnClick="TestSignIn_Click" CausesValidation="false" />
        </div>
    </asp:Panel>
    <asp:Button ID="TestSignOutButton" runat="server" Visible="false" CssClass="btn btn-outline-primary mb-4" Text="Sign out of Student test session" OnClick="TestSignOut_Click" CausesValidation="false" />
    <% if (Workspace == null) { %><p class="sd-note">The isolated test form is available only on localhost over HTTPS with ASP.NET debugging enabled. It is disabled when team authentication is registered.</p><% } %>
    <% if (Workspace != null) { %>
    <p class="mb-3"><a class="sd-document-link" href="<%= ResolveUrl("~/Student/StudentDashboardPage/Dashboard.aspx") %>">Open Student Dashboard</a></p>
    <section class="sd-profile-banner"><span class="sd-profile-avatar" aria-hidden="true"><%: DisplayName.Substring(0, 1).ToUpperInvariant() %></span><div><h2><%: DisplayName %></h2><p><%: Show(Record.Major) %></p><span class="sd-badge mt-2">The University of Jordan · الجامعة الأردنية</span></div></section>
    <div class="row g-4">
        <div class="col-xl-5"><section class="sd-panel" aria-labelledby="academic-title"><div class="sd-panel-head"><h2 id="academic-title">Academic &amp; account information</h2><span class="sd-count">Read-only</span></div><div class="sd-panel-body">
            <p class="sd-note mb-3">These details are maintained by the university and authorized coordinators. Contact your coordinator to request a correction.</p>
            <dl class="sd-details"><dt>Full name</dt><dd><%: Show(Record.Name) %></dd><dt>Account email</dt><dd><%: Show(Record.Email) %></dd><dt>University email</dt><dd><%: Show(Record.UniEmail) %></dd><dt>Major</dt><dd><%: Show(Record.Major) %></dd><dt>GPA</dt><dd><%: Record.GPA.HasValue ? Record.GPA.Value.ToString("0.##") : "Not provided" %><span class="sd-note d-block">As recorded; no grading scale is assumed.</span></dd><dt>Company assignment</dt><dd><%: CompanyText %></dd><dt>Academic supervisor</dt><dd><%: SupervisorText %></dd></dl>
        </div></section></div>
        <div class="col-xl-7"><section class="sd-panel" aria-labelledby="personal-title"><div class="sd-panel-head"><h2 id="personal-title">Contact &amp; professional details</h2><span class="sd-count"><%: CanUpdate ? "Authorized fields only" : "Read-only" %></span></div><div class="sd-panel-body">
            <p class="sd-note mb-4"><%: CanUpdate ? "Edit your permitted contact and professional fields below. Academic and account details stay read-only. Cancel reloads your current saved profile." : "Editing is unavailable in this session. Profile changes require an authenticated student session and an approved field policy." %></p>
            <% if (CanUpdate && !UniversityInternshipManagmentSystem.Student.Data.FirebaseStudentRepository.ProfileWritesEnabled) { %><div class="sd-message" role="note">You can prepare changes, but saving is not authorized yet: Firebase currently permits reads only. Save will keep your entries without sending an update until the database owner approves profile writes.</div><% } %>
            <asp:Label ID="SaveMessage" runat="server" CssClass="sd-save-message" role="status" aria-live="polite" />
            <div class="mb-4"><asp:Label runat="server" AssociatedControlID="PhoneNumberInput" CssClass="form-label" Text="Phone number" /><asp:TextBox ID="PhoneNumberInput" runat="server" CssClass="form-control" MaxLength="30" ReadOnly="true" TextMode="Phone" /><span class="sd-note">Include a country code where applicable.</span></div>
            <div class="mb-4"><asp:Label runat="server" AssociatedControlID="SkillsInput" CssClass="form-label" Text="Skills" /><asp:TextBox ID="SkillsInput" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3" ReadOnly="true" aria-describedby="skills-help" /><span class="sd-note" id="skills-help">One skill per line. Up to 20 skills, 60 characters each.</span></div>
            <div class="mb-4"><asp:Label runat="server" AssociatedControlID="CvInput" CssClass="form-label" Text="CV link" /><asp:TextBox ID="CvInput" runat="server" CssClass="form-control" MaxLength="2048" ReadOnly="true" /><span class="sd-note">A public HTTPS link to your CV; file uploads are not available here.</span><% if (SafeCvUrl != null) { %><a class="sd-document-link" href="<%: SafeCvUrl %>" target="_blank" rel="noopener noreferrer">Open CV <span aria-hidden="true">&#8599;</span></a><% } else { %><p class="sd-note mt-1">No valid CV link provided.</p><% } %></div>
            <div class="mb-4"><asp:Label runat="server" AssociatedControlID="PortfolioInput" CssClass="form-label" Text="Portfolio link" /><asp:TextBox ID="PortfolioInput" runat="server" CssClass="form-control" MaxLength="2048" ReadOnly="true" /><span class="sd-note">An absolute HTTPS link to your work.</span><% if (SafePortfolioUrl != null) { %><a class="sd-document-link" href="<%: SafePortfolioUrl %>" target="_blank" rel="noopener noreferrer">Open portfolio <span aria-hidden="true">&#8599;</span></a><% } else { %><p class="sd-note mt-1">No valid portfolio link provided.</p><% } %></div>
            <div class="d-flex flex-wrap gap-2">
                <asp:Button ID="SaveButton" runat="server" CssClass="sd-save-button" Text="Save Changes" OnClick="SaveButton_Click" Visible="false" />
                <asp:Button ID="CancelButton" runat="server" CssClass="btn btn-outline-primary sd-cancel-button" Text="Cancel" OnClick="CancelButton_Click" Visible="false" CausesValidation="false" />
            </div>
        </div></section></div>
    </div>
    <% } %>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Student/Content/Student.js") %>" defer></script>
</asp:Content>
