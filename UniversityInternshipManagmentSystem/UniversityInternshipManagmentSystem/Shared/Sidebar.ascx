<%@ Control Language="C#" %>
<%@ Import Namespace="UniversityInternshipManagmentSystem.Config" %>

<script runat="server">
    // =====================================================================
    //  Role Menus (100% English):  "Link text|~/Folder/Page.aspx"
    //  Role retrieved from Session["role"] ("student", "company", "academic", "coordinator")
    // =====================================================================
    string[] GetMenu(string role)
    {
        switch (role)
        {
            case "student":
                return new[] {
                    "Dashboard|~/Student/StudentDashboardPage/Dashboard.aspx",
                    "My Profile|~/Student/StudentProfilePage/Profile.aspx",
                    "Browse Opportunities|~/Student/Opportunities/Opportunities.aspx",
                    "My Applications|~/Student/MyApplications/MyApplications.aspx",
                    "My Tasks|~/Student/StudentTasksPage/StudentTasksForm.aspx",
                    "My Progress|~/Student/MyProgress/MyProgress.aspx"
                };
            case "company":
                return new[] {
                    "Dashboard|~/Company/Dashboard.aspx",
                    "Manage Opportunities|~/Company/ManageOpportunities/ManageOpportunities.aspx",
                    "Applications|~/Company/ApplicationsReview/ApplicationsReview.aspx",
                    "My Trainees|~/Company/MyTrainees/MyTrainees.aspx",
                    "Tasks|~/Company/ManageTasks/ManageTasks.aspx",
                    "Final Evaluation|~/Company/FinalEvaluation/FinalEvaluation.aspx",
                    "Account|~/Company/SupervisorAccount/SupervisorAccount.aspx"
                };
            case "academic":
                return new[] {
                    "Dashboard|~/Academic/Dashboard.aspx",
                    "Student Progress|~/Academic/StudentProgress/StudentProgress.aspx",
                    "Final Evaluation|~/Academic/FinalEvaluation/FinalEvaluation.aspx",
                    "Account|~/Academic/SupervisorAccount/SupervisorAccount.aspx"
                };
            case "coordinator":
            case "admin":
                return new[] {
                    "Dashboard|~/Coordinator/CoordinatorDashbord/CoordinatorDashbord.aspx",
                    "Students|~/Coordinator/ManageStudents/ManageStudents.aspx",
                    "Companies|~/Coordinator/ManageCompanySupervisors/ManageCompanySupervisors.aspx",
                    "Academic Supervisors|~/Coordinator/ManageAcademicSupervisors/ManageAcademicSupervisors.aspx",
                    "Assign Supervisors|~/Coordinator/AssignAcademicSupervisors/AssignAcademicSupervisors.aspx",
                    "Monitor Progress|~/Coordinator/CoordinatorMonitor/CoordinatorMonitor.aspx",
                    "Completion Review|~/Coordinator/FinalCompletionReview/FinalCompletionReview.aspx",
                    "Contact Messages|~/Coordinator/ContactMessages/ContactMessages.aspx",
                    "Account|~/Coordinator/CoordinatorAccount/CoordinatorAccount.aspx"
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
        string currentPage = Request.AppRelativeCurrentExecutionFilePath ?? "";

        var html = new System.Text.StringBuilder();
        foreach (string item in GetMenu(role))
        {
            // Active on the exact page, on any page inside the same page folder
            // (so "My Tasks" stays highlighted on the week pages too),
            // or on any Dashboard page for the Dashboard link.
            string[] parts = item.Split('|');
            string folder = parts[1].Substring(0, parts[1].LastIndexOf('/'));
            bool active = currentPage.Equals(parts[1], StringComparison.OrdinalIgnoreCase)
                          || (folder.Split('/').Length > 2 && currentPage.StartsWith(folder + "/", StringComparison.OrdinalIgnoreCase))
                          || (parts[1].IndexOf("Dashboard", StringComparison.OrdinalIgnoreCase) >= 0
                              && currentPage.IndexOf("Dashboard", StringComparison.OrdinalIgnoreCase) >= 0);
            html.Append("<a class=\"uims-side-link" + (active ? " active" : "") + "\" href=\"" + ResolveUrl(parts[1]) + "\">"
                        + Server.HtmlEncode(parts[0]) + "</a>");
        }

        litLinks.Text = html.ToString();
        litRole.Text = GetRoleTitle(role);
        litName.Text = Server.HtmlEncode((Session["name"] as string) ?? "Not signed in");
    }

    protected void btnLogout_Click(object sender, EventArgs e)
    {
        AuthHelper.SignOut();
        Response.Redirect("~/login/Login.aspx?msg=" + Server.UrlEncode("You have been signed out successfully."), false);
        Context.ApplicationInstance.CompleteRequest();
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
    <asp:LinkButton ID="btnLogout" runat="server" CssClass="uims-side-logout" CausesValidation="false" OnClick="btnLogout_Click">Sign Out</asp:LinkButton>
</div>