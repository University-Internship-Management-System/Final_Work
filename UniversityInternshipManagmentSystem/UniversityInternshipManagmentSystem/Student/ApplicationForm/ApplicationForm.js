document.addEventListener('DOMContentLoaded', function() {
    'use strict';

    var btnSubmit = document.getElementById('btnSubmitApp');
    var txtCoverLetter = document.getElementById('txtCoverLetter');
    var successModalEl = document.getElementById('successModal');

    // the server sets this after the application is saved
    // check it before the button because the form is hidden after saving
    if (successModalEl && window.applicationSaved) {
        new bootstrap.Modal(successModalEl).show();
    }

    // no button means the server hid the form
    if (!btnSubmit) return;

    btnSubmit.addEventListener('click', function(e) {
        e.preventDefault();

        // quick check, the server checks again
        var coverVal = txtCoverLetter ? txtCoverLetter.value.trim() : '';

        if (!coverVal) {
            alert('Please fill out the motivation question (Cover Letter).');
            txtCoverLetter.focus();
            return;
        }

        // disable the button so it can't be clicked twice, then click the hidden server button
        btnSubmit.disabled = true;
        btnSubmit.textContent = 'Submitting...';
        document.getElementById('btnSubmit').click();
    });
});