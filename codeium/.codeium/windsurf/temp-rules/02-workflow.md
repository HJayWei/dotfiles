# 02 · 開發工作流程（可選模式）

> 支援三種工作流程模式，依專案性質與開發階段選擇適合的方式。所有模式均遵循通用準則（分支策略、PR 規範、Code Review）。
>
> 參考來源：GitHub Spec-Kit、Fission-AI OpenSpec、Google Engineering Practices、Agile/Scrum Best Practices

---

## 工作流程模式選擇

| 模式 | 適用場景 | 主要工具 |
|------|---------|----------|
| **[A] Spec-Kit (SDD)** | 正式專案、需求明確、團隊協作 | [GitHub Spec-Kit](https://github.com/github/spec-kit) |
| **[B] OpenSpec (OPSX)** | AI 輔助驅動、快速迭代、結構化且靈活 | [Fission-AI OpenSpec](https://github.com/Fission-AI/OpenSpec) |
| **[C] Vibe Coding** | 探索性開發、個人原型、快速驗證想法 | 無特定工具 |

**選擇指引**：
- 有正式需求規格、多人協作 → Mode A
- 使用 Windsurf OPSX workflow、AI 驅動迭代 → Mode B
- 快速原型、個人探索、POC → Mode C
- 所有模式均遵循下方「通用準則」（分支策略、PR、Code Review）

---

## Mode A：Spec-Kit（Specification-Driven Development）

> 基於 GitHub Spec-Kit 的 SDD 方法論，規格是第一公民，程式碼是其表達式。

### SDD 核心思想

**規格（Specification）是第一公民，程式碼是其表達式。**

```
傳統開發：想法 → 直接寫程式 → 問題出現 → 修正
SDD 開發：想法 → 規格化 → 計畫 → 任務 → 實作 → 驗證
```

**關鍵優勢**:
- 需求變更成為「系統性重新生成」，而非手動重寫
- AI 輔助開發在規格清晰時效果最佳
- 規格即文件，降低知識孤島風險

---

### 五階段開發流程

#### Phase 1 · 需求規格（`/speckit.specify`）

**輸出物**: `specs/{feature-name}/spec.md`

**必做事項**:
- [ ] 撰寫清晰的功能描述（使用者視角）
- [ ] 定義 User Stories，標記優先級（P1 / P2 / P3）
- [ ] 撰寫可測試的 Acceptance Scenarios（Given / When / Then）
- [ ] 識別核心實體與資料模型
- [ ] 列出非功能性需求（效能、安全性、可用性）
- [ ] 識別外部依賴與邊界

**User Story 格式**:
```
作為 [使用者角色]，
我想要 [功能描述]，
以便 [業務價值]。

驗收條件：
- Given [前置條件] When [操作] Then [預期結果]
```

**優先級定義**:
| 優先級 | 定義 | 範例 |
|--------|------|------|
| P1 | 核心 MVP 功能，沒有它產品無法運作 | 使用者登入、資料讀寫 |
| P2 | 重要功能，顯著提升使用者體驗 | 搜尋過濾、通知功能 |
| P3 | 加分功能，可延後實作 | 匯出報表、進階統計 |

---

#### Phase 2 · 實作規劃（`/speckit.plan`）

**輸出物**: `specs/{feature-name}/plan.md`

**必做事項**:
- [ ] 確認技術選型與專案結構
- [ ] **執行 Constitution Check**（通過 Article VII 簡潔性閘門）
- [ ] 設計資料模型與 API 契約（API-first）
- [ ] 識別風險與技術挑戰
- [ ] 記錄 Complexity Tracking（若有原則妥協）

**Constitution Check 清單**:
```markdown
#### Simplicity Gate (Article VII)
- [ ] 初始實作使用 ≤ 3 個模組？
- [ ] 無「未來可能需要」的抽象？
- [ ] 每個抽象層都有明確理由？

#### Anti-Abstraction Gate (Article VIII)
- [ ] 直接使用框架功能，無不必要包裝？
- [ ] 單一資料模型表示（無重複 DTO）？

#### Integration-First Gate (Article IX)
- [ ] 契約已定義？
- [ ] 契約測試已撰寫？
```

---

#### Phase 3 · 任務拆解（`/speckit.tasks`）

**輸出物**: `specs/{feature-name}/tasks.md`

**任務格式**:
```markdown
## Task {N}: {任務名稱}
- **Story**: P{1|2|3} - {User Story 標題}
- **估計**: {小時}h
- **依賴**: Task {M}, Task {K}  （或「無」）
- **並行標記**: [P] 可與 Task {X} 並行執行

### 實作步驟
1. ...
2. ...

### 完成標準
- [ ] 測試覆蓋率達標
- [ ] Linting 全部通過
- [ ] Code Review 完成
```

**任務排序原則**:
```
Setup → Infrastructure → Domain Layer → Service Layer → API Layer → Frontend → E2E Tests
```

**並行任務識別**:
- 無相互依賴的任務可標記 `[P]` 並行執行
- 並行任務不得共享可變狀態

---

#### Phase 4 · 實作（`/speckit.implement`）

**實作紀律**:
1. 嚴格按任務順序：P1 完成並驗證後，才能進行 P2
2. 每個任務完成後立即進行 Code Review
3. 測試先行（Red → Green → Refactor）
4. 小幅度、漸進式提交（每個 commit 只做一件事）

**每日工作流程**:
```
1. 拉取最新程式碼 (git pull --rebase)
2. 確認今日任務（from tasks.md）
3. 建立功能分支（feature/{task-id}-{description}）
4. 撰寫測試（Red 狀態）
5. 實作程式碼（Green 狀態）
6. 重構（Refactor）
7. 提交（Conventional Commits 格式）
8. 開啟 Pull Request
```

---

#### Phase 5 · 品質驗證（`/speckit.analyze`）

**執行跨文件一致性檢查**:
- [ ] `spec.md` 的需求是否全部在 `tasks.md` 中有對應任務？
- [ ] `plan.md` 的 API 契約是否與實際實作一致？
- [ ] Constitution Check 是否全部通過？
- [ ] 測試覆蓋率是否達標？
- [ ] 所有 Acceptance Scenarios 是否通過？

---

## Mode B：OpenSpec（OPSX）

> 適用工具：[Fission-AI OpenSpec](https://github.com/Fission-AI/OpenSpec)，透過結構化 Artifact 引導 AI 輔助開發，比 Spec-Kit 更輕量、更彈性。

### OPSX 開發流程

```
探索想法 → 建立變更 → 生成 Artifacts → 執行實作 → 驗證 → 歸檔
```

### 常用指令

| 指令 | 用途 |
|------|------|
| `/opsx-explore` | 探索模式：思考問題、釐清需求（開始前使用）|
| `/opsx-new` | 建立新變更，逐步引導建立所有 Artifacts |
| `/opsx-ff` | Fast-forward：一次生成所有 Artifacts（快速啟動）|
| `/opsx-continue` | 繼續目前變更，建立下一個 Artifact |
| `/opsx-apply` | 根據 Artifacts 執行實作任務 |
| `/opsx-verify` | 驗證實作是否符合 Artifacts 定義 |
| `/opsx-sync` | 同步 Delta Spec 至主規格 |
| `/opsx-archive` | 歸檔已完成的變更 |

### OPSX 工作紀律

1. 開始實作前必須先完成 Artifact 建立（至少有 Delta Spec 與任務清單）
2. 使用 `/opsx-verify` 確認後再執行 `/opsx-archive`
3. 每個變更範圍控制在單一邏輯功能單元
4. 變更對應一組有意義的 Conventional Commits

---

## Mode C：Vibe Coding（探索式開發）

> 適用場景：個人專案原型、技術探索、快速 POC、學習性實作。快速移動，但保持最低限度的紀律。

### 精簡工作流程

```
想法 → 直接實作 → 驗證可行性 → （若需轉正式）補寫規格
```

### 最低要求（即使 Vibe Coding 也不可省略）

- [ ] 使用 Conventional Commits 格式提交（詳見 `06-git.md`）
- [ ] 不提交含有敏感資訊的程式碼（API Key、密碼等）
- [ ] 基本的錯誤處理，避免靜默失敗
- [ ] 若確定轉為正式專案，補寫 `spec.md` 並切換至 Mode A 或 B

### 升級路徑

| 階段 | 動作 |
|------|------|
| POC 成功，要轉正式專案 | 補寫 spec.md，切換至 Mode A 或 B |
| 探索中，需要他人協作 | 整理程式結構，補充基本文件 |
| 純個人使用，不轉正式 | 維持 Vibe Coding 即可 |

---

## 通用準則（所有模式適用）

### 分支策略（Git Flow 簡化版）

```
main          ← 生產環境，隨時可部署
  └── develop ← 整合分支，功能完成後合併
        └── feature/{id}-{description}   ← 功能開發
        └── fix/{id}-{description}        ← Bug 修復
        └── chore/{description}           ← 維護性任務
```

**分支命名規則**:
```
feature/JIRA-123-user-authentication
fix/JIRA-456-null-pointer-exception
chore/update-dependencies
```

**合併策略**:
- `feature → develop`: Squash and Merge（保持 develop 歷史整潔）
- `develop → main`: Merge Commit（保留完整歷史）
- `hotfix → main`: Cherry-pick + 同步 develop

---

### Pull Request 規範

### PR 標題格式

遵循 Conventional Commits 格式（詳見 `06-git.md`）：
```
feat(auth): 新增 JWT 重新整理 Token 機制
fix(order): 修正訂單金額計算精度問題
```

### PR 描述模板

```markdown
## 變更摘要
<!-- 一段話描述此 PR 做了什麼 -->

## 相關 Issue / Task
- Closes #123
- Task: specs/{feature}/tasks.md#Task-5

## 變更類型
- [ ] feat: 新功能
- [ ] fix: Bug 修復
- [ ] refactor: 重構（無功能變更）
- [ ] chore: 維護性任務
- [ ] docs: 文件更新

## 測試
- [ ] 已新增 / 更新單元測試
- [ ] 已新增 / 更新整合測試
- [ ] 本地測試通過

## Constitution Check
- [ ] 符合 SOLID 原則
- [ ] 符合 MVP 範圍
- [ ] 通過簡潔性閘門
- [ ] 無硬編碼敏感資訊
```

### PR 大小限制

| 類型 | 建議行數 | 若超過 |
|------|---------|--------|
| 一般功能 | ≤ 400 行變更 | 拆分為多個 PR |
| 重構 | ≤ 600 行變更 | 分批進行 |
| 初始設定 | ≤ 1000 行變更 | 可接受，需說明 |

---

### Code Review 準則

#### Reviewer 職責

**必須檢查**:
- [ ] 邏輯正確性（業務邏輯是否符合需求）
- [ ] 安全性問題（SQL injection、XSS、敏感資訊洩漏）
- [ ] 效能問題（N+1 查詢、記憶體洩漏）
- [ ] SOLID 原則遵循
- [ ] 測試完整性

**不應該**: 強制個人風格偏好（已由 Linting 工具處理）

#### 意見格式

使用標準前綴讓意見意圖清晰：
```
// 必須修改才能合併
[blocking] 此處有 SQL Injection 風險，請使用參數化查詢

// 建議改善但不強制
[suggestion] 可考慮將此邏輯提取為獨立函式，提升可讀性

// 純粹問題，不需修改
[question] 這裡使用 Redis 而非 in-memory 的原因？

// 讚美好的程式碼
[praise] 這個錯誤處理設計非常清晰！
```

#### 回應時限

| 優先級 | 首次回應 | 完成 Review |
|--------|---------|------------|
| Hotfix | 1 小時內 | 2 小時內 |
| P1 功能 | 4 小時內 | 24 小時內 |
| P2/P3 功能 | 24 小時內 | 48 小時內 |

---

### 環境管理

```
本地開發 (local) → 整合測試 (staging) → 生產環境 (production)
```

**環境變數管理**:
- 使用 `.env.{environment}` 分環境設定
- **禁止**將含有真實密鑰的 `.env` 提交到 Git
- 使用 `.env.example` 列出所有必要變數（值為佔位符）
- 生產環境使用 Vault / Kubernetes Secrets / 雲端金鑰管理服務

**部署前檢查清單**:
- [ ] 所有測試通過
- [ ] Linting 無錯誤
- [ ] 環境變數已正確設定
- [ ] 資料庫 Migration 已執行
- [ ] 回滾計畫已準備
