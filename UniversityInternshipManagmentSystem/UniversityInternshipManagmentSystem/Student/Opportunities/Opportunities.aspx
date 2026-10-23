<%@ Page Language="C#" AutoEventWireup="true" Async="true" CodeBehind="Opportunities.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Student.Opportunities.Opportunities" %>
<%@ Register Src="~/Shared/Sidebar.ascx" TagPrefix="uims" TagName="Sidebar" %>
<%@ Register Src="~/Shared/Footer.ascx" TagPrefix="uims" TagName="Footer" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Explore Opportunities | UIMS</title>
    <link href="~/Content/bootstrap.min.css" rel="stylesheet" runat="server" />
    <link href="~/Shared/uims.css" rel="stylesheet" runat="server" />
    <link href="Opportunities.css" rel="stylesheet" />
</head>
<body>
    <form id="form1" runat="server">
        <div class="uims-shell">

            <aside class="uims-sidebar">
                <uims:Sidebar runat="server" />
            </aside>
            <div class="uims-overlay" onclick="document.body.classList.remove('uims-side-open')"></div>

            <div class="uims-main">
                <div class="uims-topbar">
                    <button type="button" class="uims-menu-btn" aria-label="Open menu"
                        onclick="document.body.classList.add('uims-side-open')">&#9776;</button>
                    <span>UIMS</span>
                </div>

                <main class="uims-content">

                    <div class="uims-page-head">
                        <div>
                            <h1 class="page-title mb-1">Explore Opportunities</h1>
                            <p class="text-muted mb-0">Internships that match your major.</p>
                        </div>
                        <asp:Label ID="lblCount" runat="server" ClientIDMode="Static" CssClass="small-label" />
                    </div>

                    <%-- why the student can't apply, or a load error --%>
                    <asp:Panel ID="pnlNotice" runat="server" Visible="false" CssClass="alert alert-warning">
                        <asp:Label ID="lblNotice" runat="server" />
                    </asp:Panel>

                    <%-- search and company filter --%>
                    <div class="card mb-4">
                        <div class="card-body">
                            <div class="row g-3 align-items-end">
                                <div class="col-md-6">
                                    <label class="small-label mb-1" for="txtSearch">Search</label>
                                    <asp:TextBox ID="txtSearch" runat="server" ClientIDMode="Static" CssClass="form-control" placeholder="Title, keyword or location" />
                                </div>
                                <div class="col-md-3">
                                    <label class="small-label mb-1" for="<%= ddlCompany.ClientID %>">Company</label>
                                    <asp:DropDownList ID="ddlCompany" runat="server" CssClass="form-select">
                                        <asp:ListItem Value="">All companies</asp:ListItem>
                                    </asp:DropDownList>
                                </div>
                                <div class="col-md-3 d-flex gap-2">
                                    <asp:Button ID="btnSearch" runat="server" ClientIDMode="Static" Text="Search" CssClass="btn btn-primary flex-fill" CausesValidation="false" />
                                    <asp:Button ID="btnReset" runat="server" Text="Reset" CssClass="btn btn-outline-primary" CausesValidation="false" />
                                </div>
                            </div>
                        </div>
                    </div>

                    <%-- the cards are added here from the code behind --%>
                    <div class="row g-4" id="oppGrid" runat="server" clientidmode="Static">
                    </div>

                    <div id="oppNoMatch" class="card opp-hidden"><div class="opp-nomatch">No opportunities match what you typed.</div></div>

                    <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="card">
                        <div class="opp-empty">
                            <div class="icon">&#128188;</div>
                            <h3 class="card-title mt-2">No opportunities found</h3>
                            <p class="mb-0">Try a different search, or check back later for new internships.</p>
                        </div>
                    </asp:Panel>
                </main>

                <uims:Footer runat="server" />
            </div>

        </div>
    </form>

    <script src="<%= ResolveUrl("~/Scripts/bootstrap.bundle.min.js") %>"></script>
    <script src="<%= ResolveUrl("Opportunities.js") %>"></script>
</body>
</html>