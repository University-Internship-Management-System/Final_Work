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
        initTopbarNav();
    });

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
