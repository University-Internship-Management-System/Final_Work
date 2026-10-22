<%@ Page Title="First-Time Login - UIMS" Language="C#" MasterPageFile="~/Shared/Public.Master" AutoEventWireup="true" CodeBehind="FirstLogin.aspx.cs" Inherits="UniversityInternshipManagmentSystem.login.FirstLogin" Async="true" %>

<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/login/css/login.css") %>" />
</asp:Content>

<asp:Content ID="Main" ContentPlaceHolderID="MainContent" runat="server">
    <%-- Full-screen background (see login.css). The navigation bar is hidden on this page by Shared/Public.Master. --%>
    <div class="auth-bg" aria-hidden="true">
        <span class="auth-blob b1"></span><span class="auth-blob b2"></span><span class="auth-blob b3"></span>
        <span class="auth-ring r1"></span><span class="auth-ring r2"></span><span class="auth-ring r3"></span><span class="auth-ring r4"></span>
    </div>

    <div class="auth-wrap">
        <div class="auth-card wide">
            <!-- Header Icon & Title -->
            <div class="auth-brand">
                <div class="auth-icon"><i class="bi bi-shield-lock-fill"></i></div>
                <div><span class="auth-eyebrow">One last step</span></div>
                <h1 class="auth-title">Choose your own password</h1>
                <p class="auth-sub">
                    Welcome to the Field Training Platform (KASIT).<br />
                    For your security, replace the temporary password before you continue.
                </p>
            </div>

            <!-- Alert Notification Panel -->
            <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="alert alert-danger small d-flex align-items-center gap-2 mb-3">
                <i class="bi bi-exclamation-triangle-fill fs-5"></i>
                <div><asp:Literal ID="litAlertMessage" runat="server" /></div>
            </asp:Panel>

            <!-- New Password Field -->
            <div class="mb-3">
                <label class="form-label" for="txtNewPassword">New password</label>
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-lock"></i></span>
                    <asp:TextBox ID="txtNewPassword" runat="server" TextMode="Password" CssClass="form-control" placeholder="Enter a new password" required="required" ClientIDMode="Static" />
                    <button class="btn btn-toggle-password" type="button" data-toggle-target="txtNewPassword" title="Show / Hide Password" aria-label="Toggle password visibility">
                        <i class="bi bi-eye"></i>
                    </button>
                </div>
                <div class="pw-meter" aria-hidden="true"><span id="pwMeterBar"></span></div>
                <div class="pw-meter-text" id="pwMeterText">At least 6 characters. Longer is stronger.</div>
            </div>

            <!-- Confirm New Password Field -->
            <div class="mb-4">
                <label class="form-label" for="txtConfirmPassword">Confirm new password</label>
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-lock-fill"></i></span>
                    <asp:TextBox ID="txtConfirmPassword" runat="server" TextMode="Password" CssClass="form-control" placeholder="Re-enter the new password" required="required" ClientIDMode="Static" />
                    <button class="btn btn-toggle-password" type="button" data-toggle-target="txtConfirmPassword" title="Show / Hide Password" aria-label="Toggle password visibility">
                        <i class="bi bi-eye"></i>
                    </button>
                </div>
                <div class="pw-match" id="pwMatch" aria-live="polite"></div>
            </div>

            <!-- Submit Button -->
            <div class="d-grid mb-3">
                <asp:Button ID="btnSavePassword" runat="server" Text="Save password and continue" CssClass="btn btn-uj-primary btn-lg" OnClick="btnSavePassword_Click" />
            </div>

            <!-- Sign Out / Cancel Link -->
            <div class="text-center">
                <asp:LinkButton ID="btnCancelLogout" runat="server" CssClass="auth-link" CausesValidation="false" OnClick="btnCancelLogout_Click">
                    Sign out and return later
                </asp:LinkButton>
            </div>

            <div class="auth-secure"><i class="bi bi-shield-check"></i> Your password is stored securely by Firebase Authentication</div>
        </div>
    </div>

    <!-- External Module Script -->
    <script src="<%= ResolveUrl("~/login/javascript/login.js") %>"></script>
</asp:Content>
