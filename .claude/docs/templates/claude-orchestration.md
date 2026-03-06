# .claude/CLAUDE.md

## メタデータブロック

**[プロジェクト名]** — マルチエージェントオーケストレーションシステム
- バージョン情報
- ライセンス情報（指定された場合）
- 作成日/更新日
- スタック: 例）Claude Code / Codex CLI / Gemini CLI
- 担当: [名前]
- 期間: [YYYY-MM 〜 YYYY-MM]

## 役割
Claude Codeをオーケストレーターとして、CodexとGeminiを協調動作させるマルチエージェントシステムの統括。

## 回答スタイル
- 挨拶・前置き・絵文字は禁止
- 結論から先に述べる

## 振る舞い
- 不明点は実装前に1つだけ質問する
- `spec.md` → `plan.md` → 実装の順を守る
- `spec.md` に記載のない機能は追加しない

## 完了条件
[完了の定義と検証コマンド]

## ディレクトリ構成
[プロジェクトの基本構成]

- `docs/spec.md` — 要件定義（変更時は必ず参照）
- `docs/plans/` — 実装計画（タスク完了時に更新）
- `orchestrator/shared/results/` — エージェント結果統合ディレクトリ

## Multi-Agent Orchestration Skills

このプロジェクトはClaude Codeをオーケストレーターとして、
CodexとGeminiを協調動作させるマルチエージェントシステムです。

### Available Skills (Custom Commands)

#### /dispatch - エージェント派遣
特定のエージェントにタスクを派遣します。
```
Usage: /dispatch [agent] [task]
- agent: codex | gemini | all
- task: 実行するタスクの説明
```

#### /parallel - 並列実行
CodexとGeminiに異なる視点からタスクを同時実行させます。
```
Usage: /parallel [phase] [task_description]
```

#### /phase - フェーズ進行
実装フェーズを進めます（design → implement → review → optimize）
```
Usage: /phase next
```

### Orchestration Rules

1. **設計フェーズ**: CodexとGeminiに並列で調査・設計させる
2. **実装フェーズ**: Codexにコード実装、Geminiにテスト・ドキュメント生成
3. **レビューフェーズ**: 両エージェントの出力を交差レビューさせる
4. **最適化フェーズ**: 統合結果をもとに最終最適化

### Agent Roles

- **Codex**: コード実装、アルゴリズム設計、デバッグ
- **Gemini**: アーキテクチャ設計、リサーチ、テスト設計、ドキュメント

### Result Integration

各エージェントの結果は `orchestrator/shared/results/` に保存され、
次のフェーズへの入力として自動的に使用されます。

## 禁止事項
[守るべき規約・禁止事項]

---
## 重要な注意事項および禁止事項
[**禁止事項や守るべき規約などを記入する**]

---
## いつPLANSを参照するかの規定
- PLANS.md が唯一の決定事項の所在とする
- `docs/plans` 内の最新の `PLANS.md` を参照する
- 実装や調査が 2 ステップ以上になりそうなとき参照する
- 実装や調査が30 分を超える見込みの作業でを参照する

---
## 参照ドキュメント
[**開発において参照すべきドキュメントを記述する**]
*詳細ルール* → `rules/`
*スキル集* → `skills/`
