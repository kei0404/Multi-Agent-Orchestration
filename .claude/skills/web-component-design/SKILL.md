---
name: web-component-design
description: React・Vue・Svelteのコンポーネントパターン（CSS-in-JS、コンポジション戦略、再利用可能なコンポーネント設計を含む）を習得する。UIコンポーネントライブラリの構築、コンポーネントAPIの設計、フロントエンドデザインシステムの実装時に使用する。
---

# Webコンポーネント設計

モダンフレームワークを使い、クリーンなコンポジションパターンとスタイリングアプローチで再利用可能かつ保守性の高いUIコンポーネントを構築する。

## このスキルを使用するタイミング

- 再利用可能なコンポーネントライブラリやデザインシステムの設計
- 複雑なコンポーネントコンポジションパターンの実装
- CSS-in-JS ソリューションの選定と適用
- アクセシブルでレスポンシブなUIコンポーネントの構築
- コードベース全体で一貫したコンポーネントAPIの作成
- レガシーコンポーネントのモダンパターンへのリファクタリング
- Compound ComponentsやRender Propsの実装

## 主要コンセプト

### 1. コンポーネントコンポジションパターン

**Compound Components**: 関連するコンポーネントが連携して動作するパターン

```tsx
// 使用例
<Select value={value} onChange={setValue}>
  <Select.Trigger>Choose option</Select.Trigger>
  <Select.Options>
    <Select.Option value="a">Option A</Select.Option>
    <Select.Option value="b">Option B</Select.Option>
  </Select.Options>
</Select>
```

**Render Props**: レンダリングを親に委譲するパターン

```tsx
<DataFetcher url="/api/users">
  {({ data, loading, error }) =>
    loading ? <Spinner /> : <UserList users={data} />
  }
</DataFetcher>
```

**Slots（Vue/Svelte）**: 名前付きコンテンツの注入ポイント

```vue
<template>
  <Card>
    <template #header>Title</template>
    <template #content>Body text</template>
    <template #footer><Button>Action</Button></template>
  </Card>
</template>
```

### 2. CSS-in-JS アプローチ

| ソリューション        | アプローチ           | 最適な用途                        |
| --------------------- | -------------------- | --------------------------------- |
| **Tailwind CSS**      | ユーティリティクラス | 高速プロトタイピング、デザインシステム |
| **CSS Modules**       | スコープ付きCSSファイル | 既存CSS、段階的導入              |
| **styled-components** | テンプレートリテラル | React、動的スタイリング          |
| **Emotion**           | オブジェクト/テンプレートスタイル | 柔軟、SSR対応            |
| **Vanilla Extract**   | ゼロランタイム       | パフォーマンス重視のアプリ       |

### 3. コンポーネントAPI設計

```tsx
interface ButtonProps {
  variant?: "primary" | "secondary" | "ghost";
  size?: "sm" | "md" | "lg";
  isLoading?: boolean;
  isDisabled?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  children: React.ReactNode;
  onClick?: () => void;
}
```

**設計原則**:

- セマンティックなprop名を使う（`isLoading` vs `loading`）
- 適切なデフォルト値を提供する
- `children` によるコンポジションをサポートする
- `className` や `style` でのスタイルオーバーライドを許可する

## クイックスタート: React + Tailwind コンポーネント

```tsx
import { forwardRef, type ComponentPropsWithoutRef } from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        primary: "bg-blue-600 text-white hover:bg-blue-700",
        secondary: "bg-gray-100 text-gray-900 hover:bg-gray-200",
        ghost: "hover:bg-gray-100 hover:text-gray-900",
      },
      size: {
        sm: "h-8 px-3 text-sm",
        md: "h-10 px-4 text-sm",
        lg: "h-12 px-6 text-base",
      },
    },
    defaultVariants: {
      variant: "primary",
      size: "md",
    },
  },
);

interface ButtonProps
  extends
    ComponentPropsWithoutRef<"button">,
    VariantProps<typeof buttonVariants> {
  isLoading?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, isLoading, children, ...props }, ref) => (
    <button
      ref={ref}
      className={cn(buttonVariants({ variant, size }), className)}
      disabled={isLoading || props.disabled}
      {...props}
    >
      {isLoading && <Spinner className="mr-2 h-4 w-4" />}
      {children}
    </button>
  ),
);
Button.displayName = "Button";
```

## フレームワーク別パターン

### React: Compound Components

```tsx
import { createContext, useContext, useState, type ReactNode } from "react";

interface AccordionContextValue {
  openItems: Set<string>;
  toggle: (id: string) => void;
}

const AccordionContext = createContext<AccordionContextValue | null>(null);

function useAccordion() {
  const context = useContext(AccordionContext);
  if (!context) throw new Error("Must be used within Accordion");
  return context;
}

export function Accordion({ children }: { children: ReactNode }) {
  const [openItems, setOpenItems] = useState<Set<string>>(new Set());

  const toggle = (id: string) => {
    setOpenItems((prev) => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  };

  return (
    <AccordionContext.Provider value={{ openItems, toggle }}>
      <div className="divide-y">{children}</div>
    </AccordionContext.Provider>
  );
}

Accordion.Item = function AccordionItem({
  id,
  title,
  children,
}: {
  id: string;
  title: string;
  children: ReactNode;
}) {
  const { openItems, toggle } = useAccordion();
  const isOpen = openItems.has(id);

  return (
    <div>
      <button onClick={() => toggle(id)} className="w-full text-left py-3">
        {title}
      </button>
      {isOpen && <div className="pb-3">{children}</div>}
    </div>
  );
};
```

### Vue 3: Composables

```vue
<script setup lang="ts">
import { ref, computed, provide, inject, type InjectionKey } from "vue";

interface TabsContext {
  activeTab: Ref<string>;
  setActive: (id: string) => void;
}

const TabsKey: InjectionKey<TabsContext> = Symbol("tabs");

// 親コンポーネント
const activeTab = ref("tab-1");
provide(TabsKey, {
  activeTab,
  setActive: (id: string) => {
    activeTab.value = id;
  },
});

// 子コンポーネントでの使用
const tabs = inject(TabsKey);
const isActive = computed(() => tabs?.activeTab.value === props.id);
</script>
```

### Svelte 5: Runes

```svelte
<script lang="ts">
  interface Props {
    variant?: 'primary' | 'secondary';
    size?: 'sm' | 'md' | 'lg';
    onclick?: () => void;
    children: import('svelte').Snippet;
  }

  let { variant = 'primary', size = 'md', onclick, children }: Props = $props();

  const classes = $derived(
    `btn btn-${variant} btn-${size}`
  );
</script>

<button class={classes} {onclick}>
  {@render children()}
</button>
```

## ベストプラクティス

1. **単一責任**: 各コンポーネントは1つのことをうまくこなす
2. **Propドリリングの回避**: 深くネストされたデータにはContextを使用する
3. **デフォルトでアクセシブル**: ARIA属性とキーボードサポートを含める
4. **制御/非制御の両対応**: 適切な場合は両パターンをサポートする
5. **Ref転送**: 親からDOMノードへのアクセスを可能にする
6. **メモ化**: 重いレンダリングには `React.memo`、`useMemo` を使用する
7. **エラーバウンダリ**: 失敗する可能性のあるコンポーネントをラップする

## よくある問題

- **Propの爆発**: propが多すぎる → コンポジションを検討する
- **スタイルの競合**: スコープ付きスタイルやCSS Modulesを使用する
- **再レンダリングの連鎖**: React DevToolsでプロファイリングし、適切にメモ化する
- **アクセシビリティの不備**: スクリーンリーダーとキーボードナビゲーションでテストする
- **バンドルサイズ**: 未使用のコンポーネントバリアントをTree-shakeする

## リソース

- [React Component Patterns](https://reactpatterns.com/)
- [Vue Composition API Guide](https://vuejs.org/guide/reusability/composables.html)
- [Svelte Component Documentation](https://svelte.dev/docs/svelte-components)
- [Radix UI Primitives](https://www.radix-ui.com/primitives)
- [shadcn/ui Components](https://ui.shadcn.com/)
