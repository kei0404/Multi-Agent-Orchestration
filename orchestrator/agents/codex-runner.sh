# orchestrator/agents/codex-runner.sh
#!/bin/bash
# Codex エージェントラッパー - タスクを受け取り実行して結果を返す

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

set -a
source "$SCRIPT_DIR/../../.env"
set +a

SHARED_DIR="$SCRIPT_DIR/../shared"
TASK_FILE="$SHARED_DIR/task-queue/codex-task.json"
RESULT_FILE="$SHARED_DIR/results/codex-result.json"
LOG_FILE="$SHARED_DIR/results/output.log"

log() {
    echo "[$(date '+%H:%M:%S')] [Codex] $1" | tee -a "$LOG_FILE"
}

# タスクキューを監視してループ
log "🟢 Codex Agent 起動 - タスク待機中..."

while true; do
    if [ -f "$TASK_FILE" ]; then
        TASK=$(cat "$TASK_FILE")
        PROMPT=$(echo "$TASK" | jq -r '.prompt')
        PHASE=$(echo "$TASK" | jq -r '.phase')
        
        log "📥 タスク受信 (Phase: $PHASE): $PROMPT"
        
        # タスクファイル削除（処理中マーク）
        rm "$TASK_FILE"
        
        # Codex 実行（ペインにリアルタイム表示 + 結果をキャプチャ）
        log "⚙️  Codex 実行中..."
        tmp_out="/tmp/codex-result-$$.txt"
        # CODEX_MODELが設定されている場合のみ--modelを付与（ChatGPTアカウントはデフォルトモデルを使用）
        if [ -n "$CODEX_MODEL" ]; then
            codex exec --full-auto --model "$CODEX_MODEL" "$PROMPT" 2>&1 | tee "$tmp_out"
        else
            codex exec --full-auto "$PROMPT" 2>&1 | tee "$tmp_out"
        fi
        EXIT_CODE=${PIPESTATUS[0]}
        RESULT=$(cat "$tmp_out")
        rm -f "$tmp_out"
        
        # 結果を JSON で保存
        jq -n \
            --arg agent "codex" \
            --arg phase "$PHASE" \
            --arg result "$RESULT" \
            --argjson success "$([ $EXIT_CODE -eq 0 ] && echo true || echo false)" \
            '{agent: $agent, phase: $phase, result: $result, success: $success, timestamp: now}' \
            > "$RESULT_FILE"
        
        log "✅ 完了 - 結果を保存: $RESULT_FILE"
        echo "" | tee -a "$LOG_FILE"
        echo "--- Codex Result (Phase: $PHASE) ---" | tee -a "$LOG_FILE"
        echo "-------------------" | tee -a "$LOG_FILE"
    fi
    sleep 2
done