# 通用開發準則 (Universal Development Rules)

> 整合自 spec-driven.md、企業工程憲章、及 Google / Meta / OpenAI / Windsurf 資深工程師的最佳實踐。
>
> **版本**: 2.0.0 | **更新**: 2026-03-03 | **語言**: 正體中文（技術術語除外）

---

## 架構概覽

本規則集依 **Windsurf 三層架構**（Memory → Rules → Workflows/Skills）組織。
所有規則檔案為**扁平結構**（Windsurf `.windsurf/rules/` 不支援子目錄）。

```
┌─────────────────────────────────────────────────────────┐
│  Memory（全域記憶）                                       │
│  global_rules.md → 核心摘要，所有專案自動載入               │
├─────────────────────────────────────────────────────────┤
│  Rules（規則文件，每個 ≤12000 chars，扁平放置）             │
│  ├── Always On：00-core-principles, 01-code-style,      │
│  │              03-ai-tools                             │
│  ├── Model Decision：02-workflow, 04-testing,           │
│  │     05-security, 06-git, tool-container, tool-linting│
│  ├── Glob：lang-* (*.py, *.ts, *.php, *.sql, *.go,    │
│  │         *.swift, *.rs, *.vue)                        │
│  └── Manual：opsx-rules, specify-rules                  │
├─────────────────────────────────────────────────────────┤
│  Workflows（/slash-command）& Skills（@skill-name）       │
│  ├── /git-commit, /plan, /tdd, /build-fix, /verify,    │
│  │   /refactor-clean, /test-coverage, /built-in-review  │
│  ├── /opsx-*, /speckit.*                                │
│  └── @git-commit-generator, @webapp-testing             │
└─────────────────────────────────────────────────────────┘
```

---

## 檔案清單與 Windsurf 分類

### Memory（全域記憶）

| 檔案 | 說明 | 部署位置 |
|------|------|---------|
| `global_rules.md` | 所有規則的核心摘要（6.8K chars） | `~/.codeium/windsurf/memories/global_rules.md` |

### Rules（補充規則）

> **注意**：所有檔案必須放在 `.windsurf/rules/` 根目錄下，不可使用子目錄。

| 檔案 | 啟用模式 | 說明 |
|------|---------|------|
| `00-core-principles.md` | Always On | Nine Articles、SOLID、Clean Architecture 完整範例 |
| `01-code-style.md` | Always On | 命名、格式、錯誤處理完整範例 |
| `02-workflow.md` | Model Decision | Vibe Coding、分支策略、PR、Code Review |
| `03-ai-tools.md` | Always On | 提示工程、場景分類、Windsurf 特定準則 |
| `04-testing.md` | Model Decision | TDD 完整範例、整合測試、契約測試 |
| `05-security.md` | Model Decision | OWASP Top 10 完整範例 |
| `06-git.md` | Model Decision | Conventional Commits 完整範例、Rebase、Hooks |
| `opsx-rules.md` | Manual | OpenSpec (OPSX) 工作流程規則 |
| `specify-rules.md` | Manual | Spec-Kit (SDD) 工作流程規則 |
| `lang-typescript.md` | Glob: `**/*.ts, **/*.tsx, **/*.js, **/*.jsx` | TypeScript/JavaScript 特定準則 |
| `lang-python.md` | Glob: `**/*.py` | Python 特定準則 |
| `lang-php.md` | Glob: `**/*.php` | PHP (Laravel) 特定準則 |
| `lang-sql.md` | Glob: `**/*.sql` | SQL / 資料庫查詢準則 |
| `lang-golang.md` | Glob: `**/*.go, **/go.mod, **/go.sum` | Go 特定準則 |
| `lang-swift.md` | Glob: `**/*.swift, **/Package.swift` | Swift 特定準則 |
| `lang-rust.md` | Glob: `**/*.rs, **/Cargo.toml, **/Cargo.lock` | Rust 特定準則 |
| `lang-vue.md` | Glob: `**/*.vue, **/*.ts, **/*.js` | Vue.js 特定準則 |
| `tool-container.md` | Model Decision | Docker / Podman 容器化準則 |
| `tool-linting.md` | Model Decision | Linting & Formatting 工具設定 |

### 啟用模式說明

| 模式 | 行為 |
|------|------|
| **Always On** | 每次對話自動載入 |
| **Model Decision** | AI 依任務內容判斷是否載入（需撰寫觸發描述） |
| **Glob** | 當操作的檔案符合 glob pattern 時自動載入 |
| **Manual** | 使用者在 Cascade 中 `@規則名稱` 手動啟用 |

> **注意**：啟用模式已透過各檔案的 YAML frontmatter 設定（`trigger: always_on | model_decision | glob | manual`），部署後 Windsurf 會自動讀取。

---

## 工作流程模式

| 模式 | 適用場景 | 核心指令 | 規則文件 |
|------|---------|---------|---------|
| **Spec-Kit (SDD)** | 正式專案、多人協作 | `/speckit.*` | `@specify-rules` |
| **OpenSpec (OPSX)** | AI 驅動、快速迭代 | `/opsx-*` | `@opsx-rules` |
| **Vibe Coding** | 探索/原型/POC | 無 | `02-workflow.md` |

---

## 優先級層次

```
使用者即時指示  >  本規則集  >  框架預設慣例  >  語言標準
```

---

## 設計哲學

| 哲學 | 意涵 |
|------|------|
| **Observability over Opacity** | 一切可觀察可驗證；透過介面暴露功能 |
| **Simplicity over Cleverness** | 先求簡單，僅在必要時增加複雜度 |
| **Integration over Isolation** | 真實環境測試，而非人工隔離 |
| **Modularity over Monoliths** | 每個功能具備清晰邊界 |

---

## 快速參考

### Non-Negotiable

- SOLID 原則（`00-core-principles.md`）
- 測試先行 TDD（`04-testing.md`）
- 函式 ≤50 行、檔案 ≤500 行（`01-code-style.md`）
- 敏感資訊使用環境變數（`05-security.md`）
- Conventional Commits（`06-git.md`）

### 常用指令

| 需求 | 指令 |
|------|------|
| 生成 commit message | `/git-commit` |
| 實作規劃（確認才動手）| `/plan` |
| TDD 開發循環 | `/tdd` |
| 修復建置錯誤 | `/build-fix` |
| 全面驗證 | `/verify` |
| 清除 dead code | `/refactor-clean` |
| 覆蓋率分析與補齊 | `/test-coverage` |
| 程式碼審查 | `/built-in-review` |
| 開始新功能（OPSX） | `/opsx-new` 或 `/opsx-ff` |
| 執行任務（OPSX） | `/opsx-apply` |
| 驗證（OPSX） | `/opsx-verify` |
| 探索想法 | `/opsx-explore` |
| 需求規格（SDD） | `/speckit.specify` |
| 實作（SDD） | `/speckit.implement` |

---

## 參考來源

- [GitHub Spec-Kit](https://github.com/github/spec-kit/blob/main/spec-driven.md)
- [Fission-AI OpenSpec](https://github.com/Fission-AI/OpenSpec)
- [Google Engineering Practices](https://google.github.io/eng-practices/)
- [Windsurf Documentation](https://docs.windsurf.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
