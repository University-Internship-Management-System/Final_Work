(function () {
    var root = document.querySelector('.student-dashboard');
    var status = document.getElementById('student-request-status');
    var form = root.closest('form');
    var submitting = false;
    root.addEventListener('click', function (event) {
        var link = event.target.closest('a');
        if (!link || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey || event.button !== 0) return;
        var url = new URL(link.href, location.href);
        if (url.origin === location.origin && url.pathname !== location.pathname && !link.target) {
            status.hidden = false;
            status.textContent = 'Loading student data…';
            root.setAttribute('aria-busy', 'true');
        }
    });
    form.addEventListener('submit', function (event) {
        var button = event.submitter;
        if (!button || !root.contains(button) || !(button.classList.contains('sd-save-button') || button.classList.contains('sd-signin-button') || button.classList.contains('sd-cancel-button'))) return;
        if (submitting) { event.preventDefault(); return; }
        submitting = true;
        status.hidden = false;
        status.textContent = button.classList.contains('sd-signin-button') ? 'Signing in and reading Firebase…' : button.classList.contains('sd-cancel-button') ? 'Reloading your saved profile…' : 'Validating and saving your profile…';
        root.setAttribute('aria-busy', 'true');
        button.setAttribute('aria-disabled', 'true');
    });
    window.addEventListener('pageshow', function () {
        submitting = false;
        status.hidden = true;
        root.removeAttribute('aria-busy');
        root.querySelectorAll('.sd-save-button, .sd-signin-button, .sd-cancel-button').forEach(function (button) {
            button.removeAttribute('aria-disabled');
        });
    });
}());
