<%@ Page Title="Company Supervisor Dashboard - UIMS" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" CodeBehind="Dashboard.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Company.Dashboard" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid py-3">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h1 class="page-title mb-1">Company Supervisor Dashboard</h1>
                <p class="text-muted mb-0">Welcome, <asp:Literal ID="litSupervisorName" runat="server" /> to the Corporate Internship Portal.</p>
            </div>
            <div>
                <span class="badge badge-submitted px-3 py-2">Company Mentor</span>
            </div>
        </div>

        <div class="row g-4 mb-4">
            <div class="col-md-4">
                <div class="card p-3 shadow-sm border-0">
                    <div class="small-label mb-1">Currently Hosted Interns</div>
                    <h3 class="card-title text-success mb-0">Active Trainees</h3>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card p-3 shadow-sm border-0">
                    <div class="small-label mb-1">Pending Student Applications</div>
                    <h3 class="card-title text-primary mb-0">Review Applications</h3>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card p-3 shadow-sm border-0">
                    <div class="small-label mb-1">Published Internship Openings</div>
                    <h3 class="card-title text-warning mb-0">Manage Opportunities</h3>
                </div>
            </div>
        </div>

        <div class="card p-4 shadow-sm">
            <h2 class="section-title mb-3">Company Mentorship Overview</h2>
            <p class="text-muted">Manage your organization's internship vacancies, assign daily tasks, track student attendance, and submit midterm & final corporate evaluations through the navigation sidebar.</p>
        </div>
    </div>
</asp:Content>
