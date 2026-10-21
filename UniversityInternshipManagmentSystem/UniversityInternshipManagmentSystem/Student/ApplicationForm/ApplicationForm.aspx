<%@ Page Language="C#" AutoEventWireup="true" Async="true" CodeBehind="ApplicationForm.aspx.cs" Inherits="UniversityInternshipManagmentSystem.Student.ApplicationForm.ApplicationForm" %>
<%@ Register Src="~/Shared/Sidebar.ascx" TagPrefix="uims" TagName="Sidebar" %>
<%@ Register Src="~/Shared/Footer.ascx" TagPrefix="uims" TagName="Footer" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Apply for Internship | UIMS</title>
    <link href="~/Content/bootstrap.min.css" rel="stylesheet" runat="server" />
    <link href="~/Shared/uims.css" rel="stylesheet" runat="server" />
    <link href="ApplicationForm.css" rel="stylesheet" />
</head>
<body>
    <form id="form1" runat="server">
        <div class="uims-shell">

            <!-- Sidebar -->
            <aside class="uims-sidebar">
                <uims:Sidebar runat="server" />
            </aside>
            <div class="uims-overlay" onclick="document.body.classList.remove('uims-side-open')"></div>

            <div class="uims-main">
                <!-- Topbar -->
                <div class="uims-topbar">
                    <button type="button" class="uims-menu-btn" aria-label="Open menu"
                        onclick="document.body.classList.add('uims-side-open')">&#9776;</button>
                    <span>UIMS</span>
                </div>

                <main class="uims-content">
                    <div class="uims-page-head">
                        <div>
                            <h1 class="page-title mb-1">Internship Application Form</h1>
                            <p class="text-muted mb-0">Review your profile details and submit your application for this opportunity.</p>
                        </div>
                    </div>

                    <!-- Application Form Card -->
                    <div class="card app-form-card">
                        <div class="card-body p-4">
                            
                            <!-- Student Auto-filled Info Header -->
                            <h5 class="form-section-title mb-3">Applicant Information</h5>
                            
                            <div class="row g-3 mb-4">
                                <!-- 1. Name -->
                                <div class="col-md-6">
                                    <label class="form-label small-label" for="txtName">Full Name</label>
                                    <asp:TextBox ID="txtName" runat="server" ClientIDMode="Static" CssClass="form-control" ReadOnly="true" />
                                </div>

                                <!-- 2. Major -->
                                <div class="col-md-6">
                                    <label class="form-label small-label" for="txtMajor">Major</label>
                                    <asp:TextBox ID="txtMajor" runat="server" ClientIDMode="Static" CssClass="form-control" ReadOnly="true" />
                                </div>

                                <!-- 3. Email -->
                                <div class="col-md-6">
                                    <label class="form-label small-label" for="txtEmail">Email Address</label>
                                    <asp:TextBox ID="txtEmail" runat="server" ClientIDMode="Static" CssClass="form-control" ReadOnly="true" />
                                </div>

                                <!-- 4. Phone -->
                                <div class="col-md-6">
                                    <label class="form-label small-label" for="txtPhone">Phone Number</label>
                                    <asp:TextBox ID="txtPhone" runat="server" ClientIDMode="Static" CssClass="form-control" ReadOnly="true" />
                                </div>

                                <!-- 5. Skills -->
                                <div class="col-12">
                                    <label class="form-label small-label" for="txtSkills">Skills</label>
                                    <asp:TextBox ID="txtSkills" runat="server" ClientIDMode="Static" CssClass="form-control" ReadOnly="true" TextMode="MultiLine" Rows="2" />
                                </div>
                            </div>

                            <hr class="my-4" />

                            <!-- Dynamic Links & Motivation -->
                            <h5 class="form-section-title mb-3">Application Details</h5>

                            <div class="row g-3">
                                <!-- 6. CV URL -->
                                <div class="col-md-6">
                                    <label class="form-label small-label" for="txtCvUrl">CV URL <span class="text-danger">*</span></label>
                                    <asp:TextBox ID="txtCvUrl" runat="server" ClientIDMode="Static" CssClass="form-control" ReadOnly="true"  placeholder="https://example.com/my-cv.pdf" Required="true" />
                                </div>

                                <!-- 7. Portfolio URL -->
                                <div class="col-md-6">
                                    <label class="form-label small-label" for="txtPortfolioUrl">Portfolio URL (Optional)</label>
                                    <asp:TextBox ID="txtPortfolioUrl" runat="server" ClientIDMode="Static" CssClass="form-control" ReadOnly="true" placeholder="https://github.com/my-username" />
                                </div>

                                <!-- 8. Cover Letter (Motivation) -->
                                <div class="col-12">
                                    <label class="form-label small-label" for="txtCoverLetter">Why are you interested in this internship? (Cover Letter) <span class="text-danger">*</span></label>
                                    <asp:TextBox ID="txtCoverLetter" runat="server" ClientIDMode="Static" TextMode="MultiLine" Rows="4" CssClass="form-control" placeholder="Describe your motivations, learning goals, and relevant experiences for this role..." Required="true" />
                                </div>
                            </div>

                            <!-- Submit Action -->
                            <div class="d-flex justify-content-end gap-2 mt-4">
                                <a href="../Opportunities/Opportunities.aspx" class="btn btn-outline-secondary">Cancel</a>
                                <button type="button" id="btnSubmitApp" class="btn btn-primary px-4">Confirm Application</button>
                            </div>

                        </div>
                    </div>
                </main>

                <!-- Footer -->
                <uims:Footer runat="server" />
            </div>

        </div>

        <!-- Success Modal (Pop-up) -->
        <div class="modal fade" id="successModal" tabindex="-1" aria-labelledby="successModalLabel" aria-hidden="true" data-bs-backdrop="static">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content text-center p-4">
                    <div class="modal-body">
                        <div class="modal-icon mb-3">
                            &#10004;
                        </div>
                        <h4 class="modal-title mb-2" id="successModalLabel">Application Submitted Successfully!</h4>
                        <p class="text-muted mb-4">Your application has been received. You can track its status from your applications page.</p>
                        
                        <div class="d-flex flex-column flex-sm-row justify-content-center gap-2">
                            <a href="../Opportunities/Opportunities.aspx" class="btn btn-outline-primary">Back to Opportunities</a>
                            <a href="../MyApplications/MyApplications.aspx" class="btn btn-primary">Back to My Applications</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>

    </form>

    <script src="<%= ResolveUrl("~/Scripts/bootstrap.bundle.min.js") %>"></script>
    <script src="ApplicationForm.js"></script>
</body>
</html>