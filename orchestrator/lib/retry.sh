# orchestrator/shared/lib/retry.sh

dispatch_with_retry() {
    local agent=$1
    local prompt=$2
    local phase=$3
    local max_retry=${MAX_RETRY:-3}
    local attempt=0

    while [ $attempt -lt $max_retry ]; do
        dispatch_task "$agent" "$prompt" "$phase"
        RESULT=$(wait_for_result "$agent" "$ORCHESTRATOR_TIMEOUT")

        if [ $? -eq 0 ]; then
            local success=$(echo "$RESULT" | jq -r '.success')
            if [ "$success" = "true" ]; then
                echo "$RESULT"
                return 0
            fi
        fi

        attempt=$((attempt + 1))
        log "⚠️  リトライ $attempt/$max_retry: $agent"
        sleep $((attempt * 5))  # バックオフ
    done

    # フォールバック: Claude 自身が処理
    log "🔄 フォールバック: Claude が直接処理します"
    echo "{\"agent\":\"claude-fallback\",\"result\":\"FALLBACK_NEEDED\",\"phase\":\"$phase\"}"
}