(() => {
    'use strict';
    document.querySelectorAll('[data-password]').forEach(button => {
        button.addEventListener('click', () => {
            const input = document.getElementById(button.dataset.password);
            const show = input.type === 'password';
            input.type = show ? 'text' : 'password';
            button.textContent = show ? 'Hide' : 'Show';
            button.setAttribute('aria-pressed', String(show));
            button.setAttribute('aria-label', (show ? 'Hide' : 'Show') + ' password');
        });
    });
    const modal = document.getElementById('passwordModal');
    if (!modal) return;
    if (document.getElementById('openPassword').value === '1') bootstrap.Modal.getOrCreateInstance(modal).show();
    modal.addEventListener('hidden.bs.modal', () => {
        document.getElementById('openPassword').value = '0';
        const alert = modal.querySelector('[role="alert"]');
        if (alert) alert.hidden = true;
        modal.querySelectorAll('input[type="password"], input[type="text"]').forEach(input => { input.value = ''; input.type = 'password'; });
        modal.querySelectorAll('[data-password]').forEach(button => { button.textContent = 'Show'; button.setAttribute('aria-pressed', 'false'); });
    });
    modal.addEventListener('keydown', event => {
        if (event.key === 'Enter' && event.target.tagName === 'INPUT') {
            event.preventDefault();
            event.stopPropagation();
            modal.querySelector('input[type="submit"]').click();
        }
    });
})();
