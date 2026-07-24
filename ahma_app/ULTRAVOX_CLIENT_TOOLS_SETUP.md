# Ultravox client tools to add manually

Flutter implements these tools over the live WebRTC data channel, but the
Ultravox agent must declare them before it can call them.

## 1. Add `scheduleEvent`

In the Ultravox dashboard, open the AHMA agent, add a custom **Client** tool,
and use:

- Model tool name: `scheduleEvent`
- Description and parameters: copy them from
  `lib/data/models/schedule_client_tool.json`
- Timeout: `30s` (the default client-tool timeout is too short for the
  authenticated Render → Google Calendar request)
- Client execution: enabled (there is no HTTP URL)

The required model parameters are `summary`, `startTime`, and `endTime`.
`description` and `location` are optional. Date-times must be ISO 8601 and
include the Singapore offset, for example `2026-07-25T14:00:00+08:00`.

## 2. Add `contactSupport`

Add a second custom **Client** tool:

- Model tool name: `contactSupport`
- Description and parameters: copy them from
  `lib/data/models/contact_support_client_tool.json`
- Timeout: `30s` (the default client-tool timeout is too short for Gmail)
- Client execution: enabled (there is no HTTP URL)

Its required parameters are `subject` and `message`. The backend deliberately
ignores any recipient supplied by the model and routes the email to
`reach.ahma@gmail.com`.

## 3. Attach both tools to the agent

Add `scheduleEvent` and `contactSupport` to the AHMA agent's selected tools,
alongside the existing `navigate` client tool. Save/publish the agent version.

If either tool already exists, edit it and set **Timeout** to `30s`; changing
the JSON files in Flutter does not update an existing Ultravox dashboard tool.

The checked-in stage responses retain `scheduleEvent` in `SCHEDULE` and
`contactSupport` in `AHMA_GREETING` and `AHMA_RESOURCES`.

## 4. Smoke test

1. Sign in to AHMA and connect a personal Google Calendar from Account.
2. Start a new voice call and ask to add a clearly dated 30-minute reminder.
3. Confirm it appears in that signed-in user's primary Google Calendar.
4. Start another call, explicitly ask AHMA to contact support, and approve the
   message.
5. Confirm the message arrives at `reach.ahma@gmail.com`.

If Calendar is not connected, the voice agent should tell the user to open
Account and select **Connect Calendar**. It must not claim the event was added.
