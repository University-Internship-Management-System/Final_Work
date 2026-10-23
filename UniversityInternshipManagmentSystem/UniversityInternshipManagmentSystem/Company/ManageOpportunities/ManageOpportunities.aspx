<%@ Page Language="C#" AutoEventWireup="true" Async="true" CodeBehind="ManageOpportunities.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Company.ManageOpportunities.ManageOpportunities" %>
<%@ Register Src="~/Shared/Sidebar.ascx" TagPrefix="uims" TagName="Sidebar" %>
<%@ Register Src="~/Shared/Footer.ascx" TagPrefix="uims" TagName="Footer" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Manage Opportunities | UIMS</title>
    <link href="~/Content/bootstrap.min.css" rel="stylesheet" runat="server" />
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet" />
    <link href="~/Shared/uims.css" rel="stylesheet" runat="server" />
    <link href="ManageOpportunities.css" rel="stylesheet" />
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
                    <span>UIMS - Company Supervisor Dashboard</span>
                </div>

                <main class="uims-content">
                    <div class="uims-page-head d-flex justify-content-between align-items-center mb-4">
                        <div>
                            <h1 class="page-title mb-1">Manage Opportunities</h1>
                            <p class="text-muted mb-0">Add, edit, and close internship opportunities, specify specializations, requirements, and available seats.</p>
                        </div>
                        <%-- Hidden when the company profile is missing (nothing could be saved) --%>
                        <asp:PlaceHolder ID="phAddButton" runat="server">
                            <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#opportunityModal" id="btnAddOpportunity" onclick="resetModalForAdd()">
                                <i class="fa fa-plus me-1"></i> Add New Opportunity
                            </button>
                        </asp:PlaceHolder>
                    </div>

                    <%-- Why an action was refused, or why the list could not be loaded --%>
                    <asp:Panel ID="pnlMessage" runat="server" Visible="false" EnableViewState="false" CssClass="alert alert-warning">
                        <asp:Label ID="lblMessage" runat="server" />
                    </asp:Panel>

                    <!-- Hidden field to track editing ID -->
                    <asp:HiddenField ID="hfEditingOpportunityId" runat="server" ClientIDMode="Static" />

                    <!-- Opportunities Table Card -->
                    <div class="card opp-table-card">
                        <div class="card-body p-4">
                            
                            <asp:Repeater ID="rptOpportunities" runat="server" OnItemCommand="rptOpportunities_ItemCommand">
                                <HeaderTemplate>
                                    <div class="table-responsive">
                                        <table class="table align-middle mb-0 uims-opp-table">
                                            <thead>
                                                <tr>
                                                    <th>Title</th>
                                                    <th>Company</th>
                                                    <th>Seats Left</th>
                                                    <th>Status</th>
                                                    <th>Deadline</th>
                                                    <th class="text-end">Actions</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                </HeaderTemplate>
                                <ItemTemplate>
                                                <tr>
                                                    <td>
                                                        <span class="fw-bold d-block text-dark"><%#: Eval("Title") %></span>
                                                    </td>
                                                    <td>
                                                        <span class="text-secondary"><%#: Eval("CompanyName") %></span>
                                                    </td>
                                                    <td>
                                                        <span class="badge bg-light text-dark border"><%# Eval("SeatsLeft") %> of <%# Eval("Seats") %></span>
                                                    </td>
                                                    <td>
                                                        <span class='badge <%# StatusBadgeClass(Container.DataItem) %> px-2 py-1'>
                                                            <%# StatusText(Container.DataItem) %>
                                                        </span>
                                                    </td>
                                                    <td>
                                                        <small class="text-muted"><%# FormatDate(Eval("ApplicationDeadline")) %></small>
                                                    </td>
                                                    <td class="text-end">
                                                        <div class="d-inline-flex gap-1">
                                                            <asp:LinkButton ID="btnToggle" runat="server" CommandName="ToggleStatus" CommandArgument='<%# Eval("Id") %>' 
                                                                CssClass='<%# IsStatusOpen(Container.DataItem) ? "btn btn-sm btn-outline-danger" : "btn btn-sm btn-outline-success" %>'>
                                                                <%# IsStatusOpen(Container.DataItem) ? "Close" : "Open" %>
                                                            </asp:LinkButton>
                                                            
                                                            <asp:LinkButton ID="btnEdit" runat="server" CommandName="EditOpp" CommandArgument='<%# Eval("Id") %>' 
                                                                CssClass="btn btn-sm btn-outline-primary">
                                                                <i class="fa fa-pen"></i> Edit
                                                            </asp:LinkButton>
                                                        </div>
                                                    </td>
                                                </tr>
                                </ItemTemplate>
                                <FooterTemplate>
                                            </tbody>
                                        </table>
                                    </div>
                                </FooterTemplate>
                            </asp:Repeater>

                            <!-- حالة عدم وجود بيانات -->
                            <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="text-center py-5">
                                <h5 class="text-muted mb-2">No opportunities found</h5>
                                <p class="text-muted small mb-3">Click on "Add New Opportunity" to create the first one.</p>
                            </asp:Panel>

                        </div>
                    </div>
                </main>

                <!-- Footer -->
                <uims:Footer runat="server" />
            </div>

        </div>

        <!-- Modal for Add/Edit Opportunity -->
        <div class="modal fade" id="opportunityModal" tabindex="-1" aria-labelledby="opportunityModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-centered">
                <div class="modal-content p-3">
                    <div class="modal-header border-0">
                        <h5 class="modal-title fw-bold" id="opportunityModalLabel">Add Opportunity</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <%-- Why the last save was refused (the form opens again with what was typed) --%>
                        <asp:Panel ID="pnlFormError" runat="server" ClientIDMode="Static" Visible="false" EnableViewState="false" CssClass="alert alert-danger">
                            <asp:Label ID="lblFormError" runat="server" />
                        </asp:Panel>
                        <div class="row g-3">
                            <div class="col-md-12">
                                <label class="form-label small-label" for="txtTitle">Opportunity Title <span class="text-danger">*</span></label>
                                <asp:TextBox ID="txtTitle" runat="server" ClientIDMode="Static" CssClass="form-control" placeholder="e.g. Software Engineering Intern" Required="true" />
                            </div>
                            <div class="col-md-6">
                                <label class="form-label small-label" for="txtCompanyName">Company Name</label>
                                <asp:TextBox ID="txtCompanyName" runat="server" ClientIDMode="Static" CssClass="form-control bg-light" ReadOnly="true" />
                            </div>
                            <div class="col-md-6">
                                <label class="form-label small-label" for="txtLocation">Location</label>
                                <asp:TextBox ID="txtLocation" runat="server" ClientIDMode="Static" CssClass="form-control bg-light" ReadOnly="true" />
                            </div>
                            <div class="col-md-6">
                                <label class="form-label small-label" for="txtSeats">Available Seats <span class="text-danger">*</span></label>
                                <asp:TextBox ID="txtSeats" runat="server" ClientIDMode="Static" CssClass="form-control" TextMode="Number" placeholder="e.g. 5" min="1" Required="true" />
                            </div>
                            <div class="col-md-6">
                                <label class="form-label small-label" for="txtDeadline">Application Deadline <span class="text-danger">*</span></label>
                                <asp:TextBox ID="txtDeadline" runat="server" ClientIDMode="Static" TextMode="Date" CssClass="form-control" Required="true" />
                            </div>
                            <div class="col-12">
                                <label class="form-label small-label" for="txtDescription">Description <span class="text-danger">*</span></label>
                                <asp:TextBox ID="txtDescription" runat="server" ClientIDMode="Static" TextMode="MultiLine" Rows="3" CssClass="form-control" placeholder="Describe the role and responsibilities..." Required="true" />
                            </div>
                            <div class="col-12">
                                <label class="form-label small-label fw-bold mb-2">Required Majors <span class="text-danger">*</span></label>
                                <div class="p-3 border rounded bg-light majors-checkbox-list">
                                    <asp:CheckBoxList ID="chkMajors" runat="server" ClientIDMode="Static" RepeatLayout="Flow">
                                        <asp:ListItem Text="Computer Science" Value="Computer Science" />
                                        <asp:ListItem Text="Cybersecurity" Value="Cybersecurity" />
                                        <asp:ListItem Text="Computer Information Systems" Value="Computer Information Systems" />
                                        <asp:ListItem Text="Business Information Technology" Value="Business Information Technology" />
                                        <asp:ListItem Text="Data Science" Value="Data Science" />
                                        <asp:ListItem Text="Artificial Intelligence" Value="Artificial Intelligence" />
                                    </asp:CheckBoxList>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer border-0">
                        <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                        <asp:Button ID="btnSaveOpportunity" runat="server" ClientIDMode="Static" Text="Save Opportunity" CssClass="btn btn-primary px-4" OnClick="btnSaveOpportunity_Click" />
                    </div>
                </div>
            </div>
        </div>

    </form>

    <script src="<%= ResolveUrl("~/Scripts/bootstrap.bundle.min.js") %>"></script>
    <script src="ManageOpportunities.js"></script>
    
    
</body>
</html>