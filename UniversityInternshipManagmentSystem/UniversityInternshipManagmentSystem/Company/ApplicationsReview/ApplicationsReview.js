// ApplicationsReview.js

// Reject first shows the reason box (Accept is hidden until Cancel)
function showRejectBox() {
    document.getElementById('decisionButtons').classList.add('d-none');
    var box = document.getElementById('rejectBox');
    box.classList.remove('d-none');
    document.getElementById('txtReason').focus({ preventScroll: true });
    // the reason box is the last thing in the popup, so scroll to the bottom to show its buttons
    var body = box.closest('.modal-body');
    body.scrollTo({ top: body.scrollHeight, behavior: 'smooth' });
}

// Cancel: forget the reason and go back to Accept / Reject
function hideRejectBox() {
    document.getElementById('txtReason').value = '';
    document.getElementById('rejectBox').classList.add('d-none');
    document.getElementById('decisionButtons').classList.remove('d-none');
}

// reject needs a reason
function confirmReject() {
    var box = document.getElementById('txtReason');
    if (box && box.value.trim() === '') {
        alert('Please write the reason for rejection.');
        box.focus();
        return false;
    }
    return confirm('Reject this application?');
}

// the server asks to open the popup (after View or a failed decision)
document.addEventListener('DOMContentLoaded', function () {
    if (window.openRejectBox) {
        showRejectBox();
    }
    if (window.openApplicationModal) {
        bootstrap.Modal.getOrCreateInstance(document.getElementById('applicationModal')).show();
    }
});
