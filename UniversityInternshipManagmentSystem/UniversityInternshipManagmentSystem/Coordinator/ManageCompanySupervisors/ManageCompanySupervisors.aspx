<%@ Page Title="Company supervisors" Language="C#" Async="true" AutoEventWireup="true" ViewStateEncryptionMode="Always" CodeBehind="ManageCompanySupervisors.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Coordinator.ManageCompanySupervisorsPage" MasterPageFile="~/Shared/Dashboard.Master" %>
<asp:Content ID="head" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="company-supervisors.css?v=20261023-2" rel="stylesheet" />
</asp:Content>
<asp:Content ID="content" ContentPlaceHolderID="MainContent" runat="server">
    <asp:ScriptManager ID="companyScripts" runat="server" />
    <header class="company-heading">
        <div><p class="company-eyebrow">COORDINATOR / ACCOUNT MANAGEMENT</p><h1 class="page-title">Company supervisors</h1><p class="text-muted">Manage company contacts and sign-in access.</p></div>
        <asp:HyperLink ID="addCompany" runat="server" Visible="false" CssClass="btn btn-primary"><i class="bi bi-plus-lg" aria-hidden="true"></i> Add supervisor</asp:HyperLink>
    </header>
    <asp:Panel ID="messagePanel" runat="server" CssClass="company-notice company-error" role="alert" Visible="false"><asp:Literal ID="message" runat="server" Mode="Encode" /></asp:Panel>
    <asp:Panel ID="workspace" runat="server" Visible="false" DefaultButton="searchButton">
        <section class="company-summary" aria-label="Company supervisors total"><div class="company-summary-main"><span class="company-summary-icon"><i class="bi bi-buildings" aria-hidden="true"></i></span><div><span class="company-summary-label">Company supervisors</span><strong><asp:Literal ID="companyCount" runat="server" /></strong></div></div><p>Company supervisor accounts.<br />Manage company contacts and sign-in access.</p></section>
        <section class="card company-card" aria-labelledby="directoryTitle">
            <div class="company-section-heading"><div><h2 id="directoryTitle">Company directory</h2><p class="text-muted">Company details, supervisor accounts and sign-in access.</p></div></div>
            <div class="company-search-tools"><div class="company-search-field"><asp:Label runat="server" AssociatedControlID="companySearch" CssClass="visually-hidden" Text="Search companies or supervisors" /><i class="bi bi-search" aria-hidden="true"></i><asp:TextBox ID="companySearch" ClientIDMode="Static" runat="server" CssClass="form-control" MaxLength="120" placeholder="Search company, supervisor or email" OnTextChanged="SearchChanged" /></div><asp:Button ID="searchButton" ClientIDMode="Static" runat="server" Text="Search" CssClass="btn btn-outline-primary" OnClick="SearchChanged" CausesValidation="false" /></div>
            <asp:UpdatePanel ID="directoryUpdate" runat="server" UpdateMode="Conditional"><ContentTemplate>
                <table class="table company-table"><thead><tr><th scope="col">Company</th><th scope="col">Supervisor</th><th scope="col">Contact</th><th scope="col">Status</th><th scope="col">Actions</th></tr></thead><tbody>
                    <asp:Repeater ID="companies" runat="server"><ItemTemplate>
                        <tr data-company-row>
                            <td><strong><%#: Eval("CompanyName") %></strong><small><%#: Eval("Location") %></small></td>
                            <td><span class="company-mobile-label">Supervisor</span><strong><%#: Eval("Name") %></strong><small><%#: Eval("Email") %></small></td>
                            <td><small><%#: Eval("CompEmail") %></small><small><%#: Eval("PhoneNumber") %></small></td>
                            <td><span class="company-mobile-label">Status</span><span class='company-status <%# AccountStatus((string)Eval("Id")) == "Active" ? "company-active" : AccountStatus((string)Eval("Id")) == "Inactive" ? "company-inactive" : "company-pending" %>'><%#: AccountStatus((string)Eval("Id")) %></span></td>
                            <td><div class="company-row-actions">
                                <asp:HyperLink runat="server" Text="Edit" CssClass="btn btn-outline-primary btn-sm" NavigateUrl='<%# AccountUrl((string)Eval("Id"), false) %>' />
                                <asp:HyperLink runat="server" Text='<%# CanToggle((string)Eval("Id")) ? AccountStatus((string)Eval("Id")) == "Active" ? "Deactivate" : "Activate" : "Unavailable" %>' CssClass="btn btn-outline-primary btn-sm" Enabled='<%# CanToggle((string)Eval("Id")) %>' NavigateUrl='<%# AccountUrl((string)Eval("Id"), true) %>' />
                            </div></td>
                        </tr>
                    </ItemTemplate></asp:Repeater>
                </tbody></table>
                <asp:Panel ID="emptyDirectory" runat="server" CssClass="company-empty" Visible="false"><i class="bi bi-search" aria-hidden="true"></i><h3>No matching accounts</h3><p>Add a supervisor or try another search.</p></asp:Panel>
                <nav class="company-pagination" aria-label="Company directory pages"><span><asp:Literal ID="pageSummary" runat="server" /></span><div><asp:HyperLink ID="previousPage" runat="server" CssClass="btn btn-outline-primary btn-sm" Text="Previous" /><asp:HyperLink ID="nextPage" runat="server" CssClass="btn btn-outline-primary btn-sm" Text="Next" /></div></nav>
            </ContentTemplate><Triggers><asp:AsyncPostBackTrigger ControlID="companySearch" EventName="TextChanged" /><asp:AsyncPostBackTrigger ControlID="searchButton" EventName="Click" /></Triggers></asp:UpdatePanel>
            <p class="company-auth-note"><i class="bi bi-shield-check" aria-hidden="true"></i> Inactive accounts cannot sign in. “No login linked” means this record has no matching Authentication account.</p>
        </section>
    </asp:Panel>

    <div class="modal fade company-modal" id="companyModal" tabindex="-1" aria-labelledby="editorTitle" aria-hidden="true"><div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable"><div class="modal-content">
        <asp:UpdatePanel ID="editorUpdate" runat="server" UpdateMode="Conditional"><ContentTemplate>
            <asp:HiddenField ID="openEditor" ClientIDMode="Static" runat="server" Value="0" />
            <asp:Panel ID="editorPanel" runat="server" CssClass="company-editor" Visible="false" DefaultButton="saveButton">
                <div class="modal-header"><div><p class="company-eyebrow">COMPANY ACCOUNT</p><h2 id="editorTitle" class="modal-title"><asp:Literal ID="editorHeading" runat="server" Text="Add company supervisor" /></h2><p class="company-editor-note">Company details and supervisor sign-in information.</p></div><button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button></div>
                <div class="modal-body">
                    <asp:Panel ID="editorNotice" runat="server" CssClass="company-notice company-error" role="alert" Visible="false"><asp:Literal ID="editorMessage" runat="server" Mode="Encode" /></asp:Panel>
                    <fieldset class="company-fields"><legend><span>1</span> Supervisor details</legend><div class="company-form-grid">
                        <div><asp:Label runat="server" AssociatedControlID="supervisorName" Text="Full name *" /><asp:TextBox ID="supervisorName" ClientIDMode="Static" runat="server" CssClass="form-control" MaxLength="100" autocomplete="name" /></div>
                        <div><asp:Label runat="server" AssociatedControlID="loginEmail" Text="Company email *" /><asp:TextBox ID="loginEmail" runat="server" CssClass="form-control" MaxLength="254" inputmode="email" /><small>Fixed after account creation.</small></div>
                        <div><asp:Label runat="server" AssociatedControlID="phoneNumber" Text="Jordanian mobile number *" /><asp:TextBox ID="phoneNumber" runat="server" CssClass="form-control" MaxLength="10" TextMode="Phone" placeholder="0791234567" inputmode="numeric" /><small>10 digits, starting with 07.</small></div>
                    </div></fieldset>
                    <fieldset class="company-fields"><legend><span>2</span> Company information</legend><div class="company-form-grid">
                        <div><asp:Label runat="server" AssociatedControlID="companyName" Text="Company name *" /><asp:TextBox ID="companyName" runat="server" CssClass="form-control" MaxLength="150" /></div>
                        <div><asp:Label runat="server" AssociatedControlID="companyEmail" Text="Confirmed email *" /><asp:TextBox ID="companyEmail" runat="server" ReadOnly="true" CssClass="form-control" MaxLength="254" inputmode="email" /></div>
                        <div><asp:Label runat="server" AssociatedControlID="companyLocation" Text="Location *" /><asp:TextBox ID="companyLocation" runat="server" CssClass="form-control" MaxLength="200" placeholder="City and office address" /></div>
                    </div></fieldset>
                    <asp:Panel ID="passwordSection" runat="server"><fieldset class="company-fields company-password-section"><legend><span>3</span> Account access</legend><asp:Label runat="server" AssociatedControlID="temporaryPassword" Text="Temporary password" /><div class="company-password"><asp:TextBox ID="temporaryPassword" ClientIDMode="Static" runat="server" CssClass="form-control" ReadOnly="true" autocomplete="off" spellcheck="false" /><asp:Button ID="generatePassword" runat="server" Text="Regenerate" CssClass="btn btn-outline-primary" OnClick="GeneratePassword" CausesValidation="false" /></div><small>Generated automatically. Copy it before saving; the supervisor must change it at first login.</small></fieldset></asp:Panel>
                </div>
                <div class="modal-footer"><button type="button" class="btn btn-outline-primary" data-bs-dismiss="modal">Cancel</button><asp:Button ID="saveButton" ClientIDMode="Static" runat="server" Text="Create account" CssClass="btn btn-primary" OnClick="SaveClick" formnovalidate="formnovalidate" /></div>
            </asp:Panel>
        </ContentTemplate><Triggers><asp:AsyncPostBackTrigger ControlID="generatePassword" EventName="Click" /><asp:AsyncPostBackTrigger ControlID="saveButton" EventName="Click" /></Triggers></asp:UpdatePanel>
    </div></div></div>

    <asp:Panel ID="savedPanel" runat="server" Visible="false"><div class="modal fade company-result-modal" id="companySavedModal" tabindex="-1" aria-labelledby="savedTitle"><div class="modal-dialog modal-dialog-centered"><div class="modal-content"><div class="modal-body"><span class="company-result-icon"><i class="bi bi-check-lg" aria-hidden="true"></i></span><h2 id="savedTitle">Success</h2><p><asp:Literal ID="savedMessage" runat="server" Mode="Encode" /></p><button type="button" class="btn btn-primary" data-bs-dismiss="modal">OK</button></div></div></div></div></asp:Panel>
    <asp:Panel ID="confirmPanel" runat="server" Visible="false"><div class="modal fade company-result-modal" id="companyConfirmModal" tabindex="-1" aria-labelledby="confirmTitle"><div class="modal-dialog modal-dialog-centered"><div class="modal-content"><div class="modal-body"><span class="company-result-icon"><i class="bi bi-shield-lock" aria-hidden="true"></i></span><h2 id="confirmTitle">Change sign-in access</h2><p><asp:Literal ID="confirmMessage" runat="server" Mode="Encode" /></p><div class="company-confirm-actions"><button type="button" class="btn btn-outline-primary" data-bs-dismiss="modal">Cancel</button><asp:Button ID="confirmToggleButton" runat="server" CssClass="btn btn-primary" Text="Confirm" OnClick="ConfirmToggle" CausesValidation="false" /></div></div></div></div></div></asp:Panel>
    <script src="<%= ResolveUrl("~/Coordinator/ManageCompanySupervisors/company-supervisors.js?v=20261023-1") %>" defer></script>
</asp:Content>
