<%@ Page Title="Student Dashboard - UIMS" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" CodeBehind="Dashboard.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Student.Dashboard.Dashboard" %>

<asp:Content ID="HeadContent" ContentPlaceHolderID="HeadContent" runat="server">
    <!-- Student Dashboard Specific Stylesheet -->
    <link rel="stylesheet" href="<%= ResolveUrl("~/Student/Dashboard/css/dashboard.css") %>" />
</asp:Content>

<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container-fluid px-0">

        <!-- Student Profile Header Banner -->
        <div class="student-header d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3">
            <div>
                <h1 class="student-title">
                    Welcome back, <asp:Literal ID="litStudentName" runat="server" />
                </h1>
                <p class="student-subtitle">
                    <span><i class="bi bi-mortarboard me-1"></i> <asp:Literal ID="litMajor" runat="server" /></span>
                    <span class="mx-2 text-muted">&bull;</span>
                    <span><i class="bi bi-envelope me-1"></i> <asp:Literal ID="litUniEmail" runat="server" /></span>
                    <span class="mx-2 text-muted">&bull;</span>
                    <span><i class="bi bi-graph-up me-1"></i> GPA: <strong><asp:Literal ID="litGPA" runat="server" /></strong></span>
                </p>
            </div>
            <div class="d-flex align-items-center gap-2">
                <span class="badge-status badge-approved py-2 px-3">
                    <i class="bi bi-patch-check-fill"></i>
                    <span>Training Active &amp; Approved</span>
                </span>
            </div>
        </div>

        <!-- Metric KPI Cards Row -->
        <div class="row g-3 mb-4">
            <!-- Metric 1: Hours Completed -->
            <div class="col-md-6 col-xl-3">
                <div class="kpi-card">
                    <div class="kpi-label">Completed Hours</div>
                    <div class="kpi-value text-uj-green">
                        195 <span class="fs-6 text-muted fw-normal">/ 320 hrs</span>
                    </div>
                    <div class="uims-progress">
                        <div id="trainingProgressBar" class="uims-progress-bar" data-progress-width="61%"></div>
                    </div>
                    <div class="kpi-subtext mt-2 d-flex justify-content-between">
                        <span>61% Complete</span>
                        <span>125 hrs remaining</span>
                    </div>
                </div>
            </div>

            <!-- Metric 2: Weekly Diaries -->
            <div class="col-md-6 col-xl-3">
                <div class="kpi-card">
                    <div class="kpi-label">Weekly Diaries</div>
                    <div class="kpi-value text-dark">
                        6 <span class="fs-6 text-muted fw-normal">/ 10 Weeks</span>
                    </div>
                    <div class="d-flex align-items-center gap-2 mt-2">
                        <span class="badge-status badge-approved">5 Approved</span>
                        <span class="badge-status badge-pending">1 Pending</span>
                    </div>
                    <div class="kpi-subtext mt-2">Week 7 submission due Sunday</div>
                </div>
            </div>

            <!-- Metric 3: Host Company Placement -->
            <div class="col-md-6 col-xl-3">
                <div class="kpi-card">
                    <div class="kpi-label">Host Organization</div>
                    <div class="kpi-value fs-5 text-truncate" title="Umniah Innovation Lab">
                        <asp:Literal ID="litCompany" runat="server" />
                    </div>
                    <div class="kpi-subtext mt-2">
                        <i class="bi bi-person-badge me-1"></i> Mentor: Eng. Zaid Al-Nsour
                    </div>
                </div>
            </div>

            <!-- Metric 4: Academic Supervisor -->
            <div class="col-md-6 col-xl-3">
                <div class="kpi-card">
                    <div class="kpi-label">Academic Supervisor</div>
                    <div class="kpi-value fs-5 text-truncate">
                        <asp:Literal ID="litSupervisor" runat="server" />
                    </div>
                    <div class="kpi-subtext mt-2">
                        <i class="bi bi-building me-1"></i> Department of Software Engineering
                    </div>
                </div>
            </div>
        </div>

        <!-- Main Content Area: Placement Details & Weekly Tasks Table -->
        <div class="row g-4">
            <!-- Left Column: Details & Table (col-lg-8) -->
            <div class="col-lg-8">

                <!-- Placement Overview Card -->
                <div class="dashboard-card">
                    <div class="dashboard-card-title">
                        <i class="bi bi-briefcase-fill text-uj-green"></i>
                        <span>Current Internship Placement</span>
                    </div>
                    <div class="row g-3">
                        <div class="col-sm-6">
                            <div class="detail-item">
                                <div class="detail-label">Training Track / Title</div>
                                <div class="detail-value">Full-Stack Cloud & Web Engineering</div>
                            </div>
                        </div>
                        <div class="col-sm-6">
                            <div class="detail-item">
                                <div class="detail-label">Training Duration</div>
                                <div class="detail-value">July 1, 2026 &ndash; August 31, 2026 (8 Weeks)</div>
                            </div>
                        </div>
                        <div class="col-sm-6">
                            <div class="detail-item">
                                <div class="detail-label">Attendance Schedule</div>
                                <div class="detail-value">Sunday to Thursday &bull; 8 Hours / Day</div>
                            </div>
                        </div>
                        <div class="col-sm-6">
                            <div class="detail-item">
                                <div class="detail-label">Placement Status</div>
                                <div class="detail-value text-success">
                                    <i class="bi bi-shield-check me-1"></i> Verified & Approved by Coordinator
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Recent Weekly Diaries & Tasks -->
                <div class="dashboard-card">
                    <div class="d-flex flex-column flex-sm-row justify-content-between align-items-sm-center mb-3 gap-2">
                        <div class="dashboard-card-title mb-0">
                            <i class="bi bi-journal-check text-uj-green"></i>
                            <span>Weekly Training Diaries &amp; Tasks</span>
                        </div>
                        <!-- Client-side filter buttons -->
                        <div class="btn-group btn-group-sm" role="group" aria-label="Task Filter">
                            <button type="button" class="btn btn-primary task-filter-btn active" data-filter="all">All</button>
                            <button type="button" class="btn btn-outline-secondary task-filter-btn" data-filter="approved">Approved</button>
                            <button type="button" class="btn btn-outline-secondary task-filter-btn" data-filter="pending">Pending</button>
                        </div>
                    </div>

                    <div class="table-responsive">
                        <table class="uims-table">
                            <thead>
                                <tr>
                                    <th>Week</th>
                                    <th>Task Focus Area</th>
                                    <th>Hours</th>
                                    <th>Company Mentor</th>
                                    <th>Academic Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr class="task-row" data-status="pending">
                                    <td class="fw-bold">Week 6</td>
                                    <td>RESTful API Integration &amp; Automated Testing</td>
                                    <td>40 hrs</td>
                                    <td><span class="badge-status badge-approved"><i class="bi bi-check2"></i> Approved</span></td>
                                    <td><span class="badge-status badge-pending"><i class="bi bi-clock"></i> In Review</span></td>
                                </tr>
                                <tr class="task-row" data-status="approved">
                                    <td class="fw-bold">Week 5</td>
                                    <td>Database Schema Design &amp; Entity Migrations</td>
                                    <td>40 hrs</td>
                                    <td><span class="badge-status badge-approved"><i class="bi bi-check2"></i> Approved</span></td>
                                    <td><span class="badge-status badge-approved"><i class="bi bi-check-all"></i> Verified</span></td>
                                </tr>
                                <tr class="task-row" data-status="approved">
                                    <td class="fw-bold">Week 4</td>
                                    <td>Frontend Component Architecture &amp; UI Redesign</td>
                                    <td>40 hrs</td>
                                    <td><span class="badge-status badge-approved"><i class="bi bi-check2"></i> Approved</span></td>
                                    <td><span class="badge-status badge-approved"><i class="bi bi-check-all"></i> Verified</span></td>
                                </tr>
                                <tr class="task-row" data-status="approved">
                                    <td class="fw-bold">Week 3</td>
                                    <td>Docker Containerization &amp; CI/CD Pipelines</td>
                                    <td>35 hrs</td>
                                    <td><span class="badge-status badge-approved"><i class="bi bi-check2"></i> Approved</span></td>
                                    <td><span class="badge-status badge-approved"><i class="bi bi-check-all"></i> Verified</span></td>
                                </tr>
                                <tr class="task-row" data-status="approved">
                                    <td class="fw-bold">Week 2</td>
                                    <td>Authentication Middleware &amp; Role-Based Security</td>
                                    <td>40 hrs</td>
                                    <td><span class="badge-status badge-approved"><i class="bi bi-check2"></i> Approved</span></td>
                                    <td><span class="badge-status badge-approved"><i class="bi bi-check-all"></i> Verified</span></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

            </div>

            <!-- Right Column: Quick Actions & Milestones (col-lg-4) -->
            <div class="col-lg-4">

                <!-- Quick Actions Card -->
                <div class="dashboard-card">
                    <div class="dashboard-card-title">
                        <i class="bi bi-lightning-charge-fill text-uj-green"></i>
                        <span>Quick Actions</span>
                    </div>
                    <div class="d-flex flex-column gap-2">
                        <a href="#" class="action-btn action-btn-primary w-100 justify-content-center">
                            <i class="bi bi-plus-circle"></i>
                            <span>Submit Week 7 Diary</span>
                        </a>
                        <a href="#" class="action-btn action-btn-outline w-100 justify-content-center">
                            <i class="bi bi-file-earmark-arrow-down"></i>
                            <span>Download Official Template</span>
                        </a>
                        <a href="mailto:kasit.training@ju.edu.jo" class="action-btn action-btn-outline w-100 justify-content-center">
                            <i class="bi bi-chat-left-dots"></i>
                            <span>Contact Training Coordinator</span>
                        </a>
                    </div>
                </div>

                <!-- Training Milestone Checklist -->
                <div class="dashboard-card">
                    <div class="dashboard-card-title">
                        <i class="bi bi-check2-square text-uj-green"></i>
                        <span>Internship Milestones</span>
                    </div>
                    <ul class="list-unstyled mb-0 d-flex flex-column gap-3 small">
                        <li class="d-flex align-items-start gap-2">
                            <i class="bi bi-check-circle-fill text-success fs-6 mt-1"></i>
                            <div>
                                <strong class="d-block text-dark">Internship Registration &amp; Acceptance</strong>
                                <span class="text-muted">Approved by KASIT Coordinator</span>
                            </div>
                        </li>
                        <li class="d-flex align-items-start gap-2">
                            <i class="bi bi-check-circle-fill text-success fs-6 mt-1"></i>
                            <div>
                                <strong class="d-block text-dark">Midterm Company Evaluation</strong>
                                <span class="text-muted">Rated Excellent (95/100)</span>
                            </div>
                        </li>
                        <li class="d-flex align-items-start gap-2">
                            <i class="bi bi-arrow-right-circle-fill text-warning fs-6 mt-1"></i>
                            <div>
                                <strong class="d-block text-dark">Complete 320 Training Hours</strong>
                                <span class="text-muted">Currently at 195 hrs (61%)</span>
                            </div>
                        </li>
                        <li class="d-flex align-items-start gap-2">
                            <i class="bi bi-circle text-muted fs-6 mt-1"></i>
                            <div>
                                <strong class="d-block text-muted">Final Training Report &amp; Portfolio</strong>
                                <span class="text-muted">Due at week 8 completion</span>
                            </div>
                        </li>
                        <li class="d-flex align-items-start gap-2">
                            <i class="bi bi-circle text-muted fs-6 mt-1"></i>
                            <div>
                                <strong class="d-block text-muted">Final Presentation &amp; Grade</strong>
                                <span class="text-muted">Faculty committee review</span>
                            </div>
                        </li>
                    </ul>
                </div>

            </div>
        </div>

    </div>

    <!-- Student Dashboard Client Script -->
    <script src="<%= ResolveUrl("~/Student/Dashboard/javascript/dashboard.js") %>"></script>
</asp:Content>
