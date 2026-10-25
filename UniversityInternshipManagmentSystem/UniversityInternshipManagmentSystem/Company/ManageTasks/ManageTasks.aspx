<%@ Page Title="Tasks" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" CodeBehind="ManageTasks.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Company.ManageTasksPage.ManageTasksForm" Async="true" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <%-- the task cards and the popup use the same styles as the student My Tasks page --%>
    <link href="../../Student/StudentTasksPage/StudentTasks.css" rel="stylesheet" />
    <link href="ManageTasks.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <%--
        TASKS PAGE (company supervisor) = all the tasks my company created, a button to create a new one,
        and a button on every task to review the work my trainees sent.
        All data comes from the C# code-behind (ManageTasks.aspx.cs).
    --%>

    <div class="st-page">

        <div class="st-header">
            <div>
                <h1 class="page-title uims-page-title">Tasks</h1>
                <p class="text-muted mb-0">Create tasks for your trainees and review their work.</p>
            </div>
            <asp:LinkButton ID="btnNew" runat="server" CssClass="btn btn-primary" CausesValidation="false" OnClick="btnNew_Click">+ New task</asp:LinkButton>
        </div>

        <div class="st-summary">
            <div class="st-stat" style="--stat-color: var(--uims-primary)">
                <div class="st-stat-number"><asp:Label ID="lblTotal" runat="server" Text="0" /></div>
                <div class="st-stat-label">Tasks</div>
            </div>
            <div class="st-stat" style="--stat-color: var(--uims-info)">
                <div class="st-stat-number"><asp:Label ID="lblOpen" runat="server" Text="0" /></div>
                <div class="st-stat-label">Open</div>
            </div>
            <div class="st-stat" style="--stat-color: var(--uims-warning)">
                <div class="st-stat-number"><asp:Label ID="lblWaiting" runat="server" Text="0" /></div>
                <div class="st-stat-label">Waiting for review</div>
            </div>
        </div>

        <%-- Hours used in each week (the busiest trainee). One trainee can have at most 15 hours of tasks in a week. --%>
        <div class="mt-hours">
            <span class="mt-hours-title">Hours per week</span>
            <asp:Literal ID="litWeekHours" runat="server" />
        </div>

        <div class="st-toolbar">
            <asp:DropDownList ID="ddlWeekFilter" runat="server" CssClass="form-select st-select" AutoPostBack="true" OnSelectedIndexChanged="ddlWeekFilter_SelectedIndexChanged">
                <asp:ListItem Value="0" Text="All weeks" Selected="True" />
                <asp:ListItem Value="1" Text="Week 1" />
                <asp:ListItem Value="2" Text="Week 2" />
                <asp:ListItem Value="3" Text="Week 3" />
                <asp:ListItem Value="4" Text="Week 4" />
                <asp:ListItem Value="5" Text="Week 5" />
                <asp:ListItem Value="6" Text="Week 6" />
            </asp:DropDownList>
        </div>

        <%-- Task cards --%>
        <div class="st-grid">
            <asp:Repeater ID="rptTasks" runat="server" OnItemCommand="rptTasks_ItemCommand">
                <ItemTemplate>
                    <article class="st-card">
                        <div class="st-card-top">
                            <span class="st-week">Week <%# Eval("WeekNumber") %></span>
                            <span class='badge <%# StatusBadge(Container.DataItem) %>'><%# StatusText(Container.DataItem) %></span>
                        </div>
                        <h3 class="st-card-title"><%#: Eval("TaskName") %></h3>
                        <p class="st-card-desc"><%#: Eval("TaskDescription") %></p>
                        <div class="st-card-meta">
                            <span class='<%# DueCss(Container.DataItem) %>'><%# DueText(Container.DataItem) %></span>
                            <span><%# HoursText(Container.DataItem) %></span>
                            <span><%# TraineeText(Container.DataItem) %></span>
                        </div>
                        <div class="st-card-meta">
                            <span class='badge <%# ReviewBadge(Container.DataItem) %>'><%# ReviewText(Container.DataItem) %></span>
                        </div>
                        <div class="st-card-actions">
                            <a class="btn btn-sm btn-primary" href='ReviewTask.aspx?taskId=<%# Eval("TaskId") %>'>Review submissions</a>
                            <asp:LinkButton runat="server" CommandName="edit" CommandArgument='<%# Eval("TaskId") %>'
                                CssClass="btn btn-sm btn-outline-primary" Text="Edit" />
                            <asp:LinkButton runat="server" CommandName="toggle" CommandArgument='<%# Eval("TaskId") %>'
                                CssClass="btn btn-sm btn-outline-primary" Text='<%# ToggleText(Container.DataItem) %>' />
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

    <%-- New task: a popup that shows when pnlNew.Visible = true --%>
    <asp:Panel ID="pnlNew" runat="server" ClientIDMode="Static" CssClass="st-modal" Visible="false">
        <div class="st-modal-backdrop"></div>
        <div class="st-modal-dialog" role="dialog" aria-modal="true">
            <asp:LinkButton ID="btnClose" runat="server" ClientIDMode="Static" CssClass="st-modal-close" CausesValidation="false" OnClick="btnClose_Click" aria-label="Close">&times;</asp:LinkButton>

            <h2><asp:Label ID="lblPopupTitle" runat="server" Text="New task" /></h2>
            <asp:HiddenField ID="hfEditId" runat="server" />

            <div class="st-form">
                <label for="txtName">Task name *</label>
                <asp:TextBox ID="txtName" runat="server" ClientIDMode="Static" CssClass="form-control" MaxLength="100" />

                <label for="txtDescription">Description *</label>
                <%-- ValidateRequestMode=Disabled: the text may contain < and >. Safe because we HTML-encode it everywhere we show it. --%>
                <asp:TextBox ID="txtDescription" runat="server" ClientIDMode="Static" CssClass="form-control" TextMode="MultiLine" Rows="4" ValidateRequestMode="Disabled" />

                <div class="mt-two">
                    <div>
                        <label for="ddlWeek">Week *</label>
                        <asp:DropDownList ID="ddlWeek" runat="server" ClientIDMode="Static" CssClass="form-select">
                            <asp:ListItem Value="1" Text="Week 1" />
                            <asp:ListItem Value="2" Text="Week 2" />
                            <asp:ListItem Value="3" Text="Week 3" />
                            <asp:ListItem Value="4" Text="Week 4" />
                            <asp:ListItem Value="5" Text="Week 5" />
                            <asp:ListItem Value="6" Text="Week 6" />
                        </asp:DropDownList>
                    </div>
                    <div>
                        <label for="txtMax">Max score *</label>
                        <asp:TextBox ID="txtMax" runat="server" ClientIDMode="Static" CssClass="form-control" TextMode="Number" min="1" max="100" step="0.5" Text="10" />
                    </div>
                </div>

                <div class="mt-two">
                    <div>
                        <label for="txtStart">Start date *</label>
                        <asp:TextBox ID="txtStart" runat="server" ClientIDMode="Static" CssClass="form-control" TextMode="Date" />
                    </div>
                    <div>
                        <label for="txtDeadline">Deadline *</label>
                        <asp:TextBox ID="txtDeadline" runat="server" ClientIDMode="Static" CssClass="form-control" TextMode="Date" />
                    </div>
                </div>

                <label for="txtHours">Weight in hours (the default for everybody) *</label>
                <asp:TextBox ID="txtHours" runat="server" ClientIDMode="Static" CssClass="form-control" TextMode="Number" min="1" max="15" step="1" Text="1" />
                <div class="mt-hours-note">How many training hours this task stands for. The tasks of one week can add up to 15 hours at most for each trainee. A trainee who needs a different number can get it in the list below.</div>
                <div class="mt-hours mt-hours-popup"><asp:Literal ID="litPopupHours" runat="server" /></div>

                <label for="txtTools">Tools (optional)</label>
                <asp:TextBox ID="txtTools" runat="server" ClientIDMode="Static" CssClass="form-control" MaxLength="100" placeholder="Visual Studio, Git" />

                <label>Trainees who get this task * <span class="mt-hours-note">(empty hours box = the default hours)</span></label>
                <asp:Label ID="lblNoTrainees" runat="server" CssClass="text-muted" Visible="false" Text="No student is assigned to your company yet. Ask the coordinator." />
                <asp:Repeater ID="rptTrainees" runat="server">
                    <HeaderTemplate><div class="mt-trainees"></HeaderTemplate>
                    <ItemTemplate>
                        <div class="mt-trainee">
                            <asp:CheckBox ID="chkTrainee" runat="server" Checked='<%# (bool)Eval("Ticked") %>' />
                            <asp:HiddenField ID="hfTraineeId" runat="server" Value='<%# Eval("Id") %>' />
                            <span class="mt-trainee-name"><%#: Eval("Name") %></span>
                            <asp:TextBox ID="txtTraineeHours" runat="server" CssClass="form-control mt-trainee-hours" TextMode="Number" min="1" max="15" step="1" placeholder="same" Text='<%# Eval("Hours") %>' />
                        </div>
                    </ItemTemplate>
                    <FooterTemplate></div></FooterTemplate>
                </asp:Repeater>

                <div class="st-error"><asp:Label ID="lblFormError" runat="server" /></div>
                <asp:Button ID="btnSave" runat="server" Text="Create task" CssClass="btn btn-primary" OnClick="btnSave_Click" />
            </div>
        </div>
    </asp:Panel>

    <%-- Green message after a success (fades out by itself) --%>
    <asp:Panel ID="pnlMessage" runat="server" CssClass="st-flash" Visible="false">
        <asp:Label ID="lblMessage" runat="server" />
    </asp:Panel>

    <script src="<%= ResolveUrl("~/Company/ManageTasks/ManageTasks.js") %>"></script>
</asp:Content>
