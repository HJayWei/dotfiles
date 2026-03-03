---
trigger: always_on
---

# 01 · 通用程式碼風格與格式規範（補充規則）

> 本文件定義跨語言的通用程式碼風格與格式規範完整範例。
>
> 語言特定規則詳見 `lang-typescript.md`、`lang-python.md`、`lang-php.md`、`lang-sql.md`、`lang-golang.md`、`lang-swift.md`、`lang-rust.md`、`lang-vue.md`。
>
> 參考來源：Google Style Guides、Airbnb Style Guide、Microsoft TypeScript Guidelines

---

## 命名慣例

### 通用規則

| 類型 | 慣例 | 範例 |
|------|------|------|
| 類別 / 介面 / 型別 | `PascalCase` | `UserService`, `OrderRepository` |
| 函式 / 方法 | `camelCase` | `getUserById()`, `sendEmail()` |
| 變數 / 參數 | `camelCase` (JS/TS) 或 `snake_case` (Python) | `userName`, `user_name` |
| 常數 | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT`, `API_BASE_URL` |
| 私有成員 | 前綴 `_`（Python）或 `#`（JS Class Fields）| `_internalState`, `#privateField` |
| 布林變數 | `is` / `has` / `can` 前綴 | `isActive`, `hasPermission`, `canEdit` |
| 非同步函式 | 無需加 `Async` 後綴，由回傳型別表達 | `getUser()` 回傳 `Promise<User>` |
| 事件處理器 | `handle` + 事件名稱 | `handleSubmit`, `handleUserCreated` |

### 禁止的命名方式

```
// ❌ 禁止
const d = new Date();
const temp = getValue();
function do_something() {}
class user_service {}
const FLAG = true;        // 布林常數應使用 is/has 前綴

// ✅ 正確
const currentDate = new Date();
const userProfile = getValue();
function doSomething() {}
class UserService {}
const IS_PRODUCTION = true;
```

---

## 程式碼長度限制

| 項目 | 限制 | 超過時的處理方式 |
|------|------|----------------|
| 每行字元數 | ≤ 120 字元 | 換行，使用適當縮排 |
| 單一函式行數 | ≤ 50 行 | 提取子函式 |
| 單一類別行數 | ≤ 300 行 | 拆分職責，提取相關類別 |
| 單一檔案行數 | ≤ 500 行 | 模組化，拆分為多個檔案 |
| 函式參數數量 | ≤ 4 個 | 使用 Options Object 模式 |

```typescript
// ❌ 參數過多
function createUser(name: string, email: string, role: string, age: number, phone: string) {}

// ✅ 使用 Options Object
interface CreateUserOptions {
  name: string;
  email: string;
  role: string;
  age: number;
  phone?: string;
}
function createUser(options: CreateUserOptions): Promise<User> {}
```

---

## 縮排與格式

- **縮排**: 使用 **Space**（非 Tab）
  - TypeScript / JavaScript / JSON / YAML / HTML / CSS: **2 spaces**
  - Python: **4 spaces**
  - PHP: **4 spaces**
  - SQL: **4 spaces**
- **字串引號**: 優先使用單引號（TypeScript/JavaScript），Python 使用雙引號或單引號（一致即可）
- **結尾分號**: TypeScript/JavaScript 必須加分號（由 ESLint/Prettier 強制執行）
- **Trailing Comma**: 多行陣列、物件、函式參數最後一項加尾逗號（有助於 Git diff 可讀性）

---

## 註解規範

### 何時加註解

```typescript
// ✅ 說明「為什麼」，而非「是什麼」
// 使用指數退避避免在高峰期壓垮下游服務
const delay = Math.pow(2, retryCount) * 1000;

// ❌ 無意義的描述性註解（程式碼本身已表達）
// 將 count 加 1
count++;
```

### 必須加註解的情境

1. **複雜演算法**: 說明演算法選擇理由
2. **非直觀的 workaround**: 加上 issue 連結
3. **效能關鍵路徑**: 說明最佳化理由與 benchmark 數據
4. **暫時性程式碼（TODO）**: 格式為 `// TODO(姓名): 說明 [JIRA-123]`
5. **已知的技術債務**: 格式為 `// FIXME: 說明問題`

### 公開 API 文件

所有公開函式 / 類別必須有文件字串（JSDoc / docstring）：

```typescript
/**
 * 依 ID 查詢使用者。
 *
 * @param id - 使用者的唯一識別碼（UUID v4）
 * @returns 使用者實體，若不存在則回傳 null
 * @throws {DatabaseError} 資料庫連線失敗時
 */
async function findUserById(id: string): Promise<User | null> {}
```

---

## 錯誤處理

### 原則

1. **永不吞掉錯誤**：`catch` 區塊必須至少記錄日誌或重新拋出
2. **使用自定義錯誤類別**：區分業務錯誤與系統錯誤
3. **提供有意義的錯誤訊息**：包含上下文資訊

```typescript
// ❌ 吞掉錯誤
try {
  await processOrder(order);
} catch (e) {}

// ❌ 模糊的錯誤訊息
throw new Error('Error');

// ✅ 有意義的錯誤處理
try {
  await processOrder(order);
} catch (error) {
  logger.error('訂單處理失敗', { orderId: order.id, error });
  throw new OrderProcessingError(`訂單 ${order.id} 處理失敗: ${error.message}`, { cause: error });
}
```

### 自定義錯誤類別結構

```typescript
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500,
    options?: ErrorOptions
  ) {
    super(message, options);
    this.name = this.constructor.name;
  }
}

class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} (id: ${id}) 不存在`, 'NOT_FOUND', 404);
  }
}

class ValidationError extends AppError {
  constructor(message: string, public readonly fields?: Record<string, string>) {
    super(message, 'VALIDATION_ERROR', 422);
  }
}
```

---

## 魔法數字與常數

```typescript
// ❌ 禁止魔法數字
if (retryCount > 3) { setTimeout(fn, 5000); }

// ✅ 使用命名常數
const MAX_RETRY_COUNT = 3;
const RETRY_DELAY_MS = 5_000;

if (retryCount > MAX_RETRY_COUNT) {
  setTimeout(fn, RETRY_DELAY_MS);
}
```

---

## 匯入排序

所有檔案的匯入語句依以下順序排列（使用空行分隔各群組）：

```typescript
// 1. Node.js 內建模組
import { readFileSync } from 'fs';
import path from 'path';

// 2. 第三方套件
import express from 'express';
import { z } from 'zod';

// 3. 內部模組（絕對路徑）
import { UserService } from '@/services/UserService';
import { logger } from '@/utils/logger';

// 4. 相對路徑匯入
import { validateUserInput } from './validators';
import type { UserDto } from './types';
```

---

## 程式碼組織

### 檔案結構慣例（以 TypeScript 類別為例）

```typescript
// 1. 匯入
// 2. 型別定義 / 介面
// 3. 常數
// 4. 主要類別 / 函式
// 5. 輔助函式（私有）
// 6. 匯出
```

### 關注點分離

```
❌ 在同一函式中混合：資料驗證 + 業務邏輯 + 資料庫操作 + HTTP 回應
✅ 分離為：
   - 驗證層（Validator）
   - 服務層（Service）
   - 資料層（Repository）
   - 控制器（Controller）
```

---

## 非同步程式碼

```typescript
// ✅ 優先使用 async/await
async function fetchUser(id: string): Promise<User> {
  const user = await userRepository.findById(id);
  if (!user) {
    throw new NotFoundError('User', id);
  }
  return user;
}

// ❌ 避免 callback hell
function fetchUser(id, callback) {
  db.query('SELECT...', id, (err, result) => {
    if (err) callback(err);
    else callback(null, result);
  });
}

// ✅ 並行執行獨立的非同步操作
const [user, orders] = await Promise.all([
  userRepository.findById(userId),
  orderRepository.findByUserId(userId),
]);
```

---

## 不可變性（Immutability）

### 原則

優先建立新物件，避免直接修改既有物件。不可變性降低副作用、提升可預測性與並行安全性。

### 語言對應實踐

| 語言 | 不可變宣告 | 不可變資料結構 |
|------|-----------|---------------|
| TypeScript | `const`, `readonly`, `as const` | `Readonly<T>`, `ReadonlyArray<T>` |
| Python | 慣例（無強制）| `tuple`, `frozenset`, `@dataclass(frozen=True)` |
| Swift | `let`, `struct` | 值型別預設不可變 |
| Rust | 預設不可變 | `let`（需 `mut` 才可變） |
| Go | 無語言層面強制 | 回傳新結構而非修改原結構 |

```typescript
// ❌ 直接修改物件
function updateUser(user: User, name: string): User {
  user.name = name;
  return user;
}

// ✅ 建立新物件（spread operator）
function updateUser(user: User, name: string): User {
  return { ...user, name };
}

// ✅ 陣列操作：使用不修改原陣列的方法
const updated = items.map((item) =>
  item.id === targetId ? { ...item, status: 'done' } : item,
);
```

### 規則

- 變數預設使用 `const`（TS/JS）、`let`（Swift）、`let`（Rust），僅在必要時使用可變宣告
- 函式應回傳新物件而非修改輸入參數
- 使用 `readonly` / `Readonly<T>` 標記不應被修改的屬性
- 陣列操作優先使用 `map` / `filter` / `reduce`，避免 `push` / `splice` 直接修改

---

## 輸入驗證

### 原則

**永遠不信任外部輸入**。所有來自使用者、API、外部服務的資料必須在系統邊界處驗證。

```typescript
// ✅ 使用 schema 驗證（zod 範例）
import { z } from 'zod';

const CreateUserSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
  age: z.number().int().min(0).max(150),
});

type CreateUserInput = z.infer<typeof CreateUserSchema>;

function createUser(raw: unknown): Promise<User> {
  const input = CreateUserSchema.parse(raw); // 驗證失敗會拋出 ZodError
  return userService.create(input);
}
```

### 規則

- 在系統邊界（API handler、CLI 輸入、外部 webhook）驗證所有輸入
- 使用 schema-based 驗證庫（zod、joi、Pydantic、Laravel Form Request）
- 驗證失敗時快速失敗，提供清楚的錯誤訊息
- 禁止信任前端驗證 — 後端必須獨立驗證

---

## Dead Code

- **禁止提交** 已註解掉的程式碼區塊（使用 Git 歷史紀錄追溯）
- **禁止** 未使用的變數、匯入、函式（由 Linting 工具強制）
- **允許** `// TODO:` 標記，但必須有對應 issue 追蹤
