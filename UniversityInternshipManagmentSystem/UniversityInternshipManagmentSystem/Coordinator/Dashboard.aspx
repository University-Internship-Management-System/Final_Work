<%@ Page Title="Training Coordinator Dashboard - UIMS" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" CodeBehind="Dashboard.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Coordinator.Dashboard" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid py-3">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h1 class="page-title mb-1">Field Training Coordinator Dashboard</h1>
                <p class="text-muted mb-0">Welcome, <asp:Literal ID="litCoordinatorName" runat="server" /> to the Faculty Administration & Coordination Portal.</p>
            </div>
            <div>
                <span class="badge badge-rejected px-3 py-2">Head Coordinator</span>
            </div>
        </div>

        <div class="row g-4 mb-4">
            <div class="col-md-3">
                <div class="card p-3 shadow-sm border-0">
                    <div class="small-label mb-1">Total Registered Students</div>
                    <h3 class="card-title text-success mb-0">Student Directory</h3>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card p-3 shadow-sm border-0">
                    <div class="small-label mb-1">Approved Partner Companies</div>
                    <h3 class="card-title text-primary mb-0">Company Directory</h3>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card p-3 shadow-sm border-0">
                    <div class="small-label mb-1">Faculty Academic Supervisors</div>
                    <h3 class="card-title text-info mb-0">Supervisor Allocations</h3>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card p-3 shadow-sm border-0">
                    <div class="small-label mb-1">Internship Progress & Hours</div>
                    <h3 class="card-title text-warning mb-0">Live Monitoring</h3>
                </div>
            </div>
        </div>

        <div class="card p-4 shadow-sm">
            <h2 class="section-title mb-3">System Administration & Coordination Overview</h2>
            <p class="text-muted">As the Training Coordinator, you have administrative oversight to approve training placements, assign faculty supervisors to students, verify completed credit hours, and conduct final graduation clearance reviews.</p>
        </div>
    </div>
</asp:Content>
