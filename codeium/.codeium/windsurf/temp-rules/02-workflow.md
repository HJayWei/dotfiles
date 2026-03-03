# 02 · 開發工作流程（補充規則）

> **本文件為 `global_rules.md` 的詳細補充**。模式選擇與通用準則摘要已提取至全域規則，此處提供 Vibe Coding 詳細流程、分支策略、PR 規範、Code Review 等完整內容。
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

> 基於 [GitHub Spec-Kit](https://github.com/github/spec-kit) 的 SDD 方法論。規格是第一公民，程式碼是其表達式。
> 完整指令、目錄結構、工作紀律請參閱 **`specify-rules.md`**。

**核心流程**：`specify → plan → tasks → implement → analyze`

**選用此模式時**：有正式需求規格、多人協作、需求追溯性要求高。

---

## Mode B：OpenSpec（OPSX）

> 基於 [Fission-AI OpenSpec](https://github.com/Fission-AI/OpenSpec) 的 Artifact 驅動方法論。AI 輔助、快速迭代、結構化且靈活。
> 完整指令、目錄結構、工作紀律請參閱 **`opsx-rules.md`**。

**核心流程**：`explore → new → continue/ff → apply → verify → archive`

**選用此模式時**：AI 驅動迭代、中小型功能、需要靈活的結構化流程。

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
