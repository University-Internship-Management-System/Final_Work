<%@ Page Title="My Progress" Language="C#"
    MasterPageFile="~/Shared/Dashboard.Master"
    AutoEventWireup="true"
    Async="true"
    CodeBehind="MyProgress.aspx.cs"
    Inherits="UniversityInternshipManagmentSystem.Student.MyProgress" %>

<asp:Content ID="ProgressHead"
    ContentPlaceHolderID="HeadContent"
    runat="server">

    <link href="MyProgress.css" rel="stylesheet" />

</asp:Content>

<asp:Content ID="ProgressContent"
    ContentPlaceHolderID="MainContent"
    runat="server">

    <div class="my-progress-page">

        <div class="progress-page-header">
            <h1 class="page-title">My Progress</h1>

            <p>
                <%: CoursePassed
                    ? "Your internship is complete. Celebrate your achievement and keep your certificate."
                    : "Track your internship journey and weekly assigned tasks." %>
            </p>
        </div>

        <!-- Keep errors visible regardless of the course result. -->
        <asp:Panel ID="pnlError"
            runat="server"
            Visible="false"
            CssClass="alert alert-danger mb-4"
            role="alert">

            <asp:Literal ID="litError" runat="server" />

        </asp:Panel>

        <% if (!pnlError.Visible)
            { %>

        <section
            class="mp-journey <%: CoursePassed ? "mp-journey-passed" : "" %>"
            aria-labelledby="mp-journey-title">

            <% if (CoursePassed)
                { %>

            <!-- Approved: trophy on the right, no weeks. -->
            <div class="mp-success-header">

                <div class="mp-success-copy">
                    <p class="mp-eyebrow">
                        INTERNSHIP SUCCESSFULLY COMPLETED
                           
                    </p>

                    <h2 id="mp-journey-title">You did it. Course passed!
                    </h2>

                    <p>
                        Your result has been approved by the
                                university training coordinator.
                           
                    </p>
                </div>

                <div class="mp-trophy" aria-hidden="true">
                    <svg viewBox="0 0 100 100">

                        <path class="mp-trophy-cup"
                            d="M30 19h40v25a20 20 0 0 1-40 0V19Z" />

                        <path class="mp-trophy-line"
                            d="M30 25H18v12a17 17 0 0 0 17 17
                                       m35-29h12v12a17 17 0 0 1-17 17
                                       M50 64v15m-12 2h24m-29 7h34" />

                        <path class="mp-trophy-star"
                            d="m50 29 3.5 7.2 8 1.1-5.7 5.6
                                       1.3 7.9-7.1-3.7-7.1 3.7
                                       1.3-7.9-5.7-5.6 8-1.1Z" />

                    </svg>
                </div>

            </div>

            <% }
                else
                { %>

            <div class="mp-journey-header">

                <div>
                    <p class="mp-eyebrow">
                        YOUR TRAINING JOURNEY
                           
                    </p>

                    <h2 id="mp-journey-title">Your internship journey
                    </h2>
                </div>

                <span class="mp-state">
                    <%: CompletedTrainingWeekCount + " of 6 weeks completed" %>
                </span>

            </div>

            <div class="mp-timeline-scroll"
                tabindex="0"
                aria-label="Training weeks">

                <ol class="mp-timeline">

                    <% for (int week = 1; week <= 6; week++)
                        { %>

                    <li class="<%: GetJourneyWeekClass(week) %>"
                        aria-current="<%:
                                        !TrainingWeeksFinished &&
                                        CurrentTrainingWeek.HasValue &&
                                        CurrentTrainingWeek.Value == week
                                            ? "step"
                                            : "false" %>">

                        <span class="mp-week-node">
                            <%:
                                            IsJourneyWeekComplete(week)
                                                ? "✓"
                                                : week.ToString() %>
                        </span>

                        <strong>Week <%: week %>
                        </strong>

                        <small>
                            <%: GetJourneyWeekStatus(week) %>
                        </small>

                    </li>

                    <% } %>
                </ol>

            </div>

            <p class="mp-journey-note">
                <%: TrainingWeeksFinished
                            ? "All assigned tasks for all six weeks have been submitted. Your pass confirmation still requires approval from the university training coordinator."
                            : "A week is completed when all its assigned tasks are submitted. Your pass confirmation and certificate require university training coordinator approval." %>
            </p>

            <% } %>
        </section>

        <!-- Shown only when Certificate.IsPassAdmin is true. -->
        <% if (CoursePassed)
            { %>

        <section class="mp-certificate-card"
            aria-labelledby="mp-certificate-heading">

            <div class="mp-certificate-heading">

                <div>
                    <span class="mp-certificate-label">UNIVERSITY APPROVAL RECEIVED
                    </span>

                    <h3 id="mp-certificate-heading">Your completion certificate
                    </h3>

                    <p>
                        You have successfully passed
                                the internship course.
                           
                    </p>
                </div>

                <span class="mp-passed-badge">Passed
                </span>

            </div>

            <% if (!string.IsNullOrEmpty(
                                GetCertificateDownloadUrl()))
                { %>

            <div class="mp-certificate-file">

                <div class="mp-file-info">
                    <strong>Personalized completion certificate
                    </strong>

                    <span>Includes your approved training information
                    </span>
                </div>

                <div class="mp-certificate-actions">

                    <a class="btn btn-outline-primary"
                        href="<%: GetCertificateDownloadUrl() %>"
                        target="_blank"
                        rel="noopener">View certificate
                    </a>

                    <a class="btn btn-primary mp-download-button"
                        href="<%: GetCertificateDownloadUrl() %>?print=1"
                        target="_blank"
                        rel="noopener">

                        <svg viewBox="0 0 24 24" aria-hidden="true">
                            <path d="M12 3v12m-4-4 4 4 4-4
                         M5 16v5h14v-5" />
                        </svg>

                        Save as PDF
                    </a>

                </div>

            </div>

            <% }
                else
                { %>

            <p class="mp-certificate-waiting" role="status">
                Your course result has been approved.
                            Your certificate will be available here
                            once it has been issued.
                       
            </p>

            <% } %>
        </section>

        <% } %>

        <!-- Statistics remain visible after passing. -->
        <div class="row g-4 mb-4">

            <div class="col-lg-4 col-md-6">
                <div class="progress-stat-card">

                    <div class="progress-stat-label">
                        Training Duration
                       
                    </div>

                    <div class="progress-stat-value">
                        6
                       
                    </div>

                    <div class="progress-stat-caption">
                        Weeks
                       
                    </div>

                </div>
            </div>

            <div class="col-lg-4 col-md-6">
                <div class="progress-stat-card">

                    <div class="progress-stat-label">
                        Required Training Hours
                       
                    </div>

                    <div class="progress-stat-value">
                        90
                       
                    </div>

                    <div class="progress-stat-caption">
                        15 hours per week
                       
                    </div>

                </div>
            </div>

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

        <!-- Hide the overview and weekly cards after approval. -->
        <% if (!CoursePassed)
            { %>

        <div class="progress-info-box">

            <h2>Internship Overview</h2>

            <p>
                Your internship consists of 6 weeks,
                        with 15 required training hours each week.
                        Your company supervisor will assign tasks
                        throughout your internship period.
                   
            </p>

        </div>

        <div class="progress-section-header">

            <h2>Weekly Progress</h2>

            <span>6 Training Weeks</span>

        </div>

        <div class="row g-4">

            <asp:Repeater ID="rptWeeks" runat="server">

                <ItemTemplate>

                    <div class="col-lg-4 col-md-6">

                        <div class="progress-week-card">

                            <div class="progress-week-header">

                                <h3>Week <%# Eval("WeekNumber") %>
                                </h3>

                                <span class="progress-hours-badge">15 Hours
                                </span>

                            </div>

                            <div class="progress-task-count">

                                <strong>
                                    <%# Eval("TaskCount") %>
                                </strong>

                                <span>Assigned Tasks</span>

                            </div>

                            <div class="progress-divider"></div>

                            <div class="weekly-progress-box">

                                <div class="weekly-progress-heading">

                                    <span>Submission Progress
                                    </span>

                                    <strong>
                                        <%# Eval("ProgressPercentage") %>%
                                    </strong>

                                </div>

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

                                <p class="weekly-progress-caption">
                                    <%# Eval("SubmittedCount") %>
                                            of
                                           
                                    <%# Eval("TaskCount") %>
                                            tasks submitted
                                       
                                </p>

                            </div>

                            <div class="progress-week-description">

                                <%# Convert.ToInt32(Eval("TaskCount")) > 0
                                            ? "View the tasks assigned to you for this week."
                                            : "No tasks assigned yet by your company supervisor." %>
                            </div>

                            <a class="btn btn-outline-primary progress-view-btn"
                                href='<%# ResolveUrl(
                                            "~/Student/StudentTasksPage/WeekTasksForm.aspx?week="
                                            + Eval("WeekNumber")) %>'>View Details &rarr;

                            </a>

                        </div>

                    </div>

                </ItemTemplate>

            </asp:Repeater>

        </div>

        <% } %>

        <% } %>
    </div>

</asp:Content>

