<%@ Page Title="My Trainees" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" %>
<%@ Register Src="~/Shared/ComingSoon.ascx" TagPrefix="uims" TagName="ComingSoon" %>

<%-- PLACEHOLDER: Planned page, not built yet. Replace this file with the real page, keep the same path so the sidebar link keeps working. --%>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <uims:ComingSoon runat="server"
        PageTitle="My Trainees"
        Summary="The students you accepted and their training progress."
        Items="List your accepted trainees|See their training information and progress|Approve their logged training hours" />
</asp:Content>
