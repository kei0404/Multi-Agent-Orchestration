# [プロジェクト名] 実装計画書

## メタ情報
- 作成日: YYYY-MM-DD
- 参照仕様: ./spec.md
- 見積工数: X日
- 担当: [担当者/Claude]

## 実装フェーズ

### Phase 1: 環境構築（Day 1）
- [ ] **1.1** プロジェクト初期化
  - 内容: Next.js 14 プロジェクト作成、TypeScript設定
  - コマンド: `npx create-next-app@latest --typescript`
  - 完了条件: `npm run dev` で起動確認

- [ ] **1.2** Supabase連携
  - 内容: Supabase クライアント設定、環境変数
  - ファイル: `lib/supabase.ts`, `.env.local`
  - 完了条件: Supabaseへの接続テスト成功

### Phase 2: データベース設計（Day 2）
- [ ] **2.1** テーブル作成
  - 内容: employees, departments, skills テーブル
  - SQL: `supabase/migrations/001_init.sql`
  - 完了条件: マイグレーション成功

- [ ] **2.2** 型定義生成
  - 内容: Supabase型をTypeScriptに変換
  - コマンド: `supabase gen types typescript`
  - 完了条件: `types/database.types.ts` 生成

### Phase 3: 基本機能実装（Day 3-5）
- [ ] **3.1** 社員一覧画面
  - 内容: 社員一覧の表示、ページネーション
  - ファイル: `app/employees/page.tsx`
  - 完了条件: 全社員が一覧表示される

- [ ] **3.2** 社員詳細画面
  - 内容: 社員の詳細情報表示
  - ファイル: `app/employees/[id]/page.tsx`
  - 完了条件: IDから社員情報が取得・表示される

### Phase 4: 検索・フィルター機能（Day 6-7）
- [ ] **4.1** 検索UI
  - 内容: 検索フォーム、フィルターコンポーネント
  - ファイル: `components/SearchForm.tsx`
  - 完了条件: 検索条件が入力できる

- [ ] **4.2** 検索API
  - 内容: 検索エンドポイント実装
  - ファイル: `app/api/employees/search/route.ts`
  - 完了条件: 条件に合致する社員が返却される

### Phase 5: テスト・品質保証（Day 8）
- [ ] **5.1** 単体テスト
  - 内容: 主要コンポーネントのテスト
  - コマンド: `npm run test`
  - 完了条件: テストカバレッジ80%以上

- [ ] **5.2** E2Eテスト
  - 内容: 主要シナリオの自動テスト
  - コマンド: `npm run test:e2e`
  - 完了条件: 全シナリオパス

## 依存関係図


## リスクと対策
| リスク | 影響度 | 対策 |
|--------|--------|------|
| Supabase接続不可 | 高 | ローカルPostgreSQLで代替 |
| 型定義の不整合 | 中 | マイグレーション毎に再生成 |

## 完了定義（Definition of Done）
- [ ] 全タスクのチェックボックスがON
- [ ] テストが全てパス
- [ ] ドキュメント更新
- [ ] コードレビュー完了