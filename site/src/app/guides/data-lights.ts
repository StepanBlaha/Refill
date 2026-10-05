import type { Section } from "./types";

const where = "Open Refill, then **Settings → Integrations → Add**";
const colors = "Event colors: reset and test `#C8FF4D` (200, 255, 77), warning `#FFB547` (255, 181, 71), empty `#FF503C` (255, 80, 60).";

export const lights: Section[] = [
  {
    id: "homeassistant", title: "Home Assistant", group: "Lights and webhooks",
    intro: "Any light Home Assistant can control turns the color of the event.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "Make sure your Mac can open Home Assistant, for example `http://homeassistant.local:8123`.",
        "In Home Assistant, go to **Settings → Automations & Scenes → Create automation → Create new automation**. Open the three-dot menu and choose **Edit in YAML**.",
        "Paste the automation below. Replace `light.living_room` with your light. Find its ID under **Settings → Devices & services → Entities**. Save.",
        `${where} → **Home Assistant (any lights)**.`,
      ] },
      { t: "code", title: "automation.yaml (Home Assistant 2024.10 or newer)", x: `alias: Refill light
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
      flash: long` },
      { t: "p", x: "This works with any light brand Home Assistant supports: Hue, IKEA, LIFX, Nanoleaf, Zigbee, Tuya and more. The light must support color. For a white-only bulb, drop `rgb_color`. On older Home Assistant, use `platform: webhook` and `service: light.turn_on`. See the [webhook trigger docs](https://www.home-assistant.io/docs/automation/trigger/#webhook-trigger)." },
      { t: "p", x: "The webhook ID acts like a password. If others share your network, pick a longer ID than `refill` in both places. To react differently per event, branch on `trigger.json.kind` (`reset`, `warning`, `empty`, `test`)." },
      { t: "h", x: "Fill in Refill" },
      { t: "fields", x: [
        ["HA URL", "`http://homeassistant.local:8123`, or its IP. No trailing slash."],
        ["Webhook ID", "`refill`, the same as `webhook_id` in the automation."],
      ] },
      { t: "h", x: "Send a test" },
      { t: "p", x: "Click **Send test**. The light should turn lime green. Home Assistant answers `200` even when no automation matches, so a missing reaction means checking the automation." },
      { t: "h", x: "What Refill sends" },
      { t: "p", x: colors + " `r`, `g`, `b` and `utilization` are strings. `rgb` is a list of numbers." },
      { t: "code", title: "POST http://homeassistant.local:8123/api/webhook/refill", x: `{
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
}` },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "Nothing happens: open the automation, then **Traces** from the three-dot menu. No trace means the webhook ID differs.",
        "Trace shows an error on `rgb_color`: the entity is not a color light.",
        "Connection errors: the URL is wrong, or the Mac is not on the same network. `local_only: true` rejects requests from outside your network.",
      ] },
    ],
  },
  {
    id: "hue", title: "Philips Hue", group: "Lights and webhooks",
    intro: "Your Hue lights flash green, amber or red straight from the bridge, no cloud.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "Find the bridge IP. Check the bridge details in the Hue app, your router, or [discovery.meethue.com](https://discovery.meethue.com).",
        "Press the round link button on the bridge. Within 30 seconds, run the command below. It prints `[{\"success\":{\"username\":\"…\"}}]`. Copy the username. If you get `link button not pressed`, press the button and run it again.",
        "List your rooms with the second command. Each key (`1`, `2`…) is a group ID with a `name`. Use `0` for all lights.",
        `${where} → **Philips Hue**.`,
      ] },
      { t: "code", copy: true, x: `curl -X POST http://BRIDGE_IP/api -d '{"devicetype":"refill#mac"}'` },
      { t: "code", copy: true, x: "curl http://BRIDGE_IP/api/USERNAME/groups" },
      { t: "p", x: "Refill uses the local Hue API v1 over plain HTTP. Hue has marked it legacy, but bridges still answer it. See the [Hue getting started guide](https://developers.meethue.com/develop/get-started-2/)." },
      { t: "h", x: "Fill in Refill" },
      { t: "fields", x: [
        ["Bridge IP", "For example `192.168.1.20`. Give the bridge a fixed address in your router."],
        ["API username", "The username from step 2."],
        ["Group / room ID", "A group ID from step 3. Empty or `0` means all lights."],
      ] },
      { t: "h", x: "Send a test" },
      { t: "p", x: "Click **Send test**. The lights turn green and breathe for 15 seconds. Hue answers `200` even for errors, so judge by the lights, not the status." },
      { t: "h", x: "What Refill sends" },
      { t: "p", x: "Color is CIE `xy`: reset and test `[0.3, 0.6]`, warning `[0.55, 0.41]`, empty `[0.675, 0.322]`. Warning uses `alert: select` (one pulse). Everything else uses `lselect` (15 seconds)." },
      { t: "code", title: "PUT http://BRIDGE_IP/api/USERNAME/groups/0/action", x: `{
  "alert": "lselect",
  "bri": 254,
  "on": true,
  "xy": [0.3, 0.6]
}` },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "`OK 200` but dark lights: the bridge replied `unauthorized user` (wrong username) or `resource not available` (wrong group). Repeat the group command with curl to see the reply.",
        "Timeout: the IP changed, or the Mac is on another network or VLAN.",
        "`Missing fields`: Bridge IP or API username is empty.",
      ] },
    ],
  },
  {
    id: "wled", title: "WLED", group: "Lights and webhooks",
    intro: "A WLED strip flashes the event color, or runs a preset you made for resets.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        "Find the host. Try `wled.local`, or use the IP from your router or the WLED app.",
        "Optional: open the WLED web page, set a color and effect you like, open **Presets**, save it to a slot and note its number. The ID is the slot number. See [the JSON API docs](https://kno.wled.ge/interfaces/json-api/).",
        `${where} → **WLED strip**.`,
      ] },
      { t: "h", x: "Fill in Refill" },
      { t: "fields", x: [
        ["Host", "`wled.local` or an IP. Refill adds `http://` for you."],
        ["Preset ID for reset (optional)", "For example `3`. Leave empty to use the plain green breathing effect."],
      ] },
      { t: "h", x: "Send a test" },
      { t: "p", x: "Click **Send test**. The strip turns lime and breathes. A test never runs your preset, only a real reset does." },
      { t: "h", x: "What Refill sends" },
      { t: "p", x: "Warning breathes amber (effect 2). Empty is solid red (effect 0). A reset with a preset ID sends the preset instead." },
      { t: "code", title: "POST http://wled.local/json/state", x: `{
  "bri": 255,
  "on": true,
  "seg": [{ "col": [[200, 255, 77]], "fx": 2 }]
}` },
      { t: "code", title: "Reset with Preset ID 3", x: `{ "on": true, "ps": 3 }` },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "Cannot resolve `wled.local`: use the IP address. Not every network supports `.local` names.",
        "Preset does nothing: the slot is empty. Save the preset again and check the number.",
        "Timeout: the strip is off the Wi-Fi or on another network.",
      ] },
    ],
  },
  {
    id: "webhook", title: "Custom webhook", group: "Lights and webhooks",
    intro: "Call any HTTP endpoint with a body you shape yourself.",
    blocks: [
      { t: "h", x: "Steps" },
      { t: "ol", x: [
        `${where} → **Custom webhook**. Method starts as \`POST\`.`,
        "Enter the URL. Add headers if the service needs them. Write a body template, or leave it empty to send the event JSON.",
        "Click **Send test**.",
      ] },
      { t: "h", x: "Fill in Refill" },
      { t: "fields", x: [
        ["URL", "A full `https://` or `http://` address. Placeholders do not work here."],
        ["Method", "`POST` by default. `GET` sends no body."],
        ["Headers (Key: Value per line)", "For example `Authorization: Bearer abc`. `Content-Type: application/json` is set for you."],
        ["Body template (empty = event JSON)", "Text with placeholders from the table. Empty sends the event JSON."],
      ] },
      { t: "h", x: "Placeholders" },
      { t: "p", x: "Refill replaces these in the body as plain text. It does not escape quotes, so keep them out of names." },
      { t: "table", head: ["Placeholder", "Value", "Example"], x: [
        ["`{{kind}}`", "Event type", "`reset`, `warning`, `empty`, `test`"],
        ["`{{title}}`", "Headline", "`Testing, testing`"],
        ["`{{message}}`", "Message text", "`If you see this, the pipes work. Drip approves.`"],
        ["`{{account}}`", "Account name", "`Refill`"],
        ["`{{window}}`", "Window label", "`5h session`"],
        ["`{{utilization}}`", "Percent used, whole number", "`100`"],
        ["`{{color}}`", "Event color as hex", "`#C8FF4D`"],
        ["`{{r}}` `{{g}}` `{{b}}`", "Event color, 0 to 255 each", "`200` `255` `77`"],
        ["`{{json}}`", "The whole event as JSON", "see below"],
      ] },
      { t: "p", x: colors },
      { t: "code", title: "Default body (the {{json}} value)", x: `{"accountId":"test","accountName":"Refill","detectedAt":"2026-10-05T09:30:00Z","kind":"test","message":"If you see this, the pipes work. Drip approves.","provider":"test","reason":"test","title":"Testing, testing","utilization":100,"window":"five_hour","windowLabel":"5h session"}` },
      { t: "h", x: "Example: IFTTT or Zapier" },
      { t: "p", x: "Create an [IFTTT Webhooks](https://ifttt.com/maker_webhooks) trigger, or a Zapier **Catch Hook**, and use its URL. IFTTT expects `value1` to `value3`." },
      { t: "code", title: "URL: https://maker.ifttt.com/trigger/refill/with/key/YOUR_KEY", x: `{"value1":"{{kind}}","value2":"{{message}}","value3":"{{color}}"}` },
      { t: "h", x: "Example: a light controller" },
      { t: "p", x: "Works for a Node-RED flow, an ESPHome or Shelly-style device, or your own server that takes JSON. Adjust the URL and field names to what yours expects." },
      { t: "code", title: "PUT http://192.168.1.50/api/light + header Authorization: Bearer YOUR_TOKEN", x: `{"on":true,"rgb":[{{r}},{{g}},{{b}}],"label":"{{kind}}"}` },
      { t: "h", x: "If it fails" },
      { t: "ul", x: [
        "`HTTP 400` or `422`: the body is not valid JSON for that service. Test the same body with curl.",
        "`HTTP 401` or `403`: add or fix the `Authorization` header.",
        "A `GET` does nothing useful: Refill sends no body and does not fill the URL. Use `POST`.",
      ] },
    ],
  },
];
