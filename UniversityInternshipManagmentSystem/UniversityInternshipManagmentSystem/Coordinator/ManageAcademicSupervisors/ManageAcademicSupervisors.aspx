<%@ Assembly Name="System.Net.Http, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a" %>
<%@ Page Language="C#" Async="true" AutoEventWireup="true" CodeBehind="ManageAcademicSupervisors.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Coordinator.CoordinatorAcademicAccounts" MasterPageFile="~/Shared/Dashboard.Master" %>
<asp:Content ID="head" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="academic-supervisors.css" />
</asp:Content>
<asp:Content ID="body" ContentPlaceHolderID="MainContent" runat="server">
    <div class="academic-heading"><div><p class="academic-eyebrow">COORDINATOR / ACCOUNT MANAGEMENT</p><h1 class="page-title">Academic supervisors</h1><p class="text-muted">Manage supervisor profiles and their academic specializations.</p></div><a id="addSupervisor" runat="server" visible="false" href="#editor" class="btn btn-primary">Add supervisor</a></div>
    <asp:Panel ID="notice" runat="server" role="status" CssClass="academic-notice" Visible="false"><asp:Literal ID="noticeText" runat="server" Mode="Encode" /></asp:Panel>
    <asp:Panel ID="workspace" runat="server" Visible="false">
        <div class="academic-summary"><div><span class="small-label">Academic supervisors</span><strong><asp:Literal ID="total" runat="server" /></strong></div><p>Assign students to a supervisor with the same major when creating student accounts.</p></div>
        <div class="academic-grid">
            <section class="card academic-card"><div class="academic-section"><h2>Supervisor directory</h2><label for="supervisorSearch" class="visually-hidden">Search supervisors</label><input id="supervisorSearch" type="search" class="form-control" placeholder="Search name, email or major" maxlength="120" /></div>
                <div class="table-responsive"><table class="table align-middle"><thead><tr><th scope="col">Supervisor</th><th scope="col">Major</th><th scope="col">Phone</th><th scope="col">Action</th></tr></thead><tbody id="directory">
                <asp:Repeater ID="directory" runat="server" OnItemCommand="DirectoryCommand"><ItemTemplate><tr class="supervisor-row"><td><strong><%#: Eval("Name") %></strong><small><%#: Eval("UniversityEmail") %></small></td><td><%#: Eval("Major") %></td><td><%#: Eval("PhoneNumber") %></td><td><asp:LinkButton runat="server" Text="Edit" CommandName="EditSupervisor" CommandArgument='<%# Eval("Id") %>' CausesValidation="false" CssClass="btn btn-outline-primary btn-sm" /></td></tr></ItemTemplate></asp:Repeater>
                </tbody></table></div><p id="searchEmpty" hidden>No supervisors match your search.</p><asp:Label ID="emptyDirectory" runat="server" Visible="false" Text="No academic supervisors yet. Add the first supervisor using this form." CssClass="academic-empty-directory" />
            </section>
            <section id="editor" class="card academic-card"><h2><asp:Literal ID="editorTitle" runat="server" Text="Add supervisor" /></h2><p class="text-muted">The account role is Academic Supervisor.</p>
                <asp:ValidationSummary runat="server" ValidationGroup="Supervisor" CssClass="academic-validation-summary" HeaderText="Please check the following:" />
                <asp:Label runat="server" AssociatedControlID="fullName" Text="Full name" /><asp:TextBox ID="fullName" runat="server" CssClass="form-control" MaxLength="100" />
                <asp:RequiredFieldValidator runat="server" ControlToValidate="fullName" ValidationGroup="Supervisor" ErrorMessage="Full name is required." Display="Dynamic" />
                <asp:Label runat="server" AssociatedControlID="email" Text="Login email" /><asp:TextBox ID="email" runat="server" CssClass="form-control" MaxLength="254" TextMode="Email" /><small class="text-muted">Login email cannot be changed here after account creation.</small>
                <asp:Label runat="server" AssociatedControlID="universityEmail" Text="University email" /><asp:TextBox ID="universityEmail" runat="server" CssClass="form-control" MaxLength="254" TextMode="Email" />
                <asp:Label runat="server" AssociatedControlID="major" Text="Major" /><asp:DropDownList ID="major" runat="server" CssClass="form-select">
                    <asp:ListItem Value="">Select a major</asp:ListItem>
                    <asp:ListItem Value="Computer Science">Computer Science</asp:ListItem>
                    <asp:ListItem Value="Cybersecurity">Cybersecurity</asp:ListItem>
                    <asp:ListItem Value="Computer Information Systems">Computer Information Systems</asp:ListItem>
                    <asp:ListItem Value="Business Information Technology">Business Information Technology</asp:ListItem>
                    <asp:ListItem Value="Data Science">Data Science</asp:ListItem>
                    <asp:ListItem Value="Artificial Intelligence">Artificial Intelligence</asp:ListItem>
                </asp:DropDownList><small class="text-muted">Choose the supervisor's academic specialization.</small>
                <asp:Label runat="server" AssociatedControlID="phone" Text="Phone number" /><asp:TextBox ID="phone" runat="server" CssClass="form-control" MaxLength="25" TextMode="Phone" />
                <asp:Panel ID="passwordArea" runat="server"><asp:Label runat="server" AssociatedControlID="temporaryPassword" Text="Temporary password" /><asp:TextBox ID="temporaryPassword" runat="server" CssClass="form-control" TextMode="Password" MaxLength="128" /><small class="text-muted">Use at least 12 characters. Share it with the supervisor securely. A password change is required at first login.</small></asp:Panel>
                <div class="academic-editor-actions"><asp:Button ID="save" runat="server" Text="Create account" CssClass="btn btn-primary" ValidationGroup="Supervisor" OnClick="SaveClick" /><asp:Button runat="server" Text="Cancel" CssClass="btn btn-outline-primary" CausesValidation="false" OnClick="CancelClick" /></div>
            </section>
        </div>
    </asp:Panel>
    <script src="<%= ResolveUrl("~/Coordinator/ManageAcademicSupervisors/academic-supervisors.js") %>" defer></script>
</asp:Content>
