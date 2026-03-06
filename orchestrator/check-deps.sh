# orchestrator/check-deps.sh
#!/bin/bash

REQUIRED_TOOLS=("tmux" "jq" "claude" "codex" "gemini")
MISSING=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        MISSING+=("$tool")
    fi
done

REQUIRED_VARS=("ANTHROPIC_API_KEY" "OPENAI_API_KEY" "GOOGLE_API_KEY")
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
```

---

### 設定項目チェックリスト
```
必須設定
 ✅ ~/.claude/settings.json      → Claude Code のパーミッション
 ✅ .claude/settings.json        → プロジェクトローカルパーミッション
 ✅ ~/.codex/config.toml         → Codex の承認モード・モデル指定
 ✅ ~/.gemini/settings.json      → Gemini のモデル指定
 ✅ .env                         → API キー一元管理
 ✅ CLAUDE.md / GEMINI.md        → 各エージェントの役割定義

堅牢性設定
 ✅ lock.sh                      → ファイル競合防止
 ✅ retry.sh                     → リトライ・フォールバック
 ✅ state.json                   → フェーズ状態追跡
 ✅ check-deps.sh                → 起動前依存チェック

表示・運用設定
 ✅ tmux pane-border-status      → ペインタイトル表示
 ✅ display.sh                   → リアルタイム進捗更新
 ✅ .gitignore                   → APIキー・一時ファイル除外