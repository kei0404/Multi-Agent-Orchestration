---
description: マルチエージェント（Claude/Codex/Gemini）オーケストレーションを起動してタスクを実行する
allowed-tools:
  - Shell
  - Read
---

tmuxセッションでマルチエージェントオーケストレーションを起動し、指定されたタスクを実行します。

## 実行手順

### 1. tmuxセッション起動

```bash
cd /home/kkatano/projects/community-chat
bash orchestrator/tmux-setup.sh
```

これにより以下のペイン構成でtmuxセッション `multi-agent` が起動します：
- Pane 0: 🤖 Claude Code (Orchestrator)
- Pane 1: ⚡ Codex Agent
- Pane 2: ✨ Gemini Agent
- Pane 3: 📊 Output Log

### 2. オーケストレーション実行

tmuxセッション起動後、Pane 0（Orchestrator）で以下を実行：

```bash
bash orchestrator/orchestrate.sh "$ARGUMENTS"
```

### 実行フロー

1. **Phase 1: 設計・調査**
   - Codex: 実装計画とコード構造の分析
   - Gemini: ベストプラクティスとアーキテクチャの調査

2. **Phase 2: 実装**
   - Codex: コア機能の実装
   - Gemini: テストとドキュメント作成

3. **Phase 3: レビュー・最適化**
   - Codex: 実装レビューと最適化提案
   - Gemini: セキュリティ監査とパフォーマンス分析

### 結果の確認

- リアルタイムログ: Pane 3（Output Log）
- 詳細結果: `orchestrator/shared/results/` ディレクトリ
  - `merged-phase1.json`: Phase 1統合結果
  - `merged-phase2.json`: Phase 2統合結果
  - `merged-phase3.json`: Phase 3統合結果
  - `output.log`: 全体のログ

## セッション操作

```bash
# セッションに接続
tmux attach -t multi-agent

# セッション一覧
tmux ls

# セッション終了
tmux kill-session -t multi-agent
```

## 使用例

```bash
# 認証機能の実装
orchestrate "ユーザー認証機能をJWT方式で実装する"

# データベース設計
orchestrate "チャット履歴を保存するためのSupabaseスキーマを設計"

# パフォーマンス最適化
orchestrate "APIレスポンス時間を改善するキャッシュ戦略を提案"
```

## 注意事項

- tmuxがインストールされていること
- `codex` コマンドがパスに通っていること（Codexエージェント用）
- `gemini` コマンドがパスに通っていること（Geminiエージェント用）
- `jq` コマンドがインストールされていること（JSON処理用）
