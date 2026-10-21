<%@ Page Title="Completion Review" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" %>
<%@ Register Src="~/Shared/ComingSoon.ascx" TagPrefix="uims" TagName="ComingSoon" %>

<%-- PLACEHOLDER: Planned page, not built yet. Replace this file with the real page, keep the same path so the sidebar link keeps working. --%>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <uims:ComingSoon runat="server"
        PageTitle="Completion Review"
        Summary="Review the evaluations and approve internship completion."
        Items="Compare the company and academic final evaluations|Check the training hours and the university requirements|Approve completion and generate the PDF report" />
</asp:Content>
