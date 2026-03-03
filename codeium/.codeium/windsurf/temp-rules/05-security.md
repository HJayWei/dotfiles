# 05 · 安全性編碼準則（補充規則）

> **本文件為 `global_rules.md` 的詳細補充**。安全性核心要點摘要已提取至全域規則，此處提供 OWASP Top 10 完整範例與實踐準則。
>
> 參考來源：OWASP Top 10、Google Security Engineering、Meta Security Best Practices、CWE/SANS Top 25

---

## OWASP Top 10 防護要點

### 1. Broken Access Control（存取控制缺陷）

```typescript
// ❌ 僅依賴前端隱藏
router.get('/admin/users', (req, res) => {
  return res.json(await userRepo.findAll());  // 無後端授權檢查
});

// ✅ 後端強制授權檢查
router.get('/admin/users', authenticate, authorize('admin'), async (req, res) => {
  return res.json(await userRepo.findAll());
});

// ✅ 物件層級授權（IDOR 防護）
router.get('/orders/:id', authenticate, async (req, res) => {
  const order = await orderRepo.findById(req.params.id);
  if (order.userId !== req.user.id) {
    throw new ForbiddenError('無權限存取此訂單');
  }
  return res.json(order);
});
```

**規則**:
- 預設拒絕（Deny by default）：白名單授權，而非黑名單
- 伺服器端強制所有存取控制檢查
- 物件層級授權必須驗證所有者關係

### 2. Cryptographic Failures（加密缺陷）

```typescript
// ❌ 明文儲存密碼
user.password = req.body.password;

// ❌ 使用弱雜湊
user.password = md5(req.body.password);

// ✅ 使用 bcrypt（cost factor ≥ 12）
import bcrypt from 'bcrypt';
user.password = await bcrypt.hash(req.body.password, 12);

// ✅ 驗證密碼
const isValid = await bcrypt.compare(inputPassword, user.password);
```

**規則**:
- 禁止儲存明文密碼
- 禁止使用 MD5、SHA1 作為密碼雜湊
- 使用 bcrypt / Argon2 / scrypt 進行密碼雜湊
- 靜態資料（at rest）使用 AES-256 加密
- 傳輸資料（in transit）強制使用 TLS 1.2+

### 3. Injection（注入攻擊）

```typescript
// ❌ SQL Injection 漏洞
const users = await db.query(`SELECT * FROM users WHERE email = '${email}'`);

// ✅ 參數化查詢
const users = await db.query('SELECT * FROM users WHERE email = $1', [email]);

// ✅ 使用 ORM（自動參數化）
const user = await User.where({ email }).first();
```

```typescript
// ❌ XSS 漏洞（直接插入 HTML）
element.innerHTML = userInput;

// ✅ 使用文字節點或安全的序列化
element.textContent = userInput;
// 或使用 DOMPurify 清理 HTML
element.innerHTML = DOMPurify.sanitize(userInput);
```

**規則**:
- 所有資料庫查詢必須使用參數化查詢或 ORM
- 永不使用字串拼接建構 SQL / NoSQL 查詢
- 輸出至 HTML 前必須進行 HTML 轉義
- 避免使用 `eval()`、`innerHTML`（或確保已清理）

### 4. Insecure Design（不安全設計）

**規則**:
- 敏感操作必須進行速率限制（Rate Limiting）
- 重要操作使用雙重確認（idempotency key）
- 使用威脅建模（Threat Modeling）評估設計

### 5. Security Misconfiguration（安全配置錯誤）

```bash
# ❌ 在生產環境啟用 debug 模式
APP_DEBUG=true  # .env.production

# ✅ 生產環境關閉 debug
APP_DEBUG=false
APP_ENV=production
```

**規則**:
- 生產環境關閉 debug 模式
- 移除預設帳號和範例應用
- 設定安全的 HTTP Headers（CSP、HSTS、X-Frame-Options）
- 最小化暴露的服務端口

### 6. Vulnerable and Outdated Components（易受攻擊的元件）

```bash
# 定期執行依賴漏洞掃描
npm audit
pip-audit
composer audit
```

**規則**:
- 訂閱安全公告（GitHub Dependabot、Snyk）
- 高危漏洞 24 小時內修補
- 中危漏洞 7 天內修補
- 依賴版本鎖定（package-lock.json / requirements.txt）

### 7. Identification and Authentication Failures（認證缺陷）

```typescript
// ✅ JWT 最佳實踐
const token = jwt.sign(
  { userId: user.id, role: user.role },
  process.env.JWT_SECRET,       // 從環境變數讀取
  {
    expiresIn: '15m',           // 短暫的 access token
    issuer: 'myapp.com',
    audience: 'myapp.com',
  }
);

// ✅ 登入失敗的速率限制
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,    // 15 分鐘
  max: 5,                       // 最多 5 次嘗試
  message: '登入嘗試次數過多，請稍後再試',
});
```

**規則**:
- Access Token 有效期 ≤ 15 分鐘
- Refresh Token 使用 Rotation 機制（使用後廢棄）
- 登入失敗實作速率限制
- 敏感操作強制重新認證
- 啟用多因素認證（MFA）選項

### 8. Software and Data Integrity Failures（軟體和資料完整性缺陷）

**規則**:
- 驗證所有反序列化的資料
- CI/CD Pipeline 使用簽署的 artifacts
- 第三方函式庫驗證 hash / 簽章

### 9. Security Logging and Monitoring Failures（安全記錄缺陷）

```typescript
// ✅ 記錄安全相關事件
logger.warn('登入失敗', {
  email: req.body.email,        // 不記錄密碼
  ip: req.ip,
  userAgent: req.headers['user-agent'],
  timestamp: new Date().toISOString(),
});

logger.info('使用者登入', {
  userId: user.id,
  ip: req.ip,
  timestamp: new Date().toISOString(),
});
```

**必須記錄的事件**:
- 認證成功 / 失敗
- 授權失敗（403）
- 輸入驗證失敗
- 敏感資料存取
- 管理員操作
- 系統錯誤（5xx）

**禁止記錄**:
- 密碼、密鑰、Token
- 完整信用卡號（PAN）
- 個人敏感資訊（依 GDPR / 個資法）

### 10. SSRF（伺服器端請求偽造）

```typescript
// ❌ SSRF 漏洞
const response = await fetch(req.body.url);  // 使用者控制 URL

// ✅ 白名單驗證
const ALLOWED_DOMAINS = ['api.example.com', 'cdn.example.com'];
const url = new URL(req.body.url);
if (!ALLOWED_DOMAINS.includes(url.hostname)) {
  throw new ValidationError('不允許的目標網域');
}
```

---

## 敏感資訊管理

### 環境變數規則

```bash
# ❌ 硬編碼密鑰（絕對禁止）
const SECRET_KEY = 'my-super-secret-key-12345';
DATABASE_URL = 'postgres://admin:password123@prod-db:5432/mydb';

# ✅ 從環境變數讀取
const SECRET_KEY = process.env.SECRET_KEY;
if (!SECRET_KEY) throw new Error('SECRET_KEY 環境變數未設定');
```

### `.env` 檔案管理

```
.env                 ← 禁止提交（加入 .gitignore）
.env.local           ← 禁止提交（個人本地設定）
.env.example         ← 必須提交（包含所有 KEY，值為佔位符）
.env.test            ← 可提交（僅含測試用的非敏感值）
```

### 機密管理層級

| 環境 | 建議工具 |
|------|---------|
| 本地開發 | `.env.local`（不提交）|
| 測試/Staging | Kubernetes Secrets / Docker Secrets |
| 生產環境 | HashiCorp Vault / AWS Secrets Manager / GCP Secret Manager |

---

## HTTP 安全 Headers

```typescript
// 使用 helmet.js（Express）
import helmet from 'helmet';
app.use(helmet());

// 或手動設定
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  res.setHeader('Content-Security-Policy', "default-src 'self'");
  next();
});
```

---

## 輸入驗證

**原則：永遠不信任輸入**

```typescript
// ✅ 使用 zod 進行嚴格型別驗證
import { z } from 'zod';

const CreateUserSchema = z.object({
  name: z.string().min(1).max(100).trim(),
  email: z.string().email().toLowerCase(),
  age: z.number().int().min(0).max(150),
});

async function createUser(input: unknown): Promise<User> {
  const validated = CreateUserSchema.parse(input);  // 失敗會拋出 ZodError
  return userRepo.save(validated);
}
```

**驗證層級**:
1. **格式驗證**：型別、長度、格式（正規表達式）
2. **業務驗證**：值域範圍、業務規則
3. **跨欄位驗證**：欄位間的相互依賴關係

---

## 安全 Code Review 清單

- [ ] 所有資料庫查詢是否使用參數化查詢？
- [ ] 是否有任何硬編碼的密鑰或密碼？
- [ ] 輸出至前端的資料是否已進行 HTML 轉義？
- [ ] 是否對所有 API 端點實施了適當的授權檢查？
- [ ] 敏感操作是否有速率限制？
- [ ] 錯誤訊息是否洩漏了過多的系統內部資訊？
- [ ] 日誌是否記錄了敏感資訊？
- [ ] 依賴的第三方套件是否有已知漏洞？
