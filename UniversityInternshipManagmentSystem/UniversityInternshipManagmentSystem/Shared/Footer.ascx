<%@ Control Language="C#" %>
<script runat="server">
    protected bool IsAuthPage = false;
    protected void Page_Load(object sender, EventArgs e)
    {
        string path = Page.AppRelativeVirtualPath ?? "";
        IsAuthPage = path.StartsWith("~/login/", StringComparison.OrdinalIgnoreCase);
    }
</script>

<footer class="uims-footer mt-auto py-3">
    <div class="container-fluid px-lg-4">
        <div class="uims-footer-inner d-flex flex-column flex-md-row justify-content-between align-items-center gap-2">
            <div class="d-flex align-items-center gap-2 text-center text-md-start">
                <span>&copy; <%: DateTime.Now.Year %> The University of Jordan &middot; King Abdullah II School of Information Technology (KASIT)</span>
            </div>
            <div class="d-flex align-items-center gap-3">
                <a href="<%= ResolveUrl("~/index.aspx") %>">Home</a>
                <% if (!IsAuthPage) { %>
                <a href="<%= ResolveUrl("~/About.aspx") %>">About KASIT</a>
                <% } %>
                <a href="<%= ResolveUrl("~/Contact.aspx") %>">Contact Us</a>
                <% if (!IsAuthPage) { %>
                <a href="<%= ResolveUrl("~/login/Login.aspx") %>">Login Portal</a>
                <% } %>
            </div>
        </div>
    </div>
</footer>
