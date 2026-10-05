import c from "./Shared.module.css";

/** Small arrow that slides 2px on button hover. Decorative. */
export default function Arrow() {
  return (
    <svg className={c.arrow} width="14" height="14" viewBox="0 0 14 14" aria-hidden="true" focusable="false">
      <path d="M2 7h9M7.5 3L11.5 7l-4 4" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}
