// Animação sutil de entrada ao rolar (estilo Apple/Notion)
// Com rede de segurança: nenhum elemento permanece invisível se o
// IntersectionObserver não disparar (aba oculta, pré-render etc.).
(function () {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  if (!('IntersectionObserver' in window)) return;

  var sel = [
    '.section .card', '.section .portal', '.stats .stat', '.media-card',
    '.paper-card', '.book-card', '.award', '.section .kicker',
    '.section .section-title', '.section .section-lead', '.rx-mock',
    '.timeline li', '.seal', '.archive-band', '.quote'
  ].join(',');

  var els = Array.prototype.slice.call(document.querySelectorAll(sel));
  els.forEach(function (el, i) {
    el.classList.add('reveal');
    el.style.transitionDelay = Math.min((i % 6) * 60, 300) + 'ms';
  });

  function show(el) { el.classList.add('in'); }

  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) { show(entry.target); io.unobserve(entry.target); }
    });
  }, { threshold: 0.12, rootMargin: '0px 0px -5% 0px' });

  els.forEach(function (el) { io.observe(el); });

  // Rede de segurança: revela qualquer elemento visível que o IO não pegou
  function sweep() {
    els.forEach(function (el) {
      if (el.classList.contains('in')) return;
      var r = el.getBoundingClientRect();
      if (r.top < window.innerHeight + 40 && r.bottom > -40) show(el);
    });
  }
  window.addEventListener('scroll', sweep, { passive: true });
  window.addEventListener('resize', sweep, { passive: true });
  document.addEventListener('visibilitychange', sweep);
  setTimeout(sweep, 400);

  var tentativas = 0;
  var timer = setInterval(function () {
    sweep();
    tentativas++;
    var pendentes = els.some(function (el) { return !el.classList.contains('in'); });
    if (tentativas > 20 || !pendentes) clearInterval(timer);
  }, 1000);
})();
