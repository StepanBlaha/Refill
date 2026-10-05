"use client";

import { useEffect, useRef, useState } from "react";
import Status from "./Status";
import s from "./CopyCommand.module.css";

/** A command in a code block with a copy button. Feedback uses the shared Status component. */
/** execCommand fallback for browsers without (or blocking) the async Clipboard API. */
function legacyCopy(text: string): boolean {
  const t = document.createElement("textarea");
  t.value = text;
  t.setAttribute("readonly", "");
  t.style.position = "fixed";
  t.style.opacity = "0";
  document.body.appendChild(t);
  t.select();
  let ok = false;
  try { ok = document.execCommand("copy"); } catch { ok = false; }
  t.remove();
  return ok;
}

export default function CopyCommand({ command, label }: { command: string; label: string }) {
  const [state, setState] = useState<"idle" | "ok" | "fail">("idle");
  const timer = useRef<number | undefined>(undefined);

  useEffect(() => () => window.clearTimeout(timer.current), []);

  const copy = async () => {
    window.clearTimeout(timer.current);
    let ok = false;
    try {
      if (!navigator.clipboard) throw new Error("no clipboard");
      // Some browsers leave writeText pending on a permission prompt; don't wait forever.
      await Promise.race([
        navigator.clipboard.writeText(command),
        new Promise((_, reject) => setTimeout(() => reject(new Error("timeout")), 1500)),
      ]);
      ok = true;
    } catch {
      ok = legacyCopy(command);
    }
    setState(ok ? "ok" : "fail");
    timer.current = window.setTimeout(() => setState("idle"), 3500);
  };

  return (
    <div className={s.wrap}>
      <div className={s.box}>
        <code className={s.cmd}>{command}</code>
        <button type="button" className={s.btn} onClick={copy} aria-label={`Copy ${label} command`}>
          <svg width="16" height="16" viewBox="0 0 16 16" aria-hidden="true" focusable="false">
            <rect x="5.5" y="5.5" width="8" height="8" rx="1.5" fill="none" stroke="currentColor" strokeWidth="1.6" />
            <path d="M10.5 3.5v-.5A1.5 1.5 0 009 1.5H3A1.5 1.5 0 001.5 3v6A1.5 1.5 0 003 10.5h.5" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
          </svg>
          Copy
        </button>
      </div>
      {state === "ok" && <Status kind="success">Copied to your clipboard.</Status>}
      {state === "fail" && (
        <Status kind="error">Could not copy. Select the command and copy it yourself.</Status>
      )}
    </div>
  );
}
