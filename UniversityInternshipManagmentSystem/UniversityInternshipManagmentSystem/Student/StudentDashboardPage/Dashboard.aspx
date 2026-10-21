<%@ Page Title="Student Dashboard" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" Async="true" CodeBehind="Dashboard.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Student.StudentDashboardPage.Dashboard" %>
<asp:Content ID="PageHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/Student/Content/Student.css") %>" />
    <link rel="stylesheet" href="<%= ResolveUrl("~/Student/StudentDashboardPage/Dashboard.css") %>" />
</asp:Content>
<asp:Content ID="DashboardContent" ContentPlaceHolderID="MainContent" runat="server">
    <div class="student-dashboard">
        <a class="sd-skip" href="#page-content">Skip to page content</a>
        <div id="student-request-status" class="sd-message" role="status" aria-live="polite" hidden></div>
        <% if (!string.IsNullOrEmpty(DataError)) { %><div class="sd-message" role="alert"><%: DataError %></div><% } %>
        <% if (Workspace == null) { %><p class="mb-3"><a class="sd-document-link" href="<%= ResolveUrl("~/Student/StudentProfilePage/Profile.aspx") %>">Open Student Profile for local test sign-in</a></p><% } %>
        <div id="page-content" tabindex="-1">

    <div class="sd-heading"><div><span class="sd-eyebrow">Your internship, at a glance</span><h1>Student Dashboard</h1><p class="sd-muted">A clear view of your learning journey.</p></div><span class="sd-demo"><%: ModeLabel %></span></div>
    <% if (Workspace != null) { %>
    <section class="sd-welcome sd-campus" aria-labelledby="welcome-title"><div><span class="sd-eyebrow">The University of Jordan · الجامعة الأردنية</span><h2 id="welcome-title">Welcome, <%: DisplayName %>.</h2><p>Your next chapter starts with a little progress, every day. Keep your information up to date and follow your internship journey here.</p><a class="sd-button mt-3" href="<%= ResolveUrl("~/Student/StudentProfilePage/Profile.aspx") %>">View my profile <span aria-hidden="true">&#8599;</span></a></div></section>
    <% if (!string.IsNullOrEmpty(ActivityError)) { %><div class="sd-message" role="alert"><%: ActivityError %></div><% } %>
    <% if (!ActivityAvailable && string.IsNullOrEmpty(ActivityError)) { %><div class="sd-message" role="note">Activity modules are not connected. Application, task, and deadline totals are unavailable; no activity or training-hour records are assumed.</div><% } %>
    <div class="row g-3 mb-4" aria-label="Dashboard summaries">
        <div class="col-6 col-xl-3"><a class="sd-stat sd-stat-link" href="#applications"><div class="sd-stat-top">Applications<span class="sd-stat-icon" aria-hidden="true">&#9707;</span></div><div class="sd-number"><%: ActivityCount(Overview.Applications.Count) %></div><p class="sd-muted"><%: Overview.Applications.Count == 0 ? "No applications to display" : "View application statuses" %></p></a></div>
        <div class="col-6 col-xl-3"><a class="sd-stat sd-stat-link" href="#tasks"><div class="sd-stat-top">Assigned tasks<span class="sd-stat-icon" aria-hidden="true">&#9745;</span></div><div class="sd-number"><%: ActivityCount(Overview.Tasks.Count) %></div><p class="sd-muted"><%: Overview.Tasks.Count == 0 ? "No assigned tasks to display" : "View task statuses" %></p></a></div>
        <div class="col-6 col-xl-3"><a class="sd-stat sd-stat-link" href="#deadlines"><div class="sd-stat-top">Upcoming deadlines<span class="sd-stat-icon" aria-hidden="true">&#9633;</span></div><div class="sd-number"><%: ActivityCount(Overview.Deadlines.Count) %></div><p class="sd-muted"><%: Overview.Deadlines.Count == 0 ? "No deadlines to display" : "View upcoming dates" %></p></a></div>
        <div class="col-6 col-xl-3"><a class="sd-stat sd-stat-link" href="#progress"><div class="sd-stat-top">Approved hours<span class="sd-stat-icon" aria-hidden="true">&#9684;</span></div><div class="sd-number"><%: HoursText %></div><p class="sd-muted">Approved training hours only</p></a></div>
    </div>
    <div class="row g-4">
        <div class="col-xl-8"><section class="sd-panel" id="applications" aria-labelledby="applications-title"><div class="sd-panel-head"><h2 id="applications-title">My applications</h2><span class="sd-count"><%: RecordCount(Overview.Applications.Count) %></span></div>
            <% if (Overview.Applications.Count == 0) { %><div class="sd-empty"><span class="sd-empty-icon" aria-hidden="true">&#9707;</span><h3>No applications to display</h3><p>Applications and their statuses will appear when the applications module is connected.</p></div><% } %>
            <asp:Repeater ID="ApplicationsList" runat="server"><HeaderTemplate><ul class="sd-activity-list"></HeaderTemplate><ItemTemplate><li><div><h3><%#: Eval("Title") %></h3><p class="sd-muted"><%#: Eval("Detail") %></p></div><span class="sd-badge"><%#: Eval("Status") %></span></li></ItemTemplate><FooterTemplate></ul></FooterTemplate></asp:Repeater>
        </section></div>
        <div class="col-xl-4"><section class="sd-panel" id="deadlines" aria-labelledby="deadlines-title"><div class="sd-panel-head"><h2 id="deadlines-title">Upcoming deadlines</h2></div>
            <% if (Overview.Deadlines.Count == 0) { %><div class="sd-empty"><span class="sd-empty-icon" aria-hidden="true">&#9633;</span><h3>No deadlines to display</h3><p>Upcoming dates will appear when connected modules provide them.</p></div><% } %>
            <asp:Repeater ID="DeadlinesList" runat="server"><HeaderTemplate><ul class="sd-activity-list"></HeaderTemplate><ItemTemplate><li><div><h3><%#: Eval("Title") %></h3><p class="sd-muted"><%#: Eval("Detail") %></p><p class="sd-muted">Due: <%#: FormatDeadline(Eval("DueUtc")) %></p></div></li></ItemTemplate><FooterTemplate></ul></FooterTemplate></asp:Repeater>
        </section></div>
        <div class="col-xl-8"><section class="sd-panel" id="tasks" aria-labelledby="tasks-title"><div class="sd-panel-head"><h2 id="tasks-title">Assigned tasks</h2><span class="sd-count"><%: RecordCount(Overview.Tasks.Count) %></span></div>
            <% if (Overview.Tasks.Count == 0) { %><div class="sd-empty"><span class="sd-empty-icon" aria-hidden="true">&#9745;</span><h3>No assigned tasks to display</h3><p>Your tasks, instructions, and statuses will appear when the tasks module is connected.</p></div><% } %>
            <asp:Repeater ID="TasksList" runat="server"><HeaderTemplate><ul class="sd-activity-list"></HeaderTemplate><ItemTemplate><li><div><h3><%#: Eval("Title") %></h3><p class="sd-muted"><%#: Eval("Detail") %></p><p class="sd-muted">Due: <%#: FormatDeadline(Eval("DueUtc")) %></p></div><span class="sd-badge"><%#: Eval("Status") %></span></li></ItemTemplate><FooterTemplate></ul></FooterTemplate></asp:Repeater>
        </section></div>
        <div class="col-xl-4"><section class="sd-panel" id="progress" aria-labelledby="progress-title"><div class="sd-panel-head"><h2 id="progress-title">Internship progress</h2></div><div class="sd-panel-body">
            <h3><%: CompanyText %></h3><p class="sd-muted"><%: Show(Overview.InternshipStatus, "No internship progress reported") %></p><div class="sd-progress-total"><strong><%: HoursText %></strong><span class="sd-muted">approved hours</span></div>
            <% if (ProgressPercent.HasValue) { %><div class="progress" role="progressbar" aria-label="Approved training hours" aria-valuenow="<%: ProgressPercent.Value %>" aria-valuemin="0" aria-valuemax="100"><div class="progress-bar" style="width: <%: ProgressPercent.Value %>%"></div></div><% } %>
            <div class="sd-training-detail"><span>Training-hour requirement</span><strong><%: Overview.RequiredHours.HasValue ? Overview.RequiredHours.Value.ToString("0.##") + " hours" : "Not provided" %></strong></div><p class="sd-note">No training-hour records or official target are assumed. This summary is not an academic grade.</p>
        </div></section></div>
        <div class="col-12"><section class="sd-panel" id="evaluations" aria-labelledby="evaluations-title"><div class="sd-panel-head"><h2 id="evaluations-title">Evaluations &amp; feedback</h2><span class="sd-count">Student-visible only</span></div>
            <% if (Overview.Evaluations.Count == 0) { %><div class="sd-empty"><span class="sd-empty-icon" aria-hidden="true">&#9734;</span><h3>No published evaluations or feedback</h3><p>Only feedback released to you will appear after the evaluations module is connected.</p></div><% } %>
            <asp:Repeater ID="EvaluationsList" runat="server"><HeaderTemplate><ul class="sd-activity-list"></HeaderTemplate><ItemTemplate><li><div><h3><%#: Eval("Title") %></h3><p class="sd-feedback"><%#: Eval("Detail") %></p><p class="sd-muted">Due: <%#: FormatDeadline(Eval("DueUtc")) %></p></div><span class="sd-badge"><%#: Eval("Status") %></span></li></ItemTemplate><FooterTemplate></ul></FooterTemplate></asp:Repeater>
        </section></div>
    </div>
    <% } %>
        </div>
    </div>
    <script src="<%= ResolveUrl("~/Student/Content/Student.js") %>" defer></script>
</asp:Content>
