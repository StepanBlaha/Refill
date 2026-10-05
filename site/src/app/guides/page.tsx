import Guide from "@/components/Guide";
import { pageMeta } from "@/lib/site";
import { SECTIONS } from "./data";

export const metadata = pageMeta({
  title: "Setup guides | Refill",
  description:
    "Step-by-step setup for Refill: Claude, Copilot, Cursor and Gemini accounts, ntfy, Pushover, Telegram, Discord, Slack, Home Assistant, Hue, WLED, webhooks, hooks, Shortcuts, dashboard and widgets.",
  path: "guides/",
});

export default function Page() {
  return <Guide sections={SECTIONS} />;
}
