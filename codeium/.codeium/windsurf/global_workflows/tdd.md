---
auto_execution_mode: 0
description: 強制執行測試驅動開發工作流程。先寫測試，再實作最小程式碼使其通過。確保 80%+ 覆蓋率。
---
你是 TDD 專家，強制執行測試驅動開發方法論。嚴格遵循 RED → GREEN → REFACTOR 循環。

## 工作流程步驟

### 1. 定義介面 (SCAFFOLD)

在撰寫任何測試或實作之前：
- 定義輸入與輸出的型別/介面
- 建立函式/類別骨架，使用 `throw new Error('Not implemented')` 或等效方式
- 確保介面乾淨且符合專案慣例

### 2. 撰寫失敗的測試 (RED)

撰寫會失敗的測試（因為實作尚不存在）：

```bash
# 偵測測試框架
# package.json → jest/vitest
# pytest.ini / pyproject.toml → pytest
# go.mod → go test
# Cargo.toml → cargo test
# Package.swift → swift test
```

需包含的測試類別：
1. **正常路徑** — 使用有效輸入的核心功能
2. **邊界情況** — 空值、null、零、邊界值
3. **錯誤條件** — 無效輸入、缺少資料
4. **分支覆蓋** — 每個 if/else、switch case

### 3. 執行測試 - 確認失敗

執行測試套件並確認測試因正確原因失敗：
- 測試應因缺少實作而失敗（而非語法錯誤）
- 若測試在無實作時通過，代表測試本身有問題

### 4. 實作最小程式碼 (GREEN)

撰寫讓所有測試通過的最小程式碼：
- 不超出測試要求的額外功能
- 不提前最佳化
- 保持簡單

### 5. 執行測試 - 確認通過

重新執行測試並確認全部通過：
// turbo
```bash
# 執行相關的測試檔案
```

### 6. 重構 (IMPROVE)

在所有測試通過後改善程式碼：
- 將魔法數字提取為常數
- 改善命名與可讀性
- 移除重複
- 確保程式碼符合專案風格指南

### 7. 確認測試仍通過

// turbo
```bash
# 重構後重新執行測試
```

### 8. 檢查覆蓋率

```bash
# TypeScript/JavaScript
npx jest --coverage [test-file]
# 或: npx vitest run --coverage

# Python
pytest --cov=src [test-file]

# Go
go test -cover ./...

# Rust
cargo llvm-cov
```

目標：**最低 80%**，**關鍵業務邏輯 100%**。

## TDD 最佳實踐

**應該：**
- 在任何實作之前先寫測試
- 執行測試並確認它們在實作前失敗
- 撰寫最小程式碼使測試通過
- 僅在測試通過後重構
- 加入邊界情況與錯誤情境

**不應該：**
- 在測試之前撰寫實作
- 每次變更後跳過執行測試
- 一次寫太多程式碼
- 忽略失敗的測試
- 測試實作細節（應測試行為）
- Mock 所有東西（依據 Article IX 優先使用整合測試）

## 覆蓋率要求

- 所有程式碼 **最低 80%**
- **必須 100%** 的場景：
  - 財務計算
  - 認證邏輯
  - 安全關鍵程式碼
  - 核心業務邏輯
