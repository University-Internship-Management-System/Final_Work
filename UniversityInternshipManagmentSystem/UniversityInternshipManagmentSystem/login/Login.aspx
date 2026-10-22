<%@ Page Title="Login - UIMS" Language="C#" MasterPageFile="~/Shared/Public.Master" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="UniversityInternshipManagmentSystem.login.Login" Async="true" %>

<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/login/css/login.css") %>" />
</asp:Content>

<asp:Content ID="Main" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container py-4">
        <div class="card login-card p-4 p-md-5">
            <!-- Header Brand & Title -->
            <div class="text-center mb-4">
                <img src="<%= ResolveUrl("~/login/images/uj-logo.png") %>" alt="University of Jordan Logo" class="login-logo mb-2" />
                <h4 class="fw-bold text-uj-green mb-1">Unified Login Portal</h4>
                <p class="text-muted small">King Abdullah II School of Information Technology (KASIT)</p>
            </div>

            <!-- Error Notification Panel -->
            <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="alert alert-danger d-flex align-items-center gap-2 small mb-3">
                <i class="bi bi-exclamation-octagon-fill fs-5"></i>
                <div><asp:Literal ID="litErrorMsg" runat="server" /></div>
            </asp:Panel>

            <!-- Success Notification Panel -->
            <asp:Panel ID="pnlSuccess" runat="server" Visible="false" CssClass="alert alert-success d-flex align-items-center gap-2 small mb-3">
                <i class="bi bi-check-circle-fill fs-5"></i>
                <div><asp:Literal ID="litSuccessMsg" runat="server" /></div>
            </asp:Panel>

            <!-- Email Address Field -->
            <div class="mb-3">
                <label class="form-label fw-semibold">University Email Address <span class="text-danger">*</span></label>
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-envelope"></i></span>
                    <asp:TextBox ID="txtEmail" runat="server" TextMode="Email" CssClass="form-control" placeholder="name@ju.edu.jo" required="required" ClientIDMode="Static" />
                </div>
            </div>

            <!-- Password Field with Show/Hide Toggle -->
            <div class="mb-3">
                <div class="d-flex justify-content-between align-items-center mb-1">
                    <label class="form-label fw-semibold mb-0">Password <span class="text-danger">*</span></label>
                    <button type="button" class="btn-forgot-password" id="btnOpenForgotModal">Forgot Password?</button>
                </div>
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-lock"></i></span>
                    <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" CssClass="form-control" placeholder="••••••••••••" required="required" ClientIDMode="Static" />
                    <button class="btn btn-toggle-password" type="button" data-toggle-target="txtPassword" title="Show / Hide Password" aria-label="Toggle password visibility">
                        <i class="bi bi-eye"></i>
                    </button>
                </div>
            </div>

            <!-- Submit Button -->
            <div class="d-grid gap-2 mt-4">
                <asp:Button ID="btnLogin" runat="server" Text="Sign In" CssClass="btn btn-uj-primary btn-lg" OnClick="btnLogin_Click" />
            </div>

            <hr class="my-4 text-muted" />

        </div>
    </div>

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
                    <asp:Button ID="btnSendRecovery" runat="server" Text="Send Reset Link" CssClass="btn btn-uj-primary" OnClick="btnSendRecovery_Click" />
                </div>
            </div>
        </div>
    </div>

    <!-- External Module Script -->
    <script src="<%= ResolveUrl("~/login/javascript/login.js") %>"></script>
</asp:Content>
