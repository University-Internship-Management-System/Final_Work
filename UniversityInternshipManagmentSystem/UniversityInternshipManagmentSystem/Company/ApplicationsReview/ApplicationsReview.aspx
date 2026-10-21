<%@ Page Title="Applications" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" %>
<%@ Register Src="~/Shared/ComingSoon.ascx" TagPrefix="uims" TagName="ComingSoon" %>

<%-- PLACEHOLDER: Planned page, not built yet. Replace this file with the real page, keep the same path so the sidebar link keeps working. --%>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <uims:ComingSoon runat="server"
        PageTitle="Applications"
        Summary="Review the applications students sent to your opportunities."
        Items="See each applicant's profile and CV|Accept an application|Reject an application and give the reason" />
</asp:Content>
