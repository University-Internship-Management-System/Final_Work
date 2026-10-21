<%@ Page Title="Academic Supervisor Dashboard - UIMS" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" CodeBehind="Dashboard.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Academic.Dashboard" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid py-3">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h1 class="page-title mb-1">Academic Supervisor Dashboard</h1>
                <p class="text-muted mb-0">Welcome, Dr. <asp:Literal ID="litAcademicName" runat="server" /> to the Academic Supervision Portal.</p>
            </div>
            <div>
                <span class="badge badge-approved px-3 py-2">Faculty Supervisor</span>
            </div>
        </div>

        <div class="row g-4 mb-4">
            <div class="col-md-4">
                <div class="card p-3 shadow-sm border-0">
                    <div class="small-label mb-1">Supervised Students</div>
                    <h3 class="card-title text-success mb-0">Active Trainees</h3>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card p-3 shadow-sm border-0">
                    <div class="small-label mb-1">Pending Progress Reports</div>
                    <h3 class="card-title text-warning mb-0">Review Reports</h3>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card p-3 shadow-sm border-0">
                    <div class="small-label mb-1">Final Evaluations</div>
                    <h3 class="card-title text-primary mb-0">Grading & Assessment</h3>
                </div>
            </div>
        </div>

        <div class="card p-4 shadow-sm">
            <h2 class="section-title mb-3">Academic Supervision Overview</h2>
            <p class="text-muted">You can monitor weekly student diaries, review corporate evaluations, conduct faculty visits, and submit final internship grades using the sidebar navigation.</p>
        </div>
    </div>
</asp:Content>
