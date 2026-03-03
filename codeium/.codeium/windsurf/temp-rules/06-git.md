# 06 · Git 工作流程與 Commit 規範

> 良好的 Git 歷史是專案最寶貴的文件之一。
>
> 參考來源：Conventional Commits Specification、Google Engineering Practices、Angular Commit Guidelines

---

## Conventional Commits 格式

### 基本格式

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Type 類型

| Type | 用途 | 範例 |
|------|------|------|
| `feat` | 新功能 | `feat(auth): 新增 JWT refresh token 機制` |
| `fix` | Bug 修復 | `fix(order): 修正訂單金額精度計算錯誤` |
| `refactor` | 重構（無功能變更，無 bug 修復）| `refactor(user): 提取 email 驗證邏輯為獨立函式` |
| `test` | 新增或修正測試 | `test(auth): 新增 token 過期的單元測試` |
| `docs` | 文件更新 | `docs(api): 更新 user endpoint 的 OpenAPI 說明` |
| `chore` | 維護性任務（依賴更新、設定變更）| `chore: 更新 eslint 至 v9` |
| `style` | 純粹格式修改（不影響邏輯）| `style: 統一縮排格式` |
| `perf` | 效能改善 | `perf(query): 為 orders 表的 user_id 加入索引` |
| `ci` | CI/CD 設定變更 | `ci: 新增 Docker build cache 設定` |
| `build` | 建置系統或外部依賴變更 | `build: 升級 Node.js 至 22 LTS` |
| `revert` | 還原先前的 commit | `revert: feat(auth): 新增 JWT refresh token 機制` |

### Scope（影響範圍）

Scope 表示此次變更影響的模組或功能範圍：

```
feat(auth):        ← 認證模組
fix(user):         ← 使用者模組
refactor(order):   ← 訂單模組
chore(deps):       ← 依賴管理
docs(readme):      ← README 文件
```

### Description（描述）規則

- **語言選擇**：依專案性質決定
  - 中文專案 / 個人專案：**正體中文**（技術術語除外）
  - 開源專案 / 國際團隊 / 使用 `/git-commit` 自動生成：**英文**
- **動詞開頭**
  - 中文：新增、修正、移除、更新、重構、改善
  - 英文：add, fix, remove, update, refactor, improve（imperative mood）
- **不超過 72 字元**（含 type 和 scope）
- **不加句點結尾**

```
// ✅ 正確（中文專案）
feat(auth): 新增使用者 Google OAuth 登入功能
fix(payment): 修正台幣金額四捨五入計算錯誤
refactor(user): 提取使用者驗證邏輯至 UserValidator 類別

// ✅ 正確（開源專案 / 自動生成）
feat(auth): add Google OAuth login support
fix(payment): fix TWD amount rounding calculation
refactor(user): extract validation logic to UserValidator

// ❌ 錯誤
feat: 我做了一些更改
fix: fixed a bug.    ← 加了句點、不具體
update stuff         ← 缺少 type
```

---

## Commit Body 與 Footer

### Body（commit 內文）

當變更需要更多解釋時使用，與標題間空一行：

```
fix(auth): 修正 JWT Token 在時區變更時失效問題

Token 到期時間使用了本地時區計算，導致在不同時區的伺服器上
行為不一致。現改為全程使用 UTC 時間，確保跨時區的一致性。

影響範圍：所有使用 JWT 認證的 API 端點
```

### Footer

```
feat(auth): 新增雙因素認證 (2FA) 支援

支援 TOTP（RFC 6238）標準的雙因素認證。

BREAKING CHANGE: POST /auth/login 回應格式新增 requiresMfa 欄位，
前端需更新以處理 MFA 挑戰流程。

Closes #234
Related: #189, #201
```

**常用 Footer 關鍵字**:
- `BREAKING CHANGE:` — 重大不相容變更（觸發 MAJOR 版本升級）
- `Closes #N` — 關閉 GitHub Issue
- `Related: #N` — 相關 Issue
- `Co-authored-by: Name <email>` — 共同作者

---

## Commit 紀律

### 原子性提交（Atomic Commits）

**一個 commit 只做一件事**：

```
// ✅ 原子性 commit
commit A: test(user): 新增 createUser 的邊界條件測試
commit B: feat(user): 實作 createUser 方法
commit C: refactor(user): 提取 email 驗證為獨立函式

// ❌ 混合多件事
commit: 新增功能、修 bug、更新文件、改格式
```

### 提交前檢查

**禁止提交的內容**:
- [ ] 硬編碼的密鑰、密碼、Token
- [ ] 已註解掉的程式碼區塊
- [ ] `console.log()` 的除錯輸出（生產程式碼）
- [ ] 未解決的 `<<<<<<< HEAD` 合併衝突標記
- [ ] 失敗的測試
- [ ] Linting 錯誤

**建議使用 pre-commit hook**:
```bash
# .husky/pre-commit
npm run lint
npm run test:unit
```

---

## 分支策略

### 分支命名

```
main                                   ← 生產環境
develop                                ← 整合分支

feature/{issue-id}-{kebab-description} ← 功能開發
fix/{issue-id}-{kebab-description}     ← Bug 修復
hotfix/{issue-id}-{kebab-description}  ← 緊急修復
chore/{kebab-description}              ← 維護任務
release/v{major}.{minor}.{patch}       ← 版本發布準備
```

**範例**:
```
feature/JIRA-123-user-oauth-login
fix/JIRA-456-order-total-calculation
hotfix/JIRA-789-security-token-leak
chore/upgrade-nodejs-22
release/v2.1.0
```

### 分支生命週期

```
1. 從 develop 建立功能分支
   git checkout -b feature/JIRA-123-description develop

2. 開發過程中定期 rebase（保持線性歷史）
   git fetch origin
   git rebase origin/develop

3. 完成後開啟 Pull Request → develop

4. 合併後刪除功能分支
   git branch -d feature/JIRA-123-description
```

---

## 合併策略

| 合併方向 | 策略 | 理由 |
|---------|------|------|
| `feature → develop` | **Squash and Merge** | 保持 develop 歷史整潔 |
| `develop → main` | **Merge Commit** | 保留完整版本歷史 |
| `hotfix → main` | **Merge Commit** | 緊急修復需保留蹤跡 |
| `main → hotfix` | **Cherry-pick** | 僅同步特定修復 |

**禁止**:
- `git push --force` 到 `main` 或 `develop`（使用 `--force-with-lease`）
- 直接 push 到 `main`（必須透過 PR）

---

## Rebase vs Merge

**使用 Rebase 的情境**:
- 在功能分支上同步最新的 develop 變更（`git rebase origin/develop`）
- 整理功能分支的 commit 歷史（interactive rebase）

**使用 Merge 的情境**:
- 功能完成後合併回 develop / main
- 需要保留合併記錄的場景

**Interactive Rebase 整理 commit**:
```bash
# 整理最近 3 個 commit
git rebase -i HEAD~3

# 操作選項
pick   ← 保留
squash ← 合併到前一個 commit
reword ← 修改 commit 訊息
drop   ← 刪除此 commit
```

---

## 版本標籤（Tags）

遵循 Semantic Versioning（`v{MAJOR}.{MINOR}.{PATCH}`）：

| 版本號 | 觸發條件 |
|--------|---------|
| MAJOR | `BREAKING CHANGE` footer，或 API 不相容變更 |
| MINOR | `feat` type commit |
| PATCH | `fix` type commit |

```bash
# 建立版本標籤
git tag -a v1.2.0 -m "release: v1.2.0 - 新增 OAuth 登入與雙因素認證"
git push origin v1.2.0

# 查看版本歷史
git tag -l --sort=-version:refname | head -10
```

---

## `.gitignore` 最佳實踐

**必須加入 `.gitignore` 的項目**:
```
# 環境設定（絕對禁止提交含密鑰的 env 檔案）
.env
.env.local
.env.production
.env.staging

# 依賴
node_modules/
vendor/
__pycache__/
*.pyc

# 建置產出
dist/
build/
.next/

# IDE 設定（個人偏好）
.vscode/settings.json
.idea/

# 系統檔案
.DS_Store
Thumbs.db

# 日誌
*.log
logs/
```

**應該提交的**:
```
.env.example        ← 列出所有必要的 env key（值為佔位符）
.vscode/extensions.json  ← 推薦的 VS Code 擴充套件（團隊共用）
```

---

## AI 輔助 Commit Message 生成

透過以下工具自動分析 staged changes 並生成 Conventional Commits 格式的 commit message（生成結果為英文）：

**Windsurf Workflow**：輸入 `/git-commit` 啟動，定義於 `global_workflows/git-commit.md`

**Skill**：`git-commit-generator`，AI 會分析目前 staged changes 與對話上下文，提供 2–3 種 commit message 選項

**使用流程**：
```bash
# 1. 暂存變更
git add <files>

# 2. 輸入指令以 AI 生成 commit message
# Windsurf: /git-commit
# 或呼叫 git-commit-generator skill

# 3. 選擇合適的 message 後執行
git commit -m "<選擇的 message>"
```

> **注意**：自動生成的 commit message 為英文；若專案想要中文 commit，不要使用 AI 自動生成，手動撰寫即可。

---

## Git Hooks 設定

### 使用 Husky + lint-staged

```json
// package.json
{
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": ["eslint --fix", "prettier --write"],
    "*.{css,scss,json,md}": ["prettier --write"]
  }
}
```

```bash
# .husky/pre-commit（提交前自動 lint）
npx lint-staged

# .husky/commit-msg（驗證 commit 訊息格式）
npx --no -- commitlint --edit $1
```
