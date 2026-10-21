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
                return new[] {
                    "Dashboard|~/Coordinator/Dashboard.aspx",
                    "Students|~/Coordinator/ManageStudents/ManageStudents.aspx",
                    "Companies|~/Coordinator/ManageCompanySupervisors/ManageCompanySupervisors.aspx",
                    "Academic Supervisors|~/Coordinator/ManageAcademicSupervisors/ManageAcademicSupervisors.aspx",
                    "Assign Supervisors|~/Coordinator/AssignAcademicSupervisors/AssignAcademicSupervisors.aspx",
                    "Monitor Progress|~/Coordinator/Monitor.aspx",
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
            case "coordinator": return "Coordinator";
            default: return "Guest";
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        string role = ((Session["role"] as string) ?? "").ToLower();
        string currentPage = Request.AppRelativeCurrentExecutionFilePath;

        var html = new System.Text.StringBuilder();
        foreach (string item in GetMenu(role))
        {
            string[] parts = item.Split('|');
            bool active = currentPage.Equals(parts[1], StringComparison.OrdinalIgnoreCase);
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
