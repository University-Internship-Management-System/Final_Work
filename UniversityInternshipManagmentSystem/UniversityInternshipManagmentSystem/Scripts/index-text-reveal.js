(() => {
    'use strict';
    const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
    if (reducedMotion.matches || !('IntersectionObserver' in window)) return;

    const headings = document.querySelectorAll('.uims-hero-title, .uims-section-title, .uims-identity-heading, #student-guide-title');
    const observer = new IntersectionObserver(entries => {
        entries.forEach(entry => {
            if (!entry.isIntersecting) return;
            entry.target.classList.add('uims-text-visible');
            observer.unobserve(entry.target);
        });
    }, { threshold: 0.12, rootMargin: '0px 0px -6% 0px' });

    headings.forEach(heading => {
        if (heading.classList.contains('uims-word-reveal')) return;
        // Wrap text nodes only: retain colored spans, line breaks and whitespace.
        const walker = document.createTreeWalker(heading, NodeFilter.SHOW_TEXT);
        const nodes = [];
        while (walker.nextNode()) nodes.push(walker.currentNode);
        let index = 0;
        heading.setAttribute('aria-label', heading.textContent.replace(/\s+/g, ' ').trim());
        nodes.forEach(node => {
            const fragment = document.createDocumentFragment();
            node.textContent.split(/(\s+)/).filter(Boolean).forEach(token => {
                if (/^\s+$/.test(token)) {
                    fragment.append(document.createTextNode(token));
                    return;
                }
                const mask = document.createElement('span');
                mask.className = 'uims-word-mask';
                mask.setAttribute('aria-hidden', 'true');
                const word = document.createElement('span');
                word.className = 'uims-word-inner';
                word.textContent = token;
                word.style.setProperty('--word-delay', `${Math.min(index++ * 70, 840)}ms`);
                mask.append(word);
                fragment.append(mask);
            });
            node.replaceWith(fragment);
        });
        heading.classList.add('uims-word-reveal');
        observer.observe(heading);
    });

    document.querySelectorAll('.uims-section-subtitle, .uims-identity-statement').forEach(text => {
        text.classList.add('uims-copy-reveal');
        observer.observe(text);
    });
    // If the user enables reduced motion while the page is open, reveal all text.
    reducedMotion.addEventListener('change', event => {
        if (!event.matches) return;
        observer.disconnect();
        document.querySelectorAll('.uims-word-reveal, .uims-copy-reveal').forEach(element => element.classList.add('uims-text-visible'));
    });
})();
