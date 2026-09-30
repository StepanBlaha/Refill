import { useId } from "react";

export type Mood = "happy" | "focus" | "sweaty" | "asleep" | "party";

type Props = {
  mood?: Mood;
  pct?: number;
  size?: number;
  title?: string;
};

/** Drip: flat glass tank with a face. Same generator as the app dashboard. */
export default function Drip({ mood = "happy", pct = 100, size = 56, title }: Props) {
  const raw = useId().replace(/[^a-zA-Z0-9]/g, "");
  const id = `dc${raw}`;
  const level = mood === "party" ? 100 : Math.max(0, Math.min(100, pct));
  const liquid =
    mood === "asleep" ? "rgba(255,255,255,.32)" : mood === "sweaty" ? "#FF453A" : mood === "focus" ? "#FF9F0A" : "#30D158";
  const top = 96 - (86 * level) / 100;
  const k = top <= 40 ? "#000" : "#fff";
  const stroke = { fill: "none", stroke: k, strokeWidth: 4, strokeLinecap: "round", strokeLinejoin: "round" } as const;
  const dot = (x: number) => <circle cx={x} cy={44} r={3.4} fill={k} />;

  let face;
  if (mood === "happy")
    face = (
      <>
        {dot(38)}
        {dot(62)}
        <path d="M42 57 Q50 64 58 57" {...stroke} />
      </>
    );
  else if (mood === "focus") face = <path d="M33 44 H43 M57 44 H67 M43 60 H57" {...stroke} />;
  else if (mood === "sweaty")
    face = (
      <>
        {dot(38)}
        {dot(62)}
        <path d="M42 62 Q50 55 58 62" {...stroke} />
      </>
    );
  else if (mood === "asleep")
    face = (
      <>
        <path d="M33 44 Q38 49 43 44 M57 44 Q62 49 67 44" {...stroke} />
        <path d="M45 59 H55" {...stroke} />
        <text x="72" y="28" fontFamily="-apple-system,system-ui,sans-serif" fontWeight={600} fontSize={16} fill="#808080">
          z
        </text>
      </>
    );
  else
    face = (
      <>
        <path d="M33 47 L38 40 L43 47 M57 47 L62 40 L67 47" {...stroke} />
        <path d="M40 55 H60 Q60 67 50 67 Q40 67 40 55Z" fill={k} stroke={k} strokeWidth={2} strokeLinejoin="round" />
      </>
    );

  return (
    <svg
      viewBox="0 0 100 100"
      width={size}
      height={size}
      role={title ? "img" : undefined}
      aria-label={title}
      aria-hidden={title ? undefined : true}
    >
      <defs>
        <clipPath id={id}>
          <rect x="13" y="10" width="74" height="86" rx="19" />
        </clipPath>
      </defs>
      <rect x="13" y="10" width="74" height="86" rx="19" fill="#1C1C1E" />
      <rect x="0" y={top} width="100" height="100" fill={liquid} clipPath={`url(#${id})`} />
      <rect x="13" y="10" width="74" height="86" rx="19" fill="none" stroke="rgba(255,255,255,.32)" strokeWidth="2" />
      <rect x="38" y="3" width="24" height="5" rx="2.5" fill="rgba(255,255,255,.32)" />
      {face}
    </svg>
  );
}
