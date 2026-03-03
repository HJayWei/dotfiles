# 通用開發準則 (Universal Development Rules)

> 整合自 spec-driven.md、企業工程憲章、及 Claude / Google / Meta / OpenAI / Cursor / Windsurf 資深工程師的最佳實踐。
>
> **版本**: 1.0.0 | **建立**: 2026-02-27 | **語言**: 正體中文（技術術語除外）

---

## 目錄結構

```
temp-rules/
├── README.md                  ← 本檔案：目錄總覽
├── 00-core-principles.md      ← 核心架構原則（Clean Architecture、SOLID、SDD）
├── 01-code-style.md           ← 通用程式碼風格與格式規範
├── 02-workflow.md             ← 開發工作流程（Spec-Driven Development）
├── 03-ai-tools.md             ← AI 工具使用準則（Cascade / Cursor / Windsurf）
├── 04-testing.md              ← 測試策略與品質準則
├── 05-security.md             ← 安全性編碼準則
├── 06-git.md                  ← Git 工作流程與 Commit 規範
├── languages/
│   ├── typescript.md          ← TypeScript / JavaScript 特定準則
│   ├── python.md              ← Python 特定準則
│   ├── php.md                 ← PHP (Laravel) 特定準則
│   └── sql.md                 ← SQL / 資料庫查詢準則
└── tools/
    ├── docker.md              ← Docker / 容器化準則
    └── linting.md             ← Linting & Formatting 工具設定準則
```

---

## 優先級層次

```
使用者即時指示  >  本規則集  >  框架預設慣例  >  語言標準
```

當規則間產生衝突時，遵循上方優先級。所有規則均允許在有充分技術理由時例外，但必須在 `plan.md` 的 Complexity Tracking 中文件化。

---

## 設計哲學

本規則集基於四大核心哲學，源自 GitHub Spec-Kit 的 Constitutional Foundation：

| 哲學 | 意涵 |
|------|------|
| **Observability over Opacity** | 一切必須可被觀察與驗證；透過 CLI 介面暴露功能 |
| **Simplicity over Cleverness** | 先求簡單，僅在證明有必要時才增加複雜度 |
| **Integration over Isolation** | 在真實環境中測試，而非人工隔離環境 |
| **Modularity over Monoliths** | 每個功能都是具備清晰邊界的模組 |

---

## 快速參考

### 必須遵循（Non-Negotiable）

- [ ] SOLID 原則 — 詳見 `00-core-principles.md`
- [ ] 測試先行（Test-First）— 詳見 `04-testing.md`
- [ ] 函式不超過 50 行，檔案不超過 500 行 — 詳見 `01-code-style.md`
- [ ] 所有敏感資訊使用環境變數 — 詳見 `05-security.md`
- [ ] Conventional Commits 格式 — 詳見 `06-git.md`

### Code Review 快速清單

- [ ] 遵循 SOLID 原則？
- [ ] 是否符合 MVP 範圍（無過度設計）？
- [ ] 有適當測試覆蓋？
- [ ] 命名清晰、無魔法數字？
- [ ] 錯誤處理完善？
- [ ] 無硬編碼的敏感資訊？
- [ ] Linting 全部通過？

---

## 參考來源

- [GitHub Spec-Kit: Spec-Driven Development](https://github.com/github/spec-kit/blob/main/spec-driven.md)
- [Google Engineering Practices](https://google.github.io/eng-practices/)
- [Meta Engineering Blog](https://engineering.fb.com/)
- [OpenAI Prompt Engineering Guide](https://platform.openai.com/docs/guides/prompt-engineering)
- [Anthropic Model Spec](https://www.anthropic.com/news/claude-s-constitution)
- [Cursor Rules Community](https://cursor.directory/)
- [Windsurf Documentation](https://docs.codeium.com/windsurf)
