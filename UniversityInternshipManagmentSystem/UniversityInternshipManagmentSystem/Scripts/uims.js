(()=>{'use strict';
const one=s=>document.querySelector(s),all=s=>[...document.querySelectorAll(s)];
const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

// 1. Mobile Navigation Menu Toggle
const toggle=one('#uimsNavToggle'),menu=one('#uimsNavMenu'),navbar=one('#uimsNavbar');
const closeMenu=()=>{
    menu?.classList.remove('open');
    toggle?.setAttribute('aria-expanded','false');
};
toggle?.addEventListener('click',()=>{
    const open=menu.classList.toggle('open');
    toggle.setAttribute('aria-expanded',String(open));
});

// Close mobile menu on link click
all('.uims-nav-link').forEach(link=>link.addEventListener('click',()=>{
    closeMenu();
}));
document.addEventListener('keydown',event=>{
    if(event.key==='Escape' && menu?.classList.contains('open')){
        closeMenu();
        toggle?.focus();
    }
});
document.addEventListener('click',event=>{
    if(menu?.classList.contains('open') && !navbar?.contains(event.target)) closeMenu();
});
window.matchMedia('(min-width: 1101px)').addEventListener('change',event=>{
    if(event.matches) closeMenu();
});

// 2. Smooth Scrolling for In-Page Anchor Links (with Sticky Navbar Offset)
all('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', e => {
        const href = anchor.getAttribute('href');
        if (!href || href === '#' || href === '#!') return;
        const target = one(href);
        if (target) {
            e.preventDefault();
            const navOffset = navbar ? navbar.offsetHeight : 70;
            const topPos = target.getBoundingClientRect().top + window.pageYOffset - navOffset;
            window.scrollTo({
                top: Math.max(0, topPos),
                behavior: reducedMotion ? 'auto' : 'smooth'
            });
            if (history.pushState) {
                history.pushState(null, '', href);
            }
        }
    });
});

// 3. Staggered Reveal-on-Scroll
const revealElements = all('.reveal, .reveal-up, .reveal-left, .reveal-right');
if (reducedMotion || !('IntersectionObserver' in window)) {
    revealElements.forEach(el => el.classList.add('is-revealed'));
} else {
    const revealObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const el = entry.target;
                const delay = el.dataset.delay;
                if (delay) {
                    el.style.transitionDelay = `${delay}ms`;
                }
                el.classList.add('is-revealed');
                observer.unobserve(el);
            }
        });
    }, {
        threshold: 0.1,
        rootMargin: '0px 0px -30px 0px'
    });
    revealElements.forEach(el => revealObserver.observe(el));
}

// 4. Scrollspy (Highlight active navbar link based on current section in view)
const navLinks = all('.uims-nav-link');
const trackedSections = all('section[id], footer[id]');
if ('IntersectionObserver' in window && trackedSections.length && navLinks.length) {
    const scrollspyObserver = new IntersectionObserver(entries => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const id = entry.target.id;
                navLinks.forEach(link => {
                    const href = link.getAttribute('href');
                    link.classList.toggle('active', href === `#${id}`);
                });
            }
        });
    }, {
        threshold: 0.2,
        rootMargin: '-20% 0px -40% 0px'
    });
    trackedSections.forEach(sec => scrollspyObserver.observe(sec));
}

// 5. Animated Stats Counter (count-up from 0 to data-target, runs once)
const statNumbers = all('.uims-stat-number');
function renderFinalStat(el) {
    const val = Number(el.dataset.target) || 0;
    el.textContent = val.toLocaleString('en-US') + (el.dataset.suffix || '');
}
function animateCounter(el) {
    if (el._hasAnimated) return;
    el._hasAnimated = true;
    const target = Number(el.dataset.target) || 0;
    const suffix = el.dataset.suffix || '';
    if (reducedMotion) {
        renderFinalStat(el);
        return;
    }
    const duration = 1400;
    const start = performance.now();
    function tick(now) {
        const elapsed = now - start;
        const progress = Math.min(elapsed / duration, 1);
        const ease = progress === 1 ? 1 : 1 - Math.pow(2, -10 * progress);
        const current = Math.floor(ease * target);
        el.textContent = current.toLocaleString('en-US') + suffix;
        if (progress < 1) {
            requestAnimationFrame(tick);
        } else {
            el.textContent = target.toLocaleString('en-US') + suffix;
        }
    }
    requestAnimationFrame(tick);
}

if (reducedMotion || !('IntersectionObserver' in window)) {
    statNumbers.forEach(renderFinalStat);
} else {
    statNumbers.forEach(el => {
        el.textContent = '0' + (el.dataset.suffix || '');
    });
    const statsObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                animateCounter(entry.target);
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.2 });
    statNumbers.forEach(el => statsObserver.observe(el));
}

// 6. Throttled requestAnimationFrame Scroll Interactions:
//    - Top scroll-progress bar in #178568
//    - Sticky navbar background & height transition
//    - Floating Back to top button (after 400px)
//    - Hero Parallax effect
//    - Identity band campus image parallax
//    - Timeline progress line filling & step activation
const topBtn = one('#backToTop');
const progressEl = one('#scrollProgress');
const heroBg = one('.uims-hero-bg');
const identitySection = one('#identity');
const identityImg = one('.uims-identity-visual img');
const guideContainer = one('.uims-guide-steps');
const guideSteps = all('.uims-guide-step');

let isTicking = false;
function updateScrollEffects() {
    const scrollY = window.pageYOffset || document.documentElement.scrollTop;
    const docHeight = document.documentElement.scrollHeight - window.innerHeight;

    // Top scroll progress bar
    if (progressEl) {
        progressEl.style.width = (docHeight > 0 ? (scrollY / docHeight) * 100 : 0) + '%';
    }

    // Navbar state change (transparent/subtle over hero -> solid #07523E with shadow)
    if (navbar) {
        navbar.classList.toggle('navbar-scrolled', scrollY > 50);
    }

    // Back to top visibility
    if (topBtn) {
        topBtn.classList.toggle('visible', scrollY > 400);
    }

    // Parallax & Timeline animations (disabled if prefers-reduced-motion)
    if (!reducedMotion) {
        // Hero background image subtle parallax
        if (heroBg && scrollY < window.innerHeight) {
            heroBg.style.transform = `translate3d(0, ${Math.round(scrollY * 0.18)}px, 0)`;
        }

        // Identity band campus image parallax
        if (identityImg && identitySection) {
            const rect = identitySection.getBoundingClientRect();
            if (rect.top < window.innerHeight && rect.bottom > 0) {
                const factor = (window.innerHeight - rect.top) / (window.innerHeight + rect.height);
                const offset = (factor - 0.5) * 32;
                identityImg.style.transform = `translate3d(0, ${offset.toFixed(1)}px, 0) scale(1.06)`;
            }
        }

        // How It Works timeline progress line filling & step activation
        if (guideContainer && guideSteps.length) {
            const rect = guideContainer.getBoundingClientRect();
            if (rect.top < window.innerHeight && rect.bottom > 0) {
                const progress = Math.min(Math.max((window.innerHeight * 0.65 - rect.top) / rect.height, 0), 1);
                guideContainer.style.setProperty('--guide-progress', (progress * 100) + '%');
                guideSteps.forEach((step, idx) => {
                    const threshold = (idx + 0.35) / guideSteps.length;
                    step.classList.toggle('is-active', progress >= threshold);
                });
            }
        }
    } else {
        guideSteps.forEach(step => step.classList.add('is-active'));
    }
}

function onScroll() {
    if (!isTicking) {
        requestAnimationFrame(() => {
            updateScrollEffects();
            isTicking = false;
        });
        isTicking = true;
    }
}
window.addEventListener('scroll', onScroll, { passive: true });
updateScrollEffects();

// Back to Top click
topBtn?.addEventListener('click', () => {
    window.scrollTo({ top: 0, behavior: reducedMotion ? 'auto' : 'smooth' });
});

// 7. Accessible FAQ Accordion (Smooth CSS Grid Height Animation)
all('.uims-accordion-btn').forEach((btn, i) => {
    const panel = btn.closest('.uims-accordion-item')?.querySelector('.uims-accordion-collapse');
    if (!panel) return;
    panel.id = 'faq-answer-' + i;
    btn.setAttribute('aria-controls', panel.id);
    btn.addEventListener('click', () => {
        const item = btn.closest('.uims-accordion-item');
        const isOpen = btn.getAttribute('aria-expanded') === 'true';
        btn.setAttribute('aria-expanded', String(!isOpen));
        item?.classList.toggle('open', !isOpen);
    });
});

// 8. Live Amman Clock
function clock(){
    const parts = Object.fromEntries(new Intl.DateTimeFormat('en-GB', {
        timeZone: 'Asia/Amman',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hourCycle: 'h23'
    }).formatToParts(new Date()).filter(p => p.type !== 'literal').map(p => [p.type, +p.value]));
    const h = parts.hour, m = parts.minute, s = parts.second;
    const timeDisplay = one('#ammanTimeDisplay');
    if (timeDisplay) {
        timeDisplay.textContent = [h, m, s].map(n => String(n).padStart(2, '0')).join(':');
    }
    [['hour', (h % 12) * 30 + m / 2], ['minute', m * 6 + s / 10], ['second', s * 6]].forEach(([id, deg]) => {
        one('#hand-' + id)?.setAttribute('transform', `rotate(${deg} 200 135)`);
    });
}
clock();
setInterval(clock, 1000);

// Demonstrative statistics note
const note = document.createElement('p');
note.textContent = 'Preview statistics · illustrative figures, not live system totals';
note.style.cssText = 'text-align:center;font-size:10px;color:#6b7e77;margin:12px 0';
one('.uims-stats-strip .uims-container')?.append(note);

// 9. Curated Opportunities Carousel and Live Filter
let data = { opportunities: [], message: 'Internship listings are currently unavailable.' };
try { data = JSON.parse(one('#home-data')?.textContent || '{}'); } catch {}
let page = 0;
const size = 3;
const grid = one('#jobGrid');
const search = one('#searchInput');
const prev = one('#previousJobs');
const next = one('#nextJobs');

function element(tag, text, cls) {
    const el = document.createElement(tag);
    el.textContent = text;
    if (cls) el.className = cls;
    return el;
}

function render() {
    if (!grid) return;
    const query = (search?.value || '').trim().toLowerCase();
    const list = (data.opportunities || []).filter(o => [o.title, o.companyName, o.location, o.major].join(' ').toLowerCase().includes(query));
    const pages = Math.max(1, Math.ceil(list.length / size));
    page = Math.min(page, pages - 1);
    grid.replaceChildren();
    list.slice(page * size, (page + 1) * size).forEach(o => {
        const card = element('article', '', 'uims-job-card');
        card.append(
            element('small', o.companyName),
            element('h3', o.title),
            element('p', o.location + ' · ' + o.major),
            element('p', o.seatsLeft + ' seats available · Deadline: ' + o.deadline)
        );
        const link = element('a', data.canApply ? 'View application' : 'Sign in to apply', 'uims-btn uims-btn--outline-primary');
        link.href = data.canApply ? data.applyUrl + '?opportunityId=' + encodeURIComponent(o.id) : data.loginUrl;
        card.append(link);
        grid.append(card);
    });
    if (!list.length) {
        grid.append(element('div', query ? 'No matching internships.' : data.message, 'uims-job-empty'));
    }
    const countEl = one('#carouselCount');
    if (countEl) countEl.textContent = list.length ? `${page + 1} / ${pages} · ${list.length} opportunities` : 'No listings';
    if (prev) prev.disabled = page === 0;
    if (next) next.disabled = page >= pages - 1;
}

search?.addEventListener('input', () => { page = 0; render(); });
prev?.addEventListener('click', () => { page--; render(); });
next?.addEventListener('click', () => { page++; render(); });
render();
})();

// Amman clock tooltip interaction
(()=>{
    const clock = document.querySelector('.uims-photo-clock'), tooltip = document.querySelector('#clockTooltip');
    if (!clock || !tooltip) return;
    const update = () => tooltip.classList.toggle('is-visible', clock.matches(':hover') || document.activeElement === clock);
    ['pointerenter', 'pointerleave', 'focus', 'blur'].forEach(event => clock.addEventListener(event, update));
})();
