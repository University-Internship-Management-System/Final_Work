<%@ Page Title="Academic supervisors" Language="C#" Async="true" AutoEventWireup="true" ViewStateEncryptionMode="Always" CodeBehind="ManageAcademicSupervisors.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Coordinator.CoordinatorAcademicAccounts" MasterPageFile="~/Shared/Dashboard.Master" %>
<asp:Content ID="head" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="academic-supervisors.css?v=20261023-1" />
</asp:Content>
<asp:Content ID="body" ContentPlaceHolderID="MainContent" runat="server">
    <asp:ScriptManager ID="academicScripts" runat="server" />
    <header class="academic-heading"><div><p class="academic-eyebrow">COORDINATOR / ACCOUNT MANAGEMENT</p><h1 class="page-title">Academic supervisors</h1><p class="text-muted">Manage supervisor profiles and their academic specializations.</p></div><asp:HyperLink ID="addSupervisor" runat="server" Visible="false" CssClass="btn btn-primary"><i class="bi bi-plus-lg" aria-hidden="true"></i> Add supervisor</asp:HyperLink></header>
    <asp:Panel ID="notice" runat="server" role="alert" CssClass="academic-notice academic-error" Visible="false"><asp:Literal ID="noticeText" runat="server" Mode="Encode" /></asp:Panel>
    <asp:Panel ID="workspace" runat="server" Visible="false" DefaultButton="searchButton">
        <section class="academic-summary" aria-label="Academic supervisor total"><div class="academic-summary-main"><span class="academic-summary-icon"><i class="bi bi-person-badge" aria-hidden="true"></i></span><div><span class="academic-summary-label">Academic supervisors</span><strong><asp:Literal ID="total" runat="server" /></strong></div></div><p>Each supervisor has one major.<br />Assign students from the same specialization.</p></section>
        <section class="card academic-card" aria-labelledby="directoryTitle">
            <div class="academic-section-heading"><div><h2 id="directoryTitle">Supervisor directory</h2><p class="text-muted">Academic profiles, specializations and contact details.</p></div></div>
            <div class="academic-search-tools"><div class="academic-search-field"><asp:Label runat="server" AssociatedControlID="supervisorSearch" CssClass="visually-hidden" Text="Search supervisors" /><i class="bi bi-search" aria-hidden="true"></i><asp:TextBox ID="supervisorSearch" ClientIDMode="Static" runat="server" CssClass="form-control" MaxLength="120" placeholder="Search name, email or major" OnTextChanged="SearchChanged" /></div><asp:Button ID="searchButton" runat="server" CssClass="btn btn-outline-primary" Text="Search" OnClick="SearchChanged" CausesValidation="false" /></div>
            <asp:UpdatePanel ID="directoryUpdate" runat="server" UpdateMode="Conditional"><ContentTemplate>
                <table class="table academic-table"><thead><tr><th scope="col">Supervisor</th><th scope="col">Major</th><th scope="col">Phone</th><th scope="col">Action</th></tr></thead><tbody>
                    <asp:Repeater ID="directory" runat="server"><ItemTemplate><tr data-academic-row>
                        <td><strong><%#: Eval("Name") %></strong><small><%#: Eval("UniversityEmail") %></small><small><%#: Eval("Email") %></small></td>
                        <td><span class="academic-mobile-label">Major</span><%#: Eval("Major") %></td>
                        <td><span class="academic-mobile-label">Phone</span><%#: Eval("PhoneNumber") %></td>
                        <td><asp:HyperLink runat="server" Text="Edit" CssClass="btn btn-outline-primary btn-sm" NavigateUrl='<%# EditUrl((string)Eval("Id")) %>' /></td>
                    </tr></ItemTemplate></asp:Repeater>
                </tbody></table>
                <asp:Panel ID="emptyDirectory" runat="server" CssClass="academic-empty" Visible="false"><i class="bi bi-search" aria-hidden="true"></i><h3>No matching supervisors</h3><p>Add a supervisor or try another search.</p></asp:Panel>
                <nav class="academic-pagination" aria-label="Supervisor directory pages"><span><asp:Literal ID="pageSummary" runat="server" /></span><div><asp:HyperLink ID="previousPage" runat="server" CssClass="btn btn-outline-primary btn-sm" Text="Previous" /><asp:HyperLink ID="nextPage" runat="server" CssClass="btn btn-outline-primary btn-sm" Text="Next" /></div></nav>
            </ContentTemplate><Triggers><asp:AsyncPostBackTrigger ControlID="supervisorSearch" EventName="TextChanged" /><asp:AsyncPostBackTrigger ControlID="searchButton" EventName="Click" /></Triggers></asp:UpdatePanel>
        </section>
    </asp:Panel>

    <div class="modal fade academic-modal" id="academicModal" tabindex="-1" aria-labelledby="editorHeading" aria-hidden="true"><div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable"><div class="modal-content">
        <asp:UpdatePanel ID="editorUpdate" runat="server" UpdateMode="Conditional"><ContentTemplate>
            <asp:HiddenField ID="openEditor" ClientIDMode="Static" runat="server" Value="0" />
            <asp:Panel ID="editorPanel" runat="server" CssClass="academic-editor" Visible="false" DefaultButton="save">
                <div class="modal-header"><div><p class="academic-eyebrow">ACADEMIC ACCOUNT</p><h2 id="editorHeading" class="modal-title"><asp:Literal ID="editorTitle" runat="server" Text="Add academic supervisor" /></h2><p class="academic-editor-note">Supervisor details, academic specialization and sign-in information.</p></div><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button></div>
                <div class="modal-body">
                    <asp:Panel ID="editorNotice" runat="server" CssClass="academic-notice academic-error" role="alert" Visible="false"><asp:Literal ID="editorMessage" runat="server" Mode="Encode" /></asp:Panel>
                    <fieldset class="academic-fields"><legend><span>1</span> Supervisor details</legend><div class="academic-form-grid">
                        <div><asp:Label runat="server" AssociatedControlID="fullName" Text="Full name *" /><asp:TextBox ID="fullName" runat="server" CssClass="form-control" MaxLength="100" autocomplete="name" /></div>
                        <div><asp:Label runat="server" AssociatedControlID="email" Text="Login email *" /><asp:TextBox ID="email" runat="server" CssClass="form-control" MaxLength="254" inputmode="email" /><small>Fixed after account creation.</small></div>
                        <div><asp:Label runat="server" AssociatedControlID="universityEmail" Text="University email *" /><asp:TextBox ID="universityEmail" runat="server" CssClass="form-control" MaxLength="254" inputmode="email" /></div>
                        <div><asp:Label runat="server" AssociatedControlID="phone" Text="Jordanian mobile number *" /><asp:TextBox ID="phone" runat="server" CssClass="form-control" TextMode="Phone" MaxLength="10" placeholder="0791234567" inputmode="numeric" /><small>10 digits, starting with 07.</small></div>
                    </div></fieldset>
                    <fieldset class="academic-fields"><legend><span>2</span> Academic specialization</legend><div class="academic-form-grid"><div><asp:Label runat="server" AssociatedControlID="major" Text="Major *" /><asp:DropDownList ID="major" runat="server" CssClass="form-select"><asp:ListItem Value="">Select a major</asp:ListItem><asp:ListItem>Computer Science</asp:ListItem><asp:ListItem>Cybersecurity</asp:ListItem><asp:ListItem>Computer Information Systems</asp:ListItem><asp:ListItem>Business Information Technology</asp:ListItem><asp:ListItem>Data Science</asp:ListItem><asp:ListItem>Artificial Intelligence</asp:ListItem></asp:DropDownList></div><div class="academic-major-note"><i class="bi bi-mortarboard" aria-hidden="true"></i><p>One major per supervisor. Reassign their students before changing their specialization.</p></div></div></fieldset>
                    <asp:Panel ID="passwordArea" runat="server"><fieldset class="academic-fields academic-password-section"><legend><span>3</span> Account access</legend><asp:Label runat="server" AssociatedControlID="temporaryPassword" Text="Temporary password" /><div class="academic-password"><asp:TextBox ID="temporaryPassword" ClientIDMode="Static" runat="server" CssClass="form-control" ReadOnly="true" autocomplete="off" spellcheck="false" /><asp:Button ID="generatePassword" runat="server" Text="Regenerate" CssClass="btn btn-outline-primary" OnClick="GeneratePassword" CausesValidation="false" /></div><small>Generated automatically. Copy it before saving; the supervisor must change it at first login.</small></fieldset></asp:Panel>
                </div>
                <div class="modal-footer"><button type="button" class="btn btn-outline-primary" data-bs-dismiss="modal">Cancel</button><asp:Button ID="save" ClientIDMode="Static" runat="server" CssClass="btn btn-primary" Text="Create account" OnClick="SaveClick" formnovalidate="formnovalidate" /></div>
            </asp:Panel>
        </ContentTemplate><Triggers><asp:AsyncPostBackTrigger ControlID="generatePassword" EventName="Click" /><asp:AsyncPostBackTrigger ControlID="save" EventName="Click" /></Triggers></asp:UpdatePanel>
    </div></div></div>
    <asp:Panel ID="savedPanel" runat="server" Visible="false"><div class="modal fade academic-result-modal" id="academicSavedModal" tabindex="-1" aria-labelledby="savedTitle"><div class="modal-dialog modal-dialog-centered"><div class="modal-content"><div class="modal-body"><span class="academic-result-icon"><i class="bi bi-check-lg" aria-hidden="true"></i></span><h2 id="savedTitle">Supervisor saved</h2><p><asp:Literal ID="savedMessage" runat="server" Mode="Encode" /></p><button type="button" class="btn btn-primary" data-bs-dismiss="modal">OK</button></div></div></div></div></asp:Panel>
    <script src="<%= ResolveUrl("~/Coordinator/ManageAcademicSupervisors/academic-supervisors.js?v=20261023-1") %>" defer></script>
</asp:Content>
