<%@ Page Language="C#" Async="true" AutoEventWireup="true" CodeBehind="AssignAcademicSupervisors.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Coordinator.AssignAcademicSupervisorsPage" MasterPageFile="~/Shared/Dashboard.Master" %>
<asp:Content ID="head" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="assign-supervisors.css?v=20261021-2" rel="stylesheet" />
</asp:Content>
<asp:Content ID="content" ContentPlaceHolderID="MainContent" runat="server">
    <header class="assign-heading"><div><p class="assign-eyebrow">COORDINATOR / ACCOUNT MANAGEMENT</p><h1 class="page-title">Assign academic supervisors</h1><p class="text-muted">Group students by major and manage their academic supervision.</p></div><a class="btn btn-outline-primary" runat="server" href="~/Coordinator/ManageAcademicSupervisors/ManageAcademicSupervisors.aspx">Manage supervisors</a></header>
    <asp:Panel ID="messagePanel" runat="server" Visible="false" role="status"><asp:Literal ID="message" runat="server" Mode="Encode" /></asp:Panel>
    <asp:Panel ID="workspace" runat="server" Visible="false">
    <section class="card assign-filters" aria-labelledby="filterTitle">
        <h2 id="filterTitle" class="section-title">Find a student group</h2>
        <div class="assign-filter-grid">
            <div><label for="assignMajor">Major</label><asp:DropDownList ID="assignMajor" ClientIDMode="Static" runat="server" CssClass="form-select" AutoPostBack="true" OnSelectedIndexChanged="FiltersChanged"><asp:ListItem Value="">Select a major</asp:ListItem><asp:ListItem>Computer Science</asp:ListItem><asp:ListItem>Cybersecurity</asp:ListItem><asp:ListItem>Computer Information Systems</asp:ListItem><asp:ListItem>Business Information Technology</asp:ListItem><asp:ListItem>Data Science</asp:ListItem><asp:ListItem>Artificial Intelligence</asp:ListItem></asp:DropDownList></div>
            <div><label for="assignSearch">Student name or university email</label><input id="assignSearch" type="search" class="form-control" placeholder="Search students" maxlength="120" /></div>
            <div><label for="assignStatus">Current assignment</label><asp:DropDownList ID="assignStatus" ClientIDMode="Static" runat="server" CssClass="form-select" AutoPostBack="true" OnSelectedIndexChanged="FiltersChanged"><asp:ListItem Value="All">All students</asp:ListItem><asp:ListItem Value="Unassigned">Unassigned</asp:ListItem><asp:ListItem Value="Assigned">Already assigned</asp:ListItem></asp:DropDownList></div>
        </div>
    </section>
    <div class="assign-grid">
        <section class="card assign-students" aria-labelledby="studentsTitle">
            <div class="assign-section-heading"><div><h2 id="studentsTitle" class="section-title">Students</h2><p class="text-muted"><asp:Literal ID="groupCaption" Mode="Encode" runat="server" /></p></div><span id="assignSelectionBadge" class="assign-count">0 selected</span></div>
            <div class="assign-table-toolbar"><label class="assign-checkbox-label"><input id="assignSelectAll" type="checkbox" class="form-check-input" /> Select all visible students</label><button id="assignClear" type="button" class="btn btn-outline-primary btn-sm">Clear selection</button></div>
            <table class="table align-middle assign-table"><thead><tr><th scope="col"><span class="visually-hidden">Select</span></th><th scope="col">Student</th><th scope="col">Current supervisor</th></tr></thead><tbody id="assignStudentRows">
                <asp:Repeater ID="students" runat="server"><ItemTemplate>
                    <tr data-student-row><td><asp:CheckBox ID="selectedStudent" runat="server" aria-label="Select student" /><asp:HiddenField ID="studentId" runat="server" Value='<%# Eval("Id") %>' /></td><td><strong><%#: Eval("Name") %></strong><small><%#: Eval("UniEmail") %></small></td><td><span class="assign-mobile-label">Current supervisor: </span><%#: Eval("SupervisorName") %></td></tr>
                </ItemTemplate></asp:Repeater>
                <tr id="assignEmptyRow" hidden><td colspan="3" class="assign-empty">No students match this selection.</td></tr>
            </tbody></table>
            <p class="assign-help">Changing the major or assignment filter clears the selection.</p>
        </section>
        <aside class="card assign-panel" aria-labelledby="assignmentTitle">
            <p class="assign-eyebrow">GROUP ASSIGNMENT</p><h2 id="assignmentTitle" class="section-title">Set academic supervisor</h2><p class="text-muted">Select students, then choose a supervisor from the same major.</p>
            <label for="assignSupervisor">Academic supervisor</label><asp:DropDownList ID="assignSupervisor" ClientIDMode="Static" runat="server" CssClass="form-select" />
            <p class="assign-help"><asp:Literal ID="supervisorHelp" runat="server" Mode="Encode" /></p><a class="assign-manage-link" runat="server" href="~/Coordinator/ManageAcademicSupervisors/ManageAcademicSupervisors.aspx">Create or manage supervisors</a>
            <p class="assign-reassignment-note">The new supervisor replaces the current assignment for selected students only.</p>
            <asp:Button ID="reviewButton" ClientIDMode="Static" runat="server" Text="Review assignment" CssClass="btn btn-primary w-100" OnClick="ReviewAssignment" />
        </aside>
    </div>
    <asp:Panel ID="reviewPanel" runat="server" Visible="false" CssClass="card assign-review">
        <h2 class="section-title">Review assignment</h2><p><asp:Literal ID="reviewSummary" Mode="Encode" runat="server" /></p>
        <ul class="assign-review-students"><asp:Repeater ID="reviewStudents" runat="server"><ItemTemplate><li><strong><%#: Eval("Name") %></strong><small>Current supervisor: <%#: Eval("Previous") %></small></li></ItemTemplate></asp:Repeater></ul>
        <div class="assign-actions"><asp:Button ID="confirmButton" runat="server" Text="Confirm assignment" CssClass="btn btn-primary" OnClick="ConfirmAssignment" /><asp:Button ID="backButton" runat="server" Text="Back to selection" CssClass="btn btn-outline-primary" OnClick="CancelReview" /></div>
    </asp:Panel>
    </asp:Panel>
    <script src="<%= ResolveUrl("~/Coordinator/AssignAcademicSupervisors/assign-supervisors.js?v=20261021-2") %>" defer></script>
</asp:Content>
