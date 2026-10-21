
<%@ Page Title="My Progress" Language="C#"
    MasterPageFile="~/Shared/Dashboard.Master"
    AutoEventWireup="true"
    Async="true"
    CodeBehind="MyProgress.aspx.cs"
    Inherits="UniversityInternshipManagmentSystem.Student.MyProgress" %>

<asp:Content ID="ProgressHead"
    ContentPlaceHolderID="HeadContent"
    runat="server">

    <link runat="server"
          href="MyProgress.css"
          rel="stylesheet" />

</asp:Content>

<asp:Content ID="ProgressContent"
    ContentPlaceHolderID="MainContent"
    runat="server">

    <div class="my-progress-page">

        <!-- Page Header -->
        <div class="progress-page-header">
            <h1>My Progress</h1>
            <p>
                Track your internship journey and weekly assigned tasks.
            </p>
        </div>

        <!-- Statistics -->
        <div class="row g-4 mb-4">

            <!-- Training Duration -->
            <div class="col-lg-4 col-md-6">
                <div class="progress-stat-card">
                    <div class="progress-stat-label">
                        Training Duration
                    </div>

                    <div class="progress-stat-value">6</div>

                    <div class="progress-stat-caption">
                        Weeks
                    </div>
                </div>
            </div>

            <!-- Required Hours -->
            <div class="col-lg-4 col-md-6">
                <div class="progress-stat-card">
                    <div class="progress-stat-label">
                        Required Training Hours
                    </div>

                    <div class="progress-stat-value">90</div>

                    <div class="progress-stat-caption">
                        15 hours per week
                    </div>
                </div>
            </div>

            <!-- Assigned Tasks -->
            <div class="col-lg-4 col-md-6">
                <div class="progress-stat-card">
                    <div class="progress-stat-label">
                        Assigned Tasks
                    </div>

                    <div class="progress-stat-value">
                        <asp:Literal ID="litTotalTasks"
                                     runat="server"
                                     Text="0" />
                    </div>

                    <div class="progress-stat-caption">
                        Tasks assigned by your supervisor
                    </div>
                </div>
            </div>

        </div>

        <!-- Internship Overview -->
        <div class="progress-info-box">
            <h2>Internship Overview</h2>
            <p>
                Your internship consists of 6 weeks, with 15 required
                training hours each week. Your company supervisor
                will assign tasks throughout your internship period.
            </p>
        </div>

        <!-- Error Message -->
        <asp:Panel ID="pnlError"
                   runat="server"
                   Visible="false"
                   CssClass="alert alert-danger mb-4">

            <asp:Literal ID="litError" runat="server" />

        </asp:Panel>

        <!-- Weekly Progress Header -->
        <div class="progress-section-header">
            <h2>Weekly Progress</h2>
            <span>6 Training Weeks</span>
        </div>

        <!-- Weekly Cards -->
        <div class="row g-4">

            <asp:Repeater ID="rptWeeks" runat="server">

                <ItemTemplate>

                    <div class="col-lg-4 col-md-6">

                        <div class="progress-week-card">

                            <!-- Week Header -->
                            <div class="progress-week-header">

                                <h3>
                                    Week <%# Eval("WeekNumber") %>
                                </h3>

                                <span class="progress-hours-badge">
                                    15 Hours
                                </span>

                            </div>

                            <!-- Assigned Tasks -->
                            <div class="progress-task-count">

                                <strong>
                                    <%# Eval("TaskCount") %>
                                </strong>

                                <span>Assigned Tasks</span>

                            </div>

                            <div class="progress-divider"></div>

                            <!-- Weekly Submission Progress -->
                            <div class="weekly-progress-box">

                                <div class="weekly-progress-heading">

                                    <span>Submission Progress</span>

                                    <strong>
                                        <%# Eval("ProgressPercentage") %>%
                                    </strong>

                                </div>

                                <!-- Progress Bar -->
                                <div class="weekly-progress-track"
                                     role="progressbar"
                                     aria-label="Weekly submission progress"
                                     aria-valuemin="0"
                                     aria-valuemax="100"
                                     aria-valuenow='<%# Eval("ProgressPercentage") %>'>

                                    <div class="weekly-progress-fill"
                                         style='width: <%# Eval("ProgressPercentage") %>%;'>
                                    </div>

                                </div>

                                <!-- Submitted Count -->
                                <p class="weekly-progress-caption">

                                    <%# Eval("SubmittedCount") %>
                                    of
                                    <%# Eval("TaskCount") %>
                                    tasks submitted

                                </p>

                            </div>

                            <!-- Week Description -->
                            <div class="progress-week-description">

                                <%# Convert.ToInt32(Eval("TaskCount")) > 0
                                    ? "View the tasks assigned to you for this week."
                                    : "No tasks assigned yet by your company supervisor." %>

                            </div>

                            <!-- View Details -->
                            <a class="btn btn-outline-primary progress-view-btn"
                               href='<%# ResolveUrl("~/Student/Tasks.aspx?week=" + Eval("WeekNumber")) %>'>

                                View Details &rarr;

                            </a>

                        </div>

                    </div>

                </ItemTemplate>

            </asp:Repeater>

        </div>

    </div>

</asp:Content>