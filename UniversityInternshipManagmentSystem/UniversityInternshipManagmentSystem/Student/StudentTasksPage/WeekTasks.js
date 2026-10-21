// Small browser-side helpers for the week page. All the data and logic are in the C# code-behind.

(function () {
    "use strict";

    var popup = document.getElementById("pnlDetails");   // only exists in the page when the popup is open
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
