<%@ Page Title="Review task" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" CodeBehind="ReviewTask.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Company.ManageTasksPage.ReviewTaskForm" Async="true" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="../../Student/StudentTasksPage/StudentTasks.css" rel="stylesheet" />
    <link href="ManageTasks.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <%--
        REVIEW PAGE (company supervisor) = ONE task (the id comes from the address: ReviewTask.aspx?taskId=...).
        A table with one line per trainee. "Review" opens a popup with the work and the score / feedback form.
        All data comes from the C# code-behind (ReviewTask.aspx.cs).
    --%>

    <div class="st-page">

        <nav class="st-breadcrumb" aria-label="Breadcrumb">
            <a href="ManageTasks.aspx">Tasks</a>
            <span>/</span>
            <asp:Label ID="lblCrumb" runat="server" Text="Task" />
        </nav>

        <div class="st-header st-week-header">
            <div>
                <h1 class="page-title uims-page-title">
                    <asp:Label ID="lblTitle" runat="server" />
                    <asp:Label ID="lblStatusBadge" runat="server" CssClass="badge" />
                </h1>
                <p class="mb-1"><asp:Label ID="lblDescription" runat="server" /></p>
                <p class="text-muted mb-0"><asp:Label ID="lblInfo" runat="server" /></p>
            </div>
        </div>

        <div class="st-summary">
            <div class="st-stat" style="--stat-color: var(--uims-primary)">
                <div class="st-stat-number"><asp:Label ID="lblAssigned" runat="server" Text="0" /></div>
                <div class="st-stat-label">Trainees</div>
            </div>
            <div class="st-stat" style="--stat-color: var(--uims-warning)">
                <div class="st-stat-number"><asp:Label ID="lblNotSent" runat="server" Text="0" /></div>
                <div class="st-stat-label">Not submitted</div>
            </div>
            <div class="st-stat" style="--stat-color: var(--uims-info)">
                <div class="st-stat-number"><asp:Label ID="lblWaiting" runat="server" Text="0" /></div>
                <div class="st-stat-label">Waiting for review</div>
            </div>
            <div class="st-stat" style="--stat-color: var(--uims-danger)">
                <div class="st-stat-number"><asp:Label ID="lblRevision" runat="server" Text="0" /></div>
                <div class="st-stat-label">Changes requested</div>
            </div>
            <div class="st-stat" style="--stat-color: var(--uims-success)">
                <div class="st-stat-number"><asp:Label ID="lblEvaluated" runat="server" Text="0" /></div>
                <div class="st-stat-label">Evaluated</div>
            </div>
        </div>

        <%-- One line per trainee --%>
        <asp:Repeater ID="rptRows" runat="server" OnItemCommand="rptRows_ItemCommand">
            <HeaderTemplate>
                <div class="card">
                    <div class="table-responsive">
                        <table class="table align-middle mb-0">
                            <thead>
                                <tr><th>Trainee</th><th>Hours</th><th>Status</th><th>Last submission</th><th></th></tr>
                            </thead>
                            <tbody>
            </HeaderTemplate>
            <ItemTemplate>
                                <tr>
                                    <td><strong><%#: StudentName(Container.DataItem) %></strong></td>
                                    <td><%# HoursOf(Container.DataItem) %></td>
                                    <td><span class='badge <%# StateBadge(Container.DataItem) %>'><%# StateText(Container.DataItem) %></span></td>
                                    <td><%# SentText(Container.DataItem) %></td>
                                    <td class="text-end">
                                        <asp:LinkButton runat="server" CommandName="open" CommandArgument='<%# SubmissionIdOf(Container.DataItem) %>'
                                            Visible='<%# HasSubmission(Container.DataItem) %>'
                                            CssClass='<%# CanReview(Container.DataItem) ? "btn btn-sm btn-primary" : "btn btn-sm btn-outline-primary" %>'
                                            Text='<%# CanReview(Container.DataItem) ? "Review" : "View" %>' />
                                    </td>
                                </tr>
            </ItemTemplate>
            <FooterTemplate>
                            </tbody>
                        </table>
                    </div>
                </div>
            </FooterTemplate>
        </asp:Repeater>

        <asp:Panel ID="pnlEmpty" runat="server" CssClass="st-empty" Visible="false">
            <p class="st-empty-title">No trainee has this task</p>
        </asp:Panel>
    </div>

    <%-- The work of one trainee + the evaluation form: a popup that shows when pnlReview.Visible = true --%>
    <asp:Panel ID="pnlReview" runat="server" ClientIDMode="Static" CssClass="st-modal" Visible="false">
        <div class="st-modal-backdrop"></div>
        <div class="st-modal-dialog" role="dialog" aria-modal="true">
            <asp:LinkButton ID="btnClose" runat="server" ClientIDMode="Static" CssClass="st-modal-close" CausesValidation="false" OnClick="btnClose_Click" aria-label="Close">&times;</asp:LinkButton>

            <asp:Label ID="lblRevBadge" runat="server" CssClass="badge" />
            <h2><asp:Label ID="lblStudent" runat="server" /></h2>

            <div class="st-meta-grid">
                <div><div class="st-meta-label">Version</div><div class="st-meta-value"><asp:Label ID="lblVersion" runat="server" /></div></div>
                <div><div class="st-meta-label">Sent on</div><div class="st-meta-value"><asp:Label ID="lblSent" runat="server" /> <asp:Label ID="lblLate" runat="server" CssClass="st-late" Visible="false" Text="LATE" /></div></div>
                <div><div class="st-meta-label">Max score</div><div class="st-meta-value"><asp:Label ID="lblMax" runat="server" /></div></div>
            </div>

            <div class="st-section-title">The work</div>
            <p class="mb-1"><asp:Label ID="lblWork" runat="server" /></p>
            <asp:HyperLink ID="hlLink" runat="server" Target="_blank" rel="noopener" Visible="false" />

            <%-- Older versions of the same trainee (newest first) --%>
            <asp:Panel ID="pnlHistory" runat="server" Visible="false">
                <div class="st-section-title">All versions</div>
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

            <%-- Already evaluated, or changes were requested: show the decision --%>
            <asp:Panel ID="pnlResult" runat="server" Visible="false">
                <div class="st-section-title">Your evaluation</div>
                <asp:Panel ID="pnlResultBox" runat="server" CssClass="st-feedback">
                    <div class="st-score"><asp:Label ID="lblResultScore" runat="server" /></div>
                    <asp:Label ID="lblResultFeedback" runat="server" />
                </asp:Panel>
            </asp:Panel>

            <%-- Waiting for the supervisor: score it, or ask for changes --%>
            <asp:Panel ID="pnlForm" runat="server" Visible="false">
                <div class="st-section-title">Your evaluation</div>
                <div class="st-form">
                    <label for="txtScore">Score (from 0 to <asp:Label ID="lblMaxHint" runat="server" />)</label>
                    <asp:TextBox ID="txtScore" runat="server" ClientIDMode="Static" CssClass="form-control" TextMode="Number" min="0" step="0.5" />
                    <label for="txtFeedback">Feedback</label>
                    <%-- ValidateRequestMode=Disabled: the text may contain < and >. Safe because we HTML-encode it everywhere we show it. --%>
                    <asp:TextBox ID="txtFeedback" runat="server" ClientIDMode="Static" CssClass="form-control" TextMode="MultiLine" Rows="4" placeholder="What was good? What must change?" ValidateRequestMode="Disabled" />
                    <div class="st-error"><asp:Label ID="lblFormError" runat="server" /></div>
                    <div class="mt-buttons">
                        <asp:Button ID="btnApprove" runat="server" Text="Save score" CssClass="btn btn-primary" OnClick="btnApprove_Click" />
                        <asp:Button ID="btnRevise" runat="server" Text="Request changes" CssClass="btn btn-outline-danger" OnClick="btnRevise_Click" />
                    </div>
                    <p class="text-muted mb-0 mt-2">"Request changes" needs feedback. The trainee can then send a new version.</p>
                </div>
            </asp:Panel>

            <asp:HiddenField ID="hfSubmissionId" runat="server" />
        </div>
    </asp:Panel>

    <%-- Green message after a success (fades out by itself) --%>
    <asp:Panel ID="pnlMessage" runat="server" CssClass="st-flash" Visible="false">
        <asp:Label ID="lblMessage" runat="server" />
    </asp:Panel>

    <script src="<%= ResolveUrl("~/Company/ManageTasks/ManageTasks.js") %>"></script>
</asp:Content>
