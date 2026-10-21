// Student / Explore Opportunities page.
// 1) Live filter: hides the cards that do not contain the typed words, while the student types.
// 2) Enter key in the search box runs the real (server) search.
// The real search and the filters by company are still done by the backend; this file only makes the page feel faster.
(function() {
    'use strict';

    var searchBox = document.getElementById('txtSearch');   // ClientIDMode="Static" in the .aspx
    var searchBtn = document.getElementById('btnSearch');
    var grid = document.getElementById('oppGrid');
    var noMatch = document.getElementById('oppNoMatch');

    if (!searchBox || !grid) { return; }

    // The cards are the columns inside the grid (the Repeater writes one column per opportunity).
    function getCards() {
        return grid.querySelectorAll('.opp-card');
    }

    function normalize(text) {
        return (text || '').toLowerCase().replace(/\s+/g, ' ').trim();
    }

    function applyFilter() {
        var words = normalize(searchBox.value).split(' ').filter(Boolean);
        var cards = getCards();
        var shown = 0;

        for (var i = 0; i < cards.length; i++) {
            var column = cards[i].parentNode;                   // the .col-md-6 around the card
            var text = normalize(cards[i].textContent);
            var match = words.every(function(w) { return text.indexOf(w) !== -1; });

            if (match) {
                column.classList.remove('opp-hidden');
                shown++;
            } else {
                column.classList.add('opp-hidden');
            }
        }

        // Show the "no match" message only when there are cards but none matches.
        if (noMatch) {
            if (cards.length > 0 && shown === 0) {
                noMatch.classList.remove('opp-hidden');
            } else {
                noMatch.classList.add('opp-hidden');
            }
        }
    }

    searchBox.addEventListener('input', applyFilter);

    // Enter inside the search box = click the Search button (instead of submitting by accident).
    searchBox.addEventListener('keydown', function(e) {
        if (e.key === 'Enter') {
            e.preventDefault();
            if (searchBtn) { searchBtn.click(); }
        }
    });

    // If the page comes back with text already in the box (after a search), filter right away.
    applyFilter();
})();
