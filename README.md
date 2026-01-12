[English](README.md) | [中文](README_CN.md)

# Claude Code Telegram Notifier

A shell script that sends Telegram notifications for Claude Code events, keeping you informed when tasks complete, permissions are needed, or input is required.

## Features

- **Task Completion Notifications** - Get notified when Claude Code finishes a task, including session duration and memory usage
- **Permission Request Alerts** - Receive instant alerts when Claude Code needs your authorization
- **Idle Input Prompts** - Know when Claude Code is waiting for your input
- **Rich Message Format** - Clean, formatted messages with project name, timestamps, and session info

## Prerequisites

- A Telegram Bot Token (from [@BotFather](https://t.me/BotFather))
- Your Telegram Chat ID
- `jq` command-line JSON processor
- Claude Code CLI installed

## Installation

### 1. Create a Telegram Bot

1. Open Telegram and search for [@BotFather](https://t.me/BotFather)
2. Send `/newbot` and follow the prompts
3. Save the **Bot Token** you receive (format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### 2. Get Your Chat ID

1. Start a chat with your new bot
2. Send any message to the bot
3. Visit: `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
4. Find `"chat":{"id":123456789}` in the response - that's your Chat ID

### 3. Set Environment Variables

Add to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
export TELEGRAM_BOT_TOKEN="your_bot_token_here"
export TELEGRAM_CHAT_ID="your_chat_id_here"
```

Then reload your shell:
```bash
source ~/.zshrc  # or source ~/.bashrc
```

### 4. Download and Configure the Script

```bash
# Download the script
curl -o ~/telegram_notify.sh https://raw.githubusercontent.com/cyenxchen/telegram-notify/master/telegram_notify.sh

# Make it executable
chmod +x ~/telegram_notify.sh
```

### 5. Configure Claude Code Hooks

Add the following to your Claude Code settings file (`~/.claude/settings.json`):

```json
{
  "hooks": {
    "Stop": [
      {
        "type": "command",
        "command": "~/telegram_notify.sh"
      }
    ],
    "Notification": [
      {
        "type": "command",
        "command": "~/telegram_notify.sh"
      }
    ]
  }
}
```

## Notification Examples

### Task Completed
```
✅ Claude Code Task Completed

📁 Project: my-project
⏱️ Duration: 5min 32sec
💾 Memory: 256 MB
⏰ Completed: 2024-01-15 14:30:22
```

### Permission Required
```
⚠️ Claude Code Needs Authorization

📁 Project: my-project
💬 Message: Permission needed to execute command
🆔 Session: a1b2c3d4
⏰ Time: 2024-01-15 14:30:22
```

### Waiting for Input
```
⏳ Claude Code Waiting for Input

📁 Project: my-project
💬 Message: Waiting for your input
🆔 Session: a1b2c3d4
⏰ Time: 2024-01-15 14:30:22
```

## Troubleshooting

**No notifications received?**
- Verify environment variables are set: `echo $TELEGRAM_BOT_TOKEN`
- Check if `jq` is installed: `which jq`
- Test the script manually: `echo '{"hook_event_name":"Stop"}' | ~/telegram_notify.sh`

**Script not found?**
- Ensure the script path in `settings.json` matches the actual location
- Use absolute paths (e.g., `/Users/username/telegram_notify.sh`)

## License

MIT License
