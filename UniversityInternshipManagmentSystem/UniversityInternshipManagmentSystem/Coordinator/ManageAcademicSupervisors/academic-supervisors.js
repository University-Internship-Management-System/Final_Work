(() => {
    'use strict';
    const input = document.getElementById('supervisorSearch');
    if (!input) return;
    const rows = [...document.querySelectorAll('.supervisor-row')];
    input.addEventListener('input', () => {
        const query = input.value.trim().toLocaleLowerCase();
        let shown = 0;
        rows.forEach(row => {
            row.hidden = !row.textContent.toLocaleLowerCase().includes(query);
            if (!row.hidden) shown++;
        });
        document.getElementById('searchEmpty').hidden = !rows.length || shown > 0;
    });
})();
