# orchestrator/agents/codex-runner.sh
#!/bin/bash
# Codex エージェントラッパー - タスクを受け取り実行して結果を返す

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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
        
        # Codex 実行
        log "⚙️  Codex 実行中..."
        RESULT=$(codex exec \
            --full-auto \
            "$PROMPT" 2>&1)
        EXIT_CODE=$?
        
        # 結果を JSON で保存
        jq -n \
            --arg agent "codex" \
            --arg phase "$PHASE" \
            --arg result "$RESULT" \
            --argjson success "$([ $EXIT_CODE -eq 0 ] && echo true || echo false)" \
            '{agent: $agent, phase: $phase, result: $result, success: $success, timestamp: now}' \
            > "$RESULT_FILE"
        
        log "✅ 完了 - 結果を保存: $RESULT_FILE"
        echo "--- Codex Result ---" | tee -a "$LOG_FILE"
        echo "$RESULT" | tee -a "$LOG_FILE"
        echo "-------------------" | tee -a "$LOG_FILE"
    fi
    sleep 2
done