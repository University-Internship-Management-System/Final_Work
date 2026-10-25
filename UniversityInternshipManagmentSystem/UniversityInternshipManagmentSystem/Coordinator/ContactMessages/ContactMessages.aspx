<%@ Page Title="Contact Messages" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" Async="true" AsyncTimeout="60" AutoEventWireup="true" CodeFile="ContactMessages.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Coordinator.ContactInboxPage" %>
<%@ Assembly Name="System.Net.Http, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a" %>
<asp:Content ID="InboxHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="<%= ResolveUrl("~/Coordinator/ContactMessages/ContactMessages.css?v=1") %>" />
</asp:Content>
<asp:Content ID="InboxContent" ContentPlaceHolderID="MainContent" runat="server">
    <div class="contact-inbox">
        <header class="ci-heading"><div><span class="ci-eyebrow">COORDINATOR WORKSPACE</span><h1 class="uims-page-title">Contact Messages</h1><p>Read messages submitted through the UIMS Contact Us form.</p></div><span class="ci-badge"><i class="bi bi-shield-lock" aria-hidden="true"></i> Staff only</span></header>
        <asp:Panel ID="NoticePanel" runat="server" Visible="false" CssClass="ci-notice" role="alert"><asp:Literal ID="Notice" runat="server" Mode="Encode" /></asp:Panel>
        <div id="ci-loading" class="ci-notice" role="status" aria-live="polite" hidden>Loading messages securely…</div>
        <asp:Panel ID="Workspace" runat="server">
            <section class="ci-directory" aria-labelledby="ci-directory-title">
                <div class="ci-toolbar"><div><h2 id="ci-directory-title">Your message inbox</h2><p><asp:Literal ID="Summary" runat="server" Mode="Encode" /></p></div><asp:Panel ID="SearchPanel" runat="server" CssClass="ci-search" DefaultButton="SearchButton"><asp:Label runat="server" AssociatedControlID="SearchInput" CssClass="ci-sr-only" Text="Search messages" /><asp:TextBox ID="SearchInput" runat="server" MaxLength="100" CssClass="form-control" placeholder="Name, email, subject or message" /><asp:Button ID="SearchButton" runat="server" Text="Search" OnClick="Search_Click" CssClass="btn btn-primary" /><asp:Button ID="ReloadButton" runat="server" Text="Reload" OnClick="Reload_Click" CssClass="btn btn-outline-primary" /></asp:Panel></div>
                <asp:Panel ID="EmptyPanel" runat="server" Visible="false" CssClass="ci-empty"><i class="bi bi-envelope-open" aria-hidden="true"></i><h3><asp:Literal ID="EmptyHeading" runat="server" Mode="Encode" /></h3><p><asp:Literal ID="EmptyText" runat="server" Mode="Encode" /></p></asp:Panel>
                <asp:Repeater ID="Messages" runat="server" EnableViewState="false"><ItemTemplate>
                    <article class="ci-message"><div class="ci-message-heading"><h3><%#: Eval("Subject") %></h3><span class="ci-date"><%#: Eval("DateLabel") %></span></div><div class="ci-sender"><strong><%#: Eval("FullName") %></strong><span><%#: Eval("Email") %></span></div><details><summary>Read message</summary><p class="ci-message-body"><%#: Eval("Message") %></p></details></article>
                </ItemTemplate></asp:Repeater>
            </section><p class="ci-footnote">Messages are shown from Firebase. Handling status and email replies are not enabled on this page.</p>
        </asp:Panel>
    </div>
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            var root = document.querySelector('.contact-inbox'), form = root && root.closest('form');
            if (form) form.addEventListener('submit', function () { document.getElementById('ci-loading').hidden = false; root.setAttribute('aria-busy', 'true'); });
        });
    </script>
</asp:Content>
