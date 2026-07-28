/* PM98 — pm98.mwmai.no
   Three jobs, in this order:
     1. the screen router. The site is the game's own shell: a front door, the
        MANAGER MENU hub, and the screens you reach off it. State lives in the
        URL hash, so every screen is still linkable and the back button works.
     2. the squad book. Renders the top-20 tables from data/players.json — a
        straight read of the game database ranked on the three fields the
        instant match engine actually consults, priced from the executable's
        own fee/wage tables.
     3. the APK link. CI uploads one pm98-<commit>.apk per build to the `latest`
        release, so any filename baked into the page is stale the moment the
        next commit lands.

   Served under a strict CSP with no 'unsafe-inline' in style-src, so nothing
   here may emit a style="..." attribute. Add a class to style.css instead. */
(function () {
  'use strict';

  /* =====================================================================
     1. ROUTER
     ===================================================================== */

  /* the screens that live inside the content shell */
  var SCREENS = ['start', 'download', 'build', 'beat', 'money', 'book', 'sources'];

  var splash  = document.getElementById('splash');
  var menu    = document.getElementById('menu');
  var content = document.getElementById('content');
  var navBtns = document.querySelectorAll('.topbar nav button[data-go]');

  function screenEl(name) { return document.getElementById('scr-' + name); }

  function show(name) {
    var inContent = SCREENS.indexOf(name) >= 0;

    splash.hidden  = name !== 'splash';
    menu.hidden    = name !== 'menu';
    content.hidden = !inContent;

    SCREENS.forEach(function (s) {
      var el = screenEl(s);
      if (el) el.hidden = s !== name;
    });

    for (var i = 0; i < navBtns.length; i++) {
      navBtns[i].setAttribute('aria-current',
        navBtns[i].dataset.go === name ? 'true' : 'false');
    }

    document.body.className = 'on-' + name;
    if (name === 'book') book.draw();
  }

  function known(name) {
    return name === 'splash' || name === 'menu' || SCREENS.indexOf(name) >= 0;
  }

  /* deep links that pointed into the old one-page layout */
  var ALIAS = { hack: 'beat' };

  function fromHash() {
    var h = (location.hash || '').replace('#', '');
    if (known(h)) return h;
    if (ALIAS[h]) return ALIAS[h];
    return 'splash';
  }

  /* an aliased hash names an element inside the screen it resolves to */
  function scrollToAnchor() {
    var h = (location.hash || '').replace('#', '');
    if (!h || known(h)) return;
    var el = document.getElementById(h);
    if (el) el.scrollIntoView();
  }

  function go(name) {
    if (!known(name)) return;
    show(name);
    try {
      if (name === 'splash') history.replaceState(null, '', location.pathname);
      else history.pushState(null, '', '#' + name);
    } catch (e) { location.hash = name === 'splash' ? '' : name; }
    window.scrollTo(0, 0);
  }

  document.addEventListener('click', function (e) {
    var t = e.target.closest('[data-go]');
    if (!t) return;
    e.preventDefault();
    go(t.dataset.go);
  });

  window.addEventListener('hashchange', function () { show(fromHash()); scrollToAnchor(); });
  window.addEventListener('popstate', function () { show(fromHash()); });

  /* =====================================================================
     2. SQUAD BOOK
     ===================================================================== */
  var book = (function () {
    var DATA = null;
    var state = { kind: 'position', band: 'all', role: null, q: '' };

    var out   = document.getElementById('out');
    var roles = document.getElementById('roles');
    var note  = document.getElementById('note');
    var q     = document.getElementById('q');
    var bAll  = document.getElementById('bAll');
    var bU24  = document.getElementById('bU24');

    function money(v) {
      if (v == null) return '';
      return '£' + v.toLocaleString('en-GB');
    }
    function esc(s) {
      return String(s).replace(/[&<>"]/g, function (c) {
        return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
      });
    }

    function groupsOfKind(kind) {
      return DATA.groups.filter(function (g) { return g.kind === kind; });
    }

    function label(g) {
      if (g.kind === 'position') {
        return { GK: 'Goalkeepers', DF: 'Defenders', MF: 'Midfielders', FW: 'Forwards' }[g.pos] || g.pos;
      }
      if (g.kind === 'role') return (g.name || g.key) + ' · ' + g.pos;
      return g.name || g.key;
    }

    function rows(g) {
      var list = (state.band === 'u24' ? g.u24 : g.all) || [];
      if (!state.q) return list;
      var t = state.q.toLowerCase();
      return list.filter(function (p) {
        return (p.n + ' ' + p.c + ' ' + p.l).toLowerCase().indexOf(t) >= 0;
      });
    }

    function table(g) {
      var list = rows(g);
      var gk = g.pos === 'GK';

      var h = '<div class="tbl-plate"><div class="tbl-cap"><b>' + esc(label(g)) + '</b>';
      if (g.n) h += '<span>' + g.n.toLocaleString('en-GB') + ' in the database</span>';
      h += '</div>';

      if (!list.length) return h + '<p class="empty">Nothing matches that filter.</p></div>';

      h += '<div class="tablewrap"><table><thead><tr>' +
           '<th class="num">#</th><th>Player</th><th>Club</th><th>League</th>' +
           '<th class="num">Age</th><th class="num">STR</th><th class="num">Pass</th>' +
           (gk ? '<th class="num">GKSAVE</th>' : '<th class="num">Score</th>') +
           '<th class="num">Fee</th><th class="num">Wage / yr</th>' +
           '</tr></thead><tbody>';

      list.forEach(function (p, i) {
        h += '<tr>' +
          '<td class="num rank">' + (i + 1) + '</td>' +
          '<td class="nm">' + esc(p.n) + (p.y ? '<span class="gem">youth</span>' : '') + '</td>' +
          '<td class="club">' + esc(p.c) + '</td>' +
          '<td class="league">' + esc(p.l) + '</td>' +
          '<td class="num">' + (p.a ? p.a : '–') + '</td>' +
          '<td class="num">' + p.s + '</td>' +
          '<td class="num">' + p.pa + '</td>' +
          '<td class="num sc">' + (gk ? p.sc : Number(p.sc).toFixed(1)) + '</td>' +
          '<td class="num fee">' + money(p.f) + '</td>' +
          '<td class="num">' + money(p.w) + '</td>' +
          '</tr>';
      });
      return h + '</tbody></table></div></div>';
    }

    function drawRoles() {
      if (state.kind === 'position') { roles.innerHTML = ''; return; }
      var gs = groupsOfKind(state.kind);
      roles.innerHTML = gs.map(function (g) {
        var on = state.role === g.key || (state.role === null && g === gs[0]);
        return '<button data-key="' + esc(g.key) + '" aria-pressed="' + (on ? 'true' : 'false') + '">' +
          esc(g.name || g.key) + ' <span class="n">' + g.n + '</span></button>';
      }).join('');
    }

    function draw() {
      if (!DATA) return;
      var gs = groupsOfKind(state.kind);
      if (!gs.length) { out.innerHTML = ''; return; }

      drawRoles();

      if (state.kind === 'position') {
        note.textContent = 'Every rated player in the database, split by broad position. ' +
          'Outfielders rank on (STR + PASS) / 2; keepers rank on GKSAVE.';
        out.innerHTML = gs.map(table).join('');
        return;
      }

      var g = gs.filter(function (x) { return x.key === state.role; })[0] || gs[0];
      note.textContent = g.note || '';
      out.innerHTML = table(g);
    }

    /* --------------------------------------------------------- events */
    document.querySelectorAll('.seg [data-kind]').forEach(function (b) {
      b.addEventListener('click', function () {
        state.kind = b.dataset.kind;
        state.role = null;
        document.querySelectorAll('.seg [data-kind]').forEach(function (o) {
          o.setAttribute('aria-pressed', String(o === b));
        });
        draw();
      });
    });

    bAll.addEventListener('click', function () {
      state.band = 'all';
      bAll.setAttribute('aria-pressed', 'true');
      bU24.setAttribute('aria-pressed', 'false');
      draw();
    });
    bU24.addEventListener('click', function () {
      state.band = 'u24';
      bU24.setAttribute('aria-pressed', 'true');
      bAll.setAttribute('aria-pressed', 'false');
      draw();
    });

    roles.addEventListener('click', function (e) {
      var b = e.target.closest('button');
      if (!b) return;
      state.role = b.dataset.key;
      draw();
    });

    var t;
    q.addEventListener('input', function () {
      clearTimeout(t);
      t = setTimeout(function () { state.q = q.value.trim(); draw(); }, 130);
    });

    /* ----------------------------------------------------------- load */
    fetch('data/players.json')
      .then(function (r) {
        if (!r.ok) throw new Error('HTTP ' + r.status);
        return r.json();
      })
      .then(function (d) { DATA = d; draw(); })
      .catch(function () {
        out.innerHTML = '<p class="note">The player database could not be loaded. ' +
          'The rest of the site does not need it.</p>';
      });

    return { draw: draw };
  })();

  /* =====================================================================
     3. APK LINK
     The link baked into index.html by deploy.sh stays as the fallback: if
     the API is unreachable or rate-limited (unauthenticated, 60/hr per IP),
     the page is exactly as it shipped.
     ===================================================================== */
  (function () {
    var btn = document.getElementById('dlbtn');
    if (!btn || !window.fetch) return;

    function setAll(ids, text) {
      ids.forEach(function (id) {
        var el = document.getElementById(id);
        if (el) el.textContent = text;
      });
    }

    fetch('https://api.github.com/repos/Matswm86/pm98-android/releases/tags/latest', {
      headers: { Accept: 'application/vnd.github+json' }
    })
      .then(function (r) { if (!r.ok) throw 0; return r.json(); })
      .then(function (rel) {
        var apks = (rel.assets || []).filter(function (a) {
          return /^pm98-[0-9a-f]{7,40}\.apk$/.test(a.name);
        });
        if (!apks.length) return;
        apks.sort(function (a, b) { return a.updated_at < b.updated_at ? 1 : -1; });

        var a = apks[0];
        var mb = (a.size / 1e6).toFixed(1);
        var commit = a.name.replace(/^pm98-|\.apk$/g, '');
        var when = new Date(a.updated_at).toLocaleDateString('en-GB',
          { day: 'numeric', month: 'short', year: 'numeric' });

        if (a.browser_download_url) btn.href = a.browser_download_url;
        setAll(['dlmeta'],
          'file  ' + a.name + ' · ' + mb + ' MB · build ' + commit + ' · uploaded ' + when);
        setAll(['buildline-hub', 'buildline-badge'], a.name + ' · ' + mb + ' MB');
        setAll(['builddate-hub'], when);
      })
      .catch(function () { /* keep the baked-in link */ });
  })();

  /* ------------------------------------------------------------- start up */
  show(fromHash());
  scrollToAnchor();
})();
