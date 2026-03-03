# 全域開發規則

> 所有專案的核心規則摘要。詳細規範請參閱對應的補充規則文件（`00-06`、`languages/`、`tools/`）。

## 語言與環境

- 回應方式：永遠使用台灣地區的繁體中文及相關用語
- 本地開發：macOS
- 部署環境（Docker/VM）：Debian，使用 zsh 或 bash

---

## 核心架構原則（詳見 `00-core-principles.md`）

遵循 Nine Articles of Development：

1. **Library-First**：功能先以獨立模組設計，禁止直接在應用層實作
2. **Interface Mandate**：核心功能必須有明確的輸入/輸出介面與型別定義
3. **Test-First**：TDD（Red → Green → Refactor），核心邏輯 ≥80% 覆蓋率
4. **Clean Architecture**：依賴由外向內（Presentation → Application → Domain ← Infrastructure）
5. **SOLID**：SRP、OCP、LSP、ISP、DIP 不可妥協
6. **MVP-First**：YAGNI，禁止「未來可能需要」的抽象，P1 → P2 → P3 漸進
7. **Simplicity Gate**：設計決策須通過簡潔性閘門（≤3 模組、無過度抽象）
8. **Anti-Abstraction**：直接使用框架功能，禁止無謂包裝
9. **Integration-First Testing**：測試盡可能接近真實環境（真實 DB > Mock）

---

## 程式碼風格（詳見 `01-code-style.md`）

### 命名慣例

| 類型 | 慣例 |
|------|------|
| 類別/介面/型別 | `PascalCase` |
| 函式/方法 | `camelCase` |
| 變數/參數 | `camelCase`(JS/TS) / `snake_case`(Python) |
| 常數 | `UPPER_SNAKE_CASE` |
| 布林變數 | `is`/`has`/`can` 前綴 |

### 格式

- 縮排：Space（TS/JS/JSON/YAML/HTML/CSS: 2 spaces；Python/PHP/SQL: 4 spaces）
- 每行 ≤ 120 字元，函式 ≤ 50 行，類別 ≤ 300 行，檔案 ≤ 500 行，參數 ≤ 4 個
- 匯入順序：內建 → 第三方 → 內部模組 → 相對路徑（空行分隔）
- Trailing Comma：多行陣列/物件/參數加尾逗號

### 錯誤處理

- 永不吞掉錯誤：catch 必須記錄日誌或重新拋出
- 使用自定義錯誤類別區分業務/系統錯誤
- 提供含上下文的有意義錯誤訊息

### 註解與 Dead Code

- 說明「為什麼」而非「是什麼」
- 公開 API 必須有 JSDoc / docstring
- TODO 格式：`// TODO(name): description [ISSUE-ID]`
- 禁止提交：已註解程式碼、未使用的變數/匯入、魔法數字

---

## 開發工作流程（詳見 `02-workflow.md`）

### 三種模式

| 模式 | 適用場景 | 規則文件 |
|------|---------|---------|
| **Spec-Kit (SDD)** | 正式專案、多人協作 | `specify-rules.md` |
| **OpenSpec (OPSX)** | AI 驅動、快速迭代 | `opsx-rules.md` |
| **Vibe Coding** | 探索/原型/POC | 無（遵循最低要求） |

### 通用準則

- 分支策略：`main` → `develop` → `feature/fix/chore/{id}-{desc}`
- 合併：feature→develop Squash；develop→main Merge Commit
- PR ≤ 400 行，標題使用 Conventional Commits 格式
- Code Review：邏輯正確性、安全性、效能、SOLID、測試完整性

---

## AI 工具使用（詳見 `03-ai-tools.md`）

- AI 是架構夥伴，不是程式碼生成機器
- 提示結構：`[上下文] [任務] [限制] [輸出]`
- 高價值：規格撰寫、骨架、測試生成、文件、重構建議
- 謹慎使用：複雜業務邏輯、安全程式碼、DB Migration
- 避免：整個功能端對端生成、未閱讀直接修改
- AI 除錯迴圈：連續三次未解決 → 停下手動分析
- 驗收標準：理解每行程式碼、測試覆蓋、無硬編碼密鑰、符合現有風格
- 成本最佳化：批次處理相關變更，避免不必要的 AI 呼叫

---

## 測試策略（詳見 `04-testing.md`）

- 金字塔比例：Unit 70% · Integration 20% · E2E 10%
- 覆蓋率：Domain ≥80%、Service/Repository ≥70%、API 契約 100%
- TDD：Red → Green → Refactor
- 測試命名：`[方法]_[情境]_[預期結果]`，Given/When/Then 結構
- 依賴注入是可測試性基礎
- Mock：外部 API、時間、隨機；真實 DB/快取/佇列（Article IX）
- 反模式：測試私有方法、過度 Mock、測試間共享狀態、sleep() 等待、一個測試驗證多個行為

---

## 安全性（詳見 `05-security.md`）

- OWASP Top 10 防護：存取控制、加密、注入防護、安全配置
- 密碼：bcrypt/Argon2（cost ≥12），禁止 MD5/SHA1/明文
- SQL：參數化查詢或 ORM，禁止字串拼接
- XSS：textContent 或 DOMPurify，禁止 innerHTML 直接插入使用者輸入
- 環境變數：禁止硬編碼密鑰，`.env` 加入 `.gitignore`，提供 `.env.example`
- JWT：access token ≤15min，refresh token rotation
- 輸入驗證：永遠不信任輸入（使用 zod/joi 等驗證庫）
- 安全 Headers：CSP、HSTS、X-Frame-Options（helmet.js）
- 依賴漏洞：高危 24hr、中危 7天內修補
- 日誌：記錄安全事件，禁止記錄密碼/Token/個資

---

## Git 規範（詳見 `06-git.md`）

### Conventional Commits

```
<type>(<scope>): <description>
```

Types: `feat` | `fix` | `refactor` | `test` | `docs` | `chore` | `style` | `perf` | `ci` | `build` | `revert`

### Commit 紀律

- 原子性：一個 commit 只做一件事
- 描述：動詞開頭、≤72 字元、不加句點
- 禁止提交：硬編碼密鑰、註解程式碼、console.log、合併衝突標記
- AI 生成 commit：使用 `/git-commit` workflow

### 分支與版本

- 命名：`feature/{id}-{desc}`、`fix/{id}-{desc}`、`hotfix/{id}-{desc}`
- 開發中定期 rebase，禁止 force push 到 main/develop
- SemVer：BREAKING CHANGE → MAJOR、feat → MINOR、fix → PATCH

---

## 一般行為準則

<behavioral_guidelines>

- 進行小幅度、漸進式的變更；避免大規模重構
- 除非明確要求，否則不更改可運作的程式碼
- 修改程式碼時逐步進行，先驗證變更
- 如有不確定，先請求釐清再產生程式碼
- 逐步推理後再產生程式碼或發送回應
- 注意成本，僅在必要時發送請求，批次處理變更
- 除錯：漸進式小修改，查看終端機輸出
- 始終遵循使用者指示，使用者指示優先於全域規則
- 避免過度設計，追求最簡單的解決方案

</behavioral_guidelines>

## 檔案處理

- 長檔案分解為較小、更易管理的檔案
- 優先從其他檔案匯入函式，而非直接修改
- 依目錄結構組織檔案

## 專案管理

- 任務開始前必須先檢查目錄結構與 README.md
- 參考專案的功能規劃以獲取上下文
- 每次變更後更新功能規劃進度
- 每個回應中建議下一步驟

## 語言特定（詳見 `languages/` 目錄）

- **Python**：型別提示、分組匯入（標準/外部/本地）、pylint、pytest
- **JavaScript/TypeScript**：ES 現代語法、const/let 優先、eslint、jest、JSDoc
- **PHP**：PSR-12、PHPStan、PHPUnit
- **SQL**：關鍵字大寫、參數化查詢、索引策略
