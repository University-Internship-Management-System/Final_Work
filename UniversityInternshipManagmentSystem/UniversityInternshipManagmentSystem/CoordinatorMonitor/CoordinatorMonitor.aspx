<%@ Page Language="C#" Async="true" AutoEventWireup="true" CodeBehind="CoordinatorMonitor.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Coordinator.CoordinatorMonitor" MasterPageFile="~/Shared/Dashboard.Master" %>
<asp:Content ID="PageHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="CoordinatorMonitor.css" rel="stylesheet" />
</asp:Content>
<asp:Content ID="PageMain" ContentPlaceHolderID="MainContent" runat="server">
            <div class="cm-hero-card">
                <span class="cm-hero-kicker">FIELD TRAINING OFFICE</span>
                <h1>Internship Placement Monitor</h1>
                <p>Monitor students, companies, training hours, evaluations and progress.</p>
            </div>
            <p class="text-muted small mt-2">Live records from Realtime Database. This page is read only.</p>
            <asp:Label ID="lblError" runat="server" CssClass="alert alert-warning d-block" Visible="false" />
            <nav class="monitor-tabs" aria-label="Monitor sections">
                <button type="button" class="monitor-tab" data-target="studentsPanel" aria-selected="true">Students</button>
                <button type="button" class="monitor-tab" data-target="companiesPanel" aria-selected="false">Companies</button>
                <button type="button" class="monitor-tab" data-target="academicPanel" aria-selected="false">Academic supervisors</button>
            </nav>
            <asp:Panel ID="pnlUserDetail" runat="server" Visible="false" CssClass="detail-overlay" role="dialog" aria-modal="true" aria-labelledby="detailTitle">
                <div class="detail-dialog p-4 p-md-5">
                    <div class="d-flex justify-content-between align-items-center gap-3 mb-4">
                        <h2 id="detailTitle" class="section-title mb-0"><asp:Literal ID="litDetailTitle" runat="server" /></h2>
                        <a id="closeDetail" runat="server" href="~/CoordinatorMonitor/CoordinatorMonitor.aspx" class="btn btn-outline-primary btn-sm">Close</a>
                    </div>
                    <asp:Literal ID="litUserDetail" runat="server" />
                </div>
            </asp:Panel>
            <section id="studentsPanel" class="card admin-card p-3 p-md-4 mb-4 monitor-panel" aria-labelledby="studentsHeading">
                <div class="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-3">
                    <h2 id="studentsHeading" class="section-title mb-0">Students</h2>
                    <span id="studentCount" class="text-muted small"></span>
                </div>
                <div class="row g-3 mb-3 p-3 monitor-filters align-items-end" aria-label="Student filters">
                    <div class="col-lg-5 col-md-6"><label class="form-label" for="studentSearch">Search students</label><input id="studentSearch" type="search" class="form-control" placeholder="Name or email" /></div>
                    <div class="col-lg-3 col-md-6"><label class="form-label" for="majorFilter">Major</label><select id="majorFilter" class="form-select"><option value="">All majors</option><asp:Literal ID="litMajorOptions" runat="server" /></select></div>
                    <div class="col-lg-3 col-md-8"><label class="form-label" for="placementFilter">Placement</label><select id="placementFilter" class="form-select"><option value="">All students</option><option value="assigned">Assigned</option><option value="unassigned">Unassigned</option></select></div>
                    <div class="col-lg-1 col-md-4"><button id="clearFilters" type="button" class="btn btn-outline-secondary btn-sm w-100">Reset</button></div>
                </div>
                <div class="table-responsive">
                    <table class="table monitor-table align-middle mb-0">
                        <thead><tr><th>Student / Major</th><th>Training company</th><th>Academic supervisor</th><th>Training hours</th><th>Final status</th><th>Actions</th></tr></thead>
                        <tbody><asp:Literal ID="litStudentRows" runat="server" /></tbody>
                    </table>
                    <p id="noFilterResults" class="text-muted py-3 mb-0" style="display:none">No students match the selected filters.</p>
                </div>
            </section>
            <section id="academicPanel" class="card admin-card p-3 p-md-4 mb-4 monitor-panel" aria-labelledby="academicHeading" hidden>
                        <h2 id="academicHeading" class="section-title mb-3">Academic supervisors</h2>
                        <div class="table-responsive"><table class="table monitor-table align-middle mb-0">
                            <thead><tr><th>Name</th><th>Email</th><th>Major</th><th>View</th></tr></thead>
                            <tbody><asp:Literal ID="litAcademicRows" runat="server" /></tbody>
                        </table></div>
            </section>
            <section id="companiesPanel" class="card admin-card p-3 p-md-4 mb-4 monitor-panel" aria-labelledby="companyHeading" hidden>
                        <h2 id="companyHeading" class="section-title mb-3">Companies and supervisors</h2>
                        <div class="table-responsive"><table class="table monitor-table align-middle mb-0">
                            <thead><tr><th>Name</th><th>Company</th><th>Location</th><th>View</th></tr></thead>
                            <tbody><asp:Literal ID="litCompanyRows" runat="server" /></tbody>
                        </table></div>
            </section>
    <div id="studentActionMenu" class="action-menu" role="menu" aria-label="Student actions" hidden>
        <button type="button" role="menuitem" data-section="overview">Overview</button>
        <button type="button" role="menuitem" data-section="tasks">Tasks</button>
        <button type="button" role="menuitem" data-section="hours">Training hours</button>
        <button type="button" role="menuitem" data-section="evaluations">Evaluations</button>
    </div>
    <div id="drawerBackdrop" class="drawer-backdrop" hidden></div>
    <aside id="studentDrawer" class="student-drawer" role="dialog" aria-modal="true" aria-labelledby="drawerTitle" hidden>
        <div class="drawer-head d-flex justify-content-between align-items-start gap-3">
            <div><h2 id="drawerTitle" class="section-title mb-1">Student</h2><p id="drawerMajor" class="text-muted mb-0"></p></div>
            <button id="drawerClose" type="button" class="btn btn-outline-primary btn-sm" aria-label="Close student details">Close</button>
        </div>
        <div class="drawer-content">
            <nav class="drawer-tabs" aria-label="Student detail sections">
                <button type="button" data-drawer-tab="overview" aria-selected="true">Overview</button>
                <button type="button" data-drawer-tab="tasks" aria-selected="false">Tasks</button>
                <button type="button" data-drawer-tab="hours" aria-selected="false">Training hours</button>
                <button type="button" data-drawer-tab="evaluations" aria-selected="false">Evaluations</button>
            </nav>
            <div id="drawerBody"></div>
        </div>
    </aside>
    <div id="studentDetailData" hidden><asp:Literal ID="litStudentDetails" runat="server" /></div>
    <script src="<%= ResolveUrl("~/CoordinatorMonitor/CoordinatorMonitor.js") %>?v=2"></script>
</asp:Content>
