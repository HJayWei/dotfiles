# 04 · 測試策略與品質準則（補充規則）

> **本文件為 `global_rules.md` 的詳細補充**。測試金字塔、覆蓋率目標、TDD 流程摘要已提取至全域規則，此處提供完整範例、整合測試、契約測試、測試資料管理等詳細內容。
>
> 參考來源：Google Testing Blog、Meta Engineering（TestPilot）、TDD by Example（Kent Beck）

---

## 測試金字塔

```
        /\
       /E2E\          ← 少量：驗證關鍵使用者旅程（慢、貴）
      /------\
     /Integration\    ← 適量：驗證元件間協作（中等速度）
    /------------\
   /  Unit Tests  \   ← 大量：驗證個別函式/類別（快、便宜）
  /________________\
```

**比例建議**：Unit 70% · Integration 20% · E2E 10%

**反模式（Ice Cream Cone）**：
```
  E2E   ← 大量（慢、脆弱、難維護）
 -------
 Integration ← 少量
  --------
  Unit ← 幾乎沒有
```

---

## 覆蓋率目標

| 層級 | 覆蓋率目標 | 強制執行 |
|------|-----------|---------|
| 核心業務邏輯（Domain Layer） | ≥ 80% | CI 必須通過 |
| 服務層（Service Layer） | ≥ 70% | CI 必須通過 |
| 資料層（Repository Layer） | ≥ 70% | CI 必須通過 |
| API 端點（Controllers） | 契約測試 100% | CI 必須通過 |
| 基礎設施層 | ≥ 50% | 建議達成 |

> **覆蓋率是底線，不是目標。** 100% 覆蓋率不等於良好測試。關注測試的語意完整性，而非數字。

---

## TDD 工作流程（Red → Green → Refactor）

### Step 1：Red（寫失敗的測試）

```typescript
// ✅ 先寫測試，此時 UserService 尚未實作
describe('UserService.createUser', () => {
  it('成功建立使用者並回傳包含 id 的使用者物件', async () => {
    // Arrange
    const dto: CreateUserDto = { name: '王小明', email: 'wang@example.com' };
    const mockRepo = { save: jest.fn().mockResolvedValue({ id: 'uuid-123', ...dto }) };
    const service = new UserService(mockRepo);

    // Act
    const result = await service.createUser(dto);

    // Assert
    expect(result.id).toBeDefined();
    expect(result.email).toBe('wang@example.com');
    expect(mockRepo.save).toHaveBeenCalledWith(expect.objectContaining(dto));
  });

  it('當 email 格式錯誤時拋出 ValidationError', async () => {
    const dto: CreateUserDto = { name: '王小明', email: 'invalid-email' };
    const service = new UserService(new MockUserRepository());

    await expect(service.createUser(dto)).rejects.toThrow(ValidationError);
  });
});
```

### Step 2：Green（最少程式碼使測試通過）

實作最簡單能使測試通過的程式碼，不要過度設計。

### Step 3：Refactor（重構）

在測試全部通過的前提下，改善程式碼品質。重構後測試必須仍然通過。

---

## 測試命名規範

### 格式

```
[單元/方法名稱] + [情境] + [預期結果]

// ✅ 清晰
it('createUser_當email重複時_拋出DuplicateEmailError', ...);
it('calculateTotal_包含折扣時_正確計算折扣後金額', ...);

// ✅ 英文格式（When / Should）
it('should throw DuplicateEmailError when email already exists', ...);

// ❌ 模糊
it('測試使用者建立', ...);
it('works correctly', ...);
```

### Given / When / Then 結構

```typescript
it('當訂單金額超過 1000 元時，應套用 10% 折扣', () => {
  // Given（前置條件）
  const order = new Order({ items: [{ price: 500, quantity: 3 }] });

  // When（執行動作）
  const total = order.calculateTotal();

  // Then（驗證結果）
  expect(total).toBe(1350); // 1500 * 0.9
});
```

---

## 測試隔離原則

### 依賴注入是測試的基礎

```typescript
// ❌ 無法測試（直接依賴具體實作）
class OrderService {
  async create(dto: OrderDto) {
    const db = new Database();       // 無法 mock
    const mailer = new Mailer();     // 無法 mock
  }
}

// ✅ 可測試（依賴注入）
class OrderService {
  constructor(
    private readonly orderRepo: OrderRepository,
    private readonly mailer: MailService,
  ) {}

  async create(dto: OrderDto) {
    const order = await this.orderRepo.save(dto);
    await this.mailer.sendConfirmation(order);
    return order;
  }
}
```

### Mock 使用準則

**應該 Mock 的**:
- 外部 API（第三方服務、付費 API）
- 時間相關函式（`Date.now()`、`setTimeout`）
- 隨機函式（`Math.random()`）
- 檔案系統操作（單元測試中）

**應該使用真實實作的（Article IX）**:
- 資料庫（使用 in-memory DB 或 test container）
- 快取層（Redis 使用 ioredis-mock 或真實 Redis）
- 訊息佇列（使用 test instance）

---

## 整合測試準則

```typescript
// ✅ 整合測試：使用真實資料庫
describe('UserRepository 整合測試', () => {
  let dataSource: DataSource;

  beforeAll(async () => {
    dataSource = await createTestDatabase();  // SQLite in-memory 或 test container
  });

  afterAll(async () => {
    await dataSource.destroy();
  });

  beforeEach(async () => {
    await dataSource.synchronize(true);  // 每次測試前清空資料
  });

  it('save() 應儲存使用者並回傳含 id 的物件', async () => {
    const repo = new UserRepository(dataSource);
    const user = await repo.save({ name: '測試', email: 'test@example.com' });
    expect(user.id).toBeDefined();
  });
});
```

---

## API 契約測試

在實作 API 之前，必須先定義並測試契約。

```typescript
// 契約測試：驗證 API 回應格式符合約定
describe('POST /api/users 契約測試', () => {
  it('成功回應必須包含 id、name、email、createdAt 欄位', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ name: '測試', email: 'test@example.com' });

    expect(response.status).toBe(201);
    expect(response.body).toMatchObject({
      id: expect.any(String),
      name: expect.any(String),
      email: expect.any(String),
      createdAt: expect.any(String),
    });
  });

  it('驗證失敗時回應 422 並包含 errors 陣列', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ name: '', email: 'invalid' });

    expect(response.status).toBe(422);
    expect(response.body.errors).toBeInstanceOf(Array);
    expect(response.body.errors.length).toBeGreaterThan(0);
  });
});
```

---

## 測試資料管理

### 工廠模式（Factory Pattern）

```typescript
// tests/factories/user.factory.ts
export function createUserDto(overrides: Partial<CreateUserDto> = {}): CreateUserDto {
  return {
    name: '預設使用者',
    email: `user-${Date.now()}@example.com`,
    role: 'user',
    ...overrides,
  };
}

// 使用
const adminUser = createUserDto({ role: 'admin' });
const invalidUser = createUserDto({ email: 'invalid' });
```

### 禁止使用真實生產資料進行測試

- 測試資料必須是合成的、可重複的
- 使用工廠函式生成測試資料
- 不得在測試程式碼中出現真實個資

---

## 測試環境設定

### CI/CD 測試流程

```yaml
# 建議的 CI 測試流程
test:
  steps:
    - name: 單元測試
      run: npm run test:unit -- --coverage
    - name: 整合測試
      run: npm run test:integration
    - name: 覆蓋率檢查
      run: npm run test:coverage-check  # 低於門檻則失敗
    - name: Lint 檢查
      run: npm run lint
```

### 測試腳本命名慣例

```json
{
  "scripts": {
    "test": "jest",
    "test:unit": "jest --testPathPattern='unit'",
    "test:integration": "jest --testPathPattern='integration'",
    "test:e2e": "jest --testPathPattern='e2e'",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  }
}
```

---

## 常見測試反模式

| 反模式 | 問題 | 改善方式 |
|--------|------|---------|
| **測試私有方法** | 測試實作細節，脆弱 | 透過公開介面測試行為 |
| **過度 Mock** | 測試不代表真實行為 | 使用整合測試取代 |
| **測試順序依賴** | 測試間共享狀態 | 每個測試獨立設定前置條件 |
| **寫了測試但不運行** | 失去信心保障 | CI 強制執行測試 |
| **一個測試驗證多個行為** | 失敗時難以定位問題 | 每個測試只驗證一件事 |
| **使用 `sleep()` 等待** | 測試不穩定（flaky） | 使用確定性的等待機制 |

---

## Web App E2E 測試工具

Web 應用程式的前端 E2E 測試可使用 **`webapp-testing` skill**（基於 Python Playwright），透過 Windsurf 呼叫 skill 進行 UI 驗證、截圖、Console Log 擷取。

**適用場景**：
- 驗證前端 UI 功能與互動行為
- 除錯動態頁面渲染問題
- 擷取瀏覽器截圖作為測試證據

**使用方式**：
```bash
# 使用 helper script 啟動 server 並執行自動化測試
python scripts/with_server.py --server "npm run dev" --port 5173 -- python your_automation.py
```

> 詳細使用方式請參考 `webapp-testing` skill 文件，首次使用請先執行 `--help` 查看參數。
