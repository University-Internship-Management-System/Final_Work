var monitorDataElement = document.getElementById('studentDetailData');
var monitorData = monitorDataElement ? JSON.parse(monitorDataElement.textContent || '{}') : {};
var monitorStudents = monitorData.Students || [];

(function () {
            var table = document.querySelector('#studentsPanel tbody');
            var majorFilter = document.getElementById('majorFilter');
            var majorNames = [];
            function show(value) {
                return value == null || String(value).trim() === '' ? '—' : String(value);
            }
            monitorStudents.forEach(function (student) {
                if (student.Major && majorNames.indexOf(student.Major) === -1) majorNames.push(student.Major);
                var row = document.createElement('tr');
                row.className = 'student-row';
                row.setAttribute('data-search', ((student.Name || '') + ' ' + (student.Email || '')).toLowerCase());
                row.setAttribute('data-major', student.Major || '');
                row.setAttribute('data-placement', student.Placed ? 'assigned' : 'unassigned');
                var cells = [
                    document.createElement('td'), document.createElement('td'), document.createElement('td'),
                    document.createElement('td'), document.createElement('td'), document.createElement('td')
                ];
                cells[0].className = 'student-name';
                var name = document.createElement('strong');
                name.textContent = show(student.Name);
                cells[0].appendChild(name);
                cells[0].appendChild(document.createElement('br'));
                var major = document.createElement('small');
                major.className = 'text-muted';
                major.textContent = show(student.Major);
                cells[0].appendChild(major);
                cells[1].textContent = show(student.CompanyName);
                cells[2].textContent = show(student.AcademicSupervisorName);
                var hours = document.createElement('strong');
                hours.textContent = student.ApprovedHours + ' / ' + student.RequiredHours + ' h';
                cells[3].appendChild(hours);
                var track = document.createElement('div');
                track.className = 'hours-track';
                var fill = document.createElement('span');
                fill.style.width = student.ApprovedPercent + '%';
                track.appendChild(fill);
                cells[3].appendChild(track);
                var stage = document.createElement('span');
                stage.className = 'status-badge';
                stage.textContent = show(student.CompletionStage);
                cells[4].appendChild(stage);
                var actions = document.createElement('div');
                actions.className = 'student-actions';
                var view = document.createElement('button');
                view.type = 'button';
                view.className = 'btn btn-outline-primary btn-sm view-student';
                view.setAttribute('data-student', student.Id);
                view.innerHTML = '&#128065; View Details';
                var more = document.createElement('button');
                more.type = 'button';
                more.className = 'btn btn-outline-primary btn-sm more-button';
                more.setAttribute('data-student', student.Id);
                more.setAttribute('aria-label', 'More actions for ' + (student.Name || ''));
                more.setAttribute('aria-haspopup', 'menu');
                more.setAttribute('aria-expanded', 'false');
                more.innerHTML = '&#8943;';
                actions.appendChild(view);
                actions.appendChild(more);
                cells[5].appendChild(actions);
                cells.forEach(function (cell) { row.appendChild(cell); });
                table.appendChild(row);
            });
            if (!monitorStudents.length) {
                var empty = document.createElement('tr');
                var cell = document.createElement('td');
                cell.colSpan = 6;
                cell.className = 'text-muted';
                cell.textContent = 'No students found.';
                empty.appendChild(cell);
                table.appendChild(empty);
            }
            majorNames.sort();
            majorNames.forEach(function (major) { majorFilter.add(new Option(major, major)); });
        }());

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
            var close = document.getElementById('closeDetail');
            var details = document.getElementById('userDetail');
            var query = new URLSearchParams(window.location.search);
            var academicId = query.get('academic');
            var companyId = query.get('company');
            if (!academicId && !companyId) return;
            var academic = !!academicId;
            var id = academic ? academicId : companyId;
            var supervisors = academic ? monitorData.Academics : monitorData.Companies;
            var supervisor = supervisors ? supervisors[id] : null;
            document.getElementById('detailTitle').textContent = academic ? 'Academic supervisor details' : 'Company supervisor details';
            function field(label, value) {
                var column = document.createElement('div');
                column.className = 'col-sm-6 col-xl-4';
                var list = document.createElement('dl');
                list.className = 'mb-0';
                var title = document.createElement('dt');
                title.textContent = label;
                var description = document.createElement('dd');
                description.textContent = value == null || String(value).trim() === '' ? '—' : value;
                list.appendChild(title);
                list.appendChild(description);
                column.appendChild(list);
                details.appendChild(column);
                return description;
            }
            if (supervisor) {
                details.className = 'row student-detail';
                field('Supervisor ID', id);
                field('Name', supervisor.Name);
                field('Email', supervisor.Email);
                field('Phone', supervisor.PhoneNumber);
                if (academic) {
                    if (supervisor.UniversityEmail !== supervisor.Email) field('University email', supervisor.UniversityEmail);
                    field('Major', supervisor.Major);
                } else {
                    if (supervisor.CompEmail !== supervisor.Email) field('Company email', supervisor.CompEmail);
                    field('Company', supervisor.CompanyName);
                    field('Location', supervisor.Location);
                }
                field('First login', supervisor.FirstLogin === true ? 'Yes' : 'No');
                var picture = field('Profile picture', null);
                try {
                    var url = new URL(supervisor.ProfilePicUrl);
                    if (url.protocol === 'http:' || url.protocol === 'https:') {
                        picture.textContent = '';
                        var link = document.createElement('a');
                        link.href = url.href;
                        link.target = '_blank';
                        link.rel = 'noopener noreferrer';
                        link.textContent = 'Open Profile picture';
                        picture.appendChild(link);
                    }
                } catch (error) { }
            } else {
                details.textContent = 'Supervisor record was not found.';
            }
            dialog.hidden = false;
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
            var records = monitorStudents;
            var tabButtons = drawer.querySelectorAll('[data-drawer-tab]');
            var activeMenuButton = null;
            var activeStudent = null;
            var returnFocus = null;
            function escapeHtml(value) {
                return String(value == null ? '' : value).replace(/[&<>"']/g, function (character) {
                    return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[character];
                });
            }
            function show(value) { return escapeHtml(value == null || String(value).trim() === '' ? '—' : value); }
            function detail(label, value) {
                return '<div class="col-sm-6 col-xl-4"><dl class="mb-0"><dt>' + show(label) +
                    '</dt><dd>' + show(value) + '</dd></dl></div>';
            }
            function linkDetail(label, value) {
                try {
                    var url = new URL(value);
                    if (url.protocol === 'http:' || url.protocol === 'https:') {
                        return '<div class="col-sm-6 col-xl-4"><dl class="mb-0"><dt>' + show(label) +
                            '</dt><dd><a target="_blank" rel="noopener noreferrer" href="' + escapeHtml(url.href) +
                            '">Open ' + show(label) + '</a></dd></dl></div>';
                    }
                } catch (error) { }
                return detail(label, null);
            }
            function passFlag(value) { return value === true ? 'Yes' : value === false ? 'No' : null; }
            function dateText(value) {
                if (!value) return null;
                var iso = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::\d{2}(?:\.\d+)?)?(Z|[+-]\d{2}:\d{2})$/i.exec(String(value));
                if (iso) return iso[1] + '-' + iso[2] + '-' + iso[3] + ' ' + iso[4] + ':' + iso[5] +
                    ' ' + (iso[6].toUpperCase() === 'Z' ? '+00:00' : iso[6]);
                var date = new Date(value);
                if (isNaN(date.getTime())) return value;
                var pad = function (number) { return String(number).padStart(2, '0'); };
                var offset = -date.getTimezoneOffset();
                var zone = (offset < 0 ? '-' : '+') + pad(Math.floor(Math.abs(offset) / 60)) + ':' + pad(Math.abs(offset) % 60);
                return date.getFullYear() + '-' + pad(date.getMonth() + 1) + '-' + pad(date.getDate()) + ' ' +
                    pad(date.getHours()) + ':' + pad(date.getMinutes()) + ' ' + zone;
            }
            function renderRecord(record) {
                var html = '<section data-detail-section="overview"><div class="drawer-section"><h3>Student information</h3><div class="row student-detail">';
                html += detail('Student ID', record.Id) + detail('Name', record.Name) + detail('Major', record.Major);
                html += detail('Email', record.Email) + (record.UniversityEmail !== record.Email ? detail('University email', record.UniversityEmail) : '');
                html += detail('Phone', record.Phone) + detail('GPA', record.Gpa);
                html += detail('Skills', Array.isArray(record.Skills) ? record.Skills.join(', ') : null);
                html += linkDetail('CV', record.CvUrl) + linkDetail('Portfolio', record.PortfolioUrl);
                html += '</div></div><div class="drawer-section"><h3>Placement and progress</h3><div class="row student-detail">';
                html += detail('Training company', record.CompanyName) + detail('Academic supervisor', record.AcademicSupervisorName);
                html += detail('Placement status', record.Placed ? 'Assigned' : 'Unassigned');
                html += detail('Approved training hours', record.ApprovedHours + ' / ' + record.RequiredHours + ' hours');
                html += detail('Evaluated task hours', record.EvaluatedHours + ' hours');
                html += detail('Tasks submitted or evaluated', record.SubmittedTasks + ' / ' + record.AssignedTasks);
                html += detail('Company report', record.CompanyReportStatus) + detail('Academic evaluation', record.AcademicReportStatus);
                html += detail('Completion stage', record.CompletionStage) + '</div></div></section>';

                html += '<section data-detail-section="tasks"><div class="drawer-section"><h3>Tasks</h3>';
                record.Tasks.forEach(function (task) {
                    html += '<div class="mb-3"><strong>' + show(task.Name) + '</strong>' +
                        '<div class="text-muted small">Week ' + show(task.Week) + ' · ' + task.Hours + ' hours · ' +
                        show(task.Status || 'Not submitted') + '</div>';
                    if (task.Feedback) html += '<div class="text-muted small">Company feedback: ' + show(task.Feedback) + '</div>';
                    html += '</div>';
                });
                if (!record.Tasks.length) html += '<p class="drawer-empty">No tasks assigned.</p>';
                html += '</div></section>';

                html += '<section data-detail-section="hours"><div class="drawer-section"><h3>Training hours</h3><div class="row student-detail">';
                html += detail('Assigned task hours', record.AssignedHours + ' hours');
                html += detail('Evaluated task hours', record.EvaluatedHours + ' hours');
                html += detail('Approved hours', record.ApprovedHours + ' hours');
                html += detail('Evaluated hours in unsigned weeks', record.PendingHours + ' hours');
                html += detail('Required hours', record.RequiredHours + ' hours');
                html += '</div><div class="hours-track hours-track-wide"><span style="width:' + record.ApprovedPercent +
                    '%"></span></div><p class="text-muted small mt-2 mb-0">Approved hours come from signed weekly reports.</p></div></section>';

                html += '<section data-detail-section="evaluations"><div class="drawer-section"><h3>Task evaluations</h3>';
                var evaluated = record.Tasks.filter(function (task) { return task.Status === 'Evaluated' && task.Score != null; });
                evaluated.forEach(function (task) {
                    html += '<div class="mb-3"><strong>' + show(task.Name) + '</strong><div>' +
                        show(task.Score) + ' / ' + show(task.MaxScore) + '</div>';
                    if (task.Feedback) html += '<div class="text-muted small">' + show(task.Feedback) + '</div>';
                    html += '</div>';
                });
                if (!evaluated.length) html += '<p class="drawer-empty">No evaluated task submissions.</p>';
                html += '</div><div class="drawer-section"><h3>Company final report</h3><div class="row student-detail">';
                html += detail('Status', record.CompanyReportStatus);
                var report = record.CompanyReport;
                if (report) {
                    html += detail('Approved hours', record.ApprovedHours + ' hours');
                    html += detail('Training start', dateText(report.StartDate)) + detail('Training end', dateText(report.EndDate));
                    html += detail('Sent at', dateText(report.SentAt)) + detail('Company comments', report.Comments);
                    var ratings = report.Ratings || {};
                    [['Responsibility', 'Responsibility'], ['WorkingHours', 'Working hours'], ['Accuracy', 'Accuracy'],
                        ['Teamwork', 'Teamwork'], ['Adaptation', 'Adaptation'], ['LearningSpeed', 'Learning speed']]
                        .forEach(function (rating) { if (ratings[rating[0]] != null) html += detail(rating[1], ratings[rating[0]]); });
                }
                html += '</div></div><div class="drawer-section"><h3>Academic final evaluation</h3><div class="row student-detail">';
                html += detail('Status', record.AcademicReportStatus);
                var academic = record.AcademicReport;
                if (academic) {
                    html += detail('Academic pass decision', passFlag(academic.IsPassAcademic));
                    html += detail('Academic comments', academic.Comments) + detail('Sent at', dateText(academic.SentAt));
                    html += detail('Last updated', dateText(academic.UpdatedAt));
                }
                html += '</div></div><div class="drawer-section"><h3>Coordinator completion</h3><div class="row student-detail">';
                html += detail('Stage', record.CompletionStage);
                var certificate = record.Certificate;
                if (certificate) {
                    html += detail('Certificate ID', certificate.CertificateId) + detail('Opportunity ID', certificate.OpportunityId);
                    html += detail('Company pass flag', passFlag(certificate.IsPassCompany));
                    html += detail('Academic pass flag', passFlag(certificate.IsPassAcademic));
                    html += detail('Coordinator pass flag', passFlag(certificate.IsPassAdmin));
                    html += detail('Coordinator comments', certificate.AdminComments);
                    html += detail('Approved at', dateText(certificate.ApprovedAt)) + detail('Approved by', certificate.ApprovedBy);
                }
                return html + '</div></div></section>';
            }
            function hideMenu() {
                menu.hidden = true;
                if (activeMenuButton) activeMenuButton.setAttribute('aria-expanded', 'false');
                activeMenuButton = null;
            }
            function findRecord(id) {
                for (var i = 0; i < records.length; i++) {
                    if (records[i].Id === id) return records[i];
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
                document.getElementById('drawerTitle').textContent = record.Name || 'Student';
                document.getElementById('drawerMajor').textContent = record.Major || '';
                body.innerHTML = renderRecord(record);
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
            // روابط الطلاب القديمة تفتح نافذة التفاصيل نفسها.
            var link = new URLSearchParams(window.location.search);
            var studentId = link.get('student');
            if (studentId) {
                var firstButton = document.querySelector('.view-student[data-student="' + studentId.replace(/[^a-zA-Z0-9_-]/g, '') + '"]');
                if (firstButton) openDrawer(studentId, link.get('section') || 'overview', firstButton);
            }
        }());
