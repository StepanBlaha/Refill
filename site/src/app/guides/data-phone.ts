import type { Section } from "./types";

const where = "Open Refill, then **Settings → Integrations → Add**";
const test = "Click **Send test**. Refill shows `OK 200` when the service accepted the request.";

export const phone: Section[] = [
  {
    id: "ntfy", title: "ntfy", group: "Phone and chat",
    intro: "Push notifications on your phone. Free, no account.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "Install the ntfy app on your phone ([iOS and Android](https://docs.ntfy.sh/subscribe/phone/)).",
        `${where} → **ntfy (phone push)**. Refill fills in a random topic like \`refill-1a2b3c4d\`.`,
        "In the ntfy app, tap **+** and subscribe to the same topic on the same server.",
      ] },
      { t: "p", x: "A topic on ntfy.sh works like a password. Anyone who knows the name can read and publish to it, so keep the random one." },
      { t: "h", x: "Fill in Refill" },
      { t: "fields", x: [
        ["Server", "`https://ntfy.sh`, or the URL of your own ntfy server. Leave it empty for ntfy.sh."],
        ["Topic", "The topic you subscribed to in the app. Required."],
        ["Access token (optional)", "A `tk_…` token, only if your server protects the topic. Sent as a Bearer token."],
      ] },
      { t: "h", x: "Send a test" },
      { t: "p", x: test },
      { t: "h", x: "What Refill sends" },
      { t: "p", x: "A JSON `POST` to the server root for tests, warnings and empty tanks, and for a reset when the Mac is awake. Priority is 4 for a reset and 3 for everything else. Tags are `zap`, `warning`, `battery` or `droplet` (test)." },
      { t: "code", title: "POST https://ntfy.sh", x: `{
  "message": "If you see this, the pipes work. Drip approves.",
  "priority": 3,
  "tags": ["droplet"],
  "title": "Testing, testing",
  "topic": "refill-1a2b3c4d"
}` },
      { t: "h", x: "Resets while the Mac sleeps or is off" },
      { t: "p", x: "With ntfy enabled and **Send on → Refill** on, Refill also posts a delayed message for each window that has been used and has a reset time. ntfy holds it and delivers it about 30 seconds after the reset, using the `At` header, even if the Mac is asleep or powered off. The message id is stable for that account and window (`refill-` plus a short hash of the account id and window). Publishing the same id again replaces the pending push, so a changed reset time does not leave a duplicate. Cancelling deletes that id." },
      { t: "p", x: "The access token stays in `~/.config/refill/integrations.json` on the Mac. Refill's note of what it scheduled is `~/.config/refill/ntfy-schedule.json` (mode 0600) and contains no token. The delayed body is the account's display name and the window, for example `Work: 5h session is full again.` The title is `Refilled`." },
      { t: "p", x: "ntfy.sh accepts a delay from 10 seconds up to 3 days. A weekly reset further out is scheduled once the Mac is awake inside that window. A limit that starts while the Mac is off is scheduled the next time Refill sees it." },
      { t: "p", x: "If the Mac is awake at the reset, Refill sends the normal ntfy message immediately and deletes the delayed one, so you get one push. If the Mac slept through delivery, the delayed push already went out, and the alert after wake does not send a second ntfy message. The local notification on wake still appears." },
      { t: "p", x: "If **Also mute phone and chat pushes** is on and the delivery hour falls inside quiet hours, that reset is not scheduled." },
      { t: "p", x: "An external script that posted the same ids is no longer needed. If you installed the LaunchAgent `local.refill.ntfy-schedule`, remove it so it does not publish a second copy:" },
      { t: "code", copy: true, x: "launchctl bootout gui/$(id -u)/local.refill.ntfy-schedule\nrm -f ~/Library/LaunchAgents/local.refill.ntfy-schedule.plist" },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "`HTTP 403`: the topic is protected. Add an access token.",
        "`OK 200` but no push: the topic in the app differs from the one in Refill. Compare them character by character.",
        "`Missing fields`: the Topic field is empty.",
      ] },
    ],
  },
  {
    id: "pushover", title: "Pushover", group: "Phone and chat",
    intro: "Push notifications on iPhone, Android and desktop through Pushover.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "Create an account at [pushover.net](https://pushover.net) and install the Pushover app on your phone. The app is paid after a trial, so check [their pricing](https://pushover.net/pricing).",
        "Copy **Your User Key** from the top of the Pushover dashboard.",
        "Go to [pushover.net/apps/build](https://pushover.net/apps/build), name the application `Refill` and create it. Copy the **API Token/Key**.",
        `${where} → **Pushover (phone push)**.`,
      ] },
      { t: "h", x: "Fill in Refill" },
      { t: "fields", x: [
        ["App token", "The API token of the application you just created."],
        ["User key", "Your user key. Not the app token."],
      ] },
      { t: "h", x: "Send a test" },
      { t: "p", x: test },
      { t: "h", x: "What Refill sends" },
      { t: "code", title: "POST https://api.pushover.net/1/messages.json (form encoded)", x: "token=APP_TOKEN&user=USER_KEY&title=Testing%2C%20testing&message=If%20you%20see%20this%2C%20the%20pipes%20work.%20Drip%20approves." },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "`HTTP 400` with `application token is invalid`: the app token is wrong, or you pasted the user key into it.",
        "`HTTP 400` with `user identifier is invalid`: the user key is wrong, or the two values are swapped.",
        "`OK 200` but no alert: the Pushover app has no device registered. Open it and sign in.",
      ] },
    ],
  },
  {
    id: "telegram", title: "Telegram", group: "Phone and chat",
    intro: "Messages from your own Telegram bot, in a private chat or a group.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "In Telegram, open [@BotFather](https://t.me/botfather) and send `/newbot`. Pick a name and a username ending in `bot`. BotFather replies with a token like `123456:ABC…`.",
        "Open your new bot, press **Start** and send it any message, for example `hi`.",
        "Open `https://api.telegram.org/bot<token>/getUpdates` in a browser, with your token in place of `<token>`. Find `\"chat\":{\"id\":123456789`. That number is your chat ID.",
        `${where} → **Telegram bot**.`,
      ] },
      { t: "p", x: "For a group, add the bot to the group, send a message there, and read the ID from `getUpdates`. Group IDs are negative, like `-1001234567890`. See the [Bot API docs](https://core.telegram.org/bots/api#getupdates)." },
      { t: "h", x: "Fill in Refill" },
      { t: "fields", x: [
        ["Bot token", "The token from BotFather."],
        ["Chat ID", "The number from `getUpdates`, including the minus sign for groups."],
      ] },
      { t: "h", x: "Send a test" },
      { t: "p", x: test },
      { t: "h", x: "What Refill sends" },
      { t: "code", title: "POST https://api.telegram.org/bot<token>/sendMessage", x: `{
  "chat_id": "123456789",
  "text": "Testing, testing\\nIf you see this, the pipes work. Drip approves."
}` },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "`getUpdates` returns an empty `result`: message the bot first, then reload.",
        "`HTTP 401`: the token is wrong. Copy it again from BotFather.",
        "`HTTP 400 chat not found`: wrong chat ID, or you never pressed Start.",
        "`HTTP 403`: you blocked the bot, or it was removed from the group.",
      ] },
    ],
  },
  {
    id: "discord", title: "Discord", group: "Phone and chat",
    intro: "An embed in a Discord channel, colored by event.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "In Discord, open **Server Settings → Integrations → Webhooks** and click **New Webhook**. You need the Manage Webhooks permission. See [Discord's guide](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks).",
        "Name it, choose the channel, and click **Copy Webhook URL**.",
        `${where} → **Discord**.`,
      ] },
      { t: "h", x: "Fill in Refill" },
      { t: "fields", x: [["Webhook URL", "`https://discord.com/api/webhooks/…`. Treat it like a password."]] },
      { t: "h", x: "Send a test" },
      { t: "p", x: "Click **Send test**. Discord answers with an empty success, so Refill shows `OK 204`." },
      { t: "h", x: "What Refill sends" },
      { t: "p", x: "The embed color is the event color as a number: 13172557 (green, reset and test), 16758087 (amber, warning), 16732220 (red, empty)." },
      { t: "code", title: "POST <your webhook URL>", x: `{
  "username": "Refill",
  "embeds": [{
    "title": "Testing, testing",
    "description": "If you see this, the pipes work. Drip approves.",
    "color": 13172557
  }]
}` },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "`HTTP 404`: the webhook was deleted. Create a new one.",
        "`HTTP 429`: Discord is rate limiting the webhook. Wait a minute.",
        "`Missing fields`: the URL is empty or not a full `https://` address.",
      ] },
    ],
  },
  {
    id: "slack", title: "Slack", group: "Phone and chat",
    intro: "A message in a Slack channel through an incoming webhook.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "Go to [api.slack.com/apps](https://api.slack.com/apps?new_app=1), click **Create New App**, choose **From scratch**, name it `Refill` and pick your workspace.",
        "Open **Incoming Webhooks** and switch **Activate Incoming Webhooks** on.",
        "Click **Add New Webhook to Workspace**, choose a channel and allow it. Copy the URL. Details are in [Slack's docs](https://docs.slack.dev/messaging/sending-messages-using-incoming-webhooks).",
        `${where} → **Slack**.`,
      ] },
      { t: "h", x: "Fill in Refill" },
      { t: "fields", x: [["Webhook URL", "`https://hooks.slack.com/services/…`. It contains a secret, so never commit it."]] },
      { t: "h", x: "Send a test" },
      { t: "p", x: test },
      { t: "h", x: "What Refill sends" },
      { t: "code", title: "POST <your webhook URL>", x: `{
  "text": "*Testing, testing*\\nIf you see this, the pipes work. Drip approves."
}` },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "`HTTP 404 no_service`: the webhook was revoked or the URL is incomplete. Slack revokes URLs it finds in public repositories.",
        "`HTTP 404 channel_not_found` or `channel_is_archived`: add the webhook again and pick a live channel.",
      ] },
    ],
  },
];
