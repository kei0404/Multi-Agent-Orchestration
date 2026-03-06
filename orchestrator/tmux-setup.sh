# orchestrator/tmux-setup.sh
#!/bin/bash

SESSION="multi-agent"
PROJECT_DIR="$(pwd)"

# 既存セッションがあれば削除
tmux kill-session -t $SESSION 2>/dev/null

# 新規セッション作成（メインペイン: Claude Code Orchestrator）
tmux new-session -d -s $SESSION -x 220 -y 50

# セッション名・ペイン0のタイトル設定
tmux rename-window -t $SESSION "orchestrator"
tmux send-keys -t $SESSION:0.0 "echo '=== Claude Code Orchestrator ===' && cd $PROJECT_DIR" Enter

# 右側を垂直分割 → Codex ペイン（Pane 1）
tmux split-window -t $SESSION:0 -h
tmux send-keys -t $SESSION:0.1 "echo '=== Codex Agent ===' && cd $PROJECT_DIR" Enter

# Codex ペインをさらに垂直分割 → Gemini ペイン（Pane 2）
tmux split-window -t $SESSION:0.1 -v
tmux send-keys -t $SESSION:0.2 "echo '=== Gemini Agent ===' && cd $PROJECT_DIR" Enter

# 下部に結果ログペイン（Pane 3）
tmux split-window -t $SESSION:0.0 -v -p 30
tmux send-keys -t $SESSION:0.3 "echo '=== Results / Output Log ===' && tail -f $PROJECT_DIR/orchestrator/shared/results/output.log 2>/dev/null || touch $PROJECT_DIR/orchestrator/shared/results/output.log && tail -f $PROJECT_DIR/orchestrator/shared/results/output.log" Enter

# ペインサイズ調整
tmux resize-pane -t $SESSION:0.0 -x 80
tmux resize-pane -t $SESSION:0.3 -y 12

# Orchestrator ペインにフォーカス
tmux select-pane -t $SESSION:0.0

# tmux のペインボーダーにラベル表示
tmux set-option -t $SESSION pane-border-status top
tmux set-option -t $SESSION pane-border-format "#{pane_index}: #{pane_title}"
tmux select-pane -t $SESSION:0.0 -T "🤖 Claude Code (Orchestrator)"
tmux select-pane -t $SESSION:0.1 -T "⚡ Codex Agent"
tmux select-pane -t $SESSION:0.2 -T "✨ Gemini Agent"
tmux select-pane -t $SESSION:0.3 -T "📊 Output Log"

echo "✅ tmux セッション '$SESSION' を起動しました"
echo "接続: tmux attach -t $SESSION"

tmux attach -t $SESSION