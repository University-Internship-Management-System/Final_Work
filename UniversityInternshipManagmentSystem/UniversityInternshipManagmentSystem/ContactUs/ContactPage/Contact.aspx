<%@ Page Title="Contact Us | UIMS" Language="C#" MasterPageFile="~/Shared/Public.Master" AutoEventWireup="true" Async="true" CodeBehind="Contact.aspx.cs" Inherits="UniversityInternshipManagmentSystem.ContactModule.ContactPage" %>
<asp:Content ID="ContactHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/ContactUs/ContactPage/Contact.css") %>" />
</asp:Content>
<asp:Content ID="ContactBody" ContentPlaceHolderID="MainContent" runat="server">
    <section class="contact-page container py-5" aria-labelledby="contact-title">
        <div class="row g-4 g-lg-5 align-items-start">
            <div class="col-lg-4 contact-intro">
                <span class="contact-eyebrow">UIMS &middot; University of Jordan</span>
                <h1 id="contact-title" class="mt-3">Contact us</h1>
                <p class="contact-lead">Have a question about the internship system? Send a message to help us understand what you need.</p>
                <div class="contact-note"><h2>Before you send</h2><p>Include relevant details about your question. Please do not send passwords, identification documents, or other sensitive information.</p></div>
            </div>
            <div class="col-lg-8">
                <div class="card contact-card p-4 p-md-5">
                    <h2>Send a message</h2>
                    <p class="text-muted mb-4">All fields are required.</p>
                    <asp:Panel ID="Availability" runat="server" CssClass="alert alert-warning" role="status">Message sending is temporarily unavailable while secure submission is configured. Your message has not been sent.</asp:Panel>
                    <asp:Panel ID="Feedback" runat="server" Visible="false" role="status" aria-live="polite"><asp:Literal ID="FeedbackText" runat="server" Mode="Encode" /></asp:Panel>
                    <asp:HiddenField ID="Csrf" runat="server" />
                    <asp:HiddenField ID="Submission" runat="server" />
                    <div class="row g-3">
                        <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="FullName" CssClass="form-label" Text="Full name" /><asp:TextBox ValidateRequestMode="Disabled" ID="FullName" runat="server" CssClass="form-control" MaxLength="100" autocomplete="name" required="required" /><asp:Label ID="NameError" runat="server" CssClass="contact-error" role="alert" /></div>
                        <div class="col-md-6"><asp:Label runat="server" AssociatedControlID="Email" CssClass="form-label" Text="Email address" /><asp:TextBox ValidateRequestMode="Disabled" ID="Email" runat="server" CssClass="form-control" TextMode="Email" MaxLength="254" autocomplete="email" required="required" /><asp:Label ID="EmailError" runat="server" CssClass="contact-error" role="alert" /></div>
                        <div class="col-12"><asp:Label runat="server" AssociatedControlID="Subject" CssClass="form-label" Text="Subject" /><asp:TextBox ValidateRequestMode="Disabled" ID="Subject" runat="server" CssClass="form-control" MaxLength="150" required="required" /><asp:Label ID="SubjectError" runat="server" CssClass="contact-error" role="alert" /></div>
                        <div class="col-12"><asp:Label runat="server" AssociatedControlID="Message" CssClass="form-label" Text="Message" /><asp:TextBox ValidateRequestMode="Disabled" ID="Message" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="7" MaxLength="4000" required="required" aria-describedby="message-limit" /><span id="message-limit" class="small text-muted">Up to 4,000 characters. Plain text only.</span><asp:Label ID="MessageError" runat="server" CssClass="contact-error" role="alert" /></div>
                        <div class="col-12 pt-2"><asp:Button ID="Send" runat="server" Text="Send Message" CssClass="btn btn-primary px-4 py-3" OnClick="Send_Click" /><span class="contact-sending ms-3" role="status" hidden>Sending your message...</span></div>
                    </div>
                </div>
            </div>
        </div>
    </section>
    <script src="<%= ResolveUrl("~/ContactUs/ContactPage/Contact.js") %>" defer></script>
</asp:Content>
