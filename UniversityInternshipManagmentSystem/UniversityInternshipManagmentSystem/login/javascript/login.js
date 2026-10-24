(function() {
  const bgCanvas = document.getElementById('bgCanvas');
  const ctx = bgCanvas ? bgCanvas.getContext('2d') : null;
  const loginCard = document.getElementById('loginCard');

  const grandUjLogoSvg = document.getElementById('grandUjLogoSvg');
  const shieldProgressRing = document.getElementById('shieldProgressRing');
  const torchFlameGroup = document.getElementById('torchFlameGroup');
  const leftStatusDot = document.getElementById('leftStatusDot') || { style: {} };

  const emailInput = document.getElementById('txtEmail') || document.getElementById('emailInput');
  const passwordInput = document.getElementById('txtPassword') || document.getElementById('passwordInput');
  const emailGroup = document.getElementById('emailGroup');
  const passwordGroup = document.getElementById('passwordGroup');
  const togglePasswordBtn = document.getElementById('togglePasswordBtn');
  const eyeIconOpen = document.getElementById('eyeIconOpen');
  const eyeIconClosed = document.getElementById('eyeIconClosed');
  const uimsLoginForm = document.getElementById('form1') || document.getElementById('uimsLoginForm');
  const signInBtn = document.getElementById('btnLogin') || document.getElementById('signInBtn');
  const signInBtnText = document.getElementById('signInBtnText');
  const officialAlertBox = document.getElementById('officialAlertBox');
  const officialAlertText = document.getElementById('officialAlertText');

  const infoModal = document.getElementById('infoModal');
  const modalTitle = document.getElementById('modalTitle');
  const modalBody = document.getElementById('modalBody');

  let activeField = 'none';
  let isPasswordVisible = false;
  let pointer = { x: 0, y: 0, targetX: 0, targetY: 0 };
  let particles = [];
  let ripples = [];
  const flameGlow = document.getElementById('flameGlowCircle');
  const reduceQuery = window.matchMedia ? window.matchMedia('(prefers-reduced-motion: reduce)') : { matches: false, addEventListener: function() {} };
  const fineQuery = window.matchMedia ? window.matchMedia('(hover: hover) and (pointer: fine)') : { matches: true };
  let reduceMotion = reduceQuery.matches;
  let W = window.innerWidth, H = window.innerHeight, rafId = 0, flameTimer = 0, resizeTimer = 0;

  // 1. Background Canvas & Ripples
  function resizeCanvas() {
    if (!bgCanvas || !ctx) return;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    W = window.innerWidth; H = window.innerHeight;
    bgCanvas.width = Math.round(W * dpr);
    bgCanvas.height = Math.round(H * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    if (reduceMotion) drawFrame();
  }
  window.addEventListener('resize', function() {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(resizeCanvas, 120);
  });
  resizeCanvas();

  function initParticles() {
    particles = [];
  }
  initParticles();
  const bgLayers = document.querySelectorAll('[data-bg-lines]');

  function emitShieldRipple(color) {
    if (reduceMotion || !grandUjLogoSvg || !ctx) return;
    const rect = grandUjLogoSvg.getBoundingClientRect();
    const cx = rect.left + rect.width * 0.5;
    const cy = rect.top + rect.height * 0.48;
    ripples.push({
      x: cx,
      y: cy,
      r: 25,
      maxR: Math.max(W, H) * 0.55,
      alpha: 0.42,
      color: color || '#10b981'
    });
  }
  window.emitShieldRipple = emitShieldRipple;

  function triggerErrorState() {
    if (!loginCard) return;
    loginCard.classList.remove('state-email', 'state-password');
    loginCard.classList.remove('state-error');
    void loginCard.offsetWidth;
    loginCard.classList.add('state-error');
    emitShieldRipple('#e60000');
  }
  window.triggerErrorState = triggerErrorState;

  function drawFrame() {
    if (!ctx) return;
    const animate = !reduceMotion;
    ctx.clearRect(0, 0, W, H);

    const tilt = animate && (fineQuery.matches || !window.matchMedia);
    pointer.x += (pointer.targetX - pointer.x) * 0.07;
    pointer.y += (pointer.targetY - pointer.y) * 0.07;
    if (tilt) bgLayers.forEach(function(el) { el.style.setProperty('--mx', pointer.x.toFixed(3)); el.style.setProperty('--my', pointer.y.toFixed(3)); });

    const tiltX = pointer.y * -7;
    const tiltY = pointer.x * 9;
    if (tilt && grandUjLogoSvg) grandUjLogoSvg.style.transform = "rotateX(" + tiltX.toFixed(2) + "deg) rotateY(" + tiltY.toFixed(2) + "deg) translate3d(" + (pointer.x * 6).toFixed(1) + "px, " + (pointer.y * 5).toFixed(1) + "px, 0)";

    for (let i = ripples.length - 1; i >= 0; i--) {
      const rp = ripples[i];
      rp.r += 5.2;
      rp.alpha *= 0.962;
      ctx.beginPath();
      ctx.arc(rp.x, rp.y, rp.r, 0, Math.PI * 2);
      ctx.strokeStyle = rp.color;
      ctx.globalAlpha = rp.alpha;
      ctx.lineWidth = 2;
      ctx.stroke();
      ctx.globalAlpha = 1;
      if (rp.alpha < 0.015 || rp.r > rp.maxR) {
        ripples.splice(i, 1);
      }
    }

    ctx.globalAlpha = 1;
  }
  function renderLoop() {
    drawFrame();
    rafId = (!reduceMotion && !document.hidden) ? requestAnimationFrame(renderLoop) : 0;
  }
  function startLoop() { if (!rafId) rafId = requestAnimationFrame(renderLoop); }
  document.addEventListener('visibilitychange', function() { if (!document.hidden) startLoop(); });
  if (reduceQuery && reduceQuery.addEventListener) {
    reduceQuery.addEventListener('change', function(e) {
      reduceMotion = e.matches;
      if (reduceMotion) { ripples.length = 0; if (grandUjLogoSvg) grandUjLogoSvg.style.transform = ''; drawFrame(); } else { startLoop(); }
    });
  }
  renderLoop();

  window.addEventListener('pointermove', function(e) {
    if (e.pointerType && e.pointerType !== 'mouse') return;
    pointer.targetX = (e.clientX / window.innerWidth - 0.5) * 2;
    pointer.targetY = (e.clientY / window.innerHeight - 0.5) * 2;
  }, { passive: true });

  // 2. Shield Reactions
  function pulseTorchFlame() {
    if (reduceMotion || !flameGlow) return;
    flameGlow.classList.add('pulse');
    clearTimeout(flameTimer);
    flameTimer = setTimeout(function() { flameGlow.classList.remove('pulse'); }, 180);
  }

  function updateEmailReaction() {
    if (!emailInput || !shieldProgressRing) return;
    const val = (emailInput.value || '').trim();
    const isValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val);
    const progress = Math.min(1, val.length / 20);

    shieldProgressRing.style.strokeDashoffset = (1131 * (1 - progress)).toFixed(0);

    if (isValid) {
      shieldProgressRing.setAttribute('stroke', '#34d399');
      if (leftStatusDot && leftStatusDot.style) leftStatusDot.style.backgroundColor = '#34d399';
    } else {
      shieldProgressRing.setAttribute('stroke', '#fbbf24');
      if (leftStatusDot && leftStatusDot.style) leftStatusDot.style.backgroundColor = '#fbbf24';
    }
  }

  if (emailInput) {
    emailInput.addEventListener('focus', function() {
      activeField = 'email';
      if (loginCard && !loginCard.classList.contains('state-error')) {
        loginCard.classList.remove('state-password');
        loginCard.classList.add('state-email');
      }
      if (emailGroup) emailGroup.classList.remove('input-invalid');
      emailInput.removeAttribute('aria-invalid');
      updateEmailReaction();
    });

    emailInput.addEventListener('input', function() {
      activeField = 'email';
      pulseTorchFlame();
      emitShieldRipple('#10b981');
      updateEmailReaction();
    });

    emailInput.addEventListener('blur', function() {
      activeField = 'none';
      if (loginCard && !loginCard.classList.contains('state-error')) {
        loginCard.classList.remove('state-email');
      }
    });
  }

  if (passwordInput) {
    passwordInput.addEventListener('focus', function() {
      activeField = 'password';
      if (loginCard && !loginCard.classList.contains('state-error')) {
        loginCard.classList.remove('state-email');
        loginCard.classList.add('state-password');
      }
      if (passwordGroup) passwordGroup.classList.remove('input-invalid');
      passwordInput.removeAttribute('aria-invalid');
      if (shieldProgressRing) shieldProgressRing.setAttribute('stroke', '#fbbf24');
      if (leftStatusDot && leftStatusDot.style) leftStatusDot.style.backgroundColor = '#fbbf24';
      emitShieldRipple('#d4af37');
    });

    passwordInput.addEventListener('input', function() {
      activeField = 'password';
      const len = (passwordInput.value || '').length;
      const progress = Math.min(1, len / 12);
      if (shieldProgressRing) shieldProgressRing.style.strokeDashoffset = (1131 * (1 - progress)).toFixed(0);
      pulseTorchFlame();
      emitShieldRipple('#d4af37');
    });

    passwordInput.addEventListener('blur', function() {
      activeField = 'none';
      if (loginCard && !loginCard.classList.contains('state-error')) {
        loginCard.classList.remove('state-password');
      }
    });
  }

  if (togglePasswordBtn && passwordInput) {
    togglePasswordBtn.addEventListener('click', function(e) {
      e.preventDefault();
      isPasswordVisible = !isPasswordVisible;
      passwordInput.type = isPasswordVisible ? 'text' : 'password';
      togglePasswordBtn.setAttribute('aria-pressed', String(isPasswordVisible));
      togglePasswordBtn.setAttribute('aria-label', isPasswordVisible ? 'Hide password' : 'Show password');
      if (eyeIconOpen) eyeIconOpen.style.display = isPasswordVisible ? 'block' : 'none';
      if (eyeIconClosed) eyeIconClosed.style.display = isPasswordVisible ? 'none' : 'block';
      pulseTorchFlame();
      emitShieldRipple(isPasswordVisible ? '#e60000' : '#d4af37');
    });
  }

  // 3. Form Validation (runs before ASP.NET postback)
  function validateLoginForm(e) {
    const emailVal = emailInput ? (emailInput.value || '').trim() : '';
    const passVal = passwordInput ? (passwordInput.value || '').trim() : '';
    const isValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailVal);

    if (!emailVal || !isValid) {
      if (e) e.preventDefault();
      if (emailGroup) emailGroup.classList.add('input-invalid');
      if (officialAlertBox) {
        officialAlertBox.className = 'official-alert alert-error';
        officialAlertBox.style.display = 'flex';
      }
      if (officialAlertText) officialAlertText.textContent = 'Please enter a valid email address.';
      if (emailInput) {
        emailInput.setAttribute('aria-invalid', 'true');
        emailInput.focus();
      }
      triggerErrorState();
      return false;
    }

    if (!passVal || passVal.length < 4) {
      if (e) e.preventDefault();
      if (passwordGroup) passwordGroup.classList.add('input-invalid');
      if (officialAlertBox) {
        officialAlertBox.className = 'official-alert alert-error';
        officialAlertBox.style.display = 'flex';
      }
      if (officialAlertText) officialAlertText.textContent = 'Please enter your password.';
      if (passwordInput) {
        passwordInput.setAttribute('aria-invalid', 'true');
        passwordInput.focus();
      }
      triggerErrorState();
      return false;
    }

    if (loginCard) loginCard.classList.remove('state-error');
    if (officialAlertBox) officialAlertBox.style.display = 'none';
    if (signInBtn) {
      if (signInBtn.tagName === 'INPUT') {
        signInBtn.value = 'Authenticating...';
      } else if (signInBtnText) {
        signInBtnText.textContent = 'Authenticating...';
      }
    }
    emitShieldRipple('#10b981');
    return true;
  }

  if (signInBtn) {
    signInBtn.addEventListener('click', function(e) {
      if (!validateLoginForm(e)) {
        return false;
      }
    });
  }

  [emailInput, passwordInput].forEach(function(el) {
    if (el) {
      el.addEventListener('input', function() {
        if (loginCard) loginCard.classList.remove('state-error');
        if (officialAlertBox) officialAlertBox.style.display = 'none';
      });
    }
  });

  // 4. Header / Footer Navigation Modals
  let lastFocus = null;
  function showModal(title, bodyHtml) {
    if (!infoModal) return;
    lastFocus = document.activeElement;
    if (modalTitle) modalTitle.textContent = title;
    if (modalBody) modalBody.innerHTML = bodyHtml;
    infoModal.classList.add('show');
    const footBtn = document.getElementById('closeModalFootBtn');
    if (footBtn) footBtn.focus();
  }

  function closeModal() {
    if (infoModal) infoModal.classList.remove('show');
    if (lastFocus && lastFocus.focus) lastFocus.focus();
  }

  document.addEventListener('keydown', function(e) {
    if (!infoModal || !infoModal.classList.contains('show')) return;
    if (e.key === 'Escape') { closeModal(); return; }
    if (e.key === 'Tab') {
      const items = [document.getElementById('closeModalBtn'), document.getElementById('closeModalFootBtn')].filter(Boolean);
      if (items.length === 0) return;
      const i = items.indexOf(document.activeElement);
      e.preventDefault();
      items[(i + (e.shiftKey ? items.length - 1 : 1)) % items.length].focus();
    }
  });

  const closeMBtn = document.getElementById('closeModalBtn');
  if (closeMBtn) closeMBtn.addEventListener('click', closeModal);
  const closeMFootBtn = document.getElementById('closeModalFootBtn');
  if (closeMFootBtn) closeMFootBtn.addEventListener('click', closeModal);
  if (infoModal) {
    infoModal.addEventListener('click', function(e) {
      if (e.target === infoModal) closeModal();
    });
  }

  const navAbout = document.getElementById('navAboutBtn');
  if (navAbout) {
    navAbout.addEventListener('click', function() {
      showModal(
        'Ø¹Ù† Ù†Ø¸Ø§Ù… Ø§Ù„ØªØ¯Ø±ÙŠØ¨ Ø§Ù„Ù…ÙŠØ¯Ø§Ù†ÙŠ (UIMS)',
        '<p>Ù…Ù†ØµØ© Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠØ© Ø±Ø³Ù…ÙŠØ© ØªØ§Ø¨Ø¹Ø© Ù„ÙƒÙ„ÙŠØ© Ø§Ù„Ù…Ù„Ùƒ Ø¹Ø¨Ø¯Ø§Ù„Ù„Ù‡ Ø§Ù„Ø«Ø§Ù†ÙŠ Ù„ØªÙƒÙ†ÙˆÙ„ÙˆØ¬ÙŠØ§ Ø§Ù„Ù…Ø¹Ù„ÙˆÙ…Ø§Øª (KASIT) ÙÙŠ Ø§Ù„Ø¬Ø§Ù…Ø¹Ø© Ø§Ù„Ø£Ø±Ø¯Ù†ÙŠØ© Ù„Ø¥Ø¯Ø§Ø±Ø© ÙˆÙ…ØªØ§Ø¨Ø¹Ø© Ø§Ù„ØªØ¯Ø±ÙŠØ¨ Ø§Ù„Ù…ÙŠØ¯Ø§Ù†ÙŠ Ù„Ù„Ø·Ù„Ø¨Ø©.</p>'
      );
    });
  }

  const navContact = document.getElementById('navContactBtn');
  if (navContact) {
    navContact.addEventListener('click', function() {
      showModal(
        'ØªÙˆØ§ØµÙ„ Ù…Ø¹Ù†Ø§ - ÙƒÙ„ÙŠØ© KASIT',
        '<p><strong>Ø§Ù„Ø¬Ø§Ù…Ø¹Ø© Ø§Ù„Ø£Ø±Ø¯Ù†ÙŠØ© - Ø¹Ù…Ù‘Ø§Ù†ØŒ Ø§Ù„Ø£Ø±Ø¯Ù†</strong><br>Ù‡Ø§ØªÙ: <span dir="ltr">+962 6 5355000</span></p>'
      );
    });
  }

  const navHome = document.getElementById('navHomeBtn');
  if (navHome) {
    navHome.addEventListener('click', function() {
      if (officialAlertBox) officialAlertBox.style.display = 'none';
      if (emailInput) emailInput.value = '';
      if (passwordInput) passwordInput.value = '';
      updateEmailReaction();
    });
  }

  // 5. Password Reset / Recovery Modal
  function openForgotModal() {
    const modal = document.getElementById('forgotModal');
    const emailIn = document.getElementById('txtEmail');
    const recIn = document.getElementById('txtRecoveryEmail');
    if (emailIn && recIn && emailIn.value) {
      recIn.value = emailIn.value.trim();
    }
    if (modal) modal.classList.add('show');
  }
  window.openForgotModal = openForgotModal;

  const forgotBtn = document.getElementById('forgotPasswordBtn');
  if (forgotBtn) {
    forgotBtn.addEventListener('click', function(e) {
      e.preventDefault();
      openForgotModal();
    });
  }

  const closeForgot = document.getElementById('closeForgotModalBtn');
  if (closeForgot) {
    closeForgot.addEventListener('click', function() {
      const m = document.getElementById('forgotModal');
      if (m) m.classList.remove('show');
    });
  }

  const cancelForgot = document.getElementById('cancelForgotBtn');
  if (cancelForgot) {
    cancelForgot.addEventListener('click', function() {
      const m = document.getElementById('forgotModal');
      if (m) m.classList.remove('show');
    });
  }

  // Check if server rendered an error on postback (e.g. wrong password/email from Firebase)
  const serverErr = document.getElementById('pnlError');
  if (serverErr && serverErr.style.display !== 'none' && loginCard) {
    triggerErrorState();
  }

  // Initialize progress ring state
  updateEmailReaction();
})();