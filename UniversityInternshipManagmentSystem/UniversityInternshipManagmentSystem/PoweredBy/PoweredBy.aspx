<%@ Page Language="C#" %>

<%@ Import Namespace="UniversityInternshipManagmentSystem.Config" %>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Powered by · The UIMS team</title>
    <meta name="description" content="Seven people. One vision. Meet the people behind UIMS.">
    <link rel="stylesheet" href="system-bootstrap.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link rel="stylesheet" href="system-shell.css">
    <link rel="stylesheet" href="styles.css">
    <link rel="stylesheet" href="uims-theme.css">
    <script src="team.js?v=e99afb57af1f" defer></script>
    <script src="system-shell.js" defer></script>
</head>
<body id="top">
    <header class="uims-navbar-wrapper" id="uimsNavbar">
        <div class="uims-container uims-nav-container">
            <a href="<%= ResolveUrl("~/index.aspx") %>#home" class="uims-brand" aria-label="The University of Jordan - UIMS Home">
                <img src="images/university-logo.png" alt="The University of Jordan Logo" class="uims-brand-logo" />
                <div class="uims-brand-text">
                    <span class="uims-brand-title">The University of Jordan</span>
                    <span class="uims-brand-subtitle">Internship Management System</span>
                </div>
            </a>

            <nav aria-label="Main Navigation">
                <ul class="uims-nav-menu" id="uimsNavMenu">
                    <li><a href="<%= ResolveUrl("~/index.aspx") %>#home" class="uims-nav-link">Home</a></li>
                    <li><a href="<%= ResolveUrl("~/index.aspx") %>#about" class="uims-nav-link">About</a></li>
                    <li><a href="<%= ResolveUrl("~/index.aspx") %>#how-it-works" class="uims-nav-link">How It Works</a></li>
                    <li><a href="<%= ResolveUrl("~/index.aspx") %>#roles" class="uims-nav-link">Portals</a></li>
                    <li><a href="<%= ResolveUrl("~/index.aspx") %>#opportunities" class="uims-nav-link">Internships</a></li>
                    <li><a href="<%= ResolveUrl("~/index.aspx") %>#faq" class="uims-nav-link">FAQ</a></li>
                    <li><a href="#team" class="uims-nav-link active" aria-current="page">Our Team</a></li>
                    <li><a href="#contact" class="uims-nav-link">Contact</a></li>
                </ul>
            </nav>

            <div class="uims-nav-actions">

                <a class="uims-btn uims-btn--outline-white" href="<%= ResolveUrl(AuthHelper.IsAuthenticated ? AuthHelper.GetDashboardUrl(AuthHelper.UserRole) : "~/login/Login.aspx") %>">
                    <span><%: AuthHelper.IsAuthenticated ? "My Dashboard" : "Sign In" %></span>
                    <i class="bi bi-arrow-up-right"></i>
                </a>
                <button type="button" class="uims-nav-toggle" id="uimsNavToggle" aria-label="Toggle navigation menu" aria-expanded="false">
                    <i class="bi bi-list"></i>
                </button>
            </div>
        </div>
    </header>
    <main>
        <section class="intro" aria-labelledby="intro-title">
            <div class="intro-label"><span class="section-number">UIMS / THE PEOPLE BEHIND IT</span><span class="edition">SEVEN MINDS. ONE VISION.</span></div>
            <h1 id="intro-title">Powered by <span>Orange</span></h1>
            <div class="intro-bottom">
                <p>A shared idea. Seven different perspectives.<br>
                    One team turning an internship project into a connected experience.</p>
                <a href="#team" class="discover">Discover the team <span aria-hidden="true">↓</span></a></div>
            <span class="intro-outline" aria-hidden="true">07</span></section>
        <section class="training-company" aria-labelledby="company-title">
            <div class="company-eyebrow">OUR TRAINING COMPANY</div>
            <img src="images/orange-logo.svg" alt="Orange" width="88" height="88"><h2 id="company-title">Learning. Building. <span>Growing together.</span></h2>
            <p>Developed during our training experience at <strong>Orange.</strong><br>
                A place to connect ideas, put learning into practice, and build as a team.</p>
            <a href="#team" class="company-team-link">Meet the people behind the project <span aria-hidden="true">↓</span></a></section>
        <section class="team" id="team" aria-labelledby="team-title">
            <div class="section-top">
                <div class="section-number">01 / MEET THE TEAM</div>
                <h2 id="team-title">Seven people.<br>
                    <span class="accent">One vision.</span></h2>
                <p>The people behind the project.<br>
                    Different strengths, brought together by a shared ambition.</p>
                <span class="interaction-hint">EXPLORE EACH PORTRAIT <span aria-hidden="true">↗</span></span></div>
            <div class="team-grid" id="team-grid"></div>
            <p class="pending-note">Hover or tap a portrait to explore profiles.</p>
        </section>
        <section class="statement">
            <p class="section-number">BUILT TOGETHER</p>
            <h2>It starts with an idea.<br>
                It happens with <span>people.</span></h2>
            <div class="statement-bottom">
                <p>Curiosity connects us. Collaboration moves us.<br>
                    And every detail has a person behind it.</p>
                <a href="#top" class="discover">Back to top <span aria-hidden="true">↗</span></a></div>
        </section>
    </main>
    <footer class="uims-footer" id="contact">
        <div class="uims-container">
            <div class="uims-footer-grid">
                <!-- Col 1: About University -->
                <div>
                    <h4 class="uims-footer-col-title">The University of Jordan</h4>
                    <p class="uims-footer-desc">
                        King Abdullah II School of Information Technology (KASIT). Delivering world-class computing education and pioneering regional research since 1962.
                    </p>
                    <div class="d-flex align-items-center gap-2">
                        <span class="uims-badge uims-badge--mint">
                            <i class="bi bi-patch-check-fill"></i>Official Portal
                        </span>
                    </div>
                </div>

                <!-- Col 2: Navigation Links -->
                <div>
                    <h4 class="uims-footer-col-title">Quick Navigation</h4>
                    <ul class="uims-footer-links">
                        <li><a href="<%= ResolveUrl("~/index.aspx") %>#home">Home Portal</a></li>
                        <li><a href="<%= ResolveUrl("~/index.aspx") %>#about">About the System</a></li>
                        <li><a href="<%= ResolveUrl("~/index.aspx") %>#how-it-works">How It Works</a></li>
                        <li><a href="<%= ResolveUrl("~/index.aspx") %>#roles">Stakeholder Portals</a></li>
                        <li><a href="<%= ResolveUrl("~/index.aspx") %>#opportunities">Internship Directory</a></li>
                        <li><a href="<%= ResolveUrl("~/index.aspx") %>#faq">Frequently Asked Questions</a></li>
                    </ul>
                </div>

                <!-- Col 3: Contact Details -->
                <div>
                    <h4 class="uims-footer-col-title">Contact Information</h4>
                    <div class="uims-footer-contact-item">
                        <i class="bi bi-geo-alt-fill"></i>
                        <span>Queen Rania Street, Amman, Jordan</span>
                    </div>
                    <div class="uims-footer-contact-item">
                        <i class="bi bi-telephone-fill"></i>
                        <span>+962 6 5355000 Ext. 22000</span>
                    </div>
                    <div class="uims-footer-contact-item">
                        <i class="bi bi-envelope-fill"></i>
                        <span>kasit.training@ju.edu.jo</span>
                    </div>
                    <div class="uims-footer-contact-item">
                        <i class="bi bi-globe"></i>
                        <a href="https://www.ju.edu.jo" target="_blank" rel="noopener noreferrer">www.ju.edu.jo</a>
                    </div>
                </div>

                <!-- Col 4: Campus Map -->
                <div>
                    <h4 class="uims-footer-col-title">Campus Location</h4>
                    <div class="uims-footer-map">
                        <iframe title="University of Jordan Location on Map" src="https://maps.google.com/maps?q=University%20of%20Jordan%2C%20Amman&amp;z=15&amp;output=embed" loading="lazy" referrerpolicy="no-referrer-when-downgrade" allowfullscreen></iframe>
                    </div>
                    <a href="https://www.google.com/maps/search/?api=1&amp;query=University%20of%20Jordan%2C%20Amman" target="_blank" rel="noopener noreferrer" class="small text-decoration-underline text-light">Open in Google Maps <i class="bi bi-box-arrow-up-right ms-1"></i>
                    </a>
                </div>
            </div>


            <div class="uims-footer-bottom">
                <div>
                    &copy; 2026 The University of Jordan - King Abdullah II School of Information Technology (KASIT). All rights reserved.
                </div>
                <div class="d-flex align-items-center gap-3">
                    <a href="<%= ResolveUrl("~/Contact.aspx") %>" class="text-light">Contact Us</a>
                    <span>&bull;</span>
                    <a href="<%= ResolveUrl(AuthHelper.IsAuthenticated ? AuthHelper.GetDashboardUrl(AuthHelper.UserRole) : "~/login/Login.aspx") %>" class="text-light"><%: AuthHelper.IsAuthenticated ? "My Dashboard" : "Sign In Portal" %></a>
                </div>
            </div>
        </div>
    </footer>
</body>
</html>
