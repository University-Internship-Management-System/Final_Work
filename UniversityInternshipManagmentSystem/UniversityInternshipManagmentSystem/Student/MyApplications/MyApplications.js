// MyApplications.js - التعامل مع التفاعلات في صفحة طلباتي

document.addEventListener('DOMContentLoaded', function () {

    // تأكيد عملية قبول العرض (Confirm)
    const confirmButtons = document.querySelectorAll('.btn-confirm-action');
    confirmButtons.forEach(button => {
        button.addEventListener('click', function (e) {
            const confirmed = confirm('Are you sure you want to confirm this training offer? This action will finalize your choice and cancel your other active applications.');
            if (!confirmed) {
                e.preventDefault();
            }
        });
    });

    // تأكيد عملية رفض العرض (Reject)
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