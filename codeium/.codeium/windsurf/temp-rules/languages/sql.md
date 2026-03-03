# SQL / 資料庫開發準則

> 適用於 PostgreSQL（主要）、MySQL、SQLite 的查詢與 Migration 設計。
>
> 參考來源：PostgreSQL 官方文件、Use The Index, Luke、Google Database Style Guide

---

## 命名慣例

| 類型 | 慣例 | 範例 |
|------|------|------|
| 資料表 | `snake_case` 複數 | `users`, `order_items` |
| 欄位 | `snake_case` | `created_at`, `user_id` |
| 主鍵 | `id`（建議使用 UUID v7） | `id uuid PRIMARY KEY` |
| 外鍵 | `{參照表單數}_id` | `user_id`, `order_id` |
| 索引 | `idx_{table}_{columns}` | `idx_users_email` |
| 唯一約束 | `uq_{table}_{columns}` | `uq_users_email` |
| 外鍵約束 | `fk_{table}_{ref_table}` | `fk_orders_users` |
| 預存程序 | `snake_case` 動詞開頭 | `calculate_order_total()` |

---

## SQL 風格

### 關鍵字大寫，識別符小寫

```sql
-- 正確
SELECT
    u.id,
    u.name,
    u.email,
    COUNT(o.id) AS order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.is_active = TRUE
    AND u.created_at >= NOW() - INTERVAL '30 days'
GROUP BY u.id, u.name, u.email
ORDER BY order_count DESC
LIMIT 20;

-- 禁止
select id,name from users where isActive=1
```

### 欄位明確指定（禁止 SELECT *）

```sql
-- 禁止（效能差、脆弱）
SELECT * FROM users;

-- 正確（明確指定所需欄位）
SELECT id, name, email, created_at FROM users;
```

---

## 索引策略

### 何時建立索引

```sql
-- 1. 主鍵（自動建立）
-- 2. 外鍵欄位（JOIN 效能）
CREATE INDEX idx_orders_user_id ON orders (user_id);

-- 3. 常用的 WHERE 條件欄位
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_orders_status ON orders (status);

-- 4. 複合索引（最左前綴原則）
-- 適用於 WHERE status = ? AND created_at > ?
CREATE INDEX idx_orders_status_created ON orders (status, created_at DESC);

-- 5. 部分索引（Partial Index）只索引有意義的資料
CREATE INDEX idx_orders_pending ON orders (created_at)
WHERE status = 'pending';
```

### 何時不建立索引

- 寫入頻率遠高於讀取的欄位
- 基數（cardinality）極低的欄位（如布林值）
- 資料量極少的表（< 1000 行）

### 識別 N+1 與慢查詢

```sql
-- 使用 EXPLAIN ANALYZE 分析查詢計畫
EXPLAIN ANALYZE
SELECT u.*, COUNT(o.id) AS order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id;

-- 確認是否使用索引掃描（Index Scan）而非循序掃描（Seq Scan）
-- Seq Scan 在大資料表通常代表缺少索引
```

---

## Migration 規範

### 原則

1. **Migration 是不可逆的生產操作**，每次執行必須謹慎
2. 每個 migration 必須同時實作 `up()` 和 `down()`（可回滾）
3. Migration 檔案一旦提交就不得修改（只能新增新的 migration）
4. 高風險操作（大表 ALTER、DROP 等）必須在離峰時段執行

### Laravel Migration 範例

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->constrained()->cascadeOnDelete();
            $table->decimal('total_amount', 10, 2);
            $table->string('status', 50)->default('pending');
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();

            // 索引
            $table->index('user_id');
            $table->index(['status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
```

### 高風險 Migration 的安全做法

```sql
-- 在 PostgreSQL 中為大型表新增欄位（避免鎖表）
-- 1. 先新增可為 NULL 的欄位（不鎖表）
ALTER TABLE orders ADD COLUMN discount_amount DECIMAL(10,2);

-- 2. 批次更新預設值（避免長時間鎖定）
UPDATE orders SET discount_amount = 0 WHERE id IN (
    SELECT id FROM orders WHERE discount_amount IS NULL LIMIT 1000
);
-- 重複執行直到全部更新完成

-- 3. 設定 NOT NULL 約束（分離執行）
ALTER TABLE orders ALTER COLUMN discount_amount SET NOT NULL;
ALTER TABLE orders ALTER COLUMN discount_amount SET DEFAULT 0;
```

---

## 交易（Transaction）

```sql
-- 需要原子性的操作必須使用交易
BEGIN;

UPDATE accounts SET balance = balance - 500 WHERE id = 'sender_id';
UPDATE accounts SET balance = balance + 500 WHERE id = 'receiver_id';
INSERT INTO transfer_logs (from_id, to_id, amount) VALUES ('sender_id', 'receiver_id', 500);

COMMIT;
-- 任何步驟失敗時 ROLLBACK
```

```php
// Laravel 中使用交易
DB::transaction(function () use ($senderId, $receiverId, $amount) {
    Account::where('id', $senderId)->decrement('balance', $amount);
    Account::where('id', $receiverId)->increment('balance', $amount);
    TransferLog::create([
        'from_id' => $senderId,
        'to_id'   => $receiverId,
        'amount'  => $amount,
    ]);
});
```

---

## 資料模型設計準則

### 正規化（Normalization）

- 預設遵循第三正規化（3NF）
- 為效能考量的反正規化必須文件化並加 comment

### 主鍵策略

```sql
-- 推薦：UUID v7（時序性，適合分散式系統）
id UUID DEFAULT gen_random_uuid() PRIMARY KEY

-- 或使用 ULID（更易讀、排序性更好）
-- 在應用程式層生成 ULID

-- 自增整數（僅適合簡單的小型系統）
id BIGSERIAL PRIMARY KEY
```

### 時間欄位

```sql
-- 所有資料表必須有時間追蹤欄位
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
deleted_at TIMESTAMPTZ  -- 軟刪除（soft delete）
```

**規則**:
- 永遠使用帶時區的時間戳（`TIMESTAMPTZ`），而非 `TIMESTAMP`
- 時間戳以 UTC 儲存
- 禁止使用 `DATETIME`（MySQL 舊式，無時區資訊）

### 軟刪除 vs 硬刪除

| 情境 | 建議 |
|------|------|
| 使用者資料、訂單、財務記錄 | 軟刪除（保留稽核軌跡）|
| 暫時性資料（session、快取記錄）| 硬刪除 |
| 需要 GDPR 合規的個資 | 硬刪除（或匿名化）|

---

## 效能最佳化

### 常見反模式與修正

```sql
-- 反模式 1：在 WHERE 子句中使用函式（無法使用索引）
-- 禁止
WHERE DATE(created_at) = '2024-01-01'

-- 正確（能使用 created_at 的索引）
WHERE created_at >= '2024-01-01 00:00:00'
  AND created_at <  '2024-01-02 00:00:00'

-- 反模式 2：OR 條件（考慮改用 UNION）
-- 可能無法有效使用索引
WHERE status = 'pending' OR status = 'processing'

-- 更好的做法
WHERE status IN ('pending', 'processing')

-- 反模式 3：SELECT COUNT(*) 檢查存在性（效能差）
-- 禁止
IF (SELECT COUNT(*) FROM users WHERE email = ?) > 0

-- 正確
IF EXISTS (SELECT 1 FROM users WHERE email = ?)
```

### 分頁最佳化

```sql
-- 反模式：OFFSET 在大資料集效能極差
SELECT * FROM orders ORDER BY created_at DESC LIMIT 20 OFFSET 10000;

-- 正確：使用 Keyset Pagination（Cursor-based）
SELECT * FROM orders
WHERE created_at < :last_cursor_value
ORDER BY created_at DESC
LIMIT 20;
```

---

## 安全性

```sql
-- 永遠使用參數化查詢（防止 SQL Injection）
-- 禁止（PHP 範例）
$query = "SELECT * FROM users WHERE email = '$email'";

-- 正確（PDO 參數化）
$stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
$stmt->execute([$email]);

-- 使用最小權限原則：應用程式帳號不應有 DDL 權限
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
-- 不授予 CREATE, DROP, ALTER
```
