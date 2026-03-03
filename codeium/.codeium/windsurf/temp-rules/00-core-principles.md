# 00 · 核心架構原則（補充規則）

> **本文件為 `global_rules.md` 的詳細補充**。核心摘要已提取至全域規則，此處提供完整範例與實踐要求。
>
> **權威性**: 本文件優先於所有其他開發慣例。任何違反須在 `plan.md` Complexity Tracking 中文件化。
>
> 來源：GitHub Spec-Kit（Nine Articles of Development）、Clean Architecture、SOLID

---

## Article I · Library-First Principle（模組優先原則）

每個功能必須先以獨立模組或函式庫的形式存在，再整合到應用程式中。

**實踐要求**:
- 功能從邊界清晰的獨立模組開始設計，禁止直接在應用層實作
- 模組依賴關係必須是單向的、明確的
- 跨模組共用的邏輯必須抽取至共用函式庫，而非在各模組重複

**禁止**:
- 「我先寫在這裡，之後再重構」的思維
- 跨模組的隱式耦合（直接引用其他模組的內部實作）

---

## Article II · CLI Interface Mandate（介面可觀察性）

每個核心功能必須可透過明確介面（CLI、REST API、函式簽章）存取與驗證。

**實踐要求**:
- 所有服務層功能必須有明確的輸入/輸出型別定義
- 結構化資料交換使用 JSON 格式
- 避免封裝在不可觀察的黑盒物件中

---

## Article III · Test-First Imperative（測試先行，不可妥協）

實作程式碼之前，測試必須已存在且確認失敗（Red 狀態）。

**TDD 三步驟（Red → Green → Refactor）**:
1. **Red**: 撰寫一個失敗的測試，描述期望行為
2. **Green**: 寫出最少量程式碼使測試通過
3. **Refactor**: 在保持測試通過的前提下改善程式碼

**非可選的要求**:
- 核心業務邏輯 ≥ 80% 測試覆蓋率
- 服務層與資料層 ≥ 70% 測試覆蓋率
- 所有 API 端點必須有契約測試

---

## Article IV · Clean Architecture（乾淨架構）

依賴方向必須由外向內，內層不得知道外層的存在。

```
表現層 (Presentation)   →  應用層 (Application)
應用層 (Application)    →  領域層 (Domain)
領域層 (Domain)         →  （不依賴任何層）
基礎設施層 (Infrastructure) → 領域層（透過介面）
```

**每層職責**:
| 層級 | 職責 | 禁止事項 |
|------|------|----------|
| 表現層 | HTTP 請求處理、輸入驗證、回應格式化 | 業務邏輯、直接存取資料庫 |
| 應用層 | 用例編排、跨領域協調 | 直接資料庫查詢、HTTP 細節 |
| 領域層 | 業務規則、實體定義、領域事件 | 任何外部框架或基礎設施依賴 |
| 基礎設施層 | 資料庫、外部 API、檔案系統 | 業務邏輯 |

---

## Article V · SOLID Principles（不可妥協）

### S — Single Responsibility Principle（單一職責）
每個類別、函式、模組只負責一個明確的職責。

```typescript
// ❌ 違反 SRP
class UserService {
  createUser(data: UserDto) { /* ... */ }
  sendWelcomeEmail(user: User) { /* ... */ }  // 應在 EmailService
  generateReport() { /* ... */ }              // 應在 ReportService
}

// ✅ 遵循 SRP
class UserService {
  createUser(data: UserDto): Promise<User> { /* ... */ }
}
class EmailService {
  sendWelcomeEmail(user: User): Promise<void> { /* ... */ }
}
```

### O — Open-Closed Principle（開放封閉）
對擴展開放，對修改封閉。透過抽象與介面實現彈性。

```typescript
// ❌ 違反 OCP：新增支付方式需修改現有程式碼
function processPayment(type: string, amount: number) {
  if (type === 'credit') { /* ... */ }
  else if (type === 'paypal') { /* ... */ }  // 需修改此函式
}

// ✅ 遵循 OCP：透過策略模式擴展
interface PaymentStrategy {
  process(amount: number): Promise<void>;
}
class PaymentService {
  constructor(private strategy: PaymentStrategy) {}
  pay(amount: number) { return this.strategy.process(amount); }
}
```

### L — Liskov Substitution Principle（里氏替換）
子類別必須能完全替換父類別，且不破壞程式正確性。

### I — Interface Segregation Principle（介面隔離）
不應強迫客戶端實作未使用的介面；介面應細粒度且針對性。

```typescript
// ❌ 違反 ISP：讀取方只需要 read
interface Repository<T> {
  findById(id: string): Promise<T>;
  save(entity: T): Promise<void>;
  delete(id: string): Promise<void>;
}

// ✅ 遵循 ISP
interface ReadableRepository<T> {
  findById(id: string): Promise<T>;
}
interface WritableRepository<T> {
  save(entity: T): Promise<void>;
  delete(id: string): Promise<void>;
}
```

### D — Dependency Inversion Principle（依賴反轉）
高層模組不依賴低層模組；兩者都依賴抽象。

```typescript
// ❌ 違反 DIP
class OrderService {
  private db = new PostgresDatabase();  // 直接依賴具體實作
}

// ✅ 遵循 DIP
class OrderService {
  constructor(private readonly orderRepo: OrderRepository) {}  // 依賴抽象
}
```

---

## Article VI · MVP-First Principle（最小可行優先）

**YAGNI（You Aren't Gonna Need It）**: 禁止「可能未來需要」的抽象。

**優先級排序**:
```
P1（必要功能）→ 驗證 → P2（重要功能）→ 驗證 → P3（加分功能）
```

**允許技術債務暫時存在，但必須**:
- 在 `tasks.md` 或 Issue 中明確記錄
- 設定償還時間點（Sprint 或里程碑）
- 不影響核心功能穩定性

**效能優化原則**:
```
先測量 → 找出瓶頸 → 針對性優化（有 benchmark 數據支撐）
禁止：「感覺會比較快」的提前優化
```

---

## Article VII · Simplicity Gate（簡潔性閘門）

每個設計決策必須通過以下閘門：

- [ ] 是否可用更少的抽象層達到相同效果？
- [ ] 是否超過 3 個專案 / 模組用於初始實作？（超過須說明理由）
- [ ] 是否有「為了模式而模式」的跡象？
- [ ] 三行程式碼能解決的問題，是否建立了五個介面？

**可接受的設計模式**（僅在解決特定問題時引入）:
- **Creational**: Factory, Builder, Singleton（謹慎使用）
- **Structural**: Adapter, Decorator, Facade, Proxy
- **Behavioral**: Strategy, Observer, Command, Template Method, Repository

---

## Article VIII · Anti-Abstraction（反過度抽象）

**Framework Trust**: 直接使用框架功能，而非無謂包裝。

```typescript
// ❌ 無謂包裝 Express
class HttpWrapper {
  get(path: string, handler: Function) {
    this.app.get(path, handler);  // 沒有增加任何價值
  }
}

// ✅ 直接使用框架
router.get('/users', userController.list);
```

**可接受的抽象條件**:
1. 解決具體的重複問題（DRY 原則）
2. 隱藏真正複雜的邏輯
3. 提供有意義的邊界（跨團隊 / 跨模組介面）

---

## Article IX · Integration-First Testing（整合優先測試）

測試必須盡可能接近真實環境。

**偏好**:
- 真實資料庫（in-memory 或 test container）> Mock 資料庫
- 真實 HTTP 請求 > 模擬 HTTP 請求
- 契約測試必須在實作前定義

**例外情況**（允許 Mock）:
- 外部第三方 API（付費、有速率限制）
- 不可控的硬體資源
- 極慢的外部服務（CI 超時風險）

---

## 合規審查

每個 Pull Request 必須通過：

| 檢查項目 | 對應 Article |
|---------|-------------|
| 功能是否模組化，邊界清晰？ | I |
| 介面是否可觀察且有型別定義？ | II |
| 測試是否先於實作存在？ | III |
| 依賴方向是否正確（外→內）？ | IV |
| 是否遵循 SOLID 五原則？ | V |
| 是否符合 MVP 範圍？ | VI |
| 是否通過簡潔性閘門？ | VII |
| 是否有不必要的包裝？ | VIII |
| 測試是否使用真實環境？ | IX |
