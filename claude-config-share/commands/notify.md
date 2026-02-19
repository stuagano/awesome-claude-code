---
description: Send a notification to the user via Slack webhook
argument-hint: [message to send]
allowed-tools: Bash(curl:*),Read
---

## Notify

Send a notification via Slack incoming webhook.

### Setup

1. Create a Slack app at https://api.slack.com/apps
2. Add an Incoming Webhook and copy the URL
3. Store the webhook URL securely (e.g., in 1Password or `~/.claude/secrets.json`)

### Execution

1. Read the webhook URL from your secrets store.
2. Post to it:

```
curl -s -X POST -H "Content-type: application/json" --data '{"text":"MESSAGE_HERE"}' "$WEBHOOK_URL"
```

If the webhook returns `ok`, the notification was delivered. If it fails, tell the user the webhook may need to be reconfigured.
