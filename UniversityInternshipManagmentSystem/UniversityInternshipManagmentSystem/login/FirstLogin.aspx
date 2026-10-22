<%@ Page Title="First-Time Login - UIMS" Language="C#" MasterPageFile="~/Shared/Public.Master" AutoEventWireup="true" CodeBehind="FirstLogin.aspx.cs" Inherits="UniversityInternshipManagmentSystem.login.FirstLogin" Async="true" %>

<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/login/css/login.css") %>" />
</asp:Content>

<asp:Content ID="Main" ContentPlaceHolderID="MainContent" runat="server">
    <div class="container py-4">
        <div class="card first-login-card p-4 p-md-5">
            <!-- Header Icon & Title -->
            <div class="text-center mb-4">
                <div class="stat-icon mx-auto mb-3">
                    <i class="bi bi-shield-lock-fill fs-2"></i>
                </div>
                <h4 class="fw-bold text-dark mb-1">First-Time Login Security Setup</h4>
                <p class="text-muted small">
                    Welcome to the Field Training Platform (KASIT).<br />
                    According to security policy, you must update your temporary password before proceeding.
                </p>
            </div>

            <!-- Alert Notification Panel -->
            <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="alert alert-danger small d-flex align-items-center gap-2 mb-3">
                <i class="bi bi-exclamation-triangle-fill fs-5"></i>
                <div><asp:Literal ID="litAlertMessage" runat="server" /></div>
            </asp:Panel>

            <!-- New Password Field -->
            <div class="mb-3">
                <label class="form-label fw-semibold">New Password <span class="text-danger">*</span></label>
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-lock"></i></span>
                    <asp:TextBox ID="txtNewPassword" runat="server" TextMode="Password" CssClass="form-control" placeholder="Enter new password" required="required" ClientIDMode="Static" />
                    <button class="btn btn-toggle-password" type="button" data-toggle-target="txtNewPassword" title="Show / Hide Password" aria-label="Toggle password visibility">
                        <i class="bi bi-eye"></i>
                    </button>
                </div>
                <span class="password-hint">Must be at least 6 characters long.</span>
            </div>

            <!-- Confirm New Password Field -->
            <div class="mb-4">
                <label class="form-label fw-semibold">Confirm New Password <span class="text-danger">*</span></label>
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-lock-fill"></i></span>
                    <asp:TextBox ID="txtConfirmPassword" runat="server" TextMode="Password" CssClass="form-control" placeholder="Re-enter new password" required="required" ClientIDMode="Static" />
                    <button class="btn btn-toggle-password" type="button" data-toggle-target="txtConfirmPassword" title="Show / Hide Password" aria-label="Toggle password visibility">
                        <i class="bi bi-eye"></i>
                    </button>
                </div>
            </div>

            <!-- Submit Button -->
            <div class="d-grid mb-3">
                <asp:Button ID="btnSavePassword" runat="server" Text="Save Password & Enter Dashboard" CssClass="btn btn-uj-primary btn-lg" OnClick="btnSavePassword_Click" />
            </div>

            <!-- Sign Out / Cancel Link -->
            <div class="text-center">
                <asp:LinkButton ID="btnCancelLogout" runat="server" CssClass="text-muted small text-decoration-none" CausesValidation="false" OnClick="btnCancelLogout_Click">
                    Sign Out and Return Later
                </asp:LinkButton>
            </div>
        </div>
    </div>

    <!-- External Module Script -->
    <script src="<%= ResolveUrl("~/login/javascript/login.js") %>"></script>
</asp:Content>
