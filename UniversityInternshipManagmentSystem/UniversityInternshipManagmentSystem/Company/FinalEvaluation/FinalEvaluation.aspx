<%@ Page Title="Final Evaluation" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" CodeBehind="FinalEvaluation.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Company.FinalEvaluationPage.FinalEvaluationListForm" Async="true" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="../../Student/StudentTasksPage/StudentTasks.css" rel="stylesheet" />
    <link href="FinalEvaluation.css" rel="stylesheet" />
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <%--
        FINAL EVALUATION (company supervisor) = my trainees, with the state of their training report and final evaluation.
        "Open" goes to the page of one trainee (EvaluateTrainee.aspx) where the supervisor signs the weeks and fills the evaluation form.
        All data comes from the C# code-behind (FinalEvaluation.aspx.cs).
    --%>

    <div class="st-page">

        <div class="st-header">
            <div>
                <h1 class="page-title">Final Evaluation</h1>
                <p class="text-muted mb-0">Sign the weekly training report of each trainee and complete the final evaluation (university form SUJ-KASIT-03-01-02).</p>
            </div>
        </div>

        <div class="st-summary">
            <div class="st-stat" style="--stat-color: var(--uims-primary)">
                <div class="st-stat-number"><asp:Label ID="lblTrainees" runat="server" Text="0" /></div>
                <div class="st-stat-label">Trainees</div>
            </div>
            <div class="st-stat" style="--stat-color: var(--uims-warning)">
                <div class="st-stat-number"><asp:Label ID="lblNotStarted" runat="server" Text="0" /></div>
                <div class="st-stat-label">Not started</div>
            </div>
            <div class="st-stat" style="--stat-color: var(--uims-info)">
                <div class="st-stat-number"><asp:Label ID="lblDraft" runat="server" Text="0" /></div>
                <div class="st-stat-label">Draft</div>
            </div>
            <div class="st-stat" style="--stat-color: var(--uims-success)">
                <div class="st-stat-number"><asp:Label ID="lblSent" runat="server" Text="0" /></div>
                <div class="st-stat-label">Sent to the academic supervisor</div>
            </div>
        </div>

        <%-- One line per trainee --%>
        <asp:Repeater ID="rptTrainees" runat="server">
            <HeaderTemplate>
                <div class="card">
                    <div class="table-responsive">
                        <table class="table align-middle mb-0">
                            <thead>
                                <tr><th>Trainee</th><th>Hours done</th><th>Weeks signed</th><th>Final evaluation</th><th></th></tr>
                            </thead>
                            <tbody>
            </HeaderTemplate>
            <ItemTemplate>
                                <tr>
                                    <td><strong><%#: Eval("Name") %></strong><span class="ev-sub"><%#: Eval("Major") %></span></td>
                                    <td><%# Eval("HoursText") %></td>
                                    <td><%# Eval("WeeksText") %></td>
                                    <td><span class='badge <%# Eval("Badge") %>'><%# Eval("StatusText") %></span></td>
                                    <td class="text-end"><a class="btn btn-sm btn-primary" href='EvaluateTrainee.aspx?studentId=<%# Eval("Id") %>'>Open</a></td>
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
            <p class="st-empty-title">No trainees yet</p>
            <p class="text-muted mb-0">The coordinator assigns students to your company. They show here when they are assigned.</p>
        </asp:Panel>
    </div>
</asp:Content>
