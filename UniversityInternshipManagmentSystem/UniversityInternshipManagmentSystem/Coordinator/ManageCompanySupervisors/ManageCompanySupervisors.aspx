<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ManageCompanySupervisors.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Coordinator.ManageCompanySupervisorsPage" MasterPageFile="~/Shared/Dashboard.Master" %>
<asp:Content ID="head" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="company-supervisors.css" />
</asp:Content>
<asp:Content ID="content" ContentPlaceHolderID="MainContent" runat="server">
    <header class="company-heading">
        <div><p class="company-eyebrow">COORDINATOR / ACCOUNT MANAGEMENT</p><h1 class="page-title">Company supervisors</h1><p class="text-muted">Manage company contacts and supervisor accounts.</p></div>
        <a class="btn btn-primary" href="#companyEditor" id="addCompany">Add supervisor</a>
    </header>
    <p class="company-preview" role="note">Interface preview. You can fill in and review the form; accounts are not saved yet.</p>
    <div class="company-grid">
        <section class="card company-card" aria-labelledby="directoryTitle">
            <div class="company-section-heading"><div><h2 id="directoryTitle">Company directory</h2><p class="text-muted">Supervisor details and account access.</p></div><span class="company-count">0 accounts loaded</span></div>
            <div class="company-tools"><div><label for="companySearch">Search companies or supervisors</label><input type="search" id="companySearch" class="form-control" placeholder="Search name, company or email" disabled /></div><div><label for="statusFilter">Account status</label><select id="statusFilter" class="form-select" disabled><option>All statuses</option><option>Active</option><option>Inactive</option></select></div></div>
            <div class="table-responsive"><table class="table company-table"><thead><tr><th scope="col">Company / Supervisor</th><th scope="col">Location</th><th scope="col">Status</th><th scope="col">Actions</th></tr></thead><tbody><tr><td colspan="4"><div class="company-empty"><span class="company-empty-icon" aria-hidden="true">C</span><h3>No company accounts loaded</h3><p>Company records, editing and account activation will be available when this page is connected to Firebase.</p><a href="#companyEditor" class="btn btn-outline-primary">Prepare a supervisor account</a></div></td></tr></tbody></table></div>
        </section>
        <section id="companyEditor" class="card company-card" aria-labelledby="editorTitle">
            <p class="company-eyebrow">NEW ACCOUNT</p><h2 id="editorTitle">Add company supervisor</h2><p class="text-muted">This account will have the Company Supervisor role.</p>
            <fieldset class="company-fields"><legend>Supervisor details</legend>
                <label for="supervisorName">Full name <span aria-hidden="true">*</span></label><input id="supervisorName" class="form-control" autocomplete="name" maxlength="100" minlength="2" required />
                <label for="loginEmail">Login email <span aria-hidden="true">*</span></label><input id="loginEmail" type="email" class="form-control" autocomplete="email" maxlength="254" required /><small>The supervisor will use this email to sign in.</small>
                <label for="phoneNumber">Phone number <span aria-hidden="true">*</span></label><input id="phoneNumber" type="tel" class="form-control" autocomplete="tel" maxlength="25" pattern="\+?[0-9 \(\)\-]{7,25}" placeholder="+962 7X XXX XXXX" required />
            </fieldset>
            <fieldset class="company-fields"><legend>Company information</legend>
                <label for="companyName">Company name <span aria-hidden="true">*</span></label><input id="companyName" class="form-control" autocomplete="organization" maxlength="150" minlength="2" required />
                <label for="companyEmail">Company email <span aria-hidden="true">*</span></label><input id="companyEmail" type="email" class="form-control" maxlength="254" required />
                <label for="companyLocation">Location <span aria-hidden="true">*</span></label><input id="companyLocation" class="form-control" maxlength="200" placeholder="City and office address" required />
            </fieldset>
            <fieldset class="company-fields"><legend>Account access</legend>
                <label for="temporaryPassword">Temporary password <span aria-hidden="true">*</span></label><div class="company-password"><input id="temporaryPassword" type="password" class="form-control" autocomplete="new-password" minlength="12" maxlength="128" required aria-describedby="passwordHelp" /><button id="togglePassword" type="button" aria-controls="temporaryPassword" aria-pressed="false">Show</button></div><small id="passwordHelp">At least 12 characters. The supervisor must change it at first login.</small>
                <label for="accountStatus">Initial account status</label><select id="accountStatus" class="form-select"><option value="Active">Active</option><option value="Inactive">Inactive</option></select><small>Active accounts can sign in. Inactive accounts have sign-in access disabled.</small>
            </fieldset>
            <div class="company-actions"><button type="button" id="reviewCompany" class="btn btn-primary">Review account</button><button type="button" id="clearCompany" class="btn btn-outline-primary">Clear</button></div><p id="companyFeedback" class="company-feedback" role="status" hidden></p>
        </section>
    </div>
    <dialog id="companyReview" aria-labelledby="reviewTitle"><div class="company-review-heading"><h2 id="reviewTitle">Review supervisor account</h2><button type="button" id="closeReview" aria-label="Close review">&times;</button></div><p class="text-muted">Check the details below. This preview does not create an account.</p><dl id="reviewDetails"></dl><p class="company-preview">The password is hidden and will not be saved in company profile data.</p><button type="button" id="returnToForm" class="btn btn-primary">Back to form</button></dialog>
    <script src="<%= ResolveUrl("~/Coordinator/ManageCompanySupervisors/company-supervisors.js") %>" defer></script>
</asp:Content>
