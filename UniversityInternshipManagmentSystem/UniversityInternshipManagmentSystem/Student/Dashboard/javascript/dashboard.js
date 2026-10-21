/**
 * UIMS Student Dashboard Client Script
 * Simple, clean JavaScript for UI enhancements and report filtering.
 */

document.addEventListener('DOMContentLoaded', function () {
    // 1. Smoothly animate training hours progress bar
    var progressBar = document.getElementById('trainingProgressBar');
    if (progressBar) {
        var targetWidth = progressBar.getAttribute('data-progress-width') || '0%';
        progressBar.style.width = '0%';
        setTimeout(function () {
            progressBar.style.width = targetWidth;
        }, 150);
    }

    // 2. Client-side Task & Weekly Report Filter (All / Approved / Pending)
    var filterButtons = document.querySelectorAll('.task-filter-btn');
    var taskRows = document.querySelectorAll('.task-row');

    filterButtons.forEach(function (button) {
        button.addEventListener('click', function () {
            var filterValue = this.getAttribute('data-filter');

            // Update active button state
            filterButtons.forEach(function (btn) {
                btn.classList.remove('active', 'btn-primary');
                btn.classList.add('btn-outline-secondary');
            });
            this.classList.remove('btn-outline-secondary');
            this.classList.add('active', 'btn-primary');

            // Filter table rows
            taskRows.forEach(function (row) {
                var status = row.getAttribute('data-status');
                if (filterValue === 'all' || status === filterValue) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        });
    });
});
