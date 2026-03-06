# orchestrator/lib/display.sh

SESSION="multi-agent"

# ペインにステータスバナーを送信
update_pane_status() {
    local pane=$1
    local status=$2
    local color=$3  # green, yellow, red

    # ペインタイトルを動的更新
    case $color in
        green)  tmux select-pane -t $SESSION:0.$pane -T "✅ $status" ;;
        yellow) tmux select-pane -t $SESSION:0.$pane -T "⚙️  $status" ;;
        red)    tmux select-pane -t $SESSION:0.$pane -T "❌ $status" ;;
    esac
}

# 使用例
update_pane_status 1 "Codex: Running Phase 2" yellow
update_pane_status 2 "Gemini: Waiting..."     green