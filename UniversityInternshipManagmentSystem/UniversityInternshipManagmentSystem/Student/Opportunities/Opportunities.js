document.addEventListener('DOMContentLoaded', function () {
    const searchInput = document.getElementById('txtSearch');
    const companySelect = document.getElementById('ddlCompany');
    const searchBtn = document.getElementById('btnSearch');
    const resetBtn = document.getElementById('btnReset');

    // 1. عند الضغط على زر البحث (Search)
    if (searchBtn) {
        searchBtn.addEventListener('click', function (e) {
            e.preventDefault();

            let keyword = searchInput ? searchInput.value.toLowerCase().trim() : "";
            let selectedCompany = companySelect ? companySelect.value.toLowerCase().trim() : "";

            // جلب جميع بطاقات الفرص المعروضة ديناميكياً
            let opportunityCards = document.querySelectorAll('.opp-item');

            opportunityCards.forEach(card => {
                let cardText = card.innerText.toLowerCase();
                let cardCompany = card.getAttribute('data-company') || "";

                // مطابقة الكلمة المفتاحية (في العنوان أو الوصف أو الشركة)
                let matchesKeyword = keyword === "" || cardText.includes(keyword);

                // مطابقة الشركة المختارة من القائمة المنسدلة
                let matchesCompany = selectedCompany === "" || cardCompany === selectedCompany;

                // إظهار أو إخفاء البطاقة بناءً على الشروط
                if (matchesKeyword && matchesCompany) {
                    card.style.display = ""; // إظهار
                } else {
                    card.style.display = "none"; // إخفاء
                }
            });
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
            let opportunityCards = document.querySelectorAll('.opp-item');
            opportunityCards.forEach(card => {
                card.style.display = "";
            });
        });
    }
});