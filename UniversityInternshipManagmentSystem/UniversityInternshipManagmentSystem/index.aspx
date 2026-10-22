<%@ Page Title="Internship Management System" Language="C#" MasterPageFile="~/Shared/Public.Master" AutoEventWireup="true" Async="true" CodeBehind="index.aspx.cs" Inherits="UniversityInternshipManagmentSystem.PublicHome" %>
<asp:Content ID="HomeHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet" />
    <link href="Assets/PublicHome/Home.css" rel="stylesheet" />
</asp:Content>
<asp:Content ID="HomeBody" ContentPlaceHolderID="MainContent" runat="server">
  <div class="public-home">
<header class="topbar">
    <div class="container nav">
      <a aria-label="Home page" class="brand" href="#home"><img alt="University of Jordan logo" class="brand-logo"
          src="Assets/PublicHome/university-logo.png" /><span><span class="brand-title">The University of Jordan</span><span
            class="brand-sub">The University of Jordan</span></span></a>
      <nav aria-label="Main navigation" class="navlinks" id="navlinks"><a class="active" href="#home">Home</a><a
          href="#opportunities">Internships</a><a href="#about">About</a><a href="#faq">FAQ</a><a
          href="Contact.aspx">Contact Us</a>
        <% if (IsSignedIn) { %><a href="<%= ResolveUrl("~/login/Logout.aspx") %>">Sign out</a><% } %>
      </nav>
      <a class="login-btn" href="<%: DashboardHref %>"><%: IsSignedIn ? "My Dashboard ↗" : "Login ↗" %></a><button type="button" aria-controls="navlinks" aria-expanded="false"
        aria-label="Open menu" class="menu-toggle" id="menuToggle">☰</button>
    </div>
  </header>
  
    <section class="hero" id="home">
      <div class="container hero-content">
        <% if (IsSignedIn) { %><p class="home-welcome">Welcome back, <%: SignedInName %></p><% } %>
        <h1>Internship Management System<br />at the University of Jordan</h1>
        <p>Connecting students, companies, and the university in one platform to discover internships, manage tasks,
          track evaluations and training hours, and complete the internship approval process.</p>
        <div class="actions"><a class="btn btn-white" href="#opportunities">Browse Internships →</a><a
            class="btn btn-outline" href="#about">Learn More ▶</a></div>
      </div>
    </section>
    <section class="section opportunities" id="opportunities">
      <div class="container">
        <div class="heading"><span class="eyebrow">YOUR NEXT OPPORTUNITY</span>
          <h2>Latest Internship Opportunities</h2>
          <p>Explore current internship opportunities published by participating companies.</p>
        </div>
        <div class="opportunity-toolbar">
          <p>Explore opportunities from participating companies and organizations.</p><input
            aria-label="Search internships" class="search" id="searchInput"
            placeholder="Search company, major, or technology..." type="search" />
        </div>
        <div class="internship-carousel" role="region" aria-roledescription="carousel"
          aria-label="Internship opportunities">
          <div class="carousel-controls"><span class="carousel-count" id="carouselCount" role="status"
              aria-live="polite"></span><button class="carousel-arrow" id="previousJobs" type="button"
              aria-label="Previous internships" aria-controls="jobGrid" disabled><svg viewBox="0 0 24 24"
                aria-hidden="true">
                <path d="m14 6-6 6 6 6" />
              </svg></button><button class="carousel-arrow" id="nextJobs" type="button" aria-label="Next internships"
              aria-controls="jobGrid" disabled><svg viewBox="0 0 24 24" aria-hidden="true">
                <path d="m10 6 6 6-6 6" />
              </svg></button></div>
          <div class="grid" id="jobGrid" tabindex="0"
            aria-label="Internship cards. Use left and right arrow keys to browse."></div>
        </div>
        <p class="load-status" id="loadStatus"></p>
      </div>
    </section>
    <section class="section training-guide" id="training-guide" aria-labelledby="trainingHeading">
      <div class="container">
        <div class="heading"><span class="eyebrow">YOUR INTERNSHIP, STEP BY STEP</span>
          <h2 id="trainingHeading">How Does Your Internship Work?</h2>
          <p>A simple guide from finding your opportunity to completing your training.</p>
        </div>
        <div class="training-layout">
          <div class="training-media" id="trainingMedia">
            <div class="training-poster"><span class="video-symbol" aria-hidden="true">&#9654;</span><span
                class="video-label">Internship walkthrough</span>
              <h3>Your journey starts here.</h3>
              <p id="trainingVideoStatus">The video guide will be available soon. Explore the steps alongside to get
                started.</p>
            </div>
          </div>
          <div>
            <ol class="training-steps">
              <li>
                <div>
                  <h3>Find your opportunity &amp; apply</h3>
                  <p>Log in with your student account, explore internships that match your major, and submit your
                    application.</p>
                </div>
              </li>
              <li>
                <div>
                  <h3>Train, submit &amp; track</h3>
                  <p>Once accepted, follow your supervisor's tasks, submit your work, and track your feedback and
                    training hours.</p>
                </div>
              </li>
              <li>
                <div>
                  <h3>Complete your internship</h3>
                  <p>After your evaluations and requirements are reviewed and approved by the university coordinator,
                    download your completion report.</p>
                </div>
              </li>
            </ol><a class="training-link" href="#opportunities">Explore internship opportunities <span
                aria-hidden="true">&#8594;</span></a>
          </div>
        </div>
      </div>
    </section>
    <section class="section about" id="about">
      <div class="container about-layout">
        <div class="about-text"><span class="eyebrow">ABOUT THE SYSTEM</span>
          <h2>About the System &amp; the University</h2>
          <p>The University of Jordan Internship Management System brings students, academic supervisors, host
            companies, and university coordinators together in one convenient platform.</p>
          <p>Students can explore and apply for internships, submit assigned tasks, monitor evaluations and approved
            training hours, and obtain their official completion report once approved by the coordinator.</p>
          <div class="benefits">
            <div class="benefit"><span class="check">✓</span> Find internships that match your specialization</div>
            <div class="benefit"><span class="check">✓</span> Track tasks, performance, and feedback</div>
            <div class="benefit"><span class="check">✓</span> Record training hours and completion approvals</div>
          </div>
        </div>
        <div aria-label="University campus background" class="about-visual" role="img"><span>Your Future Starts Here
            ↗</span></div>
      </div>
    </section>
    <section class="section faq" id="faq">
      <div class="container">
        <div class="heading"><span class="eyebrow">FREQUENTLY ASKED QUESTIONS</span>
          <h2>FAQ</h2>
          <p>Answers to common questions about university internships.</p>
        </div>
        <div class="faq-list">
          <div class="faq-item open"><button aria-expanded="true" type="button">How can I apply for an internship? <span
                class="faq-icon">+</span></button>
            <div class="faq-answer">Log in with your student account, browse the opportunities available for your major,
              choose one, and click Apply.</div>
          </div>
          <div class="faq-item"><button aria-expanded="false" type="button">Can I apply for multiple internships? <span
                class="faq-icon">+</span></button>
            <div class="faq-answer">You may apply to multiple opportunities, but you can only confirm one internship
              offer at a time.</div>
          </div>
          <div class="faq-item"><button aria-expanded="false" type="button">How do I track my application? <span
                class="faq-icon">+</span></button>
            <div class="faq-answer">Open My Applications from your student dashboard to see whether your application is
              pending, accepted, or rejected.</div>
          </div>
          <div class="faq-item"><button aria-expanded="false" type="button">How are tasks and training hours tracked?
              <span class="faq-icon">+</span></button>
            <div class="faq-answer">Your company supervisor assigns tasks with deadlines. You can submit your work and
              review feedback. Training hours follow the university approval process and are not approved automatically
              when a task is completed.</div>
          </div>
          <div class="faq-item"><button aria-expanded="false" type="button">When can I download my completion report?
              <span class="faq-icon">+</span></button>
            <div class="faq-answer">After the university coordinator reviews the evaluations and requirements and
              approves completion, the report becomes available for download and printing.</div>
          </div>
        </div>
      </div>
    </section>
  
  <footer class="footer">
    <div class="container">
      <div class="footer-grid">
        <div>
          <h3>The University of Jordan</h3>
          <p>Internship Management System<br />University Internship Management System</p>
          <p>Bridging academic learning with real-world experience.</p>
        </div>
        <div>
          <h3>Quick Links</h3>
          <div class="footer-links"><a href="#home">Home</a><a href="#opportunities">Internships</a><a
              href="#about">About</a><a href="#faq">FAQ</a></div>
        </div>
        <div>
          <h3>Support &amp; Contact</h3>
          <div class="footer-links"><a href="Contact.aspx">Contact Us</a><a href="<%: DashboardHref %>"><%: IsSignedIn ? "My Dashboard" : "Login" %></a><a
              href="https://www.ju.edu.jo/" rel="noopener noreferrer" target="_blank">Official University Website ↗</a>
          </div>
        </div>
        <div>
          <h3>Project Partner</h3><a class="partner" href="https://www.ju.edu.jo/" id="partnerLink"
            rel="noopener noreferrer" target="_blank"><img alt="Partner organization logo" class="partner-badge"
              id="partnerImage" onerror="this.style.display='none';this.nextElementSibling.style.display='grid'"
              src="https://www.ju.edu.jo/" /><span
              style="display:none;width:64px;height:64px;background:#fff;border-radius:9px;color:#07523e;place-items:center;font-weight:900">LOGO</span><span><span
                class="powered">Powered by</span><br /><span class="partner-name" id="partnerName">Partner
                Organization</span></span></a>
          <p class="demo-note">Replace this with the actual partner’s website and logo.</p>
        </div>
        <div class="footer-location">
          <h3>Our Location</h3>
          <div class="footer-map"><iframe title="University of Jordan location on Google Maps"
              src="https://maps.google.com/maps?q=University%20of%20Jordan%2C%20Amman&amp;z=15&amp;output=embed"
              loading="lazy" referrerpolicy="no-referrer-when-downgrade" allowfullscreen></iframe></div><a
            href="https://www.google.com/maps/search/?api=1&amp;query=University%20of%20Jordan%2C%20Amman"
            target="_blank" rel="noopener noreferrer">Open in Google Maps &#8599;</a>
        </div>
      </div>
      <div class="copyright">© <span id="year"></span> Internship Management System — a student prototype, not an
        official University of Jordan website.</div>
    </div>
  </footer>
  <div class="toast" id="toast" role="status"></div>
  </div>
  <script type="application/json" id="home-data"><%= PublicDataJson %></script>
  <script src="<%= ResolveUrl("~/Assets/PublicHome/Home.js") %>"></script>
</asp:Content>
