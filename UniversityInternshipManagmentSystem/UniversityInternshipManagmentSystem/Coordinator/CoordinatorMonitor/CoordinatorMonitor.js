(function () {
            var tabs = document.querySelectorAll('.monitor-tab');
            var panels = document.querySelectorAll('.monitor-panel');
            function queryValue(name) {
                var items = window.location.search.substring(1).split('&');
                for (var i = 0; i < items.length; i++) {
                    var pair = items[i].split('=');
                    if (pair[0] === name) return decodeURIComponent(pair.slice(1).join('=').replace(/\+/g, ' '));
                }
                return '';
            }
            function showPanel(id) {
                for (var i = 0; i < panels.length; i++) {
                    if (panels[i].id === id) panels[i].removeAttribute('hidden');
                    else panels[i].setAttribute('hidden', 'hidden');
                }
                for (var j = 0; j < tabs.length; j++) {
                    tabs[j].setAttribute('aria-selected', tabs[j].getAttribute('data-target') === id ? 'true' : 'false');
                }
            }
            for (var k = 0; k < tabs.length; k++) {
                tabs[k].addEventListener('click', function () { showPanel(this.getAttribute('data-target')); });
            }
            var view = queryValue('view');
            showPanel(queryValue('company') || view === 'companies' ? 'companiesPanel' :
                queryValue('academic') || view === 'academic' ? 'academicPanel' : 'studentsPanel');
        }());
        (function () {
            var dialog = document.querySelector('.detail-overlay[role="dialog"]');
            if (!dialog) return;
            var close = document.getElementById('closeDetail');
            if (!close) return;
            close.focus();
            dialog.addEventListener('click', function (event) { if (event.target === dialog) close.click(); });
            document.addEventListener('keydown', function (event) { if (event.key === 'Escape') close.click(); });
        }());
        (function () {
            var search = document.getElementById('studentSearch');
            var major = document.getElementById('majorFilter');
            var placement = document.getElementById('placementFilter');
            var rows = document.querySelectorAll('.student-row');
            var countLabel = document.getElementById('studentCount');
            var emptyLabel = document.getElementById('noFilterResults');
            var reset = document.getElementById('clearFilters');
            if (!search || !major || !placement || !countLabel || !emptyLabel || !reset) return;
            function filterStudents() {
                var query = search.value.trim().toLowerCase();
                var count = 0;
                for (var i = 0; i < rows.length; i++) {
                    var row = rows[i];
                    var searchable = row.getAttribute('data-search') || '';
                    var visible = (!query || searchable.indexOf(query) !== -1) &&
                        (!major.value || row.getAttribute('data-major') === major.value) &&
                        (!placement.value || row.getAttribute('data-placement') === placement.value);
                    row.style.display = visible ? '' : 'none';
                    if (visible) count++;
                }
                countLabel.textContent = count + ' of ' + rows.length + ' students';
                emptyLabel.style.display = count === 0 && rows.length > 0 ? '' : 'none';
            }
            search.addEventListener('input', filterStudents);
            major.addEventListener('change', filterStudents);
            placement.addEventListener('change', filterStudents);
            reset.addEventListener('click', function () { search.value = ''; major.value = ''; placement.value = ''; filterStudents(); });
            filterStudents();
        }());
        (function () {
            var menu = document.getElementById('studentActionMenu');
            var drawer = document.getElementById('studentDrawer');
            var backdrop = document.getElementById('drawerBackdrop');
            var closeButton = document.getElementById('drawerClose');
            var body = document.getElementById('drawerBody');
            var records = document.querySelectorAll('.drawer-record');
            var tabButtons = drawer.querySelectorAll('[data-drawer-tab]');
            var activeMenuButton = null;
            var activeStudent = null;
            var returnFocus = null;
            function hideMenu() {
                menu.hidden = true;
                if (activeMenuButton) activeMenuButton.setAttribute('aria-expanded', 'false');
                activeMenuButton = null;
            }
            function findRecord(id) {
                for (var i = 0; i < records.length; i++) {
                    if (records[i].getAttribute('data-student') === id) return records[i];
                }
                return null;
            }
            function selectTab(section) {
                if (section === 'progress') section = 'overview';
                for (var i = 0; i < tabButtons.length; i++) {
                    tabButtons[i].setAttribute('aria-selected', tabButtons[i].getAttribute('data-drawer-tab') === section ? 'true' : 'false');
                }
                var sections = body.querySelectorAll('[data-detail-section]');
                for (var j = 0; j < sections.length; j++) {
                    sections[j].hidden = sections[j].getAttribute('data-detail-section') !== section;
                }
            }
            function openDrawer(id, section, source) {
                var record = findRecord(id);
                if (!record) return;
                hideMenu();
                activeStudent = id;
                returnFocus = source;
                document.getElementById('drawerTitle').textContent = record.getAttribute('data-name') || 'Student';
                document.getElementById('drawerMajor').textContent = record.getAttribute('data-major') || '';
                body.innerHTML = record.innerHTML;
                selectTab(section || 'overview');
                drawer.hidden = false;
                backdrop.hidden = false;
                document.body.classList.add('drawer-open');
                closeButton.focus();
            }
            function closeDrawer() {
                if (drawer.hidden) return;
                drawer.hidden = true;
                backdrop.hidden = true;
                body.innerHTML = '';
                document.body.classList.remove('drawer-open');
                if (returnFocus) returnFocus.focus();
            }
            document.addEventListener('click', function (event) {
                var view = event.target.closest ? event.target.closest('.view-student') : null;
                var more = event.target.closest ? event.target.closest('.more-button') : null;
                if (view) {
                    openDrawer(view.getAttribute('data-student'), 'overview', view);
                    return;
                }
                if (more) {
                    if (activeMenuButton === more && !menu.hidden) { hideMenu(); return; }
                    hideMenu();
                    activeMenuButton = more;
                    more.setAttribute('aria-expanded', 'true');
                    var rect = more.getBoundingClientRect();
                    menu.hidden = false;
                    menu.style.left = Math.max(8, Math.min(rect.left, window.innerWidth - menu.offsetWidth - 8)) + 'px';
                    menu.style.top = (rect.bottom + menu.offsetHeight + 8 > window.innerHeight ? rect.top - menu.offsetHeight - 4 : rect.bottom + 4) + 'px';
                    menu.querySelector('button').focus();
                    return;
                }
                var action = event.target.closest ? event.target.closest('#studentActionMenu button') : null;
                if (action && activeMenuButton) {
                    openDrawer(activeMenuButton.getAttribute('data-student'), action.getAttribute('data-section'), activeMenuButton);
                    return;
                }
                if (!menu.contains(event.target)) hideMenu();
            });
            for (var i = 0; i < tabButtons.length; i++) {
                tabButtons[i].addEventListener('click', function () { selectTab(this.getAttribute('data-drawer-tab')); });
            }
            closeButton.addEventListener('click', closeDrawer);
            backdrop.addEventListener('click', closeDrawer);
            window.addEventListener('scroll', hideMenu, true);
            window.addEventListener('resize', hideMenu);
            document.addEventListener('keydown', function (event) {
                if (event.key === 'Escape') {
                    if (!menu.hidden) { var trigger = activeMenuButton; hideMenu(); if (trigger) trigger.focus(); }
                    else closeDrawer();
                }
                if (!menu.hidden && (event.key === 'ArrowDown' || event.key === 'ArrowUp')) {
                    var items = menu.querySelectorAll('button');
                    var current = Array.prototype.indexOf.call(items, document.activeElement);
                    items[(current + (event.key === 'ArrowDown' ? 1 : items.length - 1)) % items.length].focus();
                    event.preventDefault();
                }
                if (!drawer.hidden && event.key === 'Tab') {
                    var focusable = drawer.querySelectorAll('button:not([hidden]), a[href]');
                    if (focusable.length) {
                        var first = focusable[0], last = focusable[focusable.length - 1];
                        if (event.shiftKey && document.activeElement === first) { last.focus(); event.preventDefault(); }
                        else if (!event.shiftKey && document.activeElement === last) { first.focus(); event.preventDefault(); }
                    }
                }
            });
            // Old student links still open the same details drawer.
            var link = new URLSearchParams(window.location.search);
            var studentId = link.get('student');
            if (studentId) {
                var firstButton = document.querySelector('.view-student[data-student="' + studentId.replace(/[^a-zA-Z0-9_-]/g, '') + '"]');
                if (firstButton) openDrawer(studentId, link.get('section') || 'overview', firstButton);
            }
        }());
