<%@ Page Title="Manage Opportunities" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" %>
<%@ Register Src="~/Shared/ComingSoon.ascx" TagPrefix="uims" TagName="ComingSoon" %>

<%-- PLACEHOLDER: Planned page, not built yet. Replace this file with the real page, keep the same path so the sidebar link keeps working. --%>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <uims:ComingSoon runat="server"
        PageTitle="Manage Opportunities"
        Summary="Create, edit and close internship opportunities for your company."
        Items="Add an opportunity with its title, specializations and requirements|Set the number of available seats|Edit or close an opportunity" />
</asp:Content>
