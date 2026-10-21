<%@ Page Title="Final Evaluation" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" %>
<%@ Register Src="~/Shared/ComingSoon.ascx" TagPrefix="uims" TagName="ComingSoon" %>

<%-- PLACEHOLDER: Planned page, not built yet. Replace this file with the real page, keep the same path so the sidebar link keeps working. --%>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <uims:ComingSoon runat="server"
        PageTitle="Final Evaluation"
        Summary="Prepare the final academic evaluation for each of your students."
        Items="Review the company's evaluation|Write comments and the final academic evaluation|Send it to the coordinator" />
</asp:Content>
