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
        const search = document.getElementById('companySearch');
        const searchButton = document.getElementById('searchButton');
        const rows = [...document.querySelectorAll('[data-company-row]')];
        if (search && searchButton) {
            const serverQuery = search.value.trim().toLocaleLowerCase();
            let refresh;
            search.addEventListener('input', () => {
                const query = search.value.trim().toLocaleLowerCase();
                let matches = 0;
                rows.forEach(row => {
                    row.hidden = !row.textContent.toLocaleLowerCase().includes(query);
                    if (!row.hidden) matches++;
                });
                document.getElementById('companyLiveEmpty').hidden = !rows.length || matches > 0;
                clearTimeout(refresh);
                // Ask C# for the full result set when broadening a server-side search.
                if (serverQuery && !query.startsWith(serverQuery)) {
                    refresh = setTimeout(() => searchButton.click(), 450);
                }
            });
            search.addEventListener('keydown', event => {
                if (event.key === 'Enter') { event.preventDefault(); searchButton.click(); }
            });
        }
        const editor = document.getElementById('companyEditor');
        if (editor) {
            editor.addEventListener('keydown', event => {
                if (event.key === 'Enter' && event.target.tagName === 'INPUT') event.preventDefault();
            });
        }
    }
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
    else init();
})();
