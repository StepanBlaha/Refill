import type { Section } from "./types";

export const tools: Section[] = [
  {
    id: "hook", title: "Shell hook", group: "Automation and display",
    intro: "Run your own script on every event: reset, warning, empty and test.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "Open `~/.config/refill/on-reset`. Refill creates a sample there on first launch. Create the file yourself if it is missing.",
        "Start it with a shebang such as `#!/bin/zsh`. Refill runs the file directly, not through a shell.",
        "Make it executable, then check **Settings → General → Hook script** is on.",
        "Click **Send test** in the same Settings tab to run it.",
      ] },
      { t: "code", copy: true, x: "chmod +x ~/.config/refill/on-reset" },
      { t: "p", x: "Refill runs from the Dock, so your shell's `PATH` is not set. Use full paths such as `/opt/homebrew/bin/…` for tools you install with Homebrew." },
      { t: "h", x: "What your script gets" },
      { t: "p", x: "The event JSON arrives on stdin, one line. These variables are set too." },
      { t: "table", head: ["Variable", "Value"], x: [
        ["`REFILL_KIND`", "`reset`, `warning`, `empty` or `test`"],
        ["`REFILL_TITLE`, `REFILL_MESSAGE`", "Drip's headline and message"],
        ["`REFILL_COLOR`", "Event color as hex, such as `#C8FF4D`"],
        ["`REFILL_PROVIDER`", "`claude`, `codex`, `copilot`, `cursor`, `gemini` or `test`"],
        ["`REFILL_ACCOUNT_ID`, `REFILL_ACCOUNT`", "Stable account ID and display name"],
        ["`REFILL_WINDOW`, `REFILL_WINDOW_LABEL`", "Window key (`five_hour`) and label (`5h session`)"],
        ["`REFILL_UTILIZATION`", "Percent used, whole number"],
        ["`REFILL_RESETS_AT`", "ISO 8601 time of the next reset, or empty"],
        ["`REFILL_REASON`", "`scheduled`, `observed`, `threshold` or `test`"],
      ] },
      { t: "h", x: "Example" },
      { t: "code", title: "~/.config/refill/on-reset", x: `#!/bin/zsh
case "$REFILL_KIND" in
  reset)
    /usr/bin/say "$REFILL_ACCOUNT is back"
    # Pick up where you left off
    cd ~/project && /opt/homebrew/bin/claude -p "continue the plan in TODO.md" >> ~/.config/refill/hook.log 2>&1 &
    ;;
  warning)
    /usr/bin/osascript -e "display notification \\"$REFILL_UTILIZATION% used\\" with title \\"$REFILL_ACCOUNT\\""
    ;;
  empty)
    /usr/bin/curl -s -d "$REFILL_ACCOUNT is empty" https://ntfy.sh/my-private-topic
    ;;
esac` },
      { t: "h", x: "Listen from other apps" },
      { t: "p", x: "Refill also posts a macOS distributed notification named `cz.stepanblaha.refill.reset` (or `.warning`, `.empty`, `.test`). The object is the account ID and the user info holds the same `REFILL_*` values. In Hammerspoon:" },
      { t: "code", x: `hs.distributednotifications.new(function(name, object, info)
  hs.alert.show(info.REFILL_MESSAGE)
end, "cz.stepanblaha.refill.reset"):start()` },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "Nothing runs: the file is not executable, the toggle is off, or the shebang is missing.",
        "Command not found: use full paths. Add `exec >> ~/.config/refill/hook.log 2>&1` at the top to log output. Refill drops stderr.",
        "Hooks run during quiet hours too. Only sound is muted.",
      ] },
    ],
  },
  {
    id: "shortcuts", title: "Shortcuts, URLs and CLI", group: "Automation and display",
    intro: "Ask Refill from Shortcuts, Siri, a link or a terminal.",
    blocks: [
      { t: "h", x: "Shortcuts and Siri" },
      { t: "p", x: "Open the Shortcuts app, create a shortcut, and search for **Refill**. Refill must be running." },
      { t: "table", head: ["Action", "Returns"], x: [
        ["Get Remaining Usage", "Percent left as a number, or -1 if unknown. Choose Provider (Claude, Codex, Any), Window (Session 5h, Week) and optional account email."],
        ["Get Refill Status", "The full status as JSON text."],
        ["Next Refill Time", "A date. Choose a Provider."],
        ["Refresh Usage", "Re-polls now."],
        ["Send Test Signal", "Fires a test to every enabled integration."],
      ] },
      { t: "p", x: "Siri phrases: \"How much Claude is left in Refill\", \"When does Refill refill\", \"Refresh Refill\" and \"Test Refill signal\"." },
      { t: "h", x: "URL scheme" },
      { t: "table", head: ["URL", "Does"], x: [
        ["`refill://refresh`", "Re-poll now"],
        ["`refill://test`", "Send a test signal"],
        ["`refill://open`, `dashboard`, `settings`, `history`, `onboarding`", "Open that window"],
        ["`refill://status?x-success=URL&x-error=URL`", "Opens `x-success` with `remaining` and `json` added, or `x-error` with `errorMessage` if there is no data"],
      ] },
      { t: "code", copy: true, x: "open refill://test" },
      { t: "h", x: "Command line" },
      { t: "p", x: "`scripts/refill` in the repo reads `~/.config/refill/status.json` and needs `python3`. Copy it somewhere on your `PATH`." },
      { t: "code", x: `refill status        # table of accounts and windows
refill left claude   # percent left in the 5h session
refill json          # raw status.json
refill open test     # any refill:// route` },
      { t: "p", x: "Files: `~/.config/refill/status.json` is the live status and `events.jsonl` holds one JSON line per event." },
    ],
  },
  {
    id: "dashboard", title: "Local dashboard", group: "Automation and display",
    intro: "A web page with your tanks, for a browser tab or your phone.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "Open **Settings → General → Dashboard** and click **Open**. It loads `http://127.0.0.1:7788` and only this Mac can reach it.",
        "For your phone, turn on **Visible on Wi-Fi**. Open the address shown in Settings (your Mac name plus `.local` and `:7788`) in your phone's browser. Add it to the Home Screen if you like.",
        "If macOS asks to allow incoming connections, allow it.",
      ] },
      { t: "p", x: "The page is read-only and has no password. Anyone on the same Wi-Fi can open it while **Visible on Wi-Fi** is on, so use it on networks you trust." },
      { t: "h", x: "Change the port" },
      { t: "p", x: "The default is 7788. Change it in **Settings → General → Dashboard → Port** and press Return; the dashboard restarts on the new port." },
      { t: "h", x: "JSON endpoints" },
      { t: "ul", x: [
        "`/status` is the same JSON as `status.json`.",
        "`/events` lists recent events.",
        "Both allow cross-origin reads, so a page or a Home Assistant sensor can fetch them.",
      ] },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "Phone cannot connect: same Wi-Fi? Some guest and office networks block devices from each other. Try the Mac's IP address instead of the `.local` name.",
        "Port in use: pick another with the command above.",
      ] },
    ],
  },
  {
    id: "widgets", title: "Widgets", group: "Automation and display",
    intro: "Small, medium and large desktop widgets with the tanks and Drip.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "Keep Refill in `/Applications` and open it once.",
        "Right-click the desktop and choose **Edit Widgets** (or open Notification Center and scroll to **Edit Widgets**).",
        "Search for **Refill**, pick a size and add it.",
      ] },
      { t: "p", x: "The app writes a snapshot that the widget reads, so keep Refill running. The widget refreshes every 15 minutes, and right after the next known reset." },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "Refill is missing from the gallery: quit and reopen Refill, then try again. macOS finds widgets after the app has launched.",
        "Empty widget: open Refill so it can write fresh data. Check that your accounts show up in the menu bar.",
      ] },
    ],
  },
  {
    id: "quiet-hours", title: "Quiet hours and thresholds", group: "Alerts",
    intro: "Decide when Refill stays silent and when it warns you.",
    blocks: [
      { t: "h", x: "Quiet hours" },
      { t: "ol", x: [
        "Open **Settings → General → Quiet hours** and switch it on.",
        "Choose **From** and **to** hours. The default is 22:00 to 08:00 and it can cross midnight.",
        "Optional: turn on **Also mute phone and chat pushes**.",
      ] },
      { t: "table", head: ["Output", "During quiet hours"], x: [
        ["Sound", "Muted"],
        ["Notification and notch", "Still shown"],
        ["Shell hook", "Still runs"],
        ["Home Assistant, Hue, WLED, custom webhook", "Still fire"],
        ["ntfy, Pushover, Telegram, Discord, Slack", "Fire, unless you turn on the mute option. A delayed ntfy reset whose delivery hour is inside quiet hours is not scheduled when that option is on."],
      ] },
      { t: "h", x: "Warning thresholds" },
      { t: "p", x: "Under **Settings → General → Usage**, **Warn at** takes used percentages separated by commas. The default is `80, 95`. Values must be above 0 and below 100. An empty alert always goes out at 100%. **Check every** sets how often Refill polls, from 1 to 60 minutes (default 5)." },
      { t: "p", x: "Each integration has its own **Send on** switches for Refill (reset), Warning and Empty. Turn off Warning on a chat channel if you only want resets there." },
    ],
  },
  {
    id: "troubleshooting", title: "Troubleshooting", group: "Alerts",
    intro: "Quick checks for when something stays quiet.",
    blocks: [
      { t: "h", x: "Integration status messages" },
      { t: "table", head: ["Message", "Meaning"], x: [
        ["`OK 200`", "The service accepted the request. Some services use another 2xx code."],
        ["`HTTP 4xx …`", "The service refused it. The first 80 characters of its reply follow."],
        ["`Missing fields`", "A required field is empty or the URL is not a full address."],
        ["Any other text", "A network error, often a timeout after 10 seconds."],
      ] },
      { t: "h", x: "Checks" },
      { t: "ul", x: [
        "Use **Send test** on the integration first. It tests one service. **Settings → General → Send test** fires every output.",
        "Check the integration is switched on and the right **Send on** toggles are enabled.",
        "Look at `~/.config/refill/events.jsonl` to see which events fired.",
        "Settings live in `~/.config/refill`. `integrations.json` holds your tokens and is readable only by you. Do not share it.",
        "A reset is detected when a known reset time passes after use, or when a poll sees the time jump forward. The menu, the notch and most integrations need Refill running. An ntfy reset that Refill already scheduled still arrives if the Mac is asleep or off. See the ntfy guide.",
      ] },
      { t: "h", x: "Updates and installs" },
      { t: "p", x: "Refill checks GitHub Releases daily. Use **Settings → General → About → Check now**. Replacing the app keeps `~/.config/refill`. Refill is not notarized, so on first launch use **System Settings → Privacy & Security → Open Anyway**, or install with Homebrew or the one-line installer described in the [README](https://github.com/StepanBlaha/Refill#install)." },
      { t: "p", x: "Still stuck? [Open an issue](https://github.com/StepanBlaha/Refill/issues) and leave tokens out." },
    ],
  },
];
