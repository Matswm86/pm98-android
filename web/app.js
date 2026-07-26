/* PM98 squad book — pm98.mwmai.no
   Renders the top-20 tables from data/players.json. The data is a straight
   read of the game database ranked on the three fields the instant match
   engine actually consults, priced from the executable's own fee/wage tables. */
(function () {
  'use strict';

  var DATA = null;
  var state = { kind: 'position', band: 'all', role: null, q: '' };

  var out   = document.getElementById('out');
  var roles = document.getElementById('roles');
  var note  = document.getElementById('note');
  var q     = document.getElementById('q');
  var bAll  = document.getElementById('bAll');
  var bU24  = document.getElementById('bU24');

  var money = function (v) {
    if (v == null) return '';
    return '£' + v.toLocaleString('en-GB');
  };
  var esc = function (s) {
    return String(s).replace(/[&<>"]/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
    });
  };

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

  function isGK(g) { return g.pos === 'GK'; }

  function table(g) {
    var list = rows(g);
    var gk = isGK(g);
    var h = '<div class="tablewrap"><table><caption>' + esc(label(g));
    if (g.n) h += ' <span class="capn"> — ' + g.n.toLocaleString('en-GB') + ' in the database</span>';
    h += '</caption>';

    if (!list.length) {
      return h + '</table><p class="empty">Nothing matches that filter.</p></div>';
    }

    h += '<thead><tr><th class="rank"></th><th>Player</th><th>Club</th><th>League</th>' +
         '<th class="num">Age</th><th class="num">STR</th><th class="num">PASS</th>' +
         (gk ? '<th class="num">GKSAVE</th>' : '<th class="num">Score</th>') +
         '<th class="num">Fee</th><th class="num">Wage / yr</th></tr></thead><tbody>';

    list.forEach(function (p, i) {
      h += '<tr>' +
        '<td class="rank num">' + (i + 1) + '</td>' +
        '<td class="nm">' + esc(p.n) + (p.y ? ' <span class="gem">youth</span>' : '') + '</td>' +
        '<td class="club">' + esc(p.c) + '</td>' +
        '<td class="club">' + esc(p.l) + '</td>' +
        '<td class="num">' + (p.a ? p.a : '–') + '</td>' +
        '<td class="num">' + p.s + '</td>' +
        '<td class="num">' + p.pa + '</td>' +
        '<td class="num sc">' + (gk ? p.sc : Number(p.sc).toFixed(1)) + '</td>' +
        '<td class="num fee">' + money(p.f) + '</td>' +
        '<td class="num">' + money(p.w) + '</td>' +
        '</tr>';
    });
    return h + '</tbody></table></div>';
  }

  function drawRoles() {
    var gs = groupsOfKind(state.kind);
    if (state.kind === 'position') { roles.innerHTML = ''; return; }
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

  /* ------------------------------------------------------------- events */
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

  /* --------------------------------------------------------------- load */
  fetch('data/players.json')
    .then(function (r) {
      if (!r.ok) throw new Error('HTTP ' + r.status);
      return r.json();
    })
    .then(function (d) {
      DATA = d;
      draw();
    })
    .catch(function () {
      out.innerHTML = '<p class="note">The player database could not be loaded. ' +
        'The rest of the page does not need it.</p>';
    });
})();

/* ------------------------------------------------------------------ APK link
   CI uploads one pm98-<commit>.apk per build to the `latest` release, so any
   filename baked into this page is stale the moment the next commit lands.
   Resolve the newest asset at load and repoint the button. The baked-in link
   stays as the fallback: if the API is unreachable or rate-limited (it is
   unauthenticated, 60/hr per IP), the page is exactly as it shipped. */
(function () {
  'use strict';
  var btn = document.getElementById('dlbtn');
  var meta = document.getElementById('dlmeta');
  if (!btn || !window.fetch) return;

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
      if (a.browser_download_url) btn.href = a.browser_download_url;
      if (!meta) return;
      var mb = (a.size / 1e6).toFixed(1);
      var commit = a.name.replace(/^pm98-|\.apk$/g, '');
      var when = new Date(a.updated_at).toLocaleDateString('en-GB',
        { day: 'numeric', month: 'short', year: 'numeric' });
      meta.textContent = 'file  ' + a.name + ' · ' + mb + ' MB · build ' + commit +
        ' · uploaded ' + when;
    })
    .catch(function () { /* keep the baked-in link */ });
})();
