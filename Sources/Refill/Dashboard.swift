enum Dashboard {
    static let html = #"""
    <!doctype html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <title>Refill</title>
    <meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <meta name="apple-mobile-web-app-title" content="Refill">
    <meta name="theme-color" content="#0D0E11">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,700;12..96,800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
    <style>
    :root{--ink:#0D0E11;--panel:#16181D;--line:#262A31;--text:#F3F1EA;--muted:#8B8F98;--lime:#C8FF4D;--amber:#FFB547;--coral:#FF6B5B;
      --head:'Bricolage Grotesque',system-ui,sans-serif;--mono:'JetBrains Mono',ui-monospace,Menlo,monospace}
    *{box-sizing:border-box;margin:0}
    html{background:var(--ink)}
    body{background:var(--ink);color:var(--text);font-family:system-ui,-apple-system,sans-serif;min-height:100vh;overflow-x:hidden;
      padding:max(20px,env(safe-area-inset-top)) 16px max(28px,env(safe-area-inset-bottom));
      background-image:radial-gradient(900px 400px at 15% -10%,rgba(200,255,77,.07),transparent 60%)}
    main{max-width:980px;margin:0 auto}
    header{display:flex;align-items:center;gap:16px;margin-bottom:28px;flex-wrap:wrap}
    #drip{width:72px;height:72px;flex:none;animation:bob 3.2s ease-in-out infinite}
    #drip.jump{animation:jump .9s cubic-bezier(.3,1.6,.5,1)}
    .brand{flex:1;min-width:180px}
    .word{font:800 34px/1 var(--head);letter-spacing:-.03em}
    .mood{font:400 14px var(--mono);color:var(--muted);margin-top:6px}
    #snd{font:600 12px var(--mono);color:var(--muted);background:var(--panel);border:1px solid var(--line);border-radius:99px;padding:8px 14px;cursor:pointer}
    #snd.on{color:var(--lime);border-color:rgba(200,255,77,.4)}
    .card{background:var(--panel);border:1px solid var(--line);border-radius:22px;padding:18px;margin-bottom:16px}
    .card.err{border-color:rgba(255,107,91,.45)}
    .ch{display:flex;align-items:center;gap:8px;flex-wrap:wrap;margin-bottom:16px}
    .ch h2{font:700 19px var(--head);letter-spacing:-.01em;margin-right:4px;word-break:break-all}
    .chip{font:600 10px var(--mono);text-transform:uppercase;letter-spacing:.08em;color:var(--muted);border:1px solid var(--line);border-radius:99px;padding:3px 8px}
    .errtxt{color:var(--coral);font:400 12px var(--mono);margin:-6px 0 12px}
    .tanks{display:flex;flex-wrap:wrap;gap:18px 26px}
    .tank{display:flex;gap:14px;align-items:flex-end;min-width:200px;flex:1 1 200px}
    .glass{position:relative;width:64px;height:150px;flex:none;border-radius:14px 14px 18px 18px;border:2px solid #3a3f49;background:linear-gradient(90deg,rgba(255,255,255,.05),rgba(255,255,255,.01) 40%,rgba(255,255,255,.06));overflow:hidden}
    .glass:after{content:"";position:absolute;left:7px;top:8px;bottom:8px;width:5px;border-radius:9px;background:linear-gradient(rgba(255,255,255,.25),rgba(255,255,255,0));pointer-events:none}
    .liq{position:absolute;left:0;right:0;bottom:0;color:var(--lime);transition:height 1.2s cubic-bezier(.2,.8,.2,1),color .6s}
    .liq.amber{color:var(--amber)}.liq.coral{color:var(--coral)}
    .liq .body{position:absolute;left:0;right:0;top:9px;bottom:0;background:currentColor;opacity:.92}
    .liq svg{position:absolute;top:0;left:0;width:200%;height:10px;fill:currentColor;opacity:.92;animation:wave 2.6s linear infinite}
    .liq svg.b{opacity:.45;top:-3px;animation-duration:4s;animation-direction:reverse}
    .liq.fill{animation:rise 1.4s cubic-bezier(.2,.9,.25,1)}
    .info{min-width:0}
    .pct{font:600 40px/1 var(--mono);letter-spacing:-.04em}
    .pct small{font-size:13px;color:var(--muted);margin-left:5px;letter-spacing:0}
    .wl{font:700 14px var(--head);margin-top:8px}
    .cd{font:400 12px var(--mono);color:var(--muted);margin-top:4px}
    h3{font:700 13px var(--mono);color:var(--muted);text-transform:uppercase;letter-spacing:.1em;margin:30px 0 12px}
    .ev{display:flex;align-items:center;gap:12px;padding:11px 0;border-top:1px solid var(--line)}
    .dot{width:9px;height:9px;border-radius:50%;flex:none;background:var(--muted)}
    .dot.reset,.dot.test{background:var(--lime)}.dot.warning{background:var(--amber)}.dot.empty{background:var(--coral)}
    .ev b{font:700 15px var(--head)}.ev span{display:block;font:400 12px var(--mono);color:var(--muted);margin-top:2px;word-break:break-all}
    .ev time{margin-left:auto;font:400 12px var(--mono);color:var(--muted);white-space:nowrap;padding-left:8px}
    footer{margin-top:26px;text-align:center;font:400 11px var(--mono);color:var(--muted)}
    .empty{color:var(--muted);font:400 13px var(--mono);padding:24px 0;text-align:center}
    #flash{position:fixed;inset:0;pointer-events:none;opacity:0;z-index:5}
    #flash.reset{background:radial-gradient(circle at 50% 40%,rgba(200,255,77,.55),rgba(200,255,77,.15) 60%,transparent);animation:flash 1.1s ease-out}
    #flash.warning{box-shadow:inset 0 0 0 6px var(--amber),inset 0 0 90px rgba(255,181,71,.5);animation:pulse 1.6s ease-out}
    #flash.empty{box-shadow:inset 0 0 0 6px var(--coral),inset 0 0 90px rgba(255,107,91,.5);animation:pulse 1.6s ease-out}
    #toast{position:fixed;left:50%;bottom:24px;z-index:6;width:min(92vw,380px);background:var(--panel);border:1px solid var(--lime);border-radius:18px;padding:14px 18px;transform:translate(-50%,calc(100% + 40px));opacity:0;visibility:hidden;transition:transform .5s cubic-bezier(.3,1.4,.5,1),opacity .3s,visibility .5s;box-shadow:0 12px 40px rgba(0,0,0,.6)}
    #toast.show{transform:translate(-50%,0);opacity:1;visibility:visible}#toast.warning{border-color:var(--amber)}#toast.empty{border-color:var(--coral)}
    #toast b{font:800 18px var(--head);display:block}#toast span{font:400 13px var(--mono);color:var(--muted);display:block;margin-top:4px}
    @keyframes wave{to{transform:translateX(-50%)}}
    @keyframes bob{50%{transform:translateY(-5px) rotate(2deg)}}
    @keyframes jump{0%{transform:translateY(0)}35%{transform:translateY(-26px) scale(1.12,.94)}70%{transform:translateY(0) scale(.94,1.08)}100%{transform:none}}
    @keyframes rise{from{transform:translateY(100%)}to{transform:none}}
    @keyframes flash{0%{opacity:1}100%{opacity:0}}
    @keyframes pulse{0%,60%{opacity:1}100%{opacity:0}}
    @keyframes zz{0%{opacity:0;transform:translate(0,4px)}50%{opacity:1}100%{opacity:0;transform:translate(6px,-10px)}}
    @media (prefers-reduced-motion:reduce){*{animation:none!important;transition:none!important}}
    </style>
    </head>
    <body>
    <div id="flash"></div>
    <main>
      <header>
        <div id="drip"></div>
        <div class="brand"><div class="word">Refill</div><div class="mood" id="mood">Checking the tanks...</div></div>
        <button id="snd" type="button">&#128264; sound off</button>
      </header>
      <div id="accts"><div class="empty">Waiting for first reading...</div></div>
      <h3>Activity</h3>
      <div id="feed"><div class="empty">Nothing yet.</div></div>
      <footer id="foot">connecting...</footer>
    </main>
    <div id="toast"><b></b><span></span></div>
    <script>
    (function(){
    var $=function(i){return document.getElementById(i)};
    function esc(s){return String(s==null?'':s).replace(/[&<>"']/g,function(c){return{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]})}
    var WAVE='<svg viewBox="0 0 200 10" preserveAspectRatio="none"><path d="M0 5 Q25 -1 50 5 T100 5 T150 5 T200 5 V10 H0Z"/></svg>';
    var status=null,events=[],lastKey=null,first=true,lastOk=0,sig='',audio=null,toastT=null,dripMood='';
    var LINES={happy:['Tanks full. Go wreck something.','Plenty in the tank. Send it.','Brimming. Absolutely brimming.'],
      focus:['Half a tank. Make it count.','Steady now. No wasted prompts.','Getting thoughtful in here.'],
      sweaty:['Running on fumes. Pace yourself.','Oof. Ration those tokens.','I can see the bottom. Gulp.'],
      asleep:["Dry. I'll wake you when it's back.",'Zzz. Wake me at refill.','Bone dry. Go touch grass.']};
    var pick=function(a){return a[Math.floor(Math.random()*a.length)]};
    function col(u){return u>=90?'coral':u>=70?'amber':'lime'}
    function hex(c){return{lime:'#C8FF4D',amber:'#FFB547',coral:'#FF6B5B',muted:'#5b5f68'}[c]}
    function drip(m,happyEyes){
      var c=hex(m==='asleep'?'muted':m==='sweaty'?'coral':m==='focus'?'amber':'lime'),k='#0D0E11',f='';
      var eye=function(x){return happyEyes?'<path d="M'+(x-6)+' 68 Q'+x+' 58 '+(x+6)+' 68" fill="none" stroke="'+k+'" stroke-width="4" stroke-linecap="round"/>':'<circle cx="'+x+'" cy="65" r="5" fill="'+k+'"/><circle cx="'+(x+1.5)+'" cy="63" r="1.6" fill="#fff"/>'};
      if(happyEyes||m==='happy')f=(happyEyes?eye(39)+eye(61):eye(39)+eye(61))+'<path d="M40 79 Q50 91 60 79" fill="none" stroke="'+k+'" stroke-width="4" stroke-linecap="round"/><circle cx="30" cy="77" r="4" fill="#FF6B5B" opacity=".35"/><circle cx="70" cy="77" r="4" fill="#FF6B5B" opacity=".35"/>';
      else if(m==='focus')f=eye(39)+eye(61)+'<path d="M41 82 H59" stroke="'+k+'" stroke-width="4" stroke-linecap="round"/>';
      else if(m==='sweaty')f=eye(39)+eye(61)+'<path d="M31 54 L46 58 M69 54 L54 58" stroke="'+k+'" stroke-width="3.5" stroke-linecap="round"/><path d="M42 84 Q50 78 58 84" fill="none" stroke="'+k+'" stroke-width="4" stroke-linecap="round"/><path d="M82 40 Q88 50 82 54 Q76 50 82 40Z" fill="#7cc7ff"/>';
      else f='<path d="M32 66 Q39 72 46 66 M54 66 Q61 72 68 66" fill="none" stroke="'+k+'" stroke-width="4" stroke-linecap="round"/><ellipse cx="50" cy="82" rx="4" ry="3" fill="'+k+'"/><text x="70" y="34" font-family="JetBrains Mono,monospace" font-weight="700" font-size="16" fill="#8B8F98" style="animation:zz 2.4s ease-in-out infinite">z</text>';
      return '<svg viewBox="0 0 100 100" width="72" height="72"><path d="M50 4 C50 4 15 44 15 68 a35 32 0 0 0 70 0 C85 44 50 4 50 4Z" fill="'+c+'"/><path d="M30 60 Q32 46 42 36" fill="none" stroke="#fff" stroke-opacity=".45" stroke-width="5" stroke-linecap="round"/>'+f+'</svg>';
    }
    function setDrip(m,jump){
      var d=$('drip');
      if(m!==dripMood||jump){d.innerHTML=drip(m,jump);if(m!==dripMood)$('mood').textContent=pick(LINES[m]);dripMood=m}
      if(jump){d.classList.remove('jump');void d.offsetWidth;d.classList.add('jump');setTimeout(function(){if(dripMood===m){d.classList.remove('jump');d.innerHTML=drip(m,false)}},1200)}
    }
    function moodOf(){
      var low=null;
      ((status&&status.accounts)||[]).forEach(function(a){(a.windows||[]).forEach(function(w){
        if(w.key==='five_hour'||w.key==='primary'){var r=Math.max(0,100-w.utilization);if(low===null||r<low)low=r}})});
      if(low===null)return 'happy';
      low=Math.round(low);
      return low<=0?'asleep':low<20?'sweaty':low<50?'focus':'happy';
    }
    function tank(ai,w){
      return '<div class="tank" data-a="'+ai+'" data-k="'+esc(w.key)+'"><div class="glass"><div class="liq"><div class="body"></div>'+WAVE+WAVE.replace('<svg','<svg class="b"')+'</div></div>'+
        '<div class="info"><div class="pct"><span class="n">--</span><small>left</small></div><div class="wl">'+esc(w.label||w.key)+'</div><div class="cd"></div></div></div>';
    }
    function renderAccounts(){
      var A=(status&&status.accounts)||[],s=JSON.stringify(A.map(function(a){return[a.id,a.error?1:0,a.email,a.plan,(a.windows||[]).map(function(w){return w.key+w.label})]}));
      if(s!==sig){
        sig=s;
        $('accts').innerHTML=A.length?A.map(function(a,i){
          return '<section class="card'+(a.error?' err':'')+'"><div class="ch"><h2>'+esc(a.email||a.name)+'</h2><span class="chip">'+esc(a.provider)+'</span>'+(a.plan?'<span class="chip">'+esc(a.plan)+'</span>':'')+'</div>'+
            (a.error?'<div class="errtxt">'+esc(a.error)+'</div>':'')+'<div class="tanks">'+(a.windows||[]).map(function(w){return tank(i,w)}).join('')+'</div></section>';
        }).join(''):'<div class="empty">No accounts yet. Add one from the menu bar.</div>';
      }
      A.forEach(function(a,i){(a.windows||[]).forEach(function(w){
        var t=document.querySelector('.tank[data-a="'+i+'"][data-k="'+w.key+'"]');if(!t)return;
        var rem=Math.max(0,Math.min(100,Math.round(100-w.utilization))),l=t.querySelector('.liq');
        l.style.height=rem?'max('+rem+'%,10px)':'0';l.className='liq '+col(w.utilization)+(l.classList.contains('fill')?' fill':'');
        t.querySelector('.n').textContent=rem+'%';
        t.querySelector('.cd').dataset.r=w.resetsAt||'';
      })});
      tick();
    }
    function tick(){
      Array.prototype.forEach.call(document.querySelectorAll('.cd'),function(e){
        var r=e.dataset.r;if(!r){e.textContent='no reset scheduled';return}
        var s=Math.floor((Date.parse(r)-Date.now())/1000);
        if(s<=0){e.textContent='refilling now...';return}
        var d=Math.floor(s/86400),h=Math.floor(s%86400/3600),m=Math.floor(s%3600/60);
        e.textContent='refills in '+(d?d+'d '+h+'h':h?h+'h '+m+'m':m+'m '+String(s%60).padStart(2,'0')+'s');
      });
      if(status&&status.updatedAt){var u=Math.max(0,Math.round((Date.now()-Date.parse(status.updatedAt))/1000));$('foot').textContent='updated '+ago(u)+' ago'}
    }
    function ago(s){return s<60?s+'s':s<3600?Math.floor(s/60)+'m':s<86400?Math.floor(s/3600)+'h':Math.floor(s/86400)+'d'}
    function renderFeed(){
      var L=events.slice(-10).reverse();
      $('feed').innerHTML=L.length?L.map(function(e){
        var t=Math.max(0,Math.round((Date.now()-Date.parse(e.detectedAt))/1000));
        return '<div class="ev"><i class="dot '+esc(e.kind)+'"></i><div><b>'+esc(e.title)+'</b><span>'+esc(e.accountName)+' &middot; '+esc(e.windowLabel)+'</span></div><time>'+ago(t)+' ago</time></div>';
      }).join(''):'<div class="empty">Nothing yet. Events show up when a tank refills.</div>';
    }
    function chime(kind){
      if(localStorage_get()!=='1')return;
      try{
        audio=audio||new (window.AudioContext||window.webkitAudioContext)();if(audio.state==='suspended')audio.resume();
        var notes=kind==='warning'?[[330,0]]:kind==='empty'?[[196,0]]:[[523.25,0],[783.99,.16]];
        notes.forEach(function(n){
          var o=audio.createOscillator(),g=audio.createGain(),t=audio.currentTime+n[1];
          o.type='sine';o.frequency.value=n[0];g.gain.setValueAtTime(0,t);g.gain.linearRampToValueAtTime(.22,t+.02);g.gain.exponentialRampToValueAtTime(.0001,t+.6);
          o.connect(g);g.connect(audio.destination);o.start(t);o.stop(t+.65);
        });
      }catch(e){}
    }
    function localStorage_get(){try{return localStorage.getItem('refill.sound')}catch(e){return null}}
    function syncSnd(){var on=localStorage_get()==='1',b=$('snd');b.className=on?'on':'';b.innerHTML=on?'&#128266; sound on':'&#128264; sound off'}
    $('snd').onclick=function(){
      var on=localStorage_get()!=='1';
      try{localStorage.setItem('refill.sound',on?'1':'0')}catch(e){}
      syncSnd();if(on)chime('reset');
    };
    function celebrate(e){
      var k=e.kind==='warning'?'warning':e.kind==='empty'?'empty':'reset',f=$('flash');
      f.className='';void f.offsetWidth;f.className=k;
      if(k==='reset'){
        Array.prototype.forEach.call(document.querySelectorAll('.liq'),function(l){l.classList.remove('fill');void l.offsetWidth;l.classList.add('fill')});
        setTimeout(function(){Array.prototype.forEach.call(document.querySelectorAll('.liq'),function(l){l.classList.remove('fill')})},1600);
        setDrip('happy',true);
      }
      var t=$('toast');t.className=k;t.querySelector('b').textContent=e.title||'';t.querySelector('span').textContent=e.message||'';
      void t.offsetWidth;t.className=k+' show';clearTimeout(toastT);toastT=setTimeout(function(){t.className=k},6000);
      chime(k);
    }
    function poll(){
      Promise.all([fetch('/status',{cache:'no-store'}).then(function(r){return r.json()}),fetch('/events',{cache:'no-store'}).then(function(r){return r.json()})]).then(function(r){
        status=r[0];events=Array.isArray(r[1])?r[1]:[];lastOk=Date.now();
        renderAccounts();
        var m=moodOf();if(m!==dripMood&&!$('drip').classList.contains('jump'))setDrip(m,false);
        renderFeed();
        var n=events[events.length-1],key=n?[n.detectedAt,n.accountId,n.window,n.kind].join('|'):null;
        if(!first&&key&&key!==lastKey)celebrate(n);
        lastKey=key;first=false;
      }).catch(function(){$('foot').textContent='offline. retrying...'});
    }
    syncSnd();setDrip('happy',false);poll();
    setInterval(poll,5000);setInterval(function(){tick();renderFeed()},1000);
    })();
    </script>
    </body>
    </html>
    """#
}
