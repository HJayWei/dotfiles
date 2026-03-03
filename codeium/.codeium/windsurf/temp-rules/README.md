# 通用開發準則 (Universal Development Rules)

> 整合自 spec-driven.md、企業工程憲章、及 Google / Meta / OpenAI / Windsurf 資深工程師的最佳實踐。
>
> **版本**: 2.0.0 | **更新**: 2025-07 | **語言**: 正體中文（技術術語除外）

---

## 架構概覽

本規則集依 **Windsurf 三層架構**（Memory → Rules → Workflows/Skills）組織：

```
┌─────────────────────────────────────────────────────────┐
│  Memory（全域記憶）                                       │
│  global_rules.md → 核心摘要，所有專案自動載入               │
├─────────────────────────────────────────────────────────┤
│  Rules（規則文件，每個 ≤12000 chars）                      │
│  ├── Always On：00-core-principles, 01-code-style,      │
│  │              03-ai-tools                             │
│  ├── Model Decision：02-workflow, 04-testing,           │
│  │                   05-security, 06-git, tools/*       │
│  ├── Glob：languages/* (*.py, *.ts, *.php, *.sql)       │
│  └── Manual：opsx-rules, specify-rules                  │
├─────────────────────────────────────────────────────────┤
│  Workflows（/slash-command）& Skills（@skill-name）       │
│  ├── /git-commit, /opsx-*, /speckit.*                   │
│  └── @git-commit-generator, @webapp-testing             │
└─────────────────────────────────────────────────────────┘
```

---

## 目錄結構與 Windsurf 分類

### Memory（全域記憶）

| 檔案 | 說明 | 部署位置 |
|------|------|---------|
| `global_rules.md` | 所有規則的核心摘要（6.8K chars） | `~/.codeium/windsurf/memories/global_rules.md` |

### Rules（補充規則）

| 檔案 | 啟用模式 | 說明 | chars |
|------|---------|------|-------|
| `00-core-principles.md` | Always On | Nine Articles、SOLID、Clean Architecture 完整範例 | 7.7K |
| `01-code-style.md` | Always On | 命名、格式、錯誤處理完整範例 | 7.3K |
| `02-workflow.md` | Model Decision | Vibe Coding、分支策略、PR、Code Review | 6.3K |
| `03-ai-tools.md` | Always On | 提示工程、場景分類、Windsurf 特定準則 | 5.8K |
| `04-testing.md` | Model Decision | TDD 完整範例、整合測試、契約測試 | 9.0K |
| `05-security.md` | Model Decision | OWASP Top 10 完整範例 | 8.3K |
| `06-git.md` | Model Decision | Conventional Commits 完整範例、Rebase、Hooks | 8.8K |
| `opsx-rules.md` | Manual | OpenSpec (OPSX) 工作流程規則 | 4.3K |
| `specify-rules.md` | Manual | Spec-Kit (SDD) 工作流程規則 | 5.3K |
| `languages/typescript.md` | Glob: `*.ts,*.tsx,*.js,*.jsx` | TypeScript/JavaScript 特定準則 | 8.0K |
| `languages/python.md` | Glob: `*.py` | Python 特定準則 | 7.6K |
| `languages/php.md` | Glob: `*.php` | PHP (Laravel) 特定準則 | 8.3K |
| `languages/sql.md` | Glob: `*.sql` | SQL / 資料庫查詢準則 | 7.7K |
| `tools/container.md` | Model Decision | Docker / Podman 容器化準則 | 9.8K |
| `tools/linting.md` | Model Decision | Linting & Formatting 工具設定 | 8.3K |

### 啟用模式說明

| 模式 | 行為 |
|------|------|
| **Always On** | 每次對話自動載入 |
| **Model Decision** | AI 依任務內容判斷是否載入（需撰寫觸發描述） |
| **Glob** | 當操作的檔案符合 glob pattern 時自動載入 |
| **Manual** | 使用者在 Cascade 中 `@規則名稱` 手動啟用 |

---

## 部署指南

將 `temp-rules/` 內容部署至 Windsurf 正式位置：

```bash
# 1. 部署 Memory（全域記憶）
cp temp-rules/global_rules.md ~/.codeium/windsurf/memories/global_rules.md

# 2. 部署 Rules（補充規則）至專案 .windsurf/rules/
#    或全域 ~/.codeium/windsurf/rules/
TARGET=~/.codeium/windsurf/rules   # 全域
# TARGET=.windsurf/rules           # 專案級

mkdir -p "$TARGET/languages" "$TARGET/tools"
cp temp-rules/0*.md temp-rules/opsx-rules.md temp-rules/specify-rules.md "$TARGET/"
cp temp-rules/languages/*.md "$TARGET/languages/"
cp temp-rules/tools/*.md "$TARGET/tools/"

# 3. Workflows 和 Skills 已由 OpenSpec/Spec-Kit init 自動建立
#    /git-commit → ~/.codeium/windsurf/global_workflows/git-commit.md（已存在）
#    @git-commit-generator → ~/.codeium/windsurf/skills/git-commit-generator/（已存在）
```

> **注意**：部署後需在 Windsurf Customizations 面板中設定各規則的啟用模式。

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
