const homeData = JSON.parse(document.getElementById('home-data').textContent);
    const CONFIG = {
      trainingVideoUrl: '',
      partner: { name: 'Partner Organization', url: 'https://www.ju.edu.jo/', imageUrl: '' }
    };
    const grid = document.getElementById('jobGrid'), search = document.getElementById('searchInput'), statusLine = document.getElementById('loadStatus'); let jobs = [];
    const safe = (v) => String(v ?? '').replace(/[&<>"']/g, s => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[s]));
    function renderJobs() {
      const query = search.value.trim().toLowerCase();
      const visible = jobs.filter(job => [job.title, job.companyName, job.location, job.major]
        .some(value => String(value || '').toLowerCase().includes(query)));
      grid.innerHTML = visible.map(job => {
        const action = homeData.isAuthenticated
          ? (homeData.canApply ? 'Apply Now →' : 'My Dashboard →') : 'Log in to apply →';
        return `<article class="job-card"><div class="job-top"><div><h3>${safe(job.title)}</h3><div class="company-name">${safe(job.companyName)}</div></div><div class="company-icon" aria-hidden="true">⌘</div></div><div><span class="pill">${safe(job.major)}</span></div><div class="details"><span>⌖ ${safe(job.location)}</span><span>◷ Apply by: ${safe(job.deadline)}</span><span>${safe(job.seatsLeft)} seats available</span></div><div class="job-actions"><button class="apply" data-apply="${safe(job.id)}" type="button">${action}</button><span class="tiny">${homeData.isAuthenticated ? 'Signed in' : 'Login required'}</span></div></article>`;
      }).join('') || '<div class="empty">' + (jobs.length ? 'No internship opportunities match your search.' : 'No opportunities to display right now.') + '</div>';
    }
    function toast(message) { const el = document.getElementById('toast'); el.textContent = message; el.classList.add('show'); clearTimeout(toast.timer); toast.timer = setTimeout(() => el.classList.remove('show'), 4000) }

    search.addEventListener('input', renderJobs);
    grid.addEventListener('click', event => {
      const button = event.target.closest('[data-apply]');
      if (!button) return;
      const id = button.getAttribute('data-apply');
      if (!jobs.some(job => job.id === id)) return;
      const applicationUrl = homeData.applyUrl + '?opportunityId=' + encodeURIComponent(id);
      if (homeData.isAuthenticated) {
        location.href = homeData.canApply ? applicationUrl : homeData.dashboardUrl;
      } else {
        location.href = homeData.loginUrl + '?ReturnUrl=' + encodeURIComponent(applicationUrl);
      }
    });
    document.querySelectorAll('.faq-item button').forEach(btn => btn.addEventListener('click', () => { const item = btn.parentElement, open = item.classList.contains('open'); document.querySelectorAll('.faq-item').forEach(el => { el.classList.remove('open'); el.querySelector('button').setAttribute('aria-expanded', 'false') }); if (!open) { item.classList.add('open'); btn.setAttribute('aria-expanded', 'true') } }));
    const menu = document.getElementById('menuToggle'), links = document.getElementById('navlinks'); menu.addEventListener('click', () => { const open = links.classList.toggle('open'); menu.setAttribute('aria-expanded', String(open)); menu.textContent = open ? '✕' : '☰' }); links.querySelectorAll('a').forEach(a => a.addEventListener('click', () => { links.classList.remove('open'); menu.setAttribute('aria-expanded', 'false'); menu.textContent = '☰' }));
    document.getElementById('year').textContent = new Date().getFullYear(); document.getElementById('partnerName').textContent = CONFIG.partner.name; document.getElementById('partnerLink').href = CONFIG.partner.url; const partnerImg = document.getElementById('partnerImage'); if (CONFIG.partner.imageUrl) partnerImg.src = CONFIG.partner.imageUrl; else { partnerImg.style.display = 'none'; partnerImg.nextElementSibling.style.display = 'grid' }
    function loadOpportunities() {
      jobs = Array.isArray(homeData.opportunities) ? homeData.opportunities : [];
      renderJobs();
      statusLine.textContent = homeData.message || '';
    }

    /* Keep carousel controls in sync with filtering, live data, and screen size. */
    const previousJobs = document.getElementById('previousJobs'), nextJobs = document.getElementById('nextJobs'), carouselCount = document.getElementById('carouselCount');
    function updateCarousel() {
      const cards = Array.from(grid.querySelectorAll('.job-card'));
      const maxScroll = Math.max(0, grid.scrollWidth - grid.clientWidth);
      previousJobs.disabled = cards.length === 0 || grid.scrollLeft <= 2;
      nextJobs.disabled = cards.length === 0 || grid.scrollLeft >= maxScroll - 2;
      if (!cards.length) { carouselCount.textContent = 'No opportunities'; return; }
      const viewport = grid.getBoundingClientRect();
      const visible = cards.map((card, index) => ({ rect: card.getBoundingClientRect(), index })).filter(({ rect }) => rect.right > viewport.left + 2 && rect.left < viewport.right - 2);
      carouselCount.textContent = visible.length ? (visible[0].index + 1) + '–' + (visible.at(-1).index + 1) + ' of ' + cards.length + ' opportunities' : cards.length + ' opportunities';
    }
    function scrollJobs(direction) {
      const card = grid.querySelector('.job-card');
      if (!card) return;
      const step = card.getBoundingClientRect().width + parseFloat(getComputedStyle(grid).gap);
      const cardsPerPage = Math.max(1, Math.floor((grid.clientWidth + parseFloat(getComputedStyle(grid).gap) + 1) / step));
      grid.scrollBy({ left: direction * step * cardsPerPage, behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth' });
    }
    previousJobs.addEventListener('click', () => scrollJobs(-1));
    nextJobs.addEventListener('click', () => scrollJobs(1));
    grid.addEventListener('scroll', updateCarousel, { passive: true });
    grid.addEventListener('keydown', event => {
      if (event.target !== grid || !['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
      event.preventDefault();
      if (event.key === 'Home' || event.key === 'End') grid.scrollTo({ left: event.key === 'Home' ? 0 : grid.scrollWidth, behavior: 'instant' });
      else scrollJobs(event.key === 'ArrowLeft' ? -1 : 1);
    });
    new MutationObserver(() => { grid.scrollTo({ left: 0, behavior: 'instant' }); updateCarousel() }).observe(grid, { childList: true });
    new ResizeObserver(updateCarousel).observe(grid);
    if (document.fonts) document.fonts.ready.then(updateCarousel);

    /* A real source replaces the poster; an empty source keeps the written guide. */
    function setupTrainingVideo() {
      const source = CONFIG.trainingVideoUrl.trim();
      if (!source) return;
      let url; try { url = new URL(source, location.href) } catch { return; }
      if (!['http:', 'https:', 'file:'].includes(url.protocol)) return;
      const host = url.hostname.toLowerCase().replace(/^www\./, '');
      const youtubeHosts = ['youtube.com', 'm.youtube.com', 'youtube-nocookie.com', 'youtu.be'];
      const media = document.getElementById('trainingMedia');
      if (youtubeHosts.includes(host)) {
        const id = host === 'youtu.be' ? url.pathname.split('/')[1] : url.searchParams.get('v') || url.pathname.match(/^\/(?:embed|shorts)\/([^/]+)/)?.[1];
        if (!/^[\w-]{11}$/.test(id || '')) return;
        const frame = document.createElement('iframe');
        frame.src = 'https://www.youtube-nocookie.com/embed/' + id;
        frame.title = 'How the internship training process works';
        frame.loading = 'lazy'; frame.allow = 'encrypted-media; picture-in-picture; fullscreen'; frame.allowFullscreen = true;
        frame.referrerPolicy = 'strict-origin-when-cross-origin';
        media.replaceChildren(frame);
      } else {
        const poster = media.firstElementChild;
        const video = document.createElement('video'); video.controls = true; video.playsInline = true; video.preload = 'metadata';
        video.poster = 'Assets/PublicHome/university-hero.jpg'; video.setAttribute('aria-label', 'Internship training walkthrough');
        const videoSource = document.createElement('source'); videoSource.src = url.href;
        videoSource.addEventListener('error', () => { media.replaceChildren(poster); document.getElementById('trainingVideoStatus').textContent = 'The video is currently unavailable. Follow the steps alongside to get started.' });
        video.append(videoSource); media.replaceChildren(video);
      }
    }
    setupTrainingVideo();
    loadOpportunities();

    document.addEventListener('keydown', event => {
      if (event.key === 'Enter' && event.target.tagName === 'INPUT') event.preventDefault();
    });
