<%@ Page Title="University Internship Management System" Language="C#" MasterPageFile="~/Shared/Public.Master" AutoEventWireup="true" Async="true" CodeBehind="index.aspx.cs" Inherits="UniversityInternshipManagmentSystem.PublicHome" %>
<asp:Content ID="HomeHead" ContentPlaceHolderID="HeadContent" runat="server"><link href="<%= ResolveUrl("~/Content/uims.css") %>" rel="stylesheet" /></asp:Content>
<asp:Content ID="HomeBody" ContentPlaceHolderID="MainContent" runat="server">
<!-- Top Scroll Progress Bar -->
    <div class="uims-scroll-progress" id="scrollProgress" aria-hidden="true"></div>

    <!-- 1. Sticky Navigation Bar -->
    <header class="uims-navbar-wrapper" id="uimsNavbar">
        <div class="uims-container uims-nav-container">
            <a href="#home" class="uims-brand" aria-label="The University of Jordan - UIMS Home">
                <img src="Assets/PublicHome/university-logo.png" alt="The University of Jordan Logo" class="uims-brand-logo" />
                <div class="uims-brand-text">
                    <span class="uims-brand-title">The University of Jordan</span>
                    <span class="uims-brand-subtitle">Internship Management System</span>
                </div>
            </a>

            <nav aria-label="Main Navigation">
                <ul class="uims-nav-menu" id="uimsNavMenu">
                    <li><a href="#home" class="uims-nav-link active">Home</a></li>
                    <li><a href="#about" class="uims-nav-link">About</a></li>
                    <li><a href="#how-it-works" class="uims-nav-link">How It Works</a></li>
                    <li><a href="#roles" class="uims-nav-link">Portals</a></li>
                    <li><a href="#opportunities" class="uims-nav-link">Internships</a></li>
                    <li><a href="#faq" class="uims-nav-link">FAQ</a></li>
                    <li><a href="#contact" class="uims-nav-link">Contact</a></li>
                </ul>
            </nav>

            <div class="uims-nav-actions"><% if (IsSignedIn) { %><a href="<%= ResolveUrl("~/login/Logout.aspx") %>" class="uims-nav-signout">Sign Out</a><% } %>
                
                <a class="uims-btn uims-btn--outline-white" href="<%: DashboardHref %>">
                    <span><%: IsSignedIn ? "My Dashboard" : "Log In" %></span>
                    <i class="bi bi-arrow-up-right"></i>
                </a>
                <button type="button" class="uims-nav-toggle" id="uimsNavToggle" aria-label="Toggle navigation menu" aria-expanded="false">
                    <i class="bi bi-list"></i>
                </button>
            </div>
        </div>
    </header>

    <!-- 2. Hero Section with Illustrated University of Jordan Clock Tower -->
    <section class="uims-hero" id="home" data-weather="clear">
        <div class="uims-hero-bg" aria-hidden="true"></div>
        <div class="uims-hero-overlay" aria-hidden="true"></div>

        <!-- Faint UJ Monogram Watermark -->
        <div class="uims-hero-watermark" aria-hidden="true">UJ 1962</div>
<div class="uims-photo-clock-frame"><svg class="uims-photo-clock" tabindex="0" aria-describedby="clockTooltip" viewBox="169 104 62 62" role="img" aria-label="Live Amman clock on the university tower"><g id="clock-face" class="uims-scene__clock-face"><defs><pattern id="clock-stone-texture" x="169" y="104" width="4" height="62" patternUnits="userSpaceOnUse" viewBox="716 230 18 280" preserveAspectRatio="none"><image href="Assets/PublicHome/clock-tower-photo.jpg" x="0" y="0" width="1288" height="1936" /></pattern></defs>
<rect x="169" y="104" width="62" height="62" fill="url(#clock-stone-texture)" />
                                <!-- White Dial Disk -->
                                
                                <!-- Brand Outer Dial Ring in #178568 with Breathing Animation -->
                                

                                <!-- Hourly Chime Expanding Ripple Wave -->
                                

                                <!-- Hour Tick Marks (#183B31) -->
                                <!-- 12, 3, 6, 9 Cardinal Bold Ticks -->
                                <line x1="200" y1="109" x2="200" y2="115" stroke="#252823" stroke-width="3" stroke-linecap="butt" />
                                <line x1="226" y1="135" x2="220" y2="135" stroke="#252823" stroke-width="3" stroke-linecap="butt" />
                                <line x1="200" y1="161" x2="200" y2="155" stroke="#252823" stroke-width="3" stroke-linecap="butt" />
                                <line x1="174" y1="135" x2="180" y2="135" stroke="#252823" stroke-width="3" stroke-linecap="butt" />

                                <!-- Minor Intermediate Hour Ticks -->
                                <line x1="213" y1="112.5" x2="210" y2="117.7" stroke="#252823" stroke-width="2.6" stroke-linecap="butt" /> <!-- 1 -->
                                <line x1="222.5" y1="122" x2="217.3" y2="125" stroke="#252823" stroke-width="2.6" stroke-linecap="butt" /> <!-- 2 -->
                                <line x1="222.5" y1="148" x2="217.3" y2="145" stroke="#252823" stroke-width="2.6" stroke-linecap="butt" /> <!-- 4 -->
                                <line x1="213" y1="157.5" x2="210" y2="152.3" stroke="#252823" stroke-width="2.6" stroke-linecap="butt" /> <!-- 5 -->
                                <line x1="187" y1="157.5" x2="190" y2="152.3" stroke="#252823" stroke-width="2.6" stroke-linecap="butt" /> <!-- 7 -->
                                <line x1="177.5" y1="148" x2="182.7" y2="145" stroke="#252823" stroke-width="2.6" stroke-linecap="butt" /> <!-- 8 -->
                                <line x1="177.5" y1="122" x2="182.7" y2="125" stroke="#252823" stroke-width="2.6" stroke-linecap="butt" /> <!-- 10 -->
                                <line x1="187" y1="112.5" x2="190" y2="117.7" stroke="#252823" stroke-width="2.6" stroke-linecap="butt" /> <!-- 11 -->

                                <!-- Real-Time Rotating Hands (Origin: 200px 135px) -->
                                <!-- Hour Hand (Short & Bold) -->
                                <line id="hand-hour" x1="200" y1="135" x2="200" y2="118" stroke="#252823" stroke-width="3" stroke-linecap="butt" />
                                <!-- Minute Hand (Long & Slim) -->
                                <line id="hand-minute" x1="200" y1="135" x2="200" y2="112" stroke="#252823" stroke-width="2" stroke-linecap="butt" />
                                <!-- Second Hand (Accent Green with Tail & Ticking Overshoot) -->
                                <line id="hand-second" x1="200" y1="142" x2="200" y2="109" stroke="#252823" stroke-width="2.6" stroke-linecap="butt" />

                                <!-- Center Brass/Dark Pivot Cap -->
                                <circle cx="200" cy="135" r="2.8" fill="#183B31" />
                                <circle cx="200" cy="135" r="1.2" fill="#252823" />
                            </g></svg></div>

        <div class="uims-container">
            <div class="uims-hero-grid">
                <!-- Left Column (55%): Hero Narrative & Actions -->
                <div class="uims-hero-text">
                    

                    <div class="uims-hero-badge reveal-up" data-delay="100">
                        <i class="bi bi-award-fill"></i>
                        <span>KASIT · Field Training System</span>
                    </div>

                    <h1 class="uims-hero-title reveal-up" data-delay="200">
                        University Internship Management System
                        <span class="uims-hero-title-highlight">The University of Jordan</span>
                    </h1>

                    <p class="uims-hero-desc reveal-up" data-delay="300">
                        The centralized academic platform connecting IT students, corporate supervisors, faculty mentors, and university coordinators. Discover verified training positions, monitor weekly progress diaries, and achieve graduation accreditation.
                    </p>

                    <div class="uims-hero-actions reveal-up" data-delay="400">
                        <a href="#opportunities" class="uims-btn uims-btn--white">
                            <span>Browse Internships</span>
                            <i class="bi bi-arrow-right"></i>
                        </a>
                        <a href="#how-it-works" class="uims-btn uims-btn--outline-white">
                            <span>Learn How It Works</span>
                            <i class="bi bi-play-circle"></i>
                        </a>
                    </div>

                    <a href="#stats" class="uims-scroll-indicator reveal-up" data-delay="500" aria-label="Scroll down to statistics">
                        <div class="uims-scroll-mouse">
                            <div class="uims-scroll-wheel"></div>
                        </div>
                        <span>Scroll to explore</span>
                    </a>
                </div>

                <!-- Right Column (45%): Animated UJ Clock Tower Scene -->
                <div class="uims-hero-tower-wrapper reveal-up" data-delay="250">
                    <div class="uims-tower-container">
                        <!-- Soft Ambient Radial Glow behind Clock Tower -->
                        <div class="uims-tower-glow" aria-hidden="true"></div>

                        <!-- Inline SVG: Hand-drawn architectural illustration of The University of Jordan Clock Tower -->
                        <svg id="clockTowerScene" class="uims-tower-svg" viewBox="0 0 400 700" width="100%" height="100%" role="img" aria-label="Illustration of the University of Jordan clock tower" xmlns="http://www.w3.org/2000/svg">
                            <defs>
                                <!-- Radial Glow behind Clock Block -->
                                <radialGradient id="clockGlowGrad" cx="50%" cy="50%" r="50%">
                                    <stop offset="0%" stop-color="#178568" stop-opacity="0.55" />
                                    <stop offset="50%" stop-color="#07523E" stop-opacity="0.22" />
                                    <stop offset="100%" stop-color="#04382D" stop-opacity="0" />
                                </radialGradient>

                                <!-- Limestone Column Gradients (Light from top-left) -->
                                <linearGradient id="stoneColumnLeft" x1="0%" y1="0%" x2="100%" y2="0%">
                                    <stop offset="0%" stop-color="#EDE3CC" />
                                    <stop offset="100%" stop-color="#D9CBA8" />
                                </linearGradient>

                                <linearGradient id="stoneColumnRight" x1="0%" y1="0%" x2="100%" y2="0%">
                                    <stop offset="0%" stop-color="#D9CBA8" />
                                    <stop offset="100%" stop-color="#B9A77F" />
                                </linearGradient>

                                <!-- Clock Block Limestone Gradient -->
                                <linearGradient id="clockBlockGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                                    <stop offset="0%" stop-color="#F4EEE0" />
                                    <stop offset="65%" stop-color="#D9CBA8" />
                                    <stop offset="100%" stop-color="#B9A77F" />
                                </linearGradient>

                                <!-- Central Recess Background -->
                                <linearGradient id="latticeBg" x1="0%" y1="0%" x2="100%" y2="0%">
                                    <stop offset="0%" stop-color="#463B30" />
                                    <stop offset="50%" stop-color="#352B21" />
                                    <stop offset="100%" stop-color="#241C15" />
                                </linearGradient>

                                <!-- Diamond Mashrabiya Pattern -->
                                <pattern id="mashrabiyaPattern" width="11" height="16" patternUnits="userSpaceOnUse">
                                    <path d="M 5.5 0 L 11 8 L 5.5 16 L 0 8 Z" fill="none" stroke="#D9CBA8" stroke-width="1.1" stroke-opacity="0.85" />
                                    <path d="M 5.5 2.5 L 9 8 L 5.5 13.5 L 2 8 Z" fill="#685F53" fill-opacity="0.65" />
                                </pattern>

                                <!-- Wet Ground Blur Filter -->
                                <filter id="groundBlur" x="-10%" y="-10%" width="120%" height="120%">
                                    <feGaussianBlur in="SourceGraphic" stdDeviation="2.2" />
                                </filter>

                                <!-- Reflection Clip Region -->
                                <clipPath id="reflectionClip">
                                    <rect x="0" y="556" width="400" height="144" />
                                </clipPath>
                            </defs>

                            <!-- 1. Ambient Glow Behind Clock Block -->
                            <g id="glow" class="uims-scene__glow">
                                <circle cx="200" cy="135" r="165" fill="url(#clockGlowGrad)" />
                            </g>

                            <!-- 2. Wet Ground Reflection (Under Ground Line y=556) -->
                            <g id="ground-reflection" class="uims-scene__reflection" clip-path="url(#reflectionClip)">
                                <!-- Dark Wet Plaza Surface -->
                                <rect x="0" y="556" width="400" height="144" fill="#03251E" />

                                <!-- Inverted Flipped Reflection of Lower Tower -->
                                <g transform="translate(0, 1112) scale(1, -1)" opacity="0.22" filter="url(#groundBlur)">
                                    <rect x="150" y="522" width="100" height="14" fill="#D9CBA8" />
                                    <rect x="140" y="536" width="120" height="12" fill="#B9A77F" />
                                    <rect x="130" y="548" width="140" height="10" fill="#A8966E" />
                                    <rect x="162" y="440" width="76" height="80" fill="#D9CBA8" />
                                    <!-- Inverted Lamp Highlights -->
                                    <circle cx="270" cy="493" r="5" fill="#FFFFFF" opacity="0.4" />
                                    <circle cx="290" cy="493" r="5" fill="#FFFFFF" opacity="0.4" />
                                </g>

                                <!-- Concentric Rain Ripples on Wet Plaza -->
                                <ellipse cx="200" cy="578" rx="42" ry="3.5" fill="none" stroke="#38E4B3" stroke-width="0.8" opacity="0.3" class="uims-ground-ripple" />
                                <ellipse cx="200" cy="610" rx="64" ry="4.5" fill="none" stroke="#38E4B3" stroke-width="0.6" opacity="0.2" class="uims-ground-ripple" />
                                <ellipse cx="280" cy="585" rx="24" ry="2.5" fill="none" stroke="#FFFFFF" stroke-width="0.7" opacity="0.25" class="uims-ground-ripple" />
                            </g>

                            <!-- 3. Cypress & Pine Trees Avenue (Behind & Around Tower) -->
                            <g id="trees" class="uims-scene__trees">
                                <!-- Far Tree Layer (Darkest Green, Deep Distance) -->
                                <g id="trees-far" opacity="0.75">
                                    <path class="tree-sway-mid" d="M 50 556 C 36 480 42 390 50 310 C 58 390 64 480 50 556 Z" fill="#04382D" />
                                    <path class="tree-sway-right" d="M 350 556 C 336 480 342 390 350 310 C 358 390 364 480 350 556 Z" fill="#04382D" />
                                </g>

                                <!-- Mid Tree Layer (Primary Green, Classic Avenue) -->
                                <g id="trees-mid">
                                    <path class="tree-sway-left" d="M 85 556 C 66 465 72 360 85 270 C 98 360 104 465 85 556 Z" fill="#07523E" />
                                    <path class="tree-sway-right" d="M 315 556 C 296 465 302 360 315 270 C 328 360 334 465 315 556 Z" fill="#07523E" />
                                </g>

                                <!-- Near Tree Layer (Accent Green, Closest Foliage) -->
                                <g id="trees-near">
                                    <path class="tree-sway-mid" d="M 120 556 C 106 485 110 415 120 345 C 130 415 134 485 120 556 Z" fill="#178568" opacity="0.9" />
                                    <path class="tree-sway-left" d="M 275 556 C 261 485 265 415 275 345 C 285 415 289 485 275 556 Z" fill="#178568" opacity="0.9" />
                                </g>
                            </g>

                            <!-- 4. Plaza Ground Pavement & Student Silhouettes -->
                            <g id="ground-plaza">
                                <!-- Stone Plaza Surface -->
                                <rect x="0" y="556" width="400" height="6" fill="#07523E" opacity="0.85" />
                                <!-- Low-Contrast Striped Curb Edge -->
                                <line x1="90" y1="556" x2="310" y2="556" stroke="#183B31" stroke-width="2.5" />
                                <line x1="90" y1="556" x2="310" y2="556" stroke="#C49B38" stroke-width="2.5" stroke-dasharray="14 14" opacity="0.65" />

                                <!-- Student Silhouettes Walking on Plaza -->
                                <!-- Student 1 with Umbrella (x=115) -->
                                <g transform="translate(112, 532)" opacity="0.75">
                                    <path d="M 0 6 Q 7 0 14 6 Z" fill="#04382D" /> <!-- Umbrella canopy -->
                                    <line x1="7" y1="6" x2="7" y2="14" stroke="#04382D" stroke-width="1" /> <!-- Umbrella shaft -->
                                    <circle cx="7" cy="11" r="2" fill="#04382D" /> <!-- Head -->
                                    <path d="M 5 13 L 9 13 L 8 22 L 6 22 Z" fill="#04382D" /> <!-- Body & coat -->
                                </g>

                                <!-- Student 2 Walking toward Tower (x=290) -->
                                <g transform="translate(290, 536)" opacity="0.75">
                                    <circle cx="4" cy="3" r="2" fill="#04382D" />
                                    <path d="M 2 5 L 6 5 L 5 18 L 3 18 Z" fill="#04382D" />
                                    <rect x="5.5" y="7" width="2" height="5" rx="1" fill="#178568" /> <!-- Backpack -->
                                </g>

                                <!-- Student 3 (x=308) -->
                                <g transform="translate(308, 538)" opacity="0.65">
                                    <circle cx="3" cy="2.5" r="1.8" fill="#04382D" />
                                    <path d="M 1.5 4.5 L 4.5 4.5 L 4 16 L 2 16 Z" fill="#04382D" />
                                </g>
                            </g>

                            <!-- 5. Tower Stepped Plinth Base & Main Shaft Body -->
                            <g id="tower-body" class="uims-scene__tower-body">
                                <!-- Stepped Limestone Base -->
                                <rect x="130" y="546" width="140" height="10" rx="1.5" fill="#A8966E" stroke="#8C7C5A" stroke-width="0.8" />
                                <rect x="140" y="534" width="120" height="12" rx="1.5" fill="#B9A77F" stroke="#8C7C5A" stroke-width="0.8" />
                                <rect x="150" y="520" width="100" height="14" rx="1" fill="#D9CBA8" stroke="#8C7C5A" stroke-width="0.8" />

                                <!-- Lower Base Trim Stone -->
                                <rect x="162" y="508" width="76" height="12" fill="#EDE3CC" stroke="#D9CBA8" stroke-width="0.8" />

                                <!-- Tower Shaft: Left Solid Limestone Column (Light) -->
                                <rect x="162" y="175" width="16" height="333" fill="url(#stoneColumnLeft)" stroke="#B9A77F" stroke-width="0.8" />

                                <!-- Tower Shaft: Right Solid Limestone Column (Shadow) -->
                                <rect x="222" y="175" width="16" height="333" fill="url(#stoneColumnRight)" stroke="#B9A77F" stroke-width="0.8" />

                                <!-- Fine Horizontal Masonry Block Lines on Columns (Every 24px) -->
                                <g stroke="#8C7C5A" stroke-width="0.7" opacity="0.65">
                                    <line x1="162" y1="200" x2="178" y2="200" />
                                    <line x1="222" y1="200" x2="238" y2="200" />
                                    <line x1="162" y1="224" x2="178" y2="224" />
                                    <line x1="222" y1="224" x2="238" y2="224" />
                                    <line x1="162" y1="248" x2="178" y2="248" />
                                    <line x1="222" y1="248" x2="238" y2="248" />
                                    <line x1="162" y1="272" x2="178" y2="272" />
                                    <line x1="222" y1="272" x2="238" y2="272" />
                                    <line x1="162" y1="296" x2="178" y2="296" />
                                    <line x1="222" y1="296" x2="238" y2="296" />
                                    <line x1="162" y1="320" x2="178" y2="320" />
                                    <line x1="222" y1="320" x2="238" y2="320" />
                                    <line x1="162" y1="344" x2="178" y2="344" />
                                    <line x1="222" y1="344" x2="238" y2="344" />
                                    <line x1="162" y1="368" x2="178" y2="368" />
                                    <line x1="222" y1="368" x2="238" y2="368" />
                                    <line x1="162" y1="392" x2="178" y2="392" />
                                    <line x1="222" y1="392" x2="238" y2="392" />
                                    <line x1="162" y1="416" x2="178" y2="416" />
                                    <line x1="222" y1="416" x2="238" y2="416" />
                                    <line x1="162" y1="440" x2="178" y2="440" />
                                    <line x1="222" y1="440" x2="238" y2="440" />
                                    <line x1="162" y1="464" x2="178" y2="464" />
                                    <line x1="222" y1="464" x2="238" y2="464" />
                                    <line x1="162" y1="488" x2="178" y2="488" />
                                    <line x1="222" y1="488" x2="238" y2="488" />
                                </g>
                            </g>

                            <!-- 6. Central Recessed Mashrabiya Diamond Lattice Screen -->
                            <g id="lattice" class="uims-scene__lattice">
                                <!-- Deep Stone Recess -->
                                <rect x="178" y="188" width="44" height="320" fill="url(#latticeBg)" stroke="#1F1812" stroke-width="1.2" />
                                <!-- Mashrabiya Openwork Screen Fill -->
                                <rect x="178" y="188" width="44" height="320" fill="url(#mashrabiyaPattern)" />
                                <!-- Vertical Mullion Divider -->
                                <line x1="200" y1="188" x2="200" y2="508" stroke="#D9CBA8" stroke-width="1.2" stroke-opacity="0.8" />
                                <!-- Structural Transoms -->
                                <line x1="178" y1="252" x2="222" y2="252" stroke="#B9A77F" stroke-width="1.2" stroke-opacity="0.8" />
                                <line x1="178" y1="316" x2="222" y2="316" stroke="#B9A77F" stroke-width="1.2" stroke-opacity="0.8" />
                                <line x1="178" y1="380" x2="222" y2="380" stroke="#B9A77F" stroke-width="1.2" stroke-opacity="0.8" />
                                <line x1="178" y1="444" x2="222" y2="444" stroke="#B9A77F" stroke-width="1.2" stroke-opacity="0.8" />
                            </g>

                            <!-- 7. Square Clock Block with Stone Cornice -->
                            <g id="clock-block" class="uims-scene__clock-block">
                                <!-- Upper Architrave Band -->
                                <rect x="154" y="92" width="92" height="4" fill="#EDE3CC" stroke="#B9A77F" stroke-width="0.8" />
                                <!-- Square Clock Face Stone Block -->
                                <rect x="156" y="95" width="88" height="80" rx="3" fill="url(#clockBlockGrad)" stroke="#B9A77F" stroke-width="1.5" />
                                <!-- Lower Sill Cornice -->
                                <rect x="154" y="173" width="92" height="4" fill="#B9A77F" stroke="#8C7C5A" stroke-width="0.8" />
                            </g>

                            <!-- 8. Circular Clock Face Dial & Ticks -->
                            

                            <!-- Invisible Click/Hover Area for Tooltip -->
                            <rect class="uims-clock-trigger" x="156" y="95" width="88" height="80" rx="3" fill="transparent" cursor="pointer" pointer-events="all" />

                            <!-- 9. Flat Roof Top Cap (NO Dome, NO Pyramid) -->
                            <g id="tower-cap" class="uims-scene__tower-cap">
                                <!-- Main Flat Roof Slab -->
                                <rect x="152" y="85" width="96" height="9" fill="#EDE3CC" stroke="#D9CBA8" stroke-width="0.8" />
                                <!-- Slim Overhanging Cornice Ledge -->
                                <rect x="148" y="81" width="104" height="4" rx="0.5" fill="#F4EEE0" stroke="#EDE3CC" stroke-width="0.5" />
                                <!-- Under-Ledge Shadow Line -->
                                <rect x="152" y="93" width="96" height="2" fill="#8C7C5A" opacity="0.6" />
                            </g>

                            <!-- 10. Rooftop Antenna Mast & Weather-Vane Instrument Cluster -->
                            <g id="mast" class="uims-scene__mast">
                                <!-- Vertical Mast Pole -->
                                <line x1="200" y1="42" x2="200" y2="81" stroke="#D9CBA8" stroke-width="1.8" stroke-linecap="round" />
                                <!-- Weather-Vane Crossbar -->
                                <line x1="192" y1="52" x2="208" y2="52" stroke="#EDE3CC" stroke-width="1.2" />
                                <polygon points="208,50 213,52 208,54" fill="#38E4B3" />
                                <line x1="192" y1="49" x2="192" y2="55" stroke="#EDE3CC" stroke-width="1" />
                                <!-- Instrument / Anemometer Horizontal Bar -->
                                <line x1="194" y1="62" x2="206" y2="62" stroke="#D9CBA8" stroke-width="1" />
                                <circle cx="194" cy="62" r="1.5" fill="#EDE3CC" />
                                <circle cx="206" cy="62" r="1.5" fill="#EDE3CC" />
                                <!-- Top Mast Finial Sphere -->
                                <circle cx="200" cy="42" r="2.5" fill="#38E4B3" />
                            </g>

                            <!-- 11. Curved Campus Street Lamps (Right Side of Tower) -->
                            <g id="lamps" class="uims-scene__lamps">
                                <!-- Lamp 1 (Near Right) -->
                                <g>
                                    <line x1="280" y1="495" x2="280" y2="556" stroke="#E2E8E5" stroke-width="1.6" />
                                    <!-- Two Curved Arms -->
                                    <path d="M 270 493 Q 280 487 290 493" fill="none" stroke="#E2E8E5" stroke-width="1.4" />
                                    <!-- Globes & Halos -->
                                    <circle cx="270" cy="494" r="7" fill="#F4EEE0" opacity="0.3" class="uims-lamp-halo" />
                                    <circle cx="290" cy="494" r="7" fill="#F4EEE0" opacity="0.3" class="uims-lamp-halo" />
                                    <circle cx="270" cy="494" r="3.2" fill="#FFFFFF" class="uims-lamp-globe" />
                                    <circle cx="290" cy="494" r="3.2" fill="#FFFFFF" class="uims-lamp-globe" />
                                </g>

                                <!-- Lamp 2 (Far Right) -->
                                <g>
                                    <line x1="345" y1="506" x2="345" y2="556" stroke="#E2E8E5" stroke-width="1.4" opacity="0.85" />
                                    <path d="M 337 504 Q 345 499 353 504" fill="none" stroke="#E2E8E5" stroke-width="1.2" opacity="0.85" />
                                    <circle cx="337" cy="505" r="5" fill="#F4EEE0" opacity="0.25" class="uims-lamp-halo" />
                                    <circle cx="353" cy="505" r="5" fill="#F4EEE0" opacity="0.25" class="uims-lamp-halo" />
                                    <circle cx="337" cy="505" r="2.6" fill="#FFFFFF" opacity="0.9" class="uims-lamp-globe" />
                                    <circle cx="353" cy="505" r="2.6" fill="#FFFFFF" opacity="0.9" class="uims-lamp-globe" />
                                </g>
                            </g>

                            <!-- 12. Diagonal Ambient Rain Streaks (24 Lines, Lightweight CSS Keyframes) -->
                            <g id="rain" class="uims-scene__rain" aria-hidden="true">
                                <line x1="30" y1="80" x2="42" y2="128" class="uims-rain-streak" style="animation-delay: 0.1s;" />
                                <line x1="80" y1="40" x2="92" y2="88" class="uims-rain-streak" style="animation-delay: 0.5s;" />
                                <line x1="130" y1="120" x2="142" y2="168" class="uims-rain-streak" style="animation-delay: 0.8s;" />
                                <line x1="170" y1="30" x2="182" y2="78" class="uims-rain-streak" style="animation-delay: 0.3s;" />
                                <line x1="230" y1="60" x2="242" y2="108" class="uims-rain-streak" style="animation-delay: 0.9s;" />
                                <line x1="280" y1="140" x2="292" y2="188" class="uims-rain-streak" style="animation-delay: 0.2s;" />
                                <line x1="330" y1="50" x2="342" y2="98" class="uims-rain-streak" style="animation-delay: 0.7s;" />
                                <line x1="370" y1="110" x2="382" y2="158" class="uims-rain-streak" style="animation-delay: 0.4s;" />
                                <line x1="45" y1="260" x2="57" y2="308" class="uims-rain-streak" style="animation-delay: 0.6s;" />
                                <line x1="100" y1="210" x2="112" y2="258" class="uims-rain-streak" style="animation-delay: 1.1s;" />
                                <line x1="150" y1="290" x2="162" y2="338" class="uims-rain-streak" style="animation-delay: 0.35s;" />
                                <line x1="250" y1="240" x2="262" y2="288" class="uims-rain-streak" style="animation-delay: 0.75s;" />
                                <line x1="300" y1="280" x2="312" y2="328" class="uims-rain-streak" style="animation-delay: 0.15s;" />
                                <line x1="360" y1="230" x2="372" y2="278" class="uims-rain-streak" style="animation-delay: 0.95s;" />
                                <line x1="60" y1="420" x2="72" y2="468" class="uims-rain-streak" style="animation-delay: 0.4s;" />
                                <line x1="110" y1="380" x2="122" y2="428" class="uims-rain-streak" style="animation-delay: 0.85s;" />
                                <line x1="155" y1="450" x2="167" y2="498" class="uims-rain-streak" style="animation-delay: 0.25s;" />
                                <line x1="245" y1="430" x2="257" y2="478" class="uims-rain-streak" style="animation-delay: 0.65s;" />
                                <line x1="295" y1="460" x2="307" y2="508" class="uims-rain-streak" style="animation-delay: 1.05s;" />
                                <line x1="350" y1="410" x2="362" y2="458" class="uims-rain-streak" style="animation-delay: 0.55s;" />
                                <line x1="85" y1="500" x2="97" y2="548" class="uims-rain-streak" style="animation-delay: 0.3s;" />
                                <line x1="140" y1="520" x2="152" y2="568" class="uims-rain-streak" style="animation-delay: 0.7s;" />
                                <line x1="265" y1="510" x2="277" y2="558" class="uims-rain-streak" style="animation-delay: 0.45s;" />
                                <line x1="325" y1="525" x2="337" y2="573" class="uims-rain-streak" style="animation-delay: 0.85s;" />
                            </g>
                        </svg>

                        <!-- Interactive Hover Tooltip for Amman Local Time -->
                        <div class="uims-clock-tooltip" id="clockTooltip" role="tooltip">
                            <div class="uims-clock-tooltip__time">
                                <i class="bi bi-clock-fill"></i>
                                <span id="ammanTimeDisplay">--:--:--</span>
                            </div>
                            <div class="uims-clock-tooltip__loc">
                                <i class="bi bi-geo-alt-fill"></i> The University of Jordan · Amman
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- 3. Floating Stats Strip (Overlaps Hero Bottom) -->
    <section class="uims-stats-strip" id="stats">
        <div class="uims-container">
            <div class="uims-stats-grid">
                <div class="uims-stat-card reveal-up" data-delay="100">
                    <div class="uims-stat-icon">
                        <i class="bi bi-mortarboard-fill"></i>
                    </div>
                    <div class="uims-stat-number" data-target="1250" data-suffix="+">0</div>
                    <div class="uims-stat-label">Active Trainees</div>
                    <div class="uims-stat-hint">Registered KASIT students</div>
                </div>

                <div class="uims-stat-card reveal-up" data-delay="200">
                    <div class="uims-stat-icon">
                        <i class="bi bi-buildings-fill"></i>
                    </div>
                    <div class="uims-stat-number" data-target="85" data-suffix="+">0</div>
                    <div class="uims-stat-label">Partner Companies</div>
                    <div class="uims-stat-hint">Telecom, FinTech &amp; Tech Hubs</div>
                </div>

                <div class="uims-stat-card reveal-up" data-delay="300">
                    <div class="uims-stat-icon">
                        <i class="bi bi-briefcase-fill"></i>
                    </div>
                    <div class="uims-stat-number" data-target="140" data-suffix="+">0</div>
                    <div class="uims-stat-label">Verified Opportunities</div>
                    <div class="uims-stat-hint">Active training seats</div>
                </div>

                <div class="uims-stat-card reveal-up" data-delay="400">
                    <div class="uims-stat-icon">
                        <i class="bi bi-clock-history"></i>
                    </div>
                    <div class="uims-stat-number" data-target="45000" data-suffix="+">0</div>
                    <div class="uims-stat-label">Completed Hours</div>
                    <div class="uims-stat-hint">Accredited training logs</div>
                </div>
            </div>
        </div>
    </section>

    <!-- 4. About System & University Section -->
    <section class="py-5" id="about">
        <div class="uims-container">
            <div class="uims-section-header">
                <span class="uims-eyebrow"><i class="bi bi-info-circle-fill"></i> Institutional Framework</span>
                <h2 class="uims-section-title">Bridging Academic Excellence With Real-World Industry</h2>
                <p class="uims-section-subtitle">
                    The University Internship Management System (UIMS) is the official training gateway at King Abdullah II School of Information Technology. It streamlines field placements into an integrated, transparent digital workflow.
                </p>
            </div>

            <div class="row g-4 align-items-center">
                <div class="col-lg-6 reveal-left">
                    <div class="uims-card p-4">
                        <h3 class="fw-bold mb-3 text-primary">Why UIMS at The University of Jordan?</h3>
                        <p class="text-muted mb-4">
                            Practical training is a core graduation requirement for all computer science, software engineering, and IT specializations. UIMS eliminates administrative friction by uniting every stakeholder on a single platform.
                        </p>

                        <div class="d-flex flex-column gap-3">
                            <div class="d-flex align-items-start gap-3">
                                <div class="uims-stat-icon m-0 flex-shrink-0">
                                    <i class="bi bi-shield-check"></i>
                                </div>
                                <div>
                                    <h5 class="fw-bold mb-1 fs-6">Accredited University Standards</h5>
                                    <p class="text-muted mb-0 small">Every opportunity is officially verified to meet the school's 320-hour curriculum standards.</p>
                                </div>
                            </div>

                            <div class="d-flex align-items-start gap-3">
                                <div class="uims-stat-icon m-0 flex-shrink-0">
                                    <i class="bi bi-journal-check"></i>
                                </div>
                                <div>
                                    <h5 class="fw-bold mb-1 fs-6">Weekly Digital Diary &amp; Task Audits</h5>
                                    <p class="text-muted mb-0 small">Students log deliverables and skills, supervised continuously by both corporate mentors and faculty.</p>
                                </div>
                            </div>

                            <div class="d-flex align-items-start gap-3">
                                <div class="uims-stat-icon m-0 flex-shrink-0">
                                    <i class="bi bi-file-earmark-pdf"></i>
                                </div>
                                <div>
                                    <h5 class="fw-bold mb-1 fs-6">Instant Completion Certification</h5>
                                    <p class="text-muted mb-0 small">Approved evaluations automatically generate the official field training clearance certificate.</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-lg-6 reveal-right">
                    <div class="uims-identity-visual">
                        <img src="Assets/PublicHome/university-hero.jpg" alt="University of Jordan Campus Clock Tower" />
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- 5. "How It Works" Timeline Section (Scroll-Driven Progress) -->
    <section class="uims-timeline-section" id="how-it-works">
        <div class="uims-container">
            <div class="uims-section-header">
                <span class="uims-eyebrow"><i class="bi bi-diagram-3-fill"></i> Internship Lifecycle</span>
                <h2 class="uims-section-title">Your Internship Journey, Step by Step</h2>
                <p class="uims-section-subtitle">
                    Follow the verified 6-stage roadmap from initial application to official graduation sign-off.
                </p>
            </div>

            <div class="uims-timeline-container">
                <!-- Vertical Progress Line -->
                <div class="uims-timeline-track" aria-hidden="true">
                    <div class="uims-timeline-progress-bar" id="timelineProgressBar"></div>
                </div>

                <!-- Step 1 -->
                <div class="uims-timeline-step reveal-up" data-delay="100">
                    <div class="uims-timeline-node">
                        <i class="bi bi-person-plus-fill"></i>
                    </div>
                    <div class="uims-timeline-card">
                        <div class="uims-timeline-step-num">Step 01</div>
                        <h3 class="uims-timeline-step-title">Register &amp; Complete Student Profile</h3>
                        <p class="uims-timeline-step-desc">
                            Sign in using your official university credentials. Update your technical skills, CV link, and major specialization to become eligible for placement matching.
                        </p>
                    </div>
                </div>

                <!-- Step 2 -->
                <div class="uims-timeline-step reveal-up" data-delay="200">
                    <div class="uims-timeline-node">
                        <i class="bi bi-search"></i>
                    </div>
                    <div class="uims-timeline-card">
                        <div class="uims-timeline-step-num">Step 02</div>
                        <h3 class="uims-timeline-step-title">Browse &amp; Apply for Opportunities</h3>
                        <p class="uims-timeline-step-desc">
                            Explore verified internships from leading telecom companies, software houses, and banks. Submit your application directly through the student portal.
                        </p>
                    </div>
                </div>

                <!-- Step 3 -->
                <div class="uims-timeline-step reveal-up" data-delay="300">
                    <div class="uims-timeline-node">
                        <i class="bi bi-check2-circle"></i>
                    </div>
                    <div class="uims-timeline-card">
                        <div class="uims-timeline-step-num">Step 03</div>
                        <h3 class="uims-timeline-step-title">Company Review &amp; Placement Confirmation</h3>
                        <p class="uims-timeline-step-desc">
                            Host companies review candidate portfolios, conduct interviews, and issue digital acceptance offers. Once confirmed, your official training term commences.
                        </p>
                    </div>
                </div>

                <!-- Step 4 -->
                <div class="uims-timeline-step reveal-up" data-delay="400">
                    <div class="uims-timeline-node">
                        <i class="bi bi-code-slash"></i>
                    </div>
                    <div class="uims-timeline-card">
                        <div class="uims-timeline-step-num">Step 04</div>
                        <h3 class="uims-timeline-step-title">Execute Tasks &amp; Submit Weekly Diaries</h3>
                        <p class="uims-timeline-step-desc">
                            Work on real company assignments. Submit weekly diaries and code links for review. Accumulate verified hours toward the mandatory 320-hour milestone.
                        </p>
                    </div>
                </div>

                <!-- Step 5 -->
                <div class="uims-timeline-step reveal-up" data-delay="500">
                    <div class="uims-timeline-node">
                        <i class="bi bi-star-fill"></i>
                    </div>
                    <div class="uims-timeline-card">
                        <div class="uims-timeline-step-num">Step 05</div>
                        <h3 class="uims-timeline-step-title">Dual Academic &amp; Corporate Evaluation</h3>
                        <p class="uims-timeline-step-desc">
                            Your company supervisor assesses technical performance and professionalism, while your academic supervisor conducts site visits and assesses learning outcomes.
                        </p>
                    </div>
                </div>

                <!-- Step 6 -->
                <div class="uims-timeline-step reveal-up" data-delay="600">
                    <div class="uims-timeline-node">
                        <i class="bi bi-mortarboard-fill"></i>
                    </div>
                    <div class="uims-timeline-card">
                        <div class="uims-timeline-step-num">Step 06</div>
                        <h3 class="uims-timeline-step-title">Faculty Sign-Off &amp; Official Completion</h3>
                        <p class="uims-timeline-step-desc">
                            The KASIT Field Training Coordinator reviews overall evaluations and gives final approval. Your accredited completion report is issued for graduation clearance.
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- 6. Role Portals Section (4 Stakeholder Cards) -->
    <section class="uims-roles-section" id="roles">
        <div class="uims-container">
            <div class="uims-section-header">
                <span class="uims-eyebrow"><i class="bi bi-people-fill"></i> Multi-Role Collaboration</span>
                <h2 class="uims-section-title">Designed for Every Stakeholder</h2>
                <p class="uims-section-subtitle">
                    Dedicated digital dashboards tailored to the specialized workflows of students, companies, faculty, and coordinators.
                </p>
            </div>

            <div class="uims-roles-grid">
                <!-- Role 1: Student Trainee -->
                <div class="uims-role-card reveal-up" data-delay="100">
                    <div>
                        <div class="uims-role-icon">
                            <i class="bi bi-person-workspace"></i>
                        </div>
                        <h3 class="uims-role-title">Student Trainee</h3>
                        <p class="uims-role-desc">
                            Discover career-defining internships, log training diaries, track task evaluations, and submit your completion requirements.
                        </p>
                        <ul class="uims-role-perks">
                            <li><i class="bi bi-check-circle-fill"></i> Browse verified corporate openings</li>
                            <li><i class="bi bi-check-circle-fill"></i> Weekly task diaries &amp; hours tracking</li>
                            <li><i class="bi bi-check-circle-fill"></i> Digital completion report download</li>
                        </ul>
                    </div>
                    <a href="<%= ResolveUrl("~/login/Login.aspx") %>" class="uims-role-link">
                        <span>Sign In as Student</span>
                        <i class="bi bi-arrow-right"></i>
                    </a>
                </div>

                <!-- Role 2: Company Supervisor -->
                <div class="uims-role-card reveal-up" data-delay="200">
                    <div>
                        <div class="uims-role-icon">
                            <i class="bi bi-building-gear"></i>
                        </div>
                        <h3 class="uims-role-title">Company Supervisor</h3>
                        <p class="uims-role-desc">
                            Publish training opportunities, review student candidates, assign weekly milestones, and evaluate trainee performance.
                        </p>
                        <ul class="uims-role-perks">
                            <li><i class="bi bi-check-circle-fill"></i> Candidate screening &amp; selection</li>
                            <li><i class="bi bi-check-circle-fill"></i> Weekly task assignment &amp; feedback</li>
                            <li><i class="bi bi-check-circle-fill"></i> Final performance grading rubrics</li>
                        </ul>
                    </div>
                    <a href="<%= ResolveUrl("~/login/Login.aspx") %>" class="uims-role-link">
                        <span>Sign In as Company</span>
                        <i class="bi bi-arrow-right"></i>
                    </a>
                </div>

                <!-- Role 3: Academic Supervisor -->
                <div class="uims-role-card reveal-up" data-delay="300">
                    <div>
                        <div class="uims-role-icon">
                            <i class="bi bi-mortarboard"></i>
                        </div>
                        <h3 class="uims-role-title">Academic Supervisor</h3>
                        <p class="uims-role-desc">
                            Oversee assigned faculty trainees, review corporate evaluations, conduct supervision visits, and submit academic assessments.
                        </p>
                        <ul class="uims-role-perks">
                            <li><i class="bi bi-check-circle-fill"></i> Real-time trainee monitoring</li>
                            <li><i class="bi bi-check-circle-fill"></i> Corporate evaluation review</li>
                            <li><i class="bi bi-check-circle-fill"></i> Academic grade submission</li>
                        </ul>
                    </div>
                    <a href="<%= ResolveUrl("~/login/Login.aspx") %>" class="uims-role-link">
                        <span>Sign In as Academic</span>
                        <i class="bi bi-arrow-right"></i>
                    </a>
                </div>

                <!-- Role 4: Department Coordinator -->
                <div class="uims-role-card reveal-up" data-delay="400">
                    <div>
                        <div class="uims-role-icon">
                            <i class="bi bi-shield-lock-fill"></i>
                        </div>
                        <h3 class="uims-role-title">Faculty Coordinator</h3>
                        <p class="uims-role-desc">
                            Manage school-wide training operations, assign academic mentors to students, audit compliance, and grant graduation clearance.
                        </p>
                        <ul class="uims-role-perks">
                            <li><i class="bi bi-check-circle-fill"></i> Department-wide analytics &amp; audit</li>
                            <li><i class="bi bi-check-circle-fill"></i> Supervisor-student allocations</li>
                            <li><i class="bi bi-check-circle-fill"></i> Official completion verification</li>
                        </ul>
                    </div>
                    <a href="<%= ResolveUrl("~/login/Login.aspx") %>" class="uims-role-link">
                        <span>Sign In as Coordinator</span>
                        <i class="bi bi-arrow-right"></i>
                    </a>
                </div>
            </div>
        </div>
    </section>

    <!-- 7. Featured Internships Section (Live Filter & Dynamic Cards) -->
    <section class="uims-jobs-section" id="opportunities">
        <div class="uims-container">
            <div class="uims-section-header">
                <span class="uims-eyebrow"><i class="bi bi-briefcase-fill"></i> Curated Placements</span>
                <h2 class="uims-section-title">Latest Verified Internship Opportunities</h2>
                <p class="uims-section-subtitle">
                    Explore available positions published by our corporate partners across Jordan's leading tech sectors.
                </p>
            </div>

            <!-- Toolbar with Search and Carousel Controls -->
            <div class="uims-jobs-toolbar reveal-up">
                <div class="uims-search-wrapper">
                    <i class="bi bi-search uims-search-icon"></i>
                    <input type="search" id="searchInput" class="uims-search" placeholder="Search by company, major, or technology (e.g. AI, Cloud, .NET)..." aria-label="Search internship opportunities" />
                </div>

                <div class="uims-carousel-controls">
                    <span class="uims-carousel-count" id="carouselCount">Loading opportunities...</span>
                    <button type="button" class="uims-arrow-btn" id="previousJobs" aria-label="Previous internships" disabled>
                        <i class="bi bi-chevron-left"></i>
                    </button>
                    <button type="button" class="uims-arrow-btn" id="nextJobs" aria-label="Next internships">
                        <i class="bi bi-chevron-right"></i>
                    </button>
                </div>
            </div>

            <p class="small text-muted">Preview snapshot — internship listings do not update in this standalone version.</p>
            <div class="uims-jobs-grid" id="jobGrid" tabindex="0" aria-label="Internship cards carousel">
                <!-- Javascript will render cards here -->
            </div>

            <div class="text-center mt-5">
                <a href="<%= ResolveUrl("~/Student/Opportunities/Opportunities.aspx") %>" class="uims-btn uims-btn--outline-primary">
                    <span>View All Field Opportunities</span>
                    <i class="bi bi-arrow-up-right"></i>
                </a>
            </div>
        </div>
    </section>

    <!-- 8. University Identity Band (Parallax, Faint Watermark, Academic Statement) -->
    <section class="uims-identity-band" id="identity">
        <!-- Faint UJ Monogram Watermark -->
        <div class="uims-identity-monogram" aria-hidden="true">UJ 1962</div>

        <div class="uims-container">
            <div class="uims-identity-layout">
                <div class="reveal-left">
                    <div class="uims-identity-quote-symbol">
                        <i class="bi bi-quote"></i>
                    </div>
                    <h2 class="uims-identity-heading">
                        Empowering Jordanian IT Leaders to Excel in Global Markets
                    </h2>
                    <p class="uims-identity-statement">
                        "At King Abdullah II School of Information Technology, we believe that academic rigor achieves its fullest potential when paired with immersive field experience. Our internship program is an institutional bridge connecting classroom fundamentals with cutting-edge industry practice."
                    </p>
                    <div class="uims-identity-meta">
                        <img src="Assets/PublicHome/university-logo.png" alt="University Seal" class="uims-identity-seal" />
                        <div>
                            <div class="uims-identity-author-title">King Abdullah II School of Information Technology (KASIT)</div>
                            <div class="uims-identity-author-sub">The University of Jordan · Amman, Hashemite Kingdom of Jordan</div>
                        </div>
                    </div>
                </div>

                <div class="reveal-right">
                    <div class="uims-identity-visual">
                        <img src="Assets/PublicHome/university-hero.jpg" alt="University of Jordan Campus Gate" />
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- 9. FAQ Section (Accessible Accordion) -->
    <section class="uims-faq-section" id="faq">
        <div class="uims-container">
            <div class="uims-section-header">
                <span class="uims-eyebrow"><i class="bi bi-question-circle-fill"></i> Common Questions</span>
                <h2 class="uims-section-title">Frequently Asked Questions</h2>
                <p class="uims-section-subtitle">
                    Find answers regarding field training eligibility, credit requirements, and administrative approvals.
                </p>
            </div>

            <div class="uims-accordion" id="uimsAccordion">
                <!-- Item 1 -->
                <div class="uims-accordion-item">
                    <h3 class="uims-accordion-header">
                        <button type="button" class="uims-accordion-btn" aria-expanded="false">
                            <span>How do I qualify and register for field training at KASIT?</span>
                            <div class="uims-accordion-icon"><i class="bi bi-plus-lg"></i></div>
                        </button>
                    </h3>
                    <div class="uims-accordion-collapse">
                        <div class="uims-accordion-body">
                            Students must successfully complete at least 90 credit hours within their degree plan to become eligible. Once eligible, sign in to UIMS using your university email, complete your profile, and browse verified listings.
                        </div>
                    </div>
                </div>

                <!-- Item 2 -->
                <div class="uims-accordion-item">
                    <h3 class="uims-accordion-header">
                        <button type="button" class="uims-accordion-btn" aria-expanded="false">
                            <span>How many training hours are required for graduation clearance?</span>
                            <div class="uims-accordion-icon"><i class="bi bi-plus-lg"></i></div>
                        </button>
                    </h3>
                    <div class="uims-accordion-collapse">
                        <div class="uims-accordion-body">
                            The accredited requirement is a minimum of <strong>320 hours</strong> of documented, verified work (typically spanning 8 to 10 weeks). Hours are logged via weekly tasks and validated by your company mentor.
                        </div>
                    </div>
                </div>

                <!-- Item 3 -->
                <div class="uims-accordion-item">
                    <h3 class="uims-accordion-header">
                        <button type="button" class="uims-accordion-btn" aria-expanded="false">
                            <span>Can I apply to multiple internship opportunities simultaneously?</span>
                            <div class="uims-accordion-icon"><i class="bi bi-plus-lg"></i></div>
                        </button>
                    </h3>
                    <div class="uims-accordion-collapse">
                        <div class="uims-accordion-body">
                            Yes, you may submit applications to several open listings. However, once you accept an official offer from a host organization, your status updates to active trainee, and other open applications are automatically concluded.
                        </div>
                    </div>
                </div>

                <!-- Item 4 -->
                <div class="uims-accordion-item">
                    <h3 class="uims-accordion-header">
                        <button type="button" class="uims-accordion-btn" aria-expanded="false">
                            <span>How does the academic supervisor evaluate my training?</span>
                            <div class="uims-accordion-icon"><i class="bi bi-plus-lg"></i></div>
                        </button>
                    </h3>
                    <div class="uims-accordion-collapse">
                        <div class="uims-accordion-body">
                            Your faculty supervisor reviews your submitted weekly diaries, inspects code repositories, communicates with your company mentor, and conducts an on-site or virtual visit before submitting your final academic assessment.
                        </div>
                    </div>
                </div>

                <!-- Item 5 -->
                <div class="uims-accordion-item">
                    <h3 class="uims-accordion-header">
                        <button type="button" class="uims-accordion-btn" aria-expanded="false">
                            <span>When can I download my official Field Training Completion Certificate?</span>
                            <div class="uims-accordion-icon"><i class="bi bi-plus-lg"></i></div>
                        </button>
                    </h3>
                    <div class="uims-accordion-collapse">
                        <div class="uims-accordion-body">
                            Upon reaching 320 hours and after both company and academic evaluations are submitted, the department coordinator approves the record. The official clearance report becomes immediately downloadable from your dashboard.
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- 10. Contact Us & Institutional Footer -->
    <footer class="uims-footer" id="contact">
        <div class="uims-container">
            <div class="uims-footer-grid">
                <!-- Col 1: About University -->
                <div>
                    <h4 class="uims-footer-col-title">The University of Jordan</h4>
                    <p class="uims-footer-desc">
                        King Abdullah II School of Information Technology (KASIT). Delivering world-class computing education and pioneering regional research since 1962.
                    </p>
                    <div class="d-flex align-items-center gap-2">
                        <span class="uims-badge uims-badge--mint">
                            <i class="bi bi-patch-check-fill"></i> Official Portal
                        </span>
                    </div>
                </div>

                <!-- Col 2: Navigation Links -->
                <div>
                    <h4 class="uims-footer-col-title">Quick Navigation</h4>
                    <ul class="uims-footer-links">
                        <li><a href="#home">Home Portal</a></li>
                        <li><a href="#about">About the System</a></li>
                        <li><a href="#how-it-works">How It Works</a></li>
                        <li><a href="#roles">Stakeholder Portals</a></li>
                        <li><a href="#opportunities">Internship Directory</a></li>
                        <li><a href="#faq">Frequently Asked Questions</a></li>
                    </ul>
                </div>

                <!-- Col 3: Contact Details -->
                <div>
                    <h4 class="uims-footer-col-title">Contact Information</h4>
                    <div class="uims-footer-contact-item">
                        <i class="bi bi-geo-alt-fill"></i>
                        <span>Queen Rania Street, Amman, Jordan</span>
                    </div>
                    <div class="uims-footer-contact-item">
                        <i class="bi bi-telephone-fill"></i>
                        <span>+962 6 5355000 Ext. 22000</span>
                    </div>
                    <div class="uims-footer-contact-item">
                        <i class="bi bi-envelope-fill"></i>
                        <span>kasit.training@ju.edu.jo</span>
                    </div>
                    <div class="uims-footer-contact-item">
                        <i class="bi bi-globe"></i>
                        <a href="https://www.ju.edu.jo" target="_blank" rel="noopener noreferrer">www.ju.edu.jo</a>
                    </div>
                </div>

                <!-- Col 4: Campus Map -->
                <div>
                    <h4 class="uims-footer-col-title">Campus Location</h4>
                    <div class="uims-footer-map">
                        <iframe title="University of Jordan Location on Map" src="https://maps.google.com/maps?q=University%20of%20Jordan%2C%20Amman&amp;z=15&amp;output=embed" loading="lazy" referrerpolicy="no-referrer-when-downgrade" allowfullscreen></iframe>
                    </div>
                    <a href="https://www.google.com/maps/search/?api=1&amp;query=University%20of%20Jordan%2C%20Amman" target="_blank" rel="noopener noreferrer" class="small text-decoration-underline text-light">
                        Open in Google Maps <i class="bi bi-box-arrow-up-right ms-1"></i>
                    </a>
                </div>
            </div>

            <p class="uims-photo-credit">Clock tower photo: <a href="https://registration.ju.edu.jo/en/english/Lists/UnitAnnouncements/Disp_Ann.aspx?ID=32" target="_blank" rel="noopener noreferrer">The University of Jordan · Registration Unit</a>.</p>
            <div class="uims-footer-bottom">
                <div>
                    &copy; 2026 The University of Jordan - King Abdullah II School of Information Technology (KASIT). All rights reserved.
                </div>
                <div class="d-flex align-items-center gap-3">
                    <a href="<%= ResolveUrl("~/Contact.aspx") %>" class="text-light">Contact Us</a>
                    <span>&bull;</span>
                    <a href="<%: DashboardHref %>" class="text-light"><%: IsSignedIn ? "My Dashboard" : "Sign In Portal" %></a>
                </div>
            </div>
        </div>
    </footer>

    <!-- Floating Back to Top Button -->
    <button type="button" class="uims-back-to-top" id="backToTop" aria-label="Back to top">
        <i class="bi bi-arrow-up"></i>
    </button>

    <!-- Data payload preserved for code-behind serialization -->
    <script type="application/json" id="home-data"><%= PublicDataJson %></script>

    <!-- UIMS Unified Interactive Scripts -->
    <script src="<%= ResolveUrl("~/Scripts/uims.js") %>"></script>

        
</asp:Content>
