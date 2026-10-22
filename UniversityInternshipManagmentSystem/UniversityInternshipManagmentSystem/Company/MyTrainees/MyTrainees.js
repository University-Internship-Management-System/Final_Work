(function () {
    'use strict';
    var page = document.querySelector('.trainees-page');
    var button = page && page.querySelector('.trainees-search input[type=submit]');
    var form = page && page.closest('form');
    if (!form || !button) return;
    var input = page.querySelector('.trainees-search input[type=text]');
    var loading = page.querySelector('.trainees-loading');
    if (!input || !loading) return;
    var busy = false;
    form.addEventListener('submit', function (event) {
        if (button.disabled || (event.submitter && event.submitter !== button)) return;
        if (busy) { event.preventDefault(); return; }
        busy = true;
        page.setAttribute('aria-busy', 'true');
        loading.hidden = false;
        button.value = 'Loading...';
    });
    window.addEventListener('pageshow', function () {
        busy = false;
        page.removeAttribute('aria-busy');
        loading.hidden = true;
        button.value = 'Search';
    });
}());
