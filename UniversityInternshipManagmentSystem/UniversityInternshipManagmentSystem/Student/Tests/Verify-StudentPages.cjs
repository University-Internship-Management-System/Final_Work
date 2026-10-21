// Run after starting a dedicated local headless Chrome with --remote-debugging-port=9231.
// Uses only Node's built-in WebSocket/fetch APIs. Never connects to Firebase.
const fs = require('node:fs');
const path = require('node:path');

async function main() {
    const baseUrl = process.env.STUDENT_BASE_URL || 'http://localhost:53191';
    const expectBlocked = process.env.STUDENT_EXPECT_AUTHENTICATED !== '1';
    const offlineLayout = process.env.STUDENT_OFFLINE_LAYOUT_TEST === '1';
    const offlineEditing = offlineLayout && process.env.STUDENT_OFFLINE_EDIT_TEST === '1';
    let firebaseRequests = 0;
    let scriptErrors = 0;
    const target = await (await fetch((process.env.STUDENT_DEBUG_URL || 'http://127.0.0.1:9231') + '/json/new?about:blank', { method: 'PUT' })).json();
    const socket = new WebSocket(target.webSocketDebuggerUrl);
    await new Promise((resolve, reject) => { socket.onopen = resolve; socket.onerror = reject; });
    let id = 0;
    const pending = new Map();
    socket.onmessage = ({ data }) => {
        const message = JSON.parse(data);
        if (message.method === 'Network.requestWillBeSent' && /firebaseio\.com|firebasedatabase\.app/.test(message.params.request.url)) firebaseRequests++;
        if (message.method === 'Runtime.exceptionThrown') scriptErrors++;
        const task = pending.get(message.id);
        if (!task) return;
        pending.delete(message.id);
        message.error ? task.reject(new Error(message.error.message)) : task.resolve(message.result);
    };
    const send = (method, params = {}) => new Promise((resolve, reject) => {
        const requestId = ++id;
        pending.set(requestId, { resolve, reject });
        socket.send(JSON.stringify({ id: requestId, method, params }));
    });
    try {
        await send('Page.enable');
        await send('Network.enable');
        await send('Runtime.enable');
        for (const width of [390, 768, 1440]) {
            await send('Emulation.setDeviceMetricsOverride', { width, height: 1000, deviceScaleFactor: 1, mobile: width < 768 });
            for (const page of ['Dashboard', 'Profile']) {
                const folder = page === 'Dashboard' ? 'StudentDashboardPage' : 'StudentProfilePage';
                await send('Page.navigate', { url: baseUrl + '/Student/' + folder + '/' + page });
                let ready = false;
                for (let attempt = 0; attempt < 100; attempt++) {
                    const result = await send('Runtime.evaluate', { expression: 'document.readyState === "complete" && document.title.includes("' + page.replace('Profile', 'My Profile').replace('Dashboard', 'Student Dashboard') + '")', returnByValue: true });
                    if (result.result.value) { ready = true; break; }
                    await new Promise(resolve => setTimeout(resolve, 100));
                }
                if (!ready) throw new Error(page + ' did not finish loading');
                const result = await send('Runtime.evaluate', {
                    expression: `JSON.stringify({ width: innerWidth, content: document.documentElement.scrollWidth, viewport: document.documentElement.clientWidth, title: document.title, images: [...document.images].every(i => i.complete && i.naturalWidth > 0), sidebar: document.querySelectorAll('.uims-sidebar').length, navbar: document.querySelectorAll('.uims-navbar').length, footer: document.querySelectorAll('.uims-footer').length, shells: document.querySelectorAll('.uims-shell').length, sharedContent: document.querySelectorAll('.uims-main > .uims-content > .student-dashboard').length, sharedSidebar: document.querySelectorAll('.uims-shell > .uims-sidebar').length, sharedFooter: document.querySelectorAll('.uims-main > .uims-footer').length, forms: document.forms.length, legacy: document.querySelectorAll('.sd-sidebar, .sd-topbar, .sd-footer, .sd-mobile-menu').length, alert: document.querySelector('.student-dashboard [role=alert]')?.textContent || '', demo: document.querySelectorAll('.sd-mode-note').length, dataPanels: document.querySelectorAll('.sd-campus, .sd-profile-banner').length, saveButtons: document.querySelectorAll('.sd-save-button').length, pendingHidden: document.getElementById('student-request-status').hidden, overflow: [...document.querySelectorAll('.student-dashboard *')].filter(e => e.getBoundingClientRect().right > innerWidth + 1).map(e => e.className).slice(0, 8) })`,
                    returnByValue: true
                });
                const report = JSON.parse(result.result.value);
                console.log(page, width, JSON.stringify(report));
                const shot = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true });
                fs.writeFileSync(path.resolve(__dirname, '../../obj/student-' + page.toLowerCase() + '-' + width + '.png'), Buffer.from(shot.data, 'base64'));
                if (report.content > report.viewport || !report.images) throw new Error(page + ' has horizontal overflow or an unloaded image at ' + width);
                if (report.sidebar !== 1 || report.navbar !== 0 || report.footer !== 1 || report.legacy !== 0 || report.shells !== 1 || report.sharedContent !== 1 || report.sharedSidebar !== 1 || report.sharedFooter !== 1 || report.forms !== 1) throw new Error('Shared shell is missing or duplicated');
                if (!report.pendingHidden || report.demo !== 0) throw new Error('Unexpected loading or demo state');
                if (expectBlocked && !offlineLayout && (!/Student sign-in integration is not configured|Sign in using the local Student Profile form/.test(report.alert) || report.dataPanels !== 0 || report.saveButtons !== 0)) throw new Error('Unauthenticated page did not fail closed');
                if (!expectBlocked && (report.alert || report.dataPanels !== 1)) throw new Error('Authenticated student data did not load');
                if (offlineLayout && (report.alert || report.dataPanels !== 1 || report.saveButtons !== (offlineEditing && page === 'Profile' ? 1 : 0))) throw new Error('Offline layout fixture controls did not match permissions');
                if (offlineLayout) {
                    const fixture = await send('Runtime.evaluate', { expression: `JSON.stringify({ label: document.querySelector('.sd-demo').textContent, totals: [...document.querySelectorAll('.sd-number')].map(x => x.textContent.trim()), taskSections: document.querySelectorAll('#tasks').length, evaluations: document.querySelectorAll('#evaluations').length, editable: [...document.querySelectorAll('.student-dashboard input:not([type=hidden]):not([type=submit]), .student-dashboard textarea')].filter(x => !x.readOnly).length })`, returnByValue: true });
                    const data = JSON.parse(fixture.result.value);
                    if (!data.label.includes('OFFLINE UI TEST') || data.editable !== (offlineEditing && page === 'Profile' ? 4 : 0)) throw new Error('Fixture label or approved editable fields are incorrect');
                    if (page === 'Dashboard' && (data.totals.some(x => x !== '—') || data.taskSections !== 1 || data.evaluations !== 1)) throw new Error('Missing activity must not show invented totals');
                }
                if (width < 992) {
                    const menu = await send('Runtime.evaluate', { expression: `(() => { document.querySelector('.uims-menu-btn').click(); const opened = document.body.classList.contains('uims-side-open') && getComputedStyle(document.querySelector('.uims-overlay')).display === 'block'; document.querySelector('.uims-overlay').click(); return opened && !document.body.classList.contains('uims-side-open'); })()`, returnByValue: true });
                    if (!menu.result.value) throw new Error('Shared mobile menu failed');
                }
            }
        }
        if (scriptErrors !== 0 || firebaseRequests !== 0) throw new Error('Unexpected browser exception or direct browser Firebase request');
        console.log('PASS: both Student pages at 390, 768, and 1440 pixels; shared mobile menu; no overflow or script errors. Mode: ' + (offlineLayout ? 'explicit offline UI fixture; NOT a Firebase read' : expectBlocked ? 'unauthenticated, blocked without demo data' : 'authenticated render only; no write test performed'));
    } finally {
        // Close only this verification target; do not affect other browser tabs or terminals.
        await fetch((process.env.STUDENT_DEBUG_URL || 'http://127.0.0.1:9231') + '/json/close/' + target.id);
        socket.close();
    }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
