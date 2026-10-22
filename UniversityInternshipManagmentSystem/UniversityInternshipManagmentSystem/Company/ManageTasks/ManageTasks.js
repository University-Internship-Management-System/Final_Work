// Small browser-side helpers for the company task pages. All the data and logic are in the C# code-behind.

(function () {
    "use strict";

    // The popup only exists in the page when it is open: "pnlNew" on the Tasks page, "pnlReview" on the Review page
    var popup = document.getElementById("pnlNew") || document.getElementById("pnlReview");
    if (!popup) return;

    // Do not scroll the page behind the popup
    document.body.style.overflow = "hidden";

    // Escape closes the popup (it presses the X button, which posts back to the server)
    document.addEventListener("keydown", function (e) {
        if (e.key !== "Escape") return;
        var close = document.getElementById("btnClose");
        if (close) close.click();
    });
})();
