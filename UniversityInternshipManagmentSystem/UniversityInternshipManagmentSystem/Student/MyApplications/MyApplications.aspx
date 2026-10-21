<%@ Page Title="My Applications" Language="C#" MasterPageFile="~/Shared/Dashboard.Master" AutoEventWireup="true" CodeBehind="MyApplications.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Student.MyApplications.MyApplications" %>
<%@ Register Src="~/Shared/ComingSoon.ascx" TagPrefix="uims" TagName="ComingSoon" %>

<%-- PLACEHOLDER: the page was blank. Replace the card below with the real list of the student's applications. --%>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <uims:ComingSoon runat="server"
        PageTitle="My Applications"
        Summary="Track the internship applications you submitted."
        Items="See each application with its status (Pending, Accepted or Rejected)|Read the reason when an application is rejected|Confirm one accepted offer" />
</asp:Content>
