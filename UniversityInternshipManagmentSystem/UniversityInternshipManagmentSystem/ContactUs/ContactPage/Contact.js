(function () {
    'use strict';
    var page = document.querySelector('.contact-page');
    if (!page) return;
    var button = page.querySelector('input[type="submit"]');
    var form = page.closest('form');
    var busy = false;
    if (!button || !form) return;
    var message = page.querySelector('textarea');
    if (message) message.setAttribute('maxlength', '4000');
    form.addEventListener('submit', function (event) {
        if (event.submitter && event.submitter !== button) return;
        if (busy) { event.preventDefault(); return; }
        if (!form.checkValidity()) return;
        busy = true;
        page.setAttribute('aria-busy', 'true');
        page.querySelector('.contact-sending').hidden = false;
        button.value = 'Sending...';
        // Keep Web Forms submit name/value in the request; disabling it drops the event.
        button.style.pointerEvents = 'none';
        button.setAttribute('aria-disabled', 'true');
    });
    window.addEventListener('pageshow', function () {
        busy = false;
        page.removeAttribute('aria-busy');
        page.querySelector('.contact-sending').hidden = true;
        button.value = 'Send Message';
        button.style.pointerEvents = '';
        button.removeAttribute('aria-disabled');
    });
}());
