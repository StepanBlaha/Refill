(function () {
  'use strict';
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var uid = 0;

  // Drip: flat glass tank. Same generator as the app dashboard.
  function drip(m, pct, size) {
    size = size || 56; pct = pct == null ? 100 : pct; if (m === 'party') pct = 100;
    var id = 'dc' + (uid++), L = m === 'asleep' ? 'rgba(255,255,255,.32)' : m === 'sweaty' ? '#FF453A' : m === 'focus' ? '#FF9F0A' : '#30D158';
    var top = 96 - 86 * Math.max(0, Math.min(100, pct)) / 100, k = top <= 40 ? '#000' : '#fff',
      S = 'fill="none" stroke="' + k + '" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"',
      dot = function (x) { return '<circle cx="' + x + '" cy="44" r="3.4" fill="' + k + '"/>'; }, f = '';
    if (m === 'happy') f = dot(38) + dot(62) + '<path d="M42 57 Q50 64 58 57" ' + S + '/>';
    else if (m === 'focus') f = '<path d="M33 44 H43 M57 44 H67 M43 60 H57" ' + S + '/>';
    else if (m === 'sweaty') f = dot(38) + dot(62) + '<path d="M42 62 Q50 55 58 62" ' + S + '/>';
    else if (m === 'asleep') f = '<path d="M33 44 Q38 49 43 44 M57 44 Q62 49 67 44" ' + S + '/><path d="M45 59 H55" ' + S + '/><text x="72" y="28" font-family="-apple-system,system-ui,sans-serif" font-weight="600" font-size="16" fill="#808080">z</text>';
    else f = '<path d="M33 47 L38 40 L43 47 M57 47 L62 40 L67 47" ' + S + '/><path d="M40 55 H60 Q60 67 50 67 Q40 67 40 55Z" fill="' + k + '" stroke="' + k + '" stroke-width="2" stroke-linejoin="round"/>';
    return '<svg viewBox="0 0 100 100" width="' + size + '" height="' + size + '" aria-hidden="true"><defs><clipPath id="' + id + '"><rect x="13" y="10" width="74" height="86" rx="19"/></clipPath></defs>' +
      '<rect x="13" y="10" width="74" height="86" rx="19" fill="#1C1C1E"/><rect x="0" y="' + top + '" width="100" height="100" fill="' + L + '" clip-path="url(#' + id + ')"/>' +
      '<rect x="13" y="10" width="74" height="86" rx="19" fill="none" stroke="rgba(255,255,255,.32)" stroke-width="2"/><rect x="38" y="3" width="24" height="5" rx="2.5" fill="rgba(255,255,255,.32)"/>' + f + '</svg>';
  }
  window.Drip = drip;
  Array.prototype.forEach.call(document.querySelectorAll('[data-drip]'), function (el) {
    el.innerHTML = drip(el.getAttribute('data-drip'), el.getAttribute('data-pct'), +el.getAttribute('data-size') || 44);
  });

  var stage = document.getElementById('stage');
  if (stage) {
    var dripEl = document.getElementById('hero-drip'), read = document.getElementById('read'), bubble = document.getElementById('bubble'),
      fill = document.getElementById('fill'), mbFill = document.getElementById('mb-fill'), mbPct = document.getElementById('mb-pct');
    var LINES = {
      happy: ['Plenty left.', 'All clear.', 'Tanks are full.'],
      sweaty: ['Running low.', 'Not much left.', 'Close to the bottom.'],
      asleep: ['Empty for now.', 'Resting until the reset.', 'Back at the next refill.'],
      party: ['Refilled.', 'Fresh tank.', 'Back to full.']
    };
    var pick = function (m) { var a = LINES[m]; return a[Math.floor(Math.random() * a.length)]; };
    var cur = '', lastPct = -1;
    var colorFor = function (l) { return l < 10 ? 'red' : l < 30 ? 'orange' : 'green'; };

    var render = function (level, mood) {
      var pct = Math.round(level);
      if (mood !== cur || Math.abs(pct - lastPct) >= 2) {
        dripEl.innerHTML = drip(mood, level, 132); lastPct = pct;
      }
      read.textContent = pct + '%';
      fill.style.transform = 'scaleX(' + (level / 100) + ')';
      fill.className = 'fill ' + colorFor(level);
      mbFill.style.width = level + '%';
      mbFill.className = 'mb-fill ' + colorFor(level);
      mbPct.textContent = pct + '%';
      if (mood !== cur) { cur = mood; stage.dataset.mood = mood; bubble.textContent = pick(mood); }
    };
    var moodFor = function (level, refilling) {
      if (refilling) return 'party';
      if (level < 10) return 'asleep';
      if (level < 45) return 'sweaty';
      return 'happy';
    };

    if (reduce) { render(72, 'happy'); }
    else {
      var T = { hold: 1800, drain: 7000, sleep: 1800, fill: 1400, party: 2400 };
      var total = T.hold + T.drain + T.sleep + T.fill + T.party, start = performance.now(), visible = true;
      if ('IntersectionObserver' in window) {
        new IntersectionObserver(function (e) { visible = e[0].isIntersecting; }).observe(stage);
      }
      (function frame(now) {
        if (visible) {
          var t = (now - start) % total, level, refilling = false;
          if (t < T.hold) level = 100;
          else if ((t -= T.hold) < T.drain) level = 100 - 100 * (t / T.drain);
          else if ((t -= T.drain) < T.sleep) level = 0;
          else if ((t -= T.sleep) < T.fill) { level = 100 * (1 - Math.pow(1 - t / T.fill, 3)); refilling = true; }
          else { level = 100; refilling = true; }
          render(level, moodFor(level, refilling));
        }
        requestAnimationFrame(frame);
      })(start);
    }
  }

  // scroll reveal
  var els = document.querySelectorAll('.card,.tile,.priv > div,.burn,.term,.notch-demo,details');
  if ('IntersectionObserver' in window && !reduce) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (en.isIntersecting) { en.target.classList.add('in'); io.unobserve(en.target); }
      });
    }, { threshold: 0.15 });
    els.forEach(function (el) { el.classList.add('rv'); io.observe(el); });
  } else {
    els.forEach(function (el) { el.classList.add('in'); });
  }
})();
