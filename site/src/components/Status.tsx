import s from "./Status.module.css";

export type StatusKind = "success" | "warning" | "error";

/** One status message style for the whole site: green success, orange warning, red error. */
export default function Status({ kind, children }: { kind: StatusKind; children: React.ReactNode }) {
  return (
    <p className={`${s.status} ${s[kind]}`} role={kind === "error" ? "alert" : "status"}>
      <span className={s.dot} aria-hidden="true" />
      <span>{children}</span>
    </p>
  );
}
