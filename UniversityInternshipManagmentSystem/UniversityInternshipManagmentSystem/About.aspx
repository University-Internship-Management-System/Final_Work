<%@ Page Title="About" Language="C#" MasterPageFile="~/Shared/Public.Master" AutoEventWireup="true" CodeBehind="About.aspx.cs" Inherits="UniversityInternshipManagmentSystem.About" %>

<asp:Content ID="TitleHead" ContentPlaceHolderID="HeadContent" runat="server"><link rel="stylesheet" href="<%= ResolveUrl("~/Shared/uims.css?v=20261025-title3") %>" /></asp:Content>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <main aria-labelledby="title">
        <h2 id="title" class="uims-page-title"><%: Title %>.</h2>
        <h3>Your application description page.</h3>
        <p>Use this area to provide additional information.</p>
    </main>
</asp:Content>
