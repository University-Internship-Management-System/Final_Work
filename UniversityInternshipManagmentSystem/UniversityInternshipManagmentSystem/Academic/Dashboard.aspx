<%@ Page Title="Academic Supervisor Dashboard - UIMS" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" Async="true" CodeBehind="Dashboard.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Academic.Dashboard" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .ad-page { color: #123e35; }
        .ad-heading { margin-bottom: 1.5rem; }
        .ad-heading h1 { color: #075c49; font-weight: 750; }
        .ad-stat { height: 100%; padding: 1.35rem; background: #fff; border: 1px solid #e0e8e4; border-left: 4px solid #15916f; border-radius: 14px; box-shadow: 0 5px 18px rgba(18, 43, 57, .04); }
        .ad-stat-label { color: #687b74; font-weight: 600; }
        .ad-stat-value { margin: .4rem 0; color: #075c49; font-size: 2rem; font-weight: 750; }
        .ad-card { padding: 1.4rem; background: #fff; border: 1px solid #e0e8e4; border-radius: 14px; box-shadow: 0 5px 18px rgba(18, 43, 57, .04); }
        .ad-table { width: 100%; border-collapse: collapse; }
        .ad-table th, .ad-table td { padding: .85rem .7rem; border-bottom: 1px solid #e7ece9; text-align: left; vertical-align: middle; }
        .ad-table th { color: #60736c; font-size: .85rem; white-space: nowrap; }
        .ad-table a { color: #08785d; font-weight: 650; text-decoration: none; }
        .ad-table a:hover { text-decoration: underline; }
        .ad-muted { color: #73817c; }
        @media (max-width: 760px) { .ad-table { min-width: 760px; } }
    </style>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid py-3 ad-page">
        <div class="ad-heading">
            <div class="small text-uppercase fw-bold text-success">Academic Supervisor</div>
            <h1 class="mb-1">Academic Dashboard</h1>
            <p class="text-muted mb-0">Welcome, <asp:Literal ID="litAcademicName" runat="server" />. Review your assigned trainees and their current training activity.</p>
        </div>

        <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="alert alert-danger" role="alert">
            <asp:Literal ID="litError" runat="server" />
        </asp:Panel>

        <div class="row g-3 mb-4">
            <div class="col-6 col-xl-3"><div class="ad-stat"><div class="ad-stat-label">Assigned students</div><div class="ad-stat-value"><asp:Literal ID="litStudentCount" runat="server" /></div><div class="small ad-muted">Students assigned to your supervisor account</div></div></div>
            <div class="col-6 col-xl-3"><div class="ad-stat"><div class="ad-stat-label">Assigned tasks</div><div class="ad-stat-value"><asp:Literal ID="litTaskCount" runat="server" /></div><div class="small ad-muted">Unique tasks assigned to your students</div></div></div>
            <div class="col-6 col-xl-3"><div class="ad-stat"><div class="ad-stat-label">Submissions awaiting review</div><div class="ad-stat-value"><asp:Literal ID="litSubmissionCount" runat="server" /></div><div class="small ad-muted">Latest task submissions marked Submitted</div></div></div>
            <div class="col-6 col-xl-3"><div class="ad-stat"><div class="ad-stat-label">Company evaluations received</div><div class="ad-stat-value"><asp:Literal ID="litEvaluationCount" runat="server" /></div><div class="small ad-muted">Evaluations sent for your assigned students</div></div></div>
        </div>

        <section class="ad-card" aria-labelledby="studentsHeading">
            <h2 id="studentsHeading" class="h4 mb-1">My trainees</h2>
            <p class="text-muted mb-3">Student and company evaluation status loaded from Firebase.</p>
            <div class="table-responsive">
                <table class="ad-table">
                    <thead><tr><th>Student</th><th>Major</th><th>Company</th><th>Company evaluation</th><th>Progress</th></tr></thead>
                    <tbody><asp:Literal ID="litStudentRows" runat="server" /></tbody>
                </table>
            </div>
        </section>
    </div>
</asp:Content>
