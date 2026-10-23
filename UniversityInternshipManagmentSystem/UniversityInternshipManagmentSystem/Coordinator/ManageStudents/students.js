(() => {
    'use strict';
    const modal = document.getElementById('studentModal');
    let scroll = 0;
    function updateModal() {
        const open = document.getElementById('openEditor');
        if (!open || !window.bootstrap) return;
        if (open.value === '1') {
            bootstrap.Modal.getOrCreateInstance(modal).show();
            const body = modal.querySelector('.modal-body');
            if (body) body.scrollTop = scroll;
        }
    }
    modal.addEventListener('hidden.bs.modal', () => {
        scroll = 0;
        document.getElementById('openEditor').value = '0';
    });
    if (window.Sys) {
        Sys.WebForms.PageRequestManager.getInstance().add_beginRequest(() => {
            const body = modal.querySelector('.modal-body');
            scroll = modal.classList.contains('show') && body ? body.scrollTop : 0;
        });
        Sys.Application.add_load(updateModal);
    }
    updateModal();
    const importModal = document.getElementById('studentImportModal');
    const importOpen = document.getElementById('openImport');
    if (importModal && importOpen && importOpen.value === '1' && window.bootstrap)
        bootstrap.Modal.getOrCreateInstance(importModal).show();
    const saved = document.getElementById('studentSavedModal');
    if (saved && window.bootstrap) bootstrap.Modal.getOrCreateInstance(saved).show();
    // "Confirmed email" is read-only and always shows the login email while it is typed
    document.addEventListener('input', event => {
        const id = event.target.id || '';
        if (id !== 'loginEmail' && !id.endsWith('_loginEmail')) return;
        const confirmedBox = document.querySelector('input[id$="universityEmail"]');
        if (confirmedBox) confirmedBox.value = event.target.value.trim();
    });
})();
