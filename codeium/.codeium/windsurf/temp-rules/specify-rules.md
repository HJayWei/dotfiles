# Spec-Kit (SDD) 工作流程規則（Mode A）

> 此規則檔適用於使用 GitHub Spec-Kit 進行 Specification-Driven Development 的專案。
> 複製至專案的 `.windsurf/rules/specify-rules.md` 即可啟用。

---

## 啟用條件

當專案採用 Spec-Kit (SDD) 工作流程時套用此規則。

---

## 核心準則

### 規格優先

- **規格（Specification）是第一公民**，程式碼是其表達式
- 所有功能開發必須先經過規格化流程，再進入實作
- 需求變更透過規格重新生成處理，而非手動修改程式碼

### 五階段流程（嚴格遵循）

1. **需求規格** (`/speckit.specify`) → 輸出 `specs/{feature}/spec.md`
2. **實作規劃** (`/speckit.plan`) → 輸出 `specs/{feature}/plan.md`
3. **任務拆解** (`/speckit.tasks`) → 輸出 `specs/{feature}/tasks.md`
4. **實作** (`/speckit.implement`) → 按任務順序實作
5. **品質驗證** (`/speckit.analyze`) → 跨文件一致性檢查

### 實作紀律

- P1 完成並驗證後，才能進行 P2
- 每個任務完成後立即進行 Code Review
- 測試先行（Red → Green → Refactor）
- 小幅度、漸進式提交（每個 commit 只做一件事）

### Constitution Check（每次 Plan 必須通過）

- [ ] 初始實作使用 ≤ 3 個模組？（Article VII 簡潔性閘門）
- [ ] 無「未來可能需要」的抽象？（Article VIII 反過度抽象）
- [ ] 契約已定義且契約測試已撰寫？（Article IX 整合優先）

---

## AI 協作準則

- AI 是**架構夥伴**，協助規格撰寫、計畫審查、程式碼生成
- 所有 AI 生成的內容必須經過人工審查
- 規格文件由人主導撰寫，AI 輔助完善
- 實作程式碼由 AI 生成後，人工驗證正確性

---

## 參考

- 完整工作流程說明：`02-workflow.md` → Mode A
- 核心架構原則：`00-core-principles.md`
