// Sumário lateral "Nesta página" — aparece em telas largas nas páginas de
// conteúdo com várias seções (h2/h3). Acompanha a rolagem e destaca a atual.
(function () {
  var article = document.querySelector('article.content');
  if (!article) return;
  var container = article.querySelector('.wrap-narrow') || article.querySelector('.wrap');
  if (!container) return;

  // coleta títulos de seção (h2 e h3 diretos do conteúdo)
  var heads = Array.prototype.filter.call(
    container.querySelectorAll('h2, h3'),
    function (h) { return h.textContent.trim().length > 1; }
  );
  if (heads.length < 4) return;               // só vale a pena com muitas seções

  var slugify = function (s) {
    return s.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')
      .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 60);
  };
  var used = {};
  heads.forEach(function (h) {
    if (!h.id) {
      var base = slugify(h.textContent) || 'sec';
      var id = base, i = 2;
      while (used[id] || document.getElementById(id)) { id = base + '-' + i++; }
      h.id = id;
    }
    used[h.id] = true;
  });

  var nav = document.createElement('nav');
  nav.className = 'toc';
  nav.setAttribute('aria-label', 'Nesta página');
  var html = '<p class="toc-title">Nesta página</p><ul>';
  heads.forEach(function (h) {
    var lvl = h.tagName === 'H3' ? ' class="toc-sub"' : '';
    html += '<li' + lvl + '><a href="#' + h.id + '">' + h.textContent + '</a></li>';
  });
  nav.innerHTML = html + '</ul>';
  container.appendChild(nav);

  var links = Array.prototype.slice.call(nav.querySelectorAll('a'));
  var byId = {};
  links.forEach(function (a) { byId[a.getAttribute('href').slice(1)] = a; });

  // marca como ativa a última seção cujo topo já passou por ~120px do topo
  var raf = 0;
  function updateActive() {
    raf = 0;
    var mark = 130, cur = heads[0];
    for (var i = 0; i < heads.length; i++) {
      if (heads[i].getBoundingClientRect().top <= mark) cur = heads[i]; else break;
    }
    var a = cur && byId[cur.id];
    if (a && !a.classList.contains('active')) {
      links.forEach(function (x) { x.classList.remove('active'); });
      a.classList.add('active');
    }
  }
  function onScroll() { if (!raf) raf = requestAnimationFrame(updateActive); }
  window.addEventListener('scroll', onScroll, { passive: true });
  window.addEventListener('resize', onScroll, { passive: true });
  updateActive();

  // rolagem suave ao clicar
  links.forEach(function (a) {
    a.addEventListener('click', function (ev) {
      var t = document.getElementById(a.getAttribute('href').slice(1));
      if (t) { ev.preventDefault(); t.scrollIntoView({ behavior: 'smooth', block: 'start' });
        history.replaceState(null, '', a.getAttribute('href')); }
    });
  });
})();
