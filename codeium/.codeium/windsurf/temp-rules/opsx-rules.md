# OpenSpec (OPSX) 工作流程規則（Mode B）

> 此規則檔適用於使用 Fission-AI OpenSpec 進行 AI 輔助開發的專案。
> 複製至專案的 `.windsurf/rules/opsx-rules.md` 即可啟用。

---

## 啟用條件

當專案採用 OpenSpec (OPSX) 工作流程時套用此規則。

---

## 核心準則

### Artifact 驅動開發

- **開始實作前必須先完成 Artifact 建立**（至少有 Delta Spec 與任務清單）
- 每個變更範圍控制在單一邏輯功能單元
- 變更對應一組有意義的 Conventional Commits

### 開發流程

```
探索想法 → 建立變更 → 生成 Artifacts → 執行實作 → 驗證 → 歸檔
```

### 常用指令

| 指令 | 用途 | 時機 |
|------|------|------|
| `/opsx-explore` | 探索模式：思考問題、釐清需求 | 開始前、遇到不確定時 |
| `/opsx-new` | 建立新變更，逐步引導建立 Artifacts | 開始新功能或修復 |
| `/opsx-ff` | Fast-forward：一次生成所有 Artifacts | 需求明確時快速啟動 |
| `/opsx-continue` | 繼續目前變更，建立下一個 Artifact | 逐步推進 |
| `/opsx-apply` | 根據 Artifacts 執行實作任務 | 進入實作階段 |
| `/opsx-verify` | 驗證實作是否符合 Artifacts 定義 | 實作完成後 |
| `/opsx-sync` | 同步 Delta Spec 至主規格 | 需要更新主規格時 |
| `/opsx-archive` | 歸檔已完成的變更 | 驗證通過後 |

### 工作紀律

1. **先 Artifact 再實作**：不跳過 Artifact 建立步驟
2. **先驗證再歸檔**：使用 `/opsx-verify` 確認後再 `/opsx-archive`
3. **範圍控制**：每個變更聚焦於單一邏輯功能單元
4. **原子提交**：變更對應有意義的 Conventional Commits（詳見 `06-git.md`）

---

## AI 協作準則

- AI 是**開發夥伴**，主動參與需求釐清、Artifact 生成、程式碼實作
- OPSX workflow 的 Artifacts 由 AI 生成，人工審查確認
- 使用 `/opsx-explore` 與 AI 一起釐清模糊需求
- 實作階段（`/opsx-apply`）由 AI 執行，人工驗收結果

---

## 參考

- 完整工作流程說明：`02-workflow.md` → Mode B
- 核心架構原則：`00-core-principles.md`
- Git 規範：`06-git.md`
