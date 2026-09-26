(function () {
  const menuButton = document.querySelector('.menu-toggle');
  const nav = document.querySelector('#site-nav');

  if (menuButton && nav) {
    menuButton.addEventListener('click', function () {
      const open = nav.classList.toggle('open');
      menuButton.setAttribute('aria-expanded', String(open));
    });

    nav.querySelectorAll('a').forEach(function (link) {
      link.addEventListener('click', function () {
        nav.classList.remove('open');
        menuButton.setAttribute('aria-expanded', 'false');
      });
    });
  }

  // Content is visible by default. Animation is progressive enhancement only,
  // so a JS failure can never make the page's text disappear.
  const items = document.querySelectorAll('.reason, .build-card, .ds-grid article, .skills-grid > div, .timeline article, .process-list > div, .tool-grid > div, .check-list li, .leave-grid > div');

  if ('IntersectionObserver' in window && !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    const observer = new IntersectionObserver(function (entries, obs) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.animate(
            [
              { opacity: 0.01, transform: 'translateY(12px)' },
              { opacity: 1, transform: 'translateY(0)' }
            ],
            { duration: 500, easing: 'cubic-bezier(.22,1,.36,1)', fill: 'both' }
          );
          obs.unobserve(entry.target);
        }
      });
    }, { threshold: 0.08, rootMargin: '0px 0px -30px 0px' });

    items.forEach(function (item) { observer.observe(item); });
  }
})();
