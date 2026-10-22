<%@ Page Language="C#" Async="true" AutoEventWireup="true" CodeBehind="CoordinatorDashbord.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Coordinator.CoordinatorDashbord" MasterPageFile="~/Shared/Dashboard.Master" %>
<asp:Content ID="PageHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Coordinator/CoordinatorDashbord/CoordinatorDashbord.css") %>?v=10" rel="stylesheet" />
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
                    <div class="col-12"><section class="card admin-card chart-card p-4 h-100" aria-labelledby="majorChartHeading">
                        <div class="chart-heading"><span class="chart-icon" aria-hidden="true"><svg><use href="#i-student" /></svg></span><div><h2 id="majorChartHeading" class="section-title mb-1">Students by Major</h2><p class="chart-subtitle mb-0">Number of students enrolled in each major</p></div></div>
                        <asp:Literal ID="litMajorChart" runat="server" />
                    </section></div>
                    <div class="col-12"><section class="card admin-card chart-card p-4 h-100" aria-labelledby="companyChartHeading">
                        <div class="chart-heading"><span class="chart-icon company" aria-hidden="true"><svg><use href="#i-building" /></svg></span><div><h2 id="companyChartHeading" class="section-title mb-1">Placed Students by Company</h2><p class="chart-subtitle mb-0">Students with a company assignment</p></div></div>
                        <div class="chart-list"><asp:Literal ID="litCompanyChart" runat="server" /></div>
                    </section></div>
                </div>
                <section class="card admin-card opportunity-section p-4 mt-4" aria-labelledby="opportunityStatsHeading">
                    <div class="chart-heading"><span class="chart-icon company" aria-hidden="true"><svg><use href="#i-briefcase" /></svg></span><div><h2 id="opportunityStatsHeading" class="section-title mb-1">Internship Opportunities</h2><p class="chart-subtitle mb-0">Live opportunity counts and the companies that posted them</p></div></div>
                    <div class="opportunity-layout">
                        <div class="opportunity-stats">
                            <div class="opportunity-stat"><strong><asp:Literal ID="litTotalOpportunities" runat="server" /></strong><span>Total opportunities</span></div>
                            <div class="opportunity-stat"><strong><asp:Literal ID="litOpenOpportunities" runat="server" /></strong><span>Open opportunities</span></div>
                            <div class="opportunity-stat"><strong><asp:Literal ID="litClosedOpportunities" runat="server" /></strong><span>Closed opportunities</span></div>
                        </div>
                        <div class="opportunity-companies"><h3>Opportunities by Company</h3><p class="chart-subtitle">The columns show each company's opportunity count; the circle shows its share.</p><asp:Literal ID="litOpportunityCompanies" runat="server" /></div>
                    </div>
                </section>
            </asp:Panel>
</asp:Content>
