
<%@ Page Title="Company Dashboard"
    Language="C#"
    MasterPageFile="~/Shared/Dashboard.Master"
    AutoEventWireup="true"
    Async="true"
    CodeBehind="Dashboard.aspx.cs"

    Inherits="UniversityInternshipManagmentSystem.Company.Dashboard" %>

<asp:Content ID="CompanyHead"
    ContentPlaceHolderID="HeadContent"
    runat="server">

    <link href="Dashboard.css" rel="stylesheet" />

</asp:Content>

<asp:Content ID="CompanyContent"
    ContentPlaceHolderID="MainContent"
    runat="server">

    <div class="company-dashboard">

        <!-- Header -->
        <div class="cd-header">
            <div>
                <span class="cd-eyebrow">
                    COMPANY SUPERVISOR
                </span>

                <h1 class="uims-page-title">Company Dashboard</h1>

                <p>
                    Monitor your trainees, assigned tasks
                    and recent submissions.
                </p>
            </div>
        </div>

        <!-- Error -->
        <asp:Panel ID="pnlError" runat="server"
            Visible="false" CssClass="alert alert-danger">

            <asp:Literal ID="litError" runat="server" />

        </asp:Panel>

        <!-- Statistics -->
        <div class="row g-4 mb-4">

            <div class="col-lg-3 col-md-6">
                <div class="cd-stat-card">
                    <div class="cd-stat-label">
                        Assigned Students
                    </div>

                    <div class="cd-stat-value">
                        <asp:Literal ID="litStudents"
                            runat="server" Text="0" />
                    </div>

                    <div class="cd-stat-footer">
                        Students training at your company
                    </div>
                </div>
            </div>

            <div class="col-lg-3 col-md-6">
                <div class="cd-stat-card">
                    <div class="cd-stat-label">
                        Assigned Tasks
                    </div>

                    <div class="cd-stat-value">
                        <asp:Literal ID="litTasks"
                            runat="server" Text="0" />
                    </div>

                    <div class="cd-stat-footer">
                        Tasks created for your trainees
                    </div>
                </div>
            </div>

            <div class="col-lg-3 col-md-6">
                <div class="cd-stat-card">
                    <div class="cd-stat-label">
                        Waiting for Review
                    </div>

                    <div class="cd-stat-value">
                        <asp:Literal ID="litPending"
                            runat="server" Text="0" />
                    </div>

                    <div class="cd-stat-footer">
                        Submitted work awaiting review
                    </div>
                </div>
            </div>

            <div class="col-lg-3 col-md-6">
                <div class="cd-stat-card">
                    <div class="cd-stat-label">
                        Evaluated
                    </div>

                    <div class="cd-stat-value">
                        <asp:Literal ID="litEvaluated"
                            runat="server" Text="0" />
                    </div>

                    <div class="cd-stat-footer">
                        Reviewed task submissions
                    </div>
                </div>
            </div>

        </div>

        <div class="row g-4">

            <!-- Students -->
            <div class="col-lg-7">
                <div class="cd-panel">

                    <div class="cd-panel-heading">
                        <div>
                            <h2>My Trainees</h2>
                            <p>Students assigned to your company</p>
                        </div>
                    </div>

                    <asp:Repeater ID="rptStudents"
                        runat="server">

                        <HeaderTemplate>
                            <div class="cd-student-list">
                        </HeaderTemplate>

                        <ItemTemplate>
                            <div class="cd-student-item">

                                <div class="cd-avatar">
                                    <%#: Eval("Initial") %>
                                </div>

                                <div class="cd-student-details">

                                    <strong>
                                        <%#: Eval("Name") %>
                                    </strong>

                                    <span>
                                        <%#: Eval("Major") %>
                                    </span>

                                    <small>
                                        <%#: Eval("Email") %>
                                    </small>

                                </div>

                                <div class="cd-student-task-count">
                                    <%# Eval("TaskCount") %> tasks
                                </div>

                            </div>
                        </ItemTemplate>

                        <FooterTemplate>
                            </div>
                        </FooterTemplate>

                    </asp:Repeater>

                    <asp:Panel ID="pnlNoStudents"
                        runat="server" Visible="false"
                        CssClass="cd-empty">

                        No students are assigned to your
                        company yet.

                    </asp:Panel>

                </div>
            </div>

            <!-- Submissions Summary -->
            <div class="col-lg-5">
                <div class="cd-panel">

                    <div class="cd-panel-heading">
                        <div>
                            <h2>Submissions Overview</h2>
                            <p>Latest submission status</p>
                        </div>
                    </div>

                    <div class="cd-status-row">
                        <span>
                            <i class="cd-status-dot cd-blue"></i>
                            Submitted
                        </span>

                        <strong>
                            <asp:Literal ID="litSubmitted"
                                runat="server" Text="0" />
                        </strong>
                    </div>

                    <div class="cd-status-row">
                        <span>
                            <i class="cd-status-dot cd-orange"></i>
                            Revision Requested
                        </span>

                        <strong>
                            <asp:Literal ID="litRevision"
                                runat="server" Text="0" />
                        </strong>
                    </div>

                    <div class="cd-status-row">
                        <span>
                            <i class="cd-status-dot cd-green"></i>
                            Evaluated
                        </span>

                        <strong>
                            <asp:Literal ID="litEvaluatedSummary"
                                runat="server" Text="0" />
                        </strong>
                    </div>

                </div>
            </div>

        </div>

        <!-- Recent Submissions -->
        <div class="cd-panel cd-recent-panel">

            <div class="cd-panel-heading">
                <div>
                    <h2>Recent Submissions</h2>
                    <p>Latest work submitted by your trainees</p>
                </div>
            </div>

            <div class="table-responsive">
                <table class="table cd-table">

                    <thead>
                        <tr>
                            <th>Student</th>
                            <th>Task</th>
                            <th>Submitted At</th>
                            <th>Status</th>
                            <th>Score</th>
                        </tr>
                    </thead>

                    <tbody>
                        <asp:Repeater ID="rptSubmissions"
                            runat="server">

                            <ItemTemplate>
                                <tr>
                                    <td><%#: Eval("StudentName") %></td>
                                    <td><%#: Eval("TaskName") %></td>
                                    <td><%#: Eval("SubmittedDate") %></td>
                                    <td>
                                        <span class='cd-status-badge <%# Eval("StatusClass") %>'>
                                            <%#: Eval("Status") %>
                                        </span>
                                    </td>
                                    <td><%#: Eval("ScoreText") %></td>
                                </tr>
                            </ItemTemplate>

                        </asp:Repeater>
                    </tbody>

                </table>
            </div>

            <asp:Panel ID="pnlNoSubmissions"
                runat="server" Visible="false"
                CssClass="cd-empty">

                No task submissions yet.

            </asp:Panel>

        </div>

    </div>

</asp:Content>
