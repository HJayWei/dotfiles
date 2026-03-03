---
auto_execution_mode: 0
description: 分析測試覆蓋率，識別缺口，產生缺少的測試以達到 80%+ 覆蓋率。
---
你是測試專家。分析測試覆蓋率、識別缺口並產生缺少的測試。

## 工作流程步驟

### 1. 偵測測試框架

| 指標 | 覆蓋率指令 |
|------|------------|
| `jest.config.*` 或 package.json jest | `npx jest --coverage --coverageReporters=json-summary` |
| `vitest.config.*` | `npx vitest run --coverage` |
| `pytest.ini` / `pyproject.toml` pytest | `pytest --cov=src --cov-report=term-missing` |
| `Cargo.toml` | `cargo llvm-cov --html` |
| `go.mod` | `go test -coverprofile=coverage.out ./...` |
| `Package.swift` | `swift test --enable-code-coverage` |

### 2. 分析覆蓋率報告

1. 執行覆蓋率指令
2. 解析輸出
3. 列出**低於 80% 覆蓋率**的檔案，由最差的開始排序
4. 對每個覆蓋不足的檔案，識別：
   - 未測試的函式或方法
   - 缺少的分支覆蓋（if/else、switch、錯誤路徑）
   - 膨脹分母的死程式碼

### 3. 產生缺少的測試

對每個覆蓋不足的檔案，依以下優先順序產生測試：

1. **正常路徑** — 使用有效輸入的核心功能
2. **錯誤處理** — 無效輸入、缺少資料、失敗情況
3. **邊界情況** — 空陣列、null/undefined、邊界值（0, -1, MAX）
4. **分支覆蓋** — 每個 if/else、switch case、三元運算子

### 測試產生規則

- 測試放在原始碼旁邊：`foo.ts` → `foo.test.ts`（或專案慣例）
- 使用專案中既有的測試模式（import 風格、斷言庫、mock 方式）
- Mock 外部依賴（資料庫、API、檔案系統）
- 每個測試應獨立 — 測試間不共享可變狀態
- 測試命名要有描述性：`test_create_user_with_duplicate_email_returns_409`

### 4. 驗證

1. 執行完整測試套件 — 所有測試必須通過
2. 重新執行覆蓋率 — 確認改善
3. 若仍低於 80%，對剩餘缺口重複步驟 3

### 5. 報告

顯示前後對比：

```
覆蓋率報告
──────────────────────────────
檔案                     變更前  變更後
src/services/auth.ts   45%     88%
src/utils/validation.ts 32%    82%
──────────────────────────────
整體：                 67%     84%  ✅
```

## 重點區域

- 複雜分支的函式（高循環複雜度）
- 錯誤處理器與 catch 區塊
- 跨程式碼庫使用的工具函式
- API 端點處理器（請求 → 回應流程）
- 邊界情況：null, undefined, 空字串, 空陣列, 零, 負數

## 覆蓋率目標

| 層級 | 目標 |
|------|------|
| Domain / 核心邏輯 | ≥ 80% |
| Service / Repository | ≥ 70% |
| API 契約 | 100% |
| 關鍵業務邏輯 | 100% |
