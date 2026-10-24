<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="UniversityInternshipManagmentSystem.login.Login" Async="true" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Field Training System (UIMS) - Unified Login Portal | The University of Jordan</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;700;800&family=Inter:wght@400;500;600;700;800&family=Cairo:wght@600;700;800;900&display=swap" rel="stylesheet">
  <style>
:root {
      --uj-green-deep: #032211;
      --uj-green-dark: #064e27;
      --uj-green: #0b5c2c;
      --uj-shield-green: #009639;
      --uj-emerald: #10b981;
      --uj-gold: #d4af37;
      --uj-red: #e60000;
      --slate-900: #0f172a;
      --slate-800: #1e293b;
      --slate-700: #334155;
      --slate-600: #475569;
      --slate-500: #64748b;
      --slate-200: #e2e8f0;
      --slate-100: #f1f5f9;
      --slate-50: #f8fafc;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    html, body {
      height: 100vh;
      width: 100%;
      margin: 0;
      padding: 0;
      overflow: hidden;
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background-color: #0a4a3a;
      background-image:
        radial-gradient(900px 700px at 8% 12%, #1d6a56 0, transparent 65%),
        radial-gradient(800px 650px at 100% 100%, #44803f 0, transparent 65%),
        radial-gradient(600px 500px at 100% 0%, #3c6a45 0, transparent 60%),
        radial-gradient(1000px 600px at 45% 108%, #032f23 0, transparent 70%),
        linear-gradient(135deg, #14594a 0%, #0a4a3a 50%, #0d5a42 100%);
      background-attachment: fixed;
      color: var(--slate-800);
      display: flex;
      flex-direction: column;
    }

    .font-arabic {
      font-family: 'Cairo', Tahoma, sans-serif;
    }

    .skip-link {
      position: absolute;
      top: -100px;
      left: 16px;
      background: #064e27;
      color: #fff;
      padding: 8px 14px;
      border-radius: 6px;
      z-index: 999;
      font-weight: 600;
      text-decoration: none;
      transition: top 0.2s ease;
    }
    .skip-link:focus {
      top: 12px;
    }

    /* Fixed Interactive Canvas & Lines */
    #bgCanvas {
      position: fixed;
      inset: 0;
      width: 100vw;
      height: 100vh;
      z-index: 1;
      pointer-events: none;
    }

    .uims-bg {
      position: fixed;
      inset: 0;
      width: 100vw;
      height: 100vh;
      z-index: 1;
      pointer-events: none;
      overflow: hidden;
    }

    .uims-bg-dots {
      position: absolute;
      inset: 0;
      background-image: radial-gradient(rgba(255, 255, 255, 0.12) 1.2px, transparent 1.2px);
      background-size: 32px 32px;
    }

    .uims-bg-lines {
      position: absolute;
      inset: 0;
      width: 100%;
      height: 100%;
      fill: none;
      stroke: #fff;
      stroke-width: 1.5;
      stroke-opacity: .09;
      scale: 1.05;
      --depth: 1;
      translate: calc(var(--mx, 0) * -14px * var(--depth)) calc(var(--my, 0) * -10px * var(--depth));
      animation: bgDrift 24s ease-in-out infinite alternate, bgBreathe 9s ease-in-out infinite alternate;
    }

    @keyframes bgDrift {
      from { transform: translate3d(-2.2%, 1.6%, 0) rotate(-1deg); }
      to   { transform: translate3d(2.2%, -1.6%, 0) rotate(1deg); }
    }

    @keyframes bgBreathe {
      from { opacity: .5; }
      to   { opacity: .95; }
    }

    /* Form1 full height flex container */
    #form1 {
      display: flex;
      flex-direction: column;
      height: 100vh;
      width: 100%;
      flex: 1;
      min-height: 0;
      overflow: hidden;
      position: relative;
    }

    /* Main Stage */
    .main-stage {
      position: relative;
      z-index: 10;
      flex: 1;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 0;
      padding: clamp(6px, 1.5vh, 16px) 24px;
      width: 100%;
    }

    .split-login-card {
      width: 100%;
      max-width: 1020px;
      display: grid;
      grid-template-columns: 1fr 1fr;
      align-items: center;
      gap: clamp(16px, 2.5vw, 36px);
      margin: 0 auto;
    }

    /* Left Panel: Emblem & Animations */
    .shield-showcase-panel {
      display: flex;
      align-items: center;
      justify-content: center;
      position: relative;
      background: transparent;
      border: 0;
      overflow: visible;
    }

    .uj-shield-viewport {
      position: relative;
      z-index: 5;
      width: 100%;
      max-width: 440px;
      display: flex;
      align-items: center;
      justify-content: center;
      perspective: 800px;
    }

    #grandUjLogoSvg {
      width: 100%;
      height: clamp(310px, 47vh, 430px);
      max-height: 440px;
      overflow: visible;
      filter: drop-shadow(0 20px 35px rgba(0, 0, 0, 0.55));
      transition: filter 0.35s ease;
      will-change: transform;
    }

    .orbit-ring-cw {
      transform-box: view-box;
      transform-origin: 200px 225px;
      animation: spinCW 28s linear infinite;
    }

    .orbit-ring-ccw {
      transform-box: view-box;
      transform-origin: 200px 225px;
      animation: spinCCW 20s linear infinite;
    }

    @keyframes spinCW {
      from { transform: rotate(0deg); }
      to   { transform: rotate(360deg); }
    }

    @keyframes spinCCW {
      from { transform: rotate(360deg); }
      to   { transform: rotate(0deg); }
    }

    #shieldProgressRing {
      transition: stroke-dashoffset 0.25s ease, stroke 0.3s ease;
    }

    #flameGlowCircle {
      transform-box: fill-box;
      transform-origin: center;
      opacity: .5;
      transition: transform .2s ease, opacity .2s ease;
    }
    #flameGlowCircle.pulse {
      transform: scale(1.4);
      opacity: 1;
    }

    #torchFlameGroup {
      transform-origin: 200px 145px;
      transition: transform 0.22s cubic-bezier(0.34, 1.56, 0.64, 1), filter 0.25s ease;
    }

    /* Right Panel: Sign-In Card */
    .login-form-panel {
      background: #F8FAF9;
      border-radius: 18px;
      border-top: 5px solid var(--uj-green);
      box-shadow: 0 25px 65px rgba(0,0,0,.55), 0 0 0 1px rgba(255,255,255,.16);
      padding: clamp(16px, 2.5vh, 28px) clamp(20px, 2.8vw, 36px);
      width: 100%;
      max-width: 420px;
      margin: 0 auto;
      transition: box-shadow .35s ease, border-top-color .35s ease;
      font-family: "Plus Jakarta Sans", Inter, system-ui, sans-serif;
    }

    .split-login-card.state-email .login-form-panel {
      border-top-color: var(--uj-emerald);
      box-shadow: 0 28px 75px rgba(16,185,129,.26), 0 0 0 1.5px rgba(16,185,129,.4);
    }
    .split-login-card.state-password .login-form-panel {
      border-top-color: var(--uj-gold);
      box-shadow: 0 28px 75px rgba(212,175,55,.28), 0 0 0 1.5px rgba(212,175,55,.45);
    }
    .split-login-card.state-error .login-form-panel {
      border-top-color: var(--uj-red);
      box-shadow: 0 0 0 1.5px rgba(239, 68, 68, .7), 0 0 90px 22px rgba(239, 68, 68, .6), 0 25px 65px rgba(0, 0, 0, .45);
      animation: cardShake 0.45s cubic-bezier(0.36, 0.07, 0.19, 0.97) both, uimsErrGlow .9s ease-out;
    }

    @keyframes cardShake {
      10%, 90% { transform: translate3d(-3px, 0, 0); }
      20%, 80% { transform: translate3d(5px, 0, 0); }
      30%, 50%, 70% { transform: translate3d(-7px, 0, 0); }
      40%, 60% { transform: translate3d(7px, 0, 0); }
    }

    @keyframes uimsErrGlow {
      0%   { box-shadow: 0 0 0 3px rgba(239, 68, 68, .9), 0 0 120px 30px rgba(239, 68, 68, .85), 0 25px 65px rgba(0, 0, 0, .45); }
      100% { box-shadow: 0 0 0 1.5px rgba(239, 68, 68, .7), 0 0 90px 22px rgba(239, 68, 68, .6), 0 25px 65px rgba(0, 0, 0, .45); }
    }

    .login-form-inner {
      width: 100%;
      margin: 0 auto;
    }

    .portal-heading-box {
      text-align: center;
      margin-bottom: clamp(8px, 1.4vh, 14px);
    }

    .fp-logo {
      width: 54px;
      height: 54px;
      margin: 0 auto 6px;
      border-radius: 50%;
      background: #fff;
      display: grid;
      place-items: center;
      box-shadow: 0 0 0 5px rgba(23,133,104,.10), 0 6px 14px rgba(7,82,62,.16);
    }
    .fp-logo img {
      height: 36px;
      width: auto;
      display: block;
    }

    .fp-pill {
      display: inline-block;
      background: #EAF4EF;
      color: #178568;
      font-weight: 700;
      font-size: 10.5px;
      letter-spacing: .12em;
      text-transform: uppercase;
      padding: 4px 12px;
      border-radius: 999px;
    }

    .login-form-panel .portal-main-title {
      margin: 6px 0 3px;
      font-size: clamp(20px, 2.3vh, 24px);
      font-weight: 800;
      color: #07523E;
      letter-spacing: -.02em;
    }

    .login-form-panel .portal-sub-title {
      margin: 0;
      font-size: 12px;
      line-height: 1.45;
      color: #65756E;
      font-weight: 400;
    }

    /* Form Fields */
    .form-group {
      margin-bottom: clamp(7px, 1.2vh, 11px);
    }

    .form-label-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 4px;
    }

    .login-form-panel .form-label {
      font-weight: 700;
      font-size: 12.5px;
      color: #183B31;
    }

    .login-form-panel .domain-badge {
      font-size: 11px;
      font-weight: 600;
      color: #64748b;
    }

    .login-form-panel .forgot-link {
      font-weight: 700;
      font-size: 12px;
      color: #178568;
      background: none;
      border: none;
      cursor: pointer;
      padding: 0;
    }

    .login-form-panel .uims-input-group {
      height: clamp(40px, 4.8vh, 46px);
      border: 1px solid #E2E8E5;
      border-radius: 12px;
      overflow: hidden;
      background: #EEF2FF;
      box-shadow: none;
      transition: border-color .2s, box-shadow .2s;
      display: flex;
      align-items: center;
    }

    .login-form-panel .uims-input-group:focus-within {
      border-color: #178568;
      box-shadow: 0 0 0 3px rgba(23,133,104,.25);
    }
    .login-form-panel .uims-input-group.input-invalid {
      border-color: #dc2626;
      box-shadow: 0 0 0 3px rgba(220,38,38,.15);
    }

    .login-form-panel .uims-input-addon {
      width: 40px;
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #EAF4EF;
      color: #178568;
      border: 0;
      flex: none;
    }

    .login-form-panel .uims-input {
      flex: 1;
      height: 100%;
      background: transparent;
      border: none;
      padding: 0 10px;
      font-size: 14px;
      color: #183B31;
      font-family: inherit;
      outline: none;
    }

    .login-form-panel .uims-eye-btn {
      width: 40px;
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #EAF4EF;
      color: #65756E;
      border: 0;
      cursor: pointer;
      flex: none;
    }

    .login-form-panel .sign-in-btn {
      width: 100%;
      height: clamp(42px, 5.0vh, 48px);
      border-radius: 14px;
      font-size: 15.5px;
      font-weight: 800;
      background: linear-gradient(90deg, #07523E, #178568);
      box-shadow: 0 10px 20px rgba(7,82,62,.24);
      font-family: inherit;
      color: #fff;
      border: none;
      cursor: pointer;
      margin-top: 4px;
      transition: transform 0.15s ease, box-shadow 0.15s ease;
    }

    .official-alert {
      padding: 7px 11px;
      border-radius: 9px;
      margin-bottom: 8px;
      font-size: 12.5px;
      gap: 7px;
      align-items: center;
      display: flex;
    }
    .alert-error {
      background: #fef2f2;
      border: 1px solid #fecaca;
      color: #991b1b;
    }
    .alert-success {
      background: #ecfdf5;
      border: 1px solid #a7f3d0;
      color: #065f46;
    }

    .fp-secure {
      display: flex;
      justify-content: center;
      align-items: center;
      gap: 6px;
      margin-top: clamp(6px, 1.0vh, 10px);
      font-size: 11.5px;
      color: #65756E;
    }
    .fp-secure svg {
      color: #178568;
      flex: none;
    }

    /* Clean Full-Width Bottom Footer */
    .fp-footer {
      position: relative;
      z-index: 10;
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 8px 24px;
      padding: 8px 48px;
      background: rgba(2, 30, 22, .68);
      backdrop-filter: blur(8px);
      -webkit-backdrop-filter: blur(8px);
      border-top: 1px solid rgba(255,255,255,.08);
      color: #dbe8e1;
      font-family: "Plus Jakarta Sans", Inter, system-ui, sans-serif;
      font-size: 12.5px;
      font-weight: 500;
      flex-shrink: 0;
      width: 100%;
    }

    .fp-footer-nav {
      display: flex;
      gap: 24px;
    }

    .fp-footer-link {
      background: none;
      border: 0;
      padding: 3px 0;
      cursor: pointer;
      color: #fff;
      font: inherit;
      font-weight: 600;
    }
    .fp-footer-link:hover {
      text-decoration: underline;
      text-underline-offset: 4px;
    }

    /* Modals */
    .modal-overlay {
      position: fixed;
      inset: 0;
      background: rgba(0, 0, 0, 0.65);
      backdrop-filter: blur(4px);
      z-index: 100;
      display: none;
      align-items: center;
      justify-content: center;
      padding: 16px;
    }
    .modal-overlay.show {
      display: flex !important;
    }
    .modal-card {
      background: #fff;
      border-radius: 14px;
      width: 100%;
      max-width: 440px;
      overflow: hidden;
      box-shadow: 0 20px 40px rgba(0,0,0,0.4);
    }
    .modal-head {
      background: #064e27;
      color: #fff;
      padding: 12px 18px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-weight: 700;
    }
    .modal-body {
      padding: 18px;
      font-size: 13.5px;
      line-height: 1.6;
      color: #334155;
    }
    .modal-foot {
      padding: 10px 18px;
      background: #f8fafc;
      border-top: 1px solid #e2e8f0;
      display: flex;
      justify-content: flex-end;
    }
    .nav-portal-btn {
      background-color: var(--uj-green);
      color: #ffffff;
      border: none;
      font-family: inherit;
      font-size: 13px;
      font-weight: 600;
      padding: 6px 16px;
      border-radius: 6px;
      cursor: pointer;
    }

    @media (max-width: 860px) {
      html, body {
        height: auto;
        min-height: 100vh;
        overflow-y: auto;
      }
      #form1 {
        height: auto;
        min-height: 100vh;
        overflow-y: auto;
      }
      .split-login-card {
        grid-template-columns: 1fr;
        max-width: 440px;
        padding-top: 14px;
      }
      .fp-footer {
        padding: 12px 20px;
        justify-content: center;
        text-align: center;
      }
      #grandUjLogoSvg {
        height: 220px;
        max-height: 220px;
      }
    }
      /* ===== Error: spin the UJ emblem and show a red lock over it ===== */
    #authenticShieldBody {
      transform-box: view-box;
      transform-origin: 200px 230px;
    }
    .split-login-card.state-error #authenticShieldBody {
      animation: ujLogoErrorFlip 0.65s cubic-bezier(0.25, 1, 0.5, 1) forwards;
    }
    @keyframes ujLogoErrorFlip {
      0%   { transform: rotateY(0deg); }
      100% { transform: rotateY(360deg); }
    }
    #errorRedLockOverlay {
      opacity: 0;
      transform-box: view-box;
      transform-origin: 200px 230px;
      transform: scale(0.75);
      transition: opacity 0.25s ease, transform 0.32s cubic-bezier(0.25, 1, 0.5, 1);
      pointer-events: none;
    }
    .split-login-card.state-error #errorRedLockOverlay {
      opacity: 1;
      transform: scale(1);
    }
  </style>
</head>
<body>
  <form id="form1" runat="server">
    <a class="skip-link" href="#txtEmail">Skip to sign-in form</a>

    <!-- Fixed Background Canvas & Elements -->
<canvas id="bgCanvas"></canvas>
  <div class="uims-bg" aria-hidden="true">
    <div class="uims-bg-dots"></div>
    <svg class="uims-bg-lines" data-bg-lines data-depth="1" viewBox="0 0 1919 860" preserveAspectRatio="xMidYMid slice" focusable="false">
      <circle cx="1800" cy="190" r="405" /><circle cx="1800" cy="190" r="555" />
    </svg>
    <svg class="uims-bg-lines" data-bg-lines data-depth="2" viewBox="0 0 1919 860" preserveAspectRatio="xMidYMid slice" focusable="false">
      <circle cx="0" cy="1060" r="388" /><circle cx="0" cy="1060" r="557" />
    </svg>
  </div>


  <!-- 4. MAIN SPLIT LOGIN CARD -->

    <!-- Main Stage: Single Container -->
    <main class="main-stage">
      <div class="split-login-card" id="loginCard">

        <!-- Left Panel: Official UJ Crest -->
<div class="shield-showcase-panel" aria-hidden="true">

        <!-- Giant Interactive Official UJ Crest (>78% of Card Height) -->
        <div class="uj-shield-viewport">
          <svg id="grandUjLogoSvg" viewBox="0 0 400 460">
            <defs>
              <!-- Dynamic Background Aura Behind Shield -->
              <radialGradient id="shieldAuraGrad" cx="50%" cy="48%" r="50%">
                <stop offset="0%" stop-color="#10b981" stop-opacity="0.42"/>
                <stop offset="60%" stop-color="#009639" stop-opacity="0.14"/>
                <stop offset="100%" stop-color="#009639" stop-opacity="0"/>
              </radialGradient>
              <!-- Flame Glow -->
              <radialGradient id="flameAuraGrad" cx="50%" cy="50%" r="50%">
                <stop offset="0%" stop-color="#ff4d4d" stop-opacity="0.85"/>
                <stop offset="60%" stop-color="#f59e0b" stop-opacity="0.35"/>
                <stop offset="100%" stop-color="#e60000" stop-opacity="0"/>
              </radialGradient>
              <!-- Arched Path for Top "الجامعة الأردنية" Calligraphy -->
              <path id="topUniversityArc" d="M 106 108 Q 200 66 294 108" />
              <!-- Clip paths for the two Red Medallion interiors -->
              <clipPath id="leftMedallionClip">
                <circle cx="155" cy="306" r="39"/>
              </clipPath>
              <clipPath id="rightMedallionClip">
                <circle cx="245" cy="306" r="39"/>
              </clipPath>
            </defs>

            <!-- 1. Interactive Ambient Aura & Orbital Rings Merged with Background -->
            <circle id="shieldAuraCircle" cx="200" cy="228" r="190" fill="url(#shieldAuraGrad)"/>

            <g class="orbit-ring-cw">
              <circle cx="200" cy="225" r="186" fill="none" stroke="rgba(167, 243, 208, 0.25)" stroke-width="1.5" stroke-dasharray="14 10"/>
              <circle cx="200" cy="39" r="3.5" fill="#34d399"/>
              <circle cx="386" cy="225" r="3.5" fill="#fbbf24"/>
              <circle cx="200" cy="411" r="3.5" fill="#ef4444"/>
              <circle cx="14" cy="225" r="3.5" fill="#34d399"/>
            </g>

            <g class="orbit-ring-ccw">
              <circle cx="200" cy="225" r="174" fill="none" stroke="rgba(251, 191, 36, 0.3)" stroke-width="1.5" stroke-dasharray="28 16"/>
            </g>

            <!-- Interactive Progress Ring that fills as user types Email/Password -->
            <circle
              id="shieldProgressRing"
              cx="200"
              cy="225"
              r="180"
              fill="none"
              stroke="#34d399"
              stroke-width="4"
              stroke-linecap="round"
              stroke-dasharray="1131"
              stroke-dashoffset="1131"
              transform="rotate(-90 200 225)"
              opacity="0.85"
            />
            <g id="authenticShieldBody">
              <!-- Official University of Jordan emblem (transparent WebP, embedded) -->
              <image href="data:image/webp;base64,UklGRsKaAQBXRUJQVlA4WAoAAAAQAAAAqwIAgwMAQUxQSOBgAAABFEmSJMeNlJFA/P/RKIDds9wjYgLyef9kPq5pz7kfyfoA60iyd5J17DMJiyfONSRZwMoVaH1w5KqMgtwvqG2BqragCjK2wAC2oO7TO/LYriRrMWtPFbBtBx1YyeohP9gKBShAkqy2jO2TCKWqQMa11hpOAekBCoesKeA+j1EAoShj9pjeD5mdGddt3dpy9WPGvRP9HcqU7MRH2oEnbnunL4JQtPeXJH6YfXxbPNTiZ0o6Z60HsN+BjHvHV9DBj2tK+izg55bL8rFtEQH7AFOyHlVbTtnY6xr2jneEAgioeCkr443X+hG4dARsBxVxf9k7egPaQqFA+ZDEeYINVAG81akM5wEFGW8waUcAgTIKfqszsDkXazFe6prWmuS61uJUJsg+s7SnPjDXkXpJHQE8EAR8zRVAQF5VW2xbWLe2pfymD2llFPoTJZ13WvD46rS3eey2n+S1ue6dlNNL+VjTxyxklkcBAfK6kxZQWqCDjy977+kUTwA7mvedeE60PZBzJfs9aVuu0goUMJ928gTKbH50AYLDY3541XcK5Me/KOQXV2uvgPnV5Xi05Ldpi8fKH2iBmj9zAfmPeqO227WsZNuuPsaYq3bebILknDY556wiIEkkmMVAUFEU441IxnSTzYIRMHOjt5koSck5CAKbJDnvUHOE3kf/UVVrrVo151yr6ldETIBvSZIsSZJs6///eC5J9GKqclM186i3iJgAyrUtSZIUZEIHlEIqZGI37WuKG8UY6W5uZu7LiAg727aplYBkDZfWYfkBlN5z0XJRUTmVO507lO7uTuXuDq27u+6ezHzP+02RZGYyySbnooqICYDcNpIkSZre15qw/nvaV2RNAPVbRMQESHLbSJCk/z9aulRmZM12hqP2FhETgMG//GOWJqGMMf0KkZl0sgCZ/sSggDMDN7GZw6bf3xgORH2Hozf9/F0obPNwZzwVNxZvfkj/vowpCNRnGNP6sT5zNFA0jo00IsUt4d2v6GL9zWzr+g1y5mxdtMSftxRaNLgygL0c3BeGc5m8XjSzcOgrybrTNIZySb5qE7TMAE1ak8UaFyt75uj1+66wfUWBT6YYUvSLecHBIDeYImUla7D3g+o9M3MM+csYoj6iwIGvZ8+cUlwUF50+Gy0aQClRURC7FHCfeUOHUxrBgeORGOofHHZ4SgOPksqgV22Nwg6eSIhXbQus9DPhMo0hUV49EEW/UGD+gxp41JRSGNZnDodxg6esgNjFWOx2m/rIo8pIr0/vgKI/sFjhBvUiMoJTSmk4p3OXQosGX6KI2MTBHvOSlolHyqjMUe9cDbYfOD2548dT0HDAzIl90ms2hbUDr8quu9NbPPUoS4SD/mWmsc3v9PSO70rGiKQBs6Sg/z3GoaDJFmfxwG8ni6BSTnrRkLFNj84vXpUiqhhUf70mCjO5UsB9/E8poJoc9EfOmGZH7uTZCVPVkPQ/7wa5SRTjsPYvcwqqzFG/3SpMk6MCj+mJqsxR4znLYMhMljiDfR/QGFU9Rf0ShhocDWHff3hU/ZD0up1gWjVnJTL9hykw/cSFWibNGNLwYRhqbgV2fDr1zCAp6KsnzEPL1lplMmT7DWexyR+VfWJmEK/P7oKiqRXY7BHtTbNyEL16V5ii9gR85fcUsHPhqFqI6s0UmPmZ/6oPzOPC7PXxzTHUzBzWuVVLmEcken3llKUwZOpL8CT44mtNgbln/nkLOFspNd8C9rxKtUw8TsJc6kObYKiJWXrT5Toc55NUZr12d5iCGkBHa7HTNTH8+z0Wrk+wBZb9+usaPI+UeZmX6L3roWhe1sz+lZaRG2CJUV89ZTkUtmpc5fJkhwLuY0/pwldTee7ycKYPMAVhtxtUysQjZdzZ6x2rk2taZO131MfUCyLCXvTafYHCVsuyImdpaFpY4YcpLfJhsdd/7AxTNL7CYflTXtQyCgtLT3LQK5cj26yooNM1RO4ZCV4X/nA+0DI1dF/BWexwo5ZljCGUS/SFE5dCyzQ628L099+m6pMws3Q/tyXs9eIhR43K4XOcAjNLsylkXXDCqiBHteNJGtoCcz7/opaRU0qJo8967VsA19xsAWz/66QxyHh6liy5LeGkp8FRg2rhA4GjtO9zSU5R9c5j5sEUVDM9W8DbL1cNIjxSWGLQhd9YGi1qZrYgrPPNF5UjS5c9vy1JHI9Eqzm1cNCrmqTHRCRGlRvfOwPONjHTwjJnL9IQZQwWkeSz/vPNsK6JFQ4rHP+QamTpspe2l2N+fU+0mlKBnZ7RIB2qA6RgKV62PeBM43IWO9ygElhKLeorn5uGghoW2RZmvOsW1RClvEh3WbIEfWJzuGbksN69GqR91wNETPrS6cuDCtOoTAF7xLMaknQziP52c9iCmpR1wC6XRvWRpYd0NWrQu9aDa0IWK12rQSaMkle9/ailYFrUnJzBphcFLVm6G4M+9cV5sK4x2QK06TnPa/BJJkTOIiJer10BtvlYN+ePWqYuqW3DEFT+9e65MIVtRtZi6U8/oSFI17lUvfagIRS2GmxnHLDhWU9q9lG6afdjdC71dzOcbTqmMN/WMkn3HMDMPmj8+/tmA4WlunE9W8Dse4XIcGTumkgIWv56J6AwFSDdbQGsf8ojqiEwc0cOHU2S1/PgTLOhFo7jMnBHRLRNmDkOew1XHbUi0DI1s7xpATte/LqWw4lZxjP5pM+dsx7Qookm1W0BbHDqQ6o+JGGWDh07hiSvp6FFjabAe9+IgTuysCsxx2Gv6fZPrQI421yoMFjzjOc1LgkppfERicOiD31qORhHE0osZh2w1mkLVEufOEnHDh5DYtRjUVCDaeFtL4vnTizuEGHmJLGMmm/9+IqAddRIqHCYe8T9ymVMnJjHiZljqXrte6fDODOBipMzwBqfu181BBZh7sTRY4mPw+9Gq7kU2HGBDnOP2DUylV7lpi+tZ0GFbRzUMhg64PKsPvDoMs7Mwt5r+PNB04GWaRq2ZeA2Pfke1TIkYZbOZ+U8hoT80n5oNZUCWz+kZWLp0PoOkVGYU+lVH/7BLrOBwlGTIGcw/e2XLdIQRGQUGXdm5lRGXfz3984DOWoQZB0wfdefP64aA4uIdMFTxOf/7o5WM2lh/n3qWYTbszPh4xMiMoKZfVB95Q+HrwaYwjQFVxBae/56oXJgGU/3vNE5JA1XvG8ZwJmGYAoLrPau37yiGqN01xPHEq+Pb42iiTiscqN6Zul0huePJTKKpOBF+c7TN7egwlIDMEOEGQf/5jUVn7J028drSE5l1PiPD84FnKk/si2C2+Ebd0TNPknujmeOJUHvWQe2eVg75/fqk3Q+wUvbGZ2Fo4+qT/70bfMA50zNmcJgufdfOazsk3TfMyuICPuk4cr3LA1ytt7IOWDpvS96TjX5JN3Op0nQq+eQbRrGme9pSNxZ7rKyM2FhSb4Uff2KI+cDcM7UFjkHLPW+64OmkKTLubiKCIek5RUfWB6wztQVOUfA/KOvWagSAmfpMFfjKBz0py1rmoUZwudziMzcSZ6gnYgIs3DwSfnf5x84D4ArTB3ZwgJz33150hhSlu7mbnZHJJZBww1fmA+gcFQ/ZAsCZu73rYdEU0iSpcNclaMIez0VBTUJU+DDJQfuLFeGCLNwLL3qohvPeetyAKw19WKcA4Y2/Pw1wxo8S9e7krvDIqmMqg99e/d5gLWmVsg6AmZveeIVi1R9GaWLFSMpxE/CNYkCB7+RgrB0aicwTBKC2LPqa/86bbdlAJjCUnVRe+QcAavs97MFqjEg0ZRaIAkR+pT+cfUnt2gB1lFNGOcImLHNZ//yjCr7wEyh91xJiAsPRtEcCrz5ZfbC0mOMG7o4lFH1latO3mtZALawhqqObGGB2bufdvMSleHSNGuZVozGg2l++pcfWB4g56jqyDgLwG149G+ezSqlTyIsV3PFJb+wF4aagsMmj+Zh5s7spMmGIaeyTKqv3HDmXisVADlnqGqoDWOdBYbWPu7vL6rGJT4lWIZFuON91njLV7ecARhnqbqMdQbA3M0//av7k0rpI49aD1zmJ3eEawYOa96uwymxdGrvWcKSyjKpvnrvBR/ZcmkAZK01VCEgAmCsswDsGvv/9GHWtKSMnDihQlcjNOhKd88Y5VgG1f9e+tGNpwOw1hJVDVnnHIBizT1PueKpoNmXkYVHSnfvI8zD+d+bomgCFm+6RsvE0rFH2TOShWPpk2p87vKvvWs9BwDGFc6aaiCyReEAYM52H/nePYtVfBmYE4+s5AQVrBCR5Muk4bFffXy7mQBgCmeoGshYV1iMXGaHo39278KsXA6HxMKjSn3wsN6+Plr1ZzH7Mi0TTwR724Q5C7Mvvaim+3/3jfdusswQABhnDdHEMtYVFgBmrX/YWX97WlVTGZiZE3dlcsq+iFk4DJes+sRfz/3ARnMAwFhrzIQiY11hCQCmrbTr0d++5llVjcFHZhFhZpaue9WVMEupN60LV3eGlvqFBmaWTj2/bUzm6H1S1fKJWy7+wv6bLGcBgKy11hD1GIGsdc4SAFpmwwNPv+LRYVVNISZuU9r2BRcJjxpKn1XDE9d+852br+AAgJy1hnqOjLXOGYycu/pWh331/+55Iatq8pGZhZllnO+ii5Fe71wPrt4M5vxCA0vn3nCISM6Zo/cxq8qSJ6/4zif332IFwkiy1hXOGiIaHyIy1rrCFRYjZ6yz68e+deWTi1U1eZ8kS9eX5EUyCouk4GNWHX7hnxd85oAt5mGkcc45awzR+BCRMbZwhTMYdc78PQ4//f8feLFUVQk+JMnSo7dxLPF657pwdWZscYF6ZuEqcsrInIWT9z6oqi7+z3UXn3H4HuvMnWYxKlnrnHPWWmvGtGO7onDWYPRiqc3e+fnz/v+uF1RVY+kjyzj6wstEhFlG5VD6oKrqH73yh5/ff/05FqOSsSPNSGuNMXZs54rCWWsMRpqhOWu+5fATfvDXe1/OqsrBlyGJ5JH1lMeSUq9dGqbGHE7UyNJuzjdx0Ngp+NKHrKpLnn3whj/84Csf2XuLNZeZYTHOdsa8FdfYdM+jT7/kn48tVFXN0fvIMr6+Qm0zR+8Dq6q+9vD1P//Se/bYfK3lZrcwzmbaUiusu/N7Pnve/13/4Aulqip7X/rIzDJyRK6nPJYE/fk0Q7Xl8B4fk7SZK7olYRFO0ZfDQVRVxb/xwiPX/PL8E4894n3v3Petu2yz8Xprrrryyquusc78jTbebPMtttnxbQcfceJ3f33FbY8893pQ1czBh5gkZxlfX/5cwpKzpOjLkLJqXvLa8wtu/uOPTvzgvjtvsdF6a6+15hprrr3Ouuuvv8GGG2++zY677/2O93z4Uyede/Hf7njylWFWVRX2pQ+JRZhZxqyxPBYH/R8UVFMF9ngxJ6k+95ZGijCnEMrhYR8i68icJcWw+IVHH7jjphtvvOm2ux/8z4Inn37mxdcCZx01p+jLEJklZxl3X8O52uQYymEfE+tIiQufeeyBu+687bY77rjrnvvuf+Chx558/rXhEFmyjppC8KWPMbGIMAuztCE1lseQlN54B1w9OWzwiAZpFiLctnBKwfuy9N77EGOSrO1n4RR8OVyW3oeYkvSqr2QjIszMKQbvh8vhEEVVNWfJWXPOmrNwisH7siyHS+9DjImFRYSFeYSw9ID3kzaDPLktXB1ZrHmTemk7V3lDIu2MLsIizMwpxRh86b33IYQQQ4wxJZaRzNK7vp6NiPCoIsKcYozB+7Is/cgQfIwpMTPLqMzM0vU8emd5v/HObbDXe9eDrR+Dpa/SUrgu3BuSDkRYuE1pk0VEuO068lZklLFFWJg58ejCnY9bHiV39+GdpR0u9fLl4OrGmBm/1iXMUh8+cPfcA11mGdH2KMIymvSw30DS3phjdXP8xhXnWibMS/SiWcbWi6HW93U4pVqJnkGC8L9/DPa2Y4AHy1Xna96V5zHJ6w9mwtUJWTpbh2PimvKQ54apasbGyk2Ue1fWZ/CPk9cfzYarD2PxFS1jqq/nIWONF7zwIVBHo3eCIxDhUn+1NGxdGIPPxRB4ZI1FL+Mt4QGXesbo966EZ4AZ4aB/WA62HqjA5yRGHimNQG/iXQCUESp4Cu1edxyqGWGvv55Ntg7I4cgYIzcKtcjlS6lsO3TlfhLwoN8Lj1tnhL1+yzlTAwUOfCN5HlXat/8yHeRFkBmdoNgz0isfohgSjvw5OKo8i12ez4GbibrQlC8k0VPWpxnFMyIc/cEoqs5grX+r59GlfbOd4l0voebhJSTmp7eGqzaLZa5WLyOk43A05z7i2YQX6iU0Dg3AMI2I11tXga0yQ9Mu1pKZWbp4P+AsE4YXHk3hbczDCBzDXOqlM8lUl7H2LBlOXTIrr0rtCCb5K179AsK8RM8z1lSVNTgpLU7cFTsEOMu3sv5iioDX3zHLWBzOX4Gx1WQc/ofLOEI6b4Oz9H0UL+GJzzKX2OGOc1LyfCLIVBEVOCZ5n5hZOjcsb9tz0YrxjO8LOH8sYeYY9GsOpoIsDlkcAydm6dguL+GNS2xE5QgVxHdXfuexhJljqedON7ZyCuz5knge+Vri8WB/Aj/Ti5HBP/7f67eHiCrGYKsn1TPzPwqDunWFndzKqIwAyetXyVKlGKx9dy6ZpSt+CfqwkRVXijrBMfDHYalCHFa/RT0zs+T9AHHlzIXjT0hIr++DojosVrheh5mlm34xfoAxEfb6yCYwVWGwzOU6LMzcBf8GmcPyCzDDpf5zRZhqMJhxqZbSXf8MR/kNJoR5WH8/D6YKDNnvasnd8W/BkWDO3M2EcFoiF7RAE4+M/Voukww4xB+T5dWMMXNclP7XEk00IpwsZeIOxHuyCeFrwFHsOIomQyKc4uJ4KkATixy+mMvIHd2Tfbwgc1h5MtEM2xCePZrgUPKpNMEsPuxj4A68KNyaYqcHln0gxaMsQm5jiBPHUk+zRBPI4sCFITJLm/mu/0rEMglU0CEv3gJ2JOeZoTthZo5e/geGJozFbi9zYJY2c7/kjhQ8gW/kTpiZo48fgzMTxGCTR7VkZh4rNxtvArBaNs03MsYhvX4AHE0Iiw3vUy8s7TYdvYcCyrZrDrKAlDyOISPE83M7wdEEMFjndi2Zf/y7HV/FLHwZCtQjYJIk0CE9uiFc7xmscrMO80iux0WaglRDsLmEK7jlFDTtngVXesvysL1maPlrdZiZ+UfQEzFBtAgO6EXUAgFMvAjxMvt3hEqCUn+/FNneIiou1mHp1Ou28WzsWWF8ZB05yLMEL9ELHdleIoNTtWQWbsurUcC6N74EXwM4Ltb/NZZ6hwifSyFJp69CsdRxCfJR70A248qhgzxHYo6lnARDvUIGX0g+SofeOEaMFDhNyBtQxN5LeZYwx1KOh6XeIINPqw/C7fkfyTPgmQmViODwU4Q5+HQMLPUCWbw/hMAs7Xpn8hvqrZERkFrjoYQN4gMcjoMLhNnHRYfA9YLDPouDZ5Z2/Q+DZ82xRQSHjS4RkcCvvAUFjZvBpk/lUtrzZfhUWF+EqNEI1/IiZi+PbwE3XhZr36HDidvx3gWAEoRBwS0oQd5A5cw+P7AhCtB4OKxxsw4nniio4hj64cFKkrdyLxJhr/fMhxsPg1Wu08UppXYczH5TZlogwPY81+RfhIf1XyvDds9ihet1CSceOVo+wjYsGc9TCZ/ADF5DmIf178uR7ZalWX/UxSnxSOk9yjEOIQRjPSk8C17GK4hIqT8fMqY7xprv6mJuEIfQmp8fh/QSWNMNY/Al9YnJRflDuDI2PpUlsqDjYE1n1uFTIURBA003Q9i5f2HLs3j1VhRbH45EQZ1QgY+VMQoDym4Fz3AIAZjthO1xqgvvXaMYFx8M2wFZfHBxDCydNxN2eMBnEe2Z8QQOoGKLNSjwc7vCtdfCvq9FzxXg/AAPi+hMTUntg2GWbLJE4lIfmA/XjsN2T/CSlJg78tY8yU8FI4KCvfESvWZZ0FgW694ri+PE88ycg+jiVWAiVC60j2eBMC/RX00zZjSH1W/VxWkULvAZeQa8SfER+w54nvCMxJ11dKAV2HEFkTSs58GYERaz/qhvxNgNn5F1RLGdCfQWaI5XgG+xHkV9BsxpiZ4AQ4Ax7nx9owyhC97SQJ4lzF5Rvh/rv2L5IQwWwIoMH0dEQtDjZxIRDZ2YFg6HGCuN7XGvdsEfEJzEtqdoSm8m1KuwxGE9BNZi98WvLPRd8Rb44VhRdDCNOAXAKu6A1ZK8XrIyEdFS54TXes9hVN6D4pSnUO5AR/AG9+oU9DuzYADC9At0oY8xVRaNykULuXrxhKcSMk5pLcAvWcoSg36zBQsCDKb9SJeEMWhFwak9XkRyfozngtLuWLHsSWLIJxEZEAAYTP+uLu6C5hr87bwCQSm+Bu84wy6Ch3Ba8ukEkMGYhmZepIvjKFodehPSFbCzignl94GYZUTFJQQMEWd3lMp8KoxBmwbz/qKLqok2fwcbX4khEjBkuHSahvU8awzatlj5Gl2cWKqGdp/3QeVulvgj4f3oNJV6wUwYag8GK/xJl6QOtDQGur4M4UvoabSLIsCt+mWyRAgmIp+8nj8LFh1bzP2dLulES2LmxqvwORipbA+zBINmC1cjn7yeYmHQRYu5v9FhKV0OM70MINkJqCwA5ByLOfAwLXGn58Uo9PlUwKCrBsv8TYcFAia0GId5jfwEyfbAB9IKoHJRAUN6GQo56LnGGnTZYPlr9VqMj2l3DGMar2Tsqqqgr1LqxUNk0HWLNW5P11oHfxrG+HM8MXw5r5ctC4NxtFjru+mqHX4AhhgApApUMk4xwmexeBZd5Ev9w/JwGFeLy2+nKzOAMaPQFsevZOuuPaMz8p+EolaEFC2keVh/Mw8W41x09/pKulIDijBGrSEAY7afwe9mTpE5XOrvloaj8cJ5d/dvpmsMmGt8DTtvxSgHnuEZcASQDpO41IuXgsP4dWfd5dfSf2WoCQZZw/Xoc5QzSHnIehBblVK9gDdo3okI87D+fCYcevKiu/xmugLGzI0uAh5cvM8quIeHAfMUXlc/kyoipf52Diz1BhzWuVWXtKG1sAMvRl7Ps9QulP5G80jxes3ycOhZi3Xu0mHhMbQS1KtcvsmVcahhokiOyWbW1vPvVh0+mowIes+6sNQ7aGGTB7WUNtdNuB7jWG4ADnOG6jC67SLnnKM+uRUcepkctn46h1wP4KsAw1grkzgB0N+M9iTnxG/sBQfqJZDDW1+QOJZWbrLqEex4wBBiY1VQOUCV4iKmIWNxTB+HI/Q4tfDuJTGNpS3hQdzPg5zGLfXtgFjOHPQ0OIOeJ4tPhJCE/UA0RgMq81g6j78B4ZS/MUQGE5AsTlKfxIikxbnweYzrI9IbtiY5egchR1hnLZf0OcRLs2wrRf1aiwgT0hj7LfUIxqSlKa4/hkkOj0CVKupH0odyJ7Y5ZxmVvX7dkMEEtTTt53qVpcUFL+E5dnDXnMkEIO/klEu8NIVef9iCwYS1tNTf0jUwJW0Il4dQxVVVYaMCFmaqE7h2Qal/nAODCWyxyvfSdZ468OFRsiDDzQBLD7IJ28ijBL1/LVhM6AL3+b312jCahztqDQ8O8X6UJZRFJKaX9oDDhCa47qH/CyYyZBSHwKowfClPkXbPWcMC53nIKNURzd6dZM5ZxMvRMJjodNE9Mx3QyvmLwANkP85DfBE7zEjOUuqPrKEJh9PTk9ekkCWfy5yWcKPLrgxF5SQQQl4N+pEc9MblyKICrVnqOg1VY4UmVEugxhNc45UAtyHEUmI9xvXv2GFezpKZX94KFpVosc2LwlVjiRpwXeB1vI/g25lXzkGPhQFVAhyOzbFyLBKNianqE9hwHWyhD99N0+5yEQn6Y2OoKmCmXaZeeAythG7sEZ8BpIRDR3jGc0Vh6POEHb0JeY675KA3L0eGUJUW6z+Wo1SOFex3uN3hRUC5rbK0TvRTgjP8R3rvp1yXJOUXtodFhTocNBxTLWUfiHADxTb1E4Q3DPF36EQSh/hBFKhUg/9Vn8fQmtnkTq4gcp395bgfl1Np0HNhUTG01A0aasQ6RXmGOEZ9OU/x0xF3l8d8y7LGVAwcdniZE4+mFVvbBOBx7tv8dP4Q1yLpcmFL3gaHynU4QcNY0mopYC8K4GF+NZT+aMjJY/oJLKrXmNk3a2xD0moQEsDRBD1FRU3J5yTDoNLRb+fDgioHFrsvTInJ0EoJJ/hsU8WSZU9Md/9LRH8SLBEq2OJr6mVVXHj2lUx4lq9nPCF98fbWgKiCDK1wfw7KX5yAp4ecYJ9K5nkAG5ucxoZJmg26fnBXEKrZ4QMpwKooXMHtHEsfPkt0mn8kbunN3TlVFZnWZdqLbeb2dbwLL8KNKITf3rM7rS6LTZ+XJNyG9BACr5QtMl3FggoWDgN2epWyywqndBBchcqcs3j9LCx6k8Xx6nkCINvbWUOqegESVsEnJzbhgDviEws+AdWWot79JmMqzSx3q4a2pEekC2qdlVRd6Z24kbULVypiEVxejcqcsyQ+HC1UORX4aIxpAtiYY2sQo+PYgDEuZwd295JzzklvmGGp0mBp7s0a+xFqTfjr2A6X+8Ci2snhaE1tyQyKsVAtEnEaQfhw4L2sSfp7sqh6g2UXZO45FQwF6VTWK6fBQ2nwJEBlgOAAG5EsvHg3OKKKg8XpGieCCsbkJnoRb1JaoK2olxhLqHyL+S/m1A6DxOufUSuYYbF86DnELvydWBbtDofqJ2Mv0NAWzOnwBK3RjiAe4b3E2h4sSPr7wlINwGKX1yT1XRZ/jOoHPwVL2AcOdUiWfqWxA74MnGAFRb6T1ngF+4h6TctQLcBhx0XC3A5+ygLoodLtiCyooAjivm5Zolqm4sVL3i3lQ+FQi0SWfqmRuamEZ6hVnNDYY8Z9w9Ur3i3qjUuB6gFksbtPqRF5hltuYoQuoyVev42Uj4ZDPRKRmfYX9U2KT2FlmQE3NuLdkj6yGtmaAKjA4RJZuN9wBagcn+bK4p2FD3vdeL1z4EB1AUMr3a2xHe0xwwgyNRfeTl/bkgxqtMCZGrmhUdd+B2oIFogdeeOCpFc5A6oRh+3fyG1pSoKRSnQGgHAV0gWAM8zLST8Oi+5aishdpUkaFtGMQ4IXoIPndFhfWLdrrcniWA3MbWjKAAluBIOCOVaUHEjUX7cIVeyFCVjMf0mStN2UFll4GssuFZdsyCrbgkM5CkUljRp3kXpuS1dbJJ5jeI69CpQgqLJc0UBhjFmmC9aGrSAvxAgVOMTHxNycklbOog7ZKyHBNUZDCiUMJOgvYVG3RHP/paFBqQFrlnOWAVp3tWzdB9iNMQf5g1HUDgqcmn1T65zFDFpcuSfoYCw9Mpuofgx2fjk1M09RU7Dgr+XHsKhhKv6pkflBeypgd4M1M1tUcM9PBGl/mDoyOCMHll7F93HwT+NTln69YkWJM5b2WBKZmx34ahqAwbynRVRFMk1403059h16HThkPQaNuyumx6JAxXpa0JgLNbSlIxSjyJIz64tbwVbNqg4fyv2IVcj9qCrgGGX0nHPSf8wmU08W27yUU5Y2HKEgYuTkOVa2Q5DR8yjnoYV6Nlj2XxrztOEoeUb0fpw7DtFwGFxNkcPPNLILGHH0KY6xvadXg6kpFDgus0q3GeJJDngOoCziGKUd1mvJoK4tdntNKVHP2NgnOoNBIjjIsSRn0bNga8tg2Yf6A896pqxhljKPnHPWg2sMhv7aFwDUUevOILrxeZLjpC1dsiGoviy+qrYPnKYLCTxD/k0kvWOpGiOLg1U7wHHuuAfIfCQn/QEZ1JfBhm8kdg2j8BiQ4mCyRP0EXH3BYN4dyUrQbyMDQ3IKh+OgylK+pdbIuItTrGCnKCUU/2LU9OG1YGsMBY7fN07A4CkcOkzqUf8+ZEydORyMUcE2OMcifi4Og56PAvW2zYuaBhHU/1ZkOX+i5gxWvlNjNxgVJXoMg0n66pvhao2M/a0G7oKjCk8gx5sCSEzGyUZ9bEXYKnMOBb6hUTp3kNPUK2xzYpAsR/2nsUQVtmKBoyQx9x/AMfsB0EZIRP4EBerd4e2vSeo7WJ5mE1v5fCyHyLEcDweqNqcsNvmv9husPc4Z3cOQ/B4UqPgxg2Uf1MTcCeF5Cy8AjMLvAEcVh0Mw7lqNPcIzH6JXsAJUkj7HQT7pS2vDVJ0Mk8Mvu8Ib7PvkCuoUJvTv5WBQ9Q7B4cwRPJDYz3A+Uf8xi6pv3OLTkUeOF9VGxw7wbyDpT50F1d4hXkZwf8CJXoJpUBj1DDhC7W23RNL4Ud8NF/jbeJjDUY9GC3VPWP1ZjSN4PBgeSZ9zTI3CxLwvXANY6t4xuE9zmrOcAoskeW27JkCzrh2L+yXVvwLW9jFHXTAftvaw0/+/B5yFy5VLYtBhcIixkeVR7li1EbR+1guWzHZQPcsydvj9CKfI8sig1yzdCMxZGnrACtFwDaiCzdBo6CDLY/xhhjH15/Al9SmNkH4PJbwg6c4JRks6RtnF5Kj+CnxUQ//gUaRVKld8PNJO8Pp9FKYJHKI+cT9FDZVVoDLQbI8o9Wy0qAnsJT6mfg9HMcFsOSEFPaUROOxUpshpnCg5DJBq5eDkKOKgn8cQmsC2b6SYxon6AIjQqvibcETyekwjsNj0GQ6Jx4PjbDSEB9L98BTnwTG+H61GMP+RHDj1kPGGzHT9c1GVeMk7UVD9Gaz/n94y4CT+HYiMSAv3bwQWa92XQ+KBhUc4EXnlbShQ/wZr3KMhpfGwZsQpjB5gdFr2/B4oqBHcPW7PwfFHwM/thgL1b7H6nRoSDyzYkG3WyPN7oEVNYLU7NHBiZu4TuKHRn8SmZ8mzu6NoDGn8zIkb+vtZsmtDWP0uDTwKDwg8zYSPeG63hrDmPW3weDgnzzLmWTLi+d0bwtoP5JB6xnx5LVGdg7n8wm4NYb2Hc0g8ZuPjgoZhhJnPkxd3rxVjDvMfk8B9iVeY6ISEOb/8llrJO2z0RD/h7xnm70BYXt+rVhzY7AUeHAh/EiwsC/evG1Nbv5piTwgmXDrS7Aj/mGdHZAdw4iUHoVUjeYcdF3IaS8YlY8LgsBFOSP7dDWHPFHlMGTAwMzHOkI9iqAEUeLumNIq0u0/RixEKYQFrUxz1OAwRNYCDNbIwS/t9i9OWVfxIDgl6SkP4gMbURyge4FH8AQHZmPN6PlqEBnCshsQs/cN2mBti/ihEnRT0pygM1Z7D6Rp5AOCKE2CGOUZUJv2ucE3A/KAbjrDEBksY3GWWhJh1+VxjUfum9bt+RTRnyiCA3slcGBX1tlVRf2RmXNWZE0VQxTqxcA5FgmA0QJmGRDjmR9eHqz+ae3tHjsY6r6RiNvamnt8MRf1h+cdyX4QrGkoHURdozUksC7dtAAbrvpQTs7TpXFHSbQ5aC6ACuWgE5khKea8GYLHdopykX2KeDnuqWCYPz+CoH2oEB5XM/VJlGQQ0odoGoBSeYeghX24Ex4TE3AcxKxtx31KMRh0nUb9rbO05fJ0js7Q9FEcB1yEUh/15pqH6u0T7JqfwoEv9DZpzdy+HuiOaduMI7ocorUBZRtyYbTOdgWSTPrcGbM0ZrP5YZ8yEp9inPE0uzKdMeGDe5Dgv3r72HPZ4Nae+ySG1WLtxH7E6B07vg6u5Fh4ejB0VXXjflfXUJJfkiw3gWSksgMS0wh6cggQ9H0XNObxqRA0hz8jM4pUfjuWPdUfGfSz1oNIG9qYJ/4Jk7n2WLmGc9K7pxtSawSo/TLECVZSjYP0P/FGWUfLkBrC1ZrHFn2Ro21H8YkBRktJrb4OrNYe9zKpQQ9lM4FtB9iHMgY9Cq+aOTmFX8KUQHjEn7PVMFLVm6FspoP+LYPb6lxlENUaYcVWK7VgxSU6/E5IjFkR9eF3YWlv5kRRV004wS5+ZcEzDu8PVmMG2ixOtxfmaU2KAueT1Y7Vm8WFVDT/1gGMkz1G/TabWztWofJdfm5+VJVfMBNU1+Itanm/wk5akT61aZ5h1bx/w5rmyxB1hylps/JyS45v8z0YTlGhKkh4FW1sF3hMk13cDfFjfg6uxEzWy5VD+cERAtMGCa8jUFRl7sUa1QiB0fiRTY6xPrARTUxar3KUpw+clKhG+I9vLS/aFra0dX5UeIRLqVQE+o9yOJD0eRU0V+LBGbiPUKpePp3CAObcR9VJnqJbIme9qkJ3i5nmUSR9ZF7aWDJb6Vx9iwX2ULH4fFDW10QuceMMZ0I3BjynnPJoE/XJNOXwwRJYtpyt31jjNy4YM1ZHFhbk/coZ5tKQPrIA6Ipp9p7TlW5292ZKTZFm4LUwNWez0akrSHzlIifkTsDXk8Pnkmade6E9qydAvtWRpd2/4NcmYKd86nerHYq0HJPQD2uA3xSs7wtaOwztKH/ua544eYESEfBKK2jH4ug6nvkcbYTkVuTJ6vXqmoXohg3k3qecBEsPJjvzKDnC1QmSx46IYp0ooH6/HoagZhy9oye0Z/MKXY1DyemlB9WKs+2P2iZmnXhDlv2vB1IrFmk9xTMwyBYOjHlovKHBwSDyyL1Dw7ZyUBD0XtkaIHL6tnlP/0Lny/riQkag46m0zQfUBi7k3qOeRfRL3c8WE4CRvbAtTIw7bvJBj6qf4kkSiHIOiRgp8KvvE7TlUtna4cKKqGPTXZKk2iIYu1ZJHSpvzAOSb4pgXrAtbGxYbPCsp9TOcf0vCQQ5HUSmOOByTAwszSz/CuzvQDFbOtYZ4vXQ6UZXMkv2TBmaW9rdBrRGgiuUXYQEneWkj1AVhvWczs3S6DT2F7TciQT8IWxMOH5Mone+DQyh+ISJBLyZTD2TwG/XCfRkvAjAGCzjpgmVQjwZrPJIjS+fbMGd0YSm3YT0YTv7NsLXg8O6UWPoYxYDJMspekfEIh3wGilqwOEfLPkf2zvMuTEavNJZqgLDUPzX0O+rCGdTvQHUsEvNT82FrwGKbJZKk/ynPkfUrYY78YbgaMDhWPXPfZhffhAUipf6QDFUfmb9olD7Ov6Kgdy6H6jNY87mcWLq6yyRXYh6UMvvdYCvP0mEpSpecojMSr/8DU334jgbp9omSlsiofzZUdQZzbtEoPLjgBkSHMNZnVoepOItdXpbEgww+E2E+ELbiHJ6eelBdP4L1GcAUBqI1Ub8JVwmejBANfTAdEC0xNKDCfgL5rJiV9JoWUWVkLTb4OQFVfgmYBjX9SCx6ekPYKgAMORxw6A3q+C7gIKkRcAy/mxWc4rtRVIGYIjrVelpjDixeX3gj9iVBvwlXERghzLyeYKjc9xTHCPbz6/XWXDGLqDIMGKz/3xArOeAR9vHDWRDzM/NhJ5qIgkQ+Eg9GkVMGBmjAIndiGZU5iXzYxANEiVr8QA+U+IHeiH1WasbrWTAVQIqM+Yf2Ry6nERA0BL1uGqgSiBrMfyqFY5dH7ozlhbWqIezwQS7j0UvANeCfQTokTEhIB8BMPFMFztAlRf6xeMvaMidj7PUU2ImXJtO6TIc3F5skF1vE6++qy2KdR6U00IZi3YcXPXvmxUHvnkWmsnZe4kPcZLrwqkHZkeS5zWGpqo7U4WQFfhTxtyuOSUr+UBQVRfbHuWxYpODCy5ZAXOz1VBSoZIN5t2WfyPOtCkd0J97HGgK7zFqqJIv5L6WYDG0fnipBDIYIzwYtgXTIBr1nZZhKMjg4hZTQ9uHVpCDkxCOaM5PkjW1hq4gsTtfAfORiGWKAUZFir4fAVREsfqMhDbqsCY6MTryeAlNBZGjoFo3chAgBgQswwqTMBf2dQxVZzH8ipwbHfXg2sDzFH4qT3rU0qHrgsN8biZm1xcT7si5jLQeIUYAfRzi/sAZM9VCBT+XQmTaRd94QI+gKZV6V5a8jKexeUWfr4CQc4k6kF/PHq8gY9xv1jcwcgFlMcWVqHPTrlYSVb9LILMcGaAMWbMcQHANBNTQJ+rsqctjqeY4snfpuY1ZyCuEpFTcKdpv09ukwFXRQjKk/EkH8Ts4qgvlWPL1R5RAsjlfPfRLTqNN2vjCFtuggWKoWELmLNUjnQ3EcZS+PscIoLAj5cyhQsQZzr9fIfREjHKF+IvR6DgqqGMIqj0iSZsYwnkPS5085JfX6a7jec8hgs9c5cfOh0jsn3CZed/LO4QS9bjaZytmXo3QxDWrvZ3CEw2cU9f610XvTFsdp4M4Mk+pbgJQYnuD8EclzW8FWjMG3NUjDoQHO4+megMkb/bN8OWK5F1zFEP6vqYkAx/mg7wnYEQ3QG0T9cNUQFTdr7EAMgzLfZvmKd+vk2ZzXk2CrxWClJzW1oyKQ0PY4tg8IWAryogJ4b5YVrFuTvP7QUbVY7PaGdBInL7EVH9bjs7S9V/1GJxYE/fNsVKvBUTFKmwbK+wj2fyVy5/KgSrE4SQM3GOKuS14wBTgzBxojypNrVAtZfFuDNCz/myRetBlMpRB+q77J+J8OB9m7YjB0jYamwTZn8HZ8K6PxejRslRiscFd7gEIcIvgawAnsn5rTYKplo8c1dUJ3hFib33gszxbg82hTDAt6IahKLHZ8SWIHoHRGbc7DWD9onQbN2BHLImq9/hGmWvYejqmjZxjehYvRjA87YlDQWwxRpbxfPTcXN1T5BjCLfuyJMZx0wVxUicPntGwsqiurOMSNy5bgJOiExoAURawvrgNTIQbf0FKahYHo6zGLLnjaGCMk5de3h60Qogubh45xLsuIAn48+iNGNfPwflVCmPYH9c3DlWKHg9mGwtdBPgSJ6UNwVTLvXxoayB5F8Gz2dh5A72CMQYD6oF+slhUfajTegBnqTZS5mGDEN6tlrWckNhvxJdSQTTRhiytCoOUC2Oow2Oh14caTBuQEh4K4bFGbGJJLeoNeBksVsnXgpiPsQGV5r3ARrPwKQDNmaPd6BZkq2VmjNBu2Csj+FbQkCE40SAnoiglBrx1Clbyta5CCm3QT2lF8wRaOO9GAE6LetjRMhRzafCwiCDUAWnK5sizoA6tVypHjowWKDcaW7EzAZUnSx+bDVgbhS5q6tq3vaR6m4siKTQaRLPnvFjAV8g2NDQGgiON8eDLCAO3LfnfM4Jd3hK2Q748ftwrMsGdwai8+bHtHzhzzojdXCHBJF9QTBdiW8KHspfkVMCDFt1fKHzvzeXKfkoqzckDUgyvlmo5cB+HHmvIkr4dXB8HepKk990GoG89V4a+BDs1IqcfAVceMu3pCfl04HCVY3odLgNAO8Rmfha2OuXc3ufsVEnIxADmLdS+kR3ypOgyWvVu5FxQ4EjHAMYQPgYZyCW+x3FDO5nSY6lj1fk2N7UV4zfMMkgewliKtUKEQivO8nguqjrUe6MChwHsxwUqeY/g+TFVYbPxwj2jKqxteEB5GfhzlErRAAdsZTvswQ4p80J8aVCRZbPOocFc4DyXLU67FQXi9fFg7gnwfOszrrxyoEogsdlogqTcIB+QuVCpYZqxxZ8YcEVAZ9bKhnnNg9ye4N+weBDIAG5ANghxHewClS+iVoj9P67n0iL2eTd3gxQCeFeyiAsdxKdlpighVV8yskHe8lLgLBgVK8lrO4jQjGqXsutkVAbI49LUmAxtaiq9nEX4RB/xrbmU4vH9RbMvjAm0AbKhd0O5pjFzFDqDFOoMV0Bj1OeltS1cFHD46PD72QOGDqJGhXwYWeEgaj6AHp921bIUcWfYKrQ0UE3tV6ULWHTri2ZPD7l++Qj7mewYoxAHplcxmaPZ5E09owpwNrA+uUCHHxubkNGSdHsPEB/sWx3hCN074d12Rk0oLtKdWzvEg9T5M2xsbOx5asTIsPhHGhTczWkHJelJhNq+Y6nq3bjPLoV1urEylajnCjwcv1yjc1V6IGRLRdUfa6MOaZ0Qq5kNlGth4dpgZmkzSlT3G/l0lH1jSANQ+m+/jtQyOMGDOhQuDDD2wQoW8r6n4kxgeoSu7AbO5b/m+w5R6Hz+M9StgwDoJK3e/qULe2wEHdqInMXWWTnCct+Ywj6h3Llsh714Ux8MceCH7zM96Lfqih33SW5eukEPfSO2Rih/EymePvDZtAXSwzTnpTfMqZP+XO+HAN7w9Is5ipoXIy3dqg/UVtQftiWUD1ag3zq2QfTrjwDMbvJKlpCMuzNkZAD3QRDknvXZOZRjs8xJ3xB/RwJrrMWM/yBmxH+Qw6pWzq4Is9n5xvDyyUQzYPMBKhhmy/yGNeGCHTPvbzL5oPcITOMehbzC4/59eIW99TsbL7qbez1E8lNOxBf1dq0J2fiZ3gcDUFm6gOP5u1OxLhNdLLCqSLLZ9WrtwGpM2eIcD+5BwLgRVx6ZPDsa8LFmdXxmwWPfRXoPEgAnny3gvjmxMQKnfgKkKg5Ufqj2Aq7kiQeMXQsM6BbY65t3bc973dkGZAeOgjnvRYSJfrA7C9Fs11RpPoQfY0D5LKbPiaxiBqWOrxF2vcbzMcBWKHTxXdDubZRHlq6g5F7Y5zOsRFUJ0ZQ/4O7hk4C2seP0siHPI76oOEP6/xzQ5VWSpERVw5wkwCK5lSw5Ift9K+XnveOOCjaxVNx6+o8SVWxRQtjchmCSv7VopZ/aC9xIX3pF2Uy48nAgVLlgh+Z9In9kCpjIMvtwFAwLe+v/XI+tUyid64+aAtxxiyJeRa7GOgWTUu1eslPd1QzE7cnuX4ocN3IG1sdw4E1QhB2jqgkoXZYqx4agwTG3xijTkqKB/J1MlbxbuBxi5OZpnjLVDK+gBmcDabjvIer0Urkq288zcGQdDgP2dWE8xl6DfhUOFbPSGdEezTvA6ROeYspFgF3FQcFq1rPV8TtLH6MaXQ1BNWE5akXWKttzQF/XTKKpk5Ue0z1HvxCC2D8E+mqXCxsiQT/EDsNVBWOZmjf2AVW7vQspuEkvACp4yUUTKycji/aplxp809AiJGbwLKGdV8rsCxkAh62vbwVQHYC/pkocsawB8F3fJdxPsGVeGqUz64pqVQviu+h6wD9ZVAHWW+A52cz27ZoKPp+aCKsTiDC17RgGqiB5z05Ajb4d9L2xRJek9lqrE4ZPqG4RFJF/PnUN/N59JrwShUt6ZEnfBL8OVYwNAg4EpJij6RbVY7PRijjwuHFYkXWZEbMA9QAPphuUoQTFJapOeC1Mt6/1HQ2dWacYJtPlsRe/hHBMtO75aDJa5pbfYMoRAjIgqRRReQDDTsg9VC5G7XD0zd89AqHLlfVhGnmTAJ88IpV0q2GOuZW+tGItLtBxgsCMRRp7CigXIIfpLcB7eqFpg8U31TcIctdLAzjsIrqBKZs+ww7CSPrQCqGI+LeX42I0zlin2KssLgESv4BSnQQKWRP3jDFSrxbuWhDQ+6zZ4GqU9QOV5SLyE+VPKfZ9lI0iFFV7PJKoWg51e5SYHKsqNIPYQ9d3oBphzLGzVrP6U9oQ2IeCwyeN0VJhiGjX8E4izmA+BqxbCjLs09IZNpE/yPOQYw3kARDvMcAbAgmJ3WiYLd4KtGKK/juBeaPoKPI9wgVkOJZgZanmIE1hL1TiiPL5h1YDwk1G478AEzFMCooEYgwgoCbuhqM0j6J2rwVSMwenqR3BTe3Sae/bjkDCLZoYyA/K0aBZtfeiiOgAv6fUfc0GV8xGNTWj9PtEsmkEGO5bEGCOsDV9I0G/IVs/uMY1ydehRniQEYyQsWoymdeHriKPXM+FQsYS1n5XYF3GEWYxmBqDpBU+wGGNErAitC+ptUmTgY1BUz7zbNDQnRYdQwRlmBgj0L+QqDsWiAHZ0LywzARWaLTwAtmpAQ79W3x8xi5gNILwyGxhqOUFUKRNwT5GNhqZnNoGpGrI4Q8tRrv/dzQ3eeJhFzBjq305ZTgAtEWGmWQrt1RSlMd03m6hq4PBR9f0JBUzyITAzY5w8WDRrj6P4VlfAoILeGkLsT1gQT9BDzKxeNLPGuIzNmrPAY/p+FVls9l9ODUpU5yD5SHfEGK2wEWZQTRlkpumUUVAadFwVGax+r4YR2iJ7HLBgEJhVMKJ5NOZl/EPoz8KBVUSYcbX69nTDQUi50ILKqNpGr8VrPG8kFP17yyqCxU90uMGQdz+iuYHgmBkGokAjFqGaWRDjVT4jHGnNYrbNkGRmffQPCxU4WcvBBSNmgHJdPsCimYkaTiwyx5kaCbmgV/+W+nCIjcxbEZ5gtIaZGVTxGLddhvSTo5LBLq9IbE9bTe+gFWYDmBoiGEE3FzVczEHCXr/EQWHCCo/pxGAoLF0Jw4zRGjaiil5P02FOXg8uZXBTR9oydjDBiIOwsWJgtTjLm7kzS5o58uvb82kEg0s0TIgmEyZHCRgF7GYNZlMIshgOKHJqyiAJ4JW/3XhnBByQQr5vrVIOJ2iUxmLANKNt5lkDGGZMCpFnI8p0dsQs+Sjqc17/NhsrWRzUmfaGzWwrJMyylAECzFgD8yl/E3tjrz/F0WrjYWbWVtEqrkGwSBjZ2kztplKpJ+KHyoRlH9bEbBcX5ufYS7hGmCGNSWJCQsbo4syTjyz491TX0F80NJrqlwDMqmGrAyq/Ab+8C45OIJytwwlyfAszuYM+DQAhQCiHEWVxnEIJElfUh1aGpSw+qiUDe8WjkMiUxBRiKFR4CBPjMRP0ckO9dvcxZfm8ZKUeJjKFUCbSAC3HH+fbMJQ2WG9BDu3EOKh3hKZApYAQK8DMsGI+uroIc67TsgkQEEjA+1iVKSiCf6RHOQzGoQOmcbljhTlcMH6g1AOwRFRwiQMnSKCBGj1A9TCADpiV5JlVqgsFPsmlZXhFHpiGZjyQIQIE68XYQRZwO4Am6hz12hmgWhZ7vhTifGqJFi4YkjJJoGbnqXgO5buxDBSvPyBCazJY/SEJs7hibC3/DXDQ42ArjNzV2rego0m+g+Ly90i8T4UBFhfoYSZXVmzBgO+0nUKbMS9YB6ayCBZfiLNtS7bgxm+EZw6bsxb0rzNAlQVYvO2N0ASHxbgUIFj4JUyo6cNAr2fBVRlhpUctbhSUR7O8BQs6XcaMc7WRFeb4HhSotGlX0YR2hNALZ09bMs04OegLW8JWGQx9w8OGsVXOdjoPO5wlKSS9ew5MpTkcTK9topiT0/EwBQsSQ9RfwaHSLbb4PWwMdr8KnMHRnjqOBxXdNE/tpKozWOYLKW4KnjejipM9FOWwGEsc94OtNrLmdSlMSLtAljWAAAWc7MEdfijK+uJqoIor8BlNkseQcXAC7D8C9e6oKmZaSnrP9KpDgX0WS5/hglG0i73sCwZbinoRESreYf7jyg2Cp9yOYYIVryaKwX0CtuoMzbilR2zijisW1Jil2TriDSg3ydZgKTOn3asPDhdr6g035rvZ7zjCSvAwWmMERD3pw2vAVF6Br2iS3hAEE76H5THG0WqYuIJeNkRUeRb7JOmVnDP0Oc+TGEI9Fw69fgMFKt9gzeeUx5L+iPM8h9+FY/4gXPURZtyoqd/itRiBnKaUn9sWtvpgcL7GNkQ2BBXEPGs9hENj4TDqnXNANWBxWAd2BEoiewe+AEBXHPU3sKiFTV7KqS22hCtrvABO5Hosu0r5S3B1QJh7vYYO7MeHapkOozwBcAX/5V6oM+clO8DUASzOV88dSE9f1jmKQZS4H51FfXQuqBYKfJSjdJya5+UsAHaKf09BLyWDWjRY/8mcaofrsF6oqfWicQwyhHWBX4Y56LGw9UBEf9fY9Niv8JkjAsozwBB6fTtbUWFKfse6gMPX6oibYTADEVbsHIE4jgXSg32okEP+90owNWGxX2CuHW8WzhHZz6Hfot8vzXIAs9efWoOaJKzyuKb6wIfXYggHMNAPYFM84pMo6gJU/FljfQjezPQAo9/k7lFe2wWuNiy+okG4NlS8lswjAKDitxB82zES9MbZRFQfu/uYpE4uvLEw5ZPkDvFhAHYUqin45b4Lh9o0WOnfGriCoBtrYz6p20fYmXD/GwFdzP6ddQLjLtFSmKuF5z/ExYzYE45AidEORwEp9zz978qgGmnh4+p5QEGT/n5w1KuNQY067PyqpDoDv4V/LEFPR60Qzb1ZQ8WwTcCdRbRVVpklBST1nJj3hK0TtPDtmrORHZxjxio4yyynCoJgVpagoqiPrAJTKwW9N3FbXgQOA3iwvARlhjyEehVF5F7wjrXqyoRU4PWn1qBWCWs+pTXAPLZSgFRQ5YoukHMcsEQvwlb2b1ivi3BB0CPg6gXG/EFjVWWLyjmP8BxnFYGlgOoBTJAfHKV2g1RpNpq2/NI2sPVCFp/XwFwHRtkGGcpoMvN8eEBnQpzgEQTgbu6uzKg3ziZTLzDYcTGnemASA9i4EDkBUXkBlMFNlC9YX03unnUmCtQrGZrzD/U1wRVIsSrfIEWFNpldgLTRbJXDUIIqN1oqF/mD4GoG5HCSlnUBZFiR4h5uQHknpL1AF8UNxZez9OjyRHUDh93fSLE+SKwBEjZQJJdxiqvbyooaPkVMv4JF7Rpa+l8auD5AkG2AGONwAKLX8U5r/D6WjqojcvhO9lIn8ToHcDPmeCGbPwX618Yw9QOHD/rI9SYYprKOQTxs48GbWQ2HcCHPsPTV2aAaMlj/cU5jSOAo40gDKklF4imeG7cLoxXNGY7XCkqYrBl6yI9QZkivMAZ1bMyVOY6l9BYrJmaIR8TXsUJcPqwB5BDnUDpA0y70EBS1ZPFlTTyW0ixkoBXQx3GcoNqUDrDjLJgFTcp1Sz+6hK0lg63fYGm3kNW0C2oP2Y3APZjaZcANCDGmUSooykXcY/rgqaVaIsy5MccmYRt4BsuYB3GKCSN7wftwCQoud/S4roV6tjhFGwXHsKOGG2yVQ2Rt9GEIlK0ot5TnPdyVfnfZmZpy2HORcP9uaY7xgg8LCKzRwEiXw3wAAQ34BLGXpfsI6RPdGWraYNmbND0o7yTfTFFn7QtUxJVYoqbUw8TZO3eXKz3x5kKBsyuEwd7FHYM4TqXZSSqtPiscZMX0gEiWvHgDmLIOh5a5HZlIjK6jXdjFp3AZZ7hzhWMsMj5EwEtIliyS9PqZqG/Cak8p1w/nrLHINna8j9pjTq3hANR75Cw56gmw9QWDPytL7pOAB3dgnHVU+oxZgTNcHkYks5S7wNWYxWdVchsiE4bZUkLEZwO1igJ2XdA1bfvV3iABAUs0QoVkLXF/FPGoNy1NVGMGW5RZ2p4gzM8gcY+Al3CI0bIolTkGuLwQ6ajfRoEaJ8y8XrktqTBDRChs4k+ed3NPs3UEQHnQwI45zzquwLk8pN5gcZKm3JZUmhXUWeCiqMYMVjeZAVEQcdnAhhBlJq9BIeujy5OpuV1fz9yeLGCKppDajbmn2B/dXYACBgtsIeXD9L2SXowCtW5o1hUaa4OMNFlS9Vl0x3klJwAiLKiMAbZZmNNLSNoXrt7g8OnE9ZAUpXyIa3BlPM5pqHQ7YekWXRhw5UqyueKFUfQKrHfPA9WcpdUWaGLmCcJvur6DgFgYdF9z1JuOiLHKTe/DBFYiyzlRT4BFvRMKXDAKTwgCEGu7s2BvzBomOGU7hvMrW8PVHTnsE7jJVVe0gmqRnAg+giheonpHVNTLZxqqOxAtfa/EieJvOEc/FSKOySOIhXiIBVSogPUVJ6CF2oPDN9UzM08E+rLvLgjIDKqIwcJTADLVo1hf2Ba29sRhz+HEqQ3JDRYI+N2cJKTOMWAVomRAkPV1kt4wzRLVHGpp2X9q4J7i7IAKbtyyY+mzwIHc2o69ygpX5rANMZoCAXnGyMqE8VJmPQkFal8xhFM01ggxS+ILP4NO24opepCMOWTpm7C+ujls/SEKbP+SppoK7hzhJUTHgQOQFQZKOyRFZ4gbWUl6RYvQBIms+5smlt7haDG5cpBTm1x5gIp9jLCDpTe4YoGTfgquEQAFjlJmHktSwTy76DuI63sRK64jC3cpP79xUyCDFRZo6iEPwSjLE5zbY/gAZzDAJMAJU+jgLkF/1bLUDACLszUy9454glGWyr7NlZPn6DzG4BDKI3wBTnIkWmiKDjsvTqkN844zTqFch0l6KbpfgZtEfWglMo2BaNZf1Utlmf+F+j+Tq6QXoUBzLHBsDtyGatjmw4lwhM7yMvTRXaB6EVacw16wDcLS/MdzakcmK0/QGQzhLG55Ly/jKuXbpxGapMPPtUbsoG7mFCtfi84NgxRceRMX+iUUjcJi72FpP7lgCTICpAZAQPoPEbmoIt2DkEX0Hoia8qubwjYKmOn/0tRDnEadQyhyMzPlBJW7yEWWF+KpGvWnzlGzKHCssuQqoipukHwFyxJGMc/Xcd0HNV6BHcwfxBCapcX85zNLr/BzxowwgW0B40e5Ps2Iy50VysqEllDyvEfSh1Yh0zDIup9rqA8jxidBggMTznCUphQxQovRAVvv2wbrd1Ggabbw/iRtZ1cRMYTqQp0Ah5Gww+AgE6oYXchasMVYsbeTPLwr2cZhzUr/1tSOPJSlWYAAMoMN3MA6gwxVkfijcoMrXag47dIydtJ/FITmWeA7ym2plp5WraOeJZ6AxK1FAUWxHBXbvPYYnPRdcA3EYduFym2ZEFPSYXoLJ/BApQP19WJ+YAUyzYPIuL8r594AxcvpS6kXcIaIKB3rNm4X9FQq0EQd3qNJOhxeI9qPFZSLasOzxsNUGYGiC/gwMb+wLVwjMfSm2zT00jaxYJNdOAC4DoKMQJX1hwn6f+SokaDApzVxJOIzqxTpGPddkNOzeCEuxhLfC4dm6mjNhzVej8yVpxzNM6CsEAnkA27M9gEdcAKoNkm8xzaQ7YWS3j7ToKm2cKamV9Z7ACEeLHPUOUJ7vAK2kO1hstyGWT8D11gstngxf2VjlitWgB174uIEnwlSih+BWVRwVsrPrkOmsaCgH+vndeUyidDC2pUIyraKvfUp123y9AqUCDhk/D1kZNTznUNzddjudV+usuQAmQNVZqihQFdWiV32kL0YcBLn13ZB0WDIDV38/X49G+C5ueOeE1C2Afu2qBAi6xx5BoirzIKMCeoYbxjlCCNkZNTfDRXUYNDC3os4MbdllODCMpPsu5DKGqKuWZqOsVL7kuS2E4KR9QQfTiIky2lUOS95J1qgxoyd+VcNzFxRRItciBqxxRzRmANYpgWWQUaHDI+AD85Jet0MS2i0LRweOdWY4HonS6sjnGeSpG2UMQ1APEUBHE6Vk34CBajJkDVzb9NYIcKDZcj6HWvVBbSZY4An0QMuj2ODg0yPo5zyo6vCoNESCnxGY5QqQSneUcI94IOlQJMVDPCgeAkLjzsxV4iaoB70RCqo2YAMrfGIhPYMOuQZcCUoRqkIK1Qw2OXOBAiSfhM1xftBVJRnNyGHencO1KKT1KdecCEuma04EWcugBUDjSesoXz3jDFJvA7LYQ6jfp9aaL4FNno8x57wwQniVTO+gzs6YzoMDuIenJ/fCq4BUYHzNHJPuODtzDjMe3kYHGMzk5L+HA5N2NF2z+UkXF3cRhP6HtyK5ctlyUt2gm1ABDjzY03SdnvpT2KZBWwXB15Dov62sNSAQHDYbaFwbSHPHVMg4vXctgizDBKVsV6IJe6PAo2YyLYu09hrOoqe9YZ9F8bsWQbKIacV1WJlZJlixeEeTj3pX2dbakagFt5eCrcjRu/A/kG4i2nAAY5hBFzIq3A8HC00JTJzLtfUBJzjq3gJEhwnXoX1zmUMNSWghY+kzHmsO0rnwASUOVyn+IPoxrtkEfksHJoz2dm3aZI2q2lKKz4bKLPMNg+vZp8hdnb5ZKZY350vbaf8nxWIGhQKHJGlJ2ox/BYmYSw6gZEWPrygtJs56Sko0KTJzr1FU855NKmp5AF6xvGdyCmoZgCFBcxhomCahReU9lJ+ej65RoUWPigs7UhLEbSGNpCDtM0D2YfWBdmVF8BKwC0HSftZkn6dWmjW1ixzvcYKQMpt87nzwC5/BoGNyCHSCef/bkauYaHAB6LIxJMTRDDmkS2eOUCbPM/iisoFsrB+BwWoYZGb8TeN0vZytIaO6MpDD2Mf0C7VJltmlnk8nab89Ppk0Lgddns9cyVUOxUv5CnU+XDhzbw1WU56Mgo0cEff08gNwGMsEYcSDWx71Dmy8N/xLaI+sIqxTcxisxckVpRRoMeTzDk4RGpiGVGRtcs+L06WEx+DAk2cnPm2Bl4YxWb4NSwi6jMTDnrnimQaGRy2fUECLIlSMTng5Ncy5j5gMszHokBDd3Sh+mVZE0ee1zLhi1hCi12+Bge9bWlDTc1i6xclaroxkBLTXM6Is0MeSdQTNON7pKgfg0Vjd3Se9rYIFJApnkuf14IQwGka8IkB707S6x1vMqa5WWzwmIdllFt42MSd8/sQHmyPW4J7QMTbJ1JMR6NAc6cCJ2jgCcDSCm7EnOKpAxxhl3+J4v0Pov5rWWsaHCytfrfGCYOvYP5osP6xLGFv+N+zH5b4ITg0+gLHRubRpIdcSKGVvyZ3L5KgwtPoJumVMyw1JjPGzvuXxorzxwsDp6DIU5U/aLHE7N+OAg2/hfdn4dGkh55j8k+gCJZWjjujHPWyWZaanrWzrtYwhvSWFPqbboI2nrmACFgW7okWGv8Q3umF84TwV6PBo30ESX/XKqj5WTvnSo1Z8ggZiDjIIFgX7gmHxk8ocGgpkkeTnuIPwgOTSPpLWDRjRwByxR80jSWO0hiSvLYlXEMad9j65ZykzWYRuBYggsZoMRY9zzjqD6gwZ2jiNizklZ4tLJWlkyi7DyDqI2uRQ5/oaJX7NLZDCKUey/MQ+o5mq3oEu85XnPQ4tNA3DuGjibnX9CKcRxkX8QRzSHrjHEP9A9lpf9VYefSDp59AHD5YhveGQx9ZYMdXJbaDJZ7KtZSbGKGOUIL+AAX6SWrRuRq5PQEmPPgsfXjpzHNlOekUoj65Mbm+AoVZ7UENwj12zdME+9APxszHo0BfSdTC0YlTe6oQbEPe8t4rkzgIIkh601xn+guA3Kyr1NcRg3zt5jWtFdBeZg7vgkPf6bDnQo71g22woyFvQHcS9TfTLPUf5Og76rluSCYIbuxIL/CsnOTF7VGgD3W04aMaegcUzqIwRg5a4vNFPc846kdQ4DhO6cns9hiKA+RojAl8lqQPr08WjdjljF3qWo3x3EREJf8QW/IBNUSAJoUAaS8dhwJ9qsN+C+UqwloMgUCZPbGdwMLX8yDqrcsZ6leoKH6kH1ctNVe5a3mWn4PT8H5w6FsLbLDg/ihFTME6erMdEPH5F+TnOYZI1O8WjvoXFDjm+/OK8TRXPh/iswoFaMxKErJW+Ru33BxEvW91WPSxxk7/5fuzEhu3lAv2xNOJG6RLIWEOh6FAX1vgx998uiLUh8cCioVVy5YEHFV9V6GWvV5AjvobFD/8/P3+5Yo5vYZOmwZvoGTU/6xHDn2l78jY5W/Skmuh+IN4Bx7cz7M4hSPRov4iWmC/11MUZhGRRkFX3EGKd/NBHjXqX+ZYg/63sN/XwDKK1A69TXmHotfXMOec8su7oUAfbLH2wxpYxmyEb1LPIfaQR+g3qUX9EFo4PKQ41vM+JAAUUHsIgnWAqXbgEsk56p3LGwvqh0xhf6ye24PL5EHw4ccAilw4zh4HLMOHYYjQHxe0/kMa2sL7Ae5n0QRqNZ/LJeeo30OL0C+38CEfY1v0wAn0sL6tA/BeXCvnoHevaiz6ZircJeo5S25jeS1W+wbOAEosNyQXCVBCUpnH9lIpDR+AAn10gfUf0dgF0qCFwlVWMkmtwILwTSSNSdDvmBb1U2jhA8PMOefaMPy5Ol2WQJL30OhI0jtXMRZ9tSlaP9WYs9QCg6ix37Ets0IEMuRts3Z+Dc9AFh2AAn22xToPa8o524Aex4OiSu2aZYhK9VOY/tC1QH0WWjhCEkuDISz1C8GO23ihmO5dhRz6bnKtX2nIUvPSxOi1SOvDEguYqVo10WaYJpf696BAH15go0c1ZS14LSJModVPRQfPOZqw9AbjqBfcDrTwkZBY2q0/B1kE99LbsGFa1DtXMRZ9OVn3M/WVh4wQk+cwTAWKnCajJ1m0Lwr06Y7WfVh91ckMXuqO8Ut4/SZaGHd3BS0csDDGWqHcOWITs4T6BYJe/SZrx29jC5yYPTNXGfuFRVbWASkNWcx+nnuOLhsto8b89BZw6OOtnf0n9ZVGyhoq7LNGajjGIoefJ6NyCB9Ggb6+wEaPZJ+45qztE8FnwOrPJ6N7/X5RUF9H1MLh3sdGogP2G4uJOswsstfbVyaHPt8U9ke6pA48Qe2J/kSJX9kbDn2/pVVv0jJXm2CLw/xgXIBT0BNQUP+HAnu8nIJIrnIAoYxDgBRdFgaqRwkCnCSlXjbDGgwAqcBnOLBIdbF4Ko1FNpGihHO8SPQEllEfXB8OA0Fjp12kIVf6rn2GMVJUaINY9QZwSOKFB6GFAaHD2g/mlLPkLKLyNubN1GQYoOTs9VtwNCiAxbtK5pxl1PT2EeIGrpzmq+8DQs5B71rTWAwMyZlvacjShOzit2CV0sJ9UGCAaM2brlWfeRSpICM+2ziJEgFrw5FRs0iQ4+FokACLDe7XIDyKSIX5ZJIpdozqfcvqN5E2vV403RoMFlvY9VkJzDyKVAAgAVeuQfUGXuGZiLRZ6vUrwWLQWODIGCIzjyITjmVEQ0ummDGxPU898UP4vGAzFBg4mqK4UIfbkOpRjIJjjBmzxINv58ZhOaXX34kCA0hHq92mZRsysShAYsqd/DGYg56OggYRaGHPV1NgHkOqBozSIjJBQG5C2RttHSZer55nDAaRRA5fymWUNicO+x0qRmn0iRNYXsotsl/xGjJmyE9tD4tBhR36iS5hHksmChWITLA25NuEL+FUGTOl8BEUGFASnFn+Wi1zG1IhIOwodw8RBvAaHO80DnqOtTSoAKHA1k/mkHksmWgsWBvti4cs4S1QTnfwGKX+eSljMLggFDhsOEZpez2DPMOYV+N0B8voQe/bAAUGmuTwFfFcIUQjFFtepb8KY0Z+8S1ogQYasHb6b9Xn3IYF6i5s+BTLN55+xlWdyzZzSh9DiwgDTot179c44TzBN0BmXNgDJOh51DKDDxR42xsptiPMLOc4xYE8q+BqnuD1imWswwCEHP5HPbejRjBZYD1nd9dYmq5+gteHNkKLaAACa2deqmWdOPAl1A+QR+Qor+yDITIDEVha/Vb17agN6aKmO2fej0Oc4rwYw1EYImMwCCEU2PRhHRbusSSFHgKW88YlGyhU7HOJD9Ey5wt7/botDIgIg9EWdnxCfa6WZUF8KWtL1CHRSTRlrxdNKxyICINRomk44DX2zKOpNaTYUuflmOQ4B9GiUf+5EhWgwQnItHDEcArCE4By/90ADHZYSanzNegTW6AFwuCUiGwLJ6iPMqrfLPfu0DLLrC3xwKivHYQWBi1knft69okH2geKjrPIi0V9/f0oDAgDVQJZ0zpfwyjuGrZBuRmCjVNspNByFgC5mF88BI5AGKgSCGTNtJ+qH2QuyIhrjNlbYPeDTJRXD0GLMJh1WO5qDclzpKXYLPtpurDOYTazD4iwz59CQRjUOmzxpMw9Sx+I6DzfiNEkiwS9oGUIg1uLD0Rwz3rOs9uTSjcOzNhMfETOudRrliaDAS45PC8Fyuiwhra4gg9HJhwnEvSJLVFgoGvtLV6XDC+CYWaneBWKcuRFh8JhwGvt7F+q5wlmv3iZmWQ7RkqnOefE4WNwGPhaLPtH9cwdaduosVCdohyHggY+hIJW/oeW0rh8GFOK+WQ4g0FwgTVv1lK4EzVgc90yxpqU9OvOGQyCCQU2vlNLZu5AtdxZYUCOoTQFPYucxaC4wMZ3q5deq34KVqSo57aMxeDYYcM7tGTuQFIdXVlgQGjC5g446jlD1mCQXGCze9RLd0dUsMaE9JBU6netMRgoUwvbPaahO8aeo1oOym2Veukc4zBoLrDXyxK7ZNRxLQFnjlHqjSvCYuBMBQ4PnLriPgqdkrOIZK8PbwyHATQ5HC+RvSUrTGp0zC/tjgIDaeOGvq0RXwijYX1AyK/sD0eDKRiadYn2VLBxqK4Yl/T1d6AgDKotlv11ihwfOCToawegRRhcO1r6vSmaaMXpeOXwmF85AAVhkF1g5oXqIzO3Z9zpPJUzgr6yPwrCYLtAcY6GJB2P68aZiM8TJOpLe6PAwNva4nT2UbhnJsuDgKODPrI7LAbgxtJJsUzS8Y7LOFu83rUlHAbixuArHNNgYXrQBzdHgQG5searGlMnDirpE9vBYWBuTPEtDTyoSfrCHnAYoBtMu1CD5IFMysMHwmGgbs2cizRyew4pyvAHYGmwBkszfq4hteeIkg5/EI4waLeYdaGG1J6DERkt6aLD4AiDd2emn68cXU8OJo8a9Zm94AiDeGuKU5U/XU8ORWS0qA/tAGcwmCeDT/jr0/XkVLJIlqA3bYyCQIM5kMFhf95v1/XkoxARTvq7FeEwwCeHn369310nI6OnqN+eDouBPhXY9VH1MujIOQX9BsFiwE8WW/9bfTuakKSjgIhkyRz0DJDF4N9hq4e1bCf7KJCzZOGkp5AxmAx02PYR9XlwkXNKeiKMweSgw7aPaRhAyBhR/BdABpOE5LDJHep5YCBtjpCgrx8OazBpSAXWvFaHua/gIOmk1MffBkeYRKQWVrpMQ+wruINI0Js3hsMkY4HZ5yp74eXpwnOkvZT0LyvAYZKRyIKOeFnLDqYjgS7ObS+onD0dDpOQ1mL3e7SsY6PUoz5/OGAxKUkWa/xJD3UQxHIbw3rv1iDCZKXDvF+ma9sVjLOQS71/AzhMYjrMelM6II4BQR/ZHA6Tmha3enUKQVCm6QM37PWuzWEwyWm68xe6eglYgtmhbGPS/1sNFpOehnDEy1pyYuaJkLm0OZZn/9VpcJgENQa73KfDozC3o11CLZf63PsASzQJAnJY+286HISZpf2dlKPXu3eFI8IkaYG553PwPPrOyjHq79dGYQiTpg507CIeZk7tSXso5HDGLFgiAk2WwBgc8JQOJ06MTki7gtJSnzoMMJhkNRZb3qBlELPdQiWXeufWMAaTruSw/A9CLMeY0mhS0j+sBkuYjDWwRz2br6IZwBT8O2RDpc9y7kwYTNIawi63pP8FrACYSakvfgSwmLQli9Xe66HHgAWEm0te79oJZDCZa3DrZ19zBag4PPI+6aWrwBpM7tque9jv0pWpAsmR9zp84jQ4okkenJ519/lmOhhFQG6kU9D/7A84ECZ9T866O73LQ/A63AmpyYegl60DQ5gcPutu+Yy/pwNe9JxAqeG0mbCEyWIL7HOn+tgVuRFgI8nrk+8GLIEmi0AGq/5Y2fOoHXAfbicdetY/bwYymFQmC/vJ59RHSZ3BZbid2mWJpb56/Aw4TDpbwlZ/11QKM3cE92EFXEe5LGXSK3cELCahjcGcE1/XJakr6xsQ3EFS5rhEXzxhKVjC5LQF9rxFlwThbnEVlG0q5fig1+0GWExaG4OVL4w8LN2/SjlnKUv+dwVYg0lssig+8qSWLJK7w2ncb1QkJ69PvAuwmOQ2BltcqTFmqSLqk4lIiHrVlrAGk97GYdlzQvZZclc4isvJNZYl6PB5S8MRJsMt8IEFGlKdWK/RsRj17ncDjjA5bgw2/7OmUnLTknuS1/CdleEMJs3JYdbJL6tPuQs0lyzqf95l4Qwm0y2w0+WafeqCljRJSOkX68BYwuQ6Gcz69NOaAv9SLKJ3qXID6TePG4IjTLqTAza7qNT/obIVmfSpf+e9O1hMyhuD4rAHNXAXRJqDtBmDPvR+C2cwWW8M5v9JY8hdEGka7LP+dm0Yg0l8KjD3u1HLJFxtnpeCvvrFGXCEyX0Hd9QjGqMIdyI9Z07deBx71b/vDHKY9DcG6/44aJmEOxHpNQEVLysiIerTx82BNZgCSA7unbcoe84T7dLCXuX32wAFpgg6ixW/+rKGKMzjxLOYxKSPf2YGnMGUQXLAm69UKVk67IR1LQ4afrwxjCOaOgAYhzmfe0ZDzO2JtEGxkEpQvemwAoXBFENywFa/ClqmDmQU6skxy1gx6cunrQDrMAXROEz74L2aPQu30818LBeUU1T501sAR5ia6CzWOucFTUEaAPust394BqzBlEVTALv+MWlIuZ4oxqgvnbYK4AhTGZ3D7I/fr1JyLamLFFT/ujNgCVMcqTBY57yFGoLkumIv+uAxS8EZTIE0LZi9/srqJdeCbSEGfeMHG4AcYWqktZh75AOao+RcZdLhGBxUr9/XoiBMmaTCYJ1zXtYYc64o6eYIiawvnbw0rMWUSlMAe/xJNCStIuluzjklLS/dAVQQplpah1kfv1/Vcw/xHCBdT1H1hkNmwBlMxXQWa/7viyqee4TwtCySOWR97HNLwzjQlAyYAtjtsmGNSXIP4ElZouir398UaBnQFA3AFph2yHVZQxLm7sgprqKaI+uiX+5EKAymdlqDeR+/Q9Un4dFUUH/DguYQNV2+7zQ4iymfVBBWO/UpZZ9YuCMtnyUF1Vs/OAvWEaaCmgLY6ieva/SJuQOtYPKiC45fGcYRpopah6F9/xzV+xGa0vJTGfSNCzcEWgZTSQuHmUfcpFpG1iHnLCIpKl++v0HLYoopOYOVPv+YasQnteicc4qqNx8xD64gTD2lFjD/6wuSgpaWR0pQffgLy4MKwtRU0wI2euV/krGsnHOWKPrqOWsDhcFUFcAVOH3QZ1Myc3dfjiRW/4fdgMJgaqu1mHfkg6opygTJWVJSvu6wmSgsprxSQVjjawtUY5oYwlH1xqPmwBaYEksFsOEpj6lK4t6LSfX+Y5aFdQZTZU0BrPPl+7PGwMIje4RDVF1w0hpAQZhKawtgxU/fqurjKNwDLNGr/udrqwMtg6m2tgBW+MJ/NPswgnmcmKNXfeqr8wFnMBXXOGC9M59XKeMIHp/osz531saAM5iqaxxou0te0+TT+HD0rK//bCtCYTGV1zhgr99HjTGOQwyiS369F6FlMdXXOsw49B9RxTNzV1IQXfT7PVtwDjTlB3AGc959hdcYuxJZF/9+r+kgBxCmAlMBzHzvjaoxdZKiaPrjOxysI0wdJkdY7pMPqabEeQxOUdT//cAZsBZTjKkgrHrm06oxMYsIp5A0XrH/LJgCU5CNA+af+bgqxyQcWeWq97ZgCsLUZHLAhl+6S1R81nj1e+bAOsLUZdsClv/wPxbp6385cC6owBRn54CZ77/oXQQUBlOfyQGAsYSp0eSsJQykAVZQOCC8OQEAcFEDnQEqrAKEAz4xGIlDoiGhIydyqqBgBglN34VjZf9uJVZxzdGh/aaEf4z/AfuJ4V2g+3f3j9kP8L/6P9D8wNZ/rX9v/xv9z/vX/E/yXyJ/2/+G/Iz0z6p/335o/5j4CPH/0f/Ff4L/R/6z+0////x/dP/K/8b/IfuZ8kP0b/z/9B+5H0A/x3+ef3v+9f4T/b/3j///+H6qP/D/ufcr+6P/e9gP9Z/t//F/wn76fL1/l/+L/r/3w+Un9m/0n+1/wf+z/8P0Bfzj+q/7r87f9t86HsWf6P/nf+L3DP5//gf+f+dfy9f7r/z/5v/c//7/r/Z9/UP9D/3/89/qv/3/1vsT/nX9w/6v7Nf/r/mfQB/5f//7AH/J///sAfv/3hH7WemT4r/If4L+3/5P/U/4L1Z/GvrX7l/gP8x/lf7j/7f918p3+v2Cf5z/2/7X1O/jf28/Hf2v/Nf7n/G/uR9yf7//q/mh6A/ND/R/y/7lfAR+L/y3+//339sv7x+4f2cfd/tf/kfEw4T/if9P/O/tl8AvvH9I/0H99/zH/H/wP73/P787/yP8t6ufZX/efnX/pfsB/pH9O/0/92/yP/W/xv///6/xif9fxp/wf/e/bf4BP5j/aP+J/hv9V/4/8z/////+Nn9H/2f81/sv/x/rv//8D/zv/K/9j/O/6j9o/sP/lH9W/2n9+/zP/j/zf///9v3m//T3Vfuh/3fz////2p/r//1/zSMWvJiWcfGB215MSzj4wO2vJiWce2CNGgKoDtrwofU4RK7EP/ZU4WVJiWcfF1Qj4wO2vJQrAyj080CissqKtDkX9dkmIr4rbrcCbLEt0aaNHKXONK1LtaiLKje51ZbkX9cVC2kh4Y/2An0kT9/QbrQwevv5XyMgO2tQ8F1FljVCUoLXRFnl3PoRJtbYppHxuuTkPmzd15KE4FbqHP7mL11lqXOjY+6sLGDtptSUxMDMymPC6C1r31/B90lIgVDAJoV7FipiggwdKTb/rJu/3FZLR8vo8m8YQ3IUpIg4QWDbTdvCRBD6fgTr/BefSd+aM5fnyrDe70n/12CkM1Gf/sVw9XqiYQgG2PJM7J1y47wdsbagFaxd3BAaPeMEi8mF7uTEGOqubrAuNejcrLt8mzcstVfkfVvJnlwFa1s17k7HsUrbEt4FlydS7QJuW/zrAtzqPU+y8oujaEqivH88//dxwrzfccu3H41cnJA+IsBybpKL9aHJmt5sReCp600EKLtMwYlAI5lhpwrlx1HPzDgf/42ODNbaJ5sLmuF2//SeQlBo6/kpsQNY3VePnZzye7KSPrHZ1at3xSzygzMhOxCqLSIFKtRKOWVCiYSK9hKXKw9lnatdNbb58hKdb9rUBEWZ/1AcV8NCxpedOhjz1JwuWhHqH2y/EfRun+p83+8+W+o93wJwdyLz9CMwZ65vVn+5mq3Y+Eh/oDZ9JH/MhxIhrI//AG+aNQG3TMwgR/3mRKcH9x3eCTV//RJ3mwDQtFk5T+RBy58h4s/2Fi1Eioa41XfoYVLMHGl3MMs4+omA3LN0PG6tT4XybG646FrZvhlqSm6NwUQM1u9lyxSlJr2BBMTsU8dB2E1tDzrJpNc5c/l2MFQKPEcn65U4kjoO/DTNMt9Gq4ghQinOJ73csxZDK33vr6ajO1gSLKOqP36NUNKeW5DzKi/sv1mAHnUmOosctLr7mv91JmGjrejjSCxVYiMdXkQ9mhFdV9vBGDI9Rpg+gZsCI7bPv7BgnGE6EVQchXScM824T2R8fra71KnHojEf/mDrks89RjAT4qqGJsJV+MOrvjh6PiusPi4tog21nRGy5HAbyW7/T/llTlGMi3eqItH1S43ANUreB7i+UO6HUjNlhXPPJArzkQD0m8SQ4KP3uA63LBPa/FnS8A0fFbi6QdQGBnGhulBe2Z+rLPGHKIilbRb8VGsLNof3mG7b8m1XnnBLv0ZanSZaiX/J9euNbhJLT5YOGJEF9f6EhWUM7fLdUiCn5YgF8kW9/8/86GS5Lh2NWUN9Q3zBJcF8xXl3URHC0TOQN94jJ+hi3NC4XAXTfMYtydb15SssMBxFZ0dkipMQLZ0mxOfrHZ891ipKISUfPdFGnrf96utaIIBT1i6xQYeApR1AeFVAwyfVR+fjf2VaiwV5MMQf6fcf+IqVig9r/qYujF7WGw+2YK0fVevyqVGvBQZdrYp2btiLrYkUWBt8I22/iqwfHBxq8Lj/rSU+scZk9/SQT2YtphdcjQfuarqFI2rFi1G3fStkxG3JrkUAjTzmQQjceQ46IoWsCbaw+gLfAFzQegrFPL4btRkH3Fbj76GBQ6zbHhULwfpxA2ejC3/y16IiOXECNTqxzOnk0YTwtpFkHX3xMTdN0kd0+r9NoPxo4GDNLm42MHIU1XpTxwAqvYaaRz6B7fyR6giKVbvdNbZGfwglA1uiUuv87Inwlokf/HHRxoDqoYf4EHZKWdfeLBr/wjF/vdlj+Qsvz7AI4H0fn+SKIzgI6n+EtLhWRH/nH+SSrhP+otjm4+zMcIFkDK9BZUNXCmq9JqIp1c2gde4Ixv+Qz/3eMAmG/tFW5hrI1DMUucLjOdWYhrAOBFwDFdt0yfXwk24oo0hAoKI16EW12yskm1T3Yj16zJ84GuRue2bMq5oJE6yQyvaVD056WVLEqTDvP5oCrfya4bUuu5UR33TsoWK+PFGMQ7wTbjxAgbcwVPwOW/823pvUsFugHtZTAsiDtCX515IGG/gy6PYsNXBxMeNqsnefN1yIvTU3whc65XwDsiEBAbvf4DkvQFCua7zQGXhVR9fNbL6j+9A2yn+vLcP4iYRKGyveFxHiv2emZd6DFUZPoxSv10yD2R1BQsYIXCpseuHyU1oIPYkJagCQWgrINqppC4DjumLLwHbXjJ4N2ro0RXLC0M60uywEEhIetDO3J3W0t28+uXB5w5f85SmI2Enfnr/oj0mtSA6zaFMJendXSiZaOjM1uQgjuCziARMzN5niXSeKCnt5AEF79y5MSzjHJxY1F1vCMIyjRWpNR+5jaTXGvU4kOw6nNrhYl3AXMp0d33DR+HsjfqKSf559uUNIhgazco9cTByxnfEHQYs6RoYBm7ryGaBFszZYDq8eSkyOeKPD4OI5S1sF+R9c5mrHYTLiwz3HYHAvy0OBB+GuFpJCVS3QL/aCcEvT7Cvk1nmHPfEj7QSn0SGqzGc+2vJfYtsgOzysMwf4ZrqO9yTuKOtyMpsWACs6WHZbNcAmPup3KMHRzLwQSXoG02PNAKJfJzNOg384Hc/hTAp2DHZCtwSXpSFHCxF/WwHr1YDZNqOGoXjgV0vOPY538m1tzh/YxveGRjPrz+lxI8TFIteQHomM2r66SuppPi/Egt27f84IzZBko1lX0L+rdL4Zszwl8mJYwDW/m4lakeS/pewIoblt6jcuAXQqENl28v57t2Y87HG/216xWNy0lGQDLNTK5uCnaMhToWcmCvQOrEXmJmURln99qwLE5ySuaUdJUMDtZvZQLfhzB3TPun/fWb+PZ47jLHUBXnhx1lMgoyfKMsU8iewN26o4viXD0vMqc9ZgryqeddU/sDk/Mm0aDQfs+bfxLEU8phd4sSWJFDMBv0DYwDMdwvPnRaiQ7ZJkmLfFVnKjkYMA8lJ4dMBXrvC26tx8R+eK5yw6V8D02eK9FxZbXkXX2lJvOPZQKru/RSUaeeb2FQVONiXqLV5w093D99Cz3QHx9uL//IWQm9JBjFg7If1z3QSKAP1RVXwwsShhnq+JvAOg05BgWBRZp9yFfQ1cW/oge8rwk4xPxHSEc2Ot4cp3ONUOf1wvdQF4NM6KqAqMMRUnme3A7k4olP47ymgtgwjPyhdapW3/lTLxgq9A7pOPTp7EniUBL1zupLbAKTrWaf2VRmTSFk6LntX8vajkaHWgWEj5VUvruv4n1BO1EmVU19i19g9CF0u2BULOTB92PsicxmGfemgwHkb1qz6YcsmMOr8OhQ0jiM6nw9J/A+0pvNWqR2FuFcSIyrVDli+/MKdwigOZxKhk68mJLtbDkiZEtBM9pBbdhUARfQ+Gv4jdon0815JVj5SRH/O028eXd3jstbjTRCx7nHRi2qdTGG/55qw6pLrRXDbZBGh++UBvRR9KDH/sEbYnJZHOoUBMxglfwzyxo7uim0TNtftXxXOVJZX0jfIAfRwXVUI1iVOm6lqmXpCWiYYfSzi+O8nZM9Krq79vswOafh0I1rfNIc2e0Xj3Z0aFoN5Kye5rf06/aM9q87Wsz1nmNehigXeQZn2E9A2YacLEVC1uwuPeSP78S8x9rcP5iHSYDIXyL7YFYwf39a4OeYT3yJgvMYpwXX5AKsM49ni196N+HWy/q5c9CN9bMQ7xFrph5SImUpAQx2TG4UmJUHuGc8B02YalmwPNX62FUC9FiArLk+yR5vtMRJQcYEVyjQj71Y8rgN0CZ8ZPWgNi1IJ2F+yDAEca6svtSH4//0Fc8f+r00nQjWcjI3xtrThXjnh9yh6nrsrqqkR8RIrP9PNfwJRAOffMzLE5EYMeG41rA2aPPsBml16R6h1HTbwpmkQMks9iSyqH5FWw585Ek1WbuIq9BMQir+97Y5GoPmR/+PBbFJXo/O93SlbQchIG5HSJSCZ2VpxinWz1HGtwN/C3xXz6Yga3qe0IcYBss9Zk7mr8u77N+QC/4iI2q02imFOnw6Z3jQkCXCWeJCZ24alei+IdeQt+NwSzSYXarPmLxZahL71RBWHLpZ6X0A6wvqxBOBNSv3oD87kdE+u7FBl5TXevFvqkh+SeRVewOoIMsAMDBb1QYXvL7WpUfWiTkIJ05/eIp+OQ4iaOnUUlBw4uz0Q4r6oMQiSD3QCFk7m02k7nhfJ5k/ep5l7Re8gtslz0qzb37oXDtiX6IXuhTZjK3kPufBS536RYDLIwjjp+RE4cl1gkfYbeqKU3KQa7F6mrizUc0QeZVgxf6OfdHydqnuErofvyJU0WvrPxaM29yN4FX/mYty/6ZSX3MBfcIaWNEpqCkxPNiHrsCa5Htnno5MPsf7YDM13rmj/+vQuOIJxU76qmG06OP9/5YEfmw3LeJzYXmCOlXkm/KOh/9HJ5GJLUHFbWLSR/yhxnPJMU27fMkUGp64x3BKK+tUks35vt4Qo/EwZHRqvuCWSjy/3eZC7vbYCP/6ngyTNCNUHV1NYu47pXMd8h7zL+t8tnxvXh4D4NSOf/eacYCy5TiC+ImDbMfse7gzqUaOqfd//ZcJz49s+kydshJeX66G3TBSo7XQHt5s7qsrx2w1onEieNEEbXrE3KChOttr3WUHsrtVvI/Yv81A2D0fHz6tQQeHoyzWvZQPbl9W8NNL9zHuCo67fYWbSVqIAIQlIGF/jx9w80OsiytS9x3xB3ujf/h3uSH+I31B8SwGrStXX51uikeeiSZZSobb+6siM+nDt79ycew5GeTpHJMWPK6AbbI8aaMXLxhwAPEYss9VXHMGb7jlT3z7urgYMyHzD3/9iH9MAD8NZXEZ5J7lcaiXtW42xNmMXryYhqegiHafxvrAjyT3tpmWeSrCVGnPp4CzdbHAn2Pq/71EwiVrEPDlsFxDEMowxDmGkswWxFZhtK6QDUDs3taswiza7K5KvDOgq2bcYOjHOqNZg3Wx4iBHefOcYsx7HjeefeENh6m1R5OSExZcXGxAckvmE18gb5FRnDCT25r5XmdcUH3iRHTPZJFjSGofE4kwcTglPYrLLXfPhsKOa0x1xiXeSOAd2gzh7Bp5JlpTVXKes7gJsPw/ytxt2BpfiDksC0ugMKmrSbbyUfl/iUmy0ei+cQh6qtykPEySqg5Jr+zvyygn7OKA2wib78/wuZVggTr0gpGu3o2BXbsOYL8tLH5QqtVKw8f0GFVZoz2bF+V6E/DY/ZV1cqMVBbcSXLKw4c/OIvBOBX9dE/yrpLuCkWgCa8b1RnjkoDn9LTRTlTHTvsDMvsAzJdeX9izx4UsUkFxs+zn21ojP+hoXTmYY+jh3FjKh00VO2jOcpF6eH3AQQGlFxTr13MjCEkjkvSwPU3BMtQj6ykrnwd4moUyYIPzSTnxD5XgKiNdMMcytxqWoburVVmCFzPqDbB7r//NVNnQy/FYRLjDpsH5623jpzTX3i9zsHhfrAypU640Je0hK6pNlAxHGB20znU2DUbKhwZ2yoOg7RJOaDhByG1OyZ+ATcxdgT8FjqH/5X8+cLEHe7NpHa5Ud+C3c2MX6y8tTaGB5DWxZzMzBfnIPvAcr5l9Hr6rJSK/+7ut2BkFngKwaN3Z9JN+M91AZdMt8mBRWqb2ZQLf3eLTHBla2OPW6rQPQRqoaNT0HPKFB1HrZ0hFWhWcYb96dJ9V5WNxz8SRfzIqrOO1oEZEIAIO4AYwkA/POp/lAQSm8p8WX+YQ0uLx/aACgqF/XetHv2U/oE2QY0lqjkPfSPx1fNus60vry+wH16hPO1uJ15LfyYD3yXi+KVFAzlBf/nONGvy83JeWfXoiBGAMwkKZh9Wa8ZW4LJ8xFj3N0yXrc9DQAKU/hpXUbw9CeKkqvoCmG/u3OOZdQCWSYm7j5544zJcavtyTkbj706qVBIQJryYdI+2x0f9CIRVN75gYs3wR6ifG9mDrqoY49TX0xtz/oSmyD6+s/yIqXURsgidEulhajA571E1hmgydpxrvot0pkLbVhGbBGfd7kpwXQj0vrTfsGa0A8taTMahIQ0kX214GoAE3eUvi4WvFIMCgcHGiYVcgfXjjSoUx/jfak7gmCZTdNsEY4q7/uORArvesHSymMeFMdEXRmT7vXkdkrGJ1o+MDnScynU6NMqwn8TqRO9XB6hYCFnX7ChdHOD4TxF/Il8IO5qsmT+dtXd0sFKkgJtXC2xsG1SXWjSY2qKSPPDS6C3v+iHk/xTQ++jI00JJ3bbmLS5wZRAHWSEeroiXlvmqap+AaXoXrg9P1vo3QZCPJ8D24qPp5ixCl0KLYQWQCxCJu3A1SnriGfqblYQhPpBPh6jIGylxX4Emaa3MARflCha6zobfAO2vDg1GdGkEai6n1s1elTYEmQHDFbA3JNsd4uD1kosY+wn2j8uWJFFdorK6NcZ/5nxDe+c5zkQoMBUvd++PBoH4PoUJdmZ8IjKnsW35RYmwGdAhpNzEL6CG4na7fNelQJh799c54WaN1Ysdc0FI/08pSwz6ni4xWgTvTmMteJrx8mt+Sv+8QUvgMFUtbLzkB4zIkSPl32mVKWNxJOlrx7xIcfm+1SYlnHL8UjiCcr+jv5ZmMLDVyA6KhjlzGRikqTKTRAY1f3WFYWI6vxyDNys5a5Xkm6xBw0doKHSrxkyeEwqIiVBdlBiJBYt33YYWKH/xffJu/9LHKEDmCf5ADP8vNlqoxwtfH9Jnw1+gDgKFlpTJB1NiKKEVCkXy93f8pPIh/jFU+RytgR481JhPh+JEig6UXzDFDAfAHmp0PjA7a8mmk4WEKNQg2zRWsvBAz1eXglfgK4efyRnB8eN16oU6wHRvLWOm9khdInBsosZRbvLFijIl/5xzsYNcBSbi4JGM3nvweOZGUMlJOWJTrDMhMGIgdokD9if+dTKZ1VmqMb+nttP6vOPLd+uymaLvum8WXymDNiOrQ1g8zYpcNCGWKT+WTjjXZJryYkU49Geq0cicOvj2K7ZCa/aItNhhIS7bRr5vdHGGjnobdfYeZMiLUgmRK7Xub21/862a70tbxO3aG/39TX7PQaYYDp8fVt6cGJkxChOF//K7D9ksS/u/EY2QhgzZkanTSKgFlyKlpXDDxo2WcfGB215f/gVIFBVZZaJC/eT3Ra/vSGhHA5D+ucu/dcfnngJSNCczOMfTrwcpNmoEErhy9D9p8QmIwOe4aogBUXkKyWncNg0SfWdoqeZxS+pWD78i7QDtryYlnHs/TtsZl9uj1LpvQ87ufSxa01SfjsZshq8gwNDS9GVCzt9WRouE/NPwpbZLmjhP4ywPXKttWWhzL3VhGad++1J2k3veXPg+zsTuFiLwXQkxyeh27lSxwY2X4EAfNqG/tAcS0WMZB1POHS7DPM31K8SJtisGg2v58XiQVlkYcfw3ef0mm4eZJQKa8mJZx8YHaylXgabzG6z7+bCj2YlEGYqRi0whvSv/pZy8nU2CcWIpbcwLcTqEEKmy5KjLoEGpMp8M+IsN56iQG4ICpAlCOME3/9iSmQ8xCum9IF4Rpth3F+sHVaHUY/83PPZ85oqHhdR3xUQOGCuK7Oz4O9MuDOw7HjA7a8mJZx+SpZzhfexUDnkIHUJ6+k+W3SlINQxF9omo0hYXhCZ/a43Q03WCeBn2A/O6EfxKFkTVM771Ec0L84ZP5+2gNdRmxyn1r7Z+/Bt1bx/AYGq6DQNvg3sIAv3b8WcSdWSa8mJZx8YHbXibL0xMMZY12/LpvAILwR0FyzonCWP1H15jJ3YoGHxh6KAufD4m312kpJhQ7kP0imVhd15MSzj4wO2vJiteh44pH+59sE99mPx3CepIIRV5/9IuOXZlIt/KCysEgKu17WxIGlm3QmOctV2uUU6f1OYnTlUB215MSzj4wO2vJpQDukwdgfUjTvzDgVMKx5ZDGdO0pjzB36P6QeeevyRsZ8sUQcokgwZxLUgoIB2k2tLmsYPtAVQHbXkxLOPjA7a/eFc1fUx4itu+sDUE4cZ1cFQFy4FQAN+qvEu/MFA8VL8U/l880wXgfbmoJ2YY1vtm+OeiGyVl2K+AdteTEs4+MDtryYln75ReZV3DJAcPGOQZHP/B4+4of/kgQ5VoRElAoOOdT2vF5+x2qvXf+Or9f79/MOwmnQHxuU0xEbvAYEfGB215MSzj4wO2vJiWcejBrUZeaUt4SvdfrTdOOXt9NomINunei/t5++/y3jPPnhOoMeTlUGnFFqeYyvgHbXkxLOPjA7a8mJZx8YHd3xwlCcqRXAFrfcvo+RFEPlEaNFo4xfjP/wWBuzLjec6++AdteTEs4+MDtryYlnHxgdteXl+w6HWeAxey6tcxPiAt7xSRX8qA7a8mJZx8YHbXkxLOPjA7a8mJZynTL215MSzj4wO2vJfwAP7+JGIAAAKHnnfFx5ssQYyAgURE+oPoT4rptDHrygdT7/SQjb8xHy5+hiUrFDgGhJ+XbvE7nxo5N9JKzISDsm8u5xjqLpujMHaGkkuFEexMHofIcwzkNSdgaHDCvPHzS5e//6ZvTWe/Ft6jSsH8EmQmf4b6EnKI75Q1CVikv9wzvN2w5bgNCHVTHvGMkMnsBAPVFimJhqbQ3jsp05liQgf4UaypDR0L5vtCUK4ttfrU27EuSScASWYU9EXra7Y97bnBIq79JJM/v/UIOES+qL7sUIOmPJ9GBDh5+LcmDKZ/BY+G3sgfDKEa5cGD6AO34ak0QbqNRM4FbS+x4RlhaorTQ2USH/8936uIThrEsQ3eXx+WgA0B6g1mJ35jYjDBVTU8XL4MHstSRyU6vRcQ+GFKR2zlWvJjrCJrrHgu9fvRMi7D+/CC6sr364eeqxRwXkOiGdw0C6CZwuFhMfc55/XM/jatk2jRgfgDJ62Am2zYVYXat047MuCRtCFKW1XtMi4lMYAGF9bCV/ce4THzs1/pgwSRSP2GX8mGd7Y+/a5y/YCDhFWWFAiDCOFRehVBpobIT+n6gc9YPrPWSZw5yB4W/h1CuRdB9Nhfc+MM1IRHsG4CzJo0qghGQXh9K97sx0Huue0PlBq6BMsFLEHaRO0AACwlUC8qp7zqICeFczWuCQVfbsCd5nJu2LS71xjgFb3LpJxvc1zoQP48R5o47d3mQVDuj3sujS5/ix14bX7NaRxYgY5SXos25IqbYzi0mL0kuQl3IoKRNgIBi8PF8laG9p4e9CUEwDVrxvQK+ka7oznqLUC3XNP89JceSsBDTRGe1HQqhulBkS4TIbqAuqCGG8Woc0a2QeQQbvGo6afSqw8JK+O5CF4UcH1192VPXtX0kjrJQyMnGDlzq2Rd24ywbw9MiU6xQS5yklI8m8MwYfhpiCtjYkcyQ5o24FtpbcUIfZfyJmR/WNDmgOfmlksyhC5AiozUSGyc4RHNROi8PAMMFm85oMJujljlU01CWY5PFeKAndPQTIzZCd+iYJrwA7ahOAvPh1QdjN93K90aF1GgImirZHG5CKOwa9B1oZhD1SlGb79ywClu7i8cekxs9lM14Bqq5LK1SORo3Ljnt/dfaRe2EjzSjB5cu8f+0SNx3Kr61kp2wr3G9aYtS33oBKw8Dp2XmlweWUIszRVQtU3ZH9tBOHBYYbTmzIXImk3aOmwh3Fw+2SQTGgxXPzp5XqPb0oO8HFTcrRTjL5bgN1a2KgKcOZqSZwHKNFgVx936It9XfIbNbj+nSCdDOdXYqpaJ3lxdjwxDPcGx+a1XM13j1N3sHMRB/Ym7C5+gvo5iTbpdGy9xH1X6ek04y4OmqcEBHWB448AiMNYkrXep3LZv/zoiXbYd8DDYw+7mnMtkIVvj5xTlm+dlsok3b1Ivsb0zhBVagHO9OXthR86RPsdzF+3+4yk6ZEo1/lsxHcaEL03OApI2XrKZPKGNFnQVWJcJs8MwquV6z2ve4lIwoq5aTGKLFBH0ufKWtmQUqLXmYHug4fn4liC/Sokr7bDtEKPDCBdwwugGeYHXKdf56aPQbAzojp49eKDx/fOQkzMaUlTrVcvQ9DF9uGGfTNe8D00sio2NJ0BVew/VHq6+K3I1DjLVZlqjmi8F65y1lLY04wRcc9GwbfnOQNW8OBXbiSA4KsmL9ovpvBT/i7SzuwfBhfy+/YOe9rUyK+qzBaLaxCA3UPuWqrt4WXI+cA4qh4XCJs45zyOgXvVQmjYT9/3Us+Q+Sf3tP5YBZ7UkdTNG9Fac9gsrN+qZImY7WUVss2+Z8igh5ycJcyHsvporSU2Sqn65jrw7gzICv5TbRgI/u1yJic1/2qlQzBaX6B+NyYm/dP63Pm7h+4tzyUV12MQN5zkfboa/xHqfAsfe5R+M/dz1lArFguNevTVDPVMe19iidpS/qkB4x4tFQpu/lKYmJC8IlkBRPtUvXNxcUHHtl4wa9R+/UEbL487zxo3x2YwwmIr1hI1GT2bgWK7Qt/+w81/xpIhZfI2nwpM9DlZ6aXloM3dc8bycm+IxPlrrIcRUNGv4iX8r4WsdULIdVpXkgK6lLrWWrb0m8SD0tKCDoEPcV08OJ+wjrYcDasMMIpjZjsR8obFsE4p+monHU12+LB/Zmdgv79YAufkZhYFxRFgTYP325M31HINaYefY9iQ+HXA2NJTG2WQil1svLKU6eve/EgbReHzFU2mYvhhHQI9o7WjXL9Fn0KNKPUsO1FGI9B1JDmlX6Jh2ru5z4o0AtWzqlfrwaZhiJjwhFVEMHjbbP4KQ5L6A35IWC+VwEx28Ke2twEaIrYFR4AA4G0NQGMBz+ZCpFLL4z+8+KQEpPPsrDR+cP1LQd5bcZLQUPmVyGZWDLvS8nNDR8+H8buP1lO3MbRHVv+HZC6o5xoG7QiOKX9zwa8EA1CQQWYggqZNnBcpwoFj4RnyNm6nAOM1YmFTh9WMaYtBPzhODOvrPYcjYefZ4n7Es1gNNptfTYHkzUnLMNh//6o9+JEP8RZvo0mxp43tgyULORSNlBck2gbpBAFZe78n6U5JtNrXy8Yu9o25Kaivz4R1IfqT3B+XC/vkWLjGnEl08Eab//EJ1/5GRnKWY4Vla57Dk5/0hCK9GsmwOZYTOlYoguFbVWjXYlzijWD95fPyxl3T03LzvZc5+Jamqe8WHNlSaWpqdbfCdl4PBc5tzwfEtUW2k6YbpZ3Xfn+JL5RYIzUuPJrTSO0TendoItFoSNSBNfuoiRAZr7fNtl3GS5rf8cbCWkz3MbmTdFZZdEtzkGL9Koat6DCWHdZmWfK3Tsc+kvbiABLFCCQvJspUtJ2JBYTe+ype5sEg48QNhg/E1JauCiezhmfoX5bZsvXT6Stqexf7j9Lwc2OYBMfKUdHS8f0L2xwOtKNULhbsJrwvsYenfcGbeCYtdQtP87xYmPFb/C/REw+VXpxudRA0M2IcwwQsocYEssaGnZmMSTMGjxF99UC+8NI3eLVV6apIECCt9i5ZtEZwlnjmez0r7g30QZyrEEaorzjmTG5q3lArOEDIf6PemygruuOw6Q6kYjXZjatKZPbRp6K6ljSaIH/3O2eI+ENrOTKmXlAqZn4MFzRc6+/y/Fj0+fMEXY+jPSXYQNYQbosS7XzXX+dylKjB0SF2RPXY/a1D1J6Ty/q+glhzt8R9xBu0dQ31ms+07EGDplAkrZfFV43+8/6rcTIhjlChGSBHp1tS8UbXejVWvOqxfKW2RYPMMo79S139AHnmcsE0FTWxcaOpSbhKNFhFRUfqY0R4hIrQJgj+hDKuOndH9y/L0TQY6zrObFfOS88dAHVMqRViv8yNvqbGfuM6I8/D9qas+Bx97hafKPd1q0iLq1ooJFp+q5HXdaKrMU/1ZL2Tz9icNT/ELDgu9smjpcuoZtzV7K0hqXYLIWWw0VDa5pB/6bXkoS7gYEh3ZPkFtEc/V1RYNMTEPITg4w+ibImDT9WYT+2fbdQdOvsCJ1+rwXjSsUpT5OAEOrgC6DILqB9+n1cY9rFtILLHwSkYNB4BnoAjIg8JwNRrK7dHVCfQzoot8dtvsLh+ZUYFM3KtLzekqDB7nXH5Tafca4RZ/k8Ns2NTqqV8xqvfRgB8TCX+2sIqLRdqVz3d701+FJtZhJEf+AeYWmduIAQYykoxDedRADDilpR0wxA3Hen6PEPPLJ68M146Fa+OAIeT5I2ngrwuEiHAQ0LeUeMNba6Gsxo15cT9jQCTcj8sysjr9bJOgJ8Sg76sm+nJQck76W30G4h1H28ZMtFVBcTExlrTE6fdRoPuDpt6VSmca6vh305U5Yll1rI+JbPNPR7wN+PNC73EGXQFno9hCTQCwGYxjBmA5k6QO8FUaiiSm5eNPwca+YW/67fubnfHLonT9vvRaE0SNq6ntsDT/4mb3S0Fn+EkPT+Z97e5kpqDpC8ALYppYZiTkBoooi+5d0T5WbOlHOoZxZfUHZrUQbZT9od+3sfcE/1jVX4LGP20jYoSXDss3doTY4DrRf/tG6cckD06RxDqlx7HTxoy//alFrln1CK0CbqVPZspF7/XOo7c87aaocLkdGsIqnkCB+VyRICM2FvpYWfuV4sfUvDlo2pbdWFHAAsbcpxC4sC9rph9Witoigh8YysC8NrCi5FD4mboXfPdcnrRjpp0CrEy/kmMFhrLsoWefGHBuOY8kKLxT+fRU3YgWl+tSq34Pnd6uoU/Y2LEchNMALl8CLne8Tj/29bal7AU1j8uyTcWuX26GfBJ0uEmmTqJ740GJPB8E88mRV6vodsUET4s0V8ICInBlTaJ+EsrKlsI5a/qk8fiYKpPnZH3wb83T2GYfpsVm9kI0/lDMENlhXF6VdLF0gmDq6ru+puADfu2KHySG68KNz4KOS+MtBLXxgfSadAjTMAuU5nvMzSsuMmnJ0/qHrdO52XvAkgIbAxEQsRIV8+c8Qj9EOZLkCaHIH69bVlYbVhX8vRj89k/qyBUdDeB4amvYB/3Ul7DTBPhcZXdOGclL5yqARmrK+uJbNXXQ48+IFverN/BNHh0aeYkkKllDvt3ClFfzn7HNtfMXW6jPKY6WcUhLPIPQjUtE8EyVG9Drt4LN3E5a39q2EGNmmoIiczcZsZ24SuOXg8MGsP7SfC4PIoo2Vs2HKd5x6VbNx56s0rlzaouKki1jTR/djRkum96VayFGQmFf2KSsyCeBn/IdIYEIbZmJTOSwNEhdDD5KMR64lfEx5V82jS+I7aOBSHKEJ8WdoXXEvd+XnTMYyWfSPAs4IFtbhvLmAs97Qr9sGromSIFwcc7CEvrrIJ4rE+QTqbc6G7lfSyj+YBiRiFK/N9QIUp6xEPXf56294fXqr7AwvB3GY36736IBmmOFVrBjjAHVUzN35HVdTJOOUVX6XLI0jkWmfIIDKP5d+Ccp2AHUjIDeBsS0Mifnn4vp1ZNk11N4RGvJBdQV6oagElRE0iNM47fVSEDr+WgtbU+8sCvId0WAETgEIQs9YEfRWiV0tw0w+d7ry2KyKE/PGpDRNnlbYjE7kcNnSrKupJgMVy9Sse7+IpRtKj4kX2bWStk5VkHanKMvS5rTtKu9FrzaeJA2L1apPmJZZn/uN8EWdpSVuW1PtzTQDwxu2xfHWzMdx2QD6o2Ia5Ki4CDsCyxW5yiQAC2POC6K9xfH8dKDSIyCzCNnQrUNzYCuuGgWBADrkbzVXGEfVwyntmqvO97YC6u2pPSnDhTleSqWpCWEQQnYh661G6mo3RjyPKzkB9qflwQ5WT81e4SfWPsGqvwL5XsxNS4HTket7v9NVAn39Ps87u/WWcStC/Pr3ap3Y/pn0/NjPa/9J01UumiTXnbEcZqx/Ffxyh+Qm+G14goMI1eKWsXjfVIwMKSnsDCRm+mSZAxO1X8EnW9+j0zEWXACxJz/+A59/FOzLAn1hEzRN/XAISa1ZXuGGhzJ6Hr+uUxi5QcYRDUP/Z3i9m7JCnPDJtqsBXLpupPFeng4Wbme2dPwRxKr2euJFn23qZWpkSgEHXWWrtQb5rm4MgVyN7MaRnznYkcTfbvLxGm8SkQBpdXDU7BKSPIGGjNkXleijXbfTBajhgOwGO046QZMTRjS9yWIjaK3lcCcNSaEbBV13pn8onPaxhNwgHSu/DncJl6hF1JDaAxaRDemBXHACzp4WIWsdQxV5xoyLTimpsbu3pTwHE8Mulwx+B3CzPikvJhfWBxaraT+v8ZJseyAEiL1bsMOAjzda/KJWLE2chnb78xRw40qYDgOljsEMVhnKXagv92Fcw+MHx1DW5QtqJOr5O0NglVwvY0JVbtrDAlzdBUu9OfMhJVdxuq0rcvmkAu5A/12QAuWGZcHP0/Tb5W+eWj9bT93wsOJZG2R30efW/3nsFflceB9wwGdDc1rYHvuGlzNnJhZ53Tt/el3g8oOPkX1PFITKPO0aZmOYsmuvF/CBKXpGSXTLfqQGBu5+TdGBx/3EViaWJr6A8WQOpFvsPt/LheBm9x4NvNZTMN30L29tubyarMlIo7G9DsvLe0XtzT2vQHsjqTC9vWX1Nugw89l19H+gKdSf66YaMzrJVShz7jUA7MeumR89QkOFrWxT58I/a1w3v2LU50Ttf4YmcYfyxVE5PV1FqOwlq4z+bKZGbNnwvfkNP38bYwvMXEil/LfCCRGx2R+tY8vczwk10YvPPK09mxJU2mXZJlBilxN3g9ydbn8mcX08gq+GGv3SgEy+vAqHRtmTvCDch6WI+be/KLVzn1oHZ3DbNGsrRpjlgsOyrfOYt2SZTVyzrM/AtSyg59Lcj2aowXFyUFptjnAHSdDV/sLIIoS/LiBtIyAW4daflGQZZIpoD5gqXlcVjoq2zy5I8liIMJRPbnUdfj5MTOZLqNZIJ/fK67HdaRIJC128zyGFelpn6A+HMnUW5orrcwMR83PMW+ymsUF/6qf3eoiiCfjDH1HS/3b0qAKlQRTjLaFoeJeLZWezZDQ06+jUve150sIsomIKndWKwQ6vZxLqluiTERI7cAq8trwywK8amw3u4frb9GsNDrn0TluoGrCwST1FOdqfP3uolx5sLm2n16qInitpEgzqBwGvyBQZuwXiX8+ZhYvy0gypdVy+pmFGlcZgp9RvEiH+9UCcJ3yUtg4GISEjtgXknkFp//X+jJIfq6JY5sAwbQ5scnHMiYaXyCtasFdQA5S8KZ/uXRsiH5WHPhi7CwKpwonG2LyYSN4H2lqM6wQpDoool83J7giptw5Myhx5KTf+n6xnxZihKZhiITmCS6aUcUlzcv4TobBBGSvu9vP6USz//mozDaeRpd/PLgjZWn758nNbB/V5onMan0Wme8PiKIIjI3qB4E7dS0JN3Lv+qKJP2JZMzjw+LnOEr3YyhsO5DbpArDj1PItxNHdOdIVY7ZfUFBKNmYvENr+tEZQzsqI49WqjzCGt1hrGXyqh5LmGcEsqvbAaLgGxxghWWNMZOCahBx2WpbA73Do78gGri/FHNGr4tJ4CWqymVks3CREs2zoKIxuZ6XDavW/t1eTAETduAlCVkj8c81B/As7Lqg/ZKxdT8NsFwSA1lTj6tivD/alhZJ+5j/MBbgFvOtGeOL3T1DuYvTtIN/Qb+y+Oii/eyAVZZFkMlrXMLcHKlVRI8eQJ4MfgyY9xCMqCIJ9uOi/M0mxvlIu3xALa0i5Of6WMNA50XHbXHCMpWypSJoiUFYJGotJMVsm3YJvWy7jDj+SLkJtN8JMWZ/19X502qSu2SpW4iOMAc7w5V/iENp/Enh3FdvnzXT1SPFvfHk4BvqQc4md2Os+K0fwop28dEwBIMEatEFyhd6SNJ4+N/rAiGA57uzWiKmtRrM05pcth2YwV22HIhaNNOV0/jViLRqjg6rXkJ90AxJGfNSXCAIk8ImaYmMnBesies6Cyj+zOqfLc8m+xDyHUaDglF3nuIevdpq644KvEW36Dff8Uv0E2X+ORsgwpVldAhDtYleuccbl59CWM0p1Y9D6m1I8PX+eQcSHxsN3oKJah5KX68FMWf/Uwc6SekM4Muo6hprbQmScXh1t9dZvoVMy/t11/eAQOWSfYkFyerTn9alEjlVNrD5eWFL7HdgtnoVI1AjDAxJnK+RabAGSOb/uQhZJ8TjKsDXxUM4rpNx/y8VI5ZHM85Z0HeJTqrVtZj77KUrNFJXLMQFje5iYROkdwsPIAcpgi8tE6CVFasi52hLrlVl1kl3u0CmKJ5O2crsA6fwO2IGfkFbYAweUR7RzHGQFEBZb0RN6L8YCCUxoSbfACMKlYq8gV6syg4NrZmCibNROwBBdsmEJNWKKVyEQiK4g/6Q14hvzrvliJys6nGlkKKSZ7gUeTKCSY9K3eCcA4Je1Chqh2LU3WIcsFQyKx+QNl+GA2dHhLLqGJXNkGWKiJRz95djjXFmqX0Iy/dYBVma3pbKy7s5oMQ+VTD5knlQWCUg9JIiORrPdeSdWQFIsTixlHSaobSbtbvuJwgwElR9fsYrUox4sOD8RCoOSvEa6kBOp+u+UqUkhFE915GmIjIlzV4qWiuysneT06pAo5UczB6K1SS1UyeN9qz001baU3nn2QCBmpjW8RhvOLgqubQY/sAKeZz2XuPMgWDaxOl74WMqP5YsZQMDVVrwS1oOOAb+/eBCmU/sPsvAmhTSpQJYaV7l+WUOCaEJ/5lsCUyIt7pVHihrKxwTIdQh0xuOaMDDzkZE7UqZwN96unphZ49q+K23I7VPG6q+CFuyDsc+uFctru/j7FOVeUMblBvtGNzIq4FYi4PT0I+D7dXKo80ZgoyrRU3bTLKkbUal2iIqWk+n0zQeZYLR2iO5AAp4Tkom7KUvGR7cyKuktS0UTsZ/bQG5CRTuGdpeDu2EPxiN3J/eyv7qcWlwDfRqNsfTNu/GDWsKXsP5h4sA7oQ/o9isT02cadVEQJH+Hc/HH97t27dIu303LTb899acqfX9ifel3bsg1KJHrWjIv4AD1wR2qaMNY2AVAdnj8mv9qtyeWTb/KpQdZ9uPfQ9/bXdFFT2uykE4l2WiJ9ZC7deaRUNLoqVo7nJQh+K95NbcIU+cZzo1je75BNmAD9NY7AimkKVsnA8zfPqFoMrKpgzAwNbKgoV6c7Rb/k25eEp5ZWsD18D/OUirBinMUdC8DmFoRYBBeSSZwEZKGD2vYEemLW2SPxdbT5QGYsNTr3c9MImOYi0QNCbrTAoLgeX2HxWtdI6CL5Nck1DNPa6STX2Co8xBgChHlvRxlC+x9vD8fb9Y9yO6ErnY128KpghM4xPSTvr5kKQQ63vk3lTdHlOFDA6KaStGw0mqwfs6OaR5aolpV2YCUS4bJSyj+WJ3Zs3uDpXtLhTrTbHwFXXPYz0lCWpjxHY4bwrrrHT0m36QXFtzPb6eqkjS7toSCWYTxfSRj5Z7pBaCdGIdPi6ghQOZa4Evt5C7Cy6lw2cDkSTsKfMQg/pOph2HqSwhypKrBiRb0HwhVPJCD+ofMINq7YR8HZb3ksQwZdPNeyFkGrv/w8qFqZwvHQtlogVSEZ0rvIQKX6fTdwtvTIw191gPkAsoajDBWweUN85+kD5wR3oNGtQhPkgNLxMqLx/osAK+Egu54y2GsSEBPnX4KZ768jcJTEGt6yB2fQ2QHKi+XMmEyMbcFcUv1e7j/BS996rTqzcEbApNjDVwLmW9jbRrwlaTy1duCs0HrkrHDQ6as88RQstc1PaLzVnqcyLwGIjTjQga2SmlajHKTimdn6PlNwXblUJHEJdH9sbZ6OWtiBfC7zeUNgBJVAihr+mAiZulLu0KLqISCTFr8IWestBOvD+xSoNLoDVCdvzPOCrKq8mQFrZsEeoniNEGMBGUmmmpdLF9qBgYdy8x1E48fLpJbu5fh/DfJLal3/FwwzL806DYWgG03GZ18JuPZqs7K7pZBXcC5c38TFMlqZZaMCwpRtxFf9zNRSY8U8/ckjk3RKJWjVn7hgoBu0RO4vQuT1LUaFIFxXJr9kZFB7Bjlukqil+53olHzNmwB2AWPU1+p2WQ8A8Pw1z/KxWcpg63ft3+B5WwCFBLv/h3w6hDKODdCY6BIKAZLAS95rXWfMWIcOvkH04gKrDVY0/BOi7bDGAKLpoxU94rmbw0gHbZmO77uEiuv4agVarc2iFGajPc1f8nX5P4Soc8izJBwcGMpj6s1oqlvcFEJmz2yggkUJNWD0T9xRiimjcOuXHUoQoTAk/ja9EWpiDPgp/SPzkQPQRlP0tRgWUpSh3LmNy+YTrU/WNYAtvmxnJX9/8xjwSKfWvG+PuQqZ2f59WUO2MRqhxmtqXQ6nYACTLgTXg5eFCVYDJRfwN5Bg/lscZmrsWjhVS/2gbk/HH4CthwblmR4Rg54v9WU3cdVrJw/o8GznYpKkkGRKKBtGiW7iOaAFT6ZflDhlv3lVolW+edO3Aae0Ho6b0aGz/xkn8BOEveGiea/OZLjNMHmCr7Ry51EMkHgVszVQF8ffdUfpqIzlJ3n5X99cF4nAM8EximJWM4R2tqtl/jb2a9oTTrM2bDuR+x3JcM3VgzEKHuh0/9L0w/lJaKTRxjQ66ZA05MeA5ulJjLeUgUSE7UuVyaTDQF2iw0Vht/h0Te5I/9YHd4nHKajyD0Jx+FmSVq3cunGm4kKT1LEbMygS7+AWqKq1JwdSnRiLzKBqg4J6gyjcCBc1r9m+UF+8+W4WWOaVIWe9U01E1ugPYOPJWY50Ua5/1KetIDLqMyHe2SfsA+Id6rAXlO0QjEF135oc6RXn3Wm8E0LoPccM6foLVKZ3AOeR3CRCMoePNwoRYYrnxnUHL8M5sZEox5uaOJiUY4p3HDXHpBycLHGXfYVkIYp1Tk5csdwxDOJlU5JQsZ3/o+uAsMBkdadnzmZkJq79Q/akeLX69dR8pyrL3y8WvMnmoFm9ybvcTfkCwGRpTlKAqtLROdXMErchM1SQXNVNCAVfLfj3hXug06Z/51YVAYTENWt66Mz5G8I+jIAa3e4cTU4RL/C3Gq4T/aU07Z+UZAJhuND8qaR24i+0m1Va64xz3wacx0Mly+4PUq34NP2Z4ZnCr/EH1LJ0To9c1ce7t70vGpH/2RLbFpYvofIrenz9OypnCzUM8Wi3idYokCsaGDdc0exisXJz/TgejG+hFliLNmJHR7IymlXWJ3z3vuIzM6nd2gbXQSD0MvBcu3UmA5/74YjuXl1B9N4f3/ubeJcIxH3oi+Fwm02kVJ2SU7uE+q3TlPMFbPGEcZtSqoox/xbLK9yieNs2UQ6TbgIfCL6hX+sy2PGeEbMz3iFM/Yntb9yoOOTkYbKPldLoP8S8Hh3zUdh05zZqAKyW22RXVzApQBt/d4ZndmUnEV/VWZ059XOlFbeFUqRKYonKMn0o8aq1MPe8QF+nsVUUMjBn7AjewE/WrBe3foeKZoihckTpb8b6+A7ryhWLvyyv4PnKVN9Qj+CrAzmvdjrpPlmJaz7yLNFbobXX7tMdnqF+hYUaRQQaTlNczp1VpqcL/6yiVVnhtaKoJILdv0sOB/9TrxFnkYdEex+bI2ywOxFi0ByBWw6/8Jr6erKep1yx0LTkhJza2Cra2kr32EFlZVQz0otLQlhh1TGR18u5zV+OcbD8nojD2dCzNVgT39/cjU3ZV8tUZf5PAH17KpYdihCAspnZdfcQAI2XuQPbodWATMfEHRCHAfi6JHatw8Q5+Bs6T0TtNDtHXs/H8bjpPbNDr5cIHAdtpRgVuM/2tzBe0c0VyPERY/x/Cqi/9QgLesgTn2gO80wb7pnbewNXlOM7ZzFURgMR5F3sVILqhYxEqvUDq1fdKbYlFNxAjKccsO3icTOYj43KWv3CRKDNUj0zsopSBUiQgJPRrkmqWIz6TIQguTQKpjZK+iR0NsfwSnND0Kgf/tLJ8RABokFESl7Vnxrl/pFEWz5MOuBfGS3339+I3cQl6FOaykaLLZ1s26QdkO0YZNl1IGI/4eIOBVZrYxiAgr0iQrUXKy6d4OPEn8HGxNmZ6lPTatOUNalUmDkfqn19azEWbVSkUzhhV5LWaj+5M3i5LaJd3P076tRQ29YT7ML5mAEmMaZPh6E1BpyiYsf4AalvkYCEONP94PVXmKy6SEFng8V7z4Jr8W3bJbzOcmszWjpI3rXqqhe3YRhJ5G6s5+pCqOE2M2r1VVFktTe6FL4p5IvfaTRmgROCEYfe5MFH+uyccAa++0aBBWJd3hoCay4THeCYaLsMhUWeI8TT/Ml75lyhcTq0yaj9SgyBcKg+om+cq3uqtD89mpINqb0C8oM4Gi6qIqWkxV1EGkNz2LkGlwSAyyQOjx2rG8hTFQCbJbU2sJiT/CkRrwLxDEkbErwg/3SepQbJ1c2A0PZYGiqgyCK+1TMGi4ew3NsW7Kg/iuhfvLWPgRtjkBEoRl0QbiGc/xB+Ef1jQrlANoyvqoNP0jRrmLCtuC3/9cjw1PrbM/P9BB3YgRFCY/oKWa3AlOlqYQ8liyYTy/45oXhPT8fUR7piVqOLiZycL/YiDHWPHP2fmBUAQa3Oj8shm23KDLCQm6o5IoVVlAorndMma1yGq5Vd9ZZZ1nA8ofFEFzkD8+iceiWNbDPXlOSaY/DxQp2m6MYl8byHcO1nw5ePWo7VJSD7+iixOo/7bcCvubhvcglfg4RTe5P1fTkjWNKuYWHiVKOQryZm5mIbcJa7KSZIDj1ffwZuSEIVqnM72frTzrakG5Pg8bbkFr8pMlhFuVD8e2x+mSbVQF2vKX0tPU9Ggm8xEv0RgoZBzWp0euMtA5ClpsxyJG4uIsWX+ZovaNf/BWYhkrdSvSyjdYOj0eEDvhhJxlN09KSrjhPgKaAUUDH5CX/Gg1mr0ZQjoBAqRz59u3fgYGYaAS+Dkhz4N6MYYWpizuMwfF77PmE0DVE1zRzV5nDsjgjulHb+G/QNpNFQ6D/v2lFVoPQxeRsOvwkIvB5d+XU4C88t3vTFNnLIpUBaMMtaC1Ftaz2ayxUeKOTRJrLm1e8S76RCn7hBoEVf9BQGmvnCddHIvUBXrVc63uSA6yvNMoG5yPO45p57aWN9hLXzyqnHABI8kzqt47KOLxB/xZgLssxckLR0cVNXt6aCazUxhzWYt2s1kB0Uq9r6Ohp0S1yxKdGa11+5MKAB7s6jVyQ4sOqyigCwgEFz1ZR6w3E/smQxxcmz0nxo9BM3gDGtHuJJU6E3TrJnKC3CtzZ7Z1Qg4UhIWHB5XDz7IU+sQgn16DJvFDrPZXk8xEo1Z0AAVow39AWtfRhJkNyHVs5x4cihoUGix7ZTonDhGsTbmjdmT/gugFSR7t6sGTLqGgupY/nKvInadCik3cFGwO6/zwPn9BABXCEIubL+yrrta21KErjs02CYtkGxGLKu/Ownz2b61o0xXbrW1aZdPj+F+1fcoHO56tk/YXwXgp0SFlOaLb3PPxNQMoig3jIW1Eur31ZeNZPvIzXXuhR6/z0Eei3kiKL9A52NUZmsS85yhEndgPdfstN/CLLAf4/Gbi5KdZZn8AG9UeQ4Qs5NqmL4fHCDLNImzXAgDwHFT/8Rqhva5EJsXLOrFGrQAZRJUd+C8oIKQwNtb1ZzI7uFUpgqavOk0V2sbJrss5kV+qreY5RJgoG/xV2wOARR3XozRlqXKyqcTr57RyrHXwqlrnBFWCBp/CitTQmMD/jpwFCsf0Wm4Dc5R7NfAQZFVcqsKDikFF+UfmncGbLLgQeWSZzLlbXwvRENDPrv7zqignRQwvuSj1NLHSJHdaCkuqYQT62izA5AwnVoiYy4Qz0V2uSxEQDtkfn2r1klQoJbdk6T3YnPqn0oqhezF6RO4NRlgAQir+Sm5VuSMn+If9xfAg4moJxtEmCHpJ97Tsz6T6dZbA1qB4Yi/mnlOSfbBFaGe5I+clKGGPkU3nIxo5jJzr0MC3tgHk0+Npozb064DJFRBltNUNDObfyuJx66ps23MtZHgsVGbqBBdwOvl3R8Z5DHAtraGs6PopFtO9WcfZj52fNJnPAHae2Fq1D/yI8h9ddqN1FL+SBXtny59emctlyfDZl0EoMQeTV5MLlC414TxPvlGZiZFZNorITSEmtwom/wdVtzw+BYJHKjoIY9k6eSB7qf21cYpTCMO3ImgYZqjUZ9LwTU5Uee7QdCRR4c5OOOJFf1f0BdeuFgclsJNhFByKCkZ5WHyUxpwcfJq44nD/h7+cGKIZIszse/Ma6T+b6qwUK9q4xLAztZyB/Zy53FuqPogDK95zyBJgC2QPrx84q3FnGrhZ1J357b7WIpQBGgsqvX0ZF29YXtggejuv6VcmQJAFjVzo98Pt7vaGqJBm1uly1Eyt90xY43kGs/LaEbGPg2wxLQukQrahAzmij+e9v79yUnOqZ56CxBOpexIE/aFuQVN0WKl/n+utXJJrRLgcvlALInprF1PFCn8oWZvg8vcOe0zksa6SAHvT7QJ2R/ueDL6O+aWuFkgOLjEogi6kT5DHl+W9Ito9BGXpXQiP3t8KMmiE7Tk1TFlH+NcClTKcIGwuZ3CabbgVi/U/hTetO9Z11hOJMcgH+xoTYA4yMxwbLLD+sIZNs3JE3RMNkLYgpfAG4hI0J5OaDzzW51LSmrnRm48lH/TbKi3PbxoPVuc53m6P1qyJVf9irop8HlZPdT6eIJJC2tmzpDMeajdWx0xvGzHHpb7pskUYLtp8YlhQbzSdx/CPmJyay/3dfInya3UeNnkWTeRtpkL+YLhVNJB679MSR0HqYn5wl8z0sIfU4iYQqzTVUuYACg8bkIjBD/ZEZ2DC89Wm2UpyYz4TYPHnrYeXZgYaxQaXGpaobHJtplm4RBW04UA0hDIn1T7suznnB2eQAKKwbu+WkjDtZH5ikMiRpgxgNA7HdTO/plFB5OftxsleeW/hKQp7nFlxy5kwTdQu5EtZC0rqskpCpgQqa8VAqy73T3PR42VK3BGb7rslMBiGfNQS0J/nxaK3Tgarbe127n7lNIlV1Pz6iskhAKt2VvNkVAjVD2ISyLDpC2QUD79z6lmgXGoOMGR5RcED5DjzW28gktbGBJ2hVeQiLNJ8HUd/7hGvr+PILwMRmACeyt/tn10HSiYZ9WUbhZqVrb3RZnCzdBAnufjtoK6ARX/Kb+QLGqzbdskz0xc8Ygk9Cug7K+0dGf4EhL/qhZ14e/UkXJDZTjbtzFpGghPuLZskq4Y/fys9UR1wKJdMPh5DgMPg/j9j1XHci2z1PgCEIaaVEjSPg/X6yg6X2L0gIUDvaBXGbnj/1WtktwUvZVRefnYkwNn7+uO/RsvAxarRDS4YWuUUzEu356PlQNhmh9u7ADW378hZow5ZtgfoKM9IJhFbWy80TtdXaWgv+qjpXqzD3VEPGryU8BCOVCyJhPFPllG5DCHTohEEjBYnLEBxRfPFDI41EANdbSpXF7Sogbk6hFFp1yGENvOU1xfzl1Fyt03O202mYpHvhU4HoJfXdFml9JY5cTnxdwWSaLhAAQ7sW2Cx/ZjTvWyKFAAFixEV0ZFl7Ixm9hELkt4tLYj5NT9GzhEffESEIuY5Z64QBqDIJnwrK4zF4Rd09ugMcY0b/mi+DFWj2JdYwm1I7LnUPqxb19NKA9xfWi4rvODYHFSFQklB8bKv1WbcrPx5KM5rK4JUVTzyODEkxwJ/uY7mHYyyPUKrsIiLWTLmDiXmtY7z7HtknR3oBrG/5ZTS0nxmLT83qsnMmEDunrOFU4gwHep1wNAe5VYdaU+fKko4Bd8hQVVsm6x1ognUPUM/N9AjuAdVPbQZMBYyJzPT34NNIvFuWGC68/HlOM7LqEjSRT3+NkIEiisOIqM6W5mPNBBVToHBvY0NfKOvjMW80wHMTE/FZZLePaKW6tdmDWqhteYwzkj0IJctSwatxtv6eZcP2TG8USuAL28vxpbJlika6bly4qDGth/6Iqsps9CGTXWE2K91S9+HXjYgbX8H1WXxoZkxfK+n+iOzVti92vxZCUUteD+Om4itExfW34sjqn6krsfOZvgiZUIoOpauxzWucIwlo4Zro8cT5z1tzFfMQ3pOJ512LGxsoDgRjq55CMKmQoCav9kTlawngaA2Pqo1wUX/q5qWJ35kHlhUzDXej6kWWrpi/uEV0Viup/A2TVsIQx26RgL1UJBJxlG9bsyztzO01hdmF3Fnx6sfobXDwoERxaY6efeNe9wZLxNcNnpAhqoF2y2iB7iW6bw0F3eHqQlQ6rUa3U/2XVTXyDFvVT48hQt8JwhOIxEYWbdSWOkH4cDtmPpW31TJijpEXQVWpFZ84ma3OjhOYlA21OgIwFT8uNpY6yW8GxKKNypH0tanTaTZhuSi7WRPGK1e5vL80sSN8/Q2gQHx/H3pt96A7G2b6Ycq4unK002rfQPUjUqnAGoit+MM7J4ibzShQd4qxgKDQ2tiOhoACXTnmoA7CteCJo5WLh1birv9fOCry8w6qKJZBq5UyoX5jo8+wUfd7u7neBRu5hVl0Tn2bErDvAC1/0zn4pVT/oeB6q6zxo9wnnZE6898DrH2eTq3/vGxWWug236ZF1CSibMOv6q2OskGHVI5BuIumWzqdJdsr9PK+vKtGC/+ghCIs3jvWc+CjEMiNCLj88iWgGCAREhGqYTk8UomTO2yozqjxHRGuDdCQPm9iORGgVcDNAit+pXi27wuqy/eZLM7UFFhnr5spnzhKZhUNvmvcayxR02qnezucxUp0y0aHKxo9i+0IoUa26oJGP5uiQtzwNDlYKcaFwErANlH7V29H/YLDd4igzu1yViWj0JSb8cn2OjIn+IARJJKJCr1Mn+JEYrlQ158JYaNTblW0KdjQeGEDaVrF8PdptKNagcomIJjRhAYv7Wr36aYr33H3+Xyv6qx519dVtdEKpG9Td9CeeBGzKbgkGGf8X7h9xe3eZzV3Hfg8wymAw8K+572Pwex5Oz1HV7FLcabkYbGjN+M+FynDYy+3xasav9QhQ9Nq1OhXrvA+V4XkekqJahUGcgjaup6UX3UOt9XS5I+vK2VTGm1aAD7bDe3dAZuS+FL0dN4lr4dAqZ+/BZMBZ41Rzvbj4NskfqOQ+FXhrQlZoRiQ/B0GnBathfRuQHZf8h2wtl9I6FZb0715ybZ18vA2B7ntbmXJL67158ynqR7IewHWSQZUDbBOewDBrCdb0zQRfPabFFYYrPL0Bxt/ERcys5axHmKqS/QdPSv0DA7aVIZ2FXzn8KWHU1VjpX9wuhwt0EAUtYYgNd4OTcQiK9lWRQVrwPEXZKmMVoKPcK9oKQ2avx0I3UaNF3ZV1Gr0PgWHeV/X3I382mJv3r8AfRm6J+yX0IXFBTFvi9qYN3Pru5OpLrE7vOZiRY3hPkuE+w2uUcRFJTVazhJK7D2RlgLsczO6mUApJ/poTuYg1tFZ6PKg2M+E/oJr+lNoXYt8fb3kGrjop0ff1FVOQ5ycik1RdOndOS8qa0aUccuOiivgP26rzb4sx2T1l9hEKz39FATM7O/8/AJRNUILO8IZuGXFv/OdFv1h9BNx+TzKGRTnJD37kgu6wJ541w0Z4oh7K8BBto8LDQLXYMTgxchN3kxJCf8SJppblmAf1iELuvGiPFCpzncCxrxaxa0wO30+KzAMuKi7pQgLlo8kuahBJgZiCgmNj7XpfZAxcnAnkNnLqgrnnPOoeNB8EDCt8b70wXqxmTpRyVUXPH5/31xIMySpGggIMBF0uqn4mJI8fdwRxP2+hsbgbxZItBpWRusZzS5VkGt75fXjLNDUJhwl+pjj0pFNgZtGPnoa5zs7UmUjPFaujgxEX+ExGGDUluWuyKrO1MJccneAHc3oXaScgFDsWac9Dnr4UlM3XPkRQ1d+uzpUnkFY3RCL29eH4U8s9eC4S9rmJFlWOdHB7CXNkeDq5sYUZXRYQ5RH55iunNsgL4M3rPKBw8hPiTnoDutocY//SlypzN8rY4mjsW4+o7ivoesDqyPWrjuH2+iLOYc0bw6lAoUEwbC0+BFJUij+uQNszXSBEp+hnoPeDCTB6nTMBqGGSLyxHUgwhYyuh+l6ygyeeY/iW7qAIMudYhm2q/SvT+b2RuI8m2/dwukLZ81WjD0VPPqBNxqK6UcSsq8D2TfSwh3pV5XMjdAMAfu9fFobwdT9uyWbpHENsEvZgmFY5S2eaPucvk9nRNksQpBOH261Y4X6Y0qC65Kr59in5hcq3uJSDo3EkEHgSAfvYQ+bjXLPtWaza8b3JJk43zTWfVbhsrYb4pGlW5bTYBZd+6lFvrYIylIO9THDWLyCCeANnsB0Tr2NYVMK0/gdDwpJA2Tf+QEUKAHu/kV0bt/aDs7IrqqEdec/6NywAWS+aAb6fQhzSsC6o8dtjEVBJF83JVS1P1Kspf7tqB72VAFnLhvSov0puTuCGIyjreh8qcTl8vVmscscya3lfqwHSsMXSa+tI+ploOmZGKqwv9YiHn9YcIPn8+CtbSKXLc7RkwOTavNDH5kq7SYpjNdw5aAf4FyPrBIaesRiwrzjaqcvftRKHxPv0k+4QeIRVv2YQtMsOGaLyDnhiIVaiEftx1fyjc+fTdZgyMsl2c+eArZK56zb9DcVkMh/CgbTJIFMkwHJZ/FeYS0JzKbOaS55RTtpxwvm9jHfRW98Q/O56zD+RIFKGAn59N56ycwpiaqtqJUct4eafdhMN4nApOUokw1Fst/4OZbKYEh2pduP8feTIakGk9c0U+iQ9i8VaPQwPdJEof+rREMPDO6jzlFEtk8lGIoUrOp0Lm2yKbjeJYWptsyOwxxxqg2YvslYqnPkhtOUOvEtHjSlr6ioKEgfz34yNfGwproHS4uFIOPJvlDszI7LDlSTsB6jjoI/1df8A2/Y93/yixxZ4Z2hfp0SxO2rEgEtqE8gYSu3tT1nw8rF/M9m+527+Fuemo4KXKzq6CLmuLANldJv5x6ORMgHxGzW4gN5iTRnDvTja7pJv1YHGd3aydJk9IF+qtuCA0uzGQ8xQDhW+H1FvBl1wFfBdd9GkR3vZt8ZYUltDbsjuWPEp0hnl0h3pYl4YICbdMJQndVXYDv8N6eCk2VCwB7m7RM8ohogoCE0nfE1uyEedxUuBEUHa2sKkUYupktQ1fBbnhzwOMHgA001SIBziVyzZ8calux+gHVXlC6OBDmizfhAp6h2mXTasthxBhSO3FWM8WCnWRLdLp5AjOoOa3A5MshmpQyb/L7mNJDlz/DCtosb7OWRPpwn9+c45WbFBqs38xXRXd/gz8THSBChlFYubZbW2VoIlt1Gtj2bN4TwzLASKJ5HHZDRVLH1UFR6DmmGc+wxet0RBQq3qBboADKnQofFZ8rZALKKZPR8ST+Zci7/ZzuOgWGS1D4oBAzsA4lPphxYoq3DVMRYKWI29bmOOv9iy5dYF+NL+lBgl4nGLadXHk1N/MmwS/a02xWYOsL0P7tIvhGEHclto47po38LVOSbrMaRbfysswiZZthFU/9A293wSE74zWpPheeDNvKj3D3Exy5sw/rsVgfK9/D0kAMyOrlay7MNEves7LNvFZvkgW4RJcOPDlvB0ccW82/OFw8YoIbLPSdHmuGbM1gArkqnVEGCwZZBWZsIweSE4HjM+chBLLYvwIPF7Ur+OsO45OrSsg8k94bztgSZd0TDm0gx608y2BAiy3T1iSuw6ZFEvAEZKiK1J+U5bjsfOgCs48BKFrEhfp5eoso+3/NE1rS0TcmJlvEEtQaf0/bdjQIftdXvQZK0pCWy4Q10CxyLQtFbTeJ9+B0JiMVharzblK0ZGWpjXWVhmBKVEsFxd4p5Jjw9CGBhJxzSi1L12dYKcFcgxvIdudTgKZGjy9SR6OMIgGGEw7dkyt/9XUwJBhkmSLf2S31lF58YHU8yXO2IdcwNgNd8Q58kAuNfv9K5hvCoVnIMuCxwXyyOKvxrNsiI2tJLkJnmQDGatQa7sC/+HeuC62jUExdvie+sbY2Mf14CwrEyfVOvoAiMFkAeNLk/vunrU1nA84Kb3PNJGRuEUCzpqWPpEjsMq7SSFHNWIRxVaUueZPHfQUBN+jyghfdJf1fY+Cpj6ywnuiHd9Rg621+zZslt3IDY7HgdfnHd76h7vA7oz0IZMiJYOlzPi+PmDU8GuzqiGL5H3gxjQDZxzBT+DO9lkZ0J5P6ns9u/gXvGC7zSvCg1Kw4fGs90lF+Vij3jvXzav14hIpWiQA6kFZn3fyGzIyMb7eZsCPGva0WQTaHbxc8zhNoLpfkgtkWOyYDS3G2NlvtVXMZ8oxlv2kIKjMM5SjwN3eTSEzncxysrCeCqLNleal3YCeSS8fGtUZwKNhzE3GNGMLav/xNujHisYnriTOMR3J3MR9GO3pUxNHT9DHIrC4KG9ejYml/cZfjz/CksGIASY0/KXfYCB6iWMVo6lqz7cXQbaQwR67g74y8BPfpMVqVLhCP+2NKJ3FUMME4WsKeXET6/1thZfe7EbcX9Ehh8UQhd41h45hzCN9zMz7Y2shp6I8rPvDa8EcL0s2d3+EwLaHx17npmms9FgBbY4s+ZQUyJWyfgUvrqEAw9Qwv6SvKTP3Xnn1fTuyv30ped7l5mcQnyuqU9fsPpKhRgWVpFA/5G0bh4Uc6cETJXeaEbGzafUyvpCAVdbK06kXiLaHWn31XOgPPwSliyaOKcCriTWDJ/AjMj/P64EZzyBw9zjvGInQ470zSaDkCqEMLEPbkQUplfrotHhLI3+D7ttjZIkrNbn2N9vhYYSBIels8ymZVU67Rupg2NVle/k1FcDHVl13tgZfYyfTlmkctsWGZKYnnAWY5+t7HEv6ryZ2+Cue2vORF5W/rcq/DKXFp7+tukCVGYvMx9hRDgaWi5oseLKzDLTO5D4JXyRkO66nculvhqijl8hLbr4CozKv4nTypPxt/ijAK8lMVRRrpF7nuZWRVibZp47KtKNeGArDwWwzRZG6YZz4EaANKcw9yyYO2bNbMNUHcNiraamyEE/7F0si6+5DU9iqTQbRhfsRtTUMaAEfLYi6SZahunQcuq1QgDVUlv+12f2wf+vtdlSBtKWJFv3e4k/Zi5rPZHp24eHCEPTjOTI2rmVULrqeIgxOYK3yCJJeVo/8sLHkqt5kLk7Ulo1EL75xvgJW6VUDf4Qd2lEMVEsrrnvLNT1NI28PO8+u8/617+EQMq+D088JtdYVnxXUYTjpl35O3F+Gr7UIo8kmBzPil+dr4V05/QTYYHs4aKDanqnpkIQWISgghwpILC2+IHZXm/q2zQB4uefPrLNJqhWINtOdZKg0QjWZIKYiOLsXlm/7gknKo6Lv75kS5v+W+mcIMh/nQLJF4hjhX53H/Ab8VDvMwk3QiknfdXhzHVaYYixs1bmanIjQuN5imrNqBcR8AbZPErObT8tQrSscO0hPx6dbhd4XnQ9KUNRFPC26ELirXGLkXBKujatQ69y+ikQ6eaeAuaSrlg85AZo3KLn4e6XtYM0l/Cr0YjyHwdw5d8ybUP3B+69L0R2XUrgBhjSfTf7Ja4sx/Pqz+wN68RuM+qS3iHSx/TLPL8gJo3nNqaNvNB/DHWRLZcmcqCx2bGxT5FR/gukemLmEPFIf/pLFQbfyGbDfXFBIjbYUKryQlp/HgFnMIeCQkvaZDJF33aNOiUqLzjjl6rALPcNEXQI8TJKhW2CnG/VfjTBCdZ7xqkZB0oC3PrXyzWBssnUAaKpEQiUZoCEkGk4m0Cu92YIU1EsmJixL9oTOWsivHh5E/sDKwea7ajN3Wo7Slku1jhIBULJbaoGinnmlKN5R8dBiCVzFw82j6EKipUvsCVcvkh7enljg8YAtwM0SGfpLaBMZn5ShmmJQ12fUFOxjXlRfu3W3lao2vGWjLb2w4BfgVVc18kBKRFoNzkHdokhFryo6+OtOPlmqHr2bkI9MUxThI8aUSKhAtQ81enT9V6Ezzb9VswALGcglPX6aW/C8lagJ84fix6H6X7QxBON0ZiD5YScNT2MRe/O4pMj5Uz2g09D/3z4WdPk15x81nk1R0lxuHFwS60KCtvaxwDHOXVyrckGPJOzSZzTuIdTujFCxo4kHBhZFs5Uzn1HAl//n04SU4yS1NiX4pvFaDV5LQOTn6OHo/bj3cRWpQpMpdKglHic8Zy3c8QNB1J9SoSFP+SfocRlbLJ02BbZZ5duChyPeDZSxwQ8OJJ8uQCL7ske+eyNpqe/vhMIhuKh91e2V/8W7ENdmRfyQK/FYVWp56peUgpDqLky7ef3gsqXn43ouqA0BpR+sKsAS5B9VHZROgb4M5iC5YAf9Avg3Czo9nuDpS6p6BTgoUkwy5P9C8oPyjPIgNLOzoPe6qlVtvR1nTvjPhIba0kT5zcYvWswaBtJApnFq6nFJR0IrAnHkL14FPd2AksKxLORHIsFrwgWBHR2e+nz8+FiVQ/p8jyVexVypdWrkVq7qzgtin2vPL03dP5sNjB5JstSCSQnO7OVneG/PKvb29ml8ajWQ2jYdFB5TWfO+dipT14HFIVWpwJ791F7vJ9eeXuP9CEGBjDJwZXjlZ3JPvIE1tWDoPwdJh4KgXQKd2a+InqSHCNr/8sjC2fKeqvvXKb6U2795vqNRHqeCqjT3Y3KQQ+7OO5i3nFynG3B4uiVNptL6xLuIM6/h8n+AOV1BM4frv/zsc1ihIiC8xgVcdLYaZGXCCAJ1je0dWzTx9kMZ7H3yZE0yCs97+WhIjfX1iRPbtLzaCeZgv2nqw9c0FYZwRYMHFdStPNYTXI+nzrrQHZzHBIrazcD04/KC23DUiRmyrEbrjd6WYOublAHKexm9CqNO3c/57ctmcungx+dRCHVOZzf0nmhvjpz7IYf6mQXxFep2CuqxwBcM7VA+YTz+wTzekgrbFD6VlsRzvGkzzhDDlymTVA4mpWKbrh1+K0wea58p6UJBWWIuk/AO+lZRkxfCp4sgy8TWVs1E4FSnZAPJUzIfSJIajI7KG5bkVBc4RHj0nPrkgo5nOKelXpkhuo4vczWta1H/qclY3n8yVwgXU1sxb2K43UQAQ/4hxmqgg+2pFX+pv3rJRJmrzSFApwxauNp0Y2eRzZHJtttLGySrXF8p2Miwn5vAKG1vS0Z2yA4hUumJRYThJTDlUjBiSHW2x3bb6qtzetKmIjRG+ZhXvDypwVtULHKTM1B1gUNqB7coiDPBrkrqHVX7Rc2kShzqDO8/PVK25EBJAT8IlqhKk2xqU4a8e2NkzGrFfAQKL1SwBUbr6G+mF2wR+FmgM1DhrXkOasG/eg7/Zqg3VVdnCQqqXwAqERxtNwzfBF77EYPd//5NZBDQcB7W/36UixtfGrI8ZuwMKVhZw4WWItXO1XDENe4bstWo+5QGO4xuqr/QABmoe8aubDnZonyXwwA6xR+dKAxPlAOwKUDJsV0liRGKYXw9Iqu1D0Nu7oxpxeaURihZJ8ji5/y8MuXKE8kNB3z/W1kZnrY50UhpcBYXX8qiD79yfUhjxkimaf8jgl83XA4RMv++XgA0Lrd8VZD1F6tiDvnjCuLuP+EIeo36mXiv4jTABOu5Sw2VAgG6WgPocas8ZFo1fhNIc8A/Uwo6WC2ESFHD8oq7H2eHf3soFLzH+nZsEmMma3ciM+foUIHAoCHoz6qu3jVGeFmRuLqUmiBXJlRgnXZ9SZA8WXL98cMJH9uZ3+8qAAOuwJymggoja7k7vWHKTUBUhDvBHzLMnb/O0/nj+Ikr5y1L1lfg7ojloy3wvr6cKSVHUGWZ9xje9NJXxXht3VjrXEf2CuRlkJ9E1Ji7wqxaQ7oKblG7tojYOSRNKID2yrDbEc6hy1eHuV4qWewvTz59bAhsztJ4zGxsO2qooqr7cMiVgsOuRzL5jmcd3gtBuFnVucYW/GfNJ2rCI2Yljc/6Prta+B7pTYdGRQwcyvfk6P20HtcQv4/giPmtN0914/esQO1ngdIqIV4+O4IZ5lC+iFspOOkzAPPy5rF6vQm92InE8n3rR9Qg2PAgMq0gebh0B2METtFKS0IJ11u9fFJRbpNj47AXGyKnAK4RQi1IG2VwDgAjuJk1NL1kOsMCxnRW377NLEo99S7sw6HA3ncZ9RYopqUG6jiWoRRpKXogxPWON7Hs5IPyq3LRiWQga+bdc3le96m5fUcDe6G00w79pwFc1rZCZQ0Ij8X5XSHyiSGzVvg0QQICU5eOcjUjeWeZt03imz+JPmGAqQmBSwvcE1K1KbNTZMo1qZ5AzzMKU8psiIv1MdbqjKfYLp9jJdwHDqr7h+VlzqW5tQN1CffyQAExwF1Goghx/K1X9NcsP/g8X2SxmDm9BhwPF3S5p7dLGvdGAA51aZ4mHKFti/Zu5OuXA9JzZajIVv8QRQsg5kjM8r+kWXmpRiHYediX/IiG7pIeS0ojLlCndz8XPzl+3ydtQhrhYTQjq4Lg60QlvSH4B4Sz4vbZpQXB0ji0FS2/yQSmEDgHbRyFztcME+Hath+zkrTvb9zGjsjnNQ9dnQl5rKfwugFPXPG9WibZ2LpcUsdO2a6yI9SI8KSP0yDY5qGCLFE6fOjxQANKosktQNDSoeCekXZogg3Xi3+HBuXEQdswcuH67wlMRMDx+oZDZ0V4RRSqntxNxP/hW9f2g5WclJhAd9GttRdJVOr4kfe/RkTw2++vVgHeKK3lawnTCFACi7Ckh5dOnj00kLNrrS6EINTeLjesmUyugR3YLY4NeaxTy6bNoBl2EAAF8mpJw7GaZWx+w4DYEqCDkmKlYNjZUyaWUYWxtABbhTcOjPPKcwuHlt2jI8Swp4dLDN0zoDE3BDjqeM54BScPZWALNfgxEFt6SCMVLZuJ9VV/HR/12XhxQPLMVIFN9477AgwbfCrOCEkZ1WQFg67JO/gqj0dg8nNYTHZ2mqZfGU/fQYNcbp/2UdxfjzQRwST1MFGTtWvdZQQ3rW5PhRoAIB56rQY82YMNyoaLOxJ0kxrqiXNF4yrpQAhkSJf0E9GWS/W4xoD+nvBnnm6jBxutmyHEHsoMVVOuoSvtdy8AQiTWzo7YpiA3g7kQO4cRuboLFDcZTDX3l5LqvUIbzPYuCuBdtL76HRWQaYpjK4WjSEF7bZ8dAZoqYr8MzThqbgLMoehhYWzGE+Cw4Nz3LX0RKGux7TJyQCwOSYxV7J0Dr3Nv8JOBLTFRTk9Ab3Pqf5Gzx1Tk8Pvg7mhCiV53/XEvv1gqyZFN48nvE1M7NfT4DY9DkTbMCjOkF6/mideMaUlqd5iorzo/+wvv9C5vfpsvtkDFwBa8jO6ZuhW8IiVHdt+iZ0xgAPcmAzQvg/wHKiupjZR4c0/t9qLbSw9XtpFgP4uRhCt4HaVckoQ26EzUzgxMsAG8KsBYEXjyfzph6WaMdydA0sqO9esJXCUHgUpheAgNnzQ5iDJ/bb0jZP7xg5NQ65mFG6KxPm9s2MbAOO1AZjJtDovnojMtEAnthPoNxqE3lFXHx3kDr+vTXsXzfno9yQWtQC7ljQvJP+vkz/+7hwCkufx5a+A6UKcFgjCUNjjNkpdrujXObZbgUqIf5YLr/uYr/F4KhGDcvjD/UFQg/eXw2vu1eMq1p0OEm3boAMiP3gDYLPHTK9hqQkOa325jMbRFR13PwCg5nKHiFVKOFGqa8e5jjrsABLZR/kfPE4ObVWIUm+k7YddF6ytWnEJ4878omK6msACHyDRzmGfurttGkqb2REqDOm/WlTEKbXtabMW43DfNEKLKdfmExDNEiiWobx690j2q0hX9wHWlHnaAS1A+EYGwd+M4o/+dyXfAFFokX0P9tmTGkoipQ0L6PZCOhROepysMPFzwmgV7b3Lpdn0h31gOjzP2PsiOE/DIN0doczVdys1fVoP7ECROuu5oMYUTPsu081UbmxprRbeYdRSjQ1SfjVNbWkvBqI1oTqaK+6i3fqhtUjfKtmeSbfqBRyS8+WWf9dQ4HrkU+39Yjj3nJ+O7aYuGE1Dnb6v0XPwdCk0d9nLzz2RBHbwbX33zflNqLzKYkJr8vvi+rvVWFTuOE7PAKAMb28ByEwbrWeSLapf3Ox+FDIZ46DSsAntLJKgkrNIPUnUjeKCdjQoR9GofOJeWVYpbZHMFLb1qMvGrUePMJdRMbDa3KHQldD86uGhuAra/XGChpXKKoKrCgVgS4nyOdt5+hwUa1Lro5spqKVDRn0ooxGA38Pgj5KhkGNmZDji7d2K0aCjxKR1U+yilN/8hfLZLv2HzMJ3V933P6nBSQn6wtZ6xIHz8offhvqogoWwqXarXrjO6sLOGM/XMdueHPxWoWQFTfPYO5Ki2n6+khuOgPCgKCE/eFCBUd8ye9slEYdteTirSY1HQ1QQ3McGtkKyminpsaZzM9nYdBniqq4YyQ8r3g4NhG3DjGHYqOk3R8QVgs+GWYjB+CeXSBzJZmlivW9bw1fVg2Cg1tD/jMYLpkiT3SNHL5rbYHiXx34MCRScAygfJOUWl8ei9NVPjPKbQeCJTkRdW7SCx3DT8dT5JhkMpVzVemHpKzO63VmCOXKUiUqBjGuWTU8nsQBVzMpVTY17CdJ8kAhtc33bJbzwO4+MXWlkKQWlRNpzFA80rlgWWRjXUOuUJ9ihzg7FZ+VnDXxCuQm6vfDlPtpbvydeTDlTBvRUE9m0EnzErAH0cwIXS+8tLTq4XvfAOZtE0Lp1LHak/Zz0FzSMWyUvbx1F7Ub/nkLf05NlTozTvF0Mkm+GRj8XHZqnaKJy8jIaFS85srXU8OduIDllEXBulUsgs3LGvfLKtfqkT0+6ftt+xtFnFEXKhJxd2mdzZ3d4PHLmNey1gHXZ4G8AbyldQv89fCWZx+LvadGcxVMOesLQH/+6B7zF+TjTtenzFL5St+bkCbgdgbGpfkQAHeZV9NMicD/G4hbFM9YsxtneoQqBMEwAJ5o/vs49pIcKQ2efKQuVBA3HCYD7z5Jv6zdL+ObT/z0AaFKhQYjioYQDYMqdniG+IEQPO3lR1/HgEbNv0Y+QV5In6LdqzrC+jHrP0Ue1u4//at9dVzdwuRNz8lecc29pBRSLiaUtAvyLkFGPKBUhXloayztxOP4sI21D4ASfWKABQdqM60GOUr2H6ONSpJ6YCsES7ie9Ha4IanIbHaLX//13VQEdIQFuiBZrqNJzPInX3GqgYyCSuxTWR3iUNaxyl20x0j5/FxxEoecvkr1GVXZkE9VYkmiu8FHuSljx6WonqR3I8PyZlqugvJu+0Cj98W9TYa4MdzCSgYlIUxhlQFMD/FtLbxhPmVseBR6wqe6nwqg3FpfcUVtlO83wk6m/Tnk8ng3KULeRFnmQ8ykKeZ01sqnjB3M9OvF53j5ZrLV5IjbDP8A71YInghEcjUQHC7B85yD0p0nFVtoGszq7ar5QGmxfM/1HuPBh15pWCqGqhxUbTi3MAe5iinXpIiS55qjnypeYmrDpH2Hu8V6bMXFC6F8PHqks4Q4ocrhP2+BapDiyOI+pddi3a2RxEkXOwTDSbdRmUGGNNXEkiX7fmNgOls5lUBVFRfYA+Ay0hnF3GFXskWWC0BD4xgVj0B0WVO3+YBX4+a9PReaBjLUZ5UcG19wCzSW+RBdkxj1nlPfdnQpFKI7pL3jQb/iGGBxl6mfCg/vxxj423LP2juZEhxE1ZdGSqZQqffPLxbezH9k1myfVePKhESLL0yCJpdFQmFgtORftYjZNM2ACfUG3/VAprl11yJqd8FkdmmHwH8+E0XpvJh3klQszYlJJJnbYCjDkojTwkZpE05dk4kmMZMSqCDIO3mHGCCBth9423CKOc10zvb9Xm52kydcAYo6AdraRJZLR6bzKUjplWPZDi3rIBsSG2GqbLfLM4ltf4f+VgwoLvJWGRlIUV44M3St9nj/ztQQsjeeOkxgnAJNyObeciJRBQ4TzqjqgR3Eg0kUwQR2S4bnzXEFUts2Rqdf7Un7wDBUMoBg/Oby2AketVhQR+BdDHS80vDC2d3uEOH2q5oE1SgW37Yw8i4W1yVchXY3MQT+jjACyie1VAsorn5APkM8qTUbKFYswZaesVs14kbP7HtRpNtwrtdfXBVBz9rnt8O1ZYcw8qgmdokEUy4m3iIRpuSexdynQSar4tk7vYQiRmK2U6Rvw6QSyd10aBdfgdovjz6fASqvMJT8n3MjtyavxST6+VtioBKhWb8OqAznoJ8QOzN8wxUug0tWpDEjJcbMq1encAb3DUPzhJOPAa0p0iz+JeipnqsMueoPaSNtyjsIx+ERNKMJF9M3csdRWDzWHOvj61z2Da5V3xuugnTjn0p7fhBZSSVbUZtvYsDJSh18zCW6ym86DzoJDOCWdcl5PVqn5iYHAAGon4fCACTn8u4+In9/347KlnEa4OPS7wzfNR/Yf2Kefa8EETtXEvYI8Xz3VjdReKkC9SyIrqS3d4vorRIpg6/UL3PZ3zRaeqDAYMbl+yxPvSKtZdyTkVQdcv0xh12E3m6gmihJIcufdcA6ODVCzh+JSx0HVdUkHkVDBehCdk3V7eXpy09AeaW8K1GHusgJXToGOvbSdfz9zk2H05St9DK0u6+pfTPSl5xdodHUAishsmB+dMiZEv872YZbRXo6UAK2HscRh60TxMOJg4L4NynOgeTWi2wd/wgzJKr84l4z3tPAEwzVCw3Ppxp+c17ejg3GC6V0EZBoNrZa/1FW8EuZ/HgfoJajNKY1sN+SwWOfkLmkAIveYC+Wd5/APYZq5Tw82LiG+cM7oBH79d1Fo7gdjpDssPU2za2bp2up99KbIvvUtOlays0YUSCuRu4l4USSIbAnl+jbYMtWTkzIprsSggEs1THgcRqQlA/UEw0ojexqUlKAcpuwca1NdifnZ1WfgCs8gX/3+j4tvbU8ZarZg/IiOGwIBBhEk6KrvWbQWg7NH3idnwz+iyAMLqGGimBunyZpV5ksRQWzMgfqMn6bI6o7gS1Kj7EpknM/WJGAoUqm+yE0ncafPurHuQ3AfryZWmZLa1/8MRHuHrlpsztVFPL26fN0zHd846HvZzBechJUSGzslwKc6QBvw/wI+6bTYWPoml2ZHFBTXcrzzcchLP1/fNihFVInuYqpknYDtg0a5dsK19S5lsV6U1YhJ6psAh3IR6GmQjjnE8lnhygbsmjwzFa6A51PUexvwsTBM/DK7QiM5GPzdXmGY1x+mMAQk6hzSRqT5we7tvQ/fWytZgunvliXYaEnuhhRhJeThacISvvMVynhJ/YeNexJWiuj4U08KMzbgh4Y3YSfQarl684LjZq2dpo6+kxWtDfitfbE7PabREXrHt9HNzQEgE2dAHdbgRhMbsm2GwEOkD5ogb/6Ze+RHtXfqeKhifexCmCHd5Uo6xQ26OMCuTFBvY2DdUnSP5rCD0/jgrwFPzwWv3/Ma8naDW2S6bJ/Gwsw8r2CZaWz5eizEXsOwjjdV85WnF1RKL7KpuBFZAorhAUU+ci0ZbaJZV7E+tzrHwmfGSBZ3MOFeC5RJqoPcAMbio6X5h3clUz1N8vzazs+phScuJqFeY8J+8D9AZy05byrXuAZZKyF/LHmTKcQIhkGEK/0DMNF7tPXZjzRVREhu4cGz0ZgOLk8I5RKbk9Z7u4V7d+v7G+ulVSPZ3dfVXyQr0pG8bgse5iGIQ/pnK1Dusz/UBcba+GisQfSjITMR0vmVmqZ16NceAyRnpVNLmniu29Dxo8BxHV2wNRSkrmFckztiD5XCgetytYeeykk28Wj2R+zj7uudAMSwsFMtKvXy+U9JDAgefXBNPx34lc83hXhu3s+qjPwXx50ZWVQDEsBE70llihkVeHi82OcmYkm7eYLk/nVeY03QeXvGWF1nTF8CuhkKQLR2qTO+ZfwZwxhuZzxgeMLjMPFpMOEIbzrxx59pmCHAFKb4B+Zfqwr+yAEBfn4yvFQviR78k3wyheT/4arSOYHs2PsO8x6d+WcK355aANP7n7TudkeRxCUXq9X45cizhn3dOlzEPxDqfXmkt3WWm6RWmjf05nFajDN+91oUdNXkqsJnOp/3djlb3eq5YSHZlP+GClcojeKuIqI6Duoe+gEdIRQHm9z/2A8J0nJ3K9MEpUgCoGfTS8+AEmxkGByMNdh228MszTMzLffRep7UoXR2yTNT3JAND9GCyZAN/5tdlXqYI5QKM3xuW70xMF4VFv0zjl/PG9OMT8XRlug/C3ux/C2uTX4Ed/H3PqufyyUnSoYSWIpl8hm3cKpu9jwtwZao8JEqxnwLQUVNlxsf9jyMn/H3kBamFSz/xG2Yyui3ZJaYi+Iwk14UlUtc0whS/xFWcIyXaH1Mk8s1e1TVLAhclJrr9tg2J8qIXeOfxMTj0zlLwCG30yTPlFWIE9cEmIEf9t0XQ2w2CDXTPKBi4kRegMJ9PW75hDaoD0zzx9kfpNXFoxjdAfLZSiGdbp04CjcZ3WX9X684NKRSoapDIoMH83g5okADGXMVLD/u+BUbIQ56q1ukT+fsVc2bez8ZPVstnnc/rMSt2SNSvhYiOFlEexISqHJTmK3bUf4a9Y6SJ4RLysw4WkOaszgvh1E3EQSwt8aXW96lZhRRfJiUKrLJJ+c1ajZEYG5hM7ALWQtq+fASHKMks7nAmIWqzEfTRPjQzA1AzTQ909WYMB+xOuKvs1E70bEs+QAZTrJJeduxrfOt4uVfsmmuPFeZhr+hD7Z8yX8EYYe3E9owrVxDvdbM6B9DIRvPZ/uD5n1QoK7Rm+BQINgK9GOfuSiT2/knnEXxt6n+FD0cFqaSF715n1xcrPP1q4pBjBXu/8xsXH0pYgs0750t8aCTAQ82bvoVd3d3iJt3uNIFI3sdPeeLrIcx/1D74a1hYrtIxOcr/oWCnR4BBnKpntQywEZdRXmdeLBe0c2KDurJ7n8amdPLLs26TfAjb1WrNfUc5Rm8g/lnXYezB8fSRxg+FFkXvvGYraNsiOhVKYe90QnAIkYQVHg+JgCYKwfEpYD+83faW54/GNZWsacdnoVHU/RwJVjY0h4bB+jU0Pgas7Lr8ZVGpF13UQWJN4+faJw29M14WK8vh3neORakxOkcd5nzWXDceIKaRqq0eZo9zDbVGpGu50vqO1SbQz9noWck8dXuHMejJpVCBzzmMYug5xzhSPXR43rVEftoCTKpNa0i/5V1cq9tmbLYeDtmdTd9+CxdeOP2j2vJHP3Z8sPQBkfl0+YTaJ2PbM8jvz46Tu/brcDy+rvGMQLLb1UQhRvUs3947X7SNjUfVx2QQmgcoME2rvldN7zRXGodbLDLbb62pWcFtsLpHP1V2tlmaNhFpzxz2HLvrYwAnUluvuD4GS/KzfU5tX3fmpPgL0qebpJSN4Q77CdrbVswApY1nx6cgjKtsWczvgGX3Rzk31QgeOC8HmtaDjjsCL/mx89YpNPKypp1eCugEyU7v3U0J8aEL2chOM/K+gQwmgqX3S1Nu3Usoc4twFPwFxbBolKVl1vnklw99GZmjyKbkyrUNTxInv3z588g18O9skq8NGoOxffVA5rdLbPOVHK/QvlnXIL5Y9UMVvfcTz48moWPAZcC2WqGg9ROhKIhOQTboaLAqufNk0HZE4iAObtG70aWJx+jgJJq5IB3lY4Eo3+UFPKiMVyf7/VYdlIhufzy8wd8YtPdDb78Xctpvj+wl4XAIwcsAyXfu+hwEeAsf2Uxhj5Cwspt50jbR4Z0Y5Tkv98+pbyBungJ3CrgWUpnTq8vkv9s8h6GJmGWo1L7HRXSvWmPHXe0PkVl8tW77VCKbBEylHYxxKYYlvfsVdkhKahLFL/nEax1COg2JebunOSnfK8l3v8/Q6kIJhDd+aFkiB/MyJ6c04faTV+0afKgNsA+sKRYMuPVyhQLxHqa3YdeomLeWAx8ICVtJwNoIY/Awt4P8rYEYDx5nU8wcOdwygWyKM0W6BSZdPO2+BCMbsKExXZ31SA+/C5GccUma0z/X73cAkwnNm9ENLBQjWqDhbCVaEX2ttLgr/q9fp+KElMr0vYdvXLwqjFtwmAfKHQJFEpQ8ppG1yqCqN5zXqSqgJUzJdHC3hQLUMIz6zDlU0+dNTCZqqpzHIO2blKaZc3eZUzdu/1Uq0OXu1rnrVtmWXS3YcOEbbyXtdimCAs1V69Nk17FjaorVBxKLGxY2Log4E6FlXlztrUB//dnSp3KL2Is51UEDjuy9t73QMpi+Qfs1U7i5/vthCHFep1h4ryaLX17I79jPAOQ0t92VRdoeo6RpQmo7uqHUGVKhnqajx6gqhFZ8TTzxs0Cn3YN1YqHB8W8X0lBWY/IdTcQ199f3Sb260q1EYJqTr9faY63aJWr9Ln0mof5wxF4xWaJVePiircbrN1nYfFP7RYajF0h3FCDiDzKOROG/mPnCIs2zDtxvRwrOTjOpgZJnta1SLrasms9pKJwB1MwU8M9W5Jl3jbvobo3N3QX7tzmyvqLi5raQOEmCogGQS8SPqrozGfDoPQwJS0+MXy1H4+H8caaypEOlBmq+lIArFrmvU7UpxxzDga80JyABi+S3e5alKrE9LsEBr8JcOw0IQfA9/zGMi6RaaiapCwD2DlkqZYiz50VSwmFc8rs3XO5+8kz0pWwMKwKM5zISEMNqeb0H+K1o7jc1XUx2OgKd9XTC3jClvjroS84pd4t8xI35hY2L+9Fj0PmlazsagoFfwRbN8eKu5YtK5mTprU0ITM3unRi+weNfbS3742xFfncPp5rFmwn+q3pbOFYn5Tx1PjQMoscbIDYem+7gVGmQiaPvdN3jU9vKsKZDgXiUHtWOGv2sFmYAElnlyrf0D66JU7Tcu9pB91glY2pnRm2ucV4f9ZueHaoaXw6mor4qDV6QBv0J8x/TnQ4UWnYrSiEMoxvVNF2OLw/tCY5ABj7NCfeZvkrqz0R9Q+YxIlWAVfXrXK6X67hPIX5M9uH5+X/eBBZW9KKaKbftS0HQN60/VLl0RPOvWIXIvyko46n+DD6J3eDhDXlID/baJq6/nj5g9Mo1+DG7Mu3Atk0meadthMELsVo5ENuYdxY/5QxLpvqRE1lHdUji4iZjycHtrM7tiC2TXK4y5rctnQX4MoMdFlRZuf3qWuHhofFKSrX81vX7t47MhupMm4S8Xt5nkXauz53KSCwbVbATNDk5+WNK0p4ecbln4lzL1GIkUzbJ8r4Qc+4yFZrfcy/yOMULMYwon1n0DOh8O8wfFEWNTao0nEHqyk0X8oiia2Q+aM/Ia4rfwFXVyTTD/oRqP71CHA0VQxalDjcrNuQVNGnRnSK5uT9iR6f1OaOS0qDcuLW7iVxWb0m6BsHUSI6fQ2DCs+hXHtsiXDPg9DHdHfkIUBoSwTMfGRM/CzjITGz23dOlB5RqK7FWNtanMJpgUbYCpmBqV0gRW57VdMm1PGtoNzxigBmgGinHuUx0RDi/g0QoU+/rGI2mfsIO4RV65DZqgvsa+25EZ12T5V9N+T9VC7U42LhZsNr3M9NZZHHAIkFo0oh/mkKrKLScxaNy8afNZvASXy21HbuyvoblxV/k3dUexRey7fScTYgefIqtIQ9WkAfsz60gJeX9p4NDhk0CICp2VOG1ubQOHBEMdHcGre+4ENEcCno1Qo3f02TmdFTGTszlvtjNOoU2ZU8nJdwZSWYSHA99NeN4z6KIjdYoYIKjob+pWNXRr7e+iksWUNk7oJ+N3c9WCW/Aq6T6xGvkvjH8Aj62gErcd1bRgyh6D+zchTUyzzKfe/NXfHaQd/If00owtXgTBEdgkXA569To6NUvDK5AZQfySJ1lNO3eT6Xbefo8CrKM3MMkVuZc8qrrTR5+ZTQHRu9bR17zWrjaqUlvwyoag2+jqorHIU6anaQXH8Xpk5xhRJ3ICpMZnB8rtm+G5+1ZCmKo2WCjnC8Sj5sEdxxSe1MWZmHa+FvyqZk4HEK8ero+KerWN/9C6ojfuezlxnY2HziAIK2pfZrsEPrmhLPsUn5gcQo0XHvGD5hL9g/JBBvaQT1rPgV37ZHe24l25aWaRsEb44jHLoexixOOOdLvAD7l1jaO3g7I0Zs8NV424C1hzWVmfNwGTQMTr4GvzwpNja4ZsxE2veKi9XVz+wK3EzO+7ZdqeeOrN4QGQCyLgmCBjMifBKN4Eedk5sfflo3DZ6w5GzHGaSlMZikbffxzRp3uz83C0m5/QmFpoOJye+8bODrnSiJWXqzj7DPfndsHFGMC/yKau4+a0OR2NlcrenVrv//yKFRr55V3xTTmyb0DSABH+pnl7QpeDIEXIi4mibuTqNKSBHG7mkVI82fZoQchBwnsXfryvQL7RGD7jI6TvzbniXAIGb/C5GdtCkWovfenKtRepJVzbFugryGM6qLWWBhGMrYXCzNm8AwK4AhX7KFRQYB7JE8W1R3qiLIhkfuy9kPkIO/eCgADE5vscgnFp8egEzyGnE+EQtGBKyEalpHD72iQYhA+h1iSRWvSeEIDaoYW3ywtxraNYPRj6PbhXV8Y3Ch/4ZyTW4SqGQti+Vn4NHuL9AjtobuDOkFz1EFGoUkjOfvItMQqhK+yFH/2vTb0xlyxP/wbGRGHNfZpTV4aNYFkuG+w5zBJUzc8fRw2D8QOzC9AwwX8q5vQXUfzdopzWBnQ+/FKIXEKQ12zsji7tO/FiQ1jc/2vIJ52GlZQrlWPQTZPDzlKnKIZxOGAVDxOLu8IISBFgMYe96VODEBpZSvk1cvlfVAMJNZdvDGGbuF0bQaP+KGagWpGOSqjBS+pGjNj/vLGhaZUaa27y3ukreI+JyGbDPbh0hPyxfY9likxw6fMjnURBumqwQ/ZTolgZ1ZOaJQLQS3VlgmpCBeLhmw6vt/2hj0mGwh2NZQZ//Znrf/BgiA8FG46fJ7cpoavlGCKG9nD2RKOXIgZdgW0MNNosEY+uwMa1oN3JZYS6OxupJ7ES9z8rQqnl6Nufphi1u/MhVeWDN1Nnh+DzWqKu4CX7K5utVUqN52FMSi9DEp1GidnDynrKs1dDMOCkZWAKAnoJhyHaIAglSK7bQo7u+IM13TJY7llG1Htjdn/RnfVkOxwuB+vPxtMI3G8MObmf7eGHxhnN1balZiwWLFzU8iaSIWKMPj/S2KP6y8sNclDVCUUv2lWEjyHv99EeU9qBbz7uwVkVL/R1MmdzTOdUlhewLYvWkA98LobSFvi5HCqOsAxnWhYAZf87iDlmmkpq+l/q5H9Vq8vyXjyDfW4XZ4Uk2bPcTCAoOcjSUWo6HQbv8vt0c43ikx1bloJ/teRV9EIIycImpb21P7tYQOZKCB7oE/RlmBI2XpuhKEyhV2o72FkRJVJ7jV61aLZa8NCad8ewHIQLKi1Cc0xJGMOXl8JrPr1eyOfMZlhiMvPw40Emfce4KiQ3v94/eBhnDYWBbCpeTZMtjFG+y/nls1hdm8ryabPQd5T6G9H1CAnilxUqqgcRHc1q9lp0G8YzozMPs5NFqutXszSR85iFYaCvRxf0Fd6kVXYUDB0yJZyK4MUBRrD2XmQnFWfuf6+rilH4q5SveauwG+JgEbVcKL4pcGMgRzRFYMjMn1USAUFBfyobCUGpEUoWVFgtblw2BqsFaOsa1ncEjbEqRSngfWfwFuvqEwwMHsN4IY2KGiuGFG80GK/m3YGzXJVO/NOX9/F6UXXt/77dMFZSphGoXXX/OzsJmW0BL+JT/2lEsLYLnkfe208KTLDcfjcbL1lNaPNUh2SctvBXc6Jz+vk6UTVPyoXQDcD2+VwoMn186MeYBp0cJZDiq81MWXHEq2+0me8wvqyM3IPGXe8jLb4fmJn7T8PAtf6mRAzeVra2ei75RenselDQ0sft8EbrtIMjFhGSB+ZXaDvsKnaGzBD9qxRqpG+VwHvC8nd/ENye3p+t/GBkEbpruJetjhf6rU/cCWImSuzkCiJhoGtg7Xw5LMNic0hL89p/Btm8qoNJOFdSzqldfz4UJ1oVsNlMCcP33A1OIWhGtcllGmm78e49sla1yrgWfv4Y1bjbKYj1je3GKDfU8dZSi65VR96nEa28+yaYIchB76IFn0hIsyYktztGHMPxJORVL1F5QWB/L0OQa7svMsIkfEIAcgZRdzRBfYlGyVJTlvZa1p/6IPGD7nmDfEXnKgRZmb8OU2iskUuGOPzbbtnMv75C7Xu+TnQqWhbEkHWXD7sZ6Ir07oq/ptiq0Q3mVQEx3SF7vcaV2qbQ6ik7hVETySS8Az/Cl+cm6O1Zzgc7pX9DRz0uHphNfl/eBVIV8acp+6yaUu0hRt6n/DIc2V1Tt51jNhQY+tnZe1Pjm3rhPG2JmLnaNQLY0jW7SbHmfC2eKqkwU7noxVsLj+x5Sft1yOd0vrJmeWd7UiLcGaSayBOM+kqky+4Gkn4xe1xvJ93B0XP3OwgHgUdxrtYVVkLmOMeo8jzbZ3z4yOpRNADyuDk84QUI5O1jh4AEW1sLJJ5Xbqwc45ThNy4vip8unEZRHyS/kXfFGm3oqTmxIoWvLZQdDTUSldKkPSmiPjqIs0ZDZ38yQG5pd+6IuYNSqmHzUaERakM//EbB1a/zN2roADjsxyIIegTMDbGc5d6WWVOJvZ14qOkWSioziA4P6izGfCF9UMafN3LgAYpi0R2o+1UDNzq3mGFKxVUbFJZHnbR0fmdSYt4jiHdT+6DELQubVkalqEDIczYilMSd2P5oYcrCmtsb96B5mKMFwVlyRClrdfm52okg+M7ki/D5quaH8vpvQZpMbEDo8SL46F8oLMc1bRBc9xaBxDckw8O6Ll6SNSxK3WwjHc5Lj3mB5E+Bn/8TqqU6SeBAuAEovStSDCUGFR5KCL6qiAfLIitl3NGPElL/8Nn2PC9QyAyUH9LGoTD9zZtIzvuBWTxs8GzZwU76O3w3Hx1yoGcYuCrNHmu2S91RtImXYtlyxtHt67DLH9sHcrim+TYYKr79M927XzuHulYbweI1SwQ7iMjCkoAz2T/cu2cFjgvuTHYgwXHvLg3wg4IxHlTFK2kt+aF2KA7kjLON0TZvQOALrX35m1wo8Y3f7FFHbFgcMfhNdb5Y02giKfvaCr9jn/7ZY5lZWsoINvSIFwxwl4+9UMlL0fwStEHZ0qWeWf5+HML0/aA3saJq0FoTJsgN3xUAdtbD4gkrWyWmPssg/UMuASAKEFhBH+vCtbqZN5Vacud5ou8K+NSutumcdmHOKaCLCYv+Vl73UiwfoLcBi33af/bfeBiLDT9RYTDLpYsyFJ/u9YXSJ4SRBXbOyGno273rUSNAkDpmLIamQrykMyKSNnQwvAVk6Sw2ffvApa9VEpd1ELxyzNBqFZcHmA12EkSU7/lHGUW14tkGI3RXOarCGwkLXqKpMqdZaBLVgKIi1BxiQ4BlI7fOkTlGleAqTXZKRzaBSqJ1KnQ3nWKICDtoPzGn+DLcc/qY9fjN3kFQDft00q/KahHkgGI26KkGD7YcBV+sUGOtbfd6CgAD98gaT0Uxx1H9gQbJLgRmu+bDUxiaXiI+TYI1N/9QYP+1jjQGhV709N7gwjbQ3XXHh/AGw5mlZegh/wQ23rmwqYs1xsIQ8RaZZRqu8EnHSB9ctyQINrVVyp3Hu5FXq9EDH2sXml5XFCb5MJ08ncLcsu1m/rmtP25jVxIWwrvdWBdRgHVGf10Wy+GeEaNdnw0Ug0vdOqeXIM7WdfdshDLEUcpg8BZKpTkwqU7IPagosdrkR/UtppPOZJDNQ8T+C8HyC500b19daWIqFn7ahT8/mf8cWZbxnLjO3KreJIrJjAx4vWXbwYxg3Psz42gnorewSVgukhdzNP2xBp7bcvQmylfMSmDkU/xboWKlzxMGu/8alLNZKexBDnx2+wT9zCsf5OiPr/9nAzuVi4rybmj1l2v9CHCKAQkQfEfxTrCzferYNmAeaUMFik2nHHRVLbo1DR2wb7uLsG904htu10yX+8g4F74fkf9q8u4wH8tXt/QvJOq80nl658CJrdfQca/gxYSAzui6j/kNTBUJsqOi9QunQByyKNH9isnZG2qFbNMbL7TKK7cBEH3czKAqdyUW61v46oM7VQghbD03SnQkOMLgPUDB8hqqvb5ZFuX3qkDxb0CTbg1KHcjfaDnX3XK1M+k5rnPSY/PdwY3TkeC1beMW64/b5QYyBn3pqsfn9Q/dK3avU2I91b2W63cM1sh3MJNmz/ZWJWZgXuw2Bxq01VATM56PWh/xwaDe85ZuMknyEEKL01JzxQrDj8aYQB0lYow/ATDvA+oq1achHVBkxy9UnRqAkSQwvgyCx7lnPK4CuRZqjWB/wDENTvam4fw7AWjRlED+I98hoe3OKl7nRdQIp4AQLBv7lHDeJ7sBfDvkKZN82A8uAQ9RvEaYP++vNl56lSuWSn1sW/Suce8D7sVazGxWAFNiLI7zsg3Kw0Wk2wD3yXsaVNS+LESYk8Snc4p3Z139S5w+jLTewxuBmho3esEXTNBwWu6QGBD3RLZHE7NgIvkOiqG5pW+zktfKoXRzX0bTBPBBz44FdNd6UpN/MO61ZEPMLtBngocr5/OsdW70I/4sfwB44PbTCV9scFnPPi8Ebtk34xn/QAoRsElGOmuyLk1PfpUvghma036Lx+70Pca7vEquLg4MkUFHbPBrwwC0wm7eQkGJdrdxJwRxB5TkyAQNGsbr7l0CMcgihWAZZ0jryil3hn5XRHCSxVggLFi/1OkzW1B+ED8qLsARe/7Qgn3QqvnaI2Fm2ibUb/zsWzTeXIIAcF/ed1mDNv2zuPpx0lkb9SrC86WxkoPbLvxxFBFFRG/1V9boNCcXFJGZUAeM46F1uiXlRCnZyfi+MDiwzKUKrx8TGLdfWXDm/VwGnh/nm4CoHDi3VHvG3XREiJn8CK3iNSlhSdDWuMh3/skyvSkFKU7gy9IQFPY4xvaaLmi6eq7ghFrOQRcsKoxh3xhC+Sem+Oom0ALG8rvHIXIclYdxPlC2NW6H0zPOQk6MI7YcKDitzGUwGzG9TEqrqItJTftLzkDlk/RWdi8Q0xD7j8zQAwY7ELGD/iAValRZv/YtKlSj8UFctRb1fsMba83SCroC70/68jmnGFqw6KwMtOR49gD9w54nLxbjXoAvIpmLovGqZE2JpfCAE4zxwe4LAEQrTMNA2Xk5NjDYJe7xyj0XTSHvMvEdxaI1b8Es2uR+SljJcz19Kvvw3X2/J8BMybB+iConZQzMAp/TrbG9ju7rRt//QiCVbhq/16aeX/HtHzMkJ5DB3bF+dDIVEobIYVRhgnJulAVFqYc+jNDSx9ArxBKJyFUYIrSa0J7zL85q4D52fmIRsO3/qC9c2SUIfO79gHFZGAU9EpM3NzPG7hn3HzfbntwmIWvsptztzYFqZQOEwNGNnbVAyPkNXMA5QOA8VPD9lSLyMvfWlKYcH9w7dTlu025cU1LkJDyofxLnpa1nib2tXBOgc9imK7YSIgmk6FXwQkSFQ58t9QWLjvu38AqDuSsDATs7hZARgQL1zDrrukyEkMXB1+RtCdmN9onlFoh43iKaC7c6kwiQrqjYS4sZMkVJeUEPCIZA3VGh0hEQRYkaddUOuaMD0ckpK0JdsLqgNv7W3RR/+/Xvw5ImXTfR6RPQMuJNZoyhL1kX5Dp0g8rCXIaoUzs41wDBm0DIWy3YKpDQscOrLXsa4ljdQYOuWKNBlEJVeQd5bWK5iPhPm+8YPJp6bG/NHWSqCMwlVth4XkmubJIM7UbtQA8ZmIny+3SMfMa60N3csoT0mXJyuHkF96MLo6FoOVK3AgYKAbdsDkybXVqN0C7xkVzz1yG/0zk/rZtcHTOt78Z6Dlt6xhSLSndSSqTACa7v5Q/keJZsSu7Vo7aw9c0DRh9K/978SXQI/dAFlCII4aNyxO4a4QUnblfPKBOoPxFdWhYDbaBOZ97Z+IXtQj4A8Hhi65bCvcgh/Bnjh1M/ayt94oxamGjwoXN+RfD/ddN/+zzjBOQakDMsB4CjCf4a+cnWvHB3fuLPowe5S6IzBHfjALD294z0Ww6cnGWv+AbEyriwHhkN6DMqKOECZJO+FZ4SJKbaMtuFWZ6kvJwS8cZDo7fDcEXXk/+pFHdEchNboCMbfqdyn+DbI4Lc0l8phBQMikPyODONsRSu0XTOaRDmF9W+Qyv/izbV8ryAsifFX0Dqm2VZFKmZlaaMo5RkbcoE/b6mO4QK/fTz7U2/Cg/0ESSHSk0OACHSlwTkqrRR0TU/+O6hTX0/AipxaeSvzQq9TyeKobMn3mbdk92FqtsmT44NO0NZ83M37xjcmecSuwfwWrQJGnrsquFf8lfsf0iQcFPm2AESqwATHR8heJFR/i/B7W+Bm/fdw/8ZwPQ3pOl1RqZN7Y+SnulMLWnaJikNrP2mjY/3uCdLgqzPcnjNtIbNnbv7ERU0KTFgnBf0YnGj+qMjDd1Q9Ce2kEBEPF3ESdHC67HPfAgMW3kyIJwL4gNralUauXSfQjFmk9A6JnK6aEViRPBHuq5JbgrZYR35PDUZvkG5pEhK/Rg13hwjaOjlr6YWX20nqqwfztbH9cNHWUt1FfY9Pr/KdncHjsI5QchHbyBYZdhjvaX2OYD9OpHnZpgpzyiXT0w11+wraPmiZv2jSVNuGM92qzhgqXIAlQW+4BHfD+kYR8kuB+tJ2oLOzFa/KmNeAuP4cCbnzYMUdj6BG96X+ra7bBjax8MA3FSvCc9anuC3GzNdZav2QOer+uSVHUUx4/SXD6uXddEwetmQY4d5+SPR7lJ3wLNwq7W5fwCTxIgNmkg4MqsJBzUdDz4/KgUc6f/fcw/R2xDKUc5hWs1+Ttz2grhF4bzD8PitpMZPI/6rIKDh+/C1nXkbzGq9a4sBooOgFPqqu6TMTtNBkWIXfeacpO9+GX61AabzIPkO3kCgyoKxdby+ndkO7DugTlGOm+L5NK9HS7oAzNm4V7sQufgAvVaVpzMLSnxjSbYJFojye4HNmPDmvEm1q1BWeGayG01XiANdGYazMcLXQYKc8v2TzSbbr+N9MviwM42QJjJ1Lv07V9EAf5iTe0+HQykj8pHzMeIRGB1Rc+89rclRjBQWgfGzq7m4S06K1KkZry8Pg+izaagUUTxQEYNtBawCfigfFaZ/APSPBDlpJ0zP6Bq2ra2l6CPCGE+Ldt11u75X1KgxejO1bGzB0b8JAZnYkD4pF6DAQRnwawBnOt1iZn42OpxRd+Rp6fcs73/T7JkfRX2DumRqmsrD4eqTzrH6fouLASvLMGZpkn4E1JtjBv6fweysOgV1man62yEM+S3I5mO8eYab/MB5a0x6rxK5zVKdWXH86XHOLEhyWtZUJMrO4a35801UuZRIHzUO7gWRQhfJpWNo/5s1LhPyhaNlSK1eMFJXAgBJzVKbWZzYn3r5hdF2WuAnzw9iYGMyxyPNYEzzIlonwmcPCfOAuA4odWvnjoYgx/OYhYUx4uVHt+taJWYRAnadShFM77F/T1suro+W/ipASOPeZpaaU6FOf0VdEUzJ5VfhfvKYSKKsZzMTWoppTH1p1/+M39xPKDshi8x6PKhWb7lPitgufPGkPuvU4ojl503TeI5AaHsji9uyqrIsOdPH40RFbRnVrtgXpe7tdSTCoHHNhzcC3lx9SmeqT9K439axZHJXta7KYVOTXvHrCQruk4K7w8mr5uzRh2d3T81YwFLMOq7vT1UI19AEDC2lyx113M+ztK0CuG1jcKh+s4DP7secmWPkhE1XV36NDJM6sYnCTVlR8zBoMpm7IXw4Canim445Em6lue1gX3qPaPQUV5D5qKcqx7dPvJZbLjKdMG80yD80WkZfdJA0aKhkV5h36atLVfOBOVI/F56qSo8+UmqEqE5nAK2f7iTNTaqUr2Vi6BCfpfV5J0yHRdSmQv+SQGgynfNifvxkLhK+4AKlBJi732eDOhiQq92U99j/fX2P7PRVe4EyItD/q1nYj7vJUaAZ/uJlQFZh56Vz8yv1Lq5+F9I16+IWWHiFwGe1ilr19nmiYaUJ9drGvhQRUgG+WTdACmK+Bmk+N9RhJ72JmssKZu1ajZu8PcjER0YRBO+K4JOF8im/MHGqDU9zE8sPVB/b8hEjOW7d5gVZmlt+ZVcfQaPt2R6w99xWTeBcCx22WbaegZ6lWLfGmaavJKujmk/DWmTT1Dfq2BZuUdUn1SJ4yzJQ35LxnhlMWazgq5mIzYbXr4Rj7JDI7tXmKC8zXafSRf2M9qz7LCD4BYoCHu0wQbLshZZbLSiApPHfM3h0n5d+ty7N7P9ik3y4uk8yUVkikyqH61nV/I6I1nAOKjybrrwMLnt/18FPsIUXoguNGxmmHoODaLijm6uJlTLNcBbnhVqrKmcWaMrF4IP2fSPMKun2HniTd/jDKs5uzORd9XIgE9t4TnUOnW4ldW8qqG6Su3VuMRsGqbZCvOpcHqAe1RMgQ7BlHsrEeNflUSLsQObEyVaBuXms+5VJ+8OX5NSvkg1dLsuFhCfKJOjmV/uXW5Q5HFz/PtrbucfqBx05sMkzlyAZcHhxQDpKqW8Ebj6KgE/1jZvy2lt7BUCZScR8oy4dXBcJGuFRScccCKC38R4//2T2sHrvLtzTgnE++EimWxDuEvy/J4OMiW74RUddoU+Bv7quSpleOHCDwNMn9E6tayAlUl+2WJp4McmH1aGoPXSP/gk8lD5W2N/9nbNl4YiN79nvDPx7L+NM3qo9ytpsmlt94TiKwSlO79jUE/QoWIHdO5v+3Y6SeMHc93/IrjqsCo7u2s/jklfSVQkRqQzPZBHPOFhNaL2TuXw6HxZwc1KaOH0DwLqci5Aes6XWO2Ucf6VOA8NqMXSZ5UYgKdUc3xOWQcOGKV+kPQjY7AMCWcFPVsSoN8I7Lv9uwR/nfx+Jwlz1fV660yKzYfSPmfKHY4DVbgbwmuRHruySn8krirItg48EEWKZ2CzmBsK3WzstwjaoKFTE3HYykJM7O1spdX5yqjKDutg/OFxnAXo7rDX9ygSFL9ciTXSeKoNuc+X4v25GHElO9eyPf9GTCHX7rcQGghVZrejp/2GGSu9C6szabovTCKh20P+tOrnAfsUpzVFJrSKMxe+dQvE1T9XmfbK7zv/NnSPKFXAmN8vlTUczdbrHRUBZp7GQcgthwKoDwcZ8ztI2UrimdMb9u6jM7FsLQ6G7ndceDz1VOKMvTFVPsNFvktRY9LXJsOqEPMTAsQWjyj45sCi2aVQmIitO4kp0OxP5o0F6IPkSXVtkksKnog23CmgjwnHd9EAzejw+G/eREvduqx7uHkWd9A/STnfoJQ7cbIWGkXOBc5RQ5sTrZX/S7YiLyG3o6wyEGYsIupIt8d7dKWndWiH9Ig8GXagtkrY7abe1xp2J/30Xg6ZndAdk1DRffqQoNu8mcpiRVz94oRN+F2TQjvM/MdOyWgQCxay5ovt+CjrExPJ6PgYqzNL1tq+pbRKV/uFc8+tczWbP2TAwDH54asOTq9uSDEbYmB9psCZ9oRgY5HP30ckyC4QvfP4PHtLsPYHA08DAzaOct+Q8aoBmuwpV6QDYwG0f3I8T65EEhELDYEU95gnJRiJfPvSATcumVIAT54e0XsqJH0tuUilkwGUYSLE+yz+FAqmBihBs6tlQyqgpCvevWj4wR/r9axMjWF8uN630vSKX/4LCgRVTpOyd3t8AHsEt6OyDBzA1jw73cgXrRKU55jK/sAPJeBPPiidTvg6cXhxTXfnGIuoSVXr0J35elSW3duz2oLWknHlWO90XOSPy4/S5ktnl8CgyFNGRgW6iLHh5Gr0Zy4tvzgwGzrfK3kth5qLOL/wlXzO49mi/u7cukZ7WOsPjPIibGTX4ngHQ0u28jAUFGX2YX5JeNgRxn0AdwCUr/4SVTZzSUfKGASun8PLJQrc+L0Cp04EMyHdsnr3zJhV665kOotfx2HOcTvP5VJlBwud5eow4IsdJWgEDiYvmRk4uoZE8G8xGSW516QBSzGdRTdcXV3Wn7+Mj7JHRpqJ8I8ip5DdJZM5ap/eEzy6x8DxyrVea1FmXeahioEXXFzYwCAoIKxS3l8u1aGQiFK3VCfJ2oHlhes8poU/3W0dc1foBlTZcYibYfo6NFYazLZeVPoJ4ipA6pE11vngawI4yrdKrAbuWBcshFJfh2a8CThVdpcoiAAyL86ET/yV9/sSuryblryJOu/7rI7s2XVtApuS/ASnCY+GyRsJ7BE3wV/cLgfMUyR9NiHS8ZoFQWLyhC0+LD505jaftcMMzK/DuL7H/CPl/4KFJPTymolB110qzkcQG+DzXi6A8bJeOxK+g212wG70Awp4e5tvPW7m61Gib8HGCqLD1zuxDtZ22kOm1iJxe/cTnzprx8fSS9ubrdPucDnfoz0fxO4qEf0wsUJje08Ugu1RX+3U/BSXriCBnTHfTqEQpCjjBZYN3VcWpsBpvaLHCJGQWa4BukzNuJvXVC24kC3YuqDWSK48cel5/9Kg4OBvbc77diEQUGYvWqfbWyJckiuoeI8Th8zNqNF6HXicU4vE8SPDlZK1mxT/tUdswOnZwizxv3wUfQrbfrA7ERkdYDsKk+ndaeZNnp8jh46yTejdCll24Xq6v60UjssLdrjfdTJozwLg7On9WPmh7ReaXoSslJL5ZYQlyijABLRAHuKc8zMmnPAy8612hRGDOFM0wI8iIxPg2p0WhtWp5IJuHVy3tV8zHHU7weiIAnbIM9BIr8kbeX82OiMoYv6WYmywXzHvQd8V2IHffhuFwfbA6BQ8uiC2pbuB7WVyJWb4/tVfhGD+grR4Knn1gIVdJiYxQqKJjQAOeiOUObrttmif2kWo6+X8A+5fuq7AGCtINtZLjrX6oeevrxvY+4n2jacZr3xqR6Nl7iOi3yCRGyHE7KM2zV7KtphE6IUObIBwHnFBWZBNTsJ8zxYL7ibOh+G8ZmJCyyw/S3JVbcbWQWhF57D9P3bMytSb6xW33nACZcusPit6qG5lwkNgd6NpxkgIY2Aci9nhJK8O4+icHT7m+LSY4XOdA/OyFXjB07AapvP+aBbBQsRqY9Uyb0nPIA8+zrVfNLxd+6kn2z4vl6i5pg+PscxOPvehemCSJPfdn9r5kEoNy5rRdfrP3DKDRYB9A2clBQj0Ok20ZvZo0N8QuV7dxJpgdm6KRVyOIqcwKhmtrwfZ9a5qR4u1qEYrqxZoV8BNaVJSgRg84kH0pxC9CGt/tkpPUAqn2R2Uin9tF7YigzfiJEbX3DBgcGYmkYKHxGS3cKgGs1epsdkXnWNT8D7/2yq961ELKeirusbAGrSwWc2mXbz9dgQL6id/b1RfmtfpSyi8npEd//ODovmHCr/wih89jbh6uKWSZNCoColkuI4IBLwxYLVM4Saq7p2/hWiwSJXA2VwJ4W/WP0zxFzaF0FJkuuyHeIln1F/U3CDNNS7HDyso/4LFcrovYIpBqDFnn5tegjrHqtrzp6//hAxxFg62KS5SphOTxERnokFH9WOkyeOzqhm46eGSBwg6+0Nng9MKlDlKKkeQYpqQxwAaPHrFQWGEMRUAZ4rQMwDhZHDJaOn0pF1uEr/2UYHYn531oblzgsSc5ZhWtXU/ZBAVstKSmbmQ4N1GQMRAczsaQOs3A+2kiQBaHa/4XV8d8oWzG5hQ2rQd13qVMAr2S2O/ApI3al9q/RbHmQg+5s5AyPRXvS4lP7p+ckvX0HfXxCXST0FEWGjPlwYr/HYW+a7gseFkn8oVc1y1zUlo1yoLB6Cp9Z6arz+hjKYTRCX7HTSPVGotQ/WKaOpncP1a8YHDlH7cI4oeBq6jW8q8OYYQZtIIpvp76a6o/HADe6w3j2WFSvWk6CnIuF1yH9UXGn2Fy0zPteWonFW+8MpEdUdMnAsH8kivZknWyY5eqSiFl3HX0kRnUGRa8Cn/TSbV3glQsrsetJ96ff+QBOAriw2zm2gSFzi5MqINIVEuMNJJZBQCAUl1MTTulOE8QboFwI+1huVs3Q+bqvcihOrmq+Phz7HpGucI213p3/21QrfHrwOzVKrh5H2zFelUKIKlaXdsbF3Y2oP0nBdEk+BAITdrU64d4QOsU9Cex8bZxAt7W3L7NQAa3kOUbM45+ElwQTjGMWiw1P0l7x4SOxqD64P6NrNA/wRfYOkLz2dfwsVfug9yJ0yZMf7DFt4gIE2wNHP5xWgEWx4xFYqn0GZV5+NrrxnwHjis6KNbi2mGxyrzwNWN5LOSTv2eAliIF+yR9bY3qSqRbmcTtL7flJ/SgkJ/OQcjMtykbQn9p6lN430+BIk7xEBiYh05Nto47I2gbRfV2HWNuh+UhKm08dYkhahjcSZNQHAYav275/bmrWTjalDWFjLLd2wbLNlPBxq8pWX/wJJWliZbgLIp0Ym4SUa/Mg7Z2mc2sS95UuyDbRWUgonJIMWkxoEdPSvkzS3VN2EEPWLKp7BWf6OnwqxJp5G9KRUU0HrWFYkwVoZRGGIp+4l/s82FyyiA1biz6CburWfEhdY0X+Q4aYuraUIdbfDUKZHXs4q6qiSkpa2EEXRI1aHCbnI//zpB+JO6ybaH9lf2E3zFA4CgRoCCHvqVTuFPgTassJPgPH2TjLCX+2iSFta5WZzyukBuPIiujtWWF5AIpVpbfZgQuSPdj39WclNEZf35oQ/kxQ/Ld3o+Z1Mzr3e09HMG1Y8NJxfHx+opR44At0qfRb30ywBmpEYCD0Pmu0tipNUJS6uIYgIsBPC0fyTmTR1wU5EZ0G548AGCwFNfW/XwLdJ5H6hHdoWz/oc1DXkwp7U4W1IbLPJzbe9vMhEZXEJJO2yTK96RwHALSmhLwx+qhphxGo8Uk/5nklaWNk6w1o/eBNhJvYkU1tA1elbVFKzLxonnqTezTSw134+J+3NWOfCFvBfWju6odMZo8Osxw3jlHH1VVGhjO4f7naPr1P3cly5x5fKsntkfyVNS1z2U4bmtkQ9E4CdXakgsxfMgeYxQP2V8wIL9tsWqF3LdwDZriGfAnpTtZw3kM5fuFLu1iq0WwUETvZT222z8FO5koaFGla+Kp6ug3CqTtMWuHXDMFfExjx2pkf0r0O43+FZ7l/jicg0lGulOqNaNMqK9u1htLVsVm4DWS8k/kNqMgeug7vnQy/Uu5BAgvrc5DC9pBdKfMv+2V2UTYrJ+dmyU/mbQoUJS27pbX9DWIKwu5LdzZqgsnl/noPAU4CJS+ZStsU7CpoJa7Bs+THcQivmZzMo2nQXpclgpDQnNpf12xadF1ceL5rnIbSYdahD8AkIHREeJSxkwy9wO6tibtEN4QG4zMVImaEUMK27jy7cWbzb5Ye4oQgQpw1XzPwH0DeLqfQkWOm8nf2Pt78BwiPjjSBSn+8YGf/V5YiUU7V9k4g0yx7/Wc+5TBPAHjkxdH+N7rXX5lCgS4uFxDpFwuZCVas4odnY1qVaHVxCNJWsMtRnFv3oc+ZSchaxxMsm2n1r1ItHdyF2k2LirmPZAACDyVkedUkXqCemMm5QntGQQdrxxzpr0ry3G4UAEo6vc1i3jyWVFC4SLn9x9zAFRWYLaWc9+bJaflM88eMAVT3qO70DuuIoihLGqXfTbn1KkvfpnGf1OM0REfBId2U/TsVyz5RhrU02dhEeJP6HLxV1Fbrdg31tv6wvCxbh4W6mcWoDYQ83HGuyWDr3BGR5EbrI11YOmC/0zLl6HYFRKrpjqxrD2c6kR+HoDivhSpzcYt5h6O0kdIRI/G6jNnbLZFHOgO8QZh9j4XZ9eZzrv69/PuuxQ5Hkye8vqwFeXgDzN2fc2WmnZU7vMk51nMTERZAjvMxCHB/RpFm3hza9U9xeT5PqOt8QNyG2b1KY3rUvW0a0wBRIXCjXMQPUucO3/0R/A375ilz/VH8sQWnXjcXg9bNnxpu0J31PF6KllzKY2tcG6gWnYW85ty29E+Jwp8vrxFA4Zw1ZOits2vss7YkiZmNheXcAmnCg1DLo0Am6y77eZ4s6WpVqmZVa+ObMZmF4iisY/K785Unyrc6qcT3Fst6frAJKJvM+M8Jb/7yEeht6kFVTa6xXm3/CaZfSzcZGsqxpbJs3jIyzwl3bSZXgnsXkbTRSV1T8QHI1A4t6ukWzVLk/2PLRJdEekCx7nuQa/5pHy7+36SnWTdsvQWnBmhLE+HRcWA8zZRaNkl3byJMMRpROJ79ITt5CA4HUiNOnYfdLFqVCaiU27yyiE//tRdtstcAuV84J9eug3bHef4wZhg9oLA8443ik7wVbI0jS5uu5I/85M6sp7n6GMz9Ts7/fPcDY7UqkLNrhyf057Fh4DQZ2yUgt/y9sdkv9S62/6jOk/RybzbmB5arg9Kn70tUEBvnITFymk0nqNuMlcd+Q8a92u3o2XBBIMrFAqB5gyRzajVF+LzgihqHP3JAyaQZohntJcvBZU+KGWp4B818nfhPQWJyYOohmPaEnCqvwHrMZOY10aEt+iT+1alvgYrGo4dIWfxHXrtyXQZFs8jhIxgom67GxXvHw+1Bd2aRXU61bZoHjhQONeJUo9Q8cGi45JgN0K9RS2Ke0Rma0C/k4d4084Ba/LMj8G9b2WX/hiUYssw+pcFPZkpNhBYSRW0N57ttkeJ1OqviCi3vkeDF8E1IWOba6mBcXZzVkPfkMP5UrT0kTfe4CIbLEYTBtG/HCBSyKQUWnWUJmPyjV0zEzbPxpVTB0nV76tI1FBpewTjcj9vSoU1SVIout3rq9G2v04qXHMabqTJ3c0VRudpah/WXgYNJeIu46d93lAs96zcI4vkzRdkYGsNcdTNn2o4EO1tjW1s2GETnKkvcpoEhjjGJzDEHP38TPa1+SpeMAg98ovuBfQuVBe/igESkyIJpmdoFEi+LVqxqyzniQqdSEXTYxc4lzicTlEdkDYpnPRBYFSczkmRo0X9jbDp2/+zu5Tm1cIMUU+jSFOgmvOk+IaNfd6D0U99Sb1UXO6LhaG3I+fHcSXUl9v8AB+R0eLAQ/WrC/TWIggAoTo4SVhpBPAcBK0YCCdEFbs7ypDkmbeqBA/Yaelj7LC+ALUIw/u05Ikh9630ydL9NJre/JG+H0CRwx502uax1vir/t1r53DHLosbiv20CKLV9jeMgG4PVg02kuQPTP18xJJ1/j3QpP12U7/gTGgY06F6NoXLVYLR+bnjGPZUPzZ7dW/ctiW0Z1u9vPLBCxBhfeEDqq9Vl/Ydwp9eQ9R9wPRJpR7FuXcD1DVsqoDypvFBZ7ti1L5KmXrx+Gnt9/ErmsohVplboVEF3wNqj+QfPi6rsslam92UH0a+ip8QgK85R1PqQRb+ucBI2/FTK3bDX4Qx5Kt2v/FtNBdtsNr/lBAakNa+R4+grQvHe3wU0bEA2wuIiFDMnQOU8F4gDQeVBrpgZu6ylBQj1ZaAEVdwHMZw2BW+7Nsfx36KFqPE7FsHr+8CbxfF4+PR8Gl8nPP83vAi7yiUkTDPnQea6qIxYf44Ld+5U2vKXSUrO37IpQ20W5cHWbsp5iVfO8oO6Uqef7y6NBQB2dRxLrqSOLhtrNOFeccsb7lux7K6p5qJe44pXy3t8RjM/e8I4fJCXuxLMN/vJvW/I7IbsFHdK/amB7494PhJcXMIsZMa3iOoqFPz8Fgp9es1SQDRKEIDS+tIS3NCg16qhtd9rbZAzQKqw481aYtg8cWX2ge+yxFOPrOMNavMFMHYpcX1COfOp+zRC6ALdM3qwK6N6fw5ZQq0s2UA1kCHMIAxz+fob3b+nz7dDzLi39jCtBOLaK2WbIjF9+eABlyUwbsrcM5Mdit3/MUZCURgxeyxFoS1kooRZRKrWuUbnywrDpLilyEDVFgbKasj/5mGAJgDYqozKySLx4hDBXt4aRTNNW2vSvLl+VZlRv+UOLymwc3dANsF56997w4bhWiCke0rOwo4FJnD5kioa0con34RzLblmhUicWtDEVB6J9BUTQZswMhDEFhKOKDEJdYFfHPod1z/lRn9ZqbrB7u1y+y1XoknXlCKUm1ypsP+jI7sd1HWhSUenzEWfwY9uzGaDIV8ns2RaDIUwj67+GAQo7eOiY8Iir0jzF+QF/k2AW3DwTZxzDz5bZ581FT6g1NwxrSZBqSLYimPWinMuVReO5HwOxuenZyrvcnuaMsedw4JtVlAgsKrM2HHipefLuSzaU6Of9LnB3MJ2Ogrck9ie5h6SCA/+6pkVbJ48vF/2HuoZxFqbSXrQae9Ufo++zoDU+QdUmHWUZuaY1EIu/Iajiv4S/E9pUypIecNcHBL+jeV8TKkxl9slwngj3+DyxMcqzQ0zH0RE1jrcjRQ19YxMhh9/CNZJSz8WqdRr7qLJCVkHMGepT3NV+H7qLlmCzeTrv+Gvbl67qCybsp6TT0Ku4MK2siCYPfw35cceHn8AOqlW9wr8afCtiH3Y2gMTiFOJMIAks34ZdBrzk94ALczn3WECCJ6lw3jzDXdBW8hMwxFXxHEc2Tvuaw+U4mUoOqflfZmuTlhDaE1U/0rHlGr0xu6MJ8xI8wH4hy2kUOcmkUcr81pemRM4+Sv4lRWuEkqrENjE974QTsKPNqQz+34iOZTlfdghRpnMHsw3eNwnbfVB5XEaM90S4K3ByiuxR1/6P4t8YWWPbVK0FQCpaDYATMl0P/2GTsw17z4aY/Tt4O81OYkHn43NNIJrWmjsjUqiiowKy3GwNE5tQoxMRXuA6eQI5jB9qJ5Ciexi6KCzgr4du8cDokkB6An0WtzGHKR2WaQktNuOwvlnQivCa0woGyrWp7PY/KcUH2bEazf06GVm+4VGR9qroHdRxoIK0t1PpA1GI2H823uND0lE6k8ESicedunfid2PqjP795vUUG5BeKOeICDTFHtVQHpIDe9dVxdTmyHhK39eM2Z3iQgwG23bVNsJGNZeDSXyIWnD9xyzPtHv9d6GbEw/As9LrafD0MRHXXpji0x1JuqU2NJmNeS8raFpYKYFSQKCAiQNHPzo5wcFDC3GK9+Kqjpe8/6BtuFJY8WpfORxlcKbasSJauCpUk1bIvC+THNKwxjSKwYj6LmEVeL4BX3OK20Co5C4GhnXCvqo2jmPsk5RlUv5wMfu4hR+TIVWgXOj3GRxy/EvhP29ZPDnrMCaU3oa2ZKNKRqDlHvJF3ietduYR7V8ZRFOvbtYHCXcGEUnvbKDMdkHCBLqunMbRpBSNdWkyYwlaiblIEoT0z88wgu3RWdNRn3jC4ptkYe/JzccABQbSu2Y7/sc3rqdZ+tigWJnGJnUn95n5fzh6D/0L7QoezSZ7urw5ESaRPUM2/7AOqognFBxPKo4c7tvpkP9855q1OJqevq7XD6iYCa5bN/QYq0+9AGuFaRm86gH4N3xtRqia1/SLUAB0lqKKI8LaKwZReKWfVLJ3sj7e1fx2FKOQz3z92Kli4qyfQb8+hdDTayMavWU7qpUCoRGlf3baZcdC8Afz8viVgBj6ot3SFS8muCX/HgOxVI0UTV1qQAIzZ4pZaZeMRiKpvzBg32yDOW/d5EE7iq6yq47IzFDxW/SxUVqOgDbshNy5gARIAlKmjO5/l1f8lF/OrN+NjTlPQf80EIDvlqFMePWta+UaGnVlzB9KjMFA4Wz3tumbdgWcgVr8Kd/mTeLbDn9C+9T9NuIAV4VEldIA3YJoeHJ6woRkFKDY4RD72xCs2CdvsSXW6vFqLCrIe3olE9d1USyUn1XFs7Gm5Q5FeGZlGYx8q8xPPoY9jm+vDCNQAKYi7S5cTxS4b89t2TNeZwM8kOOuGIkVTb1xVLBi++2BQN56GennuFtg54Hk925iDuGboqZpqTigcysMJiaW1e89pqwqcSBvsKTFSrZwFywAfGiPJKjvjTf8LfWUHex6tOGkugSdVbN7gwB61F8ZVjSDkZHFhHtZuC7CqLgtC2yzM6XuhRCcp4VKETRNR/C4VAtLQahB9Y8XNqj6m14h7nYtFnonolyvx321kTTL5VEPyUHUDbMauqDptlOvxJT1sCYLRgDOhn2JBrdvJO6HELoDre4mfogB/kjZjLDO2ph0t51XCTmSugIrhNsJ6ctANimtvymfLeCWMY14MyZTBVYoArnTUIeb7/c0/3HHSbpFx3O3ge8KZU15t0OXb6+aJJLw0h92olwMRJuop49lIgxUHAPR9fwM0YAuJbSmFJznESyCRMkp2o5mEMzPttkLjYYGYw/tOVVRvtko5tg3jRRnZa+55hf2R/QVHrN+Z4K7I49yP3UlgyZWcpqYru4br1q7SeB+jEOHX39rZLMfio0wkxCNk1y+GpFIWaooaPqvYJnzu6d4EEZxuVsOqm4SiruAAL5pUrHwQ8T5oPkiBmLgLfUSlzXlaDROoi+iSbM3ZUDRPIvDE2b8cFLj5MuLkfe8hSaE3SJdk+vJXn+OkI9ju/3IG6drxBP2bmAmYfz3T5KS3ztU8vAW+GqWWPkGqVkHsC9i65Klh7TEboV8p+WPRlomq3HAJPUjLvlvSEeo1KSZPwjSlZ7XdMRqrNTC+RRVC0T7i9X8M/mLTIndrKq0LPezW9YPypfe+O7c+23USyLbMKG8GB0SjDLA2YfpvjYfNpvE+BpDaItCqhrWrWheMrZUATyvlAO1x+5CYr9H4KLufUj4Q3GD/z/QeynyymzA4/71VR2XRZ1rRh5G7pqurJdsc8cmFu1+A5gH6GYUQu4IdjoJ+1Bb/7F9ZB8/mKmvU9Z91aXNIP37T4Y5yrYRb+XRsAUTyCLD3/Nqh6s20tDjgWVnruoF2Fip/dvBbsX+BFFdxsrwVCbsGYcHIGrzoVU7F7Y419h5x7wQtcgC2UWOC5eY+nZs5o9C1hFMHDDI6PJ/G5a9Ah/mpLEvMj4vpXsFvuhbOmVVDMAcXl7DpaOe/ixfcj0Vyq1lTghrmo4k3maDp4ITWaCw8biHi3kCsf2J8yUyl9QUBdoMA9hL62/pPLs5a4sUNUvVvh+NPAaU0hc16Qw96eUe1TvNE4F538NAPACMtK5qzrz9sM72y3zDTLDP9gjRJCm7WlPPKFzN3Vq3iCtZ6zZnRL4QvVBc2L8yfAwignx5pGsc/ub4RyljNm0s4aahk1FdvIpF6Tlm04jIUzLwhPAeikXZ9ohaU6rMql9dJaM2Iun6iyKGpQSA7J5aIqqlRnwwMWplXFBYyA8mou4Z3MaDd1yZZTlTuq9pfVlfc4PIKEPVE03NKlrh3Aky3tHnqTR2o6DQzCppz7ZZjOCOYkv1/XbM8o0+tZhf6oy0E2CJW6AqR/waVUy+cVhh/OrNAmxLU4u2ikgItQpeKyyF613kSxPXkpgti7Kxyt59Sl+8XVW/q7xjtDvyEpxR3Fp6i4W8vUrpVUIHCCMScwT4EqRTrHHvf3UeG7ACZrZYh+SpHqoiAcpmfUCGTsgJcK0Tv7D5nVPKZXvGUNeCZhWJzXamQnrqNdU0byPlm4OPHQjBmglb4nKDvSj799LmOkrvuGO3+qCLAUbG9XBP5YjuMR802POkuS5oQ2c9uc6XW0gPN3G90oRenDcVjUHzeZrotT3KDq7NM71IIuMzBIQS0/uUALANTcN1Iq4gd/UO27QrXePzNf3pewM3VzEISWwZdeGY0Osz1MrFtwbCoWkzw3+HBx4O5xKt+arCeJmAP7RktP6LTEerGBOxgaSAFbqaQjKPZr9r4c6qgzjfFEo9n9Guwr7LZOyJcCNqpXfMaYSxmEouGPPmLoWmUYNp6nyPSQDzhgQlE0hp+vnUkE3Scldg9JwfukorjQDDVhCtGpI9Eb6jlJjpKLyz5kyh4PVbE0tS4zYL9gnA/lU93LmtdegXR6ygR/fAEBmfMFMiKyAmZKSQOpCEQMym4kwctQTWMICSbh4bW/jxgolt0Df7sQnggRZX5VISqNzJ0UncHcDA9Oo7JxIylDuJ3Rf5cBeH6rqqsDbjAoqxQfpQ8IGA7Ko//E2I513QjOaU7ZXA18d8h9ktylRppM+FNduRYq1U19bCD7pwlM8vvOtuTGo0jT73FfGpAvjfwTS3JnyPnrkBJGDQ2RRcNbx6Yoj0uo8v9dPTTCn1PX9Bo/V1snteWQ1lGhl08kL4rs2Z+imYyp6YnaYaSTDfpEC2fP84JGQuWJREYagQISv9+45P3nSXE8m91K8iMp+vNrBVdYoPylWPeJE2PzCkMmyCD436OiHITm64VdNtPjUwyCj3QQsEEYq/xpSZv7LBLbQjSb44X3lULAS6W+ao/ZaYx570WcTTJrNGQz17RCYOA/TVAQcHyjaFAP0OmfwHULM6ST9hmeeskCQO+IjVliE1aw4jMH+RXBEXPNMFWW4+mBTZrv2+xdGCemX4uT50qEDQrNehXeVrUmwmJX/hK8+RCM5lvJQiaGRPOQxeTJzHhWBH9/yiYGLenVYH1417VJD3Xauf6V4fA6WXquJ41O6U6bI/CTeEp13ZspkVo6Qm3BDQ+p1+mQSTQ+c4+iRLtKvFoI/Y9H4lEAu7Qi3Uqrgu8evSaZiJNygqKzaevoeFjuXektIr0gaqJ7olQig+Och3gBBaAt8/L52gb3Zu3CSI7u2/ZDfphwtqPBI+6m2VEOEnIB85D8DMoIfXxJiK8IpTOfmwYGXcCCT4XycC2EtJhCiDbGhY3P3edXX/eSqYjVp6BJd9MxAnUnvvJ/pMDEO70Vf9H3pv2zZkrXVJXSQSvpAiUjHUKz1G61r+sDgjjQRAmRmVnBb0lhxU1ZQ5kVduLwt3QVOO7XHKB+c+hLDqtybd7rFckqY3D3ZvfA9KMvIvhij2bpYZjoMXNlJm9rbO/MH8vBUwQRij9lPFIyWcwbKGRcuCXD3mcW05JUuiAqitlKuG6BRwxAunta+vZrhq89K2H+rKJKx7uoz0fBA1CmzIb7KEYTUDVZhsiSCgssdNHRBpBfCdd0mqNA2sAewIePjOgmKzraVSZVqQS3pL45saOp8fZ/OHWG54iebivp2SqhrbeJzv/+eX8dCXA4ZMXC9y/QtmuVpwY/utm4num/w7/QmgDdOlC8GWV9ASC1Npfi1LVjVivNDQuwuFzK/zMmqo6+oF73qbCkEppufogimUXMvUz1jRg6Zm8TfDp8ynacsDAdcuOP7YTq2U14K5BLssKssNMBxNZxUHU2Rc8gKUQKVCLQRMIC92VUij5ieIvUgf5Xx+Ly2RrVf36y/L5X4ECCs82/mnpfdMYzbH1kDWMWCIVluI7m+BSb5LhbFFuwAIBTUdGWwDInZnJ1VZHDv1KMw18O6JH1Yr9FHzCkE+Ej71Jb7VN04/Pz5cHYxLcDY1Ht1NAHpL18Yd7wkGrJ6I0zIRV3m6d/gFGEM4qUMLGlm11Ufq4Rt0veN5Jr44DaFlkkhZa0d3vRX1I1g67fDSx9k9/bAXzLgwXjYWgq0nXpzGbOksRfJay7M+7WupIOHWuAU51jo/ZIZ3Y2W/RPjCHbv5R2tYDA3CDEmGpaPOk61q3Zb1JnCBC6wfsPMJ2gUFjuBnQWGLUNhtZV8HGgKImuR54fArBQKPOKh6glk76A+gu2PG9d7LdxVCGcDgt3HXnSyq6NF09L5ABT/LSrS2T0hJgGPNOXUg91N/qSixt9Fp9sTKr0Er/oXiv75384IK11uPFiX5l0IQiBxxeodBOKWnzADZCfyjRY2jfz6xj4+HRf514iUms7oiYQwC/thjANVdkg/v4sZSSYw6gnu1SLh29iyHFMy56ItgFC6WB5ZH6U9kqBLaxwV1K/vCuajtDXyXlvx/DQXapZ0Br3yzx0po3mvFhdKOSOdKlV2LLHyX1PADfKdar4u/B/oKbIGz5uCwQxl7UO4kuwNEayTJzl0Ek4+8nte+Za5DCMM/qAv7nk2RMFIheHbWf2pMcRvN1V+p903SFBZ+mzmANFq53crGkG/plka5m4XHB2YnEdLtwXWugw+H4gHvCafd5TlQ2Sl8QsCTheWuGdmpxDEcbXvsxakltIezVK6RJrVGvAxa/0qOYzrxloGpWyCp6xBT0DYCNaI+CUOJbERSKR+ibHtG3GUTNrNOYyAfOeQjFkv55qSmuo8FMvdqKvAJNbiW9FZq8I+0494J8UyydLs6hoeRhaSGOPNzaTIZDnBrExfZkVEIBwKDPXVGXV87ziK0JyHSjTZkU3sy0fFeDpUkbGzgOyVhaHQU7EVoFcKPZLcleGktm5YazMYtzXgL/c+4ypliA15T0nTHp9twZzQpS/gx68ykPXBu28yejXF2KrE57XP+Vzmir0JC3puA4zT5lsc2dZdfs7/yYFn4bgDY+9ERbqwtVT5Q39PKd6RAzd2sfUFWuP0h8CmqKgwVksk7wWSTrqs2kT+h6UEfJ5m0bAP3qxNTRu9r8HenC5IgSfPF3sVN/OkoRG0Suz1dSlYgIMw4xViqcGhI++DYmX7d0Plb5zYd5bM2uXrvj4fVYVUj+WML4ncFXWlfBlK2QYXXgRhg5PR7WVfr4/JhcJTWrS0VUf1Swo+6gnqS6mMovvjcwxOu30lijsLMoT3Mxe6S5huKRGWr9SYJvySMzpI0GeKlFaVpDP0ooVIWlqhPDZdUdsAzXoVs6GXddohmdvUT41iL9yGAaVxro85J2YQvpsM837296D2Hmxl6yH4mXJDRb13qaTaf4KZkTPbDkVl2segUJewRm5jmj8tF6zA/u90vZbIitL7RnO32wIcGmhVPlLgsyJYrbaXAsvdTRLHUsTDfN4X0Va3o1aqOqPKsuGo7Y9JbAxrT8TM3ZlEvdjLtCfHzFqDtOiMoUH45T93cTU0AqW4PuMH5Ec3zyv19c1YBIGLtHF2dUjlY7VaOVVDj+Y0mdUFOTXYx3K6mDYkCj2aXyHsiGwZhf4ZcLQ9S1j5FfUjDDdvm5bY+bDnRcCUD0vOMgXsDQO06wTtuupBNmy3zYhv0WuLrX3GMGkmhV8O3DRRspsSBof7QAln6uxWizOcdx3zJGm6ka5c+JCh5ushj8zTNwEt+07vw5qhgPlxeicHZg1tpmJsODdk+Ys+Bkr6IFI78LNxYHIpg+g68GaEfsm5BAcHCmTDd23nAEC45FUj4LKM0Q1oCREKzfC0HwTo88ku+JG4aPc7XUGqletgNeHSZJXJZcxw0npPMMeuXeupQoejp22taL6iRM8fJ69GEewvggupsZEkd5KICLN1vBR5pCeLuYTRduLD+HbMMIg+PkeV8hP1O66Kx+b8x4XBeWKT+KLyQtpjBWKZ1WQ49D5+ZOQdT7N3jmnRH1CBEAykNh5NRG2JbwNFjJcJUbRq7v4XwKyImqudUe8Fi/1W/RsR2to94YQVh6+9+VZuACQmFqwRTaYzSlOY6xJhkZvEGflndQcsz+MFgMlhlSkJF5EhbD79p7s4aj8WHrwNNxjmIMnW5tJxvO/Ywbh8LeIfTj9AtGotQnRpbBevHTT1yW4wUrYDypDVAihslOF0zQYkjI+4gU7R4D6Ih06jj9evwsL+8zlbUrWL6IscL2P4UkCknQrSnkGSTo3xUAJz595EnysXS4dA4lKqbGx5VP/z1uKDtnDNakjotKTkM0QNJHKUgbsv12q+g3vCgSiyzZR0RRA+CuZhje+xy3FYnL0Yzdzh8IqM/Nw8mDg/T3aNwwE0I8uagriMSYM77qWoWCShue0Q9/u5OtBo/5CCaZOOHW6FRzfEHj0hqZCKEwOYdY7S49kRFeN8JFWswiKTJnCYtM64pM0Zb+A9FQizltYzbwCdrQbnNFQDA8KvfwptfgN9kqtFIZ1ZzwM4y1Nh8kfVHzuOATY3M8wauSVblP9Lda2kyMH/iVMhywW6tAHj8Y16mXSHnW6rKk0ZnfXaehQahmJhUmGQSUZUesIyRW4uAzEJKBlx3XGCrhr+2HXTN55AxkoYccFe0rMxsPL/rO9xD4Tc6XORQdECYg2wJhCc5dJXbGpf9BsVCNM4HYVNTEm4u/MTawSt/eQ7BB7jw5cJjvvq9nMhdDiOlAg9ttt3jtfY/bsInh4uA6ZKWPhv1shmv2dGNaMWoE8y57kES8DnPERZsxYHuL7HQ0jii5X7K178nmvX6+lmJKAyhZ5dSk3ikrkWw2jlHQpm4f6xfpnWvI7AqzzRrW/2tV3pZD+PBEaDrxkZw9vARVHBPUZ6LRYd3a4y0A/CjtsPOJoVOACCdO45t0F6NphTA139BCjZFGIxM2bIMCKWtFltKp8zQ/auJ9s0THCjvxqUMQ2XgY9oMcSCsZlaDHHlX2fzdUs6gCK2zSMqDNbstEzsEOpM1h6zqlauObX7JPXMeU6ZCvhkQ4n9dxDoL3mZvKubqXW28ZR94dzjds2a3ufWg27cjS/11ONKxV1VWL/uBzb9De5MzF35lM9SNmrh2dHfr37SdnrlsJJMV2uguLg6IA4Ysflz+sx2uMyaRQNz7jMNY+QEvgykQJ/wtJmh9cJWb+TDTTnBUB868z7HvbAGvxTb6hZvcA5jCgrjhL9zwM4+C4fxH9cSimhG0RQeNCjkGS9WuXYgbnTA5RE/vyXpVVgUAj+e29P+5Zo3C5WHKNzZigUVPr6nQ/9B/8iZ2XjK/bAs7TcuHfC7KA6pb0nYi/AMw6/p3GQsuzo5mfpMyJiTOnSe95Qkv5XIZRXrz9Sykyx20nYj1GnxnZK5z5O/KgBgAaSjP9oM3VQ9T5p4Lkl5ZtTDeJXsJ1Wx1tDU9W4gBDm9dvMLzBqnVll8tiDtj80N4haoOvOVEcUFB7+NCeeAOh18SHU4ARZbmJ1rJDeW5+4nIsc4eZXSgt0QQXwyrXQUImcTRXsUY5Ak4ncHYXQwjzjo2YLMQJfS4ypn0hJyMM+iKjbtTiAdNxhdOEX42jzTULD0MkO2k8ywwzkINKYCQ8+c1TRXhXBVXfXkeFQsmytqgIBTmqGLSYtj+vXKl8nPNspx4YdIMowR0+YMhsKkvgZZ6hWZ+wE+egC0HPFAKL/4t0pamSEXnFjw6lvad/wbJ47I6vOk6q3ivpukxvbc6wZr7GNxWRMGYRkPloHtUUp540Dv8qwm8JWjHvDXWvIQjDgvmIGCtjD9M/junKAhohTEQTf43k8OQuhu5kzTHX/9XhWNsAcpj1uUAFoJ/AAb8ph6++en8Nt1E40XRUsxzR91ZvCjHftRgfg9gtA0VoS7ESsEiQgJDlbo37YSuLiHy5l5qVhjvWuqsowN6/HIxtojojjTMQz8l3+KSijnCwdafIDPyiLUkm+HlYzdT0U4EcLW9PVdZRs7Ouv8SfJ5obB6o+lneHPN0vJWBmcRAkwhwfP2bH+1FgRqQPkSy66V2MwlMNmWBUjCEJzU6ydCTybz8TiqmQPNG7O2G0TjFLHxKjJG/nuChvsOI5oqDE2EYSOicLumsbnwCFqHauqH0DXxFJmixBmC9saNn92IZTjcaPPQdbXT9+PjlikSg11foP+bTSx9Cy7KhSChJLphgHBTgi9eOyrk4W32fIMm7hArHbtDlqIqWTUUr6I0tD+al/gjHUsC3TCoSmLOZoJiMeysryO+R/1ezSeWi5Z5tLDOa5j/sBhrWoq+kPkWn+vK7SWnqRORaXo39KbqNgNco1lA8EBZmH1gzAyWk/YzCIcvHDaHx83Lur49/x/8JBTGLRMYdXtkZK0n4+lDbSv2F27O9GpmRAjE4zXilIBPWZLYIytMDdzDM51Og5zMW4t6yWP2mNsrigI/rqkKMNuL7loUEkWSz6z1fW+F0hoEuGNeXQOtKiamu5XCV24tX53OjsRqc1NIqum4k80SQ7uMzxa1y6yg09spi8jsSwAMmIRoDqmSXTovgohdobrDxTAHb0BJ5DCNK/0AoWuWcW4WKnt+kq1GSelWr3NQ7ZPHqqnY75sEDnHlDBbjJPnlQV3jBNJzoEJPpujy/maYyGOTSL0tE24tM3iQnJ4bNWxrgYONz3EbcLKFes3PlSm2G/2k5HO7C2Rz8GNeoLOiP3oZDgCUrTwRtZXtWWKyTAdeV9DWCxqFOo5oQgjJp37jCaNbSU43zi0e8pmyoKDTikaZVDtgqMu+Mxlz4zQ8kII/RTZLcDr1YIrN6Gi7r+AONHi4cTQwnMwOSnRuqkwgwKPR+UQkko8Jk4TyVXkFcCIykd4qMAKddWjJFiy9MnZzXncLPYvEyLSrliXObcyvp4lhHKz9sYhBrd+Lc+jngH8ecBoKkEOUpepLLqWap5+u+wwd7qu7oIo8Nf5kxX8LffcWlWLBWZxrUSiz9UddUjpR0F+J+DEDTYcYhOw+yzswOfkTSCnxwwfVpqLVnW4wyQw+6/Q2bGRNxygkHeuiCZetfu0oqvAjjcknr9YNH38Z6JoEocSotNMZQSFBDb0nHyCi97rpcOluNpSyv+tLQJtDBuFNRY0zisjfcdCLes4A329fvyRgtLY1bDaYs0oc/F43Xw5DVcquHPambKGFZzDMsMSfGS+jLgDpS+nEpYzHsWkorBEYaGAjDb/HgPtopoCLdwGtahKRMLUy8oCMzzZfo2DcAbubE0iJR2U2/U2nTxHGcWWvsW2/qJnf3h7su4ibaPxl6JNIUScQCo0QZG3ZZuYx1ioa1iNPLcCkLAYCDsqBqxTUfHWkF4r6/gpU1KVgKnCN7WBo98SoHa4zpdUSCPj7UYOFbN1yMzj1KEjN1/usQdoEzATsiHUDnO9ccso+9D2OkBSHndbgglphVshcMjeMBRXex4VI+44RYb3xNtZe6RKTe/q/Z/geEka1Mt1H8H87KIN1eXESXK0WjcjcAcLbi+VTPbmRQsYMcusGo9taOx4qBoRDJJUTkOp0F/oernoz2G8gL7k9+xQZr3uH/F2E98pKB7kP9b7qrAoamyAUzsvFY0Ye1wLmg6wz2R726OhdNT4GaZotGaTvij6pMIjyxfRuS3bfyxdlAqoKWcmZrFN8dfXVcfSAYQeINLQe3a5FDzw6rzgDC1EYGdQc+DRk92P/K+tJfTLYCRBp2+K09+yXB3v7Y293AHQK29DlqObGtN7EQ8+yJBVfVlnCikjx3znTIdDjPDDYvPoJrXPduaxkhFULm2+fTJznku+1hStuO0IKNivkZ4StY6m91jc8MXj8JcwL9RrxZ7jCfUkOXRZONZNSiySvgaf1ODORCp9JWd+rGfczLZcsPcz2jjPUzMg5jQ28oYxDLX8kdQcWMDBP4grI/+L206aBOuXUSXaxx2hil3ocqdgwlR8aiK5ITIMXlhS+c/e7M4A/B66UagdYYn+vlehx8YIKcjpbGMrXDEqu6x6+4h9GHn2AdR++BO86u5Q54RJkJk3I7bkhH7hKS+VwYCm7zNvj7ZrUDD0QYn2CqjZZeQuK2KqxsRrvY+CEPmXzexPI1Ov9YH4v9OSrxTFVHFcVcEfomeTsWqfPfWQ2WyU3r04w7myExamkAQ6oX8IPFpHivuvJQLdQx+/N3NbBE23lhTuN+F00/npueuAsDpwGN0V8iD1ZVxZv5Sowh8ktu4jpEas3k/IFa5pcPBVaZbspy4TxCH0o5yvVmZVSs/3TO5WqyRF6imNGpXbLoKzqTZow/mQnB9qfYMwcTY5SttAZgZPw/t7Y2TTn7W2zrcv7vHJU1ponZJwlcEr0ujLWZ5quxKF+twBt9yGD3TQOqvi38WCSQg+GjzZg/hmDKMBek6I+1mN3v3ol57DOHGKDLSWei9f1o/Osf3r6+QLwB51+fQf2g7PhcKl5PHKi9vbaThJ3B5tEITHumISIl+CZxmkBFggEjuc+qSyWKHmkHHWQf+EpUrVeclgUbU4kSjosIc249Hl3ZW7x7P2y6f5SBYNrHyszB3tBvI8WBr0En7DPPW28gIS5KcyZzFKl0jYm4C2yUm7dvRv5NvJ6LJ5THcd5IjBIR/xHB1QyrRk1r3UjyVGu8YFMlLcuZeS/IsnlcKg8u1epUv0EYoPW7EcsGmjteu7vxJ7pQmNgkiEhtbRxrKQY5tRLB4aQjj53j2lBoi/pP4Tn6Ij2FNatxk6yXRjOtu9T9ssaoVFxqgCaz5A4AkI2vK0rx8l/vJFYkMPqzEQkTXUW1lRWIVZlBusePXl9c2W7wDtNo6XXTk378+OlXH8/hN2ggeWwgDtxtdBHYDfNe9BIs9gT49nwEToR9BxV45RW/1zlaM3iZ9pa7/+cPFcD2vOaQQ3Kw/xdtBatibSkM+bpzqvAMlD0n6Zy8yCDzrLyBsr+SSpmHFHwjPF1fHe4HxixauzIGQvdi2LYy3BYjfLSjgPVGLYUeiHYRaBAaCqUFpJ27ZzRj9PzvArugZJQnWASpP9K84sEgkWTMnGe0xNoYAkv5ZBBFUPI/VVT3ZukmV6hB1/e/NHyHDASZ24pjARUltUH6eh3oS/wFcdr0+MRWJfj/57OnGLGoXfT2zRBP/fJseFKXWMV7+LKyfCU7HAXiZPMAt2EmDBZ+PtSyIPfs5URBaxU5iRukCzhM3EzFSRPk8xwuAts8hZaftrxGinJvJ2xZFgg//y/n4MyK0zp3mRayaRFrFCg+RZdhDuLbvmjej8vJf2Q0uUVzC+LBXr3BbZkJomG1eNOXTVrY5nYd3DzTqJyHgAgI7nBHKrl8ng5qMCvettWF9V32ik7vCGTJffel9/YdmiaqPj44qnBBsnpa1tRRmodsKIfSJPoOsk3NzhUUjivJpLv9r6tPPloX1FRyBa9PByap1p5q0O6MnISI/7OF4OMs6vHhsP589grg3p0NcS8qsJdOFgBryZrfkxKBlXPIKjjDgF44vy6GNy4VuMcc1DDAvreKbD1E4i83D0jG6eZysI8Xf08lSoSn4Efd0LLTOHLNfnOB49tZkSjr+Ueu4yysez+UFUjAlnt1vrPvJD66FpWqRriCZ8p6/s5tMekGuPI70GxHWJPxPwsIBUuSUyfSt6Zs2h0N3ZhS6kwEgCqe7xb0S3qYTXwQUTwpidnuGUEeBQGBCdbjdYkDmzxQjSWMHetnxjlqjUypqa9aiJuuutSA3xNszgS8Er8AVPSaviMFbTqnneqt+I07pcMezDAmG6JVVszv5+lq4mKBSnH1AWxNr8AI1ottZ1b2AGTcHNVM0R4DLXIFODE/caPFLZs6+wZ2AaOrZzParY2EU3b/xjqOt5mJGj7WQkvBCmg2hO5LIYoe23mEDbx4DC4NNqKnMVSB8i0ZtG/4nJfX3idJCtWkIO6r3XO+Ia1fyok6tzny/lvZHmq4z/HI3CZRx7Gt2ewZF+TRBSLnOG6NeFWNi0mvMuYRqF1R2gwYa05p8k7+/8oE2yqTsRqBveV47AmWI9KxhsUH7aLqvmYKUOEYL5toZIBL3cgqLV02NYV2VwU5pPfWXvJR49WJgAAGKOg1rOK98mw8wDYJBLsZSiD5+m1A4DkG0IrPkmLPVajgH0SomTmkd3BpZNibEsHvKLNowkPDg6LFANUnSJn56JUvTSeNRlnqiQjSMalbHWYYvbVfBw2r23kndOUI3AOhqLvSaEEPa2h786PomW2HQrWWhokAe9Sb4l2C8TRl14/lj3x09630BXHPbrr8rwYeijgNask1g+3LBLcdN30gg0bDSic8EZnrluFqg8GaeeX06oM3Ph0MMR70Ux7jog2jnAgDoGedp3Pj8k0pJ49QgEGd5p/83kCrNvSbFomO0rJ45ZUrPKfbEkIjfWWs2jl+xBxZHAhNXC2pg782wqhxeRZgOTuvP9TOClvVa7QVft6+tQ54IcYDG4UBKv6/EQEOTLziilgdI8DwgndyruV5sf8TItKKcxtvr7EruBVEA9jvYG3aQypkgsbA1XYlR7SAV0S9/ZaCyanr+Jv/TuNYYrwLdTtD2QAKvVq3xL3PvWyOnVba9iO0pquzuPuHi1rPvd+RXUOG2cIQ/HRLqhr4InI8V+WYqAEHcbUM3haD0Gy1EMy59VtlVAbHpSTzNbsPZgDdMSgG7ZlqaauZB5Xz/bqBCC6TM2oxlzLNEAbv/VX4Yb/moV1+PNPSO6JuU2lYXIxjRStpz6zOpTP+rtdf8o3tSmTj1bl8hQrrk7Fjzq57ScQz1s3hAXfu1vHLdQvRQ+MEfiXKAS+UFKbATbEUBegtWsAvyi9NC4Fd6Q+8bK/jRZZJcVW8D2oJLWVInp2TwJADaO1vWDx6V1X9DJO5I+DeMzYhNsVMLmH/7GBDJYzypm24q3QOzXhYmReoaUV+At05qf/eyKpRuL3RSIexgPFicbzXEJY1SEKgbHCPsN4kImRsds3UmepPVdaWxQ0Wsp37wfHEION5FY4SDnyAxpknk88A5iF4bjc/fvjTv74No34fj5RFAhzv3EBQhKCFdu5FDqtevSxrifjMfiOEYNbFxC49IK7HzlVWdL5hUEpwaJEJCUbbbpcLYXfXJjIUaUtpQLP1a320SdzobCsdCQ4LZxvFjcDpZ7/o6d2AsWwoQUHATGMjMYAYvK4hPlV0AW5If0fDKyz4+iRSfLe6isMbW6t5HFpD/2fUAv6Lv+2ElNzQhpEIoEeTmeT6TL4U0+iTVfEGT+1+9yu0mNTAbSHSepg/dIZN4vfGTayE2IzAghrX1neCMVmrAU7g+VRMDLocrm1V3tFzqRUbhQZ7PHPvAIhRf7NqeTDcvr+7EVl8H46ODDkNtf2PCGnqcCYQL0hKmZWkJK7gUo4WJvZwCx4NLM16OuqIFqDLBDNhu3QdQuB3ra3OMm3dRAWgj8hxApDdMfIeYEfrO5qMhw9eDwWf60+1QFipWSlREKKgDvI0UXFMiIvOySyq8P5yjc2rVPY8zaIoRRvXOSLGgBP6Y8dAe6pf4rVKInroZX3D3VX5BDvfbCoJdyis+uxSVEOLsBVISeP7b2h06wQAzCppr5jqilO7kfYjbVvS+EbQoBpFbPV5QjocmR3AmVash9kjqh6TxKVoknshs6vzr9NR/enrBqAKX+YI8fsIXc9meaOnz0rKiqEij0zLXSR7XCuujdYPXhgep/OL0GPxedLJ3PItPNUzMae7Kc1hejuDyk3fxENg2R+Tmk6ZoZldtlog6vL3qYibNIFMoqkuxp3XzAkuKuWvXUZvPLmXIxQdwrXlJvWWFqhLgTanKbqWGwiF48TUw5xZHRpIy0TiWJ0HfZERGDnXNzYYkKD8JrwNr5tQVRXsSUz3NAoWnyJbuf0W+VqUZV6qhXTirYHOHoeVJydW8IJMJONyYVsVemC/m5IGczmANPyE3agCwqhls3uhgV8tBUJumzCik7YdM9XMkWQ1lSw4aF7bTxe3CKkJ8TT+UjEOZdOSobUKOz7l5Scmuii8s4rpOheKwhtiM0Soigf64LzibX7CdJDWJA5Unc9nzChsyRg2Vrv3PX5dgBZMBSnGPqCgqOYgh06iF5wh7Jh1Y3IdOmRNKsZnmansyUs8djM+cRTvNqRinChUEWdLfgzB4RN6wtpHCtDS3Ew8zdDRwa+htUtxqOUbUHDprBvm59i6Ax7g/u+kenB9PTCAdkrEvY3RExSc3ynlQuFfWe0ZiZjUFIidxEnheTrsA9Oa0SLjS0IS0Ufv4lL86PL51vqZFHTv8PrzJoexJuQiYenL0a6dwbvwcpD/SVSdHjQ8ZSvVMS9hzyG7ZzddjvKWN1gRxwu77bY2M9TTrnFLU9blWPbUyPIFWsWeBS9tELJADC4DXSS4MJTegYCOr8ucHzrqpqXTV3icHKBBSio3opX3WEk2hwq8cKdaEKM/QEo8HSTOVjI53CeMbtsiNrPBzgkBRHMWsQdN6shbZ7vxUpVjNzQB/z5LiS6jsEzfiABG1jGlPuD2bX7ts6Yf1ifjqi+6CLZXoOAo+AjlGNG+eh9va1r0iQQLXRoxnHhWFxPJkJMfenx6NyxCH4QPQ17PiV4t3gE+t0Al2fINgCY7Xl3YE8me+1WDzGcPogr2R7O7u+Y99KxFzOv1CgHcNmanDj+6MhZIPGraKkyv1nmad/w8obemCSGygtrB1PEUmpxbzKbN9sLcSTniD5uh3/VuWRB4u3qrZuo1iI6ZjDYn4gg51OrSOc5xOXAuUAkCmGxDa5KASqWRMg9nWKoc/V1HS46peMbVPY95UwNNyMvlUbMr8A06KXczb0hB6/jn7DTIIGvNOnk/X7tT2xRyPNJYx7qO6b5d6VmIci0icyym+NoYMiVIlvWug2gAvCpEJF4YSpdyXOwk1jaadOniL1jkrf0+pYFb0KXA4m87r52uaeN/nK6/KIkPdPnskUKVrBIsT6vxgWaIUCElUsQLZDd88KRzhYZzIe9tTQKa3iK0Hra/G5ieqf828WY9zK6PJuztwfy1Q8fEinJBR5qToRGlLBPIx+Kz6EpFikaZmkvGRcI3Jq9IHLyfQ00P3x8QUNjZZNf0G9TQnBNBTOdUI0Vbw6ufKr9IpnHKsAoSZNmj0+FyZ5wa2tEvgjvexFyKL6ZABOGIcnkv72R2gcJjNgwvtgy+4L5ZkbAWGa9e60By8LOIRycqWxqOBKTXGtseB+Rn1st2QmPWn0/g91JYcDolhWRnjyn7RbGs+ZoCFBeb1sUh7fl8yZ2lK8Y8njHsVu4AIgVJNj2TrDlIPiC7oy/asj3f0740ZxvNzKhWPB4zTcfhZpuK4W6rM5r5gJA09+yt11JMHjTGUaYlW3LZpaemT9uVb3aVGkOyFti4pJfFOWBpdgKchAxZM35rbSD6blyc5BH9YVljMFFfjfR+xy47gUo9qqBIPfAjMlOhDJZXKyNHJbRf32gK+t4jJz3rg4JFywDY/DlUfiEV5otKu56pBGTtuhuTi9H5krvJTKhnvOWvk2C7P2y65tWuOgDufM8BcQB14zcJ6tlkuXQeZMj+k6NV/RC+PEMEAG3EPzmzrtOn6wZK+xAnQ3VyWXJBHxsgzpIIaItP+a/tXJpS6cDa/2TeitJz+Jy7+oyIDQ56Ou+hlIxrYBUeWId7Ig16bQFnXdZC2viwuJN5/nHVzBSmjZ22bXPzmvzGMRaEta7eCN0xJCv8SFcWUhBa6ZqoN8MA9bahCtepqRpl/hBcok29ALmd4TT5IGTnYuICUF2sR5m5uINwoIQ9KiWDcOXgnFA+Y1MSmnBqP9TgBZwfzYppRDbYULLfnty+BtblZ0geOf9GCJKgHejleMr9/Z0iAThD1xSjMK3KPlX4DfXkdbmj5ZHK5PhPw6KUoA9FstKMOnKC0KcH1ee+Fx3mCC8a2MO20UxL7GtQ4rF1lO8/b4uLy8Ayt1iSZrmwiVU11qiMS3FbSVUY0xwYbUnH/NgE/DX37l2arDOiZL2r3Hrw3fRrN2et+cYhNWz3522a091hRKWECAxEXsbn1p4Pc7+QzDPi9/f6QxoDjXatJoO9UusKpBolNRhbvd2hXeOXNrM8T55yveihQQTjEYKCAgmM3xTyOgObe8bJ8SGK5i2KUCvmADbBwtKQpDnyjg8JTV3uEVbuHXGgGuzH4ixJbwic6UX9Nn3TJa/azTaVm3wDDKZhs2OW8aL/fp3/546BjkycDxRBzrajYd9QKP3TH9Rz0BwOFpCcASVrM0oERV0XZjc0x8sj2YMid9dmb0FDUIlItGox4ujCQVB6YMjfX196ViFgAjwMoi/YZ08mq1w2sZAISQn+3eLsJ+QEh1YVgkQGHequqzPCtihnNxW2/Wd3LVay/Y570jAKk3at1W32Ovu5VMm4Ptoj2oSQWWw39xhIl2DZUAkzBSBHBSfcAGB5/zeEvzSFVDsyXeyDPIHi7/iPKn23LJSSb5H4AfF8F71Rgt+v+HrGll+9YDidovMsmP1L+4yGo0Q55MHVAhvdgXNFYidqjNiuS0oXU4uOSIrwe0gQ3qfLtUd3EPIS3jwLdw2bRAO3bRhSI+B5W0F0DxeWMbnW7XxXH8eTtqgpOzAv/D352v4p864cH8wPLQl2RpUUHoeyuEQyT7pSaWISh2T2ZjDnz0cNeqxamfj8RTVtqz9XY8K2sPZkP5Kp8rhpVGvGcPjttXB0I61/vn1qwZKY8KpiD9Y98/UKIKhsql4dyLLSLbLWSBM+zNgRFBtIJgMxbuchyeNmiQLNA/ub3P62gJwwLRLE1dRU+tvtKCVkH1CcUg0Qqh3XAMKDKbSdV7lAbv2rnYqDF9crTQVe5UHjUgOViV+G8eZfceKbt0V+8CjK9Dm0lXObht+YjKPDbxJueoU88j7FyoJpS6X3xKIIz5bQHjyGE3pr8z6MRyzyy06tJdoqMTGZTNCGBtNIKPEsDExYYkQIc+q2JCnz68DtBJhtyeguEclZu7HWOHWOzRbZCZBhM7foAL5j4apeGSEnbyvctF4mShRk5oSShQ4VvefqU2k9/rUwV12OBRulb9xOK0uSnjz+owooF9Z7NnnY/bjKGaWaiZmWBXsTC80UbC2WCbPhm28O9dYZan4ozbWGh8Oky2gqn/rOh+mxcvCaR5bhI7xdDA4b7jCPYo6FkwT4B4Gas+hoqTtiX8z72qtqROfzrSSLZFdUJege88vt59KK5lbRhYprVVFyqMTPBfgmDywnKauSjFYa4/pa/n6J3P4LzxmqYhavt5/VzPWFGO/pHO0ULCMzHLJXRJAhFrTPdRLZDnWykTsAh4R3dszUAiVOynSzKPtUWLNirprszbdbg7IVLrTYCNK5AhAumNWcMFraufKnGT6S4zyE1WsM2QmOvRns/Moe/OIFcpGgmFPvyI85u8kFqrUu5fGQiBpTPdPvut11d7jRqcAx8EH24OcDZ4K5S5P9Ii63mJRirG20U2WY1gGdy6vxrUM5fQQ5BBQo1GjvNgYXcZufcfbgVtFUrYEX4j3dHp+PuPZcIpELzHpH4V9SCfUDzZQpnjDWznPqJtpoHoX/+swTaVbGvnwgW/X6V090eQGL4eb3v0f5Dx656iPIVsbVMn5WD5LrxZOvHYs8Cxb7TYhr+OGtgqVqVU0zdgj3PkHBgdVCYJTkd8Wwd9QpoZtSBsJAJRu0Gq/0fyXTQyQIFtzG9AVpKmK/14hIW4j0yXDIWGqG8SqiIvhOH+gftB+vxMukJrnAxIvjbSl4HhCQfIniNEou3O6xYQqFRrNe5Ho2iVHntCFrx7EzjvfgbQww9W/MD2gzp1pWUdmSBwpAX7RiVI4bg1YQ1YO7dFypJ2cH9BJMBZjArEEkgevuQSGAG/cEV5ocHu340Y6kiunpGv1InykapUpRzriZpLxEe1SpckEwYA9uUQgeF5Ua2T91LBGZi1jImauD8NsvSY+TjdZKJNyeSqzP8thgupyGEsyhbCARU/dZPSAFfdIk54iWzpMsaw5+GmLQPEg4MzKySd6U/xPrEbnr+lz+azrAytMNCiLfgeZfSv1Nk+in66WyOKCzMJQ7T8v64u+Yh6GxtKiKJYKJ2A+2rI1XFkjHIX1Zc995vzCGD7Us+aQvMIcrwQjCFMc2iKYmOtKBuxt7J9K50BGIUJp1Ql7CgBmKJB93FH6P9mYLjdjzFhy3vprL+DmLZcYDxcyFgRzuffzwMkI7gKczSwyzQaU06S1PVN8cMHt6VqSmtBtTnGzZp3Rg38gewJTJHpqC3dklITD2Ckwy5G8Iam1WLnpppt9gYWg1Xtl1EOWarNfQOSGUmw0bwll7bQzXZoAvqla1aL33S63wpQmnKJWVlygmEeSVx2TNS13qVDA1ritJtYwIH155OZXhsWYekkCLrO13z5p+KEUkPexch0kQdFL1rCNLzGgjXFyUZpkus0cUQ4BPcdxUdZZanWZVEpLZuLj5k9HbcToiKEZAK4sR4YNhkxweJaaF+GoHgSt1I1yedMZfaCoYG/JMTN8JtCz8Y52uxa11AuoC7I4c7GRsm4a99+vRPis0/ESy7Fxp4kzMH4AvcJc5Jnbr8uFlxY8kPyD5S+GLKfhYVHGEHEdTSDdCuc6fynkUQVvPn3L4NcPDndPmhe0l0OfsG3kWSlnipJEWgbIaL+RCjhKfnmtvnAOSYo2xtFkOc20eWg1OvexIxPRnLWUWtulErxX/Jth7Kkoe3kRjCNcP+ORf8Nkc6ZWI9Nm8fhZF1ifTVvJbVF7jZIfuQ4LAb97eRb9nS+VcpwAmv1dXt7VZglXpXs0jUPzXi7mXv+FdIg/lX8ObjkCjHvp63R///MFj07zFg1cAzuGu1DPHU6e1pZGvKHWYAxAUuxqI6vfE8mCm8B0yw2sELFZo0LsZqiOfPeKG9eD4KuqFtyxKV+JAFroJl6bOsiN7TlBINfrYu9ac/nz1gABrAfQzSRzF6h7eus7bRBrjKQe1HBoIwaY553vmN9lB3EjbBDVSzhmKAFks7hthB3r0hkXsfeoCORzXcOCs/lrcE9vhrXVUijhOcceIyhegTs6HHYYIrt/3uDi0eOvjyZgbVmkFtYV89HO7TIE1G+5e1LBkhG2rEYPk6bvefES0wCHTDDhHZPABvM4R/e0PXvjOpmug6+V3b0CPvNkWH6tV5Et2ktGThUjrBQ/6WZ7YGQ5l1xq/VGeU3m8yGXJr5x7mpJZqotNQb8e37SJaNFI79toUJWVr8TCDWk9ESvITlWgedoYRkjoks3iMdnhIyqswKREm52EAACh3LBl8HELQ28NnmQSIAeZSq2xlnfm2xbNd+FSOTTOn8HIpKTajwisLQtB3P06R/lTHPqKHugw3vLF6BCnmK3c7ysdf/qtlPPRjLxFan0aq40AOhrd/joYC2TdnELvRq4pmAp83xNye5o1U8c0321Dshr2uqPq/dvGu4+JEHWkTiKKeoOh3651PxxMrHFDmsJEMrJMvNM2aW4xbT2Ol6hldWr1wR4PNKmWfVRcaZAC8GPfRsi857r8r2dROpl7oC3+/1I6qqJ+D5hpCWjO05JAW17IPq857A3tkv49PC7MX98jdSaTkWVuLaVBbXkHqmO45zHJI26S2eIvoqTnQJ2w6OSnXM1DP8IG54spBM0xjYP224hv/CrCDFkzdLQr+91qVpvYTFQdVvQSENbOYqq5D+3WqMl6wQI2zqwaHpAshOaPrQzuhAMwN7oNYYb9jPpOt6v3KL/wqvLfTUtd+hHuw3GorkrUCRJXsjm6LFbstOCgetoW0id2XbXu4wqG2UGWxSd0jyLJg4Jwq8jpSTuU5Tgas8tWGRdBMwBkJpetUCu4k0e2mk9elHWEP4Lu/vDaFKJ5Z8a5zxezgwK4DdLcba1YFKyHkV49yNXJLwFEIVge2uRs7guViE647Lr2U2N2xBV4gmdBsk17AKhmA8heaSId0BFSV5uOhckv+6HJotgOuw8Q+YU6fR3fRGbttuuHvdAiE4yhn+xd9w9HmPJvXBzhcjaIq2XdMg/QPnANoz3f4H9xn2qpHHuFh5zipAjz2XYOeP3yco1Yx7X9iDx7ThuqQXFmpRBjQr+9M7W5PixV57LkQ9lazINUMzVo+MlsI+13v1VXZhDnjp/1OYbbIGMBQCqORJ5X8rf89mnTdvirjqOt1C7h1NFQmgtIRgpF4Lny+AfdS2JF/swiXpdsO2ryvRrLwIPD2MgsGmzY/s5DhBECWP7+q46YilJGY7venkuJ87vg4NR3KdJSXqI7R0tc5Ix81si2IP8A5QokPgT7kQvQUJAHfW+L8VzpqvDtykapVDa3N15RPdail14+ng8SCDzvMYA0MhYprllz21vjs3Aipuz8O1nrlDfK6C/I6/Bsguv3nYS4QiCmPOdlKHXoMMraf+n+D885bKDRAMbakXx0+9XOku/KUgdLgVY60kWe3tCU6Gf+3TjTbS6AxZb3G61J+W0NeYwBqkn4mjfogyi6XmEh115DvJuvq5irjSPSTM4oW6iRV2krNsUUYF9VU+SJiezyhVHSoyiWWUGHZpgBFv7wPe/WPpOmeQAOh1+RfmjWTg10mBmSVgJRNpJyVew3WR/CuttFOG3QqENuU3TDcaPxlbINMHy/80Vv/eYjqvvLa6w6GruryiQB7cnlSPOzAxvDaZ4liBneN0Ywdx6dLRIxGVgxBIMIok3HaRpb74tYZXpIw+y9jddVamPrnMwgmm+XNNArYiNBi67mneciwPFOh4g5nRr1u5hFwuxKOYxRtlRWc7O8RToQXj5xYJASGLHHY1v/m//bUwFRnsD5ppzTsHVHd3e1XxWyRMYTTxcm44FdtEVmzw/TzJ2DQtuhfeYadkUDYoarXiJauZkrQZODpGingevKUTHcKCoR+lRuxOfuT1o3LCkkTpUlmnWhXATX4CVVDM2GKnjLzTM8fiM6xCkqj29s6PI6QVBhKK63wrVY6v2G6Wb0IIKVh+yfpIgIMXnzNjDZM7gu9VLxvt+nLm+acqUMaHixm//EjsLHtxLdM4yMgDhf0mb4eQqM6V7JwVqaV0LdOLx3b2w8PuRBUW4h57lbmXDreCpr1z4t5RQlr9uMosdobn6KU7PaPogeoOESMrQ1Na6KdOMu35LDJo8e4f/5kIP1l7kXVzzvXQXf8lqPtynP4VCCkgS7er3hofdapDshEx2SFstuzl0qbCEr19AE1daqLmU4IaZSbXNK35GQiHzUDdF0ctoUgSi1IZW9yY8G0J17nnSOWhTU9QYWvYg0Uv2nRCneZ4mlMrxOQpOWmqsRC4rZY9Deqvz8V68cF8GKCGnf8jIhxp1gHoUhGqecxz6cefAkdS/S2w+lgVGs+oYDwlimnWHvOLL1x7GxrALytlllgonmIfr1Mku9KDot4tigCOe8Sr+Hj9tJaRdLZvcWEA/Dace3RXPthGeL6UTzEqOa8KrDauBGQDaPjHXSwP8mbNx6XdUsl5/Hf/GYUTvocUqkiFF+YUzIPxnV/SRrduQU1Th+385Lbs5d/UyfXaKxT5dDWcKk+BQVUI1MCJXk+vLGxGE0c9lqWjD8ZUjCDQLi6hGBYIsJedSKhD1zi5wdmyGlE0S91jWGLANeaZMZzQHmnXUx9IjnzjI+ST6k93JMiTWS2KOut9u7DYIxoyrf+3AMko00ZiOuJxy/uKyDWYE2tx0pCP4CnDWbQAMAgJOQrOHopXbxF78W436igFgEgRg/hLegxrF1WIIY82nx7uEadwq21vM5bgmr9A3LImNSk30kc8+USW06+jTpXl9FsGNbGO+aOWOmsjhtTlAevviOZ2tHGIhhaSagabZ+M3H2o452IOdEhv8J0pKgiMfoYJWsK2ixB6Y4dKuVRQVzR9fQrFoVpVwVIIdT9aGQ9Y6qJJHEDL7nvIJX77Hj1orx2N4dksNZIK/LaFwEkS9rX2Jh/CKu6HkmFFQHuSIxd2po0T+fvqWMrUmtcaJNHquMOS0R3TLpHciBQ3hcoavY/yTG6J6MFwiba5C/vi1FUk2PvqxbqezmHWeiAjMQ3m6nJbtLc4pT2EOpFTofMhfNetu8DNpayO48Vdoi6ASUttSS1hjs4gE31irNKPciYSQ7wZVKYpFNHpXRwUamI5Ros7es3Tc3sJq0nZtfPz7haq+osFW//et5Vzjuxt9ELIfo6KyAMmfwkypGkBm/UTWcAQjel4v4fkbISJ4qDvFqYkkTPwSojN8e+UbWMd1wIOZTTQysUVt+H01y5jYvZY1Ct1a1Pwsy2SEh6Rn4YY8OJ2ENlc1TtDqI8k8cMngvEQYXFq2eqHjabuxpZMQx/aUlxQwxcmvDZSSrtUcCqVUtebl7c0zcUExext6rcFVjTnpV82vzuLFBt/eVqlt8hm2jn9PagsR8U0zmfTaEnEKU/MOuB3T55Js/55I5q24qc+k5hGRShxyfcje+BrRfPwX6VyA/THyJU78eyNL/Q3Vo8qFyWvsVXUh73Dyut6o+GhYwOpLI4NW8U7PNSOBuCQ6IR+GI/5jV+AAbq1+KcowPeZvKaLlNs3aXV3SeKLKf7M0fLmus3thvKIptu7MQoqgsmEBMu9/Y2UJnT06mlNxEPESMoK9pbxa+N73c+ru0xmS9OPdUb7/3dkQzqpMnc7Lkz6ZBHNpj5Zhw3p86Gy0Q1wtEePRXKj7uDohC/nE082nWNOshd3fWFuA+K6mKZljNRNTjMgiV9V28ex7wv332mDtlGIH15A8SztRuRgei0ibJRoxCzdwNAZyWIXPfXfD/vN5SvlkR/jJ3K0NOUSXVv3nPwHG7peXat0mY8vUSYxVZ42MzcvQ3YXOcQTF1T1hGZpiK7P7H/LdX4scZY5Cebr8aQ7yKlmVsrho3W40CWH5cFvwAPbThpdzlv8alKAX59dgTV5VCp5G7biOEb7Cx+Dy5dffVN1I6e1gXXD78kO/AKZMLpQjP5tYGeu7CxVt5bophCXpaE3mZki3bTSfMAwTJ4CCImtTeBkdPFaMQotUv1Xeh1Thref9aHW5lyGE87oDM3PlzndhmuAgrjA9caPOjzCkbDrrPEkXD+RMm1+Z3txe3OVQyxmL+99ToQ/RKCt92LjYC9QcV+ESn2tP2fo1Y7ZmEoCmgi6Onpm6GZJC18iQ6/mc+SZ6lriNwSgbQzP+vMzhPmhLjGpl22ULnuPkdWeLlBuXG7y+WSP1YEJf8WguYypQho9ozntF53qeHwFfGFWvf8RfESNIootEmPCmSwfu50xlVDead1TgEywvMEM+W5dNEoKOYKvVNoNujfk7hCWKmCgioqhSXVIk27Io9+3ocQke0FjOBfQogH4sdayxiaNJhKs5WNKeNGiI2QhKjWcWFzKDnl+CveSTkLJ2quq+ipeBfxG0YENyCepwZaNE7dzyzqMdkSI5sSkk7m2bk4MkQJv2VwZurSoQJA9WyKKDaDBBSkhIsXATQg1ykiFuOqhq+DSL0hEheMfvdNYU5vLSNjZuX0IkxSv7qpah2tIeO8l2FfDOQPQctCQlWQGDPKYPkKUJwG1MtEJiSkGYhVvbi13/WXlESGWZrLPODZTABf7F2w9x80aZXCeuLanDQmsoEDMOf3x1SdX9BFh1dW1wAoH9IYG4//sEZSuI6Ko872/GfbgN8NeDeBtRgCiCAgx6cju9uAqT1NQtARodJp34D77Dlgs02zEitIPr6pnKlLm1pzQUF5GdJavYgMA5cqxarFMVonDvKCty+j8/+14n68f/GQdbWcYVSDH96f3DSdQTXVyjvq7wvNAte7X/fj5t7dKs7Wimei5qFte++I6VjCPbEQA2A6CqUXhOZvW9IauIEikHDdjhHc5qSI83y3oqsCSczgkrWVQWaaRndzlR25zs5Zo8p4Le4NdXfYCyNmSznTPr+qBxTy+urbsUMtaPymKhB7mO1E/Y4GDzXKHiM8bePPLZJi+AkZDs+CflKfA4XXYQVGkvYY6LD683SaUa6gu/eOG+m5Xv1hEipX81R+yhb5tMNzh6obK1v9UtXjM7MFq6X6X5AqtcbysvH494sozlSqKCLiTsOVkx5rIMjqEa3179lFyZqrQLcRJae/52MIrsj9a1E8YWb3XfgSt8Ya05x/GA0OBoZVp4+ybhLEBE+oR4VhMpX6GilUviU77hczWktkq/jPy8flgcbYTO7UyI6PEtKR7GJGw8NqFIurfgf82BOWzLdSX5OXfonpLnr5gMUKPKJnUBA9CeO70I+utVtcbH82S+cZdwGXn0CdmzQGnEuIR0vFF+b8D6G79AFGvSyYZMkjF0rNu2Bcj2TXKvaJg82p6v4vxcuuA/JiHFrwHLS5rleSVaotFNidsy3YhXQcp/97PLjmRgYHnNBe2m0j81oshCyEQfAoxOkFY6I0GzjadHLGEk1QXkix7Qab8uAoljrqdXxJkhx0rHOZ3xdRrTaW1UR9rz4WpoHxrY97GDgFYzGYWdilG2qINnBL/aE0hjgx1Cn7vlgumfwX4uhbaRs56ZyLfFNxGH7jIpfKnRYa68p80Yc1E70gXeRfr+eKYt+kVF/Zg+1YrCPTLeLBdKnMyhIYnLP5+pacJhjNTha5ZSIH463LiYxy/xFqPC7hCHbVZV0+JMy3WFSj7tiAi+LKHzTW72PcalMsfwozILK5eHmSqfODTD34eVNIRci4rvBQvYK6yAMYVJKjmF1vCC94HTgF7xJsi/QHcMbBnFfwIeI5nWW8jJdpbmkoB27eNYMAN9OdNN2vXGTzB9q/zS5slXD8y4/c7HQQWdr+BvucNhSpC9g7+I3lWD5pb6tRkAVyxuBai8h1hOebU7KYAqryE33whYPyTLPQOi14I252IUlDxmrM8TDlG9xiz6QpoqP7NfWA7nDmSwitqRtWAw0e5rBiSZag7nrFvZCQ6kQ8AhzRyoOQktchWYDQapTFDbqKcH326aCZOGamUqZY/ZjJcq6+aZ0xLtibGMsjso0ddXsBc7aspr4lsQs42ZLgNqs9IcSY/3ucedDcgYUltOKsqrafH+ZjNIpd7Um6HRO52HaiB5steYvXYPmEu8P4Xq8bvGscK6xA2OZnZglK1AsDo50sLLmyAMAVZLDPXOiymESF39H7Q5qHZwAlsdJfVxn/9HIPcsimkkXPsyft53aDaawd4xyToLc0oBRjnWyl7NgFLYnFFiy0YS6MvCN10AR8/C5fvuEsdtlymwvafmOjnc+347Fe/WQZ/c2PrZZ2YOZ+/iL3mULwtWzz9xM+3w6p0O+kR0Yf9bN0q27J44O9TxPCZ8Wt/Xus+T8mD+vz1Fb8AbVCgfcBa2OxJca17FhdKneOBrhoiTLgm6DLNFHXORDQumqHpEkFnJG53kT7p+fOn3u/OYJiwCCLCghA8Lo3jRZpwdrZV/R/8WCPlMQNHUan/sm4V1UggWbTR6aeUaWMVRYG/Wg6lUxQmjrfUIrm+OJdEoDDG02RY2MNL2sJZ5tfWkAp+jDBPeq2b7lYMTqR+d05BaDsEHjFdYYZLrXTMmgy8clPMqwOLT4m0ncHrj8lzkWEAd3lY13jdTtukP6ITdoIGvjvjWRqBJa3C2iLvAPRLsjyC+0HHxkcU2wILiilA0Ltbn7DrZQjS+dMl9U/92GngfAB9D9Nom0e4PobCWZmcorr1wFAHZsa0/pfMGoJ3iKp09yMnyu5adQ3hjK6mGvEn5eLGboh/yK+9PqF7mOEQt6/e9wlNay3z7ssa9cG6eyN5JEzR5hgdiFj/seacak4B4UZSGhJ8kN7AJSKAgTiL9+7xeVMPi4RUxiCyQG2LK3KLB0/0kFzaHzSIRDLo/jutGc6bMQTFt2CLnirlYNHDpGciYCMZ7Ncf6a63QTALehPEQVniG/xPbTBKuFreAg/PXnHCxhbNKZqcWp2ofMX9C9VqutrLfL1Olexm/59SbAifYafmv4zZTzXVC+jLct3frCLqMRuShZv2nvpwexT6R03j72eAylest33TXOCUnj4OtsoNLP7LZtxtAFFczExrmdYes0wjKKmS69tNQ27CQ1eKfvFTkPPt/yFzhiOP8wyEfp8ltbOOpLyn2So0wGL74tmcs63NM5iMEEZ80Cgp+E8kfIeRwK5OKm9kzl5FcoI7UHiO9+VD/uNqosFFJNvT/+M7EsScs+H66sxYbd37P8HUFTKTptRsKOJn7gAALpVBANI2PxMB5r3m5w9Gcz8tESixLDXIVX693v51RiLjAFapK9Z04OlQo65zXzMLoFMvRpGdKIPB2fkj2dimsib8eEGDXI2emr28PdRiVmnsg1FeTEI6q1Z9eyhCA14DRV1ow3odYgOGzBz5ivWOWU/M9CSeZQCiCfDUxT29Zti4XZDID1d6OBXTlusdkrl46nGVSP+x4Ok6xbEOp1Uad4SnvEu9PeetQEOJwp2xMeB5N38ENj5AdlPAZU2ojxu9D6LIIKR8Gnm7UxLz3f2sqMDp6Ba+L3u11nEaEJE8+BK3L6b+IpnbV42KheflqWIAu4304fKSY+JCTj2/gATcxBzqejc9kChOE2C9jQpOKtXMTUo6715NErou4QRJCqSA1d5d1tSVDfDTMgMfS9EWxXbHt6cY/KehuTShucWLXs7Pkz76J9DgregJll22/yB/kDvQjIQzUsgAA6dOFs/Rf05Q/6W69hf0d+dr6l2nNECcCNseUjGMtLmB3FAOzKhCBOwRZbOJY9ibxrZTR7vG+kQ2WtyzPyCo2hOshGFmz38drSCOFJ6rD4akNlS0nMd0/QaGLwGYRpukZe8AC0kN4zdp689coUiNwiCn95BKs/Za12WUOzjtxr0R5ES+XAlTzTPObTXsAwgbv51jwubFiScfAFTWuRkRZxrYYPcrZVDLe8C/nDHtnlXLfplgyueevB3WwT51LtmkZg5jXnE1+lloZgrL9nQFGKuZo8GZA2jJEGLED1eBCWCwDGQURDv24HsO7U8meu9g4JLWGl9hWtYNtNxpyGnWrdm9SP2ZFELx0lnXQdFA5G8/lk2jBkoPqlgs30t3SJVD6kUETrSuTX4fVlQ3/ID+KA7x0qmJhpV1zBRGxg8Ndl9qRTjsG7N9VXjz/9t0m3A05+S1rIsTxYzeLXy8ajnJMHPuypCpaOXe137Sbw6YHyr26cxXF4EWjtAvAlYhsQpx7qICWsvBqrNmhpwMshK8Syd0PeaXJhQ2RlCeaTl6+yx4HG46vmgSOr+onROitCnALc5kImE6iZ/aLT2hPAN91rIQQQylPcPGHoAQ/U693bR3G2ax7N/MhNizhfClXvwsX3qRZRECkyy15YlXtuU4+eO7h/+OuSzl2I20Tg142f/QHpUIM1X5lPtFVWmBBjuvzTYL6zF+eujojwQVNWJ+KUqdNycBL9m1j/cXLqMvp2jXfRKVG8hkYbtwTAHpK3csfF4cto7t1RS8cAXSg2z+6mw8oRymctAEyFz114ytqwzw7M/X+ULMrxmjEfdH49E+937VTMcpI7r6llRGysJsuw2IDePCU2fBTjdCTzHcAAEAwVc3pSaKSeD9q5TTrBa0iVu4xkrciSflvt9Mi4rE/cyQcnYYU0WtZEi32N9jX+lUEiprNozlkSgn05rLhGSLV7rHnTw+1+p/AcnS/h8x8oz8HZvuNgqtyCQwweN4qcsNM3l0YZkqfAQURr/4Oll+6/7W9WfwuWxNnzfbGhcELbMCXVPIBHGimxETfOCcuAhOYYJjiG4B22gLruah27z/6/hNqP4g1M1YmU2UWsM2BFLayS0aFsInP9qVugsbKx96cbmsn54zwp8i8wRhip4sE2rvLrn+g60uNB7dZoi3F8IR8ZVqNW+hFOCxbtLUxEzEi6SV45s5PAhMd/XkyedANf2ftY2KSDvfVbPTejqvgYP75qnqQf4ciRdCf2zpGYct5g/gu5vyRSn71VLlZFMSwuMxSceG+S72DauU6wSubHWSfQKO51gudgCEFrCQ5NOVI64BhbZ3AKeOF8xWFoyfn+0feuN5HtVaEa/IoOI5Q2i754JBmWdKLHoX083qc9rkDwWka9Mo5EOAl019d0AachOQZIXa9P11AmMyQ6h80mPQKz08gnWEQfGxGebmT4nW63PmjCvoz0jSlrJif0Z8rbbFoWMyTHk+en1ziSq5+WBng41IGCcR/QHtK8uBCxjlbqWEg0k2nvOmcSlxjo5UmxsltOYt+f4+jVAHpHWiLak9lxy9VF4D+Q3sJ/4WQf1By56VHEAB+/9gmxZeipMZl9IZdHRKlsZW9hVx8Zzjew9laMjmO0ADCptQ/kP3i1MoQ7pATg21m0WfJuL9EOKhTxtROLJAaQ59wXv7bdY7IUau36tPDlr0/zVXdYCU+AwLoBUnMIktXAIavofYwYJIdxAfD25HGNHcRzrtQEsELRWRVRtVNmuV+pmmy3/NO/rAbqEsUxgdu7v8gnKZ8kSgX1l8pWtztbRPPpu89lDS9Rdr9lPjuVVDlyeiGbKVNeEwQw0YBagDqoTnaXLhUwr+BQaeASWENt4/8wYYI5VRdfk+7tyyzX7NLthXXQBJggOK7dzcji0DhpU5p4yc4Iy0hwbmZYvgXftgEnhVJ/wP6FCP0umj7UVyJWM/Otr/+pFv5JMa5xlJsTsyvBxuMEMtX+3mx9fhfKzfTV3OFA1utASOof7fAAJ/o2Z8NgYWHB0S+FA4WbzdLcqFFFuSYLM8XOSmgX/yOIKHtxjuEh/U2Amq7ZzVg4PvUtTIm5s+UoKIQL1kkvyoN2ny+4ovc35xdfT/hn7xX2JwxkBD7123hcft3lBleBS84+dKDSxVqRU/MNecsHVZo0hwZgFU5ZUEGDXPjoHW/udUBktu5rr754KuoQuieUJlXh9TFNF8JZ1Dz2A0wwW3R5GScY1tDfwb9Qn+gvgltzX+HYokt+RKpNc8nDYX/nh0I7lc4JrhE7vK/hiQNv64jiwlit3/XPciWtukjqqPrHhhCqWxToIOdStolkHvghzknciey/egrYoRX3tLdM+DY1ywCAIaeqR7pKc7sZ9hAdWgyzaqH4HXAvcht3ZPo1rdv99D5wva6HPHsoxlFkGueRjZO1cxHjZOE+PpnZbMBLsFcp9pgxStMuJ9y6qQdqpdcURoOixYEH3HIqGhSRHOZW64z6wEUn7rKy/64EOvKUb2UoB60Cbm09w5vR3dWrk4Q8K11TjI7/ta0g+vutYdWhubYJafv/sJHEfxhcOkATZinfYWF4Y0RENNWlKvEC0Az3Spue6cbCkWZHjCBhod5gNUL3C0m10GfwMl4hP1fRzO2dg9eogrNB9rn0P9OqZHVMZzb+gEWz80X71wAQayd1AIfubxUSMpfKAEnZCBLs5HOdYthnERn2r+tNtmgz55EJTzJ5DZvpcJX3qeZsoqOuSjLmlRB6/qQLO/jkwqDku/q6cj47xXPzhgpCYu6AzCpIP9pfSqp7OBPsRQNNnagFEj6kf899bwnUh/s3n4MC8UyrrvfMbWBpQxuy8xKywcuUmDlk6vP7gtcZulTgZlDc1dHKK4/Jl2d/efU7j0gNEOBLSX9jjHSfc5RJlg/VsgBQ+OCmcF5v5w5ZUjVE8GJWnodJTWCcS5EHbsc0e+8PZqyJaDEnug7MDSv/UQ+r2VA/8g7vKQfV9juIyavAk7JZ/XFGRbtqPCf08fja1WaIkIcEduHKOtB+hv1VhkmP2LNrZPVYDQ03WU4zKApg69Yt4usgBE9hdlmlfllF86g9B/JEw6GaF4igGBArWm7DuGNJ4GUJypyoey8WietdANycqFWX2YLPAGBhmJfmRctYKXwicLe8X+JxsMzi3wDJtrOnaUsrQKbbAuf5x9FrvhcP06YqXwZMudpmfGkniZBSBMAtVm3pomg2duwbi6kKCxP4WBnDKbKUKbNrxoH5HWQ6h4Kb+zhrxAHr0NYRz4eFva6B1RlJVI3u+8I8KZpUJo058E7Y5f2D8ULQjmJ51Gw5/vZodmKSBzXPqfnRAHwhdkaubuwpczfECUJHbgYLVpHRgZRHCZrphO3+7tbxHnCL15I6uTH/Ll1lIA6IWtQlAYXOrx3d0k8fDfdwgvcsZRo8qIs8Bu6UbBBnaN2gblNdJN8QnxMqFwoo6nlr5f+QxEFqyPW8cHbWqnW91gxt177veEENSq1zlZ/JCNs8R0sDNyVkdQeicRToxiGp1MNlZx6ns+BXFtWnQb2LUL/9RHDpVOzFg1jUO9gEHee+QXFh4Sq2zOLHMpFo3KyoL9Ml/Quh420xD5IARASzV+Mr9nUu1zn2SCtFgx8fn9s4wxK4oT4Ogxb2ib6lKBdmjfuOf3LYPdiE4dfNwlqNGXZ1S8Uy9+jmh/kDcjZf3So1eJjWywmtyE/8oQsW2RsWBAwscE6VMTOoZLG1UwoWnYbCfvY4aS3gQVKoasMeXkToGOL9fT4gxYVaGlD+gSaxzBTwpc5rWz0qj3wcVu7bQocGRcgVJBz9YtaJONqDTLDDrvWKxO9w0yNrWTnxXmm8HHtlMZsNOUh3CGva1j1veGFN7LZeJHerVt7TY3/TqUJVcy4g1vmY0Y4OnAYuPKzp6vmBvfC1TbBg9NGnJYF4jhXROPTN6KVv85ciENB2uMzP7o0kjoVRlofjEs27l8zq2BTEoj7RnQmzNWb/w9LxhQbGcoYWHjtj5fA2af4yfyb+gSnc29QeU9e2OTxnXZOxqKNdJJ1pdMxIURlOxrSBHKtrtG+MNsCMqmyLNfrbfMKg/ZNQn7/1OPwfJmv/ruaPPNgxkvY7UA+8qcl8AuTQ56WwFvP3EJTpx9ESCaz91obMM62Eri8qztbPhRZjVKdCZ0BhOCJbubFfQDpH/NNVQAlKoaGWYW3pjZUvlwdnYnRvWhmQ72aXF5qO0lkFK9KR9gkz7HFFdB9u63n8JSadajDi+7AvY7spst2feDjfAoY78aRobswHLuVegdcyfAK0zOJeHLnirmzcC5iyL0aUKj5yljZbWAjOv7rxlwSPj/zsu4h/7CRBXUjK+kCjTwBq1KDc9LE1ukm5wCs9p0lIvRWUC58KnebCGAtYhsdZvdyH6r6tE1FbYl/bPJFc8GlTPiAHRxYQjqDqo+bAusVj6hVVpuTByIz3UIReZVB6jKae4Q59H9RkEptIOlms3V3PYWMiBVASEHGTg0CEj4QAlAswx7d9rqmVWHAIjGLVtHCewyNKnrf06PU8KH+L+0a6j2/cPuhopgzW3hCSHsx1ee1WIMNKGbYVCCHRJlZN9IMC0bGzuvbA1y8dx3NY8z7ifgb8xzTyXbN9DVzgQDlHIXIAUHQNwiIzaq/MOc4xomz85j5IRTDugE5KbpgLNeqHCDLadr9eup9nypm+qHAO7eVO3MQJWIHGraAGinXFIe2CHqohZNyAFS75rhD6oyR69+jJQt/YigTkZZUMqGqknDVdQSSC4iIbrErdrt0S+xiWvs8hBso09TAtaFv4PbigZ5FS/sfbttT5kTr/SzxyvhJXgVsKlNU7hvcn5cfw4lHc+KotHd9ZbJqPobp4h1xcYAbNFOMEU12GehyKbCM7EZv6oFbPLy4nwbRgTJ273GCPFwBJvNSmLHqAU5OY3VUdL6qgBCJUaamFLFTny47IUKrTtLtf/LWSPT2FYO65ygTXSlbnuigmphcAcnFQlnSL4RKX5TB53MfQCm6Bv3yBTdp+Fq1vrVN4vjDPYdVBKwaNW21daSyuVSbHOHt4JU7Hp2PsufWMxmF/iGDsCbyRmkeZmqfSL7D/O/BhitYWS/rDdvQK6pHwhs/z+pmSRULSbeQYjzKYYB+GP6AArcuu6Y9FVhK8z6sKQoQCfg/HxkOTup5+YCqygJdzBev6BZ4uugdMDDkat8MaBm8Dy2Yw0ZSy6A8zst/+PUpDIt6vqcKkQWcakMMFEqWSGZVux8Ib+AQRKAbaqA83fyU7X8h7ohK9DF5+31mCPgmpYhyiTY9E28Tj24DPqJ+1gkRqMK/fCWwxSjlMemEYzTa3TZQMtITc7URq8iK7ixPz9nBtI9Djst2SLCKO4tV7E4Bsvd8VyWV2x8s77JkEu40q8c58lgmyRKEU3ZcFGoIXnq35nMNn6uhgFBC1z+HYYM18txB2bzoGFAxQLCTuRVzoxeNZ7O2kZm345GLx4qX18odgpUwRwC3JT1KWfBiuhacsPjVg8BCZjJ/w/lumh3uYDP8OHcc9WhhPcxO4omL8IsRoDUDQWsbcm4q+/esng+6D/dZ84qUWAlqmsRICPOPBFvcYE3uOk3oB1Eup4btuS84dZ0arCBk84GDgIlSYo000CdlOkqYu+X4YCX9VTekmLxWvH/9ZQIWIRPO+5dYAKX/B0rKtkxrW/xgXr9xb1TjcejMeevuHmH8N4aXq2sKSWEicUN0NQiUreUVda/dkP8lUXLpiiuoRnbEYQKq27lyi54oLkBfhZ6IjgJqLh2RT+7rvPo71DlEwvVvYSa+3+dGMB3McNcr2OiBE1mMZStK8EFuhB8NWyEMgQeRDp0FPzfhDmvgbiEz0hHiXy5dSTRaV7WrYHtkU3oqMMdIgJTBIBdMp3W7P1UVtAewbXkNlOlVRPYnU7uxAVTK6oPqJRM9VnXOZsi/qxzQyQw8k9DvEkBOFClTjyvxQCB7v9B4UPhmXniEsbk9l4ZKxPjbmcITYuzzNAog6+hokJ6jdN91ZVeVzfOtwjuM9NZy7UzMDKWN/u20PtHkg23gsT3ACyB4kqpZnSG2gZABD4IXMXxZFAgJTThSFcNAKaqtBLESj7Cw/XHy5Pg5HCwP7cbe/tCGKtOrfluzQwf9N1AMRsXZB9XhDikwmPyBA87pg5Jm3nDu/2nWYaqySvzmHzm6Z6uGRVNScxsVYhOsKwSqKNxuo3hnSbyPfOEtk24LpW9Q7znashuiu2IpCt01zYDD3RD9c9GQCD4zZpDOttBO2Y6jChblka4j0otYJxOkj3n5Gbce/Q+yXbY/IjYKdFZ84Y5uUEzixM+mqP3wqBK7B3NDVIK/N9SHKBrTuxGRv/PQMHydK6DLpmni9vTK2as8b5zZ1zw2M5+aNjuNNqjuBD56tk+XIg6EumOTqugr6T7WThZ2a5icvZ+eHPvIFmKiiRg5yKEZl8g0AzmH6BqKrQ4YmsEiM78s3YVUGoN9wljWfXq1M7bJHlTBsyI76zopdLCePuwRaRX2bFuSTg3zldR9Q5krUokDtOPdufpV72+8+hf284LSm2KRygvcRf6O/bUMaYsgzBDQsXqKYU0GLCRgtpaLHyF3J/QLw6l+boZ6QlvEzQmQt8LNYNOE2N52oTXC2Q9nSjV0dzHE8BfFgDQzV/jSf5h0JLqke64JHDqUnQYkALGEdvNCdeU4jf8WkrOCWIkYUhlO8QVHE79FNn3ALc4Tg83q7kBCWTOUhOltr7cYsAi2gp5U7q/le9mw4Mcj81VE/mR3hwdmBDZ7o1pqGNjH8xOvD7A6arHRv+BaaK+4ufvM0lUnLmJbxml3jPnQGbaLq0Gwo+eGn+LRwu1fEJNV5f82z5PXJWPdaye6lPnPGSQtcKEhwji64eWwyHoVoEbNWa/ZYtP7Z6XneKaQj4kMEE8eK0FWOVrkVgkRbgGemYeKCHGeZu07mb5+FMAzJ2Il5cOkK1w5DXeB5+GkVzanYAmutO6KES/bLC3aT/QWYT5K57Dy0vhSORSNdlvZi1ELdgVZ/Cf2a2VijBguNAXoAyQnZfzLoOJ9dcQAR1PIeLkAioP8c5OmmRmYSPCKyXjznYmT7KDpd6Gx/Z56qn9XQfhniWpP5SaY8z8HTekVXr1ZNTRohqOcZBJwrvjy1ZL/hXw7bcDibn9g3TvNmEcXOQDyj3YoPJPIZepH4MI/pZYPsG/p9EPPk/uxgc+o3R35TCN7Kk5X/sVRWfIGcMxvp15gpD7m3PItd6O4ac/OGkVQovqAVj0RVs+M4Utk2TMPHFaLQW7vm5LrcFibPpAlxMwotf2MNUjfNTrM6EfythoaTzUWQlEV6gqauPmaO5T4oZDTUhb8hvSPSPGwZkrqjlOTFUALpZm4vdv4spOy3KxaX2G86Rn4vNBkwgUR0I5Bg07qCghrZ6pZgKLjuL9G9AEbffR48ZwnJvSdd2upmn2rJ2wdWM3F2+G5RzHFyNsltEKsDzdqGNx2/X1Z+PPBkCSF7hOU84g5C+96umBijziL/ZfEDktNInpYegcv9kNfFmDjSWgX0Ptx4vXYinmW044y3vSG0h22UlCmjDPgjs+Xxui6k7mWbAKkgxfaKxsvLKR3V589OsLspE473R1wYWbf4R3vDu/3G/IG5I6PgwG9X8zPCNau05Cgbyx2fm18r5UC/dI+Os45mlbW+zhwxXFHwy+V+wB1zbkPp19NC165bJJk/ndzp83oAK5wKNF2UlUI8lL/xb30wXrj8zmheHtt1QZD7b4xB3nB2oFzI2cHzrchQrm/NmkuVNUUZ3tq8SyDkiPTYZQ+/unZez8B9UTgRfgLz1VxMTgPhLUdiJiB0CpA4IXdzqeMHYZbtgUMZ1B4MlyAm4FlfLhuoOs1DmhwxE83YdQIlxkOsqVKCVApl4c6Er1N4Cwis5pkihQJdAJO0GOfOGVd7Puc+Q9+yRFAuYKNfnA6FdFvNafalIRpGUbo1NNmo2J7JfyI/DjQjrJs3J9+F6WpwEhWqvS3p5pHpfYzAfnAquSxzkYIAYU90ulF5IefDuXueOteQniS+s1eXinQ4cmtl03/aDIyEmhDMWlw+pu2GmWNVOPfz98Eh/Uk7kkGELtEDYI4f+rFaskQrxfDJRwawAIEQlZTAJxsXJVkJ3xR/fAsb9GwLRZkr+kzSNIbhU7EGcaiyuQkkDI+o3AeSK6YutjIVIUhJS3BXK6b5gWrVWEuMYwR5tMRzmehUdMyjWmIU/HwdhIfF5r5kESVx5C96mTdQdC8mg1lBK1jZh07PpDEqMVnzw4yFluCN9KJEOwYsb0pRxOhCY2UQfhXbA+ydOCi9Nu7/qGkLJHvAGmI8V/VkcpevsX9cXG+oVEPLzlKGj76Kgm3uZwhiR1AcjDxCULasmmSx7vXCDoPgUe5FCxKHNWWkpo4vMJRPHUlOAiygn43UBcxUXMGgrOt2KtqSAodcyvbzY1sZaIh8xILLF9bUdN/GADWdlZlJE8EUfMtM+SAUlF2v0RUi4PHe22pRkA1lsuvVQWTH/pfdTLFRGnbztlxhbw1cIR/2WJlSBwMyPV1RtsPlP7ti4NUO78os20hDvrg1L5yiz511F146fcCupJzgPK1l7NIJ679AC/JICWf/u7a1C71atUxcPILR8Xl1+uJqw7TyOkiwAEtrS6etx4Q5hsEZfuFpKEobc7ri1c/onn/Tl1KZN8C1hCTP3NAACdldt11X6BcGXfIHaF1xT6BXmulde4L7Iqa87+Rc81K/1/W79U1BasLH+AHuhylsdA2zm3otYjpuzZmNeTQQzpX2pO8gGkxWIASrX1IlEajxvas7r22HXskzVi8xY9ain/HodO1FVXVYvuulwuVxNJ9hgyzIU601mYd5dbvAVRoaXS5e4LPamSKVtyLpG0RQ54jUGveYjF6e+5+9ZGeri0IbRP0SkGx2e+gw0E10MbNP5k0MqgfkFyJO+G9pTnOof/46v76yopuEOH0b7bborBVNlwjG9mruNKdh8g5lClfLmMbUUfWZtzauPM8C9/Nhm1kWjFWzklfrgTF26xT3uAH1mAyn8mgWg1xCQ1Olx48nstm05DicVeLYbquFbkDTTdgqgDnVSmDPSbnf8jXZ5F+ouAeUepUy2nCWb+2Y1Ym/Wwq2XO9g9/4FSZQ5Z/GskIlWK/nKqag5VlocjmLb2cFBEo9iGRrtPkgZ2XPW948j4H1bgSArzLP123vEeTN5ohc0sSALXpfnEMmyGni8QJfDaHk6YeJQ3XbPn0zCbX6V7SPponliMQhp1yVq7UIIAWcoSp4ZySSmh/COvk1ifjdGBGFi5GQRam23G+CGnk40YLbfouqMUF4/Q1nEC6Tu6Mk41WiC7CFEDHo8LvI99tr95qzgxbSP1k4zkU2NIfEsS26RdNSJPHNHgFB2Yfcxn+e2iCiHRiy3trrrbkFFjDSb27EdmdIMizVGzAqNXvRKk0u58SwBJTNXBfUNelZxoDADUSksDvmRD+S+ZIq6g4OWnNldH0mBaNF+CdZtqXmhC0k9ibYUC2kLtB3rR7ibqmmfE8jpKoJGah5sNRWU4Y+YJoCdIbx16b7wsa25gu6A4MhDch7TM2iL/X514Y0uE+Nn4ToA7TtiK4r2godWPsujHRxNV36UyY6TEtEx8fvbM8BGjdWc2WjvIsJUKPVOo+2PWANJME6lweUiy/R/cA85UwUNwnzDLLa3iwBWYbUZYoOeq9ZI5RudLZEiHeH5+tz+h5EpZF+u8LRYnrK/52uU2IBw0fC9qUGrpwZPmO+mQKHpDbcvpGTbCdzJVvzmD8JM9pNlaV0riMcoxBh4kjobkHi8s3g8WenIC9eC0ECx2v3OHuRkTX6aSUToibeEUAk0iV+tlp6XzL7pnHqH4oghv30Rq6snUu9j7o3TCQS22bcYKT/MOGYZH6f3kMj1SWvpb51AfcIRRvahIrJHaGeOkJgZxsb/QS+fXilgAAboG8ne9SCD9VnHDymqnjrl1GWiUtnG0rHbYXxCQP4NZYa1+5K7sU5S8mWXzuYyL8qY0ZUcLJhBC0+uCWz6neG0vqEfTe4ZlBPYCpqTKh39lgoLDZdwg7SxeHXE6QnAQKE3oCmMNEVgp3O/LVcmDLLQ7Sm9/nfrqL6gE8ysdL7SuS9kx1UqINNJ3CRd7ZY70aCVAhOi+0JMO3KIhBJawr9DV0MlCSAucMonSbVVEonOhYemZluSge0mvvcjkI6+vaNOHSPpWc/NngFmQZJRRaMTan6JX4Hrt4e0+Xrzv1mQ1H7n59rb88VkbL7ZdWYlbzhDmd7lcgV0KQEa4IVmUmLCxir7MSL1uC8GNspVQK2553PfnoBEiG322QBo/yzf9eNp0uIA90LT1pQvS+/4MzFl9fuTKHHKapI9/h+1YTFlmmQi3n/q06l9sbtVOsoTiy1j6eqBYpzxCxLfn1FHUOvPyzBfk9prBeaehuK2DK937dRf8kRBOct93ll6NLOKaWAFHasw/mQdZpFXSiP5o3m/b25TAuVgZUmSowtucmhvmQdLRmhcn1eO1GSKUestrFXAdPK2imMnI7daf5d8k8Cj0xdyXMTsQEpBsYTFa0Kmh3tMZ1a7mg90mYHiowmP4gBG/Bxozqn3Jdv/nNm7hcUuhg5ZDmZdHDzyE/+2ltw+OKPCaLSrkUzXZMlzz+WK4AHnxetfUtODkuP7ci8+uOb8vIJjAOVwuMUN4BQQWWK+PX6cw6py+LqIpn79/AtYXCyZWocLspmp0yBdYd9tjHjAyCtiaHYS3W5FswYydpc6PBKLeThOd74rdqll30JhksjQUgCUUjVdRM+zcT7RLlz0DIbnvlH42sy87TA6ioDEWU76I5vLZn/NJS1cf2D0lr3AJUgvSpXCW8w1+Z9mqfof9yQ/RRe5z9GcNoesgJ+gGBrZgmb7N/0muFJc1jSHbv/Qe/coz6B3PJL06bc7qiaObOhHc4RQuOg2ADZsV66v8g4kYi3HJYs+ubxkhJmU/DDfW0+OOtMkuYxQFLIiQNN2k6GZH0ThtcIBKTaD8nRetr7JCwojBEUklVEtWESzY0iWKYcm0PZ8hFLYwL7+pMpV/BMDcqYQzz6DDcxe4367gwDAEnMRlKPbuAlVfhSDlIvYkhWE+AIKaTzu2qiraqpbCFONd+ND8d/BjyHkjJvnbAKbpJOifb4ayBnq9ids66KDYTdyrBPB/sp1imHvmAil6PXeXyGyEcipJeY2BXFvvHmVEPRL+rqJc6V2YWLiZXhO64pCcLQNKLJoPUoqn8U5qrjO1FftHu3eA7ZQYK/Y8i/I3QSKJxoB7CT2D2dWnBaxa1yAalost7z2ZI1XiSOGWISyESmmHZnC8gyvPzdgdHjhWa1xEjQa6AE2K9rF59eI186x8N1bbE8Fvho+FxQl0Sf74tdwFiT7jlRqBwjxwOp7HqBzEU11DoIfwn8FGy2g7VwxO5ATVeuq6Qfba07ppUZuHGwgmtqymVkDTeiV2Q3E1e1VsTCNpfU3a8bM67oAZbIWHTEsGlY1DfwSeLF6Ok+xCNuXDSK2te7OnJEgXY4BnqWjec0PRE7xnAqxRcaTBQWvT1Dj4opWfHcgyc6zy6ZP45eF3eFWRAFOvMN2dlBspC4Kzl0z4/HTJwaQko2UiNw9nUuSde9tt/I+mYL1tZsb0MSBfWRT4ptTFn6NhBaqvTWNZLeANrCDw1p3B+Qv62O6FAu3NLjAst5UNN/2qKuju/Vu31sIkf/hWC8qfmXnG3OhKjWVC0fdNv288eGCt+KkxDNLzOfAt4suJH5Eo5X0IqPVDqTSWeIe8UokvZcKZV9UgULdmtvQv9aHdGJYR+BzaKBMUnEZeF9GxG85zUsG4kXsjiW+jniZ/v8tvbIHqhkSCjArBVohoNSkwMzfrkrOM8nc1nwzOdB9d72h//3qJuWQj4NWJJzhQm6iqcwdup2rqYm3wVzVqknYSCJ4CDrJmhZNhpDOCCCm4iWmOcbwXYvnNSiknQ0OKIoh5afXXrL++n1mt1UQdR+6yVPkV6fDzbhCexicQf41bDFn/UssvxEW6zB2cQYzdwssgRxVQkItFRNY49zB94qhqHZwuroKTQM4/iYqJSScv6LZyd+iXdP5tdxmYRx1MnK6e3dn3zY5+HeocC5+AdNe10IMy6j+dGey92qVjkpubsGRAU0YvcsR2salEYBfgE3MFypU9+SoDkm1BeUGYzk+yGNh5j8yQ1WKchx2ifwq2MuabqkvOClkDLrG9DVY0e+OcYeXC8wlLHmHc5Co9Oo/LnLou4M4o3YzO1IAd+3rAACgJAS1oyez4Bdfv88QRUI+O/04xJCZwgkwpZWEwHf8OlprI24I3/EowKCsy5HNI5rXzt10bt3UbY50BGmzl3PrEXrthIUqOdf2tGLWOUZycDTXMEMh0/6AyntMWRVCcn7cmicrL7wDdwmC0vY1RFhpHkRI9qbTpfaHszdL018rwUndkJ+AwAc9mhxkU7QKrUZnLN44yvN81mqLID0K5hZDwv15kRyYhmA864KkKNpGL6JhGIaTxKWaB882Q8I9LFv1y9cVXNUXCD+5w4Om4zarWODBIXTSHSZkUWcPyoAwUkgmX8TnuCkklYE5t6S+yhEsgi2NC+VOUW47rg7nj5D2giWw1lRa0JdxWpmgUO29Rl/loIIwGxFPhxRK2sMuVSBWS0QymV6vj8LUab0iLUx0IIoOf2ZJjPIj5kfKUk8dMr6MJECjEj9wLWc6C1YrVg2Yn7tSpL1K5YPg4wdMEZcNG6qIFuNHbtKNzTKCO7WvFnnJU36xoOoLbna2H9VR90Jn1+DA099QM7Q0zrcKlAibcFj+ZTPbvNI0jdQIY+tz6/ma36GsCdeL5hQXpn9YKk0eZ7+8ENBcrY8diUjaepxR+spmgVdqvpx7/8LkToiulwkOfyVVdhFFzNAP02/ccc5yJvNdE9zl/9XyLuv9lS4EPOmq1YeMm/ALgyt0dyZRQ0U6HJ8vSDSCBOnJJZQLQknb9nRUquBrsRK5X+gZOY3uJf+/2zfEwBbFIRQt4wPfkpBQzx+TiocsDVs1OKI+kJhmSC+auE6edTujnzl8hpdBHyj+l3r2rsA8QfnKVbqdYm/ikTTUgSBnlcJqCVRDpjZqGb/J3x7dwB4hpCHNSt00tlO+p1wmcRgI0akbLxxraf6ZqadL3N0bqQ1DmsmgSMbNPEUU4hQFg37ZDvdPoF2OPV59VFtdR1MJ2tAV3ZUdn44G3FjWeJFETkurXocDyN6qecsP+9jv6nNdEiNiFaI4k/EJHR47SWqgHvb2XfvWxmKb3EyNu+bpqqrbttatY3PTcAgfxXd8A7+hcJwDPxrNYrXadg7KVEDQYkzeW60pS6ibDPNf/OIHPHPRrGVPPfAyXaa76nH+Cj920FppKK2Tx2Q8jor1iJYVqYiUN1Zc8AW+ONeHHCF2ktSGDURiaON2crUlLt+ArWA6kSldWDbR/1CtEtNlTnCHUzSCYFfBPPEOGb3pz+966Yc8hB9Rzy0jHVYSP7jgY8ynjuHaWTdr7rtr9IEUUcrKqM1OAbun9pZWlUY+kSkbTcG82ec1Ai3FLSjCBeq1k9KeyESFHQlQAmTwTlDVGi82cDiU1ns2tVCLoPbPyiP0Wrt0SSRi3wosacon5QVxoQW7BIxtgdHX8027fsfnUOEcx46QY6AjThUQXBhx0i5TzT/1VQtGEVvLJdBgy9fdCVIBIWBpb5v5Zzkxk3jbcCf0mjSMiKVSbMA2l9oShLPsyaNUZHVAPFB4DStl6TzYAUa6yh79eQT+Jdqu7ihGeP/qDpKb7iR7qZmQuPA46tXQtbqXxMyXIb1t6/ohmIfFG/ivI/Sd52leg/9kU2nnamqoVVMVqmK1DuuiocXLXkEh7hdybDaz8pRbv6hu96sWRx/MMLQZpOyk9gQbxtiOyy2soEyG2PisDS/jTdy6Z1GnVFsqRxnsZrecTOuQ7mwGE6lgQUZSIKJau27QdGrp5setzqblndleX97GalZRGlXnblS1aKsbW31+9UWj+dajFUF/IJsxTFBo8wArermW1OtzidQ85x4VydYH7M3uD6KWfkJ5NvhJq8R6KHHFWlF9EiIaF4ZDzG6RCIQOwilXIdbvu4YAKEEeVyKS8YOJYx4zuKZCIP5RXAk7MWK6jxp0cEmX+Ownnnxx9t9+xQx4iGKk7RZCJTR4WVYbAZ+ng2p724VjtpmQRTvn+MGZwaC2HOIo+CocMCIjMPUffb6fVqafBct3OaNcAIy+QqYAEMsYDxNicrMQNhO/uiG7+DpOUdQr0EymAGULYACYIjYAANA1LhNAmNeRDoy7cryAwpdoWdDM0H5/hiu7XUqkPbGtUMluj8cBRosF6f1b/+rfIRzMiN3Soz6Ch4yjWtf3L9DU50nZC9qZ+lonriywstDqmzD36iqACZuJidsUHT0s6W2qzGmBn4uXm9/8Lides+qnauXcx4rZvxAFh+4YiHZw4IkPIwMwz5XIkQAKAkbIzYQBAWNb+8NslH0rnHgMZ5PNYAtSDFMU2hP0+bNJir/ecVXX8EKJ2lmA7Z+t/I5py5gbW/gu10Dp76V+mXOC9+oWcnXb5pntQ83Kk6n3Qvge26cPYA8/7rTy8HMOiUYk1SfQPv4aAAKihicO7j0silfFx9fotPf19BJlqo0l9YQQDfganZg+IWhmBb7F7SO+yq7lc9im4DS0A0eTos12+pkJ5G3PxwlSesA7w7HffVm0HF+of3n69W7o7M669BacTCUJTLejwkzj1qoAKeqZGR10arE1lDTYV+pzlwxg/vWL5jY7ceTWpuVb0j04vEIcrbK2+GiDdnwikk3XHB13rnhokGZfGm7ft2tUnTLbWidjfnthlky/9GU5p/MdlHJc+LKGqhb4KS5p2R/ovk1jB/JcCEpKHE+5g8OVCw7ohLa/LsB8ANdXwwG0oWoYsg4hVvNTbjDcnQNUAgrGgLsDRRhyC8rzXCyHv10A8VCf3SEyK/Is2MlYvSo0rghreqrkyOv77fDyTVZyyOMMqjP+o9qcembdqw7OoWBpsxltYxHHml3epbF2uA9dLNjD2PsVDA3hJT4c90/qfVPk6we65r74SviZbkdD6wGkrFugW32p0vV4OL+nXO3eKVmidhLIndc0aS0A0+oSStv0NPerSUC+9D0VTVYWSFM7NP2itkpSAStOnvo7NG/pheLjIvq6Eyoa8K6J+aIdxx5CT6SXdhqzLj0seEGeqyuW4POrEUokz691XmlnEgcwLSTQ9cQMIvC7qi8AhKkA/QjEWIKptx1YjuiQqRByNpvNasLnXrEKUbwy2COxs6wCtCm0Os+1UmAhlWzxovcDkM/Nbh4beavHbb+QF7ZWUq6ycbnNaN7brMzRW/FI4o5lIPQjory73TxXG3SyWTKGwoA+wDDrpRYLTFWOIlx2j02IXch+7AE+/eLQD+CvPKGWcG3yAodm/KQ+FVE7CsvCLAaej2quGflpD2GZnlNHvCKndGJ1xPSKyVgv2CHNpr8UlXLX5OECuD7F3XsdL8mLUYEW/k1lzIdftiIVmZBBI2IEQqb1b6LtjmxgJUyLAy4vLE+c+DPGmLk2pQmQ4Pxcz9KvJBeg2K55LMzLzqiJLdvRpaY3E49UcG/PWb5VPz0dDC5gAQQtO9yvz47+EMlUQc/soY30LxUsfYbfsm+urygBRbAf5iIBzXp1rE/xB3HalZ7AAU9w2JDW1rgctJpOOyRcbihulupOWloYDeklXhxulB+mkyzNq9FCLwvoPNEdyEUS/g3K+F/m4TsSIkSlhPpb5aiNJ0V+bmVVfEBxYm/T13Skhc5Ucz/UWanNMf/KKKToA9fCxpgfQAEubRBsvcSWcm6je/wooUtxurXPn+xVo6SCTbLfhr67CKDA1+i4xGSwIEIMWZIKOK2EgfdKG88qg4UMzP3pyhq//SdhJIzcNYhxbPTKbNeDIoJ+TVKqvwN19w5iJZErxt7X82OjT9Mp3ejfq3bR6qb2hvgy8B7yeFiqeV/RaqCm6/1rnBH1gaGUwnG4dfOs52yg2no5x721WFKb7IGKZP+7ZIm+bO2+54TyUqlnQSMGKZ+O0fVaM0J1dTQR1Ut0lEuwAlGT+Beu5/tgZJiBi2CYJZFP24kzycxSyMwkRx2v/P15xYkyNLpMr+cbMPB0FMmcNGxWJ0da5/nHPZ2G35Rl9IdTKx5n5LgFdjt9Cn6TuXcATXRZrmX40xEZrzxzzzcjBfCZFvcx6D+XJkJWVIsV89xgYtWOH7S5jPZAaQCR0ouTjjFb709ZpJ587m/rXXHCh2v7iBuISgJ86Hg7Snf1NtG4qSkPjA2uHyUrNnGkZMo7Mh8tXh7OscIx9HXNABYriWHL/HReHLRcm9raW94fmVnDE9VVyeY7/WexAwaL6Ob1saxVaxKVWp0TrRlgAXZYeuDEh37eui/htNsTNoQ85fplm2L3V1Qt3j0+yLeJ+GffepBxLtQuYDbvWgGei9O4d+SYhjtE6hU/E+hIN3V+hL9XeuN67ZxQGmGw23Qb7U2pLpZCe48izfwmMbMi4BNCFYWLQMpWPVeUJY92f9Jn3GlGtbmUgpB1KVaDs+pw8RMseXMr3CumcEcVhhNFtgUH2QJvVtWUQwnB5uW5Tnfc9RTqGcgqIvzQNcxe1eO3TcTxSh5Z8NqWQLADyex7Lr501lwkvvSEkG5hzO/tcUTCy3sF3X+SeSHZJox0+JZwt4xcE5Vg+Q9z+ngC7WvVd63xfdw2gHu7oJgR+4NA+78sJhU2qjnsLfmPUf5HGZJVQxhm2UXs3N6a6SVIY1S1k3uKf+vPR6a2z1qpaXL03+n4OWgjyVYEYbwEntUPuYCEw5JUSvQU/EvbXOr7WUIaDBcxg2evIOv5zVpZ+ychEdLx9Q/AayqJU5jJu06O8TJ8kFo1+vjYd1EjSwjluMecMq2tYA08REiYncjeRx+0qJoQiNDa/85ZOb9+C6h7RfYZ5s7BPgowx5hcL+t9sOjeDWMEbhoClglTqb3Dly++Hr9GBS+Z8VLvAiE+dIWyhQkjzTJrtgViAMbvUV2mqg9mX+YaFe57PYNXE3LdUZopF422t4QYcyoxy5ZTE/J08qviKCwuWt26EC+VS+OZcrQAABonISInd9Z8j0rc1833J41VG3jlvZecE4wO5JIqLlrWUry8NUSELcvbMLOWldZfUvDg6xkM8d+AEglCZZEydTV6IU+4ipegAvczF1DEUm6Ory4pkmNt5GlMd4/Xy5uSrL0MvmrLJC27JWYzZGMtgxtf7RyNsuQoETfiwF0H2li0icm/u0B9U02+k+hc9i51SU6NPxqwn2WG/bQZiyesgODVU0v9t/1tGMSLtE/Fxf/suPGKf3Rpm4RccaTu91q48khQqZkAZOtIlq7HoBZWX3CVvCNwOghmfT+agTgs5zqykUluhDF7dSR5XJhkLlRCrzUWtoJShtk6+E5/3UO52qysubYEG0eHDlRSIIJDFz/slGZ5tyv/uYuQCgF4c2u9Up1xfQ+kIVXI6w97NaXI2JaVf3Lkl4KRkwuBjuL3DXow4s7K6PjfzopnzQGls1s0+Y/7E9cM98c6+ZUhAR7+l7sErZFO1JyFGECWynWXt7YkAHhIjKNmQqQwXeH3iG2vgXS8JQaYxFrcgx6b9MEgdfIkPuGW038bb0u0YeJMcTLXMBJu+B9oBPoXCo4nZEcvFwrqikOYA4/tZzs/P+9bbZBQjFQVVFgAd4HsA5u4G4PK0D6LTKqWw0+nLmLBumF8nnW2MEg4MD5dzi98o/xnMDCWkAsYRDEbrem4bZ7MzojCcJiR1PNUehVsByg6oIp1ay5hNYVrcSgz9942O0hi+3XeneRfPIeklcdwG9gPrh/HVwc3OxBrfJ3FjZGUkltAL6Fg24r/34GJl6VcZw/bnKUQfn2Hq3roIrXgOQTJ2ZL07XgMaQKagnZ0wCQAAG+s4R1McxHNAU2wi+6dfsY6lDR8TZCuhnR9kCvLekeeytxp78OMS23YTIvftMFeHc43TnKSj+eQ/nuxd60qUzO7NfGy/oXX/ebozEPQEE7zyuX6fFF0N68aPH2Uy2U+z/nVLdH6yYP889hcTfsXIuXrjA4JvbRpkXb9d1RkbVCVrwwL5nAnBtB0D6Ex0oOm107MVPYR+SxKgYNttJsqhV7s8xJPSGwQQYznUiSd8Lp9ckPYrX20aQJNXtTU61Nf1XhFjuwq+9CmFzQ7sxUCYlRTKXb66Nfjad8CR2xRXK0Vd7+JFtC/ad6Qlnw/ZQjZw+NNc58FPx6AVww0n6AJGdgizvvAehuQG0rgXXtKHP9W6fLIK0xOkr5juBdYf1RWFUNoKICncDSyKasejc1+W6X/QFCS+f/nsQTWEvzN7mWVTI8055BNY8ydXYsokExwTIc00doi4/PjPHqNIRTjngyoKQORf8wZW+R4gQF8lcs+1yzh8AZavrdzgOV2Qc4alAoCjM3wSuZCkvw4rN9zv/Ffl7X+V1ueVyiqLAc97wx8e7HpLRoB1fF2o7DkWvGJ+5NRLraNg2zeR7xAu6Y4nHutPUB/yZvjmM0SZSS28Rzlhvokh25oJwc15HfrQBmNHg/os4DhwT+F5eWx4vZUOX3l5EqQ2t/+zC8rPP2nKZBHi17rxwspGOITrjQOh/15pWfS8FIrr2f0zA4ZJ7L9mlT24syIZIdiIxX+QD8Asx6c36tgiEgSoZEoj5SBH1Dnl4P3GUlj14LV4YjHuM1l7DzmOnppooskr2hS+6Xuvrgfb1qJNquEsfKJXVcqEfWBu/CavHKeCl+eDAFhuLIwt3op1iWj5eY3LqcqEZfz4W9b81o983dEZgsQMLtBcswjAAAzrpdApTuDgG1Vt3JW01J7wVBDPdxiB/rul2Nw57G+I2lFWXm1/Ox508AtcnFQyvvm+ktQ0PQ10/h727tMtAM36I8IbF4WQJhfpLML34S9JkE2PKNjbxVETadHSC+f8cn+4xbXxxLPpCt4arTm/9JM190DHpE3n1QxpPw6V2ZNlOgzyD0U0A7ZPthITrgPOnDrbQgyDcC3MOw8lplIcNbV6f0f1hMfQ07sSbGIsYrXFnmMQYkrwt9GoujvxmI2oX7ASy1GhJt+Fy9yDeUVNQciTw2Ssto6u0teUEzkrZg6wDj1yNgI/jseBL2RHOboP/nnLTna0lEnMn9ACeDcTlB1aWiJ8FJy4Lq72cv6zHsXAwcdNkrEfxHmepTPgOsa9Mb/gTgUyqV/0iCmzoq6XV0PVoqeZ6tUh/8YiagLGraKjsA/wVYAcm0FPIXf1Od7mLr89FFHTXZv+f2gmhQuSf0txJrjnLfbb/SMB+eGsDK8qtn30LjrNYqV2Yg8pm8dwDhi1yj5kwpCwKUfmNvqVAfcIN/Xr0Auymp5D7r89FFHLPfepOd8XcCuefnlJhd+lFCmUm2LH4zHyDXwI7lr+MWDNjqnfAsI5y6DsIb+TlHRHkf8qoI0aguUiTxaLCipzYntZCTwmtFI89LQgdvmEHb+mLr0N9ySh3ep8EcSCA/+elhBDwqaZFjrrR361z/XqcNp02NEDtUkfVwBwQg5eXd12tJ+FXS5g/ft0sM9TMNUTt3xBwfo8k0xqHmDYXVP5ise1UNuxv5b14zigYrKhqL0EqKREdVizzvi0yTvDo/Pr1QL2FYBnT5fEpTSbCKnwIlTHkqhkY4u67Z78jSz+PHqPuwavL4CW/NhSs4ieYXCEpzAfsqp/nWAhn60e3RDWb8KxPxnXJrTKDN7Jb/U4dTWZvJVBaAAABcCHfv5BzgPn3jn8cvww2VtlzkyJpepxtEFvK/h8eRFK+O1e/Xi9pm3sjRbi0rtqGJgLv+JKMNbvQJtvgTNd6v715PXYCd35SO/BquNYeqq3L+/z0axqJtTMZfVP7AhT89cHH0B/7ll8Z3GgbrYXZXlk+fgWyk3+IkGIDHj6voDSxzsymbr6aQ78AEUwI9jzEq+81p2qS7rfLISkffrfGBov7v19ZfA6Kx+gklQSTL4EXay4P7foBGS4S+RTv3wsneA1rqjLsZa3u67Lng1piIN0MmFezqk6neElty+mz1BddR7eE/zijoO6fRLG1GK9UFRCgE+bAb0k0c0/DE1l/sYP+Y3KFIt7vFfjZ7D2q3chqMXU0e66Z4qPm+CQJSirE7MH+hPNymPX1EaxJKI5XEFq7+Qd0lWUkP23oMXkLwMb51G6RVOz7syrVyGkCCiQiZ0H+hsFK/8ahqXDTj72ApJYljkxAl9KMPAd1+ktDJeXl2mR6t6SgliQxzhFIzTPqCIEbOVTRYuMbTL2VabjHPDiam9fDYWPMtj0+O1BhbXyHsLdXTDvJ4cev1f5OhXF8HcUAXbbryE6QJcAAAA4Gs/rxHBkSCC4ag1IM0kYa0oEkw+ZWEdz4XXA9+v/glkxEc2vu/tiGlf5E7n+V5wKI7shG+5HdDhzA71bAyi5BEWCkfaAK/yJ0LfZizU5TmRuChgChFVskz3BM0KVAogDrsgucSIBrRefXWyD1NKMbc2dmVEXolZ02vLJZUJOReLbO32OYma0E979VIZJAp59tRBwLhTYbP29TvTub+u1amcXHDLg/ZoODy9bFTMqAHOZiv9IPf3/E00Bb3f4WGUp0+fb1GG4yhkYA+Lx4ivo0FIffr9MvO2NWIMpGBMbbBdfU8joTpf74XyrcSQX19LYY6frGnIXou4MbdD5j2AcKSYnAszTjBgRp745ceWUulBxp/XxlmAkWccJvXJapQAAAAAaF1bP5R7ftJxrZRHWH5caAqjmGQgopQqoTVOTib6wu/1duZ7LfQzezaUZQ1tkeIWwhmsidiT86Jgaolfuj/W018/croZP3rz0MPCmrSLNr42Mm3CCK7jqV/aDzBsjJRSF/Woh0LUAAAA9VpSvzCQMxAAAAAA" x="39.0" y="18" width="322.0" height="424" preserveAspectRatio="xMidYMid meet"/>
              <!-- Soft glow over the torch flame; pulses while the user types -->
              <circle id="flameGlowCircle" cx="199" cy="130" r="40" fill="url(#flameAuraGrad)"/>
              <g id="torchFlameGroup"></g>
            </g>
            <!-- Red Lock Overlay shown only on invalid email/password -->
            <g id="errorRedLockOverlay" aria-hidden="true">
              <circle cx="200" cy="230" r="72" fill="rgba(15, 23, 42, 0.78)" stroke="#ef4444" stroke-width="3.5"/>
              <circle cx="200" cy="230" r="64" fill="rgba(230, 0, 0, 0.18)"/>
              <path d="M180 220 V203 A20 20 0 0 1 220 203 V220" fill="none" stroke="#ff4d4d" stroke-width="7" stroke-linecap="round"/>
              <rect x="171" y="218" width="58" height="46" rx="10" fill="#e60000" stroke="#fecaca" stroke-width="2.5"/>
              <circle cx="200" cy="236" r="5.5" fill="#ffffff"/>
              <path d="M200 241 V252" stroke="#ffffff" stroke-width="4.5" stroke-linecap="round"/>
            </g>
          </svg>
        </div>
      </div>

      <!-- ================================================================== -->
      <!-- RIGHT PANEL: RECENTERED LOGIN FORM (NO TOP LOGO, NO CLUTTER)       -->
      <!-- ================================================================== -->
      

        <!-- Right Panel: Sign-In Box -->
        <div class="login-form-panel">
          <div class="login-form-inner">

<div class="portal-heading-box">
            <div class="fp-logo"><img src="data:image/webp;base64,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" alt="University of Jordan" width="44" height="58"></div>
            <span class="fp-pill">Field Training System</span>
            <h1 class="portal-main-title">Welcome back</h1>
            <p class="portal-sub-title">Sign in to the University Internship Management System.<br>King Abdullah II School of Information Technology (KASIT)</p>
          </div>

          <!-- Dynamic Alert Box (Shown only on form submit) -->
          <div class="official-alert" id="officialAlertBox" role="alert">
            <span id="officialAlertText"></span>
          </div>

          <!-- Recentered Email & Password Form -->
          

            <!-- Dynamic Client Alert Box -->
            <div class="official-alert alert-error" id="officialAlertBox" role="alert" style="display:none;">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex:none;margin-top:1px;"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              <span id="officialAlertText"></span>
            </div>

            <!-- Server Error Alert Box -->
            <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="official-alert alert-error">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex:none;margin-top:1px;"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              <span><asp:Literal ID="litErrorMsg" runat="server" /></span>
            </asp:Panel>

            <!-- Server Success Alert Box -->
            <asp:Panel ID="pnlSuccess" runat="server" Visible="false" CssClass="official-alert alert-success">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex:none;margin-top:1px;"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
              <span><asp:Literal ID="litSuccessMsg" runat="server" /></span>
            </asp:Panel>

            <!-- Email Address Field -->
            <div class="mb-3">
                <label class="form-label" for="txtEmail">Email address</label>
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-envelope"></i></span>
                    <asp:TextBox ID="txtEmail" runat="server" TextMode="Email" CssClass="form-control" placeholder="name@ju.edu.jo" required="required" ClientIDMode="Static" />
                </div>
                <asp:TextBox ID="txtEmail" runat="server" TextMode="Email" CssClass="uims-input" placeholder="name@example.com" autocomplete="username" autocapitalize="none" spellcheck="false" inputmode="email" aria-describedby="officialAlertBox" ClientIDMode="Static" required="required" />
              </div>
            </div>

            <div class="form-group">
              <div class="form-label-row">
                <label for="txtPassword" class="form-label">Password</label>
                <button type="button" class="forgot-link" id="forgotPasswordBtn">Forgot password?</button>
              </div>
              <div class="uims-input-group" id="passwordGroup">
                <div class="uims-input-addon">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                </div>
                <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" CssClass="uims-input" placeholder="Enter your password" autocomplete="current-password" aria-describedby="officialAlertBox" ClientIDMode="Static" required="required" />
                <button type="button" class="uims-eye-btn" id="togglePasswordBtn" title="Show / Hide Password" aria-label="Show password" aria-pressed="false">
                  <svg id="eyeIconOpen" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" style="display:none;"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  <svg id="eyeIconClosed" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                </button>
              </div>
            </div>

            <asp:Button ID="btnLogin" runat="server" Text="Sign In" OnClick="btnLogin_Click" CssClass="sign-in-btn" ClientIDMode="Static" />

<div class="fp-secure">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 3 5 6v6c0 4.5 3 7.5 7 9 4-1.5 7-4.5 7-9V6z"/><path d="m9 12 2 2 4-4"/></svg>
            <span>Secure sign-in with Firebase Authentication</span>
          </div>
          </div>
        </div>
      </div>
    </main>

    <!-- Full-Width Bottom Footer -->
<footer class="fp-footer">
    <span class="fp-footer-copy">© 2026 The University of Jordan · King Abdullah II School of Information Technology (KASIT)</span>
    <nav class="fp-footer-nav" aria-label="Footer">
      <button type="button" class="fp-footer-link" id="navHomeBtn">Home</button>
      <button type="button" class="fp-footer-link" id="navContactBtn">Contact Us</button>
    </nav>
  </footer>

  <!-- 5. OFFICIAL INFO MODAL -->
  

    <!-- Official Info Modal -->
<div class="modal-overlay" id="infoModal" role="dialog" aria-modal="true" aria-labelledby="modalTitle">
    <div class="modal-card">
      <div class="modal-head">
        <span id="modalTitle" class="font-arabic">نظام التدريب الميداني (UIMS)</span>
        <button type="button" id="closeModalBtn" aria-label="Close" style="background:none;border:none;color:#fff;font-size:20px;cursor:pointer;">&times;</button>
      </div>
      <div class="modal-body font-arabic" dir="rtl" lang="ar" id="modalBody"></div>
      <div class="modal-foot">
        <button type="button" id="closeModalFootBtn" class="nav-portal-btn font-arabic">إغلاق</button>
      </div>
    </div>
  </div>

    <!-- Forgot Password Modal -->
    <div class="modal-overlay" id="forgotModal" role="dialog" aria-modal="true" aria-labelledby="forgotTitle">
      <div class="modal-card">
        <div class="modal-head">
          <span id="forgotTitle" class="font-arabic">Ø§Ø³ØªØ¹Ø§Ø¯Ø© ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±</span>
          <button type="button" id="closeForgotModalBtn" aria-label="Close" style="background:none;border:none;color:#fff;font-size:20px;cursor:pointer;">&times;</button>
        </div>
        <div class="modal-body font-arabic" dir="rtl" lang="ar">
          <p style="margin-bottom:12px;font-size:14px;color:#334155;line-height:1.6;">
            Ø£Ø¯Ø®Ù„ Ø¨Ø±ÙŠØ¯Ùƒ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ Ø§Ù„Ù…Ø³Ø¬Ù„ ÙÙŠ Ø§Ù„Ù†Ø¸Ø§Ù… Ù„ÙŠØªÙ… Ø¥Ø±Ø³Ø§Ù„ Ø±Ø§Ø¨Ø· Ø§Ø³ØªØ¹Ø§Ø¯Ø© ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±.
          </p>
          <asp:Panel ID="pnlRecoveryResult" runat="server" Visible="false">
            <asp:Literal ID="litRecoveryMsg" runat="server" />
          </asp:Panel>
          <div class="form-group" style="margin-top:14px;">
            <label class="form-label" for="txtRecoveryEmail" style="display:block;margin-bottom:6px;font-size:13px;font-weight:700;color:#183B31;">Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ:</label>
            <asp:TextBox ID="txtRecoveryEmail" runat="server" TextMode="Email" CssClass="uims-input" placeholder="name@example.com" style="width:100%;height:44px;padding:0 12px;border:1px solid #cbd5e1;border-radius:10px;font-size:14px;background:#fff;" ClientIDMode="Static" />
          </div>
        </div>
        <div class="modal-foot" style="display:flex;justify-content:space-between;gap:10px;">
          <button type="button" id="cancelForgotBtn" class="nav-link-btn font-arabic" style="background:#f1f5f9;color:#475569;padding:6px 16px;border-radius:8px;border:none;cursor:pointer;">Ø¥Ù„ØºØ§Ø¡</button>
          <asp:Button ID="btnSendRecovery" runat="server" Text="Ø¥Ø±Ø³Ø§Ù„ Ø±Ø§Ø¨Ø· Ø§Ù„Ø§Ø³ØªØ¹Ø§Ø¯Ø©" OnClick="btnSendRecovery_Click" CssClass="nav-portal-btn font-arabic" style="background-color:#0b5c2c;color:#fff;padding:6px 18px;border-radius:8px;border:none;cursor:pointer;" ClientIDMode="Static" />
        </div>
      </div>
    </div>
  </form>

  <script>
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
  </script>
</body>
</html>