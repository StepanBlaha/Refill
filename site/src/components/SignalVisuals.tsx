import Drip from "./Drip";
import v from "./SignalVisuals.module.css";

/** Decorative scenes for the Signals story. Parents mark them aria-hidden. */

function Screen({ children, top }: { children: React.ReactNode; top?: boolean }) {
  return <div className={`${v.screen} ${top ? v.top : ""}`}>{children}</div>;
}

export function NotchScene() {
  return (
    <Screen top>
      <div className={v.bar} />
      <div className={`${v.notch} ${v.drop}`}>
        <span className={v.bob}><Drip mood="party" size={56} /></span>
        <div className={v.copy}>
          <b>Tank&apos;s full</b>
          <span>work: the 5h session is fresh. Whatever you were doing, resume it.</span>
        </div>
      </div>
      <div className={v.win}>
        <p>&gt; refactor the auth module</p>
        <p className={v.ok}>Limit reset. Carry on.</p>
      </div>
    </Screen>
  );
}

export function NotifScene() {
  return (
    <Screen>
      <div className={v.bar} />
      <div className={`${v.card} ${v.slide}`}>
        <Drip mood="happy" pct={100} size={48} />
        <div className={v.copy}>
          <div className={v.meta}><b>Refill</b><span>now</span></div>
          <b>Tank&apos;s full</b>
          <span>work: the 5h session is fresh.</span>
        </div>
      </div>
      <div className={`${v.card} ${v.slide} ${v.second}`}>
        <Drip mood="asleep" pct={0} size={48} />
        <div className={v.copy}>
          <div className={v.meta}><b>Refill</b><span>2m ago</span></div>
          <b>Tank&apos;s dry</b>
          <span>side-hustle hit the limit. Back at the next reset.</span>
        </div>
      </div>
    </Screen>
  );
}

const WAVE = [0.35, 0.7, 0.5, 0.95, 0.6, 1, 0.45, 0.8, 0.55, 0.3, 0.65, 0.4];

export function SoundScene() {
  return (
    <Screen>
      <div className={v.sound}>
        <div className={v.wave}>
          {WAVE.map((h, i) => (
            <i key={i} style={{ height: `${h * 100}%`, animationDelay: `${(i % 6) * -0.18}s` }} />
          ))}
        </div>
        <p className={v.chip}>
          <svg width="18" height="18" viewBox="0 0 18 18" aria-hidden="true" focusable="false">
            <path d="M3 7v4h3l4 3V4L6 7H3z" fill="currentColor" />
            <path d="M12.5 6.5a3.5 3.5 0 010 5" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
          </svg>
          Refill chime
        </p>
      </div>
    </Screen>
  );
}

export function WarnScene() {
  return (
    <Screen>
      <div className={v.bar} />
      <div className={`${v.card} ${v.warn} ${v.slide}`}>
        <Drip mood="focus" pct={20} size={56} />
        <div className={v.copy}>
          <b>Running warm</b>
          <span>personal at 82%. Refill in 1h 12m.</span>
        </div>
      </div>
      <ul className={v.levels}>
        <li><i style={{ background: "var(--warn)" }} />80%</li>
        <li><i style={{ background: "var(--warn)" }} />95%</li>
        <li><i style={{ background: "var(--danger)" }} />100%</li>
      </ul>
    </Screen>
  );
}
