---
name: git-commit-helper
description: 根據 git 已暫存（staged）的變更與對話上下文，產生符合 Conventional Commits 規範的提交訊息（commit message），並依使用者語意判斷是要**僅產生訊息供參考**或**直接提交**。當使用者要求「產生 commit message」、「寫 commit」、「幫我 commit」、「commit 一下」、「提交這些變更」、「審視 staged 變更」、提到「git commit」、或在完成一段程式碼變更後準備建立提交時，務必使用本 skill。即使使用者沒有明確說出「Conventional Commits」這個詞，只要涉及產生或提交 commit message，就應啟用本 skill。
model: haiku
effort: high
---

# Git Commit Helper

依據 `git diff --staged` 的輸出與本次對話的上下文，產生**符合 Conventional Commits 規範**（./references/conventional-commits.md）的提交訊息。本 skill 有兩種運行模式，由語意判斷自動選擇。

## 雙模式設計

### 🅐 PREVIEW 模式（預設、安全）

**僅產生訊息**供使用者參考，**不執行** `git commit`。產生 2–3 個版本讓使用者挑選後自行提交。

### 🅑 EXECUTE 模式

**產生訊息並直接執行** `git commit -m "..."`，提交後回報結果（commit hash、變更摘要）。

## 模式判斷規則

**先讀對話、再決定模式。** 判斷時優先看「動詞語意」與「祈使語氣」：

| 使用者輸入語意               | 模式      | 範例                                                            |
| ---------------------------- | --------- | --------------------------------------------------------------- |
| 詢問、檢視、產生「訊息」     | PREVIEW   | 「幫我寫 commit message」「commit 訊息怎麼寫」「看一下 staged」 |
| 直接祈使動詞「commit／提交」 | EXECUTE   | 「幫我 commit」「commit 一下」「提交這些變更」「ship it」       |
| 含「先看一下」「先給我看」   | PREVIEW   | 「先給我看 commit message」「先寫好我自己 commit」              |
| 含「自動」「直接」「順便」   | EXECUTE   | 「直接幫我 commit」「順便 commit 掉」「自動提交」               |
| 模稜兩可、無法判斷           | PREVIEW   | 預設走最安全的選項                                              |

**例外條款**：以下情境**強制走 PREVIEW，忽略 EXECUTE 訊號**：

1. 偵測到敏感資訊（見 §安全檢查）
2. staged 變更橫跨多個不相關邏輯目的（建議拆分而非直接提交）
3. 偵測到 breaking change，且使用者未明確確認
4. 當前 branch 是 `main`、`master`、`release/*` 或被 protected
5. 第一次在此 repo 啟用本 skill（沒有先前 commit 風格可參考時，先讓使用者確認格式）

**判斷結果務必在第一句話顯式宣告**，例如：

- `[模式：PREVIEW] 偵測到 staged 變更涵蓋兩個不相關功能，建議拆分提交……`
- `[模式：EXECUTE] 準備為 3 個檔案的變更建立 commit……`

## 硬性規則（NEVER violate）

- **NEVER** 在沒有先執行 `git status` 與 `git diff --staged` 之前產生 commit message 或執行 commit
- **NEVER** 在沒有 staged 變更時擅自執行 `git add -A`、`git add .`——必須先列出未暫存檔案、詢問使用者
- **NEVER** 在 EXECUTE 模式下跳過敏感資訊掃描
- **NEVER** 用中文撰寫 commit message 本體（subject/body/footer）——一律 **英文**，遵循業界慣例與工具相容性
- **NEVER** 編造未在 diff 中出現的變更——只描述實際看到的內容
- **NEVER** 自動執行 `git push`、`git commit --amend`、`git rebase`、`git reset`、`git stash drop`——除非使用者明確要求
- **NEVER** 在偵測到衝突中的檔案（unmerged paths）時提交

## 工作流程

### 1. 蒐集變更資訊

依序執行：

```bash
git status
git diff --staged --stat   # 檔案層級概覽
git diff --staged          # 完整 diff
git branch --show-current  # 確認當前 branch（影響模式判斷）
```

若 `git diff --staged` 為空：停止流程，列出 `git status` 中未暫存檔案，詢問是否需要 `git add`。**EXECUTE 模式下空 diff 一律降級為說明而非繼續執行。**

### 2. 安全檢查（敏感資訊掃描）

掃描 diff，若發現以下模式，**立刻警告使用者並切換回 PREVIEW**：

- API key、token、密碼（含 `apiKey=`、`password=`、`Bearer`、`sk-`、`ghp_`、`AKIA`、`xoxb-`、`AIza` 等）
- 私鑰（`-----BEGIN ... PRIVATE KEY-----`）
- `.env`、`secrets.*`、`credentials.*`、`*.pem`、`*.key` 等檔案內容變更
- 大量二進位檔案或自動產生的檔案（`dist/`、`build/`、`node_modules/` 等，lock 檔案除外）

警告訊息應建議：`git restore --staged <file>` 或 `git rm --cached <file>` 後重做。

### 3. 分析變更性質

從 diff 與對話上下文判斷：

- **變更類型**（type）：feat / fix / docs / refactor 等
- **影響範圍**（scope）：哪個模組／元件／子系統
- **是否為 breaking change**：API 簽章、回傳格式、設定欄位、CLI 旗標
- **是否原子**（atomic）：邏輯是否單一；若否，建議拆分
- **變更動機**：對話中是否已說明「為什麼」

### 4. 產生 commit message

依下列結構撰寫，**全部使用英文**：

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### Type（必填）

| type       | 使用時機                                              |
| ---------- | ----------------------------------------------------- |
| `feat`     | 新增功能（user-facing 新能力）                        |
| `fix`      | 修復 bug                                              |
| `docs`     | 僅文件變更（README、註解、JSDoc）                     |
| `style`    | 不影響語意的格式變更（空白、分號、formatter）         |
| `refactor` | 既非新功能也非修 bug 的程式碼結構改動                 |
| `perf`     | 效能改善                                              |
| `test`     | 新增或修改測試                                        |
| `build`    | 建置系統或外部依賴（webpack、npm、Cargo、pip）        |
| `ci`       | CI 設定（GitHub Actions、GitLab CI、Jenkinsfile）     |
| `chore`    | 其他不影響 src 或 test 的變更（升級依賴版本號等）     |
| `revert`   | 還原先前的 commit（body 須附 `Refs: <commit-hash>`）  |

#### Subject（標題行）

- **祈使語氣**（imperative mood）：`add`，不是 `added` 或 `adds`
- **首字小寫**、**結尾無句號**
- **最多 72 字元**
- **具體**：避免 `fix bug`、`update code`、`improve stuff`
- 涉及特定模組時加 scope：`feat(auth):`、`fix(api):`

#### Body（選填）

下列情況需要 body：

- 變更動機（why）需要說明，光看 diff 看不出來
- 多個相關變更需要列點
- 涉及取捨（trade-off）或重要決策

撰寫要點：

- 與 subject 之間隔一空行；每行 ≤ 72 字元
- 聚焦 **what + why**，不是 **how**
- 多項變更用 `-` 列點

#### Footer（選填）

- **Breaking change**：

```
  BREAKING CHANGE: <說明破壞性變動的具體內容與遷移方式>
```

  或在 type 後加 `!`，例如 `refactor(api)!:`

- **Issue 連結**：`Closes #123`、`Fixes #456`、`Refs #789`
- **共同作者**：`Co-authored-by: Name <email@example.com>`

### 5. 依模式輸出

#### 🅐 PREVIEW 模式輸出

提供 **2–3 個版本**讓使用者挑：

1. **精簡版**：僅 subject line
2. **詳細版**：subject + body
3. **完整版**：subject + body + footer（有 breaking change 或 issue 關聯時必出）

每個版本用三反引號 code block 包起來，方便直接複製。最後附上提交指令：

```bash
git commit -m "<subject>" -m "<body>"
# 或
git commit   # 在編輯器中貼上
```

#### 🅑 EXECUTE 模式輸出

1. **先預覽**最終的 commit message（單一版本，挑最合適的）
2. **執行驗證自查清單**（見 §自查清單），有任一項未通過 → 降級為 PREVIEW
3. 執行：

```bash
   git commit -m "<subject>" -m "<body>"
```

4. **回報結果**：

```
   ✅ Committed <short-hash> on <branch>
   <subject>
   <N> files changed, <+M>/<-K> lines
```

5. 若 commit 失敗（pre-commit hook 拒絕、簽章失敗等）：完整顯示錯誤輸出，**不重試、不強制略過 hook**（除非使用者明確要求 `--no-verify`）

### 6. 後續動作（兩種模式皆適用）

**主動詢問**是否需要：

- `git push`（注意：上游分支、protected branch 規則）
- 開啟對應的 issue／PR
- 重複此流程處理剩餘未 staged 變更

**不主動執行** push 或建立 PR。

## 範例

### 簡單新功能（PREVIEW）

```
feat: add dark mode toggle to settings
```

### Bug 修復含上下文（EXECUTE 後回報）

訊息：

```
fix(database): prevent connection pool exhaustion

The connection pool was not releasing connections after failed
queries, leading to exhaustion under load. Now explicitly closes
connections in a finally block.

Fixes #234
```

回報：

```
✅ Committed a3f5c21 on feature/db-pool
fix(database): prevent connection pool exhaustion
2 files changed, +18/-4 lines
```

### Breaking change

```
refactor(api)!: change authentication endpoint structure

BREAKING CHANGE: The /auth endpoint now requires a JSON body
instead of URL parameters. Update API clients to use:
POST /auth with {"username": "...", "password": "..."}
```

### 多項相關變更

```
chore: update development dependencies

- Upgrade TypeScript to 5.3
- Update ESLint configuration
- Add Prettier for code formatting
- Remove deprecated testing library
```

## 最佳實踐

1. **Atomic（原子性）**：一個邏輯變更一個 commit；不原子時建議 `git add -p` 拆分
2. **具體**：避免 `fix bug`、`update`、`misc changes`
3. **祈使語氣**：`add feature`，不是 `added feature`
4. **聚焦 what + why**：how 由程式碼本身說明
5. **連結 issue**：有對應的 issue 編號時務必引用
6. **明確標示 breaking change**：用 `!` 或 `BREAKING CHANGE:` footer
7. **Subject ≤ 72 字元**：以利 `git log --oneline` 可讀性
8. **EXECUTE 模式偏謹慎**：任何不確定都降級為 PREVIEW；寧可多問一句，不可錯提交

## 驗證自查清單（送出前必跑）

- [ ] 模式已在第一句話宣告（PREVIEW / EXECUTE）
- [ ] type 從 11 個合法值中擇一
- [ ] subject 為祈使語氣、首字小寫、無句號、≤ 72 字元
- [ ] 若有 breaking change：已加 `!` 或 `BREAKING CHANGE:` footer
- [ ] body 每行 ≤ 72 字元（若有）
- [ ] 沒有編造未出現在 diff 中的變更
- [ ] 沒有把敏感資訊（key/token/password）寫進訊息
- [ ] 全文使用英文撰寫
- [ ] **若為 EXECUTE 模式**：已完成敏感資訊掃描、確認 branch 非 protected、確認 diff 為原子變更
