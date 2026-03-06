# コンポーネントパターン リファレンス

## Compound Components 詳解

Compound Componentsは、暗黙的な状態を共有しつつ柔軟なコンポジションを可能にするパターン。

### Contextを使った実装

```tsx
import {
  createContext,
  useContext,
  useState,
  useCallback,
  type ReactNode,
  type Dispatch,
  type SetStateAction,
} from "react";

// 型定義
interface TabsContextValue {
  activeTab: string;
  setActiveTab: Dispatch<SetStateAction<string>>;
}

interface TabsProps {
  defaultValue: string;
  children: ReactNode;
  onChange?: (value: string) => void;
}

interface TabListProps {
  children: ReactNode;
  className?: string;
}

interface TabProps {
  value: string;
  children: ReactNode;
  disabled?: boolean;
}

interface TabPanelProps {
  value: string;
  children: ReactNode;
}

// Context
const TabsContext = createContext<TabsContextValue | null>(null);

function useTabs() {
  const context = useContext(TabsContext);
  if (!context) {
    throw new Error("Tabs components must be used within <Tabs>");
  }
  return context;
}

// ルートコンポーネント
export function Tabs({ defaultValue, children, onChange }: TabsProps) {
  const [activeTab, setActiveTab] = useState(defaultValue);

  const handleChange: Dispatch<SetStateAction<string>> = useCallback(
    (value) => {
      const newValue = typeof value === "function" ? value(activeTab) : value;
      setActiveTab(newValue);
      onChange?.(newValue);
    },
    [activeTab, onChange],
  );

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab: handleChange }}>
      <div className="tabs">{children}</div>
    </TabsContext.Provider>
  );
}

// タブリスト（タブトリガーのコンテナ）
Tabs.List = function TabList({ children, className }: TabListProps) {
  return (
    <div role="tablist" className={`flex border-b ${className}`}>
      {children}
    </div>
  );
};

// 個別タブ（トリガー）
Tabs.Tab = function Tab({ value, children, disabled }: TabProps) {
  const { activeTab, setActiveTab } = useTabs();
  const isActive = activeTab === value;

  return (
    <button
      role="tab"
      aria-selected={isActive}
      aria-controls={`panel-${value}`}
      tabIndex={isActive ? 0 : -1}
      disabled={disabled}
      onClick={() => setActiveTab(value)}
      className={`
        px-4 py-2 font-medium transition-colors
        ${
          isActive
            ? "border-b-2 border-blue-600 text-blue-600"
            : "text-gray-600 hover:text-gray-900"
        }
        ${disabled ? "opacity-50 cursor-not-allowed" : ""}
      `}
    >
      {children}
    </button>
  );
};

// タブパネル（コンテンツ）
Tabs.Panel = function TabPanel({ value, children }: TabPanelProps) {
  const { activeTab } = useTabs();

  if (activeTab !== value) return null;

  return (
    <div
      role="tabpanel"
      id={`panel-${value}`}
      aria-labelledby={`tab-${value}`}
      tabIndex={0}
      className="py-4"
    >
      {children}
    </div>
  );
};
```

### 使用例

```tsx
<Tabs defaultValue="overview" onChange={console.log}>
  <Tabs.List>
    <Tabs.Tab value="overview">Overview</Tabs.Tab>
    <Tabs.Tab value="features">Features</Tabs.Tab>
    <Tabs.Tab value="pricing" disabled>
      Pricing
    </Tabs.Tab>
  </Tabs.List>
  <Tabs.Panel value="overview">
    <h2>Product Overview</h2>
    <p>Description here...</p>
  </Tabs.Panel>
  <Tabs.Panel value="features">
    <h2>Key Features</h2>
    <ul>...</ul>
  </Tabs.Panel>
</Tabs>
```

## Render Props パターン

状態とヘルパーを提供しつつ、レンダリングの制御を利用側に委譲するパターン。

```tsx
interface DataLoaderRenderProps<T> {
  data: T | null;
  loading: boolean;
  error: Error | null;
  refetch: () => void;
}

interface DataLoaderProps<T> {
  url: string;
  children: (props: DataLoaderRenderProps<T>) => ReactNode;
}

function DataLoader<T>({ url, children }: DataLoaderProps<T>) {
  const [state, setState] = useState<{
    data: T | null;
    loading: boolean;
    error: Error | null;
  }>({
    data: null,
    loading: true,
    error: null,
  });

  const fetchData = useCallback(async () => {
    setState((prev) => ({ ...prev, loading: true, error: null }));
    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error("Fetch failed");
      const data = await response.json();
      setState({ data, loading: false, error: null });
    } catch (error) {
      setState((prev) => ({ ...prev, loading: false, error: error as Error }));
    }
  }, [url]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return <>{children({ ...state, refetch: fetchData })}</>;
}

// 使用例
<DataLoader<User[]> url="/api/users">
  {({ data, loading, error, refetch }) => {
    if (loading) return <Spinner />;
    if (error) return <ErrorMessage error={error} onRetry={refetch} />;
    return <UserList users={data!} />;
  }}
</DataLoader>;
```

## ポリモーフィックコンポーネント

Components that can render as different HTML elements.

```tsx
type AsProp<C extends React.ElementType> = {
  as?: C;
};

type PropsToOmit<C extends React.ElementType, P> = keyof (AsProp<C> & P);

type PolymorphicComponentProp<
  C extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<C>> &
  Omit<React.ComponentPropsWithoutRef<C>, PropsToOmit<C, Props>>;

interface TextOwnProps {
  variant?: 'body' | 'heading' | 'label';
  size?: 'sm' | 'md' | 'lg';
}

type TextProps<C extends React.ElementType> = PolymorphicComponentProp<C, TextOwnProps>;

function Text<C extends React.ElementType = 'span'>({
  as,
  variant = 'body',
  size = 'md',
  className,
  children,
  ...props
}: TextProps<C>) {
  const Component = as || 'span';

  const variantClasses = {
    body: 'font-normal',
    heading: 'font-bold',
    label: 'font-medium uppercase tracking-wide',
  };

  const sizeClasses = {
    sm: 'text-sm',
    md: 'text-base',
    lg: 'text-lg',
  };

  return (
    <Component
      className={`${variantClasses[variant]} ${sizeClasses[size]} ${className}`}
      {...props}
    >
      {children}
    </Component>
  );
}

// 使用例
<Text>Default span</Text>
<Text as="p" variant="body" size="lg">Paragraph</Text>
<Text as="h1" variant="heading" size="lg">Heading</Text>
<Text as="label" variant="label" htmlFor="input">Label</Text>
```

## 制御/非制御パターン

Support both modes for maximum flexibility.

```tsx
interface InputProps {
  // 制御モード
  value?: string;
  onChange?: (value: string) => void;
  // 非制御モード
  defaultValue?: string;
  // 共通
  placeholder?: string;
  disabled?: boolean;
}

function Input({
  value: controlledValue,
  onChange,
  defaultValue = '',
  ...props
}: InputProps) {
  const [internalValue, setInternalValue] = useState(defaultValue);

  // 制御モードかどうかを判定
  const isControlled = controlledValue !== undefined;
  const value = isControlled ? controlledValue : internalValue;

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value;

    if (!isControlled) {
      setInternalValue(newValue);
    }

    onChange?.(newValue);
  };

  return (
    <input
      type="text"
      value={value}
      onChange={handleChange}
      {...props}
    />
  );
}

// 制御モードでの使用
const [search, setSearch] = useState('');
<Input value={search} onChange={setSearch} />

// 非制御モードでの使用
<Input defaultValue="initial" onChange={console.log} />
```

## スロットパターン

利用側がコンポーネントの内部パーツを差し替え可能にするパターン。

```tsx
interface CardProps {
  children: ReactNode;
  header?: ReactNode;
  footer?: ReactNode;
  media?: ReactNode;
}

function Card({ children, header, footer, media }: CardProps) {
  return (
    <article className="rounded-lg border bg-white shadow-sm">
      {media && (
        <div className="aspect-video overflow-hidden rounded-t-lg">{media}</div>
      )}
      {header && <header className="border-b px-4 py-3">{header}</header>}
      <div className="px-4 py-4">{children}</div>
      {footer && (
        <footer className="border-t px-4 py-3 bg-gray-50 rounded-b-lg">
          {footer}
        </footer>
      )}
    </article>
  );
}

// スロットを使用した例
<Card
  media={<img src="/image.jpg" alt="" />}
  header={<h2 className="font-semibold">Card Title</h2>}
  footer={<Button>Action</Button>}
>
  <p>カードのコンテンツがここに入ります。</p>
</Card>;
```

## Forward Ref パターン

親コンポーネントから基盤となるDOMノードへのアクセスを可能にするパターン。

```tsx
import { forwardRef, useRef, useImperativeHandle } from "react";

interface InputHandle {
  focus: () => void;
  clear: () => void;
  getValue: () => string;
}

interface FancyInputProps {
  label: string;
  placeholder?: string;
}

const FancyInput = forwardRef<InputHandle, FancyInputProps>(
  ({ label, placeholder }, ref) => {
    const inputRef = useRef<HTMLInputElement>(null);

    useImperativeHandle(ref, () => ({
      focus: () => inputRef.current?.focus(),
      clear: () => {
        if (inputRef.current) inputRef.current.value = "";
      },
      getValue: () => inputRef.current?.value ?? "",
    }));

    return (
      <div>
        <label className="block text-sm font-medium mb-1">{label}</label>
        <input
          ref={inputRef}
          type="text"
          placeholder={placeholder}
          className="w-full px-3 py-2 border rounded-md"
        />
      </div>
    );
  },
);

FancyInput.displayName = "FancyInput";

// 使用例
function Form() {
  const inputRef = useRef<InputHandle>(null);

  const handleSubmit = () => {
    console.log(inputRef.current?.getValue());
    inputRef.current?.clear();
  };

  return (
    <form onSubmit={handleSubmit}>
      <FancyInput ref={inputRef} label="Name" />
      <button type="button" onClick={() => inputRef.current?.focus()}>
        Focus Input
      </button>
    </form>
  );
}
```
