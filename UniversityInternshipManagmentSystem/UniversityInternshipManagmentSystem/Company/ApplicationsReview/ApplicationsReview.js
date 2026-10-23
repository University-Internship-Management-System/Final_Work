// ApplicationsReview.js

// Reject needs a reason: stop if the reason box is empty
function confirmReject() {
    var box = document.getElementById('txtReason');
    if (box && box.value.trim() === '') {
        alert('Please write the reason for rejection.');
        box.focus();
        return false;
    }
    return confirm('Reject this application?');
}

// The server asks to open the application window: after "View", or when a decision was refused
document.addEventListener('DOMContentLoaded', function () {
    if (window.openApplicationModal) {
        bootstrap.Modal.getOrCreateInstance(document.getElementById('applicationModal')).show();
    }
});