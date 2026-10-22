/**
 * University Internship Management System (UIMS)
 * King Abdullah II School of Information Technology - The University of Jordan
 * Login & Authentication Module JavaScript
 */

(function () {
    "use strict";

    /**
     * Initializes all event listeners when DOM content is fully loaded.
     */
    document.addEventListener("DOMContentLoaded", function () {
        initPasswordToggles();
        initDemoAutofill();
        initForgotModal();
<<<<<<< HEAD
        initPasswordMeter();
=======
        initTopbarNav();
>>>>>>> 74f40996fe90a8b391fadde64cedaeedf53b0d38
    });

    /**
     * First-login page: shows how strong the new password is and whether the two boxes match.
     * (Only a hint for the person; the server checks the password again.)
     */
    function initPasswordMeter() {
        var newInput = document.getElementById("txtNewPassword");
        var confirmInput = document.getElementById("txtConfirmPassword");
        var bar = document.getElementById("pwMeterBar");
        var text = document.getElementById("pwMeterText");
        var match = document.getElementById("pwMatch");
        if (!newInput || !bar || !text) return;

        var levels = [
            { width: "12%", color: "#DC2626", label: "Too short" },
            { width: "35%", color: "#F59E0B", label: "Weak" },
            { width: "60%", color: "#EAB308", label: "Fair" },
            { width: "82%", color: "#65A30D", label: "Good" },
            { width: "100%", color: "#16A34A", label: "Strong" }
        ];

        function score(value) {
            if (value.length < 6) return 0;
            var points = 1;
            if (value.length >= 10) points++;
            if (/[a-z]/.test(value) && /[A-Z]/.test(value)) points++;
            if (/\d/.test(value)) points++;
            if (/[^A-Za-z0-9]/.test(value)) points++;
            return Math.min(points, 4);
        }

        function update() {
            var value = newInput.value;
            if (value.length === 0) {
                bar.style.width = "0";
                text.textContent = "At least 6 characters. Longer is stronger.";
                text.style.color = "";
            } else {
                var level = levels[score(value)];
                bar.style.width = level.width;
                bar.style.backgroundColor = level.color;
                text.textContent = level.label;
                text.style.color = level.color;
            }
            if (match && confirmInput) {
                if (confirmInput.value.length === 0) {
                    match.textContent = "";
                    match.className = "pw-match";
                } else if (confirmInput.value === value) {
                    match.textContent = "Passwords match";
                    match.className = "pw-match ok";
                } else {
                    match.textContent = "Passwords do not match yet";
                    match.className = "pw-match bad";
                }
            }
        }

        newInput.addEventListener("input", update);
        if (confirmInput) confirmInput.addEventListener("input", update);
    }

    /**
     * Sets up password visibility toggles via declarative [data-toggle-target] attributes.
     */
    function initPasswordToggles() {
        var toggleButtons = document.querySelectorAll("[data-toggle-target]");
        toggleButtons.forEach(function (button) {
            button.addEventListener("click", function () {
                var targetId = button.getAttribute("data-toggle-target");
                var input = document.getElementById(targetId);
                var icon = button.querySelector("i");

                if (!input) return;

                if (input.type === "password") {
                    input.type = "text";
                    if (icon) {
                        icon.classList.remove("bi-eye");
                        icon.classList.add("bi-eye-slash");
                    }
                } else {
                    input.type = "password";
                    if (icon) {
                        icon.classList.remove("bi-eye-slash");
                        icon.classList.add("bi-eye");
                    }
                }
            });
        });
    }

    /**
     * Sets up quick autofill buttons for evaluation demo accounts via [data-demo-email].
     */
    function initDemoAutofill() {
        var demoButtons = document.querySelectorAll("[data-demo-email]");
        var emailInput = document.getElementById("txtEmail");
        var passwordInput = document.getElementById("txtPassword");

        demoButtons.forEach(function (button) {
            button.addEventListener("click", function () {
                var email = button.getAttribute("data-demo-email") || "";
                var password = button.getAttribute("data-demo-password") || "";

                if (emailInput) {
                    emailInput.value = email;
                    flashElement(emailInput);
                }

                if (passwordInput) {
                    passwordInput.value = password;
                    flashElement(passwordInput);
                }
            });
        });
    }

    /**
     * Sets up password recovery modal trigger.
     */
    function initForgotModal() {
        var forgotButton = document.getElementById("btnOpenForgotModal");
        if (forgotButton) {
            forgotButton.addEventListener("click", function (e) {
                e.preventDefault();
                openForgotModal();
            });
        }
    }

    /**
     * Helper to show a brief green flash animation when autofilling.
     * @param {HTMLElement} el
     */
    function flashElement(el) {
        el.classList.remove("autofill-highlight");
        // Trigger reflow to restart CSS animation
        void el.offsetWidth;
        el.classList.add("autofill-highlight");
    }

    /**
     * Opens the password recovery modal and transfers the current email if provided.
     */
    function openForgotModal() {
        var emailInput = document.getElementById("txtEmail");
        var recoveryInput = document.getElementById("txtRecoveryEmail");
        var modalEl = document.getElementById("forgotModal");

        if (emailInput && recoveryInput && emailInput.value) {
            recoveryInput.value = emailInput.value.trim();
        }

        if (modalEl && typeof bootstrap !== "undefined") {
            var modalInstance = bootstrap.Modal.getInstance(modalEl) || new bootstrap.Modal(modalEl);
            modalInstance.show();
        }
    }

    /**
     * Initializes responsive navigation toggler for the topbar and updates copyright year.
     */
    function initTopbarNav() {
        var menu = document.getElementById("menuToggle");
        var links = document.getElementById("navlinks");
        if (menu && links) {
            menu.addEventListener("click", function () {
                var open = links.classList.toggle("open");
                menu.setAttribute("aria-expanded", String(open));
                menu.textContent = open ? "✕" : "☰";
            });
            links.querySelectorAll("a").forEach(function (a) {
                a.addEventListener("click", function () {
                    links.classList.remove("open");
                    menu.setAttribute("aria-expanded", "false");
                    menu.textContent = "☰";
                });
            });
        }
        var yearEl = document.getElementById("year");
        if (yearEl) {
            yearEl.textContent = new Date().getFullYear();
        }
    }

    // Expose openForgotModal globally so server-side scripts can invoke it cleanly
    window.openForgotModal = openForgotModal;
})();
