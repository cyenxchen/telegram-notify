#!/bin/bash

# ============================================================
# Claude Code & Codex Telegram 增强通知脚本
#
# 支持事件:
#   - Claude Code: Stop, Notification (permission_prompt / idle_prompt)
#   - Codex:       Stop, SessionStart
# 功能: 自动识别来源、会话持续时间追踪、内存监控、丰富的消息格式
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

# --- 解析 JSON 字段(单次 jq 调用,@sh 安全转义) ---
eval "$(
    $JQ -r '@sh "HOOK_EVENT=\(.hook_event_name // "Notification") NOTIFICATION_TYPE=\(.notification_type // "") SESSION_ID=\(.session_id // "unknown") CWD=\(.cwd // "unknown") MESSAGE=\(.message // "") TRANSCRIPT_PATH=\(.transcript_path // "")"' <<<"$INPUT"
)"
SESSION_ID=${SESSION_ID//[^a-zA-Z0-9_-]/_}

# --- 辅助函数 ---

detect_source() {
    [[ -n "${CLAUDE_PROJECT_DIR:-}" || -n "${CLAUDECODE:-}" ]] && { echo "claude"; return; }
    [[ -n "${CODEX_HOME:-}" ]] && { echo "codex"; return; }

    case "$TRANSCRIPT_PATH" in
        */.codex/*|*/codex/sessions/*) echo "codex"; return ;;
        */.claude/*|*/claude/projects/*) echo "claude"; return ;;
    esac

    local pid=$PPID cmd depth=0
    while [[ "$pid" != "1" && $depth -lt 4 ]]; do
        cmd=$(ps -p "$pid" -o comm= 2>/dev/null)
        case "$cmd" in
            *codex*) echo "codex"; return ;;
            *claude*) echo "claude"; return ;;
        esac
        pid=$(ps -p "$pid" -o ppid= 2>/dev/null)
        [[ -z "$pid" ]] && break
        depth=$((depth + 1))
    done

    echo "claude"
}

get_source_label() {
    [[ "$SOURCE" == "codex" ]] && echo "Codex" || echo "Claude Code"
}

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
    pid=$(pgrep -x "$SOURCE" 2>/dev/null | head -1)
    [[ -z "$pid" ]] && pid=$(pgrep -f "$SOURCE" 2>/dev/null | head -1)
    if [[ -n "$pid" ]]; then
        mem_kb=$(ps -o rss= -p "$pid" 2>/dev/null)
        [[ -n "$mem_kb" ]] && { echo "$((mem_kb / 1024))"; return; }
    fi
    echo "N/A"
}

session_file_path() {
    echo "/tmp/${SOURCE}_session_${SESSION_ID}.start"
}

get_session_duration() {
    local session_file
    session_file=$(session_file_path)
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
    local session_file
    session_file=$(session_file_path)
    [[ ! -f "$session_file" ]] && date +%s > "$session_file"
}

cleanup_session_file() {
    rm -f "$(session_file_path)" 2>/dev/null || true
}

# --- 构建消息 ---

SOURCE=$(detect_source)
SOURCE_LABEL=$(get_source_label)
PROJECT_NAME=$(get_project_name)
TIMESTAMP=$(get_timestamp)
SHORT_SESSION=$(get_short_session_id)

case "$HOOK_EVENT" in
    "SessionStart")
        save_session_start
        exit 0
        ;;

    "Stop")
        DURATION=$(get_session_duration)
        MEMORY=$(get_memory_usage)
        cleanup_session_file

        TITLE="✅ ${SOURCE_LABEL} 任务完成"
        BODY="📁 项目: <code>${PROJECT_NAME}</code>
⏱️ 持续: ${DURATION}
💾 内存: ${MEMORY} MB
⏰ 完成: ${TIMESTAMP}"
        ;;

    "Notification")
        case "$NOTIFICATION_TYPE" in
            "permission_prompt") ;;
            "idle_prompt") exit 0 ;;
            *) echo "$MESSAGE" | grep -qi "permission" || exit 0 ;;
        esac
        save_session_start

        TITLE="⚠️ ${SOURCE_LABEL} 需要授权"
        BODY="📁 项目: <code>${PROJECT_NAME}</code>
💬 消息: ${MESSAGE:-需要你的授权}
🆔 会话: <code>${SHORT_SESSION}</code>
⏰ 时间: ${TIMESTAMP}"
        ;;

    *)
        # 忽略其他事件类型
        exit 0
        ;;
esac

# --- 发送 Telegram 消息 ---
FULL_MESSAGE="<b>${TITLE}</b>

${BODY}"

# 后台发送,不阻塞宿主 CLI
( curl -sS -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=${FULL_MESSAGE}" \
    -d "parse_mode=HTML" \
    -d "disable_web_page_preview=true" \
    >/dev/null 2>&1 & )

exit 0
