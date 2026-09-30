(function () {
  'use strict';
  var stage = document.getElementById('stage');
  var liquid = document.getElementById('liquid');
  var read = document.getElementById('read');
  var bubble = document.getElementById('bubble');
  var dripUse = document.getElementById('drip-use');
  var mbFill = document.getElementById('mb-fill');
  var mbPct = document.getElementById('mb-pct');
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  var LINES = {
    happy: ['Tanks full. Go wild.', 'Plenty of juice. Ship it.', 'All systems caffeinated.'],
    sweaty: ['Running on fumes…', 'Pace yourself, champ.', "Maybe don't start that refactor."],
    asleep: ["Dry. I'll wake you when it's back.", 'Zzz… ping me at refill.', 'Nap time. For both of us.'],
    party: ['REFILLED. LET’S GO.', 'Fresh tank! Back to work.', 'We ride again.']
  };
  function pick(m) { var a = LINES[m]; return a[Math.floor(Math.random() * a.length)]; }

  function render(level, mood) {
    var pct = Math.round(level);
    stage.style.setProperty('--lvl', level + '%');
    liquid.style.setProperty('--lvl', level + '%');
    read.textContent = pct + '%';
    mbFill.style.setProperty('--lvl', level + '%');
    mbPct.textContent = pct + '%';
    mbFill.className = 'mb-fill' + (level < 12 ? ' coral' : level < 45 ? ' amber' : '');
    if (stage.dataset.mood !== mood) {
      stage.dataset.mood = mood;
      dripUse.setAttribute('href', '#drip-' + mood);
      bubble.textContent = pick(mood);
    }
  }

  function moodFor(level, refilling) {
    if (refilling) return 'party';
    if (level < 10) return 'asleep';
    if (level < 45) return 'sweaty';
    return 'happy';
  }

  if (reduce) { render(72, 'happy'); }
  else {
    // timeline (ms): hold full, drain, sleep, refill, party
    var T = { hold: 1800, drain: 7000, sleep: 1800, fill: 1400, party: 2400 };
    var total = T.hold + T.drain + T.sleep + T.fill + T.party;
    var start = performance.now();
    var visible = true;
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
    document.querySelectorAll('.burn').forEach(function (b) { b.classList.add('in'); });
  }
})();
