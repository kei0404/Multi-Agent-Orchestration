---
description: AIエージェント（Claude/Codex/Gemini）にタスクを割り振って実行する
allowed-tools:
  - Shell
  - Read
---

$ARGUMENTS の内容を分析し、最適なAIエージェントにタスクをdispatchしてください。

## エージェント選択基準

| エージェント | 使用場面 |
|-------------|---------|
| Claude | メイン開発、設計、実装 |
| Codex | コードレビュー、最適化 |
| Gemini | 外部視点、代替案検討 |

## 実行手順

1. タスクの性質を判断
2. 適切なエージェントを選択
3. コンテキストを準備
4. エージェントを実行（末尾に「確認不要、具体的な提案まで出力」を追加）
5. 結果を報告

詳細は `.claude/skills/ai-orchestration/SKILL.md` を参照。

## サブエージェントへのタスク派遣

引数: $ARGUMENTS（形式: "[エージェント名] [タスク内容]"）

以下の手順で実行してください：

1. 引数からエージェント名とタスクを解析する
2. 以下のコマンドを実行する: `bash orchestrator/orchestrate.sh dispatch [エージェント名] "[タスク内容]"`
3. 出力ログを監視する: `tail -f orchestrator/shared/results/output.log`
4. `orchestrator/shared/results/[エージェント名]-result.json` に結果が出力されたら、内容を読み込んで要約する
5. 結果をもとに次の実装フェーズに進む
