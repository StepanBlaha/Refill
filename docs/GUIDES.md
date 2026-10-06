# Refill setup guides

Step-by-step setup for everything in Refill that needs configuring. The same guides live at https://stepanblaha.github.io/Refill/guides/.

## Contents

**Sources:** [Accounts](#accounts), [GitHub Copilot](#copilot), [Cursor](#cursor), [Gemini CLI](#gemini)

**Phone and chat:** [ntfy](#ntfy), [Pushover](#pushover), [Telegram](#telegram), [Discord](#discord), [Slack](#slack)

**Lights and webhooks:** [Home Assistant](#homeassistant), [Philips Hue](#hue), [WLED](#wled), [Custom webhook](#webhook)

**Automation and display:** [Shell hook](#hook), [Shortcuts, URLs and CLI](#shortcuts), [Local dashboard](#dashboard), [Widgets](#widgets)

**Alerts:** [Quiet hours and thresholds](#quiet-hours), [Troubleshooting](#troubleshooting)

<a id="accounts"></a>

## Accounts

**What you get.** Refill finds the Claude Code, Codex, Copilot and Gemini logins already on your Mac, and you can add more. Cursor stays one login. You can rename any of them.

### What Refill finds on its own

- Claude Code: the default `~/.claude` and every `~/.claude-*` and `~/.claude_*` folder. Each folder is one login.
- Codex CLI: `~/.codex` (this keeps the account id `codex:default`), the folder in `CODEX_HOME` when that is different, and every `~/.codex-*` and `~/.codex_*` folder. Each home is read from the ChatGPT login already in that folder (`auth.json`, or the Keychain item `Codex Auth`). Turn every Codex home off with **Settings → Accounts → Codex CLI**.
- The Copilot, Cursor and Gemini sections below cover those tools.

### Add a second Claude account

1. Open **Settings → Accounts**. Under **Add a Claude account**, type a name such as `work`, then click **Add**. Use letters, digits, `-` and `_`.
2. Terminal opens with a separate Claude profile in `~/.claude-work`. Type `/login` and finish signing in.
3. Type `/exit`, close the window, and click **Refresh** in Refill. The account appears under **Detected**.

From a clone of the repo you can do the same in a terminal. It sets `CLAUDE_CONFIG_DIR` and starts Claude Code.

```bash
scripts/add-claude-account.sh work
```

To use that account later, run Claude Code with its folder:

```bash
alias claude-work='CLAUDE_CONFIG_DIR=$HOME/.claude-work claude'
```

### Add a second Codex account

1. Under **Codex CLI**, type a name such as `work`, then click **Add**.
2. Terminal opens with `CODEX_HOME` set to `~/.codex-work` and runs `codex login`. That login is what Refill reads.
3. Quit Codex, close the window, and click **Refresh**.

```bash
scripts/add-codex-account.sh work
```

```bash
alias codex-work='CODEX_HOME=$HOME/.codex-work codex'
```

The default `~/.codex` stays `codex:default` even when `CODEX_HOME` points at it, so history and hidden accounts from older Refill builds still match. A `~/.codex-*` folder with no sessions is hidden until you log in, unless you list it under **Extra Codex folders**. The Add button writes that path for you.

### Folders outside the automatic names

Put one path per line in **Extra Claude folders**, **Extra Codex folders**, or **Extra Gemini folders**. `~` is fine.

### Rename an account

Click **⋯** next to an account (or right-click it) and choose **Rename…**. The name is stored for that account id and shown in the menu, the notch, the dashboard, widgets, history and notifications. Leave it blank and save to go back to the email, then the folder name.

### Hide, show or remove an account

- **Hide from Refill** skips that account. It is not checked and never alerts. This works for Claude, Codex, Copilot, Gemini and Cursor. Bring one back under **Hidden → Show**. There is no separate mute: hide is how you silence one account.
- **Move profile to Trash…** is offered for extra Claude, Codex and Gemini profile folders. It signs that profile out on this Mac and can be undone from the Trash. The default `~/.claude`, `~/.codex` and `~/.gemini` are never offered. Copilot and Cursor have no profile folder to trash.

### If it fails

- `Not signed in. Run claude and type /login.`: that profile has no login. Do the Claude steps above.
- `Login expired. Run claude once to renew it.`: run Claude Code once in that profile. Or turn on **Settings → Accounts → Renew expired logins** so Refill renews it. Leave it off if Claude Code runs all day.
- `Rate limited. Next try at …`: Refill pauses that account after an HTTP 429 and retries by itself.
- `No Codex login. Run codex login in this home.`: that folder has no ChatGPT login. Run `codex login` there (or the Add steps above). An API key alone is not enough.
- `Login expired. Run codex login in this home.`: run `codex login` again in that home. Or turn on **Settings → Accounts → Renew expired logins** so Refill renews it. The first time Refill reads a Keychain login, macOS may ask to allow access to `Codex Auth`.
- A Codex row shows **—** and **last seen**: the live usage request failed, and the newest session log's window has already ended. Refill will not draw that old log as a full tank. Sign in, then click **Refresh**.

<a id="copilot"></a>

## GitHub Copilot

**What you get.** Monthly premium-request and chat quota for every GitHub login that has a Copilot seat.

### Steps

1. Install the GitHub CLI and sign in with each account that has Copilot. `gh auth login` adds another login. `gh auth status` lists them.
2. Refill reads each `github.com` login with `gh auth token --user <login>`. The first login it tracks stays `copilot:default`, so switching the active `gh` user does not reshuffle history. Other logins are `copilot:<login>`.
3. Check **Settings → Accounts → More providers → GitHub Copilot** is on. Click **Refresh**.

```bash
brew install gh
```

```bash
gh auth login
```

If `gh` has no `github.com` login, Refill falls back to the single editor token in `~/.config/github-copilot` (`apps.json` or `hosts.json`) as `copilot:default`. Enterprise hosts are ignored. The Copilot editor itself is one login. Usage resets monthly. The endpoint is unofficial and can change.

### If it fails

- `No GitHub token (run gh auth login)`: sign in with the command above.
- `No GitHub token for <login>`: that login has no token. Run `gh auth login` again for it.
- `HTTP 401` or `403 (token rejected or no Copilot seat)`: that GitHub account has no Copilot seat. Check with `gh auth status`. Hide the row if you do not want it listed.

<a id="cursor"></a>

## Cursor

**What you get.** Monthly usage for the Cursor plan signed in on this Mac, with no extra login.

### Steps

1. Install the Cursor app and sign in to it.
2. Check **Settings → Accounts → More providers → Cursor** is on. Click **Refresh**.

Refill reads the sign-in from Cursor's local database, `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`, in read-only mode. It then asks cursor.com for your usage. The billing cycle end is the reset.

Cursor stores one login per Mac user. Refill does not invent a second Cursor account. A second person needs their own macOS user, or you switch the login inside Cursor (that replaces the one Refill shows, id `cursor:default`). You can still rename or hide it.

### If it fails

- `Not signed in to Cursor`: open Cursor and sign in.
- `HTTP 401` or `403 (session expired, reopen Cursor)`: open Cursor so it renews its session.
- Cursor missing from the list: Refill skips it when the database file does not exist.

<a id="gemini"></a>

## Gemini CLI

**What you get.** Per-model quota for every Gemini CLI login, with Pro and Flash tracked separately.

### Steps

1. Install Gemini CLI, run it once and sign in with Google. The default login is `~/.gemini/oauth_creds.json`, and that account stays `gemini:default`.
2. Check **Settings → Accounts → More providers → Gemini CLI** is on. Click **Refresh**.

```bash
npm install -g @google/gemini-cli
```

```bash
gemini
```

### Add another Gemini account

Gemini CLI treats `GEMINI_CLI_HOME` as a home directory and writes creds to `$GEMINI_CLI_HOME/.gemini/oauth_creds.json`, not to the home itself.

1. Under **Add a Gemini account**, type a name such as `work`, then click **Add**.
2. Terminal opens with `GEMINI_CLI_HOME` set to `~/.gemini-accounts/work`. Sign in, then exit.
3. Click **Refresh**. The login lives at `~/.gemini-accounts/work/.gemini/oauth_creds.json`.

```bash
scripts/add-gemini-account.sh work
```

```bash
alias gemini-work='GEMINI_CLI_HOME=$HOME/.gemini-accounts/work gemini'
```

A folder you already use can be listed under **Extra Gemini folders**. Point it at the directory that contains `oauth_creds.json`, or at a `GEMINI_CLI_HOME` whose `.gemini` child contains that file. `~/.gemini-*` and `~/.gemini_*` folders in your home directory are picked up on their own when they hold creds.

When the saved token expires, Refill refreshes it in memory and never writes it back. It needs the installed CLI to find the public OAuth client, or you can set `GEMINI_OAUTH_CLIENT_ID` and `GEMINI_OAUTH_CLIENT_SECRET`. The client is shared. Each account keeps its own token.

### If it fails

- `No Gemini CLI login`: run `gemini` and sign in.
- `Gemini token refresh failed (run gemini once)`: run `gemini` once so it renews its own login, then refresh.
- `Quota request failed`: Google rejected the request. Try again later.

<a id="ntfy"></a>

## ntfy

**What you get.** Push notifications on your phone. Free, no account.

### Steps

1. Install the ntfy app on your phone ([iOS and Android](https://docs.ntfy.sh/subscribe/phone/)).
2. Open Refill, then **Settings → Integrations → Add** → **ntfy (phone push)**. Refill fills in a random topic like `refill-1a2b3c4d`.
3. In the ntfy app, tap **+** and subscribe to the same topic on the same server.

A topic on ntfy.sh works like a password. Anyone who knows the name can read and publish to it, so keep the random one.

### Fill in Refill

| Field in Refill | What to enter |
|---|---|
| **Server** | `https://ntfy.sh`, or the URL of your own ntfy server. Leave it empty for ntfy.sh. |
| **Topic** | The topic you subscribed to in the app. Required. |
| **Access token (optional)** | A `tk_…` token, only if your server protects the topic. Sent as a Bearer token. |

### Send a test

Click **Send test**. Refill shows `OK 200` when the service accepted the request.

### What Refill sends

A JSON `POST` to the server root for tests, warnings and empty tanks, and for a reset when the Mac is awake. Priority is 4 for a reset and 3 for everything else. Tags are `zap`, `warning`, `battery` or `droplet` (test).

### Resets while the Mac sleeps or is off

With ntfy enabled and **Send on → Refill** on, Refill also posts a delayed message for each window that has been used and has a reset time. ntfy holds it and delivers it about 30 seconds after the reset, using the `At` header, even if the Mac is asleep or powered off. The message id is stable for that account and window (`refill-` plus a short hash of the account id and window). Publishing the same id again replaces the pending push, so a changed reset time does not leave a duplicate. Cancelling deletes that id.

The access token stays in `~/.config/refill/integrations.json` on the Mac. Refill's note of what it scheduled is `~/.config/refill/ntfy-schedule.json` (mode 0600) and contains no token. The delayed body is the account's display name and the window, for example `Work: 5h session is full again.` The title is `Refilled`.

ntfy.sh accepts a delay from 10 seconds up to 3 days. A weekly reset further out is scheduled once the Mac is awake inside that window. A limit that starts while the Mac is off is scheduled the next time Refill sees it.

If the Mac is awake at the reset, Refill sends the normal ntfy message immediately and deletes the delayed one, so you get one push. If the Mac slept through delivery, the delayed push already went out, and the alert after wake does not send a second ntfy message. The local notification on wake still appears.

If **Also mute phone and chat pushes** is on and the delivery hour falls inside quiet hours, that reset is not scheduled.

An external script that posted the same ids is no longer needed. If you installed the LaunchAgent `local.refill.ntfy-schedule`, remove it so it does not publish a second copy:

```bash
launchctl bootout gui/$(id -u)/local.refill.ntfy-schedule
rm -f ~/Library/LaunchAgents/local.refill.ntfy-schedule.plist
```

*POST https://ntfy.sh*

```json
{
  "message": "If you see this, the pipes work. Drip approves.",
  "priority": 3,
  "tags": ["droplet"],
  "title": "Testing, testing",
  "topic": "refill-1a2b3c4d"
}
```

### If it fails

- `HTTP 403`: the topic is protected. Add an access token.
- `OK 200` but no push: the topic in the app differs from the one in Refill. Compare them character by character.
- `Missing fields`: the Topic field is empty.

<a id="pushover"></a>

## Pushover

**What you get.** Push notifications on iPhone, Android and desktop through Pushover.

### Steps

1. Create an account at [pushover.net](https://pushover.net) and install the Pushover app on your phone. The app is paid after a trial, so check [their pricing](https://pushover.net/pricing).
2. Copy **Your User Key** from the top of the Pushover dashboard.
3. Go to [pushover.net/apps/build](https://pushover.net/apps/build), name the application `Refill` and create it. Copy the **API Token/Key**.
4. Open Refill, then **Settings → Integrations → Add** → **Pushover (phone push)**.

### Fill in Refill

| Field in Refill | What to enter |
|---|---|
| **App token** | The API token of the application you just created. |
| **User key** | Your user key. Not the app token. |

### Send a test

Click **Send test**. Refill shows `OK 200` when the service accepted the request.

### What Refill sends

*POST https://api.pushover.net/1/messages.json (form encoded)*

```bash
token=APP_TOKEN&user=USER_KEY&title=Testing%2C%20testing&message=If%20you%20see%20this%2C%20the%20pipes%20work.%20Drip%20approves.
```

### If it fails

- `HTTP 400` with `application token is invalid`: the app token is wrong, or you pasted the user key into it.
- `HTTP 400` with `user identifier is invalid`: the user key is wrong, or the two values are swapped.
- `OK 200` but no alert: the Pushover app has no device registered. Open it and sign in.

<a id="telegram"></a>

## Telegram

**What you get.** Messages from your own Telegram bot, in a private chat or a group.

### Steps

1. In Telegram, open [@BotFather](https://t.me/botfather) and send `/newbot`. Pick a name and a username ending in `bot`. BotFather replies with a token like `123456:ABC…`.
2. Open your new bot, press **Start** and send it any message, for example `hi`.
3. Open `https://api.telegram.org/bot<token>/getUpdates` in a browser, with your token in place of `<token>`. Find `"chat":{"id":123456789`. That number is your chat ID.
4. Open Refill, then **Settings → Integrations → Add** → **Telegram bot**.

For a group, add the bot to the group, send a message there, and read the ID from `getUpdates`. Group IDs are negative, like `-1001234567890`. See the [Bot API docs](https://core.telegram.org/bots/api#getupdates).

### Fill in Refill

| Field in Refill | What to enter |
|---|---|
| **Bot token** | The token from BotFather. |
| **Chat ID** | The number from `getUpdates`, including the minus sign for groups. |

### Send a test

Click **Send test**. Refill shows `OK 200` when the service accepted the request.

### What Refill sends

*POST https://api.telegram.org/bot<token>/sendMessage*

```json
{
  "chat_id": "123456789",
  "text": "Testing, testing\nIf you see this, the pipes work. Drip approves."
}
```

### If it fails

- `getUpdates` returns an empty `result`: message the bot first, then reload.
- `HTTP 401`: the token is wrong. Copy it again from BotFather.
- `HTTP 400 chat not found`: wrong chat ID, or you never pressed Start.
- `HTTP 403`: you blocked the bot, or it was removed from the group.

<a id="discord"></a>

## Discord

**What you get.** An embed in a Discord channel, colored by event.

### Steps

1. In Discord, open **Server Settings → Integrations → Webhooks** and click **New Webhook**. You need the Manage Webhooks permission. See [Discord's guide](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks).
2. Name it, choose the channel, and click **Copy Webhook URL**.
3. Open Refill, then **Settings → Integrations → Add** → **Discord**.

### Fill in Refill

| Field in Refill | What to enter |
|---|---|
| **Webhook URL** | `https://discord.com/api/webhooks/…`. Treat it like a password. |

### Send a test

Click **Send test**. Discord answers with an empty success, so Refill shows `OK 204`.

### What Refill sends

The embed color is the event color as a number: 13172557 (green, reset and test), 16758087 (amber, warning), 16732220 (red, empty).

*POST <your webhook URL>*

```json
{
  "username": "Refill",
  "embeds": [{
    "title": "Testing, testing",
    "description": "If you see this, the pipes work. Drip approves.",
    "color": 13172557
  }]
}
```

### If it fails

- `HTTP 404`: the webhook was deleted. Create a new one.
- `HTTP 429`: Discord is rate limiting the webhook. Wait a minute.
- `Missing fields`: the URL is empty or not a full `https://` address.

<a id="slack"></a>

## Slack

**What you get.** A message in a Slack channel through an incoming webhook.

### Steps

1. Go to [api.slack.com/apps](https://api.slack.com/apps?new_app=1), click **Create New App**, choose **From scratch**, name it `Refill` and pick your workspace.
2. Open **Incoming Webhooks** and switch **Activate Incoming Webhooks** on.
3. Click **Add New Webhook to Workspace**, choose a channel and allow it. Copy the URL. Details are in [Slack's docs](https://docs.slack.dev/messaging/sending-messages-using-incoming-webhooks).
4. Open Refill, then **Settings → Integrations → Add** → **Slack**.

### Fill in Refill

| Field in Refill | What to enter |
|---|---|
| **Webhook URL** | `https://hooks.slack.com/services/…`. It contains a secret, so never commit it. |

### Send a test

Click **Send test**. Refill shows `OK 200` when the service accepted the request.

### What Refill sends

*POST <your webhook URL>*

```json
{
  "text": "*Testing, testing*\nIf you see this, the pipes work. Drip approves."
}
```

### If it fails

- `HTTP 404 no_service`: the webhook was revoked or the URL is incomplete. Slack revokes URLs it finds in public repositories.
- `HTTP 404 channel_not_found` or `channel_is_archived`: add the webhook again and pick a live channel.

<a id="homeassistant"></a>

## Home Assistant

**What you get.** Any light Home Assistant can control turns the color of the event.

### Steps

1. Make sure your Mac can open Home Assistant, for example `http://homeassistant.local:8123`.
2. In Home Assistant, go to **Settings → Automations & Scenes → Create automation → Create new automation**. Open the three-dot menu and choose **Edit in YAML**.
3. Paste the automation below. Replace `light.living_room` with your light. Find its ID under **Settings → Devices & services → Entities**. Save.
4. Open Refill, then **Settings → Integrations → Add** → **Home Assistant (any lights)**.

*automation.yaml (Home Assistant 2024.10 or newer)*

```yaml
alias: Refill light
description: Color a light with the Refill event color
mode: restart
triggers:
  - trigger: webhook
    webhook_id: refill
    allowed_methods:
      - POST
    local_only: true
actions:
  - action: light.turn_on
    target:
      entity_id: light.living_room
    data:
      rgb_color: "{{ trigger.json.rgb }}"
      brightness: 255
      flash: long
```

This works with any light brand Home Assistant supports: Hue, IKEA, LIFX, Nanoleaf, Zigbee, Tuya and more. The light must support color. For a white-only bulb, drop `rgb_color`. On older Home Assistant, use `platform: webhook` and `service: light.turn_on`. See the [webhook trigger docs](https://www.home-assistant.io/docs/automation/trigger/#webhook-trigger).

The webhook ID acts like a password. If others share your network, pick a longer ID than `refill` in both places. To react differently per event, branch on `trigger.json.kind` (`reset`, `warning`, `empty`, `test`).

### Fill in Refill

| Field in Refill | What to enter |
|---|---|
| **HA URL** | `http://homeassistant.local:8123`, or its IP. No trailing slash. |
| **Webhook ID** | `refill`, the same as `webhook_id` in the automation. |

### Send a test

Click **Send test**. The light should turn lime green. Home Assistant answers `200` even when no automation matches, so a missing reaction means checking the automation.

### What Refill sends

Event colors: reset and test `#C8FF4D` (200, 255, 77), warning `#FFB547` (255, 181, 71), empty `#FF503C` (255, 80, 60). `r`, `g`, `b` and `utilization` are strings. `rgb` is a list of numbers.

*POST http://homeassistant.local:8123/api/webhook/refill*

```json
{
  "account": "Refill",
  "b": "77",
  "color": "#C8FF4D",
  "g": "255",
  "kind": "test",
  "message": "If you see this, the pipes work. Drip approves.",
  "r": "200",
  "rgb": [200, 255, 77],
  "title": "Testing, testing",
  "utilization": "100",
  "window": "5h session"
}
```

### If it fails

- Nothing happens: open the automation, then **Traces** from the three-dot menu. No trace means the webhook ID differs.
- Trace shows an error on `rgb_color`: the entity is not a color light.
- Connection errors: the URL is wrong, or the Mac is not on the same network. `local_only: true` rejects requests from outside your network.

<a id="hue"></a>

## Philips Hue

**What you get.** Your Hue lights flash green, amber or red straight from the bridge, no cloud.

### Steps

1. Find the bridge IP. Check the bridge details in the Hue app, your router, or [discovery.meethue.com](https://discovery.meethue.com).
2. Press the round link button on the bridge. Within 30 seconds, run the command below. It prints `[{"success":{"username":"…"}}]`. Copy the username. If you get `link button not pressed`, press the button and run it again.
3. List your rooms with the second command. Each key (`1`, `2`…) is a group ID with a `name`. Use `0` for all lights.
4. Open Refill, then **Settings → Integrations → Add** → **Philips Hue**.

```bash
curl -X POST http://BRIDGE_IP/api -d '{"devicetype":"refill#mac"}'
```

```bash
curl http://BRIDGE_IP/api/USERNAME/groups
```

Refill uses the local Hue API v1 over plain HTTP. Hue has marked it legacy, but bridges still answer it. See the [Hue getting started guide](https://developers.meethue.com/develop/get-started-2/).

### Fill in Refill

| Field in Refill | What to enter |
|---|---|
| **Bridge IP** | For example `192.168.1.20`. Give the bridge a fixed address in your router. |
| **API username** | The username from step 2. |
| **Group / room ID** | A group ID from step 3. Empty or `0` means all lights. |

### Send a test

Click **Send test**. The lights turn green and breathe for 15 seconds. Hue answers `200` even for errors, so judge by the lights, not the status.

### What Refill sends

Color is CIE `xy`: reset and test `[0.3, 0.6]`, warning `[0.55, 0.41]`, empty `[0.675, 0.322]`. Warning uses `alert: select` (one pulse). Everything else uses `lselect` (15 seconds).

*PUT http://BRIDGE_IP/api/USERNAME/groups/0/action*

```json
{
  "alert": "lselect",
  "bri": 254,
  "on": true,
  "xy": [0.3, 0.6]
}
```

### If it fails

- `OK 200` but dark lights: the bridge replied `unauthorized user` (wrong username) or `resource not available` (wrong group). Repeat the group command with curl to see the reply.
- Timeout: the IP changed, or the Mac is on another network or VLAN.
- `Missing fields`: Bridge IP or API username is empty.

<a id="wled"></a>

## WLED

**What you get.** A WLED strip flashes the event color, or runs a preset you made for resets.

### Steps

1. Find the host. Try `wled.local`, or use the IP from your router or the WLED app.
2. Optional: open the WLED web page, set a color and effect you like, open **Presets**, save it to a slot and note its number. The ID is the slot number. See [the JSON API docs](https://kno.wled.ge/interfaces/json-api/).
3. Open Refill, then **Settings → Integrations → Add** → **WLED strip**.

### Fill in Refill

| Field in Refill | What to enter |
|---|---|
| **Host** | `wled.local` or an IP. Refill adds `http://` for you. |
| **Preset ID for reset (optional)** | For example `3`. Leave empty to use the plain green breathing effect. |

### Send a test

Click **Send test**. The strip turns lime and breathes. A test never runs your preset, only a real reset does.

### What Refill sends

Warning breathes amber (effect 2). Empty is solid red (effect 0). A reset with a preset ID sends the preset instead.

*POST http://wled.local/json/state*

```json
{
  "bri": 255,
  "on": true,
  "seg": [{ "col": [[200, 255, 77]], "fx": 2 }]
}
```

*Reset with Preset ID 3*

```json
{ "on": true, "ps": 3 }
```

### If it fails

- Cannot resolve `wled.local`: use the IP address. Not every network supports `.local` names.
- Preset does nothing: the slot is empty. Save the preset again and check the number.
- Timeout: the strip is off the Wi-Fi or on another network.

<a id="webhook"></a>

## Custom webhook

**What you get.** Call any HTTP endpoint with a body you shape yourself.

### Steps

1. Open Refill, then **Settings → Integrations → Add** → **Custom webhook**. Method starts as `POST`.
2. Enter the URL. Add headers if the service needs them. Write a body template, or leave it empty to send the event JSON.
3. Click **Send test**.

### Fill in Refill

| Field in Refill | What to enter |
|---|---|
| **URL** | A full `https://` or `http://` address. Placeholders do not work here. |
| **Method** | `POST` by default. `GET` sends no body. |
| **Headers (Key: Value per line)** | For example `Authorization: Bearer abc`. `Content-Type: application/json` is set for you. |
| **Body template (empty = event JSON)** | Text with placeholders from the table. Empty sends the event JSON. |

### Placeholders

Refill replaces these in the body as plain text. It does not escape quotes, so keep them out of names.

| Placeholder | Value | Example |
|---|---|---|
| `{{kind}}` | Event type | `reset`, `warning`, `empty`, `test` |
| `{{title}}` | Headline | `Testing, testing` |
| `{{message}}` | Message text | `If you see this, the pipes work. Drip approves.` |
| `{{account}}` | Account name | `Refill` |
| `{{window}}` | Window label | `5h session` |
| `{{utilization}}` | Percent used, whole number | `100` |
| `{{color}}` | Event color as hex | `#C8FF4D` |
| `{{r}}` `{{g}}` `{{b}}` | Event color, 0 to 255 each | `200` `255` `77` |
| `{{json}}` | The whole event as JSON | see below |

Event colors: reset and test `#C8FF4D` (200, 255, 77), warning `#FFB547` (255, 181, 71), empty `#FF503C` (255, 80, 60).

*Default body (the {{json}} value)*

```json
{"accountId":"test","accountName":"Refill","detectedAt":"2026-10-05T09:30:00Z","kind":"test","message":"If you see this, the pipes work. Drip approves.","provider":"test","reason":"test","title":"Testing, testing","utilization":100,"window":"five_hour","windowLabel":"5h session"}
```

### Example: IFTTT or Zapier

Create an [IFTTT Webhooks](https://ifttt.com/maker_webhooks) trigger, or a Zapier **Catch Hook**, and use its URL. IFTTT expects `value1` to `value3`.

*URL: https://maker.ifttt.com/trigger/refill/with/key/YOUR_KEY*

```json
{"value1":"{{kind}}","value2":"{{message}}","value3":"{{color}}"}
```

### Example: a light controller

Works for a Node-RED flow, an ESPHome or Shelly-style device, or your own server that takes JSON. Adjust the URL and field names to what yours expects.

*PUT http://192.168.1.50/api/light + header Authorization: Bearer YOUR_TOKEN*

```json
{"on":true,"rgb":[{{r}},{{g}},{{b}}],"label":"{{kind}}"}
```

### If it fails

- `HTTP 400` or `422`: the body is not valid JSON for that service. Test the same body with curl.
- `HTTP 401` or `403`: add or fix the `Authorization` header.
- A `GET` does nothing useful: Refill sends no body and does not fill the URL. Use `POST`.

<a id="hook"></a>

## Shell hook

**What you get.** Run your own script on every event: reset, warning, empty and test.

### Steps

1. Open `~/.config/refill/on-reset`. Refill creates a sample there on first launch. Create the file yourself if it is missing.
2. Start it with a shebang such as `#!/bin/zsh`. Refill runs the file directly, not through a shell.
3. Make it executable, then check **Settings → General → Hook script** is on.
4. Click **Send test** in the same Settings tab to run it.

```bash
chmod +x ~/.config/refill/on-reset
```

Refill runs from the Dock, so your shell's `PATH` is not set. Use full paths such as `/opt/homebrew/bin/…` for tools you install with Homebrew.

### What your script gets

The event JSON arrives on stdin, one line. These variables are set too.

| Variable | Value |
|---|---|
| `REFILL_KIND` | `reset`, `warning`, `empty` or `test` |
| `REFILL_TITLE`, `REFILL_MESSAGE` | Drip's headline and message |
| `REFILL_COLOR` | Event color as hex, such as `#C8FF4D` |
| `REFILL_PROVIDER` | `claude`, `codex`, `copilot`, `cursor`, `gemini` or `test` |
| `REFILL_ACCOUNT_ID`, `REFILL_ACCOUNT` | Stable account ID and display name |
| `REFILL_WINDOW`, `REFILL_WINDOW_LABEL` | Window key (`five_hour`) and label (`5h session`) |
| `REFILL_UTILIZATION` | Percent used, whole number |
| `REFILL_RESETS_AT` | ISO 8601 time of the next reset, or empty |
| `REFILL_REASON` | `scheduled`, `observed`, `threshold` or `test` |

### Example

*~/.config/refill/on-reset*

```bash
#!/bin/zsh
case "$REFILL_KIND" in
  reset)
    /usr/bin/say "$REFILL_ACCOUNT is back"
    # Pick up where you left off
    cd ~/project && /opt/homebrew/bin/claude -p "continue the plan in TODO.md" >> ~/.config/refill/hook.log 2>&1 &
    ;;
  warning)
    /usr/bin/osascript -e "display notification \"$REFILL_UTILIZATION% used\" with title \"$REFILL_ACCOUNT\""
    ;;
  empty)
    /usr/bin/curl -s -d "$REFILL_ACCOUNT is empty" https://ntfy.sh/my-private-topic
    ;;
esac
```

### Listen from other apps

Refill also posts a macOS distributed notification named `cz.stepanblaha.refill.reset` (or `.warning`, `.empty`, `.test`). The object is the account ID and the user info holds the same `REFILL_*` values. In Hammerspoon:

```bash
hs.distributednotifications.new(function(name, object, info)
  hs.alert.show(info.REFILL_MESSAGE)
end, "cz.stepanblaha.refill.reset"):start()
```

### If it fails

- Nothing runs: the file is not executable, the toggle is off, or the shebang is missing.
- Command not found: use full paths. Add `exec >> ~/.config/refill/hook.log 2>&1` at the top to log output. Refill drops stderr.
- Hooks run during quiet hours too. Only sound is muted.

<a id="shortcuts"></a>

## Shortcuts, URLs and CLI

**What you get.** Ask Refill from Shortcuts, Siri, a link or a terminal.

### Shortcuts and Siri

Open the Shortcuts app, create a shortcut, and search for **Refill**. Refill must be running.

| Action | Returns |
|---|---|
| Get Remaining Usage | Percent left as a number, or -1 if unknown. Choose Provider (Claude, Codex, Any), Window (Session 5h, Week) and optional account email. |
| Get Refill Status | The full status as JSON text. |
| Next Refill Time | A date. Choose a Provider. |
| Refresh Usage | Re-polls now. |
| Send Test Signal | Fires a test to every enabled integration. |

Siri phrases: "How much Claude is left in Refill", "When does Refill refill", "Refresh Refill" and "Test Refill signal".

### URL scheme

| URL | Does |
|---|---|
| `refill://refresh` | Re-poll now |
| `refill://test` | Send a test signal |
| `refill://open`, `dashboard`, `settings`, `history`, `onboarding` | Open that window |
| `refill://status?x-success=URL&x-error=URL` | Opens `x-success` with `remaining` and `json` added, or `x-error` with `errorMessage` if there is no data |

```bash
open refill://test
```

### Command line

`scripts/refill` in the repo reads `~/.config/refill/status.json` and needs `python3`. Copy it somewhere on your `PATH`.

```bash
refill status        # table of accounts and windows
refill left claude   # percent left in the 5h session
refill json          # raw status.json
refill open test     # any refill:// route
```

Files: `~/.config/refill/status.json` is the live status and `events.jsonl` holds one JSON line per event.

<a id="dashboard"></a>

## Local dashboard

**What you get.** A web page with your tanks, for a browser tab or your phone.

### Steps

1. Open **Settings → General → Dashboard** and click **Open**. It loads `http://127.0.0.1:7788` and only this Mac can reach it.
2. For your phone, turn on **Visible on Wi-Fi**. Open the address shown in Settings (your Mac name plus `.local` and `:7788`) in your phone's browser. Add it to the Home Screen if you like.
3. If macOS asks to allow incoming connections, allow it.

The page is read-only and has no password. Anyone on the same Wi-Fi can open it while **Visible on Wi-Fi** is on, so use it on networks you trust.

### Change the port

The default is 7788. Change it in **Settings → General → Dashboard → Port** and press Return; the dashboard restarts on the new port.

### JSON endpoints

- `/status` is the same JSON as `status.json`.
- `/events` lists recent events.
- Both allow cross-origin reads, so a page or a Home Assistant sensor can fetch them.

### If it fails

- Phone cannot connect: same Wi-Fi? Some guest and office networks block devices from each other. Try the Mac's IP address instead of the `.local` name.
- Port in use: pick another with the command above.

<a id="widgets"></a>

## Widgets

**What you get.** Small, medium and large desktop widgets with the tanks and Drip.

### Steps

1. Keep Refill in `/Applications` and open it once.
2. Right-click the desktop and choose **Edit Widgets** (or open Notification Center and scroll to **Edit Widgets**).
3. Search for **Refill**, pick a size and add it.

The app writes a snapshot that the widget reads, so keep Refill running. The widget refreshes every 15 minutes, and right after the next known reset.

### If it fails

- Refill is missing from the gallery: quit and reopen Refill, then try again. macOS finds widgets after the app has launched.
- Empty widget: open Refill so it can write fresh data. Check that your accounts show up in the menu bar.

<a id="quiet-hours"></a>

## Quiet hours and thresholds

**What you get.** Decide when Refill stays silent and when it warns you.

### Quiet hours

1. Open **Settings → General → Quiet hours** and switch it on.
2. Choose **From** and **to** hours. The default is 22:00 to 08:00 and it can cross midnight.
3. Optional: turn on **Also mute phone and chat pushes**.

| Output | During quiet hours |
|---|---|
| Sound | Muted |
| Notification and notch | Still shown |
| Shell hook | Still runs |
| Home Assistant, Hue, WLED, custom webhook | Still fire |
| ntfy, Pushover, Telegram, Discord, Slack | Fire, unless you turn on the mute option. A delayed ntfy reset whose delivery hour is inside quiet hours is not scheduled when that option is on. |

### Warning thresholds

Under **Settings → General → Usage**, **Warn at** takes used percentages separated by commas. The default is `80, 95`. Values must be above 0 and below 100. An empty alert always goes out at 100%. **Check every** sets how often Refill polls, from 1 to 60 minutes (default 5).

Each integration has its own **Send on** switches for Refill (reset), Warning and Empty. Turn off Warning on a chat channel if you only want resets there.

<a id="troubleshooting"></a>

## Troubleshooting

**What you get.** Quick checks for when something stays quiet.

### Integration status messages

| Message | Meaning |
|---|---|
| `OK 200` | The service accepted the request. Some services use another 2xx code. |
| `HTTP 4xx …` | The service refused it. The first 80 characters of its reply follow. |
| `Missing fields` | A required field is empty or the URL is not a full address. |
| Any other text | A network error, often a timeout after 10 seconds. |

### Checks

- Use **Send test** on the integration first. It tests one service. **Settings → General → Send test** fires every output.
- Check the integration is switched on and the right **Send on** toggles are enabled.
- Look at `~/.config/refill/events.jsonl` to see which events fired.
- Settings live in `~/.config/refill`. `integrations.json` holds your tokens and is readable only by you. Do not share it.
- A reset is detected when a known reset time passes after use, or when a poll sees the time jump forward. The menu, the notch and most integrations need Refill running. An ntfy reset that Refill already scheduled still arrives if the Mac is asleep or off. See [ntfy](#ntfy).

### Updates and installs

Refill checks GitHub Releases daily. Use **Settings → General → About → Check now**. Replacing the app keeps `~/.config/refill`. Refill is not notarized, so on first launch use **System Settings → Privacy & Security → Open Anyway**, or install with Homebrew or the one-line installer described in the [README](https://github.com/StepanBlaha/Refill#install).

Still stuck? [Open an issue](https://github.com/StepanBlaha/Refill/issues) and leave tokens out.
