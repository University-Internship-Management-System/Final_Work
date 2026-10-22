(() => {
    'use strict';
    const container = document.getElementById('assignStudentRows');
    if (!container) return;
    const rows = [...container.querySelectorAll('[data-student-row]')];
    const search = document.getElementById('assignSearch');
    const all = document.getElementById('assignSelectAll');
    const clear = document.getElementById('assignClear');
    const supervisor = document.getElementById('assignSupervisor');
    function updateSelection() {
        const visible = rows.filter(row => !row.hidden);
        const count = rows.filter(row => row.querySelector('input[type="checkbox"]').checked).length;
        const visibleCount = visible.filter(row => row.querySelector('input[type="checkbox"]').checked).length;
        document.getElementById('assignSelectionBadge').textContent = count + ' selected';
        all.disabled = visible.length === 0;
        all.checked = visible.length > 0 && visibleCount === visible.length;
        all.indeterminate = visibleCount > 0 && visibleCount < visible.length;
        clear.disabled = count === 0;
        document.getElementById('reviewButton').disabled = !count || !supervisor.value;
    }
    search.addEventListener('input', () => {
        const query = search.value.trim().toLowerCase();
        rows.forEach(row => { row.hidden = !row.textContent.toLowerCase().includes(query); });
        document.getElementById('assignEmptyRow').hidden = rows.some(row => !row.hidden);
        updateSelection();
    });
    search.addEventListener('keydown', event => { if (event.key === 'Enter') event.preventDefault(); });
    container.addEventListener('change', updateSelection);
    supervisor.addEventListener('change', updateSelection);
    all.addEventListener('change', () => {
        rows.filter(row => !row.hidden).forEach(row => { row.querySelector('input[type="checkbox"]').checked = all.checked; });
        updateSelection();
    });
    clear.addEventListener('click', () => {
        rows.forEach(row => { row.querySelector('input[type="checkbox"]').checked = false; });
        updateSelection();
    });
    document.getElementById('assignEmptyRow').hidden = rows.length > 0;
    updateSelection();
    const review = document.querySelector('.assign-review');
    if (review) review.scrollIntoView({ behavior: 'smooth', block: 'start' });
})();
