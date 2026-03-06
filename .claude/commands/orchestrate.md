---
description: マルチエージェント（Claude/Codex/Gemini）オーケストレーションを起動してタスクを実行する
allowed-tools:
  - Bash
  - Read
---

# 必須: ai-orchestration スキルの読み込み

**本コマンド実行時、最初のアクションとして必ず以下を実行すること：**

1. `Read` ツールで `.claude/skills/ai-orchestration/SKILL.md` を読み込む
2. 読み込んだ内容（ペイン構成、エージェント役割、ワークフローパターン、tmux 自動起動の仕様）に従ってオーケストレーションを実行する

ai-orchestration スキルが読み込まれていない状態では、オーケストレーションを開始しないこと。

## 実行手順

### 1. tmuxセッション起動とオーケストレーション実行

以下のコマンドを実行してください（tmuxセッションの起動・各エージェント用ペインの自動分割・エージェント起動・タスク実行を一括で行います）：

```bash
bash orchestrator/orchestrate.sh "$ARGUMENTS"
```

このコマンドにより：
1. tmuxセッション `multi-agent` が自動起動（既存の場合はスキップ）
2. ターミナルが各エージェント用に分割され、Codex と Gemini がそれぞれ専用ペインで自動起動
3. 3フェーズの並列実行が開始
4. tmux に自動アタッチされ、各ペインの実行結果をリアルタイムで確認可能（デタッチ: `Ctrl+B` → `D`）

### ペイン構成

- Pane 0: 🤖 Claude Code (Orchestrator)
- Pane 1: ⚡ Codex Agent（Codex の実行結果が順次表示、ペインタイトルに実行状態を表示）
- Pane 2: ✨ Gemini Agent（Gemini の実行結果が順次表示、ペインタイトルに実行状態を表示）
- Pane 3: 📊 Output Log（統合リアルタイムログ）

### 2. 実行フロー

1. **Phase 1: 設計・調査**（Codex + Gemini 並列）
   - Codex: 実装計画とコード構造の分析
   - Gemini: ベストプラクティスとアーキテクチャの調査

2. **Phase 2: 実装**（Codex + Gemini 並列）
   - Codex: コア機能の実装
   - Gemini: テストとドキュメント作成

3. **Phase 3: レビュー・最適化**（Codex + Gemini 並列）
   - Codex: 実装レビューと最適化提案
   - Gemini: セキュリティ監査とパフォーマンス分析

### 3. 結果の確認

- リアルタイムログ: Pane 3（Output Log）または `tail -f orchestrator/shared/results/output.log`
- 詳細結果: `orchestrator/shared/results/` ディレクトリ
  - `merged-phase1.json`: Phase 1統合結果
  - `merged-phase2.json`: Phase 2統合結果
  - `merged-phase3.json`: Phase 3統合結果

### 4. エージェントごとの挙動確認

tmux に自動アタッチ後、各ペインで以下を確認できる：

| ペイン | 確認内容 |
|--------|----------|
| Pane 1 (Codex) | `🟢 Codex Agent 起動 - タスク待機中...` → タスク受信後、Codex の実行結果が順次表示される |
| Pane 2 (Gemini) | `🟢 Gemini Agent 起動 - タスク待機中...` → タスク受信後、Gemini の実行結果が順次表示される |
| Pane 3 (Output Log) | 統合ログがリアルタイムで表示される |

ペインが表示されない場合やエージェントが起動していない場合は、セッションを再起動：

```bash
tmux kill-session -t multi-agent 2>/dev/null
bash orchestrator/orchestrate.sh "$ARGUMENTS"
```

### 5. セッション操作

```bash
# セッションに接続（ペインを直接確認する場合）
tmux attach -t multi-agent

# セッション一覧
tmux ls

# ペイン状態確認
tmux list-panes -t multi-agent -F "Pane #{pane_index}: #{pane_title}"

# 各ペインの最新出力を確認（エージェント挙動の検証）
tmux capture-pane -t multi-agent:0.1 -p | tail -20   # Codex
tmux capture-pane -t multi-agent:0.2 -p | tail -20   # Gemini

# セッション終了
tmux kill-session -t multi-agent
```
