---
name: write-unit-tests
description: "単体テスト・結合テストの作成時に使用する。新規テストの作成、テストカバレッジの追加、失敗したテストの修正時に適用する。Vitestのパターン、TestEditorの使い方、テストファイルの構成をカバーする。"
---

# テストの書き方

単体テスト・結合テストには Vitest を使用する。テストはリポジトリルートではなく、各ワークスペースディレクトリから実行する。

## テストファイルの配置

**単体テスト** - ソースファイルと同じディレクトリに配置：

```
packages/editor/src/lib/primitives/Vec.ts
packages/editor/src/lib/primitives/Vec.test.ts  # 同じディレクトリ
```

**結合テスト** - `src/test/` ディレクトリに配置：

```
packages/tldraw/src/test/SelectTool.test.ts
packages/tldraw/src/test/commands/createShape.test.ts
```

**シェイプ/ツールのテスト** - 実装と同じディレクトリに配置：

```
packages/tldraw/src/lib/shapes/arrow/ArrowShapeUtil.test.ts
packages/tldraw/src/lib/shapes/arrow/ArrowShapeTool.test.ts
```

## テスト実行先のワークスペース

- **packages/editor**: コアプリミティブ、ジオメトリ、マネージャー、エディタの基本機能
- **packages/tldraw**: デフォルトのシェイプ/ツールが必要なもの（ほとんどの結合テスト）

```bash
cd packages/tldraw && yarn test run
cd packages/tldraw && yarn test run --grep "SelectTool"
```

## TestEditor vs Editor

結合テストには `TestEditor` を使用（デフォルトのシェイプ/ツールを含む）：

```typescript
import { createShapeId } from '@tldraw/editor'
import { TestEditor } from './TestEditor'

let editor: TestEditor

beforeEach(() => {
	editor = new TestEditor()
	editor.selectAll().deleteShapes(editor.getSelectedShapeIds())
})

afterEach(() => {
	editor?.dispose()
})
```

エディタのセットアップやカスタム設定のテストには素の `Editor` を使用：

```typescript
import { Editor, createTLStore } from '@tldraw/editor'

beforeEach(() => {
	editor = new Editor({
		shapeUtils: [CustomShape],
		bindingUtils: [],
		tools: [CustomTool],
		store: createTLStore({ shapeUtils: [CustomShape], bindingUtils: [] }),
		getContainer: () => document.body,
	})
})
```

## よく使う TestEditor メソッド

```typescript
// ポインタ操作のシミュレーション
editor.pointerDown(x, y, options?)
editor.pointerMove(x, y, options?)
editor.pointerUp(x, y, options?)
editor.click(x, y, shapeId?)
editor.doubleClick(x, y, shapeId?)

// キーボード操作のシミュレーション
editor.keyDown(key, options?)
editor.keyUp(key, options?)

// 状態のアサーション
editor.expectToBeIn('select.idle')
editor.expectToBeIn('select.crop.idle')

// シェイプのアサーション
editor.expectShapeToMatch({ id, x, y, props: { ... } })

// シェイプ操作
editor.createShapes([{ id, type, x, y, props }])
editor.updateShapes([{ id, type, props }])
editor.getShape(id)
editor.select(id1, id2)
editor.selectAll()
editor.selectNone()
editor.getSelectedShapeIds()
editor.getOnlySelectedShape()

// ツール操作
editor.setCurrentTool('arrow')
editor.getCurrentToolId()

// Undo/Redo
editor.undo()
editor.redo()
```

## ポインタイベントのオプション

```typescript
editor.pointerDown(100, 100, {
	target: 'shape', // 'canvas' | 'shape' | 'handle' | 'selection'
	shape: editor.getShape(id),
})

editor.pointerDown(150, 300, {
	target: 'selection',
	handle: 'bottom', // 'top' | 'bottom' | 'left' | 'right' | corners
})

editor.doubleClick(550, 550, {
	target: 'selection',
	handle: 'bottom_right',
})
```

## セットアップパターン

### シェイプIDを使った標準セットアップ

```typescript
const ids = {
	box1: createShapeId('box1'),
	box2: createShapeId('box2'),
	arrow1: createShapeId('arrow1'),
}

vi.useFakeTimers()

beforeEach(() => {
	editor = new TestEditor()
	editor.selectAll().deleteShapes(editor.getSelectedShapeIds())
	editor.createShapes([
		{ id: ids.box1, type: 'geo', x: 100, y: 100, props: { w: 100, h: 100 } },
		{ id: ids.box2, type: 'geo', x: 300, y: 300, props: { w: 100, h: 100 } },
	])
})

afterEach(() => {
	editor?.dispose()
})
```

### 再利用可能なprops

```typescript
const imageProps = {
	assetId: null,
	playing: true,
	url: '',
	w: 1200,
	h: 800,
}

editor.createShapes([
	{ id: ids.imageA, type: 'image', x: 100, y: 100, props: imageProps },
	{ id: ids.imageB, type: 'image', x: 500, y: 500, props: { ...imageProps, w: 600, h: 400 } },
])
```

### ヘルパー関数

```typescript
function arrow(id = ids.arrow1) {
	return editor.getShape(id) as TLArrowShape
}

function bindings(id = ids.arrow1) {
	return getArrowBindings(editor, arrow(id))
}
```

## vi.spyOn によるモック

```typescript
// 戻り値のモック
vi.spyOn(editor, 'getIsReadonly').mockReturnValue(true)

// 実装のモック
const isHiddenSpy = vi.spyOn(editor, 'isShapeHidden')
isHiddenSpy.mockImplementation((shape) => shape.id === ids.hiddenShape)

// 呼び出しの検証
const spy = vi.spyOn(editor, 'setSelectedShapes')
editor.selectAll()
expect(spy).toHaveBeenCalled()
expect(spy).not.toHaveBeenCalled()

// 必ずリストアする
isHiddenSpy.mockRestore()
```

## フェイクタイマー

```typescript
vi.useFakeTimers()

// アニメーションフレームのモック
window.requestAnimationFrame = (cb) => setTimeout(cb, 1000 / 60)
window.cancelAnimationFrame = (id) => clearTimeout(id)

it('handles animation', () => {
	editor.alignShapes(editor.getSelectedShapeIds(), 'right')
	vi.advanceTimersByTime(1000)
	// アニメーション完了後にアサート
})
```

## アサーション

### シェイプのマッチング

```typescript
// 部分一致（最も一般的）
expect(editor.getShape(id)).toMatchObject({
	type: 'geo',
	x: 100,
	props: { w: 100 },
})

editor.expectShapeToMatch({
	id: ids.box1,
	x: 350,
	y: 350,
})

// 浮動小数点のマッチング（カスタムマッチャー）
expect(result).toCloselyMatchObject({
	props: { normalizedAnchor: { x: 0.5, y: 0.75 } },
})
```

### 配列のアサーション

```typescript
expect(editor.getSelectedShapeIds()).toMatchObject([ids.box1])
expect(Array.from(selectedIds).sort()).toEqual([id1, id2, id3].sort())
expect(shapes).toContain('geo')
expect(shapes).not.toContain(ids.lockedShape)
```

### 状態のアサーション

```typescript
editor.expectToBeIn('select.idle')
editor.expectToBeIn('select.brushing')
editor.expectToBeIn('select.crop.idle')
```

## Undo/Redo のテスト

```typescript
it('handles undo/redo', () => {
	editor.doubleClick(550, 550, ids.image)
	editor.expectToBeIn('select.crop.idle')

	editor.updateShape({ id: ids.image, type: 'image', props: { crop: newCrop } })

	editor.undo()
	editor.expectToBeIn('select.crop.idle')
	expect(editor.getShape(ids.image)!.props.crop).toMatchObject(originalCrop)

	editor.redo()
	expect(editor.getShape(ids.image)!.props.crop).toMatchObject(newCrop)
})
```

## TypeScript 型のテスト

```typescript
it('Uses typescript generics', () => {
	expect(() => {
		// @ts-expect-error - 不正なpropsの型
		editor.createShape({ id, type: 'geo', props: { w: 'OH NO' } })

		// @ts-expect-error - 未知のprop
		editor.createShape({ id, type: 'geo', props: { foo: 'bar' } })

		// 正しい使い方
		editor.createShape<TLGeoShape>({ id, type: 'geo', props: { w: 100 } })
	}).toThrow()
})
```

## カスタムシェイプのテスト

```typescript
declare module '@tldraw/tlschema' {
	export interface TLGlobalShapePropsMap {
		'my-custom-shape': { w: number; h: number; text: string | undefined }
	}
}

class CustomShape extends ShapeUtil<ICustomShape> {
	static override type = 'my-custom-shape'
	static override props: RecordProps<ICustomShape> = {
		w: T.number,
		h: T.number,
		text: T.string.optional(),
	}
	getDefaultProps() {
		return { w: 200, h: 200, text: '' }
	}
	getGeometry(shape) {
		return new Rectangle2d({ width: shape.props.w, height: shape.props.h })
	}
	indicator() {}
	component() {}
}
```

## 副作用のテスト

```typescript
beforeEach(() => {
	editor = new TestEditor()
	editor.sideEffects.registerAfterChangeHandler('instance_page_state', (prev, next) => {
		if (prev.croppingShapeId !== next.croppingShapeId) {
			// 状態変更のハンドリング
		}
	})
})
```

## イベントのテスト

```typescript
it('emits wheel events', () => {
	const handler = vi.fn()
	editor.on('event', handler)

	editor.dispatch({
		type: 'wheel',
		name: 'wheel',
		delta: { x: 0, y: 10, z: 0 },
		point: { x: 100, y: 100, z: 1 },
		shiftKey: false,
		// ... その他の修飾キー
	})
	editor.emit('tick', 16) // バッチされたイベントをフラッシュ

	expect(handler).toHaveBeenCalledWith(expect.objectContaining({ name: 'wheel' }))
})
```

## メソッドチェーン

```typescript
editor
	.expectToBeIn('select.idle')
	.select(ids.imageA, ids.imageB)
	.doubleClick(550, 550, { target: 'selection', handle: 'bottom_right' })
	.expectToBeIn('select.idle')

editor.setCurrentTool('arrow').pointerDown(0, 0).pointerMove(100, 100).pointerUp()
```

## テストの実行

```bash
cd packages/tldraw && yarn test run
cd packages/tldraw && yarn test run --grep "arrow"
cd packages/editor && yarn test run --grep "Vec"

# ウォッチモード
cd packages/tldraw && yarn test
```

## 主要パターンまとめ

- シェイプIDには `createShapeId()` を使用
- 時間依存の動作には `vi.useFakeTimers()` を使用
- `beforeEach` でシェイプをクリア、`afterEach` で dispose
- シェイプ/ツールのテストは `packages/tldraw` で実行
- ステートマシンのアサーションには `expectToBeIn()` を使用
- 部分一致には `toMatchObject()` を使用
- 浮動小数点値には `toCloselyMatchObject()` を使用
- モックは `vi.spyOn()` で行い、必ず `mockRestore()` する
