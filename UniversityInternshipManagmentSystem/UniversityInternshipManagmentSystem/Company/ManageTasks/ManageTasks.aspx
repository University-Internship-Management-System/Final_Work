<%@ Page Title="Tasks" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" %>
<%@ Register Src="~/Shared/ComingSoon.ascx" TagPrefix="uims" TagName="ComingSoon" %>

<%-- PLACEHOLDER: Planned page, not built yet. Replace this file with the real page, keep the same path so the sidebar link keeps working. --%>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <uims:ComingSoon runat="server"
        PageTitle="Tasks"
        Summary="Create tasks for your trainees and review their work."
        Items="Create tasks with deadlines and evaluation criteria|Review submissions and give scores|Give feedback or ask for changes" />
</asp:Content>
