<%@ Page Title="My Trainees" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" Async="true" AsyncTimeout="180" CodeBehind="MyTrainees.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Company.MyTraineesModule.MyTraineesPage" %>
<%-- Existing project registrations are retained. All Firebase reads use the verified supervisor token. --%>
<asp:Content ID="TraineesHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/Company/MyTrainees/MyTrainees.css") %>" />
</asp:Content>
<asp:Content ID="TraineesContent" ContentPlaceHolderID="MainContent" runat="server">
    <section class="trainees-page" aria-labelledby="trainees-title">
        <div class="trainees-heading"><div><p class="trainees-eyebrow">Company supervisor</p><h1 id="trainees-title">My Trainees</h1><p class="text-muted">Your accepted students, confirmed trainees, training details and task progress.</p></div><span class="trainees-readonly">Read-only</span></div>
        <asp:Panel ID="Feedback" runat="server" Visible="false" CssClass="alert alert-warning" role="alert" EnableViewState="false"><asp:Literal ID="FeedbackText" runat="server" Mode="Encode" /></asp:Panel>
        <div class="row g-3 mb-4">
            <div class="col-md-5"><div class="card p-4 h-100"><p class="trainees-eyebrow">Accepted &amp; confirmed students</p><asp:Label ID="TotalCount" runat="server" Text="Unavailable" CssClass="trainees-count" /><p class="text-muted small mb-0 mt-2">Distinct students; Accepted and Confirmed are labelled separately.</p></div></div>
            <div class="col-md-7"><div class="card p-4 h-100"><p class="trainees-eyebrow">Company</p><asp:Label ID="CompanyName" runat="server" Text="Not loaded" CssClass="trainees-company" /><p class="text-muted small mb-0 mt-2">Only students linked to your verified company workflow are eligible.</p></div></div>
        </div>
        <div class="card trainees-directory">
            <div class="trainees-toolbar"><div><h2>Your trainee directory</h2><p class="text-muted small mb-0">Search by name or major.</p></div><asp:Panel ID="SearchPanel" runat="server" CssClass="trainees-search" DefaultButton="SearchButton"><asp:Label ID="SearchLabel" runat="server" AssociatedControlID="SearchInput" CssClass="visually-hidden" Text="Search trainees by name or major" /><asp:TextBox ID="SearchInput" runat="server" CssClass="form-control" MaxLength="100" placeholder="Name or major" Enabled="false" autocomplete="off" ValidateRequestMode="Disabled" /><asp:Button ID="SearchButton" runat="server" CssClass="btn btn-primary" Text="Search" Enabled="false" CausesValidation="false" UseSubmitBehavior="true" /></asp:Panel></div>
            <asp:Label ID="SearchError" runat="server" CssClass="trainees-validation" role="alert" />
            <p class="trainees-loading px-4" role="status" aria-live="polite" hidden>Loading your authorized trainee list...</p>
            <asp:Panel ID="UnavailableState" runat="server" CssClass="trainees-empty" role="status" EnableViewState="false"><span class="trainees-state-icon" aria-hidden="true">&#8212;</span><h3><asp:Literal ID="UnavailableHeading" runat="server" Mode="Encode" Text="Student data is unavailable" /></h3><p>No trainee records, counts, or training hours are assumed.</p></asp:Panel>
            <asp:Panel ID="EmptyState" runat="server" Visible="false" CssClass="trainees-empty" role="status" EnableViewState="false"><h3><asp:Literal ID="EmptyHeading" runat="server" Mode="Encode" /></h3><p><asp:Literal ID="EmptyText" runat="server" Mode="Encode" /></p></asp:Panel>
            <asp:Repeater ID="Trainees" runat="server" EnableViewState="false"><HeaderTemplate><ul class="trainees-list"></HeaderTemplate><ItemTemplate>
                <li class="trainees-row">
                    <div class="trainees-person">
                        <div class="trainees-person-heading"><div><h3><%#: Eval("Name") %></h3><p><%#: Eval("Major") %></p></div>
                            <span class="<%#: Eval("StatusClass") %>"><%#: Eval("StatusText") %></span></div>
                        <dl class="trainees-training">
                            <div><dt>Training company</dt><dd><%#: Eval("CompanyName") %></dd></div>
                            <div><dt>Internship opportunity</dt><dd><%#: Eval("OpportunityTitle") %></dd></div>
                            <div><dt>Confirmation date</dt><dd><%#: Eval("ConfirmationDate") %></dd></div>
                            <div><dt>Academic supervisor</dt><dd><%#: Eval("AcademicSupervisor") %></dd></div>
                        </dl>
                        <div class="trainees-progress">
                            <h4>Task progress</h4>
                            <dl class="trainees-progress-counts">
                                <div><dt>Assigned</dt><dd><%#: Eval("AssignedText") %></dd></div>
                                <div><dt>Submitted / evaluated</dt><dd><%#: Eval("SubmittedText") %></dd></div>
                                <div><dt>Evaluated</dt><dd><%#: Eval("EvaluatedText") %></dd></div>
                            </dl>
                            <div class="<%#: Eval("ProgressMeterClass") %>" role="progressbar" aria-label="Task submission progress" aria-valuemin="0" aria-valuemax="100" aria-valuenow="<%#: Eval("ProgressValue") %>"><span style="width:<%#: Eval("ProgressValue") %>%"></span></div>
                            <p class="trainees-progress-label"><%#: Eval("ProgressText") %></p>
                            <p class="trainees-progress-note"><%#: Eval("ProgressNote") %></p>
                        </div>
                    </div>
                </li>
            </ItemTemplate><FooterTemplate></ul></FooterTemplate></asp:Repeater>
            <asp:Label ID="ResultCount" runat="server" CssClass="trainees-results" />
        </div>
        <p class="trainees-note">Accepted students awaiting confirmation are shown separately from Confirmed trainees. Task submission progress is not approved training hours. Hours are unavailable without an authoritative source.</p>
    </section>
    <script src="<%= ResolveUrl("~/Company/MyTrainees/MyTrainees.js") %>" defer></script>
</asp:Content>
