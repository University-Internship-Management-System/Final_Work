<%@ Page Title="Final Evaluation" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" %>
<%@ Register Src="~/Shared/ComingSoon.ascx" TagPrefix="uims" TagName="ComingSoon" %>

<%-- PLACEHOLDER: Planned page, not built yet. Replace this file with the real page, keep the same path so the sidebar link keeps working. --%>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <uims:ComingSoon runat="server"
        PageTitle="Final Evaluation"
        Summary="Evaluate the reports and complete each student's final evaluation."
        Items="Evaluate the required reports|Complete the final evaluation using the university criteria|Send it to the academic supervisor" />
</asp:Content>
