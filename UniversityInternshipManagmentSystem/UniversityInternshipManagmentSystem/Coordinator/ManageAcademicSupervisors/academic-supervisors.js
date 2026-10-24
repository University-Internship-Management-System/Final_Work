(() => {
    'use strict';
    const editor = document.getElementById('academicModal');
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
    const saved = document.getElementById('academicSavedModal');
    if (saved && window.bootstrap) bootstrap.Modal.getOrCreateInstance(saved).show();
    // "Confirmed email" is read-only and always shows the login email while it is typed
    document.addEventListener('input', event => {
        const id = event.target.id || '';
        if (id !== 'email' && !id.endsWith('_email')) return;
        const confirmedBox = document.querySelector('input[id$="universityEmail"]');
        if (confirmedBox) confirmedBox.value = event.target.value.trim();
    });
})();
