<%@ Control Language="C#" %>
<%@ Import Namespace="UniversityInternshipManagmentSystem.Config" %>
<%
    string currentPath = Request.AppRelativeCurrentExecutionFilePath ?? string.Empty;
    bool isHome = currentPath.Equals("~/Default.aspx", StringComparison.OrdinalIgnoreCase) || currentPath.Equals("~/", StringComparison.OrdinalIgnoreCase);
    bool isAbout = currentPath.IndexOf("About", StringComparison.OrdinalIgnoreCase) >= 0;
    bool isContact = currentPath.IndexOf("Contact", StringComparison.OrdinalIgnoreCase) >= 0;
%>

<nav class="navbar navbar-expand-lg uims-navbar sticky-top bg-white border-bottom shadow-sm py-2">
    <div class="container-fluid px-lg-4">
        <a class="navbar-brand d-flex align-items-center gap-2" href="<%= ResolveUrl("~/index.aspx") %>">
            <img src="<%= ResolveUrl("~/Assets/PublicHome/university-logo.png") %>" alt="UJ Logo" height="46" style="width: auto;" />
            <div class="brand-text">
                <div class="h6 fw-bold text-uj-green mb-0">Field Training System (UIMS)</div>
                <small class="text-muted d-block" style="font-size: 0.76rem;">King Abdullah II School of Information Technology - The University of Jordan</small>
            </div>
        </a>

        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarMain"
            aria-controls="navbarMain" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
        </button>

        <div class="collapse navbar-collapse" id="navbarMain">
            <ul class="navbar-nav ms-auto mb-2 mb-lg-0 align-items-lg-center gap-lg-2">
                <li class="nav-item">
                    <a class="nav-link fw-semibold <%= isHome ? "active text-uj-green" : "" %>" href="<%= ResolveUrl("~/index.aspx") %>">
                        <i class="bi bi-house-door me-1"></i> Home
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link fw-semibold <%= isAbout ? "active text-uj-green" : "" %>" href="<%= ResolveUrl("~/About.aspx") %>">
                        <i class="bi bi-info-circle me-1"></i> About KASIT & UIMS
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link fw-semibold <%= isContact ? "active text-uj-green" : "" %>" href="<%= ResolveUrl("~/Contact.aspx") %>">
                        <i class="bi bi-envelope me-1"></i> Contact Us
                    </a>
                </li>

                <% if (AuthHelper.IsAuthenticated) { %>
                    <li class="nav-item ms-lg-2">
                        <a class="btn btn-uj-primary" href="<%= ResolveUrl(AuthHelper.GetDashboardUrl(AuthHelper.UserRole)) %>">
                            <i class="bi bi-speedometer2 me-1"></i> Dashboard
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="btn btn-outline-danger btn-sm" href="<%= ResolveUrl("~/login/Logout.aspx") %>" title="Log out">
                            <i class="bi bi-box-arrow-right me-1"></i> Logout
                        </a>
                    </li>
                <% } else { %>
                    <li class="nav-item ms-lg-2">
                        <a class="btn btn-uj-primary d-inline-flex align-items-center gap-1 px-3" href="<%= ResolveUrl("~/login/Login.aspx") %>">
                            <i class="bi bi-box-arrow-in-right"></i>
                            <span>Login Portal</span>
                        </a>
                    </li>
                <% } %>
            </ul>
        </div>
    </div>
</nav>
