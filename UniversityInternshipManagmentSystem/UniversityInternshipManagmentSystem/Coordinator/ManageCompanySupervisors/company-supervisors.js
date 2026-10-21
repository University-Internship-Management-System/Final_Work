(() => {
    'use strict';
    const editor = document.getElementById('companyEditor');
    const fields = [...editor.querySelectorAll('input, select')];
    const password = document.getElementById('temporaryPassword');
    const toggle = document.getElementById('togglePassword');
    const dialog = document.getElementById('companyReview');
    const feedback = document.getElementById('companyFeedback');

    document.getElementById('addCompany').addEventListener('click', () => {
        document.getElementById('supervisorName').focus({ preventScroll: true });
    });

    toggle.addEventListener('click', () => {
        const show = password.type === 'password';
        password.type = show ? 'text' : 'password';
        toggle.textContent = show ? 'Hide' : 'Show';
        toggle.setAttribute('aria-pressed', String(show));
    });

    document.getElementById('reviewCompany').addEventListener('click', () => {
        for (const field of fields) {
            if (field.type !== 'password') field.value = field.value.trim();
            if (!field.reportValidity()) return;
        }
        const details = document.getElementById('reviewDetails');
        details.replaceChildren();
        const labels = {
            supervisorName: 'Supervisor', loginEmail: 'Login email', phoneNumber: 'Phone',
            companyName: 'Company', companyEmail: 'Company email', companyLocation: 'Location',
            accountStatus: 'Initial status'
        };
        for (const [id, label] of Object.entries(labels)) {
            const field = document.getElementById(id);
            const term = document.createElement('dt');
            const value = document.createElement('dd');
            term.textContent = label;
            value.textContent = field.tagName === 'SELECT' ? field.selectedOptions[0].text : field.value;
            details.append(term, value);
        }
        dialog.showModal();
    });

    document.getElementById('closeReview').addEventListener('click', () => dialog.close());
    document.getElementById('returnToForm').addEventListener('click', () => dialog.close());
    document.getElementById('clearCompany').addEventListener('click', () => {
        for (const field of fields) {
            if (field.tagName === 'SELECT') field.selectedIndex = 0;
            else field.value = '';
        }
        password.type = 'password';
        toggle.textContent = 'Show';
        toggle.setAttribute('aria-pressed', 'false');
        feedback.textContent = 'Form cleared.';
        feedback.hidden = false;
        document.getElementById('supervisorName').focus();
    });

    // Enter reviews this draft instead of posting the shared Web Forms form.
    editor.addEventListener('keydown', event => {
        if (event.key === 'Enter' && event.target.tagName === 'INPUT') {
            event.preventDefault();
            document.getElementById('reviewCompany').click();
        }
    });
})();
