// ManageOpportunities.js

// Add New Opportunity: clear the form and the edit id,
// otherwise save would update the last edited opportunity
function resetModalForAdd() {
    document.getElementById('opportunityModalLabel').textContent = 'Add Opportunity';
    document.getElementById('hfEditingOpportunityId').value = '';

    ['txtTitle', 'txtSeats', 'txtDeadline', 'txtStartDate', 'txtDescription'].forEach(function (id) {
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

    // the server asks to open the popup again (after Edit or a failed save)
    if (modalEl && window.opportunityModalMode) {
        document.getElementById('opportunityModalLabel').textContent =
            window.opportunityModalMode === 'edit' ? 'Edit Opportunity' : 'Add Opportunity';
        bootstrap.Modal.getOrCreateInstance(modalEl).show();
    }

    // stop double clicks while saving.
    // disabled a bit later so the server still knows Save was clicked
    if (saveBtn) {
        saveBtn.addEventListener('click', function () {
            if (!saveBtn.form.checkValidity()) return;      // browser shows what's missing
            setTimeout(function () { saveBtn.disabled = true; }, 0);
        });
    }
});