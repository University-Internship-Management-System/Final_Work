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
})();
