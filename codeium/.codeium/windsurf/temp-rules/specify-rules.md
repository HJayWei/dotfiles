# Spec-Kit (SDD) 工作流程規則（Mode A）

> 此規則檔適用於使用 GitHub Spec-Kit 進行 Specification-Driven Development 的專案。
> 複製至專案的 `.windsurf/rules/specify-rules.md` 即可啟用。

---

## 啟用條件

當專案採用 Spec-Kit (SDD) 工作流程時套用此規則。

**前置需求**：專案已執行 `specify init .`，產生 `.specify/` 與 `.windsurf/workflows/speckit.*.md`。

---

## 核心工具

- **CLI / Scripts**：`.specify/scripts/bash/` 下的輔助腳本
- **Workflows**：位於 `.windsurf/workflows/speckit.*.md`
- **Templates**：位於 `.specify/templates/`（spec、plan、tasks、constitution 模板）
- **Memory**：`.specify/memory/constitution.md`（專案憲章，不可違反）

---

## 目錄結構

```
.specify/
├── memory/
│   └── constitution.md        ← 專案憲章（原則與治理規則）
├── templates/
│   ├── spec-template.md
│   ├── plan-template.md
│   ├── tasks-template.md
│   └── constitution-template.md
└── scripts/bash/
    ├── create-new-feature.sh
    ├── setup-plan.sh
    ├── check-prerequisites.sh
    └── update-agent-context.sh

specs/
└── {N}-{feature-short-name}/
    ├── spec.md                ← 需求規格
    ├── plan.md                ← 實作計畫
    ├── tasks.md               ← 任務清單
    ├── research.md            ← 技術研究結果
    ├── data-model.md          ← 資料模型
    ├── contracts/             ← 介面契約
    ├── quickstart.md          ← 整合測試場景
    └── checklists/            ← 品質檢查清單
        └── requirements.md
```

---

## 核心準則

### 規格優先

- **規格（Specification）是第一公民**，程式碼是其表達式
- 所有功能開發必須先經過規格化流程，再進入實作
- 需求變更透過規格重新生成處理，而非手動修改程式碼

### 完整指令表

| 指令 | 用途 | 階段 |
|------|------|------|
| `/speckit.constitution` | 建立或更新專案憲章 | 專案初始化 |
| `/speckit.specify` | 從功能描述生成需求規格（含品質驗證） | Phase 1 |
| `/speckit.clarify` | 識別規格中的模糊點，提問後回寫 | Phase 1 補充 |
| `/speckit.checklist` | 針對特定領域生成品質檢查清單 | 任意階段 |
| `/speckit.plan` | 生成實作計畫（research → data-model → contracts） | Phase 2 |
| `/speckit.tasks` | 生成依賴排序的任務清單 | Phase 3 |
| `/speckit.analyze` | **唯讀**跨文件一致性分析（不修改任何檔案） | Phase 3 後 |
| `/speckit.implement` | 按任務順序執行實作 | Phase 4 |
| `/speckit.taskstoissues` | 將 tasks.md 轉為 GitHub Issues | 任意階段 |

### 五階段流程

1. **需求規格** (`/speckit.specify`) → `spec.md`（含自動品質驗證與 checklist 生成）
2. **實作規劃** (`/speckit.plan`) → `plan.md` + `research.md` + `data-model.md` + `contracts/`
3. **任務拆解** (`/speckit.tasks`) → `tasks.md`（嚴格 checklist 格式，依 User Story 分 Phase）
4. **實作** (`/speckit.implement`) → 按任務順序實作（先檢查 checklists 通過狀態）
5. **品質驗證** (`/speckit.analyze`) → 唯讀分析報告（Duplication / Ambiguity / Coverage / Constitution）

### Task 格式規範

每個任務**必須**嚴格遵循此格式：
```
- [ ] [TaskID] [P?] [Story?] Description with file path
```

- **TaskID**：`T001`, `T002`...（循序編號）
- **[P]**：可並行執行標記（僅限不同檔案、無相依性時）
- **[Story]**：`[US1]`, `[US2]`...（對應 spec.md 的 User Story）
- **Description**：明確動作 + 確切檔案路徑

### 實作紀律

- P1 完成並驗證後，才能進行 P2
- 每個任務完成後立即進行 Code Review
- 測試先行（Red → Green → Refactor）
- 小幅度、漸進式提交（每個 commit 只做一件事）
- 完成的任務標記為 `[x]`

### Constitution（專案憲章）

- 位於 `.specify/memory/constitution.md`，使用 `/speckit.constitution` 管理
- **非可協商**：Constitution 中的 MUST 原則在 `/speckit.analyze` 中自動標記為 CRITICAL
- 任何原則違反須在 `plan.md` 中明確文件化理由
- 憲章版本遵循 SemVer（MAJOR: 原則移除 / MINOR: 新增原則 / PATCH: 用詞修正）

### Constitution Check（每次 Plan 必須通過）

- [ ] 初始實作使用 ≤ 3 個模組？（Article VII 簡潔性閘門）
- [ ] 無「未來可能需要」的抽象？（Article VIII 反過度抽象）
- [ ] 契約已定義且契約測試已撰寫？（Article IX 整合優先）

---

## AI 協作準則

- AI 是**架構夥伴**，協助規格撰寫、計畫審查、程式碼生成
- 所有 AI 生成的內容必須經過人工審查
- 規格文件由人主導撰寫，AI 輔助完善（最多 3 個 `[NEEDS CLARIFICATION]` 標記）
- 實作程式碼由 AI 生成後，人工驗證正確性
- `/speckit.analyze` 為唯讀操作，AI 不得自動修改檔案

---

## 參考

- 完整工作流程說明：`02-workflow.md` → Mode A
- 核心架構原則：`00-core-principles.md`
- Git 規範：`06-git.md`
- [GitHub Spec-Kit](https://github.com/github/spec-kit)
