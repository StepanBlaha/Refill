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
    <meta name="theme-color" content="#000000">
    <style>
    :root{--bg:#000;--card:#1C1C1E;--card2:#2C2C2E;--line:rgba(255,255,255,.1);--text:#fff;--sec:#808080;--ter:rgba(255,255,255,.32);--hover:rgba(255,255,255,.16);
      --green:#30D158;--orange:#FF9F0A;--red:#FF453A;--font:-apple-system,BlinkMacSystemFont,"SF Pro Text",system-ui,sans-serif}
    *{box-sizing:border-box;margin:0}
    html{background:var(--bg)}
    body{background:var(--bg);color:var(--text);font:14px/1.4 var(--font);min-height:100vh;overflow-x:hidden;-webkit-font-smoothing:antialiased;
      padding:max(24px,env(safe-area-inset-top)) 16px max(28px,env(safe-area-inset-bottom))}
    main{max-width:760px;margin:0 auto}
    header{display:flex;align-items:center;gap:14px;margin-bottom:24px}
    #drip{width:56px;height:56px;flex:none}
    #drip.hop{animation:hop .6s cubic-bezier(.3,1.5,.5,1)}
    .brand{flex:1;min-width:0}
    .word{font-size:24px;font-weight:600;letter-spacing:-.02em;line-height:1.1}
    .mood{font-size:14px;color:var(--sec);margin-top:4px}
    #snd{font:500 12px var(--font);color:var(--sec);background:var(--card);border:0;border-radius:4px;padding:7px 12px;cursor:pointer;transition:background .15s}
    #snd:hover{background:var(--hover)}#snd:active{background:var(--card2)}#snd:focus-visible{outline:2px solid var(--green);outline-offset:2px}
    #snd:disabled{cursor:not-allowed;opacity:.45}#snd.on{color:var(--green)}
    .card{background:var(--card);border-radius:8px;padding:16px;margin-bottom:12px}
    .card.err{}
    .ch{display:flex;align-items:center;gap:8px;flex-wrap:wrap;margin-bottom:6px}
    .ch h2{font-size:16px;font-weight:600;margin-right:4px;word-break:break-all}
    .chip{font-size:11px;font-weight:500;color:var(--sec);background:var(--card2);border-radius:4px;padding:2px 6px}
    .errtxt{color:var(--orange,#FF9F0A);font-size:12px;margin:6px 0}
    .row{padding:12px 0;border-top:1px solid var(--line)}.row:first-of-type{border-top:0}
    .top{display:flex;align-items:baseline;gap:10px;flex-wrap:wrap}
    .wl{font-size:14px;font-weight:500;flex:1;min-width:8em;overflow-wrap:anywhere}
    .cd{font-size:12px;color:var(--sec);font-variant-numeric:tabular-nums}
    .pct{font-size:19px;font-weight:600;font-variant-numeric:tabular-nums;min-width:52px;text-align:right}
    .bar{height:4px;border-radius:2px;background:rgba(255,255,255,.12);margin-top:8px;overflow:hidden}
    .fill{height:100%;width:0;border-radius:2px;background:var(--green);transform-origin:left;transition:width .8s cubic-bezier(.2,.9,.25,1),background-color .4s}
    .fill.orange{background:var(--orange)}.fill.red{background:var(--red)}
    .fill.pop{animation:pop .7s cubic-bezier(.2,.9,.25,1)}
    h3{font-size:11px;font-weight:500;color:var(--sec);margin:28px 0 8px}
    .ev{display:flex;align-items:flex-start;gap:12px;padding:10px 0;border-top:1px solid var(--line)}
    .ev>div{min-width:0;flex:1}
    .dot{width:6px;height:6px;border-radius:50%;flex:none;background:var(--ter)}
    .dot.reset,.dot.test{background:var(--green)}.dot.warning{background:var(--orange)}.dot.empty{background:var(--red)}
    .ev b{font-size:14px;font-weight:500;overflow-wrap:anywhere}.ev span{display:block;font-size:12px;color:var(--sec);margin-top:1px;overflow-wrap:anywhere}
    .ev time{margin-left:auto;font-size:12px;color:var(--ter);white-space:nowrap;padding-left:8px;font-variant-numeric:tabular-nums}
    footer{margin-top:24px;text-align:center;font-size:11px;font-weight:500;color:var(--ter)}
    .empty{color:var(--sec);font-size:13px;padding:20px 0;text-align:center}
    #flash{position:fixed;top:0;left:0;right:0;height:2px;pointer-events:none;opacity:0;z-index:5}
    #flash.reset{background:var(--green);animation:fade 1.6s ease-out}
    #flash.warning{background:var(--orange);animation:fade 1.6s ease-out}
    #flash.empty{background:var(--red);animation:fade 1.6s ease-out}
    #toast{position:fixed;left:50%;bottom:max(16px,env(safe-area-inset-bottom));z-index:6;width:min(92vw,420px);max-height:min(50vh,320px);overflow:auto;background:var(--card);border-radius:8px;padding:12px 16px;box-shadow:0 0 0 1px var(--line);transform:translate(-50%,16px);opacity:0;visibility:hidden;transition:transform .45s cubic-bezier(.3,1.3,.5,1),opacity .25s,visibility .45s;overflow-wrap:anywhere}
    #toast.show{transform:translate(-50%,0);opacity:1;visibility:visible}
    #toast b{font-size:14px;font-weight:600;display:block;overflow-wrap:anywhere}#toast span{font-size:12px;color:var(--sec);display:block;margin-top:2px;overflow-wrap:anywhere}
    @keyframes hop{40%{transform:translateY(-8px)}100%{transform:none}}
    @keyframes pop{from{transform:scaleX(0)}to{transform:none}}
    @keyframes fade{0%,50%{opacity:1}100%{opacity:0}}
    @media (prefers-reduced-motion:reduce){*{animation:none!important;transition:none!important}}
    </style>
    </head>
    <body>
    <div id="flash"></div>
    <main>
      <header>
        <div id="drip"></div>
        <div class="brand"><div class="word">Refill</div><div class="mood" id="mood">Checking usage</div></div>
        <button id="snd" type="button">sound off</button>
      </header>
      <div id="accts"><div class="empty">Waiting for the first reading.</div></div>
      <h3>Activity</h3>
      <div id="feed"><div class="empty">Nothing yet.</div></div>
      <footer id="foot">connecting</footer>
    </main>
    <div id="toast"><b></b><span></span></div>
    <script>
    (function(){
    var $=function(i){return document.getElementById(i)};
    function esc(s){return String(s==null?'':s).replace(/[&<>"']/g,function(c){return{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]})}
    var status=null,events=[],lastKey=null,first=true,lastOk=0,sig='',audio=null,toastT=null,dripMood='',uid=0;
    var LINES={happy:['Plenty left.','All clear.','Tanks are full.'],
      focus:['About half left.','Steady. Pace it.','Worth spending well.'],
      sweaty:['Running low.','Not much left.','Close to the bottom.'],
      asleep:['Empty for now.','Resting until the reset.','Back at the next refill.']};
    var pick=function(a){return a[Math.floor(Math.random()*a.length)]};
    function col(u){return u>=90?'red':u>=70?'orange':'green'}
    function drip(m,pct,size){
      size=size||56;pct=pct==null?100:pct;if(m==='party')pct=100;
      var id='dc'+(uid++),L=m==='asleep'?'rgba(255,255,255,.32)':m==='sweaty'?'#FF453A':m==='focus'?'#FF9F0A':'#30D158';
      var top=96-86*Math.max(0,Math.min(100,pct))/100,k=top<=40?'#000':'#fff',
        S='fill="none" stroke="'+k+'" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"',
        dot=function(x){return '<circle cx="'+x+'" cy="44" r="3.4" fill="'+k+'"/>'},f='';
      if(m==='happy')f=dot(38)+dot(62)+'<path d="M42 57 Q50 64 58 57" '+S+'/>';
      else if(m==='focus')f='<path d="M33 44 H43 M57 44 H67 M43 60 H57" '+S+'/>';
      else if(m==='sweaty')f=dot(38)+dot(62)+'<path d="M42 62 Q50 55 58 62" '+S+'/>';
      else if(m==='asleep')f='<path d="M33 44 Q38 49 43 44 M57 44 Q62 49 67 44" '+S+'/><path d="M45 59 H55" '+S+'/><text x="72" y="28" font-family="-apple-system,system-ui,sans-serif" font-weight="600" font-size="16" fill="#808080">z</text>';
      else f='<path d="M33 47 L38 40 L43 47 M57 47 L62 40 L67 47" '+S+'/><path d="M40 55 H60 Q60 67 50 67 Q40 67 40 55Z" fill="'+k+'" stroke="'+k+'" stroke-width="2" stroke-linejoin="round"/>';
      return '<svg viewBox="0 0 100 100" width="'+size+'" height="'+size+'" aria-hidden="true"><defs><clipPath id="'+id+'"><rect x="13" y="10" width="74" height="86" rx="19"/></clipPath></defs>'+
        '<rect x="13" y="10" width="74" height="86" rx="19" fill="#1C1C1E"/><rect x="0" y="'+top+'" width="100" height="100" fill="'+L+'" clip-path="url(#'+id+')"/>'+
        '<rect x="13" y="10" width="74" height="86" rx="19" fill="none" stroke="rgba(255,255,255,.32)" stroke-width="2"/><rect x="38" y="3" width="24" height="5" rx="2.5" fill="rgba(255,255,255,.32)"/>'+f+'</svg>';
    }
    var curPct=100;
    function setDrip(m,hop){
      var d=$('drip');
      if(m!==dripMood||hop){d.innerHTML=drip(hop?'party':m,curPct);if(m!==dripMood)$('mood').textContent=pick(LINES[m]);dripMood=m}
      if(hop){d.classList.remove('hop');void d.offsetWidth;d.classList.add('hop');setTimeout(function(){d.classList.remove('hop');d.innerHTML=drip(dripMood,curPct)},1400)}
    }
    function lowest(){
      var low=null;
      ((status&&status.accounts)||[]).forEach(function(a){(a.windows||[]).forEach(function(w){
        if(!w.stale&&(w.key==='five_hour'||w.key==='primary')){var r=Math.max(0,100-w.utilization);if(low===null||r<low)low=r}})});
      return low;
    }
    function moodOf(){
      var low=lowest();
      if(low===null)return 'happy';
      low=Math.round(low);
      return low<=0?'asleep':low<20?'sweaty':low<50?'focus':'happy';
    }
    function tank(ai,w){
      return '<div class="row tank" data-a="'+ai+'" data-k="'+esc(w.key)+'"><div class="top"><div class="wl">'+esc(w.label||w.key)+'</div><div class="cd"></div><div class="pct"><span class="n">--</span></div></div>'+
        '<div class="bar"><div class="fill"></div></div></div>';
    }
    function renderAccounts(){
      var A=(status&&status.accounts)||[],s=JSON.stringify(A.map(function(a){return[a.id,a.error?1:0,a.label,a.email,a.name,a.plan,(a.windows||[]).map(function(w){return w.key+w.label})]}));
      if(s!==sig){
        sig=s;
        $('accts').innerHTML=A.length?A.map(function(a,i){
          return '<section class="card'+(a.error?' err':'')+'"><div class="ch"><h2>'+esc(a.label||a.email||a.name)+'</h2><span class="chip">'+esc(a.provider)+'</span>'+(a.plan?'<span class="chip">'+esc(a.plan)+'</span>':'')+'</div>'+
            (a.error?'<div class="errtxt">'+esc(a.error)+'</div>':'')+(a.windows||[]).map(function(w){return tank(i,w)}).join('')+'</section>';
        }).join(''):'<div class="empty">No accounts yet. Add one from the menu bar.</div>';
      }
      A.forEach(function(a,i){(a.windows||[]).forEach(function(w){
        var t=document.querySelector('.tank[data-a="'+i+'"][data-k="'+w.key+'"]');if(!t)return;
        var l=t.querySelector('.fill'),cd=t.querySelector('.cd');
        if(w.stale){
          l.style.width='0%';l.className='fill';
          t.querySelector('.n').textContent='—';
          cd.dataset.r='';cd.dataset.seen=w.observedAt||'';cd.textContent=seenText(w.observedAt);
        }else{
          var rem=Math.max(0,Math.min(100,Math.round(100-w.utilization)));
          l.style.width=rem+'%';l.className='fill '+col(w.utilization)+(l.classList.contains('pop')?' pop':'');
          t.querySelector('.n').textContent=rem+'% left';
          cd.dataset.r=w.resetsAt||'';cd.dataset.seen='';
        }
      })});
      var lo=lowest();curPct=lo===null?100:lo;
      tick();
    }
    function tick(){
      Array.prototype.forEach.call(document.querySelectorAll('.cd'),function(e){
        if(e.dataset.seen){e.textContent=seenText(e.dataset.seen);return}
        var r=e.dataset.r;if(!r){e.textContent='not started';return}
        var s=Math.floor((Date.parse(r)-Date.now())/1000);
        if(s<=0){e.textContent='ready';return}
        var d=Math.floor(s/86400),h=Math.floor(s%86400/3600),m=Math.floor(s%3600/60);
        e.textContent='refills in '+(d?d+'d '+h+'h':h?h+'h '+m+'m':m+'m '+String(s%60).padStart(2,'0')+'s');
      });
      if(status&&status.updatedAt){var u=Math.max(0,Math.round((Date.now()-Date.parse(status.updatedAt))/1000));$('foot').textContent='updated '+ago(u)+' ago'}
    }
    function ago(s){return s<60?s+'s':s<3600?Math.floor(s/60)+'m':s<86400?Math.floor(s/3600)+'h':Math.floor(s/86400)+'d'}
    function seenText(iso){
      if(!iso)return 'last seen';
      var t=Date.parse(iso);if(isNaN(t))return 'last seen';
      try{return 'last seen '+new Date(t).toLocaleDateString(undefined,{day:'numeric',month:'short'})}catch(e){return 'last seen'}
    }
    function renderFeed(){
      var L=events.slice(-10).reverse();
      $('feed').innerHTML=L.length?L.map(function(e){
        var t=Math.max(0,Math.round((Date.now()-Date.parse(e.detectedAt))/1000));
        return '<div class="ev"><i class="dot '+esc(e.kind)+'"></i><div><b>'+esc(e.title)+'</b><span>'+esc(e.accountName)+' &middot; '+esc(e.windowLabel)+'</span></div><time>'+ago(t)+' ago</time></div>';
      }).join(''):'<div class="empty">Nothing yet. Events appear when a tank refills.</div>';
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
    function syncSnd(){var on=localStorage_get()==='1',b=$('snd');b.className=on?'on':'';b.innerHTML=on?'sound on':'sound off'}
    $('snd').onclick=function(){
      var on=localStorage_get()!=='1';
      try{localStorage.setItem('refill.sound',on?'1':'0')}catch(e){}
      syncSnd();if(on)chime('reset');
    };
    function celebrate(e){
      var k=e.kind==='warning'?'warning':e.kind==='empty'?'empty':'reset',f=$('flash');
      f.className='';void f.offsetWidth;f.className=k;
      if(k==='reset'){
        Array.prototype.forEach.call(document.querySelectorAll('.fill'),function(l){l.classList.remove('pop');void l.offsetWidth;l.classList.add('pop')});
        setTimeout(function(){Array.prototype.forEach.call(document.querySelectorAll('.fill'),function(l){l.classList.remove('pop')})},900);
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
        var m=moodOf();if(m!==dripMood&&!$('drip').classList.contains('hop'))setDrip(m,false);
        renderFeed();
        var n=events[events.length-1],key=n?[n.detectedAt,n.accountId,n.window,n.kind].join('|'):null;
        if(!first&&key&&key!==lastKey)celebrate(n);
        lastKey=key;first=false;
      }).catch(function(){$('foot').textContent='offline, retrying'});
    }
    syncSnd();setDrip('happy',false);poll();
    setInterval(poll,5000);setInterval(function(){tick();renderFeed()},1000);
    })();
    </script>
    </body>
    </html>
    """#
}
