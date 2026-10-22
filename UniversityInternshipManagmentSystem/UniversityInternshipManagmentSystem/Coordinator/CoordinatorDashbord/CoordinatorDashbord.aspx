<%@ Page Language="C#" Async="true" AutoEventWireup="true" CodeBehind="CoordinatorDashbord.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Coordinator.CoordinatorDashbord" MasterPageFile="~/Shared/Dashboard.Master" %>
<asp:Content ID="PageHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="CoordinatorDashbord.css" rel="stylesheet" />
</asp:Content>
<asp:Content ID="PageMain" ContentPlaceHolderID="MainContent" runat="server">
    <svg aria-hidden="true" style="position:absolute;width:0;height:0;overflow:hidden" xmlns="http://www.w3.org/2000/svg">
        <symbol id="i-student" viewBox="0 0 24 24"><path d="M2 9 12 4l10 5-10 5L2 9Z"/><path d="M6 11v5c3.5 3 8.5 3 12 0v-5M22 9v7"/></symbol>
        <symbol id="i-briefcase" viewBox="0 0 24 24"><rect x="3" y="7" width="18" height="14" rx="2"/><path d="M8 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M3 13c5 3 13 3 18 0M12 13v3"/></symbol>
        <symbol id="i-building" viewBox="0 0 24 24"><rect x="5" y="2" width="14" height="20" rx="1"/><path d="M9 6h1m4 0h1M9 10h1m4 0h1M9 14h1m4 0h1M10 22v-4h4v4"/></symbol>
        <symbol id="i-user" viewBox="0 0 24 24"><circle cx="12" cy="7" r="4"/><path d="M4 21v-2a8 8 0 0 1 16 0v2H4Z"/></symbol>
        <symbol id="i-check" viewBox="0 0 24 24"><rect x="4" y="4" width="16" height="16" rx="4"/><path d="m8 12 3 3 5-6"/></symbol>
    </svg>
                <asp:Panel ID="pnlDashboard" runat="server">
                <div class="hero-card">
                    <div><span class="hero-kicker">FIELD TRAINING OFFICE</span><h1>Coordinator Dashboard</h1><p>The University of Jordan - Internship Management System</p></div>
                </div>
                <asp:Label ID="lblDataError" runat="server" CssClass="alert alert-warning d-block" Visible="false" />
                <div class="row g-3">
                    <div class="col-sm-6 col-xl"><div class="card admin-card p-3 h-100 d-flex flex-row align-items-center justify-content-between"><div><div class="admin-stat"><asp:Literal ID="litStudents" runat="server" /></div><div class="small-label">Students</div></div><span class="stat-icon blue" aria-hidden="true"><svg><use href="#i-student" /></svg></span></div></div>
                    <div class="col-sm-6 col-xl"><div class="card admin-card p-3 h-100 d-flex flex-row align-items-center justify-content-between"><div><div class="admin-stat"><asp:Literal ID="litAssigned" runat="server" /></div><div class="small-label">Placed students</div></div><span class="stat-icon" aria-hidden="true"><svg><use href="#i-briefcase" /></svg></span></div></div>
                    <div class="col-sm-6 col-xl"><div class="card admin-card p-3 h-100 d-flex flex-row align-items-center justify-content-between"><div><div class="admin-stat"><asp:Literal ID="litCompanies" runat="server" /></div><div class="small-label">Companies</div></div><span class="stat-icon cyan" aria-hidden="true"><svg><use href="#i-building" /></svg></span></div></div>
                    <div class="col-sm-6 col-xl"><div class="card admin-card p-3 h-100 d-flex flex-row align-items-center justify-content-between"><div><div class="admin-stat"><asp:Literal ID="litAcademic" runat="server" /></div><div class="small-label">Academic supervisors</div></div><span class="stat-icon gold" aria-hidden="true"><svg><use href="#i-user" /></svg></span></div></div>
                    <div class="col-sm-6 col-xl"><div class="card admin-card p-3 h-100 d-flex flex-row align-items-center justify-content-between"><div><div class="admin-stat"><asp:Literal ID="litEvaluations" runat="server" /></div><div class="small-label">Evaluated submissions</div></div><span class="stat-icon gold" aria-hidden="true"><svg><use href="#i-check" /></svg></span></div></div>
                </div>
                <div class="row g-4 mt-2">
                    <div class="col-xl-6"><section class="card admin-card p-4 h-100"><h2 class="section-title mb-3">Account management and allocation</h2>
                        <a class="feature-row" runat="server" href="~/Coordinator/ManageStudents/ManageStudents.aspx"><strong><svg class="feature-icon"><use href="#i-student" /></svg> Manage students</strong><small>Review student profiles and placement information</small></a>
                        <a class="feature-row" runat="server" href="~/Coordinator/ManageCompanySupervisors/ManageCompanySupervisors.aspx"><strong><svg class="feature-icon"><use href="#i-building" /></svg> Manage companies</strong><small>View company supervisors and organizations</small></a>
                        <a class="feature-row" runat="server" href="~/Coordinator/ManageAcademicSupervisors/ManageAcademicSupervisors.aspx"><strong><svg class="feature-icon"><use href="#i-user" /></svg> Academic supervisors</strong><small>Review supervisor profiles and majors</small></a>
                    </section></div>
                    <div class="col-xl-6"><section class="card admin-card p-4 h-100"><h2 class="section-title mb-3">Monitoring and completion</h2>
                        <a class="feature-row" runat="server" href="~/Coordinator/CoordinatorMonitor/CoordinatorMonitor.aspx"><strong><svg class="feature-icon"><use href="#i-briefcase" /></svg> Placement monitoring</strong><small>Students, companies, tasks, hours and progress</small></a>
                        <a class="feature-row" runat="server" href="~/Coordinator/CoordinatorMonitor/CoordinatorMonitor.aspx"><strong><svg class="feature-icon"><use href="#i-check" /></svg> Task evaluations</strong><small>Review evaluated student submissions</small></a>
                        <div class="feature-row"><strong><svg class="feature-icon"><use href="#i-check" /></svg> Final completion review</strong><small>Available when final review records are connected</small></div>
                    </section></div>
                </div>
                <div class="row g-4 mt-1">
                    <div class="col-xl-6"><section class="card admin-card preview-card p-4 h-100" aria-labelledby="studentsPreviewHeading">
                        <div class="d-flex justify-content-between align-items-center mb-3"><h2 id="studentsPreviewHeading" class="section-title mb-0">Students</h2><a runat="server" href="~/Coordinator/CoordinatorMonitor/CoordinatorMonitor.aspx" class="btn btn-outline-primary btn-sm">View all</a></div>
                        <div class="table-responsive"><table class="table preview-table align-middle mb-0"><thead><tr><th>Name</th><th>Major</th><th>Placement</th></tr></thead><tbody><asp:Literal ID="litStudentPreview" runat="server" /></tbody></table></div>
                    </section></div>
                    <div class="col-xl-6"><section class="card admin-card preview-card p-4 h-100" aria-labelledby="evaluationsPreviewHeading">
                        <h2 id="evaluationsPreviewHeading" class="section-title mb-3">Task evaluations</h2>
                        <div class="table-responsive"><table class="table preview-table align-middle mb-0"><thead><tr><th>Student</th><th>Task</th><th>Score</th></tr></thead><tbody><asp:Literal ID="litEvaluationPreview" runat="server" /></tbody></table></div>
                    </section></div>
                    <div class="col-xl-6"><section class="card admin-card preview-card p-4 h-100" aria-labelledby="companiesPreviewHeading">
                        <h2 id="companiesPreviewHeading" class="section-title mb-3">Companies</h2>
                        <div class="table-responsive"><table class="table preview-table align-middle mb-0"><thead><tr><th>Company</th><th>Supervisor</th><th>Location</th></tr></thead><tbody><asp:Literal ID="litCompanyPreview" runat="server" /></tbody></table></div>
                    </section></div>
                    <div class="col-xl-6"><section class="card admin-card preview-card p-4 h-100" aria-labelledby="opportunitiesPreviewHeading">
                        <h2 id="opportunitiesPreviewHeading" class="section-title mb-3">Opportunities</h2>
                        <div class="table-responsive"><table class="table preview-table align-middle mb-0"><thead><tr><th>Opportunity</th><th>Company</th><th>Status</th></tr></thead><tbody><asp:Literal ID="litOpportunityPreview" runat="server" /></tbody></table></div>
                    </section></div>
                </div>
            </asp:Panel>
</asp:Content>
