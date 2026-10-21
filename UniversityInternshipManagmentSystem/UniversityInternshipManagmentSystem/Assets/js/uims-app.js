// ========================================================
// University Internship Management System (UIMS)
// Core Application Frontend Utilities
// ========================================================

document.addEventListener("DOMContentLoaded", function () {
    // Enable Bootstrap tooltips if any
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Check Firebase indicator badge
    updateFirebaseStatusBadge();
});

function togglePasswordVisibility(fieldId, iconId) {
    const input = document.getElementById(fieldId);
    const icon = document.getElementById(iconId);
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
}

function showToast(message, type = "success") {
    let container = document.getElementById("toast-container");
    if (!container) {
        container = document.createElement("div");
        container.id = "toast-container";
        document.body.appendChild(container);
    }

    const toastEl = document.createElement("div");
    let bgClass = "bg-success text-white";
    let icon = "bi-check-circle-fill";

    if (type === "danger" || type === "error") {
        bgClass = "bg-danger text-white";
        icon = "bi-exclamation-triangle-fill";
    } else if (type === "warning") {
        bgClass = "bg-warning text-dark";
        icon = "bi-exclamation-circle-fill";
    } else if (type === "info") {
        bgClass = "bg-info text-dark";
        icon = "bi-info-circle-fill";
    }

    toastEl.className = `uims-toast toast align-items-center ${bgClass} border-0 show animate__animated animate__fadeInDown`;
    toastEl.setAttribute("role", "alert");
    toastEl.innerHTML = `
        <div class="d-flex">
            <div class="toast-body d-flex align-items-center gap-2">
                <i class="bi ${icon} fs-5"></i>
                <div>${message}</div>
            </div>
            <button type="button" class="btn-close ${type === 'warning' || type === 'info' ? '' : 'btn-close-white'} me-2 m-auto" data-bs-dismiss="toast"></button>
        </div>
    `;

    container.appendChild(toastEl);
    setTimeout(() => {
        toastEl.classList.remove("show");
        setTimeout(() => toastEl.remove(), 400);
    }, 4500);
}

function updateFirebaseStatusBadge() {
    const badge = document.getElementById("firebase-status-badge");
    if (!badge) return;

    if (window.isFirebaseConfigured && window.isFirebaseConfigured()) {
        badge.innerHTML = '<span class="badge bg-success"><i class="bi bi-cloud-check me-1"></i> Firebase Connected</span>';
    } else {
        badge.innerHTML = '<span class="badge bg-light text-muted border" title="Operating in local mode. You can link Firebase credentials at any time."><i class="bi bi-hdd-network me-1"></i> Local Data Mode</span>';
    }
}

function printCertificate() {
    window.print();
}
