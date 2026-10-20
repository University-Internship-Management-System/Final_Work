<%@ Control Language="C#" %>

<%-- Top navigation for the public pages (Home, About, Contact, Login) --%>
<nav class="navbar navbar-expand-lg uims-navbar">
    <div class="container">
        <a class="navbar-brand" runat="server" href="~/Default.aspx">
            <span class="uims-logo">UJ</span>
            <span>UIMS</span>
        </a>

        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#uimsNav"
            aria-controls="uimsNav" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
        </button>

        <div class="collapse navbar-collapse" id="uimsNav">
            <ul class="navbar-nav ms-auto align-items-lg-center gap-lg-2">
                <li class="nav-item"><a class="nav-link" runat="server" href="~/Default.aspx">Home</a></li>
                <li class="nav-item"><a class="nav-link" runat="server" href="~/About.aspx">About</a></li>
                <li class="nav-item"><a class="nav-link" runat="server" href="~/Contact.aspx">Contact</a></li>
                <%-- TODO: change this link to your real login page --%>
                <li class="nav-item ms-lg-2"><a class="btn btn-primary" runat="server" href="~/Login.aspx">Log in</a></li>
            </ul>
        </div>
    </div>
</nav>
