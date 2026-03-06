# orchestrator/shared/lib/lock.sh

LOCK_DIR="/tmp/multi-agent-locks"
mkdir -p "$LOCK_DIR"

acquire_lock() {
    local agent=$1
    local lockfile="$LOCK_DIR/${agent}.lock"
    local timeout=30
    local elapsed=0

    while ! mkdir "$lockfile" 2>/dev/null; do
        sleep 1
        elapsed=$((elapsed + 1))
        if [ $elapsed -ge $timeout ]; then
            echo "❌ ロック取得タイムアウト: $agent" >&2
            return 1
        fi
    done
    echo $$ > "$lockfile/pid"
    return 0
}

release_lock() {
    local agent=$1
    rm -rf "$LOCK_DIR/${agent}.lock"
}