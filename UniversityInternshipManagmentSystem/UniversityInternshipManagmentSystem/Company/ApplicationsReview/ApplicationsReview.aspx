<%@ Page Language="C#" AutoEventWireup="true" Async="true" CodeBehind="ApplicationsReview.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Company.ApplicationsReview.ApplicationsReview" %>
<%@ Register Src="~/Shared/Sidebar.ascx" TagPrefix="uims" TagName="Sidebar" %>
<%@ Register Src="~/Shared/Footer.ascx" TagPrefix="uims" TagName="Footer" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Applications Review | UIMS</title>
    <link href="~/Content/bootstrap.min.css" rel="stylesheet" runat="server" />
    <link href="~/Shared/uims.css" rel="stylesheet" runat="server" />
    <link href="ApplicationsReview.css" rel="stylesheet" />
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
                            <h1 class="page-title mb-1">Applications Review</h1>
                            <p class="text-muted mb-0">Review the students who applied to your opportunities, then accept or reject them.</p>
                        </div>
                    </div>

                    <%-- error message --%>
                    <asp:Panel ID="pnlMessage" runat="server" Visible="false" EnableViewState="false" CssClass="alert alert-warning">
                        <asp:Label ID="lblMessage" runat="server" />
                    </asp:Panel>

                    <div class="card app-table-card">
                        <div class="card-body p-4">

                            <%-- count and status filter --%>
                            <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
                                <asp:Label ID="lblCount" runat="server" CssClass="small-label" />
                                <div class="d-flex align-items-center gap-2">
                                    <label class="small-label mb-0" for="ddlStatus">Status</label>
                                    <asp:DropDownList ID="ddlStatus" runat="server" ClientIDMode="Static" AutoPostBack="true"
                                        OnSelectedIndexChanged="ddlStatus_SelectedIndexChanged" CssClass="form-select form-select-sm app-filter">
                                        <asp:ListItem Value="">All</asp:ListItem>
                                        <asp:ListItem Value="Pending">Pending</asp:ListItem>
                                        <asp:ListItem Value="Accepted">Accepted</asp:ListItem>
                                        <asp:ListItem Value="Rejected">Rejected</asp:ListItem>
                                        <asp:ListItem Value="Confirmed">Confirmed</asp:ListItem>
                                    </asp:DropDownList>
                                </div>
                            </div>

                            <%-- applications table, pending first --%>
                            <asp:Repeater ID="rptApplications" runat="server" OnItemCommand="rptApplications_ItemCommand">
                                <HeaderTemplate>
                                    <div class="table-responsive">
                                        <table class="table align-middle mb-0 uims-app-table">
                                            <thead>
                                                <tr>
                                                    <th>Student</th>
                                                    <th>Major</th>
                                                    <th>Opportunity</th>
                                                    <th>Applied</th>
                                                    <th>Status</th>
                                                    <th class="text-end">Application</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                </HeaderTemplate>
                                <ItemTemplate>
                                                <tr>
                                                    <td class="fw-bold text-dark"><%#: Eval("StudentName") %></td>
                                                    <td><%#: Eval("Major") %></td>
                                                    <td><%#: Eval("OpportunityTitle") %></td>
                                                    <td><small class="text-muted"><%#: Eval("AppliedDate") %></small></td>
                                                    <td>
                                                        <span class='badge <%# StatusBadgeClass(Eval("Status")) %> px-2 py-1'><%#: Eval("Status") %></span>
                                                    </td>
                                                    <td class="text-end">
                                                        <asp:LinkButton runat="server" CommandName="ViewApp" CommandArgument='<%# Eval("Id") %>'
                                                            CssClass="btn btn-sm btn-outline-primary">View</asp:LinkButton>
                                                    </td>
                                                </tr>
                                </ItemTemplate>
                                <FooterTemplate>
                                            </tbody>
                                        </table>
                                    </div>
                                </FooterTemplate>
                            </asp:Repeater>

                            <%-- no applications --%>
                            <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="text-center py-5">
                                <h5 class="text-muted mb-2">No applications to show</h5>
                                <p class="text-muted small mb-0">When students apply to your opportunities, they will appear here.</p>
                            </asp:Panel>

                        </div>
                    </div>
                </main>

                <!-- Footer -->
                <uims:Footer runat="server" />
            </div>

        </div>

        <%-- id of the application open in the popup --%>
        <asp:HiddenField ID="hfApplicationId" runat="server" />

        <!-- application popup (View button) -->
        <div class="modal fade" id="applicationModal" tabindex="-1" aria-labelledby="applicationModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title fw-bold" id="applicationModalLabel">Application Form</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">

                        <%-- why the decision failed --%>
                        <asp:Panel ID="pnlModalError" runat="server" Visible="false" EnableViewState="false" CssClass="alert alert-danger">
                            <asp:Label ID="lblModalError" runat="server" />
                        </asp:Panel>

                        <%-- who applied, for what, and the status --%>
                        <div class="app-summary">
                            <div>
                                <div class="app-student"><asp:Literal ID="litStudent" runat="server" Mode="Encode" /></div>
                                <div class="app-applied">
                                    Applied for <strong><asp:Literal ID="litOpportunity" runat="server" Mode="Encode" /></strong>
                                    on <asp:Literal ID="litApplied" runat="server" Mode="Encode" />
                                </div>
                            </div>
                            <asp:Label ID="lblStatus" runat="server" CssClass="badge" />
                        </div>

                        <%-- already answered --%>
                        <asp:Label ID="lblNextStep" runat="server" CssClass="app-next-step" />

                        <h6 class="app-section-title">Student details</h6>
                        <div class="row g-2">
                            <div class="col-md-6">
                                <div class="app-tile">
                                    <span class="app-field-label">Major</span>
                                    <asp:Literal ID="litMajor" runat="server" Mode="Encode" />
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="app-tile">
                                    <span class="app-field-label">GPA</span>
                                    <asp:Literal ID="litGpa" runat="server" Mode="Encode" />
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="app-tile">
                                    <span class="app-field-label">Email</span>
                                    <asp:Literal ID="litEmail" runat="server" Mode="Encode" />
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="app-tile">
                                    <span class="app-field-label">Phone</span>
                                    <asp:Literal ID="litPhone" runat="server" Mode="Encode" />
                                </div>
                            </div>
                            <div class="col-12">
                                <div class="app-tile">
                                    <span class="app-field-label">Skills</span>
                                    <asp:Literal ID="litSkills" runat="server" Mode="Encode" />
                                </div>
                            </div>
                        </div>

                        <h6 class="app-section-title">Documents</h6>
                        <div class="d-flex flex-wrap gap-2">
                            <asp:HyperLink ID="lnkCv" runat="server" Target="_blank" CssClass="app-doc" />
                            <asp:HyperLink ID="lnkPortfolio" runat="server" Target="_blank" CssClass="app-doc" />
                        </div>

                        <h6 class="app-section-title">Cover letter</h6>
                        <div class="app-question">Why are you interested in this internship?</div>
                        <p class="app-cover"><asp:Literal ID="litCover" runat="server" Mode="Encode" /></p>

                        <%-- pending: accept or reject (enter in the reason box = reject) --%>
                        <asp:Panel ID="pnlDecision" runat="server" DefaultButton="btnReject" CssClass="app-decision">
                            <%-- step 1: Accept or Reject --%>
                            <div id="decisionButtons" class="app-decision-row">
                                <span class="app-decision-label">Your decision</span>
                                <div class="app-decision-buttons">
                                    <asp:Button ID="btnAccept" runat="server" Text="Accept" CssClass="btn btn-success"
                                        OnClick="btnAccept_Click" OnClientClick="return confirm('Accept this application?');" />
                                    <button type="button" class="btn btn-outline-danger" onclick="showRejectBox()">Reject</button>
                                </div>
                            </div>

                            <%-- step 2: shown only after Reject is clicked --%>
                            <div id="rejectBox" class="d-none">
                                <label class="app-field-label" for="txtReason">Reason for rejection</label>
                                <asp:TextBox ID="txtReason" runat="server" ClientIDMode="Static" CssClass="form-control" MaxLength="300" placeholder="Write why the application is rejected (the student will see it)" />
                                <div class="app-decision-buttons">
                                    <button type="button" class="btn btn-outline-secondary" onclick="hideRejectBox()">Cancel</button>
                                    <asp:Button ID="btnReject" runat="server" Text="Confirm rejection" CssClass="btn btn-danger"
                                        OnClick="btnReject_Click" OnClientClick="return confirmReject();" />
                                </div>
                            </div>
                        </asp:Panel>

                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Close</button>
                    </div>
                </div>
            </div>
        </div>
    </form>

    <script src="<%= ResolveUrl("~/Scripts/bootstrap.bundle.min.js") %>"></script>
    <script src="ApplicationsReview.js"></script>
</body>
</html>