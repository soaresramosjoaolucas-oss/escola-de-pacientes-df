// Alterna entre tema claro e escuro e memoriza a escolha em localStorage.
// A aplicação inicial do tema salvo (para evitar flash) roda inline no <head>
// de cada página; este arquivo só cuida do botão no header.
(function () {
  var btn = document.getElementById('theme-toggle');
  if (!btn) return;
  var icon = btn.querySelector('.msym');

  function isDark() {
    var attr = document.documentElement.getAttribute('data-theme');
    if (attr === 'dark') return true;
    if (attr === 'light') return false;
    return !!(window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches);
  }

  function syncIcon() {
    if (icon) icon.textContent = isDark() ? 'light_mode' : 'dark_mode';
  }

  syncIcon();

  btn.addEventListener('click', function () {
    var next = isDark() ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    try { localStorage.setItem('tema', next); } catch (e) {}
    syncIcon();
  });
})();
