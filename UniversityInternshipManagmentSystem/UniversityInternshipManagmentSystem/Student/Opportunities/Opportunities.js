document.addEventListener('DOMContentLoaded', function () {
    const searchInput = document.getElementById('txtSearch');
    const companySelect = document.getElementById('ddlCompany');
    const searchBtn = document.getElementById('btnSearch');
    const resetBtn = document.getElementById('btnReset');
    const noMatch = document.getElementById('oppNoMatch');
    const countLabel = document.getElementById('lblCount');
    const allCountText = countLabel ? countLabel.textContent : "";

    // show only the cards that match, and update the count
    function applyFilter(keyword, selectedCompany) {
        let opportunityCards = document.querySelectorAll('.opp-item');
        let visibleCount = 0;

        opportunityCards.forEach(card => {
            // data-search and data-company are set in the code behind
            let cardText = card.getAttribute('data-search') || "";
            let cardCompany = card.getAttribute('data-company') || "";

            let matchesKeyword = keyword === "" || cardText.includes(keyword);

            let matchesCompany = selectedCompany === "" || cardCompany === selectedCompany;

            if (matchesKeyword && matchesCompany) {
                card.style.display = "";
                visibleCount++;
            } else {
                card.style.display = "none";
            }
        });

        let isFiltering = keyword !== "" || selectedCompany !== "";

        // show "no results" only if the search hid every card
        if (noMatch) noMatch.classList.toggle('opp-hidden', !(isFiltering && opportunityCards.length > 0 && visibleCount === 0));

        // "X of Y opportunities" while searching
        if (countLabel) countLabel.textContent = isFiltering ? visibleCount + " of " + opportunityCards.length + " opportunities" : allCountText;
    }

    // search button
    if (searchBtn) {
        searchBtn.addEventListener('click', function (e) {
            e.preventDefault();

            let keyword = searchInput ? searchInput.value.toLowerCase().trim() : "";
            let selectedCompany = companySelect ? companySelect.value.toLowerCase().trim() : "";
            applyFilter(keyword, selectedCompany);
        });
    }

    // reset button
    if (resetBtn) {
        resetBtn.addEventListener('click', function (e) {
            e.preventDefault();

            if (searchInput) searchInput.value = "";
            if (companySelect) companySelect.selectedIndex = 0;

            applyFilter("", "");
        });
    }
});