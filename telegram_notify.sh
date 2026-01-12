#!/bin/bash

# ============================================================
# Claude Code Telegram 增强通知脚本
#
# 支持事件: Stop, permission_prompt, idle_prompt
# 功能: 会话持续时间追踪、内存监控、丰富的消息格式
# ============================================================

# --- 环境变量检查 ---
if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]] || [[ -z "${TELEGRAM_CHAT_ID:-}" ]]; then
    exit 0
fi

# --- 工具路径 ---
JQ="/opt/homebrew/bin/jq"
[[ ! -x "$JQ" ]] && JQ="jq"

# --- 读取 stdin JSON 输入 ---
INPUT=$(cat)

# --- 解析 JSON 字段 ---
HOOK_EVENT=$(echo "$INPUT" | $JQ -r '.hook_event_name // "Notification"')
NOTIFICATION_TYPE=$(echo "$INPUT" | $JQ -r '.notification_type // ""')
SESSION_ID=$(echo "$INPUT" | $JQ -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | $JQ -r '.cwd // "unknown"')
MESSAGE=$(echo "$INPUT" | $JQ -r '.message // ""')

# --- 辅助函数 ---

get_project_name() {
    basename "$CWD"
}

get_timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

get_short_session_id() {
    echo "${SESSION_ID:0:8}"
}

get_memory_usage() {
    local pid mem_kb
    pid=$(pgrep -f "claude" 2>/dev/null | head -1)
    if [[ -n "$pid" ]]; then
        mem_kb=$(ps -o rss= -p "$pid" 2>/dev/null)
        if [[ -n "$mem_kb" && "$mem_kb" -gt 0 ]]; then
            echo "$((mem_kb / 1024))"
            return
        fi
    fi
    echo "N/A"
}

get_session_duration() {
    local session_file="/tmp/claude_session_${SESSION_ID}.start"
    if [[ -f "$session_file" ]]; then
        local start_time end_time duration minutes seconds
        start_time=$(cat "$session_file")
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        minutes=$((duration / 60))
        seconds=$((duration % 60))
        echo "${minutes}分${seconds}秒"
    else
        echo "未知"
    fi
}

save_session_start() {
    local session_file="/tmp/claude_session_${SESSION_ID}.start"
    [[ ! -f "$session_file" ]] && date +%s > "$session_file"
}

cleanup_session_file() {
    rm -f "/tmp/claude_session_${SESSION_ID}.start" 2>/dev/null || true
}

# --- 构建消息 ---

PROJECT_NAME=$(get_project_name)
TIMESTAMP=$(get_timestamp)
SHORT_SESSION=$(get_short_session_id)

case "$HOOK_EVENT" in
    "Stop")
        DURATION=$(get_session_duration)
        MEMORY=$(get_memory_usage)
        cleanup_session_file

        TITLE="✅ Claude Code 任务完成"
        BODY="📁 项目: <code>${PROJECT_NAME}</code>
⏱️ 持续: ${DURATION}
💾 内存: ${MEMORY} MB
⏰ 完成: ${TIMESTAMP}"
        ;;

    "Notification")
        save_session_start

        case "$NOTIFICATION_TYPE" in
            "permission_prompt")
                TITLE="⚠️ Claude Code 需要授权"
                BODY="📁 项目: <code>${PROJECT_NAME}</code>
💬 消息: ${MESSAGE:-需要你的授权}
🆔 会话: <code>${SHORT_SESSION}</code>
⏰ 时间: ${TIMESTAMP}"
                ;;

            "idle_prompt")
                TITLE="⏳ Claude Code 等待输入"
                BODY="📁 项目: <code>${PROJECT_NAME}</code>
💬 消息: ${MESSAGE:-等待你的输入}
🆔 会话: <code>${SHORT_SESSION}</code>
⏰ 时间: ${TIMESTAMP}"
                ;;

            *)
                # 处理 notification_type 缺失的情况
                if echo "$MESSAGE" | grep -qi "permission"; then
                    TITLE="⚠️ Claude Code 需要授权"
                else
                    TITLE="⏳ Claude Code 等待输入"
                fi
                BODY="📁 项目: <code>${PROJECT_NAME}</code>
💬 消息: ${MESSAGE:-需要你的注意}
🆔 会话: <code>${SHORT_SESSION}</code>
⏰ 时间: ${TIMESTAMP}"
                ;;
        esac
        ;;

    *)
        # 忽略其他事件类型
        exit 0
        ;;
esac

# --- 发送 Telegram 消息 ---
FULL_MESSAGE="<b>${TITLE}</b>

${BODY}"

curl -sS -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=${FULL_MESSAGE}" \
    -d "parse_mode=HTML" \
    -d "disable_web_page_preview=true" \
    > /dev/null 2>&1

exit 0
