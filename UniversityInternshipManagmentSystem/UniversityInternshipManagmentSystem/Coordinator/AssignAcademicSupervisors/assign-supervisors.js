(() => {
    'use strict';
    const major = document.getElementById('assignMajor');
    const search = document.getElementById('assignSearch');
    const status = document.getElementById('assignStatus');
    const supervisor = document.getElementById('assignSupervisor');
    const selectAll = document.getElementById('assignSelectAll');
    const clear = document.getElementById('assignClear');
    const review = document.getElementById('assignReviewButton');
    const dialog = document.getElementById('assignReview');
    const rows = () => [...document.querySelectorAll('#assignStudentRows tr[data-student-id]')];
    const selected = () => rows().filter(row => row.querySelector('input[type="checkbox"]').checked);

    function updateSelection() {
        const selection = selected();
        document.getElementById('assignSelectionBadge').textContent = `${selection.length} selected`;
        document.getElementById('assignSummaryCount').textContent = String(selection.length);
        clear.disabled = selection.length === 0;
        const visible = rows().filter(row => !row.hidden);
        selectAll.disabled = visible.length === 0;
        const visibleSelected = visible.filter(row => row.querySelector('input[type="checkbox"]').checked).length;
        selectAll.checked = visible.length > 0 && visibleSelected === visible.length;
        selectAll.indeterminate = visibleSelected > 0 && visibleSelected < visible.length;
        const option = supervisor.selectedOptions[0];
        review.disabled = !selection.length || !supervisor.value || option.dataset.major !== major.value
            || selection.some(row => row.dataset.major !== major.value);
    }

    function filterStudents() {
        const query = search.value.trim().toLocaleLowerCase();
        for (const row of rows()) {
            const assigned = Boolean(row.dataset.supervisorId);
            row.hidden = row.dataset.major !== major.value || !row.textContent.toLocaleLowerCase().includes(query)
                || (status.value === 'Assigned' && !assigned) || (status.value === 'Unassigned' && assigned);
        }
        const anyVisible = rows().some(row => !row.hidden);
        document.getElementById('assignEmptyRow').hidden = anyVisible;
        updateSelection();
    }

    major.addEventListener('change', () => {
        rows().forEach(row => { row.querySelector('input[type="checkbox"]').checked = false; });
        search.value = '';
        status.value = 'All';
        const hasData = rows().length > 0;
        search.disabled = status.disabled = !major.value || !hasData;
        search.placeholder = major.value ? 'Search name or university email' : 'Select a major first';
        document.getElementById('assignGroupCaption').textContent = major.value || 'Select a major to prepare a student group.';
        document.getElementById('assignSummaryMajor').textContent = major.value || 'Not selected';
        supervisor.selectedIndex = 0;
        for (const option of [...supervisor.options].slice(1)) {
            option.hidden = option.disabled = option.dataset.major !== major.value;
        }
        supervisor.disabled = !major.value || ![...supervisor.options].slice(1).some(option => !option.disabled);
        supervisor.options[0].text = major.value ? 'Matching supervisors not loaded' : 'Select a major first';
        document.getElementById('assignSupervisorHelp').textContent = major.value
            ? `Only ${major.value} supervisors can be assigned. Supervisor records are pending the data connection.`
            : 'Matching supervisor accounts will appear here after the data connection is ready.';
        document.getElementById('assignEmptyTitle').textContent = major.value ? 'Student records not loaded' : 'Choose a major to begin';
        document.getElementById('assignEmptyMessage').textContent = major.value
            ? `Students in ${major.value} will appear here when the page is connected to Firebase.`
            : 'Select students from the same major, then assign them to a matching academic supervisor.';
        filterStudents();
    });
    search.addEventListener('input', filterStudents);
    status.addEventListener('change', filterStudents);
    supervisor.addEventListener('change', updateSelection);
    document.getElementById('assignStudentRows').addEventListener('change', updateSelection);
    selectAll.addEventListener('change', () => {
        rows().filter(row => !row.hidden).forEach(row => { row.querySelector('input[type="checkbox"]').checked = selectAll.checked; });
        updateSelection();
    });
    clear.addEventListener('click', () => {
        rows().forEach(row => { row.querySelector('input[type="checkbox"]').checked = false; });
        updateSelection();
    });
    review.addEventListener('click', () => {
        if (review.disabled) return;
        document.getElementById('assignReviewMajor').textContent = major.value;
        document.getElementById('assignReviewSupervisor').textContent = supervisor.selectedOptions[0].text;
        document.getElementById('assignReviewCount').textContent = String(selected().length);
        const list = document.getElementById('assignReviewStudents');
        list.replaceChildren();
        for (const row of selected()) {
            const item = document.createElement('li');
            item.textContent = row.querySelector('[data-student-name]').textContent;
            list.append(item);
        }
        dialog.showModal();
    });
    document.getElementById('assignCloseReview').addEventListener('click', () => dialog.close());
    document.getElementById('assignBack').addEventListener('click', () => dialog.close());
    search.addEventListener('keydown', event => {
        if (event.key === 'Enter') event.preventDefault();
    });
})();
