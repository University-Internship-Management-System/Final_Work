<%@ Page Title="Student Progress" Language="C#" Async="true" AutoEventWireup="true" CodeBehind="StudentProgress.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Academic.StudentProgress.StudentProgress" MasterPageFile="~/Shared/Dashboard.Master" %>
<asp:Content ID="PageHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
.sp-page{direction:ltr;text-align:left;color:var(--uims-dark)}
.sp-top{display:flex;align-items:center;gap:12px}.sp-top h1{margin:0;font-size:clamp(1.7rem,3vw,2.3rem);font-weight:800}
.sp-subtitle,.sp-help{color:var(--uims-muted)}.sp-section{margin-top:24px}
.sp-card{background:#fff;border:1px solid #dfe6ea;border-radius:15px;padding:24px;box-shadow:0 10px 25px rgba(18,43,57,.04)}
.sp-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:22px}
.sp-title{display:flex;align-items:center;gap:10px;font-size:1.18rem;font-weight:750;margin:0 0 18px}
.sp-icon{color:var(--uims-primary);font-size:1.35rem;width:28px;text-align:center}
.sp-field{margin-bottom:9px;overflow-wrap:anywhere}.sp-field span{color:var(--uims-muted)}
.sp-table{width:100%;min-width:780px;border-collapse:collapse}.sp-table th,.sp-table td{padding:13px 12px;border-bottom:1px solid #e2e8e5;vertical-align:middle}
.sp-table th{background:#f8faf9;white-space:nowrap}.sp-table td:first-child{min-width:200px}
.sp-badge{display:inline-block;padding:5px 9px;border-radius:7px;font-weight:700;white-space:nowrap}
.sp-pending{background:#fff4d6;color:#795800}.sp-revision{background:#fff0e9;color:#9a3d18}.sp-done{background:#e7f5ec;color:#07523e}.sp-muted{background:#edf0f2;color:#52616b}
.sp-empty{color:var(--uims-muted);text-align:center;padding:25px!important}.sp-progress{height:11px;background:#e5e9eb;border-radius:20px;overflow:hidden}.sp-progress span{display:block;width:75%;height:100%;background:var(--uims-primary)}
.sp-note{background:#f8faf9;border-radius:9px;padding:14px}.sp-demo{font-size:.78rem;color:var(--uims-muted);font-weight:500}
@media(max-width:850px){.sp-grid{grid-template-columns:1fr}.sp-card{padding:18px}}
</style>
</asp:Content>
<asp:Content ID="PageMain" ContentPlaceHolderID="MainContent" runat="server">
<div class="sp-page" lang="en">
    <div class="sp-top"><span class="sp-icon" aria-hidden="true">◉</span><h1>Student Progress Monitor</h1></div>
    <p class="sp-subtitle">Review training details, assigned tasks, submissions, and company feedback.</p>
    <asp:Label ID="lblMessage" runat="server" Visible="false" CssClass="alert alert-warning d-block" />
    <asp:Panel ID="pnlStudent" runat="server">
        <div class="sp-card sp-section">
            <label for="studentPicker" class="form-label fw-bold">Select a student to monitor</label>
            <select id="studentPicker" class="form-select" style="max-width:700px" onchange="if(this.value) location.href='?student='+encodeURIComponent(this.value)"><asp:Literal ID="litStudentOptions" runat="server" /></select>
        </div>
        <div class="sp-grid sp-section">
            <section class="sp-card" aria-labelledby="studentInfoHeading">
                <h2 id="studentInfoHeading" class="sp-title"><span class="sp-icon" aria-hidden="true">▣</span> Student and Training Details</h2>
                <div class="sp-field"><span>Name: </span><strong><asp:Literal ID="litStudentName" runat="server" /></strong></div>
                <div class="sp-field"><span>University email: </span><strong><asp:Literal ID="litStudentEmail" runat="server" /></strong></div>
                <div class="sp-field"><span>Major: </span><strong><asp:Literal ID="litStudentMajor" runat="server" /></strong></div>
                <div class="sp-field"><span>Student phone: </span><strong><asp:Literal ID="litStudentPhone" runat="server" /></strong></div>
                <div class="sp-field"><span>Training company: </span><strong><asp:Literal ID="litCompanyName" runat="server" /></strong></div>
                <div class="sp-field"><span>Company supervisor: </span><strong><asp:Literal ID="litSupervisorName" runat="server" /></strong></div>
                <div class="sp-field"><span>Supervisor phone: </span><strong><asp:Literal ID="litSupervisorContact" runat="server" /></strong></div>
            </section>
            <%-- ثابت: ملف قاعدة البيانات لا يحتوي ساعات معتمدة أو مطلوبة أو تقييماً نهائياً للشركة. --%>
            <section class="sp-card" aria-labelledby="hoursHeading">
                <h2 id="hoursHeading" class="sp-title"><span class="sp-icon" aria-hidden="true">◷</span> Training Hours and Company Evaluation <span class="sp-demo">Sample data</span></h2>
                <div class="d-flex justify-content-between mb-2"><span>Training hours</span><strong>210 / 280 hours</strong></div>
                <div class="sp-progress" role="progressbar" aria-label="Sample training hours progress" aria-valuenow="210" aria-valuemin="0" aria-valuemax="280"><span></span></div>
                <div class="sp-note mt-3"><strong>Company evaluation status (40%)</strong><div class="mt-2"><span class="sp-badge sp-pending">Awaiting company supervisor evaluation</span></div></div>
            </section>
        </div>
        <section class="sp-card sp-section" aria-labelledby="tasksHeading">
            <h2 id="tasksHeading" class="sp-title"><span class="sp-icon" aria-hidden="true">☷</span> Student Tasks and Company Feedback <small class="sp-help">(<asp:Literal ID="litTaskCount" runat="server" />)</small></h2>
            <div class="table-responsive"><table class="sp-table"><thead><tr><th>Task</th><th>Deadline</th><th>Submission status</th><th>Score</th><th>Company supervisor feedback</th></tr></thead><tbody><asp:Literal ID="litTaskRows" runat="server" /></tbody></table></div>
        </section>
        <%-- ثابت: حفظ الملاحظات الأكاديمية غير متاح حتى يعتمد الفريق مسارها وصلاحيات الكتابة في Firebase. --%>
        <section class="sp-card sp-section" aria-labelledby="notesHeading">
            <h2 id="notesHeading" class="sp-title"><span class="sp-icon" aria-hidden="true">▤</span> Academic Supervisor Notes <span class="sp-demo">Not available yet</span></h2>
            <p class="sp-help mb-0">Notes can be saved after their database structure and write permissions are agreed.</p>
        </section>
    </asp:Panel>
</div>
</asp:Content>
