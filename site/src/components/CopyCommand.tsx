"use client";

import { useEffect, useRef, useState } from "react";
import Status from "./Status";
import s from "./CopyCommand.module.css";

/** A command in a code block with a copy button. Feedback uses the shared Status component. */
export default function CopyCommand({ command, label }: { command: string; label: string }) {
  const [state, setState] = useState<"idle" | "ok" | "fail">("idle");
  const timer = useRef<number | undefined>(undefined);

  useEffect(() => () => window.clearTimeout(timer.current), []);

  const copy = async () => {
    window.clearTimeout(timer.current);
    try {
      if (!navigator.clipboard) throw new Error("no clipboard");
      await navigator.clipboard.writeText(command);
      setState("ok");
    } catch {
      setState("fail");
    }
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
