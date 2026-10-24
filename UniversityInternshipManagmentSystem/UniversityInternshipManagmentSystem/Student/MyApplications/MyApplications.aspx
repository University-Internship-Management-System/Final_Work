<%@ Page Language="C#" AutoEventWireup="true" Async="true" CodeBehind="MyApplications.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Student.MyApplications.MyApplications" %>
<%@ Register Src="~/Shared/Sidebar.ascx" TagPrefix="uims" TagName="Sidebar" %>
<%@ Register Src="~/Shared/Footer.ascx" TagPrefix="uims" TagName="Footer" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>My Applications | UIMS</title>
    <link href="~/Content/bootstrap.min.css" rel="stylesheet" runat="server" />
    <link href="~/Shared/uims.css" rel="stylesheet" runat="server" />
    <link href="MyApplications.css" rel="stylesheet" />
</head>
<body>
    <form id="form1" runat="server">
        <div class="uims-shell">

            <!-- Sidebar -->
            <aside class="uims-sidebar">
                <uims:Sidebar runat="server" />
            </aside>
            <div class="uims-overlay" onclick="document.body.classList.remove('uims-side-open')"></div>

            <div class="uims-main">
                <!-- Topbar -->
                <div class="uims-topbar">
                    <button type="button" class="uims-menu-btn" aria-label="Open menu"
                        onclick="document.body.classList.add('uims-side-open')">&#9776;</button>
                    <span>UIMS</span>
                </div>

                <main class="uims-content">
                    <div class="uims-page-head">
                        <div>
                            <h1 class="page-title mb-1">My Applications</h1>
                            <p class="text-muted mb-0">Track and manage your submitted internship applications.</p>
                        </div>
                    </div>

                    <%-- error message --%>
                    <asp:Panel ID="pnlMessage" runat="server" Visible="false" CssClass="alert alert-warning">
                        <asp:Label ID="lblMessage" runat="server" />
                    </asp:Panel>

                    <%-- the confirmed training, on top --%>
                    <asp:Panel ID="pnlConfirmed" runat="server" Visible="false" CssClass="confirmed-card">
                        <div class="confirmed-icon">&#10003;</div>
                        <div class="confirmed-body">
                            <div class="confirmed-eyebrow">Your training</div>
                            <h3 class="confirmed-title"><asp:Literal ID="litConfirmedTitle" runat="server" Mode="Encode" /></h3>
                            <div class="confirmed-company"><asp:Literal ID="litConfirmedCompany" runat="server" Mode="Encode" /></div>
                            <%-- only when the opportunity has a training start date --%>
                            <asp:Panel ID="pnlTrainingStart" runat="server" Visible="false" CssClass="confirmed-chip">
                                Training starts <strong><asp:Literal ID="litTrainingStart" runat="server" Mode="Encode" /></strong>
                            </asp:Panel>
                        </div>
                        <span class="confirmed-pill">Confirmed</span>
                    </asp:Panel>

                    <%-- after a confirmed training the other applications are only history --%>
                    <asp:Panel ID="pnlHistoryHead" runat="server" Visible="false" CssClass="history-head">
                        <h5 class="mb-1">Application history</h5>
                        <p class="text-muted small mb-0">Your other applications. They are closed now that you have a confirmed training.</p>
                    </asp:Panel>

                    <!-- applications table -->
                    <asp:Panel ID="pnlList" runat="server" CssClass="card app-table-card">
                        <div class="card-body p-4">
                            
                            <asp:Repeater ID="rptApplications" runat="server" OnItemCommand="rptApplications_ItemCommand">
                                <HeaderTemplate>
                                    <div class="table-responsive">
                                        <table class="table align-middle mb-0 uims-app-table">
                                            <thead>
                                                <tr>
                                                    <th>Opportunity Title</th>
                                                    <th>Company</th>
                                                    <th>Applied Date</th>
                                                    <th>Status</th>
                                                    <th class="text-end">Actions / Details</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                </HeaderTemplate>
                                <ItemTemplate>
                                        <tr>
                                            <td>
                                                <span class="fw-bold d-block text-dark"><%#: Eval("OpportunityTitle") %></span>
                                            </td>
                                            <td>
                                                <span class="text-secondary"><%#: Eval("CompanyName") %></span>
                                            </td>
                                            <td>
                                                <small class="text-muted"><%# FormatDate(Eval("AppliedAt")) %></small>
                                            </td>
                                            <td>
                                                <span class='badge <%# GetStatusBadgeClass(Eval("Status")) %> px-2 py-1'>
                                                    <%#: Eval("Status") %>
                                                </span>
                                            </td>
                                            <td class="text-end">
                                                <%-- Pending --%>
                                                <asp:Panel runat="server" Visible='<%# Convert.ToString(Eval("Status")) == "Pending" %>'>
                                                    <span class="text-muted small">Under Review</span>
                                                </asp:Panel>

                                                <%-- Rejected, show the reason --%>
                                                <asp:Panel runat="server" Visible='<%# Convert.ToString(Eval("Status")) == "Rejected" %>'>
                                                    <span class="text-danger small fw-semibold">
                                                        Reason: <%#: string.IsNullOrEmpty(Convert.ToString(Eval("RejectionReason"))) ? "No reason specified" : Convert.ToString(Eval("RejectionReason")) %>
                                                    </span>
                                                </asp:Panel>

                                                <%-- Accepted, the student confirms or rejects --%>
                                                <asp:Panel runat="server" Visible='<%# Convert.ToString(Eval("Status")) == "Accepted" %>'>
                                                    <div class="d-inline-flex gap-2">
                                                        <asp:Button ID="btnConfirm" runat="server" Text="Confirm" CommandName="ConfirmApp" CommandArgument='<%# Eval("Id") %>' CssClass="btn btn-sm btn-success btn-confirm-action" />
                                                        <asp:Button ID="btnRejectOffer" runat="server" Text="Reject" CommandName="RejectOffer" CommandArgument='<%# Eval("Id") %>' CssClass="btn btn-sm btn-outline-danger btn-reject-action" />
                                                    </div>
                                                </asp:Panel>

                                                <%-- Confirmed --%>
                                                <asp:Panel runat="server" Visible='<%# Convert.ToString(Eval("Status")) == "Confirmed" %>'>
                                                    <span class="badge bg-success-subtle text-success border border-success-subtle px-3 py-1">
                                                        Confirmed Training
                                                    </span>
                                                </asp:Panel>
                                            </td>
                                        </tr>
                                </ItemTemplate>
                                <FooterTemplate>
                                            </tbody>
                                        </table>
                                    </div>
                                </FooterTemplate>
                            </asp:Repeater>

                            <!-- no applications yet -->
                            <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="text-center py-5">
                                <h5 class="text-muted mb-2">No applications submitted yet</h5>
                                <p class="text-muted small mb-3">Explore available opportunities and apply to get started.</p>
                                <a href="../Opportunities/Opportunities.aspx" class="btn btn-primary btn-sm px-3">Browse Opportunities</a>
                            </asp:Panel>

                        </div>
                    </asp:Panel>
                </main>

                <!-- Footer -->
                <uims:Footer runat="server" />
            </div>

        </div>
    </form>

    <script src="<%= ResolveUrl("~/Scripts/bootstrap.bundle.min.js") %>"></script>
    <script src="MyApplications.js"></script>
</body>
</html>