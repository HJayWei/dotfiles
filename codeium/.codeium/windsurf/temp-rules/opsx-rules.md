# OpenSpec (OPSX) 工作流程規則（Mode B）

> 此規則檔適用於使用 Fission-AI OpenSpec 進行 AI 輔助開發的專案。
> 複製至專案的 `.windsurf/rules/opsx-rules.md` 即可啟用。

---

## 啟用條件

當專案採用 OpenSpec (OPSX) 工作流程時套用此規則。

**前置需求**：專案已執行 `openspec init`，產生 `.windsurf/` 目錄（含 workflows 與 skills）。

---

## 核心工具

- **CLI**：`openspec`（用於建立變更、查詢狀態、取得指令）
- **Workflows**：位於 `.windsurf/workflows/opsx-*.md`
- **Skills**：位於 `.windsurf/skills/openspec-*/`

---

## 目錄結構

```
openspec/
├── changes/
│   ├── <change-name>/         ← 活躍的變更
│   │   ├── .openspec.yaml     ← 變更元資料（schema、狀態）
│   │   ├── proposal.md        ← 提案（Why / What / Impact）
│   │   ├── specs/
│   │   │   └── <capability>/
│   │   │       └── spec.md    ← Delta Spec（ADDED/MODIFIED/REMOVED）
│   │   ├── design.md          ← 技術設計決策
│   │   └── tasks.md           ← 實作任務清單（checkbox 格式）
│   └── archive/               ← 已歸檔的變更
│       └── YYYY-MM-DD-<name>/
└── specs/                     ← 主規格（由 /opsx-sync 同步）
    └── <capability>/
        └── spec.md
```

---

## 核心準則

### Artifact 驅動開發

- **開始實作前必須先完成 Artifact 建立**（至少完成 schema 定義的 `applyRequires` artifacts）
- 預設 schema（spec-driven）的 artifact 順序：`proposal → specs → design → tasks`
- 每個變更範圍控制在單一邏輯功能單元
- 變更對應一組有意義的 Conventional Commits

### 開發流程

```
探索想法 → 建立變更 → 生成 Artifacts → 執行實作 → 驗證 → 歸檔
(explore)   (new)      (continue/ff)    (apply)     (verify) (archive)
```

### 完整指令表

| 指令 | 用途 | 時機 |
|------|------|------|
| `/opsx-explore` | 探索模式：思考問題、釐清需求（**禁止寫程式碼**） | 開始前、遇到不確定時 |
| `/opsx-new` | 建立新變更，顯示第一個 artifact 模板 | 開始新功能或修復 |
| `/opsx-ff` | Fast-forward：一次生成所有 Artifacts 至可實作狀態 | 需求明確時快速啟動 |
| `/opsx-continue` | 繼續目前變更，建立**下一個** Artifact（每次一個） | 逐步推進 |
| `/opsx-apply` | 根據 Artifacts 逐一執行任務，完成後標記 `[x]` | 進入實作階段 |
| `/opsx-verify` | 三維度驗證（完整性、正確性、一致性） | 實作完成後 |
| `/opsx-sync` | Agent-driven 智慧合併 Delta Spec 至主規格 | 需要更新主規格時 |
| `/opsx-archive` | 移至 `archive/YYYY-MM-DD-<name>`，可選同步 Spec | 驗證通過後 |
| `/opsx-bulk-archive` | 批次歸檔多個已完成變更 | 整理多個變更時 |
| `/opsx-onboard` | 導覽教學：引導走完一次完整 OPSX 流程 | 首次使用時 |

### 工作紀律

1. **先 Artifact 再實作**：不跳過 Artifact 建立步驟
2. **Explore 只思考**：`/opsx-explore` 模式中禁止寫程式碼，只能讀取、搜尋、討論
3. **先驗證再歸檔**：使用 `/opsx-verify` 確認後再 `/opsx-archive`
4. **範圍控制**：每個變更聚焦於單一邏輯功能單元
5. **原子提交**：變更對應有意義的 Conventional Commits（詳見 `06-git.md`）
6. **流動式工作**：`/opsx-apply` 可在 artifact 部分完成時啟動（若 tasks 已存在）

---

## AI 協作準則

- AI 是**開發夥伴**，主動參與需求釐清、Artifact 生成、程式碼實作
- OPSX workflow 的 Artifacts 由 AI 生成，人工審查確認
- 使用 `/opsx-explore` 與 AI 一起釐清模糊需求（AI 會提問、繪圖、搜尋程式碼）
- 實作階段（`/opsx-apply`）由 AI 逐一執行任務並標記完成，人工驗收結果
- 驗證階段（`/opsx-verify`）產出報告分為 CRITICAL / WARNING / SUGGESTION 三級

---

## 參考

- 完整工作流程說明：`02-workflow.md` → Mode B
- 核心架構原則：`00-core-principles.md`
- Git 規範：`06-git.md`
- [Fission-AI OpenSpec](https://github.com/Fission-AI/OpenSpec)
