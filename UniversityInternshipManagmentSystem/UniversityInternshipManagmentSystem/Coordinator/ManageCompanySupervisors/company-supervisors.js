(() => {
    'use strict';
    const editor = document.getElementById('companyModal');
    function showEditor() {
        const open = document.getElementById('openEditor');
        if (open && open.value === '1' && window.bootstrap)
            bootstrap.Modal.getOrCreateInstance(editor).show();
    }
    editor.addEventListener('hidden.bs.modal', () => {
        document.getElementById('openEditor').value = '0';
    });
    if (window.Sys) Sys.Application.add_load(showEditor);
    showEditor();
    ['companySavedModal', 'companyConfirmModal'].forEach(id => {
        const modal = document.getElementById(id);
        if (modal && window.bootstrap) bootstrap.Modal.getOrCreateInstance(modal).show();
    });
    // "Confirmed email" is read-only and always shows the login email while it is typed
    document.addEventListener('input', event => {
        const id = event.target.id || '';
        if (id !== 'loginEmail' && !id.endsWith('_loginEmail')) return;
        const confirmedBox = document.querySelector('input[id$="companyEmail"]');
        if (confirmedBox) confirmedBox.value = event.target.value.trim();
    });
})();
