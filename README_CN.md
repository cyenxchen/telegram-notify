[English](README.md) | [中文](README_CN.md)

# Claude Code Telegram 通知器

一个用于发送 Claude Code 事件通知到 Telegram 的 Shell 脚本，让你随时掌握任务完成、权限请求和输入等待的状态。

## 功能特性

- **任务完成通知** - 当 Claude Code 完成任务时收到通知，包含会话时长和内存使用情况
- **权限请求提醒** - 当 Claude Code 需要授权时立即收到提醒
- **输入等待提示** - 当 Claude Code 等待你输入时及时知晓
- **富文本消息格式** - 清晰格式化的消息，包含项目名、时间戳和会话信息

## 前置要求

- Telegram Bot Token（通过 [@BotFather](https://t.me/BotFather) 获取）
- 你的 Telegram Chat ID
- `jq` 命令行 JSON 处理工具
- 已安装 Claude Code CLI

## 安装步骤

### 1. 创建 Telegram Bot

1. 打开 Telegram，搜索 [@BotFather](https://t.me/BotFather)
2. 发送 `/newbot` 并按照提示操作
3. 保存你收到的 **Bot Token**（格式：`123456789:ABCdefGHIjklMNOpqrsTUVwxyz`）

### 2. 获取 Chat ID

1. 与你的新 Bot 开始对话
2. 向 Bot 发送任意消息
3. 访问：`https://api.telegram.org/bot<你的BOT_TOKEN>/getUpdates`
4. 在返回结果中找到 `"chat":{"id":123456789}` - 这就是你的 Chat ID

### 3. 设置环境变量

将以下内容添加到你的 shell 配置文件（`~/.zshrc` 或 `~/.bashrc`）：

```bash
export TELEGRAM_BOT_TOKEN="你的_bot_token"
export TELEGRAM_CHAT_ID="你的_chat_id"
```

然后重新加载 shell：
```bash
source ~/.zshrc  # 或 source ~/.bashrc
```

### 4. 下载并配置脚本

**方式 A：从 GitHub Releases 下载（推荐）**

```bash
# 下载最新 release 版本
curl -L -o ~/telegram_notify.sh https://github.com/cyenxchen/telegram-notify/releases/latest/download/telegram_notify.sh

# 添加执行权限
chmod +x ~/telegram_notify.sh
```

**方式 B：从 master 分支下载**

```bash
# 从 master 分支下载
curl -o ~/telegram_notify.sh https://raw.githubusercontent.com/cyenxchen/telegram-notify/master/telegram_notify.sh

# 添加执行权限
chmod +x ~/telegram_notify.sh
```

### 5. 配置 Claude Code Hooks

将以下内容添加到 Claude Code 配置文件（`~/.claude/settings.json`）：

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/telegram_notify.sh"
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/telegram_notify.sh"
          }
        ]
      }
    ]
  }
}
```

## 通知示例

### 任务完成
```
✅ Claude Code 任务完成

📁 项目: my-project
⏱️ 持续: 5分32秒
💾 内存: 256 MB
⏰ 完成: 2024-01-15 14:30:22
```

### 需要授权
```
⚠️ Claude Code 需要授权

📁 项目: my-project
💬 消息: 需要你的授权
🆔 会话: a1b2c3d4
⏰ 时间: 2024-01-15 14:30:22
```

### 等待输入
```
⏳ Claude Code 等待输入

📁 项目: my-project
💬 消息: 等待你的输入
🆔 会话: a1b2c3d4
⏰ 时间: 2024-01-15 14:30:22
```

## 故障排除

**没有收到通知？**
- 验证环境变量已设置：`echo $TELEGRAM_BOT_TOKEN`
- 检查 `jq` 是否已安装：`which jq`
- 手动测试脚本：`echo '{"hook_event_name":"Stop"}' | ~/telegram_notify.sh`

**找不到脚本？**
- 确保 `settings.json` 中的脚本路径与实际位置一致
- 使用绝对路径（如 `/Users/username/telegram_notify.sh`）

## 许可证

MIT License
