document.addEventListener('DOMContentLoaded', function () {
    const searchInput = document.getElementById('txtSearch');
    const companySelect = document.getElementById('ddlCompany');
    const searchBtn = document.getElementById('btnSearch');
    const resetBtn = document.getElementById('btnReset');
    const noMatch = document.getElementById('oppNoMatch');
    const countLabel = document.getElementById('lblCount');
    const allCountText = countLabel ? countLabel.textContent : "";

    // إظهار البطاقات المطابقة فقط، ثم تحديث العدد ورسالة "لا توجد نتائج"
    function applyFilter(keyword, selectedCompany) {
        // جلب جميع بطاقات الفرص المعروضة ديناميكياً
        let opportunityCards = document.querySelectorAll('.opp-item');
        let visibleCount = 0;

        opportunityCards.forEach(card => {
            // data-search = العنوان والشركة والوصف والموقع والتخصصات (بدون نصوص الأزرار)
            let cardText = card.getAttribute('data-search') || "";
            let cardCompany = card.getAttribute('data-company') || "";

            // مطابقة الكلمة المفتاحية (في العنوان أو الوصف أو الشركة)
            let matchesKeyword = keyword === "" || cardText.includes(keyword);

            // مطابقة الشركة المختارة من القائمة المنسدلة
            let matchesCompany = selectedCompany === "" || cardCompany === selectedCompany;

            // إظهار أو إخفاء البطاقة بناءً على الشروط
            if (matchesKeyword && matchesCompany) {
                card.style.display = ""; // إظهار
                visibleCount++;
            } else {
                card.style.display = "none"; // إخفاء
            }
        });

        let isFiltering = keyword !== "" || selectedCompany !== "";

        // "No opportunities match" only when the search hides every card
        if (noMatch) noMatch.classList.toggle('opp-hidden', !(isFiltering && opportunityCards.length > 0 && visibleCount === 0));

        // "X of Y opportunities" while searching, the original text after Reset
        if (countLabel) countLabel.textContent = isFiltering ? visibleCount + " of " + opportunityCards.length + " opportunities" : allCountText;
    }

    // 1. عند الضغط على زر البحث (Search)
    if (searchBtn) {
        searchBtn.addEventListener('click', function (e) {
            e.preventDefault();

            let keyword = searchInput ? searchInput.value.toLowerCase().trim() : "";
            let selectedCompany = companySelect ? companySelect.value.toLowerCase().trim() : "";
            applyFilter(keyword, selectedCompany);
        });
    }

    // 2. عند الضغط على زر إعادة التعيين (Reset)
    if (resetBtn) {
        resetBtn.addEventListener('click', function (e) {
            e.preventDefault();

            // تفريغ حقل البحث وإعادة القائمة للافتراضي
            if (searchInput) searchInput.value = "";
            if (companySelect) companySelect.selectedIndex = 0;

            // إظهار جميع البطاقات مرة أخرى
            applyFilter("", "");
        });
    }
});