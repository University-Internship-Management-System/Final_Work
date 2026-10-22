// Application Form Client Script
document.addEventListener('DOMContentLoaded', function() {
    'use strict';

    var btnSubmit = document.getElementById('btnSubmitApp');
    var txtCoverLetter = document.getElementById('txtCoverLetter');
    var successModalEl = document.getElementById('successModal');

    // The server sets this flag only after the application was really saved.
    // Checked before looking at the button: after saving, the form and its button are hidden.
    if (successModalEl && window.applicationSaved) {
        new bootstrap.Modal(successModalEl).show();
    }

    // No button = the server hid the form (the student cannot apply, or already applied)
    if (!btnSubmit) return;

    btnSubmit.addEventListener('click', function(e) {
        e.preventDefault();

        // 1. Simple Client-Side Validation (the server checks everything again)
        var coverVal = txtCoverLetter ? txtCoverLetter.value.trim() : '';

        if (!coverVal) {
            alert('Please fill out the motivation question (Cover Letter).');
            txtCoverLetter.focus();
            return;
        }

        // 2. Save it once: block a second click, then press the hidden server button
        //    (runs btnSubmit_Click, which writes to Firebase)
        btnSubmit.disabled = true;
        btnSubmit.textContent = 'Submitting...';
        document.getElementById('btnSubmit').click();
    });
});