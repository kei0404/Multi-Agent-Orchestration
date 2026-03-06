---
description: AIエージェント（Codex/Gemini）にタスクを個別に割り振って実行する
allowed-tools:
  - Bash
  - Read
---

$ARGUMENTS の内容を分析し、最適なAIエージェントにタスクをdispatchしてください。

## エージェント選択基準

| エージェント | 使用場面 | コマンド |
|-------------|---------|---------|
| Codex | コード実装、アルゴリズム設計、データモデル、コードレビュー | `codex` |
| Gemini | アーキテクチャ設計、調査、テスト設計、セキュリティ監査 | `gemini` |

## 実行手順

### 1. tmuxセッションの確認・起動

```bash
# セッションが存在するか確認
tmux has-session -t multi-agent 2>/dev/null && echo "セッション稼働中" || echo "セッションなし"
```

セッションがない場合は `orchestrate.sh` の `setup_tmux` を利用：

```bash
bash -c 'source orchestrator/orchestrate.sh && setup_tmux'
```

### 2. エージェントの起動確認

```bash
# 各ペインの状態確認
tmux list-panes -t multi-agent -F "Pane #{pane_index}: #{pane_title}"

# Codexペインのログ確認
tmux capture-pane -t multi-agent:0.1 -p | tail -5

# Geminiペインのログ確認
tmux capture-pane -t multi-agent:0.2 -p | tail -5
```

エージェントが起動していない場合：

```bash
# Codex起動
tmux send-keys -t multi-agent:0.1 "bash orchestrator/agents/codex-runner.sh" Enter

# Gemini起動
tmux send-keys -t multi-agent:0.2 "bash orchestrator/agents/gemini-runner.sh" Enter
```

### 3. タスクの派遣

引数を解析して、適切なエージェントにタスクを派遣します。

**Codexにタスク派遣：**
```bash
jq -n \
  --arg prompt "タスク内容" \
  --arg phase "dispatch" \
  --arg agent "codex" \
  '{prompt: $prompt, phase: $phase, agent: $agent, dispatched_at: now}' \
  > orchestrator/shared/task-queue/codex-task.json
```

**Geminiにタスク派遣：**
```bash
jq -n \
  --arg prompt "タスク内容" \
  --arg phase "dispatch" \
  --arg agent "gemini" \
  '{prompt: $prompt, phase: $phase, agent: $agent, dispatched_at: now}' \
  > orchestrator/shared/task-queue/gemini-task.json
```

### 4. 結果の監視と取得

```bash
# リアルタイムログ確認
tail -f orchestrator/shared/results/output.log

# 結果ファイル確認
cat orchestrator/shared/results/codex-result.json | jq .
cat orchestrator/shared/results/gemini-result.json | jq .
```

### 5. 結果の報告

結果JSONを読み込んで、以下の形式で要約してください：
- エージェント名
- 成功/失敗
- 結果の要約
- 次に推奨するアクション

## 使用例

```
# Codexにコードレビューを依頼
/dispatch codex このファイルのパフォーマンスを改善してください

# Geminiにアーキテクチャ調査を依頼
/dispatch gemini WebSocketとSSEの比較調査をしてください

# エージェント指定なし（自動選択）
/dispatch APIのエラーハンドリングを改善してください
```
