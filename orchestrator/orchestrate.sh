# orchestrator/orchestrate.sh
#!/bin/bash
# Claude Code からサブエージェントへタスクを派遣するオーケストレーター

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

set -a
source "$SCRIPT_DIR/../.env"
set +a

SHARED_DIR="$SCRIPT_DIR/shared"
SESSION="multi-agent"

# ディレクトリ初期化（output.log を事前作成して tail -f のエラーを防止）
mkdir -p "$SHARED_DIR/task-queue" "$SHARED_DIR/results"
touch "$SHARED_DIR/results/output.log"

log() {
    echo "[$(date '+%H:%M:%S')] [Orchestrator] $1" | tee -a "$SHARED_DIR/results/output.log"
}

# ========== tmuxセッション起動 ==========
setup_tmux() {
    if tmux has-session -t $SESSION 2>/dev/null; then
        log "tmuxセッション '$SESSION' は既に存在します"
        return 0
    fi

    log "🖥️  tmuxセッション起動中..."
    local project_dir="$(cd "$SCRIPT_DIR/.." && pwd)"

    tmux new-session -d -s $SESSION -x 220 -y 50
    tmux rename-window -t $SESSION "orchestrator"
    tmux send-keys -t $SESSION:0.0 "echo '=== Claude Code Orchestrator ===' && cd $project_dir" Enter

    # Codex ペイン（Pane 1）
    tmux split-window -t $SESSION:0 -h
    tmux send-keys -t $SESSION:0.1 "echo '=== Codex Agent ===' && cd $project_dir" Enter

    # Gemini ペイン（Pane 2）
    tmux split-window -t $SESSION:0.1 -v
    tmux send-keys -t $SESSION:0.2 "echo '=== Gemini Agent ===' && cd $project_dir" Enter

    # Output Log ペイン（Pane 3）
    tmux split-window -t $SESSION:0.0 -v -p 30
    tmux send-keys -t $SESSION:0.3 "echo '=== Results / Output Log ===' && tail -f $SHARED_DIR/results/output.log" Enter

    # レイアウト調整
    tmux resize-pane -t $SESSION:0.0 -x 80
    tmux resize-pane -t $SESSION:0.3 -y 12
    tmux select-pane -t $SESSION:0.0

    # ペインボーダーにラベル表示
    tmux set-option -t $SESSION pane-border-status top
    tmux set-option -t $SESSION pane-border-format "#{pane_index}: #{pane_title}"
    tmux select-pane -t $SESSION:0.0 -T "🤖 Claude Code (Orchestrator)"
    tmux select-pane -t $SESSION:0.1 -T "⚡ Codex Agent"
    tmux select-pane -t $SESSION:0.2 -T "✨ Gemini Agent"
    tmux select-pane -t $SESSION:0.3 -T "📊 Output Log"

    sleep 1
    log "✅ tmuxセッション起動完了"
}

# ========== サブエージェント起動 ==========
start_agents() {
    # tmuxセッションがなければ自動作成
    setup_tmux

    log "🚀 サブエージェント起動中..."

    # ペインタイトルを更新
    tmux select-pane -t $SESSION:0.1 -T "⚡ Codex Agent [起動中...]"
    tmux select-pane -t $SESSION:0.2 -T "✨ Gemini Agent [起動中...]"

    # Codex を Pane 1 で起動
    tmux send-keys -t $SESSION:0.1 "bash $SCRIPT_DIR/agents/codex-runner.sh" Enter

    # Gemini を Pane 2 で起動
    tmux send-keys -t $SESSION:0.2 "bash $SCRIPT_DIR/agents/gemini-runner.sh" Enter

    sleep 2

    # ペインタイトルを待機中に更新
    tmux select-pane -t $SESSION:0.1 -T "⚡ Codex Agent [待機中]"
    tmux select-pane -t $SESSION:0.2 -T "✨ Gemini Agent [待機中]"

    log "✅ エージェント起動完了"
}

# ========== タスク派遣 ==========
dispatch_task() {
    local agent=$1    # "codex" or "gemini"
    local prompt=$2
    local phase=$3
    
    local task_file="$SHARED_DIR/task-queue/${agent}-task.json"
    
    jq -n \
        --arg prompt "$prompt" \
        --arg phase "$phase" \
        --arg agent "$agent" \
        '{prompt: $prompt, phase: $phase, agent: $agent, dispatched_at: now}' \
        > "$task_file"
    
    log "📤 タスク派遣 → $agent (Phase: $phase)"
}

# ========== 結果待機 ==========
# 注意: この関数はバックグラウンドで実行され、stdoutがJSONファイルにリダイレクトされる。
# そのため log() はstderrに出力し、stdoutにはJSONのみを出力する。
wait_for_result() {
    local agent=$1
    local timeout=${2:-${ORCHESTRATOR_TIMEOUT:-120}}
    local result_file="$SHARED_DIR/results/${agent}-result.json"
    local elapsed=0

    log "⏳ $agent の結果待機中... (タイムアウト: ${timeout}秒)" >&2

    while [ $elapsed -lt $timeout ]; do
        if [ -f "$result_file" ]; then
            local result=$(cat "$result_file")
            rm "$result_file"
            echo "$result"
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done

    log "❌ タイムアウト: $agent の結果が $timeout 秒以内に返りませんでした" >&2
    # タイムアウト時はフォールバックJSONを返す
    jq -n \
        --arg agent "$agent" \
        --arg phase "unknown" \
        '{agent: $agent, phase: $phase, result: "TIMEOUT: エージェントからの応答がありませんでした", success: false, timestamp: now}'
    return 1
}

# ========== 並列実行 ==========
dispatch_parallel() {
    local phase=$1
    local codex_prompt=$2
    local gemini_prompt=$3
    local tmp_codex="/tmp/multi-agent-codex-$phase.json"
    local tmp_gemini="/tmp/multi-agent-gemini-$phase.json"

    log "🔀 並列実行開始 (Phase: $phase)"

    # ペインタイトルを実行中に更新
    tmux select-pane -t $SESSION:0.1 -T "⚡ Codex [$phase 実行中...]" 2>/dev/null
    tmux select-pane -t $SESSION:0.2 -T "✨ Gemini [$phase 実行中...]" 2>/dev/null

    dispatch_task "codex" "$codex_prompt" "$phase"
    dispatch_task "gemini" "$gemini_prompt" "$phase"

    # バックグラウンドで真の並列待機
    wait_for_result "codex" > "$tmp_codex" &
    local codex_pid=$!
    wait_for_result "gemini" > "$tmp_gemini" &
    local gemini_pid=$!

    wait $codex_pid
    wait $gemini_pid

    CODEX_RESULT=$(cat "$tmp_codex")
    GEMINI_RESULT=$(cat "$tmp_gemini")
    rm -f "$tmp_codex" "$tmp_gemini"

    # ペインタイトルを完了に更新
    tmux select-pane -t $SESSION:0.1 -T "⚡ Codex [$phase 完了 ✅]" 2>/dev/null
    tmux select-pane -t $SESSION:0.2 -T "✨ Gemini [$phase 完了 ✅]" 2>/dev/null

    # 結果を統合して Claude Code に返す
    MERGED_RESULT=$(jq -n \
        --argjson codex "$CODEX_RESULT" \
        --argjson gemini "$GEMINI_RESULT" \
        --arg phase "$phase" \
        '{phase: $phase, codex: $codex, gemini: $gemini}')

    echo "$MERGED_RESULT" > "$SHARED_DIR/results/merged-${phase}.json"
    log "✅ Phase $phase 完了 - 統合結果: $SHARED_DIR/results/merged-${phase}.json"

    echo "$MERGED_RESULT"
}

# ========== メイン実行 ==========
main() {
    local task_description=$1
    
    start_agents
    
    log "🎯 タスク開始: $task_description"
    
    # --- Phase 1: 設計と調査 ---
    log "📐 Phase 1: 設計・調査フェーズ"
    PHASE1=$(dispatch_parallel "phase1" \
        "Analyze and provide implementation plan for: $task_description. Focus on code structure, algorithms, and data models." \
        "Research best practices and potential approaches for: $task_description. Include architecture recommendations and potential pitfalls.")
    
    PHASE1_SUMMARY=$(echo "$PHASE1" | jq -r '"Codex: " + .codex.result + "\nGemini: " + .gemini.result')
    
    # --- Phase 2: 実装 ---
    log "⚙️  Phase 2: 実装フェーズ"
    PHASE2=$(dispatch_parallel "phase2" \
        "Based on this plan, implement the core functionality: $PHASE1_SUMMARY" \
        "Create comprehensive tests and documentation for: $PHASE1_SUMMARY")
    
    # --- Phase 3: レビューと最適化 ---
    log "🔍 Phase 3: レビュー・最適化フェーズ"
    PHASE3=$(dispatch_parallel "phase3" \
        "Review and optimize the implementation. Find bugs and suggest improvements: $(echo $PHASE2 | jq -r '.codex.result')" \
        "Security audit and performance analysis of: $(echo $PHASE2 | jq -r '.gemini.result')")
    
    log "🎉 全フェーズ完了!"
    log "📂 結果は $SHARED_DIR/results/ に保存されました"
}

# ========== エントリポイント ==========
# タスク引数を受け取り、tmux にアタッチしてペインを表示しながらオーケストレーション実行
task_description="${1:-デフォルトタスク}"

# オーケストレーションをバックグラウンドで実行し、tmux にアタッチして各ペインの実行結果を表示
main "$task_description" &
MAIN_PID=$!
sleep 2
log "📺 tmux セッションにアタッチ中... (Ctrl+B → D でデタッチ)"
tmux attach -t $SESSION
wait $MAIN_PID 2>/dev/null || true