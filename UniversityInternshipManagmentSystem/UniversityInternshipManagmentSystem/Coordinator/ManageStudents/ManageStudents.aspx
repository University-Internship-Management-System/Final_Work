<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ManageStudents.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Coordinator.ManageStudentsPage" MasterPageFile="~/Shared/Dashboard.Master" %>
<asp:Content ID="head" ContentPlaceHolderID="HeadContent" runat="server">
    <link rel="stylesheet" href="students.css" />
</asp:Content>
<asp:Content ID="content" ContentPlaceHolderID="MainContent" runat="server">
    <header class="student-heading"><div><p class="student-eyebrow">COORDINATOR / ACCOUNT MANAGEMENT</p><h1 class="page-title">Students</h1><p class="text-muted">Manage student accounts, academic details and supervisor assignments.</p></div><a id="addStudent" class="btn btn-primary" href="#studentEditor">Add student</a></header>
    <p class="student-preview" role="note">Interface preview. You can review a student draft; no account or assignment is saved yet.</p>
    <div class="student-grid">
        <section class="card student-card" aria-labelledby="directoryTitle">
            <div class="student-section-heading"><div><h2 id="directoryTitle">Student directory</h2><p class="text-muted">Academic information and assigned supervisors.</p></div><span class="student-count">0 students loaded</span></div>
            <div class="student-tools"><div><label for="studentSearch">Search students</label><input type="search" id="studentSearch" class="form-control" placeholder="Search name or university email" disabled /></div><div><label for="majorFilter">Major</label><select id="majorFilter" class="form-select" disabled><option>All majors</option></select></div></div>
            <div class="table-responsive"><table class="table student-table"><thead><tr><th scope="col">Student</th><th scope="col">Major</th><th scope="col">Academic supervisor</th><th scope="col">Actions</th></tr></thead><tbody><tr><td colspan="4"><div class="student-empty"><span class="student-empty-icon" aria-hidden="true">S</span><h3>No student accounts loaded</h3><p>Student records and editing will appear here when this page is connected to Firebase.</p><a href="#studentEditor" class="btn btn-outline-primary">Prepare a student account</a></div></td></tr></tbody></table></div>
        </section>
        <section id="studentEditor" class="card student-card" aria-labelledby="editorTitle">
            <p class="student-eyebrow">NEW ACCOUNT</p><h2 id="editorTitle">Add student</h2><p class="text-muted">This account will have the Student role.</p>
            <fieldset class="student-fields"><legend>Student details</legend>
                <label for="studentName">Full name <span aria-hidden="true">*</span></label><input id="studentName" class="form-control" autocomplete="name" minlength="2" maxlength="100" required />
                <label for="loginEmail">Login email <span aria-hidden="true">*</span></label><input id="loginEmail" class="form-control" type="email" autocomplete="email" maxlength="254" required /><small>The student will use this email to sign in.</small>
                <label for="universityEmail">University email <span aria-hidden="true">*</span></label><input id="universityEmail" class="form-control" type="email" maxlength="254" required />
                <label for="phoneNumber">Phone number <span aria-hidden="true">*</span></label><input id="phoneNumber" class="form-control" type="tel" autocomplete="tel" maxlength="25" pattern="\+?[0-9 \(\)\-]{7,25}" placeholder="+962 7X XXX XXXX" required />
            </fieldset>
            <fieldset class="student-fields"><legend>Academic information</legend>
                <label for="university">University</label><input id="university" class="form-control" value="The University of Jordan" readonly />
                <label for="college">College</label><input id="college" class="form-control" value="King Abdullah II School of Information Technology" readonly />
                <label for="studentMajor">Major <span aria-hidden="true">*</span></label><select id="studentMajor" class="form-select" required><option value="">Select a major</option><option value="Computer Science">Computer Science</option><option value="Cybersecurity">Cybersecurity</option><option value="Computer Information Systems">Computer Information Systems</option><option value="Business Information Technology">Business Information Technology</option><option value="Data Science">Data Science</option><option value="Artificial Intelligence">Artificial Intelligence</option></select>
                <label for="gpa">GPA <span aria-hidden="true">*</span></label><input id="gpa" class="form-control" type="number" min="0" max="4" step="0.01" placeholder="e.g. 3.50" required />
                <label for="requiredHours">Required training hours</label><input id="requiredHours" class="form-control" type="number" value="90" readonly /><small>At least 15 hours per week for 6 weeks.</small>
            </fieldset>
            <fieldset class="student-fields"><legend>Academic supervisor</legend>
                <label for="academicSupervisor">Assigned supervisor <span aria-hidden="true">*</span></label><select id="academicSupervisor" class="form-select" aria-describedby="supervisorHelp" disabled><option>Select a major first</option></select>
                <p id="supervisorHelp" class="student-assignment-note" role="status">Choose a major. Matching supervisor accounts will be loaded when Firebase is connected.</p>
                <a runat="server" href="~/Coordinator/ManageAcademicSupervisors/ManageAcademicSupervisors.aspx">Manage academic supervisors</a>
            </fieldset>
            <fieldset class="student-fields"><legend>Account access</legend>
                <label for="temporaryPassword">Temporary password <span aria-hidden="true">*</span></label><div class="student-password"><input id="temporaryPassword" class="form-control" type="password" minlength="12" maxlength="128" autocomplete="new-password" aria-describedby="passwordHelp" required /><button id="togglePassword" type="button" aria-controls="temporaryPassword" aria-pressed="false">Show</button></div><small id="passwordHelp">At least 12 characters. The student must change it at first login.</small>
            </fieldset>
            <div class="student-actions"><button id="reviewStudent" type="button" class="btn btn-primary">Review draft</button><button id="clearStudent" type="button" class="btn btn-outline-primary">Clear</button></div><p id="studentFeedback" class="student-feedback" role="status" hidden></p>
        </section>
    </div>
    <dialog id="studentReview" aria-labelledby="reviewTitle"><div class="student-review-heading"><h2 id="reviewTitle">Review student draft</h2><button id="closeReview" type="button" aria-label="Close review">&times;</button></div><p class="text-muted">Review the information before account creation is connected.</p><dl id="reviewDetails"></dl><p class="student-preview">A matching academic supervisor must be assigned before this account can be created. This draft is not saved.</p><button id="returnToForm" type="button" class="btn btn-primary">Back to form</button></dialog>
    <script src="<%= ResolveUrl("~/Coordinator/ManageStudents/students.js") %>" defer></script>
</asp:Content>
