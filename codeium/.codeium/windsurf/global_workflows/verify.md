---
auto_execution_mode: 0
description: 對當前程式碼庫執行全面驗證檢查（建構、型別、lint、測試、安全）。
---
你是品質保證專家。對當前程式碼庫狀態執行全面驗證。

## 工作流程步驟

### 1. 建構檢查

執行此專案的建構指令：

| 指標 | 建構指令 |
|------|----------|
| `package.json` 含 `build` script | `pnpm build` 或 `npm run build` |
| `tsconfig.json` | `npx tsc --noEmit` |
| `Cargo.toml` | `cargo build` |
| `go.mod` | `go build ./...` |
| `pyproject.toml` | `mypy .` |
| `Package.swift` | `swift build` |

建構失敗時，報告錯誤並停止。

### 2. 型別檢查

執行型別檢查器（若與建構分開）：
- TypeScript: `npx tsc --noEmit`
- Python: `mypy .`
- 報告所有錯誤含 file:line

### 3. Lint 檢查

執行專案的 linter：
- TS/JS: `npx eslint .`
- Python: `ruff check .`
- Go: `golangci-lint run`
- Rust: `cargo clippy -- -D warnings`
- Swift: `swiftlint lint`
- PHP: `./vendor/bin/pint --test`

### 4. 測試套件

執行所有測試並報告：
- 通過/失敗數量
- 覆蓋率百分比（若可用）

### 5. 安全稽核

搜尋潛在安全問題：
- 硬編碼密鑰（API key、密碼、token）
- 原始碼檔案中的 `console.log` 語句
- 未加入 `.gitignore` 的 `.env` 檔案

### 6. Git 狀態

顯示未提交的變更與自上次 commit 以來修改的檔案。

## 輸出格式

產生簡潔的驗證報告：

```
VERIFICATION: [PASS/FAIL]

Build:    [OK/FAIL]
Types:    [OK/X errors]
Lint:     [OK/X issues]
Tests:    [X/Y passed, Z% coverage]
Security: [OK/X found]
Logs:     [OK/X console.logs]

Ready for PR: [YES/NO]
```

若有關鍵問題，列出並附上修復建議。

## 參數

使用者可指定模式：
- `quick` — 僅建構 + 型別
- `full` — 所有檢查（預設）
- `pre-commit` — commit 相關檢查（建構、型別、lint、安全）
- `pre-pr` — 完整檢查加安全掃描
