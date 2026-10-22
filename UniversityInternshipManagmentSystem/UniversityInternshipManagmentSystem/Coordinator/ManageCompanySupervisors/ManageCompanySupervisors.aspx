<%@ Page Title="Company supervisors" Language="C#" Async="true" AutoEventWireup="true" CodeBehind="ManageCompanySupervisors.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Coordinator.ManageCompanySupervisorsPage" MasterPageFile="~/Shared/Dashboard.Master" %>
<asp:Content ID="head" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="company-supervisors.css?v=20261021-3" rel="stylesheet" />
</asp:Content>
<asp:Content ID="content" ContentPlaceHolderID="MainContent" runat="server">
    <header class="company-heading"><div><p class="company-eyebrow">COORDINATOR / ACCOUNT MANAGEMENT</p><h1 class="page-title">Company supervisors</h1><p class="text-muted">Manage company contacts and sign-in access.</p></div><asp:LinkButton ID="addCompany" runat="server" Visible="false" Text="Add supervisor" CssClass="btn btn-primary" OnClick="AddClick" CausesValidation="false" /></header>
    <asp:Panel ID="messagePanel" runat="server" CssClass="company-preview" role="status" Visible="false"><asp:Literal ID="message" runat="server" Mode="Encode" /></asp:Panel>
    <asp:Panel ID="workspace" runat="server" Visible="false">
        <section class="card company-card" aria-labelledby="directoryTitle">
            <div class="company-section-heading"><div><h2 id="directoryTitle">Company directory</h2><p class="text-muted">Find a supervisor, edit company details or manage account access.</p></div><span class="company-count"><asp:Literal ID="companyCount" runat="server" /> accounts</span></div>
            <div class="company-search-tools"><asp:Label runat="server" AssociatedControlID="companySearch" CssClass="visually-hidden" Text="Search companies or supervisors" /><asp:TextBox ID="companySearch" ClientIDMode="Static" runat="server" CssClass="form-control" MaxLength="120" placeholder="Search company, supervisor or email" /><asp:Button ID="searchButton" ClientIDMode="Static" runat="server" Text="Search" CssClass="btn btn-outline-primary" OnClick="SearchClick" CausesValidation="false" formnovalidate="formnovalidate" /></div>
            <table class="table company-table"><thead><tr><th scope="col">Company</th><th scope="col">Supervisor</th><th scope="col">Contact</th><th scope="col">Status</th><th scope="col">Actions</th></tr></thead><tbody>
                <asp:Repeater ID="companies" runat="server" OnItemCommand="CompaniesCommand"><ItemTemplate><tr data-company-row><td><strong><%#: Eval("CompanyName") %></strong><small><%#: Eval("Location") %></small></td><td><span class="company-mobile-label">Supervisor</span><%#: Eval("Name") %></td><td><small><%#: Eval("Email") %></small><small><%#: Eval("CompEmail") %></small><small><%#: Eval("PhoneNumber") %></small></td><td><span class="company-mobile-label">Status</span><span class='<%# Eval("StatusClass") %>'><%#: Eval("StatusText") %></span></td><td><div class="company-row-actions"><asp:LinkButton runat="server" Text="Edit" CssClass="btn btn-outline-primary btn-sm" CommandName="EditCompany" CommandArgument='<%# Eval("Id") %>' CausesValidation="false" /><asp:LinkButton runat="server" Text='<%# Eval("ToggleText") %>' CssClass='<%# Eval("ToggleClass") %>' Enabled='<%# Eval("CanToggle") %>' CommandName="ToggleLogin" CommandArgument='<%# Eval("Id") %>' CausesValidation="false" OnClientClick="return confirm('Change sign-in access for this company supervisor?');" /></div></td></tr></ItemTemplate></asp:Repeater>
            </tbody></table>
            <p id="companyLiveEmpty" class="company-empty" hidden>No matching companies. Try another name or email.</p>
            <asp:Panel ID="emptyDirectory" runat="server" CssClass="company-empty" Visible="false"><h3>No matching accounts</h3><p>Add a company supervisor or change your search.</p></asp:Panel>
            <p class="company-auth-note">Inactive accounts cannot sign in until reactivated. “No login linked” means the database record does not have a matching Authentication UID.</p>
        </section>
        <asp:Panel ID="editorPanel" runat="server" Visible="false">
        <section id="companyEditor" class="card company-card" aria-labelledby="editorTitle">
            <p class="company-eyebrow">COMPANY ACCOUNT</p><h2 id="editorTitle"><asp:Literal ID="editorHeading" runat="server" Text="Add company supervisor" /></h2>
            <fieldset class="company-fields"><legend>Supervisor details</legend><div class="company-form-grid">
                <div><asp:Label runat="server" AssociatedControlID="supervisorName" Text="Full name *" /><asp:TextBox ID="supervisorName" ClientIDMode="Static" runat="server" CssClass="form-control" MaxLength="100" autocomplete="name" /></div>
                <div><asp:Label runat="server" AssociatedControlID="loginEmail" Text="Login email *" /><asp:TextBox ID="loginEmail" runat="server" CssClass="form-control" MaxLength="254" inputmode="email" /><small>Login email is fixed after account creation.</small></div>
                <div><asp:Label runat="server" AssociatedControlID="phoneNumber" Text="Phone number *" /><asp:TextBox ID="phoneNumber" runat="server" CssClass="form-control" MaxLength="25" TextMode="Phone" placeholder="+962 7X XXX XXXX" /></div>
            </div></fieldset>
            <fieldset class="company-fields"><legend>Company information</legend><div class="company-form-grid">
                <div><asp:Label runat="server" AssociatedControlID="companyName" Text="Company name *" /><asp:TextBox ID="companyName" runat="server" CssClass="form-control" MaxLength="150" /></div>
                <div><asp:Label runat="server" AssociatedControlID="companyEmail" Text="Company email *" /><asp:TextBox ID="companyEmail" runat="server" CssClass="form-control" MaxLength="254" inputmode="email" /></div>
                <div><asp:Label runat="server" AssociatedControlID="companyLocation" Text="Location *" /><asp:TextBox ID="companyLocation" runat="server" CssClass="form-control" MaxLength="200" placeholder="City and office address" /></div>
            </div></fieldset>
            <asp:Panel ID="passwordSection" runat="server"><fieldset class="company-fields"><legend>Account access</legend><div class="company-password-field"><asp:Label runat="server" AssociatedControlID="temporaryPassword" Text="Temporary password *" /><div class="company-password"><asp:TextBox ID="temporaryPassword" ClientIDMode="Static" runat="server" TextMode="Password" CssClass="form-control" MaxLength="128" autocomplete="new-password" aria-describedby="passwordHelp" /><button id="togglePassword" type="button" aria-controls="temporaryPassword" aria-pressed="false">Show</button></div><small id="passwordHelp">At least 12 characters. A password change is required at first login.</small></div></fieldset></asp:Panel>
            <div class="company-actions"><asp:Button ID="saveButton" runat="server" Text="Create account" CssClass="btn btn-primary" OnClick="SaveClick" formnovalidate="formnovalidate" /><asp:Button runat="server" Text="Cancel" CssClass="btn btn-outline-primary" OnClick="CancelClick" CausesValidation="false" formnovalidate="formnovalidate" /></div>
        </section></asp:Panel>
    </asp:Panel>
    <script src="<%= ResolveUrl("~/Coordinator/ManageCompanySupervisors/company-supervisors.js?v=20261021-3") %>" defer></script>
</asp:Content>
