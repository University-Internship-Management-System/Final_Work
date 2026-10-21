<%@ Page Title="Week Tasks" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" CodeBehind="WeekTasksForm.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Student.StudentTasksPage.WeekTasksForm" Async="true" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="StudentTasks.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <%--
        WEEK PAGE = the tasks of ONE week (the number comes from the address: WeekTasksForm?week=3).
        All data comes from the C# code-behind.

        HEADER      lblWeekTitle, lblWeekBadge (set .Text and .CssClass = "badge " + badgeClass), lblWeekDates,
                    hlPrev, hlNext (set .NavigateUrl and .Visible)
        NUMBERS     lblTotal, lblTodo, lblReview, lblRevision, lblEvaluated
        FILTER      ddlStatus (values: all, todo, overdue, submitted, revision, evaluated), txtSearch, btnSearch
        TASK LIST   rptTasks -> bind a List of objects with these properties:
                      TaskId (string)       WeekNumber (int)      TaskName (string)    TaskDescription (string)
                      StateText (string)    BadgeClass (string)   DueText (string)     DueCssClass (string)
                      CompanyName (string)  ButtonText (string)   CanSubmit (bool)
                    DueCssClass is "", "st-due-soon" or "st-due-late".
                    The card button raises rptTasks_ItemCommand with CommandArgument = TaskId.
        EMPTY       pnlEmpty + lblEmpty (show when the list is empty)
        DETAILS     pnlDetails (Visible = true to open the popup) with
                      lblDetailWeek, lblDetailBadge, lblDetailTitle, lblDetailDescription,
                      lblDetailCompany, lblDetailStart, lblDetailDeadline, lblDetailTools, lblDetailMax
                      pnlFeedback (+ lblFeedbackScore, lblFeedbackText) : hide it when there is no feedback
                        pnlFeedbackBox is the colored box: set its .CssClass = "st-feedback revision" when changes were requested
                      pnlHistory + rptHistory -> List of objects: Version (int), DateText (string), IsLate (bool), Description, Link
                      pnlSubmit (hide it when the student cannot submit) with lblLateNote, txtDescription, txtLink, lblFormError, btnSubmit
                      hfTaskId remembers which task is open
        MESSAGE     pnlMessage + lblMessage (green message after a successful submit)
    --%>

    <div class="st-page">

        <nav class="st-breadcrumb" aria-label="Breadcrumb">
            <a href="StudentTasksForm">My Tasks</a>
            <span>/</span>
            <asp:Label ID="lblCrumb" runat="server" Text="Week" />
        </nav>

        <div class="st-header st-week-header">
            <div>
                <h1 class="page-title">
                    <asp:Label ID="lblWeekTitle" runat="server" Text="Week" />
                    <asp:Label ID="lblWeekBadge" runat="server" CssClass="badge" />
                </h1>
                <p class="text-muted mb-0"><asp:Label ID="lblWeekDates" runat="server" /></p>
            </div>
            <div class="st-week-nav">
                <asp:HyperLink ID="hlPrev" runat="server" CssClass="btn btn-outline-primary btn-sm" Text="Previous week" />
                <asp:HyperLink ID="hlNext" runat="server" CssClass="btn btn-outline-primary btn-sm" Text="Next week" />
            </div>
        </div>

        <div class="st-summary">
            <div class="st-stat" style="--stat-color: var(--uims-primary)">
                <div class="st-stat-number"><asp:Label ID="lblTotal" runat="server" Text="0" /></div>
                <div class="st-stat-label">Tasks this week</div>
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

        <%-- Filter + search (DefaultButton makes Enter in the search box press Search) --%>
        <asp:Panel ID="pnlToolbar" runat="server" CssClass="st-toolbar" DefaultButton="btnSearch">
            <asp:DropDownList ID="ddlStatus" runat="server" CssClass="form-select st-select" AutoPostBack="true" OnSelectedIndexChanged="ddlStatus_SelectedIndexChanged">
                <asp:ListItem Value="all" Text="All tasks" Selected="True" />
                <asp:ListItem Value="todo" Text="To do" />
                <asp:ListItem Value="overdue" Text="Overdue" />
                <asp:ListItem Value="submitted" Text="Submitted" />
                <asp:ListItem Value="revision" Text="Needs revision" />
                <asp:ListItem Value="evaluated" Text="Evaluated" />
            </asp:DropDownList>
            <div class="st-search-box">
                <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control" placeholder="Search tasks" />
                <asp:Button ID="btnSearch" runat="server" Text="Search" CssClass="btn btn-outline-primary" OnClick="btnSearch_Click" />
            </div>
        </asp:Panel>

        <%-- Task cards --%>
        <div class="st-grid">
            <asp:Repeater ID="rptTasks" runat="server" OnItemCommand="rptTasks_ItemCommand">
                <ItemTemplate>
                    <article class="st-card">
                        <div class="st-card-top">
                            <span class="st-week">Week <%# Eval("WeekNumber") %></span>
                            <span class='badge <%# Eval("BadgeClass") %>'><%# Eval("StateText") %></span>
                        </div>
                        <h3 class="st-card-title"><%# Eval("TaskName") %></h3>
                        <p class="st-card-desc"><%# Eval("TaskDescription") %></p>
                        <div class="st-card-meta">
                            <span class='<%# Eval("DueCssClass") %>'><%# Eval("DueText") %></span>
                            <span><%# Eval("CompanyName") %></span>
                        </div>
                        <div class="st-card-actions">
                            <asp:LinkButton runat="server" CommandName="open" CommandArgument='<%# Eval("TaskId") %>'
                                CssClass='<%# (bool)Eval("CanSubmit") ? "btn btn-sm btn-primary" : "btn btn-sm btn-outline-primary" %>'
                                Text='<%# Eval("ButtonText") %>' />
                        </div>
                    </article>
                </ItemTemplate>
            </asp:Repeater>
        </div>

        <asp:Panel ID="pnlEmpty" runat="server" CssClass="st-empty" Visible="false">
            <p class="st-empty-title">No tasks to show</p>
            <p class="text-muted mb-0"><asp:Label ID="lblEmpty" runat="server" /></p>
        </asp:Panel>
    </div>

    <%-- Task details + submit form: a popup that shows when pnlDetails.Visible = true --%>
    <asp:Panel ID="pnlDetails" runat="server" ClientIDMode="Static" CssClass="st-modal" Visible="false">
        <div class="st-modal-backdrop"></div>
        <div class="st-modal-dialog" role="dialog" aria-modal="true">
            <asp:LinkButton ID="btnClose" runat="server" ClientIDMode="Static" CssClass="st-modal-close" CausesValidation="false" OnClick="btnClose_Click" aria-label="Close">&times;</asp:LinkButton>

            <asp:Label ID="lblDetailWeek" runat="server" CssClass="st-week" />
            <asp:Label ID="lblDetailBadge" runat="server" CssClass="badge" />
            <h2><asp:Label ID="lblDetailTitle" runat="server" /></h2>
            <p class="mb-0"><asp:Label ID="lblDetailDescription" runat="server" /></p>

            <div class="st-meta-grid">
                <div><div class="st-meta-label">Company</div><div class="st-meta-value"><asp:Label ID="lblDetailCompany" runat="server" /></div></div>
                <div><div class="st-meta-label">Start date</div><div class="st-meta-value"><asp:Label ID="lblDetailStart" runat="server" /></div></div>
                <div><div class="st-meta-label">Deadline</div><div class="st-meta-value"><asp:Label ID="lblDetailDeadline" runat="server" /></div></div>
                <div><div class="st-meta-label">Tools</div><div class="st-meta-value"><asp:Label ID="lblDetailTools" runat="server" /></div></div>
                <div><div class="st-meta-label">Max score</div><div class="st-meta-value"><asp:Label ID="lblDetailMax" runat="server" /></div></div>
            </div>

            <%-- Supervisor feedback (set pnlFeedbackBox.CssClass = "st-feedback revision" when changes were requested) --%>
            <asp:Panel ID="pnlFeedback" runat="server" Visible="false">
                <div class="st-section-title">Supervisor feedback</div>
                <asp:Panel ID="pnlFeedbackBox" runat="server" CssClass="st-feedback">
                    <div class="st-score"><asp:Label ID="lblFeedbackScore" runat="server" /></div>
                    <asp:Label ID="lblFeedbackText" runat="server" />
                </asp:Panel>
            </asp:Panel>

            <%-- Every version I sent, newest first --%>
            <asp:Panel ID="pnlHistory" runat="server" Visible="false">
                <div class="st-section-title">My submissions</div>
                <ul class="st-history">
                    <asp:Repeater ID="rptHistory" runat="server">
                        <ItemTemplate>
                            <li>
                                <div class="st-history-top">
                                    <strong>Version <%# Eval("Version") %></strong>
                                    <span><%# Eval("DateText") %>
                                        <asp:Label runat="server" CssClass="st-late" Visible='<%# (bool)Eval("IsLate") %>' Text="LATE" /></span>
                                </div>
                                <%# Eval("Description") %>
                                <asp:HyperLink runat="server" Target="_blank" rel="noopener" Visible='<%# !string.IsNullOrEmpty((string)Eval("Link")) %>'
                                    NavigateUrl='<%# Eval("Link") %>' Text='<%# Eval("Link") %>' />
                            </li>
                        </ItemTemplate>
                    </asp:Repeater>
                </ul>
            </asp:Panel>

            <%-- Submit / resubmit form --%>
            <asp:Panel ID="pnlSubmit" runat="server" Visible="false" DefaultButton="btnSubmit">
                <div class="st-section-title">Submit your work</div>
                <asp:Label ID="lblLateNote" runat="server" CssClass="st-late d-block mb-2" Visible="false" Text="The deadline has passed. Your submission will be marked as late." />
                <div class="st-form">
                    <label for="txtDescription">Description *</label>
                    <%-- ValidateRequestMode=Disabled: students may type < and > (for example List<string>). Safe because we HTML-encode this text everywhere we show it. --%>
                    <asp:TextBox ID="txtDescription" runat="server" ClientIDMode="Static" CssClass="form-control" TextMode="MultiLine" Rows="4" placeholder="What did you do?" ValidateRequestMode="Disabled" />
                    <label for="txtLink">Link (optional)</label>
                    <asp:TextBox ID="txtLink" runat="server" ClientIDMode="Static" CssClass="form-control" placeholder="https://" />
                    <div class="st-error"><asp:Label ID="lblFormError" runat="server" /></div>
                    <asp:Button ID="btnSubmit" runat="server" Text="Submit" CssClass="btn btn-primary" OnClick="btnSubmit_Click" />
                </div>
            </asp:Panel>

            <asp:HiddenField ID="hfTaskId" runat="server" />
        </div>
    </asp:Panel>

    <%-- Green message after a successful submit (fades out by itself) --%>
    <asp:Panel ID="pnlMessage" runat="server" CssClass="st-flash" Visible="false">
        <asp:Label ID="lblMessage" runat="server" />
    </asp:Panel>

    <script src="<%= ResolveUrl("~/Student/StudentTasksPage/WeekTasks.js") %>"></script>
</asp:Content>
