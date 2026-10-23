// ManageOpportunities.js

// "Add New Opportunity": an empty form, and forget any opportunity that was opened with Edit before
// (otherwise Save would update that old opportunity instead of creating a new one)
function resetModalForAdd() {
    document.getElementById('opportunityModalLabel').textContent = 'Add Opportunity';
    document.getElementById('hfEditingOpportunityId').value = '';

    ['txtTitle', 'txtSeats', 'txtDeadline', 'txtDescription'].forEach(function (id) {
        var box = document.getElementById(id);
        if (box) box.value = '';
    });

    document.querySelectorAll('#chkMajors input[type="checkbox"]').forEach(function (box) {
        box.checked = false;
    });

    var error = document.getElementById('pnlFormError');
    if (error) error.style.display = 'none';
}

document.addEventListener('DOMContentLoaded', function() {
    var modalEl = document.getElementById('opportunityModal');
    var saveBtn = document.getElementById('btnSaveOpportunity');

    // The server asks to open the form again: after Edit, or when a save was refused (the reason is shown inside it)
    if (modalEl && window.opportunityModalMode) {
        document.getElementById('opportunityModalLabel').textContent =
            window.opportunityModalMode === 'edit' ? 'Edit Opportunity' : 'Add Opportunity';
        bootstrap.Modal.getOrCreateInstance(modalEl).show();
    }

    // One click = one save: block a second click while the page is sending.
    // It is disabled a moment later, so the server still knows that Save was the button pressed.
    if (saveBtn) {
        saveBtn.addEventListener('click', function () {
            if (!saveBtn.form.checkValidity()) return;      // the browser shows what is missing and sends nothing
            setTimeout(function () { saveBtn.disabled = true; }, 0);
        });
    }
});