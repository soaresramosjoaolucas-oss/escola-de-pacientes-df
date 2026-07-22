// Confetes de boas-vindas 🎉 — leves, sem bibliotecas, respeitam
// prefers-reduced-motion e somem sozinhos após a queda.
// Mistura peças coloridas e alguns emojis festivos, em duas ondas.
(function () {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  var cores = ['#1a73e8', '#ea4335', '#fbbc04', '#34a853', '#12818f', '#a142f4', '#ff6d00', '#00c2a8'];
  var emojis = ['🎉', '🎓', '✨', '❤️', '💡', '🔬'];

  function criarOnda(n, comEmoji) {
    var box = document.createElement('div');
    box.className = 'confetti-box';
    box.setAttribute('aria-hidden', 'true');
    for (var i = 0; i < n; i++) {
      var p = document.createElement('span');
      p.className = 'confetti-piece';
      // ~18% das peças são emoji; o resto é papel picado colorido
      var ehEmoji = comEmoji && Math.random() < 0.18;
      if (ehEmoji) {
        p.textContent = emojis[Math.floor(Math.random() * emojis.length)];
        p.style.fontSize = (15 + Math.random() * 14) + 'px';
        p.style.lineHeight = '1';
      } else {
        var w = 6 + Math.random() * 7;
        var h = w * (0.4 + Math.random() * 1.2);
        p.style.width = w + 'px';
        p.style.height = h + 'px';
        p.style.background = cores[i % cores.length];
        p.style.borderRadius = Math.random() < 0.3 ? '50%' : '2px';
      }
      p.style.left = (Math.random() * 100) + 'vw';
      p.style.setProperty('--dur', (2.6 + Math.random() * 2.8) + 's');
      p.style.setProperty('--delay', (Math.random() * 1.1) + 's');
      p.style.setProperty('--sway', ((Math.random() - 0.5) * 240) + 'px');
      p.style.setProperty('--spin', (1 + Math.random() * 3).toFixed(1) + 'turn');
      box.appendChild(p);
    }
    document.body.appendChild(box);
    setTimeout(function () { box.remove(); }, 7000);
  }

  function soltar() {
    criarOnda(170, true);
    // segunda onda, mais discreta, dá um respiro festivo
    setTimeout(function () { criarOnda(70, true); }, 1400);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', soltar);
  } else {
    soltar();
  }
})();
