(() => {
    'use strict';
    function init() {
        const password = document.getElementById('temporaryPassword');
        const toggle = document.getElementById('togglePassword');
        if (password && toggle) {
            toggle.addEventListener('click', () => {
                const visible = password.type === 'password';
                password.type = visible ? 'text' : 'password';
                toggle.textContent = visible ? 'Hide' : 'Show';
                toggle.setAttribute('aria-pressed', String(visible));
            });
        }
        const search = document.getElementById('studentSearch');
        const major = document.getElementById('majorFilter');
        const button = document.getElementById('searchButton');
        const rows = [...document.querySelectorAll('[data-student-row]')];
        if (search && major && button) {
            const serverQuery = search.value.trim().toLocaleLowerCase();
            const serverMajor = major.value;
            let refresh;
            function filter() {
                const query = search.value.trim().toLocaleLowerCase();
                let count = 0;
                rows.forEach(row => {
                    row.hidden = (major.value && row.dataset.major !== major.value) || !row.textContent.toLocaleLowerCase().includes(query);
                    if (!row.hidden) count++;
                });
                document.getElementById('studentLiveEmpty').hidden = !rows.length || count > 0;
                clearTimeout(refresh);
                if ((serverMajor && major.value !== serverMajor) || (serverQuery && !query.startsWith(serverQuery)))
                    refresh = setTimeout(() => button.click(), 450);
            }
            search.addEventListener('input', filter);
            major.addEventListener('change', filter);
            search.addEventListener('keydown', event => {
                if (event.key === 'Enter') { event.preventDefault(); button.click(); }
            });
        }
        const editor = document.getElementById('studentEditor');
        if (editor) editor.addEventListener('keydown', event => {
            if (event.key === 'Enter' && event.target.tagName === 'INPUT') event.preventDefault();
        });
    }
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
    else init();
})();
