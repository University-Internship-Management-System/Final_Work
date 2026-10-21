<%@ Control Language="C#" %>

<script runat="server">
    // =====================================================================
    //  EDIT THE MENUS HERE.   Format:  "Link text|~/Folder/Page.aspx"
    //  The role comes from Session["role"]  ("student", "company", "academic", "coordinator")
    // =====================================================================
    string[] GetMenu(string role)
    {
        switch (role)
        {
            case "student":
                return new[] {
                    "Dashboard|~/Student/Dashboard.aspx",
                    "My Profile|~/Student/Profile.aspx",
                    "Explore Opportunities|~/Student/Opportunities.aspx",
                    "My Applications|~/Student/Applications.aspx",
                    "My Tasks|~/Student/Tasks.aspx",
                    "My Progress|~/Student/Progress.aspx"
                };
            case "company":
                return new[] {
                    "Dashboard|~/Company/Dashboard.aspx",
                    "Manage Opportunities|~/Company/Opportunities.aspx",
                    "Applications|~/Company/Applications.aspx",
                    "My Trainees|~/Company/Trainees.aspx",
                    "Tasks|~/Company/Tasks.aspx",
                    "Final Evaluation|~/Company/FinalEvaluation.aspx",
                    "Account|~/Company/Account.aspx"
                };
            case "academic":
                return new[] {
                    "Dashboard|~/Academic/Dashboard.aspx",
                    "Student Progress|~/Academic/Progress.aspx",
                    "Final Evaluation|~/Academic/FinalEvaluation.aspx",
                    "Account|~/Academic/Account.aspx"
                };
            case "coordinator":
            case "admin":
                return new[] {
                    "Dashboard|~/CoordinatorDashbord/CoordinatorDashbord.aspx",
                    "Students|~/CoordinatorMonitor/CoordinatorMonitor.aspx?view=students",
                    "Companies|~/CoordinatorMonitor/CoordinatorMonitor.aspx?view=companies",
                    "Academic Supervisors|~/CoordinatorMonitor/CoordinatorMonitor.aspx?view=academic",
                    "Assign Supervisors|~/Coordinator/Assign.aspx",
                    "Monitor Progress|~/CoordinatorMonitor/CoordinatorMonitor.aspx",
                    "Completion Review|~/Coordinator/FinalCompletionReview.aspx",
                    "Contact Messages|~/Coordinator/Messages.aspx",
                    "Account|~/Coordinator/Account.aspx"
                };
            default:
                return new string[0];
        }
    }

    string GetRoleTitle(string role)
    {
        switch (role)
        {
            case "student": return "Student";
            case "company": return "Company Supervisor";
            case "academic": return "Academic Supervisor";
            case "coordinator":
            case "admin": return "Coordinator";
            default: return "Guest";
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        string role = ((Session["role"] as string) ?? "").ToLower();
        string currentPage = Request.AppRelativeCurrentExecutionFilePath;
        // Keep direct Coordinator page previews navigable when no login session exists.
        // This only selects navigation links; it does not grant access to page data.
        if (String.IsNullOrEmpty(role) && (currentPage.StartsWith("~/Coordinator/", StringComparison.OrdinalIgnoreCase) || currentPage.StartsWith("~/CoordinatorDashbord/", StringComparison.OrdinalIgnoreCase) || currentPage.StartsWith("~/CoordinatorMonitor/", StringComparison.OrdinalIgnoreCase)))
        {
            role = "coordinator";
        }

        var html = new System.Text.StringBuilder();
        foreach (string item in GetMenu(role))
        {
            string[] parts = item.Split('|');
            string[] target = parts[1].Split('?');
            bool active = currentPage.Equals(target[0], StringComparison.OrdinalIgnoreCase)
                          && (target.Length == 1 ? String.IsNullOrEmpty(Request.QueryString["view"])
                                                 : Request.QueryString["view"] == target[1].Split('=')[1]);
            html.Append("<a class=\"uims-side-link" + (active ? " active" : "") + "\" href=\"" + ResolveUrl(parts[1]) + "\">"
                        + Server.HtmlEncode(parts[0]) + "</a>");
        }

        litLinks.Text = html.ToString();
        litRole.Text = GetRoleTitle(role);
        litName.Text = Server.HtmlEncode((Session["name"] as string) ?? "Not signed in");
    }

    protected void btnLogout_Click(object sender, EventArgs e)
    {
        Session.Clear();
        Response.Redirect("~/Default.aspx");
    }
</script>

<a class="uims-side-brand" runat="server" href="~/Default.aspx">
    <span class="uims-logo">UJ</span>
    <strong>UIMS</strong>
</a>
<p class="uims-side-role"><asp:Literal ID="litRole" runat="server" /></p>

<nav class="uims-side-links">
    <asp:Literal ID="litLinks" runat="server" />
</nav>

<div class="uims-side-user">
    <div class="name"><asp:Literal ID="litName" runat="server" /></div>
    <asp:LinkButton ID="btnLogout" runat="server" CssClass="uims-side-logout" CausesValidation="false" OnClick="btnLogout_Click">Log out</asp:LinkButton>
</div>
