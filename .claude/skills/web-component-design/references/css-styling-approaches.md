# CSSスタイリングアプローチ リファレンス

## 比較マトリクス

| アプローチ        | ランタイム | バンドルサイズ | 学習コスト | 動的スタイル | SSR   |
| ----------------- | ---------- | -------------- | ---------- | ------------ | ----- |
| CSS Modules       | なし       | 最小           | 低         | 限定的       | 対応  |
| Tailwind          | なし       | 小（purge後）  | 中         | クラス経由   | 対応  |
| styled-components | あり       | 中             | 中         | 完全対応     | 対応* |
| Emotion           | あり       | 中             | 中         | 完全対応     | 対応  |
| Vanilla Extract   | なし       | 最小           | 高         | 限定的       | 対応  |

## CSS Modules

ランタイムオーバーヘッドゼロのスコープ付きCSS。

### セットアップ

```tsx
// Button.module.css
.button {
  padding: 0.5rem 1rem;
  border-radius: 0.375rem;
  font-weight: 500;
  transition: background-color 0.2s;
}

.primary {
  background-color: #2563eb;
  color: white;
}

.primary:hover {
  background-color: #1d4ed8;
}

.secondary {
  background-color: #f3f4f6;
  color: #1f2937;
}

.secondary:hover {
  background-color: #e5e7eb;
}

.small {
  padding: 0.25rem 0.5rem;
  font-size: 0.875rem;
}

.large {
  padding: 0.75rem 1.5rem;
  font-size: 1.125rem;
}
```

```tsx
// Button.tsx
import styles from "./Button.module.css";
import { clsx } from "clsx";

interface ButtonProps {
  variant?: "primary" | "secondary";
  size?: "small" | "medium" | "large";
  children: React.ReactNode;
  onClick?: () => void;
}

export function Button({
  variant = "primary",
  size = "medium",
  children,
  onClick,
}: ButtonProps) {
  return (
    <button
      className={clsx(
        styles.button,
        styles[variant],
        size !== "medium" && styles[size],
      )}
      onClick={onClick}
    >
      {children}
    </button>
  );
}
```

### コンポジション

```css
/* base.module.css */
.visuallyHidden {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  border: 0;
}

/* Button.module.css */
.srOnly {
  composes: visuallyHidden from "./base.module.css";
}
```

## Tailwind CSS

デザインシステムの制約を持つユーティリティファーストCSS。

### Class Variance Authority（CVA）

```tsx
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  // ベーススタイル
  "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive:
          "bg-destructive text-destructive-foreground hover:bg-destructive/90",
        outline:
          "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
        secondary:
          "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-9 rounded-md px-3",
        lg: "h-11 rounded-md px-8",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  },
);

interface ButtonProps
  extends
    React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, ...props }, ref) => {
    return (
      <button
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    );
  },
);
```

### Tailwind Merge ユーティリティ

```tsx
// lib/utils.ts
import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// 使用例 - 競合するクラスを処理
cn("px-4 py-2", "px-6"); // => 'py-2 px-6'
cn("text-red-500", condition && "text-blue-500"); // => 条件がtrueなら 'text-blue-500'
```

### カスタムプラグイン

```js
// tailwind.config.js
const plugin = require("tailwindcss/plugin");

module.exports = {
  plugins: [
    plugin(function ({ addUtilities, addComponents, theme }) {
      // ユーティリティの追加
      addUtilities({
        ".text-balance": {
          "text-wrap": "balance",
        },
        ".scrollbar-hide": {
          "-ms-overflow-style": "none",
          "scrollbar-width": "none",
          "&::-webkit-scrollbar": {
            display: "none",
          },
        },
      });

      // コンポーネントの追加
      addComponents({
        ".card": {
          backgroundColor: theme("colors.white"),
          borderRadius: theme("borderRadius.lg"),
          padding: theme("spacing.6"),
          boxShadow: theme("boxShadow.md"),
        },
      });
    }),
  ],
};
```

## styled-components

テンプレートリテラルを使用したCSS-in-JS。

```tsx
import styled, { css, keyframes } from "styled-components";

// キーフレーム
const fadeIn = keyframes`
  from { opacity: 0; transform: translateY(-10px); }
  to { opacity: 1; transform: translateY(0); }
`;

// バリアント付きのベースボタン
interface ButtonProps {
  $variant?: "primary" | "secondary" | "ghost";
  $size?: "sm" | "md" | "lg";
  $isLoading?: boolean;
}

const sizeStyles = {
  sm: css`
    padding: 0.25rem 0.75rem;
    font-size: 0.875rem;
  `,
  md: css`
    padding: 0.5rem 1rem;
    font-size: 1rem;
  `,
  lg: css`
    padding: 0.75rem 1.5rem;
    font-size: 1.125rem;
  `,
};

const variantStyles = {
  primary: css`
    background-color: ${({ theme }) => theme.colors.primary};
    color: white;
    &:hover:not(:disabled) {
      background-color: ${({ theme }) => theme.colors.primaryHover};
    }
  `,
  secondary: css`
    background-color: ${({ theme }) => theme.colors.secondary};
    color: ${({ theme }) => theme.colors.text};
    &:hover:not(:disabled) {
      background-color: ${({ theme }) => theme.colors.secondaryHover};
    }
  `,
  ghost: css`
    background-color: transparent;
    color: ${({ theme }) => theme.colors.text};
    &:hover:not(:disabled) {
      background-color: ${({ theme }) => theme.colors.ghost};
    }
  `,
};

const Button = styled.button<ButtonProps>`
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  border-radius: 0.375rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  animation: ${fadeIn} 0.3s ease;

  ${({ $size = "md" }) => sizeStyles[$size]}
  ${({ $variant = "primary" }) => variantStyles[$variant]}

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  ${({ $isLoading }) =>
    $isLoading &&
    css`
      pointer-events: none;
      opacity: 0.7;
    `}
`;

// コンポーネントの拡張
const IconButton = styled(Button)`
  padding: 0.5rem;
  aspect-ratio: 1;
`;

// テーマプロバイダー
const theme = {
  colors: {
    primary: "#2563eb",
    primaryHover: "#1d4ed8",
    secondary: "#f3f4f6",
    secondaryHover: "#e5e7eb",
    ghost: "rgba(0, 0, 0, 0.05)",
    text: "#1f2937",
  },
};

// 使用例
<ThemeProvider theme={theme}>
  <Button $variant="primary" $size="lg">
    Click me
  </Button>
</ThemeProvider>;
```

## Emotion

オブジェクト構文とテンプレート構文に対応した柔軟なCSS-in-JS。

```tsx
/** @jsxImportSource @emotion/react */
import { css, Theme, ThemeProvider, useTheme } from "@emotion/react";
import styled from "@emotion/styled";

// テーマの型定義
declare module "@emotion/react" {
  export interface Theme {
    colors: {
      primary: string;
      background: string;
      text: string;
    };
    spacing: (factor: number) => string;
  }
}

const theme: Theme = {
  colors: {
    primary: "#2563eb",
    background: "#ffffff",
    text: "#1f2937",
  },
  spacing: (factor: number) => `${factor * 0.25}rem`,
};

// オブジェクト構文
const cardStyles = (theme: Theme) =>
  css({
    backgroundColor: theme.colors.background,
    padding: theme.spacing(4),
    borderRadius: "0.5rem",
    boxShadow: "0 1px 3px rgba(0, 0, 0, 0.1)",
  });

// テンプレートリテラル構文
const buttonStyles = css`
  padding: 0.5rem 1rem;
  border-radius: 0.375rem;
  font-weight: 500;

  &:hover {
    opacity: 0.9;
  }
`;

// テーマ付きのStyled Component
const Card = styled.div`
  background-color: ${({ theme }) => theme.colors.background};
  padding: ${({ theme }) => theme.spacing(4)};
  border-radius: 0.5rem;
`;

// css propを使用したコンポーネント
function Alert({ children }: { children: React.ReactNode }) {
  const theme = useTheme();

  return (
    <div
      css={css`
        padding: ${theme.spacing(3)};
        background-color: ${theme.colors.primary}10;
        border-left: 4px solid ${theme.colors.primary};
      `}
    >
      {children}
    </div>
  );
}

// 使用例
<ThemeProvider theme={theme}>
  <Card>
    <Alert>Important message</Alert>
  </Card>
</ThemeProvider>;
```

## Vanilla Extract

完全な型安全性を持つゼロランタイムCSS-in-JS。

```tsx
// styles.css.ts
import { style, styleVariants, createTheme } from "@vanilla-extract/css";
import { recipe, type RecipeVariants } from "@vanilla-extract/recipes";

// テーマ定義
export const [themeClass, vars] = createTheme({
  color: {
    primary: "#2563eb",
    secondary: "#64748b",
    background: "#ffffff",
    text: "#1f2937",
  },
  space: {
    small: "0.5rem",
    medium: "1rem",
    large: "1.5rem",
  },
  radius: {
    small: "0.25rem",
    medium: "0.375rem",
    large: "0.5rem",
  },
});

// シンプルなスタイル
export const container = style({
  padding: vars.space.medium,
  backgroundColor: vars.color.background,
});

// スタイルバリアント
export const text = styleVariants({
  primary: { color: vars.color.text },
  secondary: { color: vars.color.secondary },
  accent: { color: vars.color.primary },
});

// Recipe（CVAに相当）
export const button = recipe({
  base: {
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    fontWeight: 500,
    borderRadius: vars.radius.medium,
    transition: "background-color 0.2s",
    cursor: "pointer",
    border: "none",
    ":disabled": {
      opacity: 0.5,
      cursor: "not-allowed",
    },
  },
  variants: {
    variant: {
      primary: {
        backgroundColor: vars.color.primary,
        color: "white",
        ":hover": {
          backgroundColor: "#1d4ed8",
        },
      },
      secondary: {
        backgroundColor: "#f3f4f6",
        color: vars.color.text,
        ":hover": {
          backgroundColor: "#e5e7eb",
        },
      },
    },
    size: {
      small: {
        padding: "0.25rem 0.75rem",
        fontSize: "0.875rem",
      },
      medium: {
        padding: "0.5rem 1rem",
        fontSize: "1rem",
      },
      large: {
        padding: "0.75rem 1.5rem",
        fontSize: "1.125rem",
      },
    },
  },
  defaultVariants: {
    variant: "primary",
    size: "medium",
  },
});

export type ButtonVariants = RecipeVariants<typeof button>;
```

```tsx
// Button.tsx
import { button, type ButtonVariants, themeClass } from "./styles.css";

interface ButtonProps extends ButtonVariants {
  children: React.ReactNode;
  onClick?: () => void;
}

export function Button({ variant, size, children, onClick }: ButtonProps) {
  return (
    <button className={button({ variant, size })} onClick={onClick}>
      {children}
    </button>
  );
}

// App.tsx - テーマでラップ
function App() {
  return (
    <div className={themeClass}>
      <Button variant="primary" size="large">
        Click me
      </Button>
    </div>
  );
}
```

## パフォーマンスに関する考慮事項

### クリティカルCSSの抽出

```tsx
// Next.js + styled-components
// pages/_document.tsx
import Document, { DocumentContext } from "next/document";
import { ServerStyleSheet } from "styled-components";

export default class MyDocument extends Document {
  static async getInitialProps(ctx: DocumentContext) {
    const sheet = new ServerStyleSheet();
    const originalRenderPage = ctx.renderPage;

    try {
      ctx.renderPage = () =>
        originalRenderPage({
          enhanceApp: (App) => (props) =>
            sheet.collectStyles(<App {...props} />),
        });

      const initialProps = await Document.getInitialProps(ctx);
      return {
        ...initialProps,
        styles: [initialProps.styles, sheet.getStyleElement()],
      };
    } finally {
      sheet.seal();
    }
  }
}
```

### スタイルのコード分割

```tsx
// 重いStyled Componentを動的インポートする
import dynamic from "next/dynamic";

const HeavyChart = dynamic(() => import("./HeavyChart"), {
  loading: () => <Skeleton height={400} />,
  ssr: false,
});
```
