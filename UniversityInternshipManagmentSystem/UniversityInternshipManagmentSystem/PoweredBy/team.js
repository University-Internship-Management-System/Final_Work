// Portraits supplied by the team. Yaqeen's portrait remains a placeholder.
const team = [
  { name: 'Abdallah Mdalal', role: 'Developer', linkedin: 'https://www.linkedin.com/in/abdallah-mdalal', github: 'https://github.com/abd3348', portfolio: 'https://abd3348.github.io/Portfolio/' },
  { name: 'Marwa Albadarneh', role: 'Scrum Master', linkedin: 'https://www.linkedin.com/in/marwa-albadarneh', github: 'https://github.com/MarwaM5', portfolio: 'https://marwam5.github.io/My-Portfolio/' },
  { name: 'Yaqeen Jawabreh', role: 'Developer', linkedin: 'https://www.linkedin.com/in/yaqeenjawabreh/', github: 'https://github.com/yaqeenjawabreh' },
  { name: 'Lujain Okour', role: 'QA', linkedin: 'https://www.linkedin.com/in/lujain-okour-06903b313/', github: 'https://github.com/lujainokour' },
  { name: 'Wadea', role: 'Developer', linkedin: 'https://www.linkedin.com/in/wadea-yh-2188b6278/', github: 'https://github.com/WadeaYH', portfolio: 'https://wadeayh.github.io/WadeaPortfolio/' },
  { name: 'Omar Alsmadi', role: 'Developer', linkedin: 'https://www.linkedin.com/in/omarkamalalsmadi/', github: 'https://github.com/omarsk2003' },
  { name: "Ala'a Frihat", role: 'Product Owner', linkedin: 'https://www.linkedin.com/in/ala-a-frihat-8149a53b3', github: 'https://github.com/AlaaFrihat', portfolio: 'https://alaafrihat.github.io/project/' }
].map((person, index) => ({ ...person, photo: ['images/abdallah.jpg', 'images/marwa.jpg', 'images/portrait-placeholder.svg', 'images/lujain.png', 'images/wadea.jpg', 'images/omar.jpg', 'images/alaa.jpg'][index], bio: person.role, skills: [] }));
const teamGrid=document.getElementById('team-grid');
team.forEach((person,i)=>{const card=document.createElement('article');card.className='member';card.dataset.bio=person.bio;card.dataset.skills=person.skills.join(',');const portrait=document.createElement('div');portrait.className='member-image';portrait.setAttribute('role','button');portrait.setAttribute('aria-label','Explore '+person.name);portrait.setAttribute('aria-expanded','false');const img=document.createElement('img');img.src=person.photo;img.alt=person.name;img.loading=i>2?'lazy':'eager';const number=document.createElement('span');number.className='member-index';number.textContent=String(i+1).padStart(2,'0');number.setAttribute('aria-hidden','true');const wait=document.createElement('span');wait.className='portrait-wait';wait.textContent='PORTRAIT COMING SOON';portrait.append(img,number,wait);const info=document.createElement('div');info.className='member-info';const name=document.createElement('h3');name.textContent=person.name;const role=document.createElement('p');role.textContent=person.role;info.append(name,role);card.append(portrait,info);teamGrid.append(card);});
teamGrid.querySelectorAll('.member').forEach((card, index) => {
    if (index !== 2) card.querySelector('.portrait-wait').remove();
});
(() => {
    const root = document.documentElement;
    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const finePointer = window.matchMedia('(hover: hover) and (pointer: fine)').matches;
    const touchMode = window.matchMedia('(hover: none)').matches;
    const SVG_NS = 'http://www.w3.org/2000/svg';
    const XLINK_NS = 'http://www.w3.org/1999/xlink';
    const BUTTON_SELECTOR = '.main-button, [data-fx-button]';

    const clamp = (value, min, max) => Math.min(Math.max(value, min), max);
    const $ = (selector, scope = document) => scope.querySelector(selector);
    const $$ = (selector, scope = document) => [...scope.querySelectorAll(selector)];

    const create = (tag, className, text) => {
        const node = document.createElement(tag);
        if (className) node.className = className;
        if (text) node.textContent = text;
        return node;
    };

    const splitWords = (heading) => {
        const nodes = [...heading.childNodes];
        let index = 0;
        heading.setAttribute('aria-label', heading.textContent.replace(/\s+/g, ' ').trim());
        heading.textContent = '';
        heading.dataset.split = '';

        nodes.forEach((node) => {
            const isElement = node.nodeType === 1;
            const holder = isElement ? node.cloneNode(false) : heading;
            const words = node.textContent.trim().split(/\s+/).filter(Boolean);

            words.forEach((word) => {
                const mask = create('span', 'word');
                const inner = create('span', 'word-inner', word);
                inner.style.setProperty('--i', index++);
                mask.setAttribute('aria-hidden', 'true');
                mask.append(inner);
                holder.append(mask, document.createTextNode(' '));
            });

            if (isElement) heading.append(holder);
        });
    };

    const setupReveal = () => {
        const heroSequence = [
            ['.hero .eyebrow', 100],
            ['.hero-text', 800],
            ['.hero .main-button', 950],
            ['.hero-side', 1050]
        ];

        heroSequence.forEach(([selector, delay]) => {
            const element = $(selector);
            if (!element) return;
            element.dataset.reveal = '';
            element.style.setProperty('--d', `${delay}ms`);
        });

        [
            '.section-number',
            '.about-text p',
            '.section-top > p',
            '.service',
            '.statement .eyebrow',
            '.member',
            '.cta .eyebrow',
            '.cta .main-button'
        ].forEach((selector) => {
            $$(selector).forEach((element) => {
                element.dataset.reveal = '';
            });
        });

        $$('.hero h1, .about h2, .section-top h2, .statement h2, .cta h2').forEach(splitWords);

        const observer = new IntersectionObserver((entries) => {
            let order = 0;
            entries.forEach((entry) => {
                if (!entry.isIntersecting) return;
                const element = entry.target;
                const hasDelay = element.style.getPropertyValue('--d') !== '';
                if (!hasDelay && !('split' in element.dataset)) {
                    element.style.setProperty('--d', `${order * 90}ms`);
                }
                order++;
                element.classList.add('is-visible');
                observer.unobserve(element);
            });
        }, { threshold: 0.15, rootMargin: '0px 0px -6% 0px' });

        return () => {
            $$('[data-reveal], [data-split]').forEach((element) => observer.observe(element));
        };
    };

    const setupSmoothScroll = () => {
        let current = window.scrollY;
        let target = current;
        let running = false;

        const limit = () => root.scrollHeight - window.innerHeight;

        const tick = () => {
            const diff = target - current;
            if (Math.abs(diff) < 0.4) {
                current = target;
                window.scrollTo(0, current);
                running = false;
                root.style.scrollBehavior = '';
                return;
            }
            current += diff * 0.085;
            window.scrollTo(0, current);
            requestAnimationFrame(tick);
        };

        const start = () => {
            if (running) return;
            running = true;
            root.style.scrollBehavior = 'auto';
            requestAnimationFrame(tick);
        };

        window.addEventListener('wheel', (event) => {
            if (event.ctrlKey) return;
            event.preventDefault();
            const unit = event.deltaMode === 1 ? 32 : event.deltaMode === 2 ? window.innerHeight : 1;
            if (!running) {
                current = window.scrollY;
                target = current;
            }
            target = clamp(target + event.deltaY * unit, 0, limit());
            start();
        }, { passive: false });

        window.addEventListener('scroll', () => {
            if (!running) {
                current = window.scrollY;
                target = current;
            }
        }, { passive: true });

        return (y) => {
            target = clamp(y, 0, limit());
            start();
        };
    };

    const setupAnchors = (scrollToY) => {
        $$('a[href^="#"]').forEach((link) => {
            const id = link.getAttribute('href');
            if (id.length < 2) return;
            const section = $(id);
            if (!section) return;
            link.addEventListener('click', (event) => {
                event.preventDefault();
                scrollToY(section.getBoundingClientRect().top + window.scrollY);
            });
        });
    };

    const setupDimensions = () => {
        $$('.about h2, .section-top h2, .cta h2').forEach((heading, index) => {
            const line = create('div', 'dim');
            line.dataset.reveal = '';
            line.setAttribute('aria-hidden', 'true');
            line.append(create('span', '', `${(2.4 + index * 1.2).toFixed(2)} m`));
            heading.after(line);
        });
    };

    const setupHero = () => {
        const hero = $('.hero');
        if (!hero) return;

        const glow = create('div', 'hero-glow');
        hero.prepend(glow);

        const rect = hero.getBoundingClientRect();
        const state = { x: rect.width * 0.7, y: rect.height * 0.45, tx: rect.width * 0.7, ty: rect.height * 0.45, raf: 0 };

        const render = () => {
            state.x += (state.tx - state.x) * 0.08;
            state.y += (state.ty - state.y) * 0.08;
            glow.style.transform = `translate3d(${state.x - 360}px, ${state.y - 360}px, 0)`;
            if (Math.abs(state.tx - state.x) > 0.5 || Math.abs(state.ty - state.y) > 0.5) {
                state.raf = requestAnimationFrame(render);
            } else {
                state.raf = 0;
            }
        };

        const kick = () => {
            if (!state.raf) state.raf = requestAnimationFrame(render);
        };

        hero.addEventListener('pointermove', (event) => {
            const bounds = hero.getBoundingClientRect();
            state.tx = event.clientX - bounds.left;
            state.ty = event.clientY - bounds.top;
            hero.style.setProperty('--mx', `${state.tx}px`);
            hero.style.setProperty('--my', `${state.ty}px`);
            kick();
        });

        render();
        requestAnimationFrame(() => glow.classList.add('is-active'));
    };

    const setupScrollEffects = () => {
        const hero = $('.hero');
        const content = $('.hero-content');
        const side = $('.hero-side');
        const statement = $('.statement');
        const bar = create('div', 'progress');
        let frame = 0;

        document.body.prepend(bar);

        const update = () => {
            frame = 0;
            const y = window.scrollY;
            const max = Math.max(root.scrollHeight - window.innerHeight, 1);
            bar.style.transform = `scaleX(${clamp(y / max, 0, 1)})`;

            if (statement) {
                const box = statement.getBoundingClientRect();
                const view = window.innerHeight;
                statement.style.setProperty('--lit', clamp((view - box.top) / (view * 0.9), 0, 1).toFixed(3));
            }

            if (!hero || !content || !side) return;
            const height = hero.offsetHeight;
            if (y < height * 1.2) {
                content.style.translate = `0 ${y * 0.18}px`;
                content.style.opacity = clamp(1 - y / (height * 0.8), 0, 1);
                side.style.translate = `0 ${y * 0.08}px`;
            }
        };

        window.addEventListener('scroll', () => {
            if (!frame) frame = requestAnimationFrame(update);
        }, { passive: true });
        window.addEventListener('resize', update);
        update();
    };

    const scramble = (node, text, speed = 1) => {
        cancelAnimationFrame(node.scrambleFrame);
        if (reduceMotion) {
            node.textContent = text;
            return;
        }

        const glyphs = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#%&+';
        const duration = 800 / speed;
        const start = performance.now();

        const step = (now) => {
            const progress = clamp((now - start) / duration, 0, 1);
            let output = '';

            for (let i = 0; i < text.length; i++) {
                const char = text[i];
                const settleAt = (i / text.length) * 0.8 + 0.2;
                if (char === ' ' || progress >= settleAt) {
                    output += char;
                } else {
                    output += glyphs[Math.floor(Math.random() * glyphs.length)];
                }
            }

            node.textContent = output;
            if (progress < 1) node.scrambleFrame = requestAnimationFrame(step);
        };

        node.scrambleFrame = requestAnimationFrame(step);
    };

    const buildRing = (role, id) => {
        const wrap = create('div', 'member-ring');
        const svg = document.createElementNS(SVG_NS, 'svg');
        const path = document.createElementNS(SVG_NS, 'path');
        const line = document.createElementNS(SVG_NS, 'circle');
        const text = document.createElementNS(SVG_NS, 'text');
        const textPath = document.createElementNS(SVG_NS, 'textPath');

        const label = role.toUpperCase();
        const unit = `${label} • `;
        const repeats = Math.max(2, Math.round(60 / unit.length));

        svg.setAttribute('viewBox', '0 0 200 200');
        svg.setAttribute('class', 'ring-svg');
        svg.setAttribute('aria-hidden', 'true');

        path.setAttribute('id', `ring-path-${id}`);
        path.setAttribute('d', 'M 10,100 a 90,90 0 1,1 180,0 a 90,90 0 1,1 -180,0');
        path.setAttribute('fill', 'none');

        line.setAttribute('cx', '100');
        line.setAttribute('cy', '100');
        line.setAttribute('r', '83');
        line.setAttribute('pathLength', '1');
        line.setAttribute('class', 'ring-line');

        text.setAttribute('class', 'ring-text');
        text.setAttribute('textLength', '565');
        text.setAttribute('lengthAdjust', 'spacing');

        textPath.setAttribute('href', `#ring-path-${id}`);
        textPath.setAttributeNS(XLINK_NS, 'xlink:href', `#ring-path-${id}`);
        textPath.textContent = unit.repeat(repeats);

        text.append(textPath);
        svg.append(path, line, text);
        wrap.append(svg);
        return wrap;
    };

    const setupMotion = (box, chips) => {
        const image = $('img', box);
        const s = { x: 0, y: 0, tx: 0, ty: 0, gx: 130, gy: 130, tgx: 130, tgy: 130, raf: 0 };

        const render = () => {
            s.x += (s.tx - s.x) * 0.1;
            s.y += (s.ty - s.y) * 0.1;
            s.gx += (s.tgx - s.gx) * 0.22;
            s.gy += (s.tgy - s.gy) * 0.22;

            box.style.transform = `perspective(900px) rotateX(${-s.y * 9}deg) rotateY(${s.x * 9}deg)`;
            box.style.setProperty('--gx', `${s.gx}px`);
            box.style.setProperty('--gy', `${s.gy}px`);

            if (image) {
                image.style.transform = `translate3d(${-s.x * 12}px, ${-s.y * 12}px, 0) scale(1.1)`;
            }

            chips.forEach(({ inner, depth }) => {
                inner.style.translate = `${s.x * depth}px ${s.y * depth}px`;
            });

            const moving =
                Math.abs(s.tx - s.x) > 0.001 ||
                Math.abs(s.ty - s.y) > 0.001 ||
                Math.abs(s.tgx - s.gx) > 0.3 ||
                Math.abs(s.tgy - s.gy) > 0.3;

            s.raf = moving ? requestAnimationFrame(render) : 0;
        };

        const kick = () => {
            if (!s.raf) s.raf = requestAnimationFrame(render);
        };

        box.addEventListener('pointermove', (event) => {
            if (event.pointerType !== 'mouse') return;
            const rect = box.getBoundingClientRect();
            s.tx = ((event.clientX - rect.left) / rect.width - 0.5) * 2;
            s.ty = ((event.clientY - rect.top) / rect.height - 0.5) * 2;
            s.tgx = event.clientX - rect.left;
            s.tgy = event.clientY - rect.top;
            kick();
        });

        box.addEventListener('pointerleave', () => {
            s.tx = 0;
            s.ty = 0;
            s.tgx = box.offsetWidth / 2;
            s.tgy = box.offsetHeight / 2;
            kick();
        });
    };

    const setupMembers = () => {
        const members = $$('.member');
        let uid = 0;

        members.forEach((member, memberIndex) => {
            const box = $('.member-image', member);
            const roleNode = $('.member-info p', member);
            if (!box || !roleNode) return;

            const role = roleNode.textContent.trim();
            const bio = member.dataset.bio || role;
            const person = team[memberIndex];
            const profiles = [
                { label: 'LinkedIn', url: person.linkedin, icon: 'bi-linkedin' },
                { label: 'GitHub', url: person.github, icon: 'bi-github' },
                { label: 'Portfolio', url: person.portfolio, icon: 'bi-box-arrow-up-right' }
            ];

            const stage = create('div', 'member-stage');
            box.replaceWith(stage);
            stage.append(buildRing(role, uid++), box);
            box.append(create('span', 'member-lens'), create('span', 'member-glare'));

            const angles = [-44, 36, 136];
            const chips = profiles.map((profile, index) => {
                const chip = create('span', 'member-chip');
                const inner = create('a', 'chip-inner');
                if (profile.url) {
                    inner.href = profile.url;
                    inner.target = '_blank';
                    inner.rel = 'noopener noreferrer';
                } else {
                    inner.setAttribute('role', 'link');
                    inner.setAttribute('aria-disabled', 'true');
                    inner.classList.add('portfolio-pending');
                    inner.title = 'Portfolio coming soon';
                }
                inner.tabIndex = -1;
                inner.setAttribute('aria-label', `${person.name} — ${profile.label}${profile.url ? " (opens in new tab)" : " (coming soon)"}`);
                const icon = create('i', `bi ${profile.icon}`);
                icon.setAttribute('aria-hidden', 'true');
                inner.append(icon, document.createTextNode(profile.label));
                chip.style.setProperty('--n', index);
                chip.append(inner);
                stage.append(chip);
                return { chip, inner, depth: 14 + index * 9, angle: (angles[index] * Math.PI) / 180 };
            });

            const placeChips = () => {
                const radius = (90 * (stage.offsetWidth + 68)) / 200 + 6;
                chips.forEach(({ chip, angle }) => {
                    chip.style.setProperty('--x', `${Math.cos(angle) * radius}px`);
                    chip.style.setProperty('--y', `${Math.sin(angle) * radius}px`);
                });
            };

            const open = () => {
                if (member.classList.contains('is-open')) return;
                placeChips();
                member.classList.add('is-open');
                chips.forEach(({ inner }) => { inner.tabIndex = 0; });
                if (bio !== role) scramble(roleNode, bio);
            };

            const close = () => {
                if (!member.classList.contains('is-open')) return;
                member.classList.remove('is-open');
                chips.forEach(({ inner }) => { inner.tabIndex = -1; });
                if (bio !== role) scramble(roleNode, role, 1.6);
            };

            member.closeCard = close; member.openCard = open;
            box.tabIndex = 0;

            let leaveTimer;
            member.addEventListener('pointerenter', (event) => {
                clearTimeout(leaveTimer);
                if (event.pointerType === 'mouse') open();
            });

            member.addEventListener('pointerleave', (event) => {
                if (event.pointerType === 'mouse') leaveTimer = setTimeout(() => {
                    if (!member.contains(document.activeElement)) close();
                }, 180);
            });

            box.addEventListener('focus', () => {
                /* Enter and Space activate the keyboard preview. */
            });

            member.addEventListener('focusout', event => {
                if (!member.contains(event.relatedTarget) && !member.matches(':hover')) close();
            });

            box.addEventListener('click', () => {
                if (!touchMode) return;
                const wasOpen = member.classList.contains('is-open');
                members.forEach((item) => {
                    if (item !== member && item.closeCard) item.closeCard();
                });
                if (wasOpen) close();
                else open();
            });

            if (finePointer && !reduceMotion) setupMotion(box, chips);
        });
    };


    setupMembers();
    $$('.member-image').forEach(box=>{
        const card=box.closest('.member');
        box.addEventListener('keydown',event=>{if(event.key==='Enter'||event.key===' '){event.preventDefault();box.click();if(!touchMode){if(card.classList.contains('is-open')) card.closeCard(); else card.openCard();}box.setAttribute('aria-expanded',String(card.classList.contains('is-open')));}if(event.key==='Escape'){card.closeCard();box.setAttribute('aria-expanded','false');}});
        new MutationObserver(()=>box.setAttribute('aria-expanded',String(card.classList.contains('is-open')))).observe(card,{attributes:true,attributeFilter:['class']});
    });
    if(!reduceMotion && 'IntersectionObserver' in window){
        const start=setupReveal();
        $$('.intro h1').forEach(splitWords);
        root.classList.add('motion');
        start();
    }
    setupScrollEffects();
    root.classList.add('ready');
})();
