---
name: pptx-creator
description: PowerPointプレゼンテーション(.pptx)を自動生成するスキル。python-pptxを使用し、会社ロゴ（右上）とフッター著作権表示を全スライドに統一配置する。「パワポを作って」「PowerPointを作成して」「プレゼン資料を作って」「スライドを生成して」などのリクエスト時に使用。
# model: inherit
# allowed-tools: "Read,Write,Bash(python3:*),Glob,Grep"
---

# PPTX Creator

python-pptxを使ったPowerPointプレゼンテーション自動生成スキル。

## ブランディング仕様

全スライドに以下を統一適用する：

- **ロゴ**: 右上に配置（幅1.2インチ、右余白0.3インチ、上余白0.2インチ）
- **フッター**: 中央揃えで `© {年} Ⓢsystems DESIGN Co.Ltd` を配置（8pt、#666666）

## ワークフロー

### 1. 要件確認

ユーザーにプレゼン内容をヒアリング：
- テーマ・目的
- スライド枚数の目安
- 含めたい内容やセクション

### 2. スライド構成の設計

以下のスライドタイプから構成を組み立てる：

| タイプ | 用途 | 必須フィールド |
|--------|------|----------------|
| `title` | 表紙 | title, subtitle |
| `content` | 箇条書き | title, body(リスト) |
| `section` | セクション区切り | title |
| `two_column` | 2カラム比較 | title, left, right |
| `blank` | 自由配置 | なし |

### 3. 生成手順

1. スライドデータをJSON形式で構造化
2. `scripts/create_pptx.py` を実行してPPTXファイルを生成

```bash
# JSON → PPTX変換
python3 scripts/create_pptx.py slides.json output.pptx
```

JSON構造例：

```json
[
  {"type": "title", "title": "プロジェクト概要", "subtitle": "2025年度 第1四半期報告"},
  {"type": "content", "title": "アジェンダ", "body": ["背景と目的", "進捗状況", "今後の計画"]},
  {"type": "section", "title": "背景と目的"},
  {"type": "content", "title": "プロジェクトの背景", "body": ["市場動向の変化", "顧客ニーズの多様化", "DX推進の加速"]},
  {"type": "two_column", "title": "比較", "left": ["案A", "コスト低", "実装期間短"], "right": ["案B", "拡張性高", "保守性高"]}
]
```

### 4. ロゴ設定

ロゴファイルは `assets/sdcロゴ（透明）.png`（透過PNG）に格納済み。
スクリプトが自動検出するため追加設定は不要。

### 5. 依存関係

```bash
pip install python-pptx
```

## Claude.ai での使用方法

Claude.aiのプロジェクト機能で使う場合は [references/claude-ai-instructions.md](references/claude-ai-instructions.md) を参照。
