/**
 * Supervisor Account Page Scripts - UIMS
 * Academic Supervisor Profile & Password Management
 */

document.addEventListener('DOMContentLoaded', function () {
    initPasswordToggles();
    initPasswordLiveValidation();
    initAutoDismissAlerts();
});

/**
 * Toggles show/hide password visibility for password inputs
 */
function initPasswordToggles() {
    const toggleButtons = document.querySelectorAll('.password-toggle-btn');

    toggleButtons.forEach(function (button) {
        button.addEventListener('click', function (e) {
            e.preventDefault();
            const targetId = button.getAttribute('data-target');
            if (!targetId) return;

            const input = document.getElementById(targetId);
            if (!input) return;

            const icon = button.querySelector('i');
            if (input.type === 'password') {
                input.type = 'text';
                if (icon) {
                    icon.classList.remove('bi-eye');
                    icon.classList.add('bi-eye-slash');
                }
                button.setAttribute('aria-label', 'Hide password');
            } else {
                input.type = 'password';
                if (icon) {
                    icon.classList.remove('bi-eye-slash');
                    icon.classList.add('bi-eye');
                }
                button.setAttribute('aria-label', 'Show password');
            }
        });
    });
}

/**
 * Provides live client-side feedback on password rules
 */
function initPasswordLiveValidation() {
    const newPwdInput = document.querySelector('[data-role="new-password"]');
    const confirmPwdInput = document.querySelector('[data-role="confirm-password"]');
    const ruleLength = document.getElementById('ruleLength');
    const ruleMatch = document.getElementById('ruleMatch');

    if (!newPwdInput || !confirmPwdInput) return;

    function checkRules() {
        const newPwd = newPwdInput.value;
        const confirmPwd = confirmPwdInput.value;

        // Rule 1: Length >= 6
        if (ruleLength) {
            const icon = ruleLength.querySelector('i');
            if (newPwd.length >= 6) {
                ruleLength.classList.add('valid');
                if (icon) {
                    icon.className = 'bi bi-check-circle-fill text-success';
                }
            } else {
                ruleLength.classList.remove('valid');
                if (icon) {
                    icon.className = 'bi bi-circle text-muted';
                }
            }
        }

        // Rule 2: Passwords match
        if (ruleMatch) {
            const icon = ruleMatch.querySelector('i');
            if (confirmPwd.length > 0 && newPwd === confirmPwd) {
                ruleMatch.classList.add('valid');
                if (icon) {
                    icon.className = 'bi bi-check-circle-fill text-success';
                }
            } else {
                ruleMatch.classList.remove('valid');
                if (icon) {
                    icon.className = 'bi bi-circle text-muted';
                }
            }
        }
    }

    newPwdInput.addEventListener('input', checkRules);
    confirmPwdInput.addEventListener('input', checkRules);
}

/**
 * Automatically fades and dismisses success alert banners after 6 seconds
 */
function initAutoDismissAlerts() {
    const alerts = document.querySelectorAll('.uims-alert-success');
    alerts.forEach(function (alertBox) {
        setTimeout(function () {
            alertBox.style.transition = 'opacity 0.5s ease';
            alertBox.style.opacity = '0';
            setTimeout(function () {
                alertBox.style.display = 'none';
            }, 500);
        }, 6000);
    });
}
