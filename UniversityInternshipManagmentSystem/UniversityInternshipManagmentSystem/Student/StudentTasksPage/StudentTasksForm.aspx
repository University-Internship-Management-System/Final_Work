<%@ Page Title="My Tasks" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" CodeBehind="StudentTasksForm.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Student.StudentTasksPage.StudentTasksForm" Async="true" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <%-- Same folder as this page, so a plain relative path works --%>
    <link href="StudentTasks.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <%--
        MY TASKS = the 6 training weeks. All data comes from the C# code-behind.

        Controls you fill from C#:
          lblTotal, lblTodo, lblReview, lblRevision, lblEvaluated   -> the 5 number cards (set .Text)
          rptWeeks  -> bind a List of objects that have these properties:
              WeekNumber (int)      DatesText (string)     StatusText (string)    BadgeClass (string)
              TaskCount (int)       PercentDone (int)      FootText (string)      IsCurrent (bool)
              ToDoCount (int)       OverdueCount (int)     ReviseCount (int)      InReviewCount (int)
          BadgeClass is one of: badge-approved, badge-pending, badge-rejected, badge-submitted, st-badge-closed
    --%>

    <div class="st-page">

        <div class="st-header">
            <h1 class="page-title">My Tasks</h1>
            <p class="text-muted mb-0">Your training has 6 weeks. Open a week to see its tasks and submit your work.</p>
        </div>

        <%-- Overall numbers --%>
        <div class="st-summary">
            <div class="st-stat" style="--stat-color: var(--uims-primary)">
                <div class="st-stat-number"><asp:Label ID="lblTotal" runat="server" Text="0" /></div>
                <div class="st-stat-label">Total tasks</div>
            </div>
            <div class="st-stat" style="--stat-color: var(--uims-warning)">
                <div class="st-stat-number"><asp:Label ID="lblTodo" runat="server" Text="0" /></div>
                <div class="st-stat-label">To do</div>
            </div>
            <div class="st-stat" style="--stat-color: var(--uims-info)">
                <div class="st-stat-number"><asp:Label ID="lblReview" runat="server" Text="0" /></div>
                <div class="st-stat-label">Waiting for review</div>
            </div>
            <div class="st-stat" style="--stat-color: var(--uims-danger)">
                <div class="st-stat-number"><asp:Label ID="lblRevision" runat="server" Text="0" /></div>
                <div class="st-stat-label">Needs revision</div>
            </div>
            <div class="st-stat" style="--stat-color: var(--uims-success)">
                <div class="st-stat-number"><asp:Label ID="lblEvaluated" runat="server" Text="0" /></div>
                <div class="st-stat-label">Evaluated</div>
            </div>
        </div>

        <h2 class="section-title">Training weeks</h2>

        <div class="st-weeks">
            <asp:Repeater ID="rptWeeks" runat="server">
                <ItemTemplate>
                    <a class='st-week-card <%# (bool)Eval("IsCurrent") ? "current" : "" %>' href='WeekTasksForm?week=<%# Eval("WeekNumber") %>'>
                        <div class="st-card-top">
                            <span class="st-week-num">Week <%# Eval("WeekNumber") %></span>
                            <span class='badge <%# Eval("BadgeClass") %>'><%# Eval("StatusText") %></span>
                        </div>
                        <div class="st-week-dates"><%# Eval("DatesText") %></div>
                        <div class="st-week-count"><strong><%# Eval("TaskCount") %></strong> tasks</div>
                        <div class="st-progress"><i style='width: <%# Eval("PercentDone") %>%'></i></div>
                        <div class="st-week-foot"><%# Eval("FootText") %></div>
                        <div class="st-week-chips">
                            <asp:Label runat="server" CssClass="st-mini-chip" Visible='<%# (int)Eval("ToDoCount") > 0 %>' Text='<%# Eval("ToDoCount") + " to do" %>' />
                            <asp:Label runat="server" CssClass="st-mini-chip" Visible='<%# (int)Eval("OverdueCount") > 0 %>' Text='<%# Eval("OverdueCount") + " overdue" %>' />
                            <asp:Label runat="server" CssClass="st-mini-chip" Visible='<%# (int)Eval("ReviseCount") > 0 %>' Text='<%# Eval("ReviseCount") + " to revise" %>' />
                            <asp:Label runat="server" CssClass="st-mini-chip" Visible='<%# (int)Eval("InReviewCount") > 0 %>' Text='<%# Eval("InReviewCount") + " in review" %>' />
                        </div>
                        <span class="st-week-open">Open week &rarr;</span>
                    </a>
                </ItemTemplate>
            </asp:Repeater>
        </div>
    </div>

</asp:Content>
