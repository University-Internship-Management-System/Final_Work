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
.sp-empty{color:var(--uims-muted);text-align:center;padding:25px!important}.sp-progress{height:11px;background:#e5e9eb;border-radius:20px;overflow:hidden}.sp-progress span{display:block;height:100%;background:var(--uims-primary)}
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
            <select id="studentPicker" class="form-select" style="max-width:700px"></select>
        </div>
        <div class="sp-grid sp-section">
            <section class="sp-card" aria-labelledby="studentInfoHeading">
                <h2 id="studentInfoHeading" class="sp-title"><span class="sp-icon" aria-hidden="true">▣</span> Student and Training Details</h2>
                <div class="sp-field"><span>Name: </span><strong id="studentName"></strong></div>
                <div class="sp-field"><span>University email: </span><strong id="studentEmail"></strong></div>
                <div class="sp-field"><span>Major: </span><strong id="studentMajor"></strong></div>
                <div class="sp-field"><span>Student phone: </span><strong id="studentPhone"></strong></div>
                <div class="sp-field"><span>Training company: </span><strong id="companyName"></strong></div>
                <div class="sp-field"><span>Company supervisor: </span><strong id="supervisorName"></strong></div>
                <div class="sp-field"><span>Supervisor phone: </span><strong id="supervisorPhone"></strong></div>
            </section>
            <section class="sp-card" aria-labelledby="hoursHeading">
                <h2 id="hoursHeading" class="sp-title"><span class="sp-icon" aria-hidden="true">◷</span> Training Progress</h2>
                <div class="d-flex justify-content-between mb-2"><span>Completed task hours</span><strong id="hoursValue"></strong></div>
                <div id="hoursProgress" class="sp-progress" role="progressbar" aria-label="Completed task hours" aria-valuemin="0" aria-valuemax="100"><span></span></div>
                <p class="sp-help mt-2 mb-0">Hours from tasks evaluated by the company supervisor.</p>
                <p class="sp-help mt-3 mb-0">Approved hours from signed weekly reports: <strong id="approvedHours"></strong></p>
                <div class="d-flex justify-content-between mt-4 mb-2"><span>Tasks submitted or evaluated</span><strong id="taskProgressValue"></strong></div>
                <div id="taskProgress" class="sp-progress" role="progressbar" aria-label="Tasks submitted or evaluated" aria-valuemin="0" aria-valuemax="100"><span></span></div>
                <p class="sp-help mt-2 mb-0">Assigned task hours: <strong id="taskHours"></strong></p>
                <div class="sp-note mt-3"><strong>Company evaluation status</strong><div class="mt-2"><span id="companyStatus" class="sp-badge"></span></div></div>
            </section>
        </div>
        <section class="sp-card sp-section" aria-labelledby="tasksHeading">
            <h2 id="tasksHeading" class="sp-title"><span class="sp-icon" aria-hidden="true">☷</span> Student Tasks and Company Feedback <small class="sp-help">(<span id="taskCount"></span>)</small></h2>
            <div class="table-responsive"><table class="sp-table"><thead><tr><th>Task</th><th>Hours</th><th>Deadline</th><th>Submission status</th><th>Score</th><th>Company supervisor feedback</th></tr></thead><tbody id="taskRows"></tbody></table></div>
        </section>
        <section class="sp-card sp-section" aria-labelledby="notesHeading">
            <h2 id="notesHeading" class="sp-title"><span class="sp-icon" aria-hidden="true">▤</span> Academic Supervisor Notes</h2>
            <asp:HiddenField ID="hidSelectedStudent" runat="server" />
            <asp:TextBox ID="txtAcademicNote" runat="server" TextMode="MultiLine" Rows="4" MaxLength="2000" CssClass="form-control" aria-label="Academic supervisor notes" placeholder="Write a progress note for this student" />
            <div class="d-flex align-items-center gap-3 mt-3"><asp:Button ID="btnSaveNote" runat="server" Text="Save Note" CssClass="btn btn-primary" OnClick="btnSaveNote_Click" /><asp:Label ID="lblNoteStatus" runat="server" role="status" /></div>
            <p class="sp-help mt-2 mb-0"><asp:Literal ID="litNoteUpdated" runat="server" /></p>
        </section>
    </asp:Panel>
</div>
<script id="progressData" type="application/json"><asp:Literal ID="litProgressData" runat="server" /></script>
<script>
(function () {
    var source = document.getElementById('progressData').textContent;
    if (!source.trim()) return;
    var data = JSON.parse(source);
    var picker = document.getElementById('studentPicker');
    if (!picker) return;

    function show(id, value) {
        document.getElementById(id).textContent = value === null || value === undefined || value === '' ? 'Not available' : value;
    }

    function progress(id, value, total) {
        var percent = total > 0 ? Math.round(value * 100 / total) : 0;
        percent = Math.max(0, Math.min(100, percent));
        var bar = document.getElementById(id);
        bar.setAttribute('aria-valuenow', percent);
        bar.querySelector('span').style.width = percent + '%';
    }

    function cell(row, value) {
        var item = document.createElement('td');
        item.textContent = value;
        row.appendChild(item);
        return item;
    }

    data.Students.forEach(function (student) {
        var name = student.Name || 'Not available';
        var major = student.Major || 'Not available';
        var option = new Option(name + ' — ' + major, student.Id);
        picker.add(option);
    });
    picker.value = data.SelectedId;
    picker.addEventListener('change', function () {
        if (picker.value) location.href = '?student=' + encodeURIComponent(picker.value);
    });

    show('studentName', data.Name);
    show('studentEmail', data.UniversityEmail);
    show('studentMajor', data.Major);
    show('studentPhone', data.Phone);
    show('companyName', data.CompanyName);
    show('supervisorName', data.SupervisorName);
    show('supervisorPhone', data.SupervisorPhone);
    document.getElementById('hoursValue').textContent = data.EvaluatedHours + ' / ' + data.RequiredHours + ' hours';
    document.getElementById('approvedHours').textContent = data.ApprovedHours + ' / ' + data.RequiredHours + ' hours';
    document.getElementById('taskHours').textContent = data.AssignedHours + ' hours';
    document.getElementById('taskProgressValue').textContent = data.SubmittedTasks + ' / ' + data.Tasks.length;
    progress('hoursProgress', data.EvaluatedHours, data.RequiredHours);
    progress('taskProgress', data.SubmittedTasks, data.Tasks.length);

    var companyStatus = document.getElementById('companyStatus');
    companyStatus.textContent = data.CompanyStatus;
    companyStatus.classList.add(data.CompanyStatus === 'Sent to academic supervisor' ? 'sp-done' :
        data.CompanyStatus === 'Not started' ? 'sp-muted' : 'sp-pending');

    document.getElementById('taskCount').textContent = data.Tasks.length;
    var rows = document.getElementById('taskRows');
    if (data.Tasks.length === 0) {
        var empty = document.createElement('tr');
        var message = cell(empty, 'No tasks are currently assigned to this student.');
        message.colSpan = 6;
        message.className = 'sp-empty';
        rows.appendChild(empty);
    }
    data.Tasks.forEach(function (task) {
        var row = document.createElement('tr');
        cell(row, task.Name || 'Not available');
        cell(row, task.Hours + ' hours');
        var date = task.Deadline || 'Not available';
        var parsed = new Date(date);
        if (date !== 'Not available' && !isNaN(parsed.getTime())) date = parsed.toISOString().slice(0, 10);
        cell(row, date);
        var status = task.Status || '';
        var statusText = 'Not submitted';
        var statusClass = 'sp-muted';
        if (status.toLowerCase() === 'submitted') { statusText = 'Pending review'; statusClass = 'sp-pending'; }
        if (status.toLowerCase() === 'revisionrequested') { statusText = 'Revision requested'; statusClass = 'sp-revision'; }
        if (status.toLowerCase() === 'evaluated') { statusText = 'Evaluated'; statusClass = 'sp-done'; }
        var badge = document.createElement('span');
        badge.className = 'sp-badge ' + statusClass;
        badge.textContent = statusText;
        cell(row, '').appendChild(badge);
        var score = '—';
        if (status.toLowerCase() === 'submitted') score = 'Pending review';
        if (status.toLowerCase() === 'evaluated') score = task.Score == null ? 'Not available' : task.Score + ' / ' + (task.MaxScore || 'Not available');
        cell(row, score);
        cell(row, task.Feedback || 'Not available');
        rows.appendChild(row);
    });
}());
</script>
</asp:Content>
