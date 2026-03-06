# orchestrator/check-deps.sh
#!/bin/bash

REQUIRED_TOOLS=("tmux" "jq" "claude" "codex" "gemini")
MISSING=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        MISSING+=("$tool")
    fi
done

# API キーチェック（Claude Code はアカウントログインでも動作するため除外）
REQUIRED_VARS=("OPENAI_API_KEY" "GOOGLE_API_KEY")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING+=("env:$var")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "❌ 以下が未設定/未インストールです:"
    printf '  - %s\n' "${MISSING[@]}"
    exit 1
fi

echo "✅ 依存関係チェック OK"