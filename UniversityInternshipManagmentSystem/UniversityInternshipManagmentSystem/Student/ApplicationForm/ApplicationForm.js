// Application Form Client Script
document.addEventListener('DOMContentLoaded', function() {
    'use strict';

    var btnSubmit = document.getElementById('btnSubmitApp');
    var txtCvUrl = document.getElementById('txtCvUrl');
    var txtCoverLetter = document.getElementById('txtCoverLetter');
    var successModalEl = document.getElementById('successModal');

    if (!btnSubmit || !successModalEl) return;

    var modal = new bootstrap.Modal(successModalEl);

    // The server sets this flag only after the application was really saved
    if (window.applicationSaved) modal.show();

    btnSubmit.addEventListener('click', function(e) {
        e.preventDefault();

        // 1. Simple Client-Side Validation
        var cvVal = txtCvUrl ? txtCvUrl.value.trim() : '';
        var coverVal = txtCoverLetter ? txtCoverLetter.value.trim() : '';

        if (!cvVal) {
            alert('Please provide your CV URL.');
            txtCvUrl.focus();
            return;
        }

        if (!coverVal) {
            alert('Please fill out the motivation question (Cover Letter).');
            txtCoverLetter.focus();
            return;
        }

        // 2. Save it: press the hidden server button (runs btnSubmit_Click, which writes to Firebase)
        document.getElementById('btnSubmit').click();
    });
});