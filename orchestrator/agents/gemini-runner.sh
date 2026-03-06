# orchestrator/agents/gemini-runner.sh
#!/bin/bash
# Gemini エージェントラッパー

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

set -a
source "$SCRIPT_DIR/../../.env"
[ -f "$SCRIPT_DIR/../../.gemini/.env" ] && source "$SCRIPT_DIR/../../.gemini/.env"
set +a

SHARED_DIR="$SCRIPT_DIR/../shared"
TASK_FILE="$SHARED_DIR/task-queue/gemini-task.json"
RESULT_FILE="$SHARED_DIR/results/gemini-result.json"
LOG_FILE="$SHARED_DIR/results/output.log"

log() {
    echo "[$(date '+%H:%M:%S')] [Gemini] $1" | tee -a "$LOG_FILE"
}

log "🟢 Gemini Agent 起動 - タスク待機中..."

while true; do
    if [ -f "$TASK_FILE" ]; then
        TASK=$(cat "$TASK_FILE")
        PROMPT=$(echo "$TASK" | jq -r '.prompt')
        PHASE=$(echo "$TASK" | jq -r '.phase')
        
        log "📥 タスク受信 (Phase: $PHASE): $PROMPT"
        rm "$TASK_FILE"
        
        log "⚙️  Gemini 実行中..."
        tmp_out="/tmp/gemini-result-$$.txt"
        gemini \
            --model "${GEMINI_MODEL:-gemini-2.5-pro}" \
            --yolo \
            --prompt "$PROMPT" 2>&1 | tee "$tmp_out"
        EXIT_CODE=${PIPESTATUS[0]}
        RESULT=$(cat "$tmp_out")
        rm -f "$tmp_out"
        
        jq -n \
            --arg agent "gemini" \
            --arg phase "$PHASE" \
            --arg result "$RESULT" \
            --argjson success "$([ $EXIT_CODE -eq 0 ] && echo true || echo false)" \
            '{agent: $agent, phase: $phase, result: $result, success: $success, timestamp: now}' \
            > "$RESULT_FILE"
        
        log "✅ 完了 - 結果を保存: $RESULT_FILE"
        echo "" | tee -a "$LOG_FILE"
        echo "--- Gemini Result (Phase: $PHASE) ---" | tee -a "$LOG_FILE"
        echo "--------------------" | tee -a "$LOG_FILE"
    fi
    sleep 2
done