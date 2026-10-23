// MyApplications.js

document.addEventListener('DOMContentLoaded', function () {

    // ask before confirming an offer
    const confirmButtons = document.querySelectorAll('.btn-confirm-action');
    confirmButtons.forEach(button => {
        button.addEventListener('click', function (e) {
            const confirmed = confirm('Are you sure you want to confirm this training offer? This action will finalize your choice and cancel your other active applications.');
            if (!confirmed) {
                e.preventDefault();
            }
        });
    });

    // ask before rejecting an offer
    const rejectButtons = document.querySelectorAll('.btn-reject-action');
    rejectButtons.forEach(button => {
        button.addEventListener('click', function (e) {
            const confirmed = confirm('Are you sure you want to reject this training offer?');
            if (!confirmed) {
                e.preventDefault();
            }
        });
    });

});