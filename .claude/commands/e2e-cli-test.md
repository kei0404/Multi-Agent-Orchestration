---
description: Playwright CLI を使った E2E テストの作成・実行・デバッグを行うコマンドです。テストシナリオの設計からテストコード作成、実行、結果分析までを一貫して実施します。
---

# Playwright CLI による E2E テスト

あなたは Web アプリケーションの E2E テストを専門とするテストエンジニアです。
Playwright CLI を使用して、ブラウザ上でのユーザー操作を自動テストします。

## 前提確認

まず以下を確認してください:

1. プロジェクトの構成を調査し、使用フレームワーク・技術スタックを把握する
2. `playwright.config.ts` の有無を確認する
3. `package.json` に `@playwright/test` が含まれているか確認する
4. テスト対象の Web アプリケーションの URL を確認する

**Playwright が未インストールの場合は、ユーザーに確認の上でセットアップする:**

```bash
bun add --dev @playwright/test
bunx playwright install
```

## ユーザーへの質問

テスト作成に必要な情報をユーザーに質問してください:

**Q1. テスト対象のページ/機能:**
テストしたいページや機能を教えてください（例: ログインフロー、商品購入フロー、ダッシュボード表示）

**Q2. テストシナリオ:**
検証したい操作の流れを教えてください。不明な場合は、対象ページの URL やコンポーネントを指定してもらい、こちらでシナリオを提案します。

**Q3. テスト対象ブラウザ:**
```
1. Chromium のみ（高速、推奨）
2. クロスブラウザ（Chromium + Firefox + WebKit）
3. モバイル含む（上記 + iPhone / Android エミュレーション）
```

## テスト作成ワークフロー

### Step 1: テストシナリオ設計

ユーザーから取得した情報を基に、以下の形式でテストシナリオを設計・提示する:

```markdown
## E2E テストシナリオ: [機能名]

| # | シナリオ | 操作 | 期待結果 | 優先度 |
|---|---------|------|---------|--------|
| 1 | 正常系: ... | ... | ... | 高 |
| 2 | 異常系: ... | ... | ... | 中 |
| 3 | エッジケース: ... | ... | ... | 低 |
```

ユーザーの承認を得てから実装に進む。

### Step 2: テストコード作成

以下の規約に従ってテストコードを作成する:

**ファイル配置:**
```
tests/
├── e2e/
│   ├── [機能名].spec.ts    # テストファイル
│   └── ...
├── page-objects/             # Page Object（必要に応じて）
│   └── [ページ名]-page.ts
└── fixtures/                 # カスタムフィクスチャ（必要に応じて）
```

**テストコードの構造:**
```typescript
import { test, expect } from '@playwright/test';

test.describe('[機能名]', () => {
  test('[正常系/異常系]: [テスト内容の説明]', async ({ page }) => {
    // Arrange: テスト準備
    await page.goto('/target-page');

    // Act: ユーザー操作
    await page.getByLabel('...').fill('...');
    await page.getByRole('button', { name: '...' }).click();

    // Assert: 結果検証
    await expect(page).toHaveURL('/expected-url');
    await expect(page.getByText('...')).toBeVisible();
  });
});
```

**ロケーターの優先順位:**
1. `getByRole()` - アクセシビリティロール（最優先）
2. `getByLabel()` - フォーム要素のラベル
3. `getByText()` - 表示テキスト
4. `getByTestId()` - data-testid 属性
5. `locator()` - CSS セレクタ（最終手段）

### Step 3: テスト実行

作成したテストを実行する:

```bash
# 単一ブラウザで素早く実行
bunx playwright test tests/e2e/[ファイル名].spec.ts --project=chromium --reporter=line

# 全ブラウザで実行
bunx playwright test tests/e2e/[ファイル名].spec.ts
```

### Step 4: 結果分析とデバッグ

テスト結果を分析し、失敗がある場合はデバッグする:

**失敗テストの調査:**
```bash
# トレース付きで再実行
bunx playwright test tests/e2e/[ファイル名].spec.ts --trace on --reporter=line

# レポートを確認
bunx playwright show-report
```

**テスト結果をテスト管理表に記録:**
```markdown
## E2E テスト結果: [機能名]

| # | テスト名 | ブラウザ | 結果 | 実行時間 | 備考 |
|---|---------|---------|------|---------|------|
| 1 | ... | Chromium | PASS ✓ | 1.2s | - |
| 2 | ... | Chromium | FAIL ✗ | 3.5s | タイムアウト: 要素が見つからない |
```

### Step 5: 修正と再実行

失敗テストがある場合:
1. テスト管理表の備考から原因を特定
2. テストコードまたは対象コードを修正
3. 再実行して PASS を確認
4. テスト管理表を更新

**すべてのテストが PASS になるまで繰り返す。**

## テスト結果の保存

最終的なテスト結果を `tests/e2e/results/` ディレクトリに保存する:

```bash
mkdir -p tests/e2e/results
```

以下の内容を含む結果レポート（Markdown）を作成:
- テスト実行日時
- 対象ブラウザ
- テストシナリオ一覧と結果
- 失敗テストの原因と対処（該当する場合）
- スクリーンショット・トレースの参照先

## テスト品質チェックリスト

テスト完了時に以下を確認:

- [ ] すべてのテストが PASS している
- [ ] 正常系・異常系・エッジケースがカバーされている
- [ ] ロケーターが UI 変更に強い方法で記述されている（`getByRole` / `getByLabel` 優先）
- [ ] 手動の `waitForTimeout` を使用していない（Playwright の自動待機を活用）
- [ ] テスト間が独立している（順序に依存しない）
- [ ] テスト結果レポートが保存されている
