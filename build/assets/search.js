// Busca de páginas — filtra o índice gerado (assets/search-index.js)
(function () {
  var input = document.getElementById('busca');
  var panel = document.getElementById('busca-resultados');
  if (!input || !panel || !window.SEARCH_INDEX) return;
  var root = input.getAttribute('data-root') || '';

  function norm(s) {
    return s.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
  }
  var idx = window.SEARCH_INDEX.map(function (e) {
    return { t: e.t, p: e.p, c: e.c, n: norm(e.t) };
  });

  function render(q) {
    var nq = norm(q.trim());
    if (nq.length < 2) { panel.classList.remove('open'); panel.innerHTML = ''; return; }
    var terms = nq.split(/\s+/);
    var hits = [];
    for (var i = 0; i < idx.length && hits.length < 100; i++) {
      var ok = terms.every(function (t) { return idx[i].n.indexOf(t) >= 0; });
      if (ok) hits.push(idx[i]);
    }
    // páginas com título mais curto e correspondência no início vêm primeiro
    hits.sort(function (a, b) {
      var pa = a.n.indexOf(terms[0]), pb = b.n.indexOf(terms[0]);
      if (pa !== pb) return pa - pb;
      return a.n.length - b.n.length;
    });
    hits = hits.slice(0, 12);
    if (!hits.length) {
      panel.innerHTML = '<div class="none">Nenhuma página encontrada.</div>';
    } else {
      panel.innerHTML = hits.map(function (h) {
        return '<a href="' + root + h.p + '/">' + (h.c ? '<small>' + h.c + '</small>' : '') + h.t + '</a>';
      }).join('');
    }
    panel.classList.add('open');
  }

  input.addEventListener('input', function () { render(input.value); });
  input.addEventListener('focus', function () { if (input.value.trim().length >= 2) render(input.value); });
  document.addEventListener('click', function (e) {
    if (!panel.contains(e.target) && e.target !== input) panel.classList.remove('open');
  });
  input.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') { panel.classList.remove('open'); input.blur(); }
    if (e.key === 'Enter') {
      var first = panel.querySelector('a');
      if (first) window.location.href = first.href;
    }
  });
})();
