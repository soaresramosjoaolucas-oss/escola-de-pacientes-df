// Confetes de boas-vindas 🎉 — leves, sem bibliotecas, respeitam
// prefers-reduced-motion e somem sozinhos após a queda.
(function () {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  var cores = ['#1a73e8', '#ea4335', '#fbbc04', '#34a853', '#12818f', '#a142f4'];
  var box = document.createElement('div');
  box.className = 'confetti-box';
  box.setAttribute('aria-hidden', 'true');

  var n = 130;
  for (var i = 0; i < n; i++) {
    var p = document.createElement('span');
    p.className = 'confetti-piece';
    var w = 6 + Math.random() * 7;
    var h = w * (0.4 + Math.random() * 1.2);
    p.style.left = (Math.random() * 100) + 'vw';
    p.style.width = w + 'px';
    p.style.height = h + 'px';
    p.style.background = cores[i % cores.length];
    p.style.borderRadius = Math.random() < 0.3 ? '50%' : '2px';
    p.style.setProperty('--dur', (2.6 + Math.random() * 2.6) + 's');
    p.style.setProperty('--delay', (Math.random() * 0.9) + 's');
    p.style.setProperty('--sway', ((Math.random() - 0.5) * 220) + 'px');
    p.style.setProperty('--spin', (1 + Math.random() * 3).toFixed(1) + 'turn');
    box.appendChild(p);
  }

  function soltar() {
    document.body.appendChild(box);
    setTimeout(function () { box.remove(); }, 6500);
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', soltar);
  } else {
    soltar();
  }
})();
