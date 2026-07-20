// Anima os números de impacto da landing (.stats .stat b) de 0 até o valor
// final quando entram na viewport. Robusto: o valor final SEMPRE aparece,
// mesmo se requestAnimationFrame/IntersectionObserver não dispararem
// (aba em segundo plano, rAF pausado etc.). Respeita prefers-reduced-motion.
(function () {
  var els = Array.prototype.slice.call(document.querySelectorAll('.stats .stat b'));
  if (!els.length) return;

  var reduce = !!(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches);

  function fmt(n) { return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, '.'); }
  function parse(t) {
    return { value: parseInt(t.replace(/\D/g, ''), 10) || 0, suffix: /\+\s*$/.test(t) ? '+' : '' };
  }

  els.forEach(function (el) {
    var p = parse(el.textContent.trim());
    el.__final = fmt(p.value) + p.suffix;   // valor final memorizado
    el.__value = p.value;
    el.__done = false;

    if (reduce || p.value === 0 || document.hidden || !('IntersectionObserver' in window)) {
      el.textContent = el.__final;          // sem animação: já mostra o final
      el.__done = true;
      return;
    }
    el.textContent = '0';
  });

  function finish(el) {
    if (el.__done) return;
    el.__done = true;
    el.textContent = el.__final;
  }

  function run(el) {
    if (el.__done) return;
    if (document.hidden) { finish(el); return; }
    var dur = 1200, t0 = null;
    function step(ts) {
      if (el.__done) return;
      if (t0 === null) t0 = ts;
      var pr = Math.min((ts - t0) / dur, 1);
      var eased = 1 - Math.pow(1 - pr, 3);
      el.textContent = fmt(Math.round(el.__value * eased)) + (/\+/.test(el.__final) ? '+' : '');
      if (pr < 1) requestAnimationFrame(step); else finish(el);
    }
    requestAnimationFrame(step);
    // rede de segurança: se o rAF não avançar, força o valor final
    setTimeout(function () { finish(el); }, dur + 800);
  }

  if ('IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) { run(e.target); io.unobserve(e.target); }
      });
    }, { threshold: 0.25 });
    els.forEach(function (el) { if (!el.__done) io.observe(el); });
  }

  // se a aba volta a ficar visível, garante que tudo terminou
  document.addEventListener('visibilitychange', function () {
    if (!document.hidden) els.forEach(function (el) {
      var r = el.getBoundingClientRect();
      if (!el.__done && r.top < innerHeight && r.bottom > 0) run(el);
    });
  });
  // último recurso: nada pode ficar preso em "0"
  setTimeout(function () { els.forEach(finish); }, 6000);
})();
