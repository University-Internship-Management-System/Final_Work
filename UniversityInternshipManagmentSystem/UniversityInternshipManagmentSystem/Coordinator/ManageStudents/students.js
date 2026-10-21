(() => {
    'use strict';
    const editor = document.getElementById('studentEditor');
    const fields = [...editor.querySelectorAll('input, select')];
    const major = document.getElementById('studentMajor');
    const supervisor = document.getElementById('academicSupervisor');
    const help = document.getElementById('supervisorHelp');
    const password = document.getElementById('temporaryPassword');
    const toggle = document.getElementById('togglePassword');
    const dialog = document.getElementById('studentReview');

    function updateAssignment() {
        supervisor.options[0].text = major.value ? 'Supervisor connection pending' : 'Select a major first';
        help.textContent = major.value
            ? `Only supervisors in ${major.value} can be assigned. Their accounts will load when Firebase is connected.`
            : 'Choose a major. Matching supervisor accounts will be loaded when Firebase is connected.';
    }
    major.addEventListener('change', updateAssignment);
    document.getElementById('addStudent').addEventListener('click', () => {
        document.getElementById('studentName').focus({ preventScroll: true });
    });
    toggle.addEventListener('click', () => {
        const show = password.type === 'password';
        password.type = show ? 'text' : 'password';
        toggle.textContent = show ? 'Hide' : 'Show';
        toggle.setAttribute('aria-pressed', String(show));
    });
    document.getElementById('reviewStudent').addEventListener('click', () => {
        for (const field of fields) {
            if (!field.readOnly && !field.disabled && field.type !== 'password') field.value = field.value.trim();
            if (!field.reportValidity()) return;
        }
        const details = document.getElementById('reviewDetails');
        details.replaceChildren();
        const labels = {
            studentName: 'Student', loginEmail: 'Login email', universityEmail: 'University email',
            phoneNumber: 'Phone', university: 'University', college: 'College', studentMajor: 'Major',
            gpa: 'GPA', requiredHours: 'Training hours'
        };
        for (const [id, label] of Object.entries(labels)) {
            const term = document.createElement('dt');
            const value = document.createElement('dd');
            term.textContent = label;
            value.textContent = document.getElementById(id).value;
            details.append(term, value);
        }
        dialog.showModal();
    });
    document.getElementById('closeReview').addEventListener('click', () => dialog.close());
    document.getElementById('returnToForm').addEventListener('click', () => dialog.close());
    document.getElementById('clearStudent').addEventListener('click', () => {
        for (const field of fields) {
            if (field.readOnly) continue;
            if (field.tagName === 'SELECT') field.selectedIndex = 0;
            else field.value = '';
        }
        password.type = 'password';
        toggle.textContent = 'Show';
        toggle.setAttribute('aria-pressed', 'false');
        updateAssignment();
        const feedback = document.getElementById('studentFeedback');
        feedback.textContent = 'Form cleared.';
        feedback.hidden = false;
        document.getElementById('studentName').focus();
    });
    editor.addEventListener('keydown', event => {
        if (event.key === 'Enter' && event.target.tagName === 'INPUT') {
            event.preventDefault();
            document.getElementById('reviewStudent').click();
        }
    });
})();
