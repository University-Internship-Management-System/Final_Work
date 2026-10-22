<%@ Page Title="Login - UIMS" Language="C#" MasterPageFile="~/Shared/Public.Master" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="UniversityInternshipManagmentSystem.login.Login" Async="true" %>

<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server">
    <!-- Google Fonts: Inter -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet" />
    <link rel="stylesheet" href="<%= ResolveUrl("~/login/css/login.css") %>" />

    <style>
        /* ==========================================================================
           Viewport & Zero-Scroll Layout Constraints
           ========================================================================== */
        html, body {
            height: 100% !important;
            margin: 0 !important;
            padding: 0 !important;
            overflow-x: hidden !important;
        }

        @media (min-height: 560px) {
            body {
                height: 100vh !important;
                max-height: 100vh !important;
                overflow-y: hidden !important;
            }
            #form1 {
                height: 100vh !important;
                max-height: 100vh !important;
                display: flex !important;
                flex-direction: column !important;
                overflow: hidden !important;
            }
            main {
                flex: 1 1 auto !important;
                display: flex !important;
                flex-direction: column !important;
                min-height: 0 !important;
                overflow: hidden !important;
            }
        }

        /* ==========================================================================
           Home Page Topbar Navigation (Login Page Customization)
           ========================================================================== */
        .topbar {
            height: 68px !important;
            background: linear-gradient(115deg, #043629, #07523e) !important;
            color: #ffffff !important;
            position: sticky;
            top: 0;
            z-index: 1030;
            box-shadow: 0 3px 15px rgba(0, 27, 21, 0.15);
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            flex-shrink: 0;
        }

        .topbar .nav {
            height: 100%;
            display: flex;
            align-items: center;
            gap: 20px;
            flex-wrap: nowrap;
            padding: 0;
            margin: 0 auto;
        }

        .topbar .container,
        .footer .container {
            width: min(1180px, calc(100% - 44px));
            max-width: 1180px;
            margin: auto;
        }

        .topbar .brand {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-right: auto;
            margin-left: 0;
            text-decoration: none !important;
            color: #ffffff !important;
        }

        .topbar .brand-logo {
            width: 48px !important;
            height: 54px !important;
            max-width: 48px !important;
            max-height: 54px !important;
            object-fit: contain;
            flex-shrink: 0;
            display: inline-block;
        }

        .topbar .brand-title {
            display: block;
            font-weight: 900;
            font-size: 17px;
            line-height: 1.3;
            white-space: nowrap;
            color: #ffffff !important;
        }

        .topbar .brand-sub {
            display: block;
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            font-size: 10px;
            opacity: .88;
            letter-spacing: .1px;
            color: #ffffff !important;
        }

        .topbar .navlinks {
            display: flex;
            align-items: center;
            gap: 26px;
            margin-left: auto;
            margin-right: 0;
            list-style: none;
            padding: 0;
            margin-bottom: 0;
        }

        .topbar .navlinks a {
            font-size: 13px;
            font-weight: 700;
            opacity: .89;
            position: relative;
            white-space: nowrap;
            color: #ffffff !important;
            text-decoration: none !important;
            transition: opacity 0.2s ease;
        }

        .topbar .navlinks a:hover,
        .topbar .navlinks a.active {
            opacity: 1;
            color: #ffffff !important;
        }

        .topbar .navlinks a.active:after {
            content: '';
            position: absolute;
            right: 0;
            left: 0;
            bottom: -10px;
            height: 2px;
            background: #ffffff;
        }

        .topbar .menu-toggle {
            display: none;
            margin-left: auto;
            margin-right: 0;
            color: #ffffff;
            border: 1px solid rgba(255, 255, 255, 0.42);
            background: transparent;
            border-radius: 7px;
            font-size: 22px;
            width: 38px;
            height: 36px;
            align-items: center;
            justify-content: center;
            cursor: pointer;
        }

        /* ==========================================================================
           Compact Login Card & Layout (Zero Scroll Optimization)
           ========================================================================== */
        .login-card {
            max-width: 440px !important;
            margin: auto !important;
            padding: 1.5rem 2rem !important;
            border: 1px solid var(--uj-border-color) !important;
            border-top: 5px solid var(--uj-green) !important;
            border-radius: var(--uj-radius);
            box-shadow: var(--uj-shadow-md);
            background: #ffffff;
        }

        .login-logo {
            max-height: 55px !important;
            height: 55px !important;
            width: auto;
            object-fit: contain;
            display: inline-block;
        }

        /* ==========================================================================
           Single-Line Institutional Footer
           ========================================================================== */
        .footer {
            background: #04382d !important;
            color: #adcbbe !important;
            padding: 10px 0 !important;
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            margin-top: auto;
            flex-shrink: 0;
        }

        .copyright {
            border-top: none !important;
            margin-top: 0 !important;
            padding-top: 0 !important;
            color: #adcbbe !important;
            text-align: center;
            font-size: 11.5px;
            line-height: 1.4;
        }

        /* Responsive Breakpoints */
        @media (max-width: 750px) {
            .topbar {
                height: 64px !important;
            }
            .topbar .nav {
                gap: 8px;
            }
            .topbar .brand-logo {
                width: 38px !important;
                height: 44px !important;
            }
            .topbar .brand-title {
                font-size: 13px;
            }
            .topbar .brand-sub {
                font-size: 7.5px;
            }
            .topbar .menu-toggle {
                display: flex;
            }
            .topbar .navlinks {
                display: none;
                position: absolute;
                left: 0;
                right: 0;
                top: 64px;
                padding: 15px 20px;
                background: #04382d;
                box-shadow: 0 12px 20px rgba(0, 0, 0, 0.15);
                flex-direction: column;
                align-items: flex-start;
                gap: 16px;
                z-index: 1050;
            }
            .topbar .navlinks.open {
                display: flex;
            }
        }
    </style>
</asp:Content>

<asp:Content ID="Main" ContentPlaceHolderID="MainContent" runat="server">
    <!-- Topbar Navigation pulled from Home Page (without Login button) -->
    <header class="topbar">
        <div class="container nav">
            <a aria-label="Home page" class="brand" href="<%= ResolveUrl("~/index.aspx#home") %>">
                <img alt="University of Jordan logo" class="brand-logo" src="<%= ResolveUrl("~/Assets/PublicHome/university-logo.png") %>" width="48" height="54" style="width: 48px !important; height: 54px !important; max-width: 48px !important; max-height: 54px !important; object-fit: contain; flex-shrink: 0;" />
                <span>
                    <span class="brand-title">The University of Jordan</span>
                    <span class="brand-sub">The University of Jordan</span>
                </span>
            </a>
            <nav aria-label="Main navigation" class="navlinks" id="navlinks">
                <a href="<%= ResolveUrl("~/index.aspx#home") %>">Home</a>
                <a href="<%= ResolveUrl("~/index.aspx#opportunities") %>">Internships</a>
                <a href="<%= ResolveUrl("~/index.aspx#about") %>">About</a>
                <a href="<%= ResolveUrl("~/index.aspx#faq") %>">FAQ</a>
                <a href="<%= ResolveUrl("~/Contact.aspx") %>">Contact Us</a>
                <% if (IsSignedIn) { %><a href="<%= ResolveUrl("~/login/Logout.aspx") %>">Sign out</a><% } %>
            </nav>
            <button type="button" aria-controls="navlinks" aria-expanded="false" aria-label="Open menu" class="menu-toggle" id="menuToggle">☰</button>
        </div>
    </header>

    <!-- Center Content Area (Fill available height with zero scroll) -->
    <div class="container py-2 flex-grow-1 d-flex flex-column justify-content-center">
        <div class="card login-card my-auto">
            <!-- Header Brand & Title -->
            <div class="text-center mb-3">
                <img src="<%= ResolveUrl("~/login/images/uj-logo.png") %>" alt="University of Jordan Logo" class="login-logo mb-2" height="55" style="max-height: 55px; width: auto;" />
                <h5 class="fw-bold text-uj-green mb-1">Unified Login Portal</h5>
                <p class="text-muted small mb-0" style="font-size: 0.78rem;">King Abdullah II School of Information Technology (KASIT)</p>
            </div>

            <!-- Error Notification Panel -->
            <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="alert alert-danger d-flex align-items-center gap-2 small p-2 mb-2">
                <i class="bi bi-exclamation-octagon-fill fs-5"></i>
                <div><asp:Literal ID="litErrorMsg" runat="server" /></div>
            </asp:Panel>

            <!-- Success Notification Panel -->
            <asp:Panel ID="pnlSuccess" runat="server" Visible="false" CssClass="alert alert-success d-flex align-items-center gap-2 small p-2 mb-2">
                <i class="bi bi-check-circle-fill fs-5"></i>
                <div><asp:Literal ID="litSuccessMsg" runat="server" /></div>
            </asp:Panel>

            <!-- Email Address Field -->
            <div class="mb-2">
                <label class="form-label fw-semibold small mb-1">University Email Address <span class="text-danger">*</span></label>
                <div class="input-group">
                    <span class="input-group-text py-1 px-2"><i class="bi bi-envelope"></i></span>
                    <asp:TextBox ID="txtEmail" runat="server" TextMode="Email" CssClass="form-control" placeholder="name@ju.edu.jo" required="required" ClientIDMode="Static" />
                </div>
            </div>

            <!-- Password Field with Show/Hide Toggle -->
            <div class="mb-3">
                <div class="d-flex justify-content-between align-items-center mb-1">
                    <label class="form-label fw-semibold small mb-0">Password <span class="text-danger">*</span></label>
                    <button type="button" class="btn-forgot-password" id="btnOpenForgotModal">Forgot Password?</button>
                </div>
                <div class="input-group">
                    <span class="input-group-text py-1 px-2"><i class="bi bi-lock"></i></span>
                    <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" CssClass="form-control" placeholder="••••••••••••" required="required" ClientIDMode="Static" />
                    <button class="btn btn-toggle-password" type="button" data-toggle-target="txtPassword" title="Show / Hide Password" aria-label="Toggle password visibility">
                        <i class="bi bi-eye"></i>
                    </button>
                </div>
            </div>

            <!-- Submit Button -->
            <div class="d-grid gap-2 mt-2">
                <asp:Button ID="btnLogin" runat="server" Text="Sign In" CssClass="btn btn-uj-primary" OnClick="btnLogin_Click" />
            </div>
        </div>
    </div>

    <!-- Institutional Footer (Single Line Copyright Only) -->
    <footer class="footer">
        <div class="container text-center">
            <div class="copyright">© <span id="year"><%: DateTime.Now.Year %></span> Internship Management System — a student prototype, not an official University of Jordan website.</div>
        </div>
    </footer>

    <!-- Password Recovery Modal (Firebase Auth Password Recovery) -->
    <div class="modal fade" id="forgotModal" tabindex="-1" aria-labelledby="forgotModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content modal-forgot-card">
                <div class="modal-header bg-uj-green text-white">
                    <h5 class="modal-title fw-bold" id="forgotModalLabel">
                        <i class="bi bi-key-fill me-2"></i> Reset Password
                    </h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body p-4">
                    <p class="text-muted small mb-3">
                        Enter your registered university email address to receive a secure password reset link via Firebase Authentication.
                    </p>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">University Email Address</label>
                        <asp:TextBox ID="txtRecoveryEmail" runat="server" CssClass="form-control" TextMode="Email" placeholder="name@ju.edu.jo" ClientIDMode="Static" />
                    </div>

                    <asp:Panel ID="pnlRecoveryResult" runat="server" Visible="false" CssClass="alert alert-info small p-2 mt-2">
                        <asp:Literal ID="litRecoveryMsg" runat="server" />
                    </asp:Panel>
                </div>
                <div class="modal-footer bg-light">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                    <%-- formnovalidate: the sign-in fields behind this popup are "required" and empty; without it the browser blocks this button --%>
                    <asp:Button ID="btnSendRecovery" runat="server" Text="Send Reset Link" CssClass="btn btn-uj-primary" OnClick="btnSendRecovery_Click" formnovalidate="formnovalidate" />
                </div>
            </div>
        </div>
    </div>

    <!-- External Module Script -->
    <script src="<%= ResolveUrl("~/login/javascript/login.js") %>"></script>
</asp:Content>
