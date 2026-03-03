---
trigger: glob
globs: **/*.ts, **/*.tsx, **/*.js, **/*.jsx
---

# TypeScript / JavaScript 開發準則

> 適用於 Node.js 後端、React 前端、Next.js、NestJS 等 TypeScript/JavaScript 專案。
>
> 參考來源：TypeScript Handbook、Google TypeScript Style Guide、Airbnb JavaScript Style Guide

---

## TypeScript 設定

### 必用的 tsconfig.json 選項

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "exactOptionalPropertyTypes": true,
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

### 禁止的 TypeScript 實踐

```typescript
// 禁止使用 any
const data: any = fetchData();

// 禁止未驗證的型別斷言
const user = unknownData as User;

// 禁止 @ts-ignore（改用 @ts-expect-error 並說明）
// @ts-ignore

// 正確：使用型別守衛
function isUser(data: unknown): data is User {
  return typeof data === 'object' && data !== null && 'id' in data;
}
```

---

## 型別系統

### 介面 vs 型別別名

```typescript
// 使用 interface 定義物件形狀（可擴展）
interface User {
  id: string;
  name: string;
  email: string;
}

// 使用 type 定義聯合型別、交叉型別或複雜型別
type UserId = string;
type UserOrAdmin = User | Admin;
type ApiResponse<T> = { data: T; status: number; message: string };
```

### 泛型的使用

```typescript
// 有意義的泛型名稱（非單字母）
interface Repository<TEntity, TId = string> {
  findById(id: TId): Promise<TEntity | null>;
  save(entity: TEntity): Promise<TEntity>;
  delete(id: TId): Promise<void>;
}

// 泛型約束
function getProperty<TObject, TKey extends keyof TObject>(
  obj: TObject,
  key: TKey
): TObject[TKey] {
  return obj[key];
}
```

### Utility Types 的使用

```typescript
// 善用內建 Utility Types
interface User {
  id: string;
  name: string;
  email: string;
  password: string;
  createdAt: Date;
}

type CreateUserDto = Omit<User, 'id' | 'createdAt'>;
type UpdateUserDto = Partial<Pick<User, 'name' | 'email'>>;
type PublicUser = Omit<User, 'password'>;
type UserId = User['id'];
```

---

## 命名慣例

```typescript
// 類別、介面、型別 → PascalCase
class UserService {}
interface OrderRepository {}
type ApiResponse<T> = { data: T };

// 函式、方法、變數 → camelCase
const getUserById = async (id: string) => {};
let currentUser: User | null = null;

// 常數 → UPPER_SNAKE_CASE
const MAX_RETRY_COUNT = 3;
const API_BASE_URL = process.env.API_URL;

// 列舉 → PascalCase 名稱，UPPER_SNAKE_CASE 成員
enum OrderStatus {
  PENDING = 'pending',
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
}

// 布林變數 → is/has/can 前綴
const isAuthenticated = false;
const hasPermission = true;
const canEdit = user.role === 'admin';
```

---

## 函式與方法

### 偏好函式式風格

```typescript
// 偏好純函式（無副作用）
function calculateDiscount(price: number, discountRate: number): number {
  return price * (1 - discountRate);
}

// 使用 const arrow function 宣告工具函式
const formatCurrency = (amount: number, currency = 'TWD'): string =>
  new Intl.NumberFormat('zh-TW', { style: 'currency', currency }).format(amount);
```

### 非同步函式

```typescript
// 優先使用 async/await
async function fetchUser(id: string): Promise<User> {
  const user = await userRepository.findById(id);
  if (!user) {
    throw new NotFoundError('User', id);
  }
  return user;
}

// 並行執行獨立的非同步操作
const [user, orders, profile] = await Promise.all([
  userRepository.findById(userId),
  orderRepository.findByUserId(userId),
  profileRepository.findByUserId(userId),
]);

// 錯誤處理
async function safeOperation<T>(
  fn: () => Promise<T>
): Promise<[T, null] | [null, Error]> {
  try {
    const result = await fn();
    return [result, null];
  } catch (error) {
    return [null, error instanceof Error ? error : new Error(String(error))];
  }
}
```

---

## 模組系統

### 匯入順序（ESLint 強制執行）

```typescript
// 1. Node.js 內建
import { readFileSync } from 'fs';
import path from 'path';

// 2. 第三方套件
import express from 'express';
import { z } from 'zod';

// 3. 內部模組（路徑別名）
import { UserService } from '@/services/UserService';
import { logger } from '@/utils/logger';

// 4. 相對路徑
import { validateInput } from './validators';
import type { UserDto } from './types';
```

### 匯出慣例

```typescript
// 偏好具名匯出（Named Exports），方便樹搖（Tree-shaking）
export class UserService {}
export interface UserRepository {}
export const createUser = async () => {};

// 僅在模組有明確主要功能時使用預設匯出
export default class App {}
```

---

## React / Vue 前端特定準則

### React 元件

```typescript
// 函式元件搭配型別定義
interface ButtonProps {
  label: string;
  onClick: () => void;
  variant?: 'primary' | 'secondary' | 'danger';
  disabled?: boolean;
}

const Button: React.FC<ButtonProps> = ({
  label,
  onClick,
  variant = 'primary',
  disabled = false,
}) => {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`btn btn-${variant}`}
    >
      {label}
    </button>
  );
};

export default Button;
```

### 狀態管理原則

```typescript
// 保持狀態最小化（最少必要的狀態）
// 衍生值不應放入 state
const [items, setItems] = useState<Item[]>([]);
const totalCount = items.length;           // 衍生值，不需要 state
const completedItems = items.filter(i => i.done);  // 衍生值
```

---

## 測試（TypeScript）

### Jest 設定

```typescript
// jest.config.ts
export default {
  preset: 'ts-jest',
  testEnvironment: 'node',
  collectCoverageFrom: ['src/**/*.ts', '!src/**/*.d.ts'],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
};
```

### 測試範例

```typescript
// user.service.test.ts
import { UserService } from './UserService';
import type { UserRepository } from './UserRepository';

describe('UserService', () => {
  let sut: UserService;
  let mockRepository: jest.Mocked<UserRepository>;

  beforeEach(() => {
    mockRepository = {
      findById: jest.fn(),
      save: jest.fn(),
      delete: jest.fn(),
    };
    sut = new UserService(mockRepository);
  });

  describe('findById', () => {
    it('使用者存在時應回傳使用者', async () => {
      const expected = { id: '1', name: '測試', email: 'test@example.com' };
      mockRepository.findById.mockResolvedValue(expected);

      const result = await sut.findById('1');

      expect(result).toEqual(expected);
      expect(mockRepository.findById).toHaveBeenCalledWith('1');
    });

    it('使用者不存在時應拋出 NotFoundError', async () => {
      mockRepository.findById.mockResolvedValue(null);

      await expect(sut.findById('999')).rejects.toThrow('NotFoundError');
    });
  });
});
```

---

## 套件管理

- **套件管理工具**: 使用 `pnpm`（速度最快、磁碟空間最省），其次為 `npm`
- **版本鎖定**: 提交 `package-lock.json` 或 `pnpm-lock.yaml`
- **版本策略**: 使用精確版本（`"express": "4.19.2"`）而非範圍版本，避免意外升級
- **依賴分類**: 正確區分 `dependencies` 和 `devDependencies`

```json
{
  "engines": {
    "node": ">=22.0.0",
    "pnpm": ">=9.0.0"
  }
}
```

---

## ESLint 設定重點

```json
{
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/explicit-function-return-type": "warn",
    "@typescript-eslint/no-unused-vars": "error",
    "no-console": "warn",
    "no-var": "error",
    "prefer-const": "error",
    "eqeqeq": ["error", "always"],
    "no-implicit-coercion": "error"
  }
}
```
