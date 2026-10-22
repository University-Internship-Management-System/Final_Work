<%@ Page Title="Training report" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" CodeBehind="EvaluateTrainee.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Company.FinalEvaluationPage.EvaluateTraineeForm" Async="true" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="../../Student/StudentTasksPage/StudentTasks.css" rel="stylesheet" />
    <link href="FinalEvaluation.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <%--
        ONE TRAINEE (the id comes from the address: EvaluateTrainee.aspx?studentId=...).
        Part 1 = the weekly training report (page 1 of the university form SUJ-KASIT-03-01-02): the supervisor signs each week.
        Part 2 = the evaluation of the trainee's performance (page 2 of the form): 6 skills, 5 levels, then "Send".
        All data comes from the C# code-behind (EvaluateTrainee.aspx.cs).
    --%>

    <div class="st-page">

        <nav class="st-breadcrumb" aria-label="Breadcrumb">
            <a href="FinalEvaluation.aspx">Final Evaluation</a>
            <span>/</span>
            <asp:Label ID="lblCrumb" runat="server" Text="Trainee" />
        </nav>

        <div class="st-header st-week-header">
            <div>
                <h1 class="page-title">
                    <asp:Label ID="lblName" runat="server" />
                    <asp:Label ID="lblStatus" runat="server" CssClass="badge" />
                </h1>
                <p class="text-muted mb-0"><asp:Label ID="lblInfo" runat="server" /></p>
            </div>
        </div>

        <asp:Panel ID="pnlSentNote" runat="server" CssClass="ev-note" Visible="false">
            <asp:Label ID="lblSentNote" runat="server" />
        </asp:Panel>

        <div class="st-summary">
            <div class="st-stat" style="--stat-color: var(--uims-primary)">
                <div class="st-stat-number"><asp:Label ID="lblApprovedHours" runat="server" Text="0" /></div>
                <div class="st-stat-label">Hours of the signed weeks (90 needed)</div>
            </div>
            <div class="st-stat" style="--stat-color: var(--uims-info)">
                <div class="st-stat-number"><asp:Label ID="lblApprovedWeeks" runat="server" Text="0" /></div>
                <div class="st-stat-label">Weeks signed</div>
            </div>
            <div class="st-stat" style="--stat-color: var(--uims-success)">
                <div class="st-stat-number ev-small"><asp:Label ID="lblOverall" runat="server" Text="-" /></div>
                <div class="st-stat-label">Result of the evaluation</div>
            </div>
        </div>

        <%-- ================= 1. The weekly training report ================= --%>
        <h2 class="ev-title">1. Weekly training report</h2>
        <p class="text-muted">The hours come from the tasks. Sign a week after you reviewed the work of that week. The university expects at least 15 hours every week and 90 hours in total.</p>

        <asp:Repeater ID="rptWeeks" runat="server" OnItemCommand="rptWeeks_ItemCommand">
            <ItemTemplate>
                <article class="ev-week">
                    <div class="ev-week-head">
                        <div><strong>Week <%# Eval("Week") %></strong> <span class="text-muted"><%# Eval("Dates") %></span></div>
                        <span class='badge <%# Eval("Badge") %>'><%# Eval("StateText") %></span>
                    </div>

                    <asp:Repeater ID="rptWeekTasks" runat="server" DataSource='<%# Eval("Tasks") %>' Visible='<%# (int)Eval("TaskCount") > 0 %>'>
                        <HeaderTemplate>
                            <div class="table-responsive">
                                <table class="table ev-table">
                                    <thead><tr><th>Task</th><th>Software / equipment</th><th class="text-end">Hours</th><th>State</th></tr></thead>
                                    <tbody>
                        </HeaderTemplate>
                        <ItemTemplate>
                                        <tr>
                                            <td><%#: Eval("Name") %></td>
                                            <td><%#: Eval("Tools") %></td>
                                            <td class="text-end"><%# Eval("Hours") %></td>
                                            <td><span class='badge <%# Eval("Badge") %>'><%# Eval("StateText") %></span></td>
                                        </tr>
                        </ItemTemplate>
                        <FooterTemplate>
                                    </tbody>
                                </table>
                            </div>
                        </FooterTemplate>
                    </asp:Repeater>
                    <asp:Label runat="server" CssClass="text-muted d-block mb-2" Visible='<%# (int)Eval("TaskCount") == 0 %>' Text="No tasks in this week." />

                    <div class="ev-week-foot">
                        <span>Hours done: <strong><%# Eval("Done") %></strong> of <%# Eval("Planned") %> planned</span>
                        <span>
                            <asp:LinkButton runat="server" CommandName="approve" CommandArgument='<%# Eval("Week") %>'
                                Visible='<%# (bool)Eval("CanApprove") %>' CssClass="btn btn-sm btn-primary" Text="Sign this week" />
                            <asp:LinkButton runat="server" CommandName="withdraw" CommandArgument='<%# Eval("Week") %>'
                                Visible='<%# (bool)Eval("CanWithdraw") %>' CssClass="btn btn-sm btn-outline-primary" Text="Withdraw the signature" />
                        </span>
                    </div>
                </article>
            </ItemTemplate>
        </asp:Repeater>

        <%-- ================= 2. The evaluation of the trainee's performance ================= --%>
        <h2 class="ev-title">2. Evaluation of the trainee's performance</h2>
        <p class="text-muted">Fill this at the end of the training, then send it to the academic supervisor. The trainee cannot see it.</p>

        <div class="ev-form">
            <div class="ev-row ev-head">
                <div class="ev-skill">Skill</div>
                <div class="ev-levels"><span>Excellent</span><span>Very good</span><span>Good</span><span>Acceptable</span><span>Weak</span></div>
            </div>

            <div class="ev-row">
                <div class="ev-skill">Taking responsibility</div>
                <asp:RadioButtonList ID="rblResponsibility" runat="server" CssClass="ev-rbl" RepeatDirection="Horizontal" RepeatLayout="Table">
                    <asp:ListItem Value="Excellent" Text="" /><asp:ListItem Value="VeryGood" Text="" /><asp:ListItem Value="Good" Text="" /><asp:ListItem Value="Acceptable" Text="" /><asp:ListItem Value="Weak" Text="" />
                </asp:RadioButtonList>
            </div>
            <div class="ev-row">
                <div class="ev-skill">Keeping working hours</div>
                <asp:RadioButtonList ID="rblWorkingHours" runat="server" CssClass="ev-rbl" RepeatDirection="Horizontal" RepeatLayout="Table">
                    <asp:ListItem Value="Excellent" Text="" /><asp:ListItem Value="VeryGood" Text="" /><asp:ListItem Value="Good" Text="" /><asp:ListItem Value="Acceptable" Text="" /><asp:ListItem Value="Weak" Text="" />
                </asp:RadioButtonList>
            </div>
            <div class="ev-row">
                <div class="ev-skill">Accuracy in work</div>
                <asp:RadioButtonList ID="rblAccuracy" runat="server" CssClass="ev-rbl" RepeatDirection="Horizontal" RepeatLayout="Table">
                    <asp:ListItem Value="Excellent" Text="" /><asp:ListItem Value="VeryGood" Text="" /><asp:ListItem Value="Good" Text="" /><asp:ListItem Value="Acceptable" Text="" /><asp:ListItem Value="Weak" Text="" />
                </asp:RadioButtonList>
            </div>
            <div class="ev-row">
                <div class="ev-skill">Working in a team</div>
                <asp:RadioButtonList ID="rblTeamwork" runat="server" CssClass="ev-rbl" RepeatDirection="Horizontal" RepeatLayout="Table">
                    <asp:ListItem Value="Excellent" Text="" /><asp:ListItem Value="VeryGood" Text="" /><asp:ListItem Value="Good" Text="" /><asp:ListItem Value="Acceptable" Text="" /><asp:ListItem Value="Weak" Text="" />
                </asp:RadioButtonList>
            </div>
            <div class="ev-row">
                <div class="ev-skill">Adapting to the work environment</div>
                <asp:RadioButtonList ID="rblAdaptation" runat="server" CssClass="ev-rbl" RepeatDirection="Horizontal" RepeatLayout="Table">
                    <asp:ListItem Value="Excellent" Text="" /><asp:ListItem Value="VeryGood" Text="" /><asp:ListItem Value="Good" Text="" /><asp:ListItem Value="Acceptable" Text="" /><asp:ListItem Value="Weak" Text="" />
                </asp:RadioButtonList>
            </div>
            <div class="ev-row">
                <div class="ev-skill">Speed of learning new skills</div>
                <asp:RadioButtonList ID="rblLearningSpeed" runat="server" CssClass="ev-rbl" RepeatDirection="Horizontal" RepeatLayout="Table">
                    <asp:ListItem Value="Excellent" Text="" /><asp:ListItem Value="VeryGood" Text="" /><asp:ListItem Value="Good" Text="" /><asp:ListItem Value="Acceptable" Text="" /><asp:ListItem Value="Weak" Text="" />
                </asp:RadioButtonList>
            </div>

            <div class="st-form ev-fields">
                <div class="ev-two">
                    <div>
                        <label for="txtStart">Training start date</label>
                        <asp:TextBox ID="txtStart" runat="server" ClientIDMode="Static" CssClass="form-control" TextMode="Date" />
                    </div>
                    <div>
                        <label for="txtEnd">Training end date</label>
                        <asp:TextBox ID="txtEnd" runat="server" ClientIDMode="Static" CssClass="form-control" TextMode="Date" />
                    </div>
                </div>

                <div class="ev-total">Total training hours (the signed weeks): <strong><asp:Label ID="lblTotalHours" runat="server" Text="0" /></strong></div>

                <label for="txtComments">Comments (optional)</label>
                <%-- ValidateRequestMode=Disabled: the text may contain < and >. Safe because we HTML-encode it everywhere we show it. --%>
                <asp:TextBox ID="txtComments" runat="server" ClientIDMode="Static" CssClass="form-control" TextMode="MultiLine" Rows="4" MaxLength="1000" ValidateRequestMode="Disabled" />

                <div class="st-error"><asp:Label ID="lblFormError" runat="server" /></div>

                <asp:Panel ID="pnlButtons" runat="server" CssClass="ev-buttons">
                    <asp:Button ID="btnSave" runat="server" Text="Save draft" CssClass="btn btn-outline-primary" OnClick="btnSave_Click" />
                    <asp:Button ID="btnSend" runat="server" Text="Send to the academic supervisor" CssClass="btn btn-primary" OnClick="btnSend_Click"
                        OnClientClick="return confirm('Send the evaluation to the academic supervisor? You cannot change it after that.');" />
                </asp:Panel>
            </div>
        </div>
    </div>

    <%-- Message after a success (fades out by itself) --%>
    <asp:Panel ID="pnlMessage" runat="server" CssClass="st-flash" Visible="false">
        <asp:Label ID="lblMessage" runat="server" />
    </asp:Panel>
</asp:Content>
