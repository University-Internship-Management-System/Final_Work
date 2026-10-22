<%@ Page Title="My Trainees" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" Async="true" AsyncTimeout="70" CodeBehind="MyTrainees.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Company.MyTraineesModule.MyTraineesPage" %>
<%-- Requires the reviewed project registrations in PROJECT-REGISTRATION.patch and a rebuild.
     Registration alone does not authorize Firebase trainee queries. --%>
<asp:Content ID="TraineesHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/Company/MyTrainees/MyTrainees.css") %>" />
</asp:Content>
<asp:Content ID="TraineesContent" ContentPlaceHolderID="MainContent" runat="server">
    <section class="trainees-page" aria-labelledby="trainees-title">
        <div class="trainees-heading"><div><p class="trainees-eyebrow">Company supervisor</p><h1 id="trainees-title">My Trainees</h1><p class="text-muted">Your confirmed trainees and their academic details, in one place.</p></div><span class="trainees-readonly">Read-only</span></div>
        <asp:Panel ID="Feedback" runat="server" Visible="false" CssClass="alert alert-warning" role="alert" EnableViewState="false"><asp:Literal ID="FeedbackText" runat="server" Mode="Encode" /></asp:Panel>
        <div class="row g-3 mb-4">
            <div class="col-md-5"><div class="card p-4 h-100"><p class="trainees-eyebrow">Confirmed trainees</p><asp:Label ID="TotalCount" runat="server" Text="Unavailable" CssClass="trainees-count" /><p class="text-muted small mb-0 mt-2">Shown only after assignments and confirmation are verified.</p></div></div>
            <div class="col-md-7"><div class="card p-4 h-100"><p class="trainees-eyebrow">Company</p><asp:Label ID="CompanyName" runat="server" Text="Not loaded" CssClass="trainees-company" /><p class="text-muted small mb-0 mt-2">Only trainees assigned to your verified company account are eligible.</p></div></div>
        </div>
        <div class="card trainees-directory">
            <div class="trainees-toolbar"><div><h2>Your trainee directory</h2><p class="text-muted small mb-0">Search by name or major.</p></div><asp:Panel ID="SearchPanel" runat="server" CssClass="trainees-search" DefaultButton="SearchButton"><asp:Label ID="SearchLabel" runat="server" AssociatedControlID="SearchInput" CssClass="visually-hidden" Text="Search trainees by name or major" /><asp:TextBox ID="SearchInput" runat="server" CssClass="form-control" MaxLength="100" placeholder="Name or major" Enabled="false" autocomplete="off" ValidateRequestMode="Disabled" /><asp:Button ID="SearchButton" runat="server" CssClass="btn btn-primary" Text="Search" Enabled="false" CausesValidation="false" UseSubmitBehavior="true" /></asp:Panel></div>
            <asp:Label ID="SearchError" runat="server" CssClass="trainees-validation" role="alert" />
            <p class="trainees-loading px-4" role="status" aria-live="polite" hidden>Loading your authorized trainee list...</p>
            <asp:Panel ID="UnavailableState" runat="server" CssClass="trainees-empty" role="status" EnableViewState="false"><span class="trainees-state-icon" aria-hidden="true">&#8212;</span><h3><asp:Literal ID="UnavailableHeading" runat="server" Mode="Encode" Text="Student data is unavailable" /></h3><p>No trainee records, counts, or training hours are assumed.</p></asp:Panel>
            <asp:Panel ID="EmptyState" runat="server" Visible="false" CssClass="trainees-empty" role="status" EnableViewState="false"><h3><asp:Literal ID="EmptyHeading" runat="server" Mode="Encode" /></h3><p><asp:Literal ID="EmptyText" runat="server" Mode="Encode" /></p></asp:Panel>
            <asp:Repeater ID="Trainees" runat="server" EnableViewState="false"><HeaderTemplate><ul class="trainees-list"></HeaderTemplate><ItemTemplate><li class="trainees-row"><div class="trainees-person"><h3><%#: Eval("Name") %></h3><p><%#: Eval("Major") %></p><span class="trainees-contact"><%#: Eval("Contact") %></span></div><span class="trainees-status">Confirmed</span></li></ItemTemplate><FooterTemplate></ul></FooterTemplate></asp:Repeater>
            <asp:Label ID="ResultCount" runat="server" CssClass="trainees-results" />
        </div>
        <p class="trainees-note">Accepted applications awaiting confirmation are not listed as confirmed trainees. Training hours and evaluations are not available on this page.</p>
    </section>
    <script src="<%= ResolveUrl("~/Company/MyTrainees/MyTrainees.js") %>" defer></script>
</asp:Content>
