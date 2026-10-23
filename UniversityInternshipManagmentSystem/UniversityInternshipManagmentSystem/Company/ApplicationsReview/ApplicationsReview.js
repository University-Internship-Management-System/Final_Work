// ApplicationsReview.js

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
    if (window.openApplicationModal) {
        bootstrap.Modal.getOrCreateInstance(document.getElementById('applicationModal')).show();
    }
});