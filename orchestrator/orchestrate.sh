# orchestrator/orchestrate.sh
#!/bin/bash
# Claude Code からサブエージェントへタスクを派遣するオーケストレーター

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

set -a
source "$SCRIPT_DIR/../.env"
set +a

SHARED_DIR="$SCRIPT_DIR/shared"
SESSION="multi-agent"

# ディレクトリ初期化
mkdir -p "$SHARED_DIR/task-queue" "$SHARED_DIR/results"

log() {
    echo "[$(date '+%H:%M:%S')] [Orchestrator] $1" | tee -a "$SHARED_DIR/results/output.log"
}

# ========== サブエージェント起動 ==========
start_agents() {
    log "🚀 サブエージェント起動中..."
    
    # Codex を Pane 1 で起動
    tmux send-keys -t $SESSION:0.1 "bash $SCRIPT_DIR/agents/codex-runner.sh" Enter

    # Gemini を Pane 2 で起動
    tmux send-keys -t $SESSION:0.2 "bash $SCRIPT_DIR/agents/gemini-runner.sh" Enter
    
    sleep 2
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
wait_for_result() {
    local agent=$1
    local timeout=${2:-120}  # デフォルト120秒
    local result_file="$SHARED_DIR/results/${agent}-result.json"
    local elapsed=0
    
    log "⏳ $agent の結果待機中..."
    
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
    
    log "❌ タイムアウト: $agent の結果が $timeout 秒以内に返りませんでした"
    return 1
}

# ========== 並列実行 ==========
dispatch_parallel() {
    local phase=$1
    local codex_prompt=$2
    local gemini_prompt=$3
    
    log "🔀 並列実行開始 (Phase: $phase)"
    
    dispatch_task "codex" "$codex_prompt" "$phase"
    dispatch_task "gemini" "$gemini_prompt" "$phase"
    
    # 並列で結果待機
    CODEX_RESULT=$(wait_for_result "codex" 180)
    GEMINI_RESULT=$(wait_for_result "gemini" 180)
    
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

# 引数からタスクを受け取る
main "$@"