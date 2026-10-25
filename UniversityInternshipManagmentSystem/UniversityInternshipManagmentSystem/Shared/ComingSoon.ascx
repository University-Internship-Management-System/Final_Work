<%@ Control Language="C#" %>
<%@ Import Namespace="UniversityInternshipManagmentSystem.Config" %>

<script runat="server">
    // A "coming soon" card for pages that are planned but not built yet.
    // Usage:  <uims:ComingSoon runat="server" PageTitle="..." Summary="..." Items="first|second|third" />
    public string PageTitle { get; set; }
    public string Summary { get; set; }
    public string Items { get; set; }     // what the page will do, separated by |

    protected string DashboardUrl
    {
        get { return ResolveUrl(AuthHelper.GetDashboardUrl(AuthHelper.UserRole)); }
    }
</script>

<div class="uims-soon">
    <h1 class="page-title uims-page-title"><%: PageTitle %></h1>

    <div class="card uims-soon-card">
        <span class="badge badge-pending">Coming soon</span>
        <h2>This page is not built yet</h2>
        <p class="text-muted mb-0"><%: Summary %></p>

        <% if (!string.IsNullOrEmpty(Items)) { %>
        <h3 class="small-label mt-4">What it will do</h3>
        <ul class="uims-soon-list">
            <% foreach (string item in Items.Split('|')) { %>
            <li><%: item %></li>
            <% } %>
        </ul>
        <% } %>

        <a class="btn btn-primary" href="<%= DashboardUrl %>">Back to dashboard</a>
    </div>
</div>
