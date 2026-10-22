<%@ Page Title="My Profile" Language="C#" ResponseEncoding="utf-8" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" Async="true" AsyncTimeout="90" CodeBehind="Profile.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Student.StudentProfilePage.Profile" %>

<asp:Content ID="PageHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/Student/Content/Student.css") %>" />
    <link rel="stylesheet" href="<%= ResolveUrl("~/Student/StudentProfilePage/Profile.css") %>" />
</asp:Content>
<asp:Content ID="ProfileContent" ContentPlaceHolderID="MainContent" runat="server">
    <div class="student-dashboard">
        <a class="sd-skip" href="#page-content">Skip to page content</a>
        <div id="student-request-status" class="sd-message" role="status" aria-live="polite" hidden></div>
        <% if (!string.IsNullOrEmpty(DataError))
            { %><div class="sd-message" role="alert"><%: DataError %></div>
        <% } %>
        <div id="page-content" tabindex="-1">

            <div class="sd-heading">
                <div><span class="sd-eyebrow">Your student identity</span><h1>My Profile</h1>
                    <p class="sd-muted">Your academic information and professional profile, together.</p>
                </div>
                <span class="sd-demo"><%: ModeLabel %></span></div>
            <input type="hidden" name="StudentCsrf" value="<%: CsrfToken %>" />
            <% if (Workspace != null)
                { %>
            <p class="mb-3"><a class="sd-document-link" href="<%= ResolveUrl("~/Student/StudentDashboardPage/Dashboard.aspx") %>">Open Student Dashboard</a></p>
            <section class="sd-profile-banner"><span class="sd-profile-avatar" aria-hidden="true"><%: DisplayName.Substring(0, 1).ToUpperInvariant() %></span><div>
                <h2><%: DisplayName %></h2>
                <p><%: Show(Record.Major) %></p>
                <span class="sd-badge mt-2">The University of Jordan &#183; &#1575;&#1604;&#1580;&#1575;&#1605;&#1593;&#1577; &#1575;&#1604;&#1571;&#1585;&#1583;&#1606;&#1610;&#1577;</span></div>
            </section>
            <div class="row g-4">
                <div class="col-xl-5">
                    <section class="sd-panel" aria-labelledby="academic-title">
                        <div class="sd-panel-head">
                            <h2 id="academic-title">Academic &amp; account information</h2>
                            <span class="sd-count">Read-only</span></div>
                        <div class="sd-panel-body">
                            <p class="sd-note mb-3">These details are maintained by the university and authorized coordinators. Contact your coordinator to request a correction.</p>
                            <dl class="sd-details">
                                <dt>Full name</dt>
                                <dd><%: Show(Record.Name) %></dd>
                                <dt>Account email</dt>
                                <dd><%: Show(Record.Email) %></dd>
                                <dt>University email</dt>
                                <dd><%: Show(Record.UniEmail) %></dd>
                                <dt>Major</dt>
                                <dd><%: Show(Record.Major) %></dd>
                                <dt>GPA</dt>
                                <dd><%: StudentGpa.HasValue ? StudentGpa.Value.ToString("0.##") : "Not provided" %><span class="sd-note d-block">As recorded; no grading scale is assumed.</span></dd>
                                <dt>Company assignment</dt>
                                <dd><%: CompanyText %></dd>
                                <dt>Academic supervisor</dt>
                                <dd><%: SupervisorText %></dd>
                            </dl>
                        </div>
                    </section>
                </div>
                <div class="col-xl-7">
                    <section class="sd-panel" aria-labelledby="personal-title">
                        <div class="sd-panel-head">
                            <h2 id="personal-title">Contact &amp; professional details</h2>
                            <span class="sd-count"><%: CanEdit ? "Editable personal fields" : "Read-only" %></span></div>
                        <div class="sd-panel-body">
                            <p class="sd-note mb-4"><%: CanUpdate ? "Edit and save your contact and professional fields below. Academic and account details stay read-only. Cancel reloads your saved profile." : "A verified Student session is required to edit and save your own profile." %>
                                <asp:Button ID="Button1" runat="server" OnClick="Button1_Click" Text="Button" />
                            </p>
                            <asp:Label ID="SaveMessage" runat="server" CssClass="sd-save-message" role="status" aria-live="polite" />
                            <div class="mb-4">
                                <asp:Label runat="server" AssociatedControlID="PhoneNumberInput" CssClass="form-label" Text="Phone number" /><asp:TextBox ID="PhoneNumberInput" runat="server" CssClass="form-control" MaxLength="30" ReadOnly="true" TextMode="Phone" /><span class="sd-note">Include a country code where applicable.</span></div>
                            <div class="mb-4">
                                <asp:Label runat="server" AssociatedControlID="SkillsInput" CssClass="form-label" Text="Skills" /><asp:TextBox ID="SkillsInput" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3" ReadOnly="true" aria-describedby="skills-help" /><span class="sd-note" id="skills-help">One skill per line. Up to 20 skills, 60 characters each.</span></div>
                            <div class="mb-4">
                                <asp:Label runat="server" AssociatedControlID="CvInput" CssClass="form-label" Text="CV link" /><asp:TextBox ID="CvInput" runat="server" CssClass="form-control" MaxLength="2048" ReadOnly="true" /><span class="sd-note">Paste a CV web link (http://, https://, or www...). Missing protocols are completed with https://. Direct file upload is not configured.</span><% if (SafeCvUrl != null)
                                                                                                                                                        { %><a class="sd-document-link" href="<%: SafeCvUrl %>" target="_blank" rel="noopener noreferrer">Open CV <span aria-hidden="true">&#8599;</span></a><% }
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            else
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            { %><p class="sd-note mt-1">No valid CV link provided.</p>
                                <% } %></div>
                            <div class="mb-4">
                                <asp:Label runat="server" AssociatedControlID="PortfolioInput" CssClass="form-label" Text="Portfolio link" /><asp:TextBox ID="PortfolioInput" runat="server" CssClass="form-control" MaxLength="2048" ReadOnly="true" /><span class="sd-note">Paste a web link to your portfolio or hosted file. http://, https://, and links without a protocol are accepted.</span><% if (SafePortfolioUrl != null)
                                                                                                                           { %><a class="sd-document-link" href="<%: SafePortfolioUrl %>" target="_blank" rel="noopener noreferrer">Open portfolio <span aria-hidden="true">&#8599;</span></a><% }
                                                                                                                                                                                                                                                                                                                                                                                                    else
                                                                                                                                                                                                                                                                                                                                                                                                    { %><p class="sd-note mt-1">No valid portfolio link provided.</p>
                                <% } %></div>
                            <div class="d-flex flex-wrap gap-2">
                                <asp:Button ID="SaveButton" runat="server" CssClass="sd-save-button" Text="Save Changes" OnClick="SaveButton_Click" Visible="false" />
                                <asp:Button ID="CancelButton" runat="server" CssClass="btn btn-outline-primary sd-cancel-button" Text="Cancel" OnClick="CancelButton_Click" Visible="false" CausesValidation="false" />
                            </div>
                        </div>
                    </section>
                </div>

            </div>
            <% } %>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Student/Content/Student.js") %>" defer></script>
</asp:Content>
