---
trigger: glob
globs: "**/*.rs, **/Cargo.toml, **/Cargo.lock"
---

# Rust 開發準則

> 適用於 Rust 系統程式、CLI 工具、Web 服務（Actix/Axum）、嵌入式等專案。
>
> 參考來源：Rust API Guidelines、Clippy Lints、Rust by Example、The Rust Book

---

## 版本與工具鏈

- 使用最新 stable Rust（`rustup default stable`）
- 使用 `cargo` 管理依賴與建置
- 使用 `rustfmt` 格式化、`clippy` linting

---

## 命名慣例

| 類型 | 慣例 | 範例 |
|------|------|------|
| Crate / 模組 | `snake_case` | `my_crate`, `user_service` |
| 型別（struct/enum/trait）| `PascalCase` | `UserService`, `ParseError` |
| 函式 / 方法 | `snake_case` | `get_user_by_id()` |
| 常數 | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT` |
| 生命週期 | 簡短小寫 | `'a`, `'de` |
| 型別參數 | 單一大寫字母或描述性名稱 | `T`, `E`, `Item` |
| 特徵方法（轉換）| `as_`（借用）/ `to_`（複製）/ `into_`（消耗）| `as_str()`, `to_string()`, `into_inner()` |

---

## 所有權與借用

### 核心原則

```rust
// ✅ 優先使用借用（避免不必要的 clone）
fn process(data: &[u8]) -> Result<Output, Error> {
    // ...
}

// ❌ 不必要的 clone
fn process(data: Vec<u8>) -> Result<Output, Error> {
    // 如果不需要所有權，用 &[u8]
}
```

### 規則

- 函式參數：優先使用 `&T`（借用），僅在需要所有權時用 `T`
- 回傳值：回傳擁有的值（`T`），讓呼叫者決定生命週期
- 避免不必要的 `.clone()`，先考慮是否能用借用解決
- 使用 `Cow<'_, str>` 處理可能需要也可能不需要複製的場景

---

## 錯誤處理

### 使用 `thiserror`（函式庫）或 `anyhow`（應用程式）

```rust
// 函式庫：使用 thiserror 定義結構化錯誤
use thiserror::Error;

#[derive(Debug, Error)]
pub enum ServiceError {
    #[error("user {id} not found")]
    NotFound { id: String },

    #[error("validation failed: {message}")]
    Validation { message: String },

    #[error("database error")]
    Database(#[from] sqlx::Error),
}

// 應用程式：使用 anyhow 簡化錯誤傳播
use anyhow::{Context, Result};

fn load_config() -> Result<Config> {
    let content = std::fs::read_to_string("config.toml")
        .context("failed to read config file")?;
    let config: Config = toml::from_str(&content)
        .context("failed to parse config")?;
    Ok(config)
}
```

### 規則

- 函式庫 crate：使用 `thiserror` 定義明確的錯誤型別
- 應用程式 crate：使用 `anyhow` 搭配 `.context()` 加上下文
- 永不使用 `.unwrap()`（除了測試）；使用 `.expect("reason")` 說明原因
- 使用 `?` 運算子傳播錯誤

---

## 型別系統

### Newtype 模式

```rust
// ✅ 使用 newtype 增加型別安全
struct UserId(String);
struct Email(String);

// 避免混淆參數
fn create_user(id: UserId, email: Email) -> Result<User, Error> {
    // ...
}
```

### Builder 模式（超過 4 個參數時）

```rust
#[derive(Default)]
struct ServerBuilder {
    port: Option<u16>,
    host: Option<String>,
    timeout: Option<Duration>,
}

impl ServerBuilder {
    fn port(mut self, port: u16) -> Self {
        self.port = Some(port);
        self
    }

    fn build(self) -> Result<Server, BuildError> {
        Ok(Server {
            port: self.port.unwrap_or(8080),
            host: self.host.unwrap_or_else(|| "127.0.0.1".to_string()),
            timeout: self.timeout.unwrap_or(Duration::from_secs(30)),
        })
    }
}
```

---

## Trait 設計

```rust
// ✅ 小而聚焦的 trait
trait Readable {
    fn read(&self, id: &str) -> Result<Option<Entity>, Error>;
}

trait Writable {
    fn save(&self, entity: &Entity) -> Result<(), Error>;
    fn delete(&self, id: &str) -> Result<(), Error>;
}

// 組合 trait
trait Repository: Readable + Writable {}
```

---

## 非同步程式設計

```rust
use tokio;

// ✅ 使用 tokio 或 async-std
async fn fetch_user(client: &reqwest::Client, id: &str) -> Result<User> {
    let response = client
        .get(&format!("/users/{id}"))
        .timeout(Duration::from_secs(5))
        .send()
        .await
        .context("failed to fetch user")?;

    let user = response
        .json::<User>()
        .await
        .context("failed to parse user response")?;

    Ok(user)
}

// ✅ 並行執行
let (user, orders) = tokio::try_join!(
    fetch_user(&client, user_id),
    fetch_orders(&client, user_id),
)?;
```

---

## 測試

### 單元測試（模組內）

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn calculate_discount_normal() {
        let result = calculate_discount(100.0, 0.1);
        assert!((result - 90.0).abs() < f64::EPSILON);
    }

    #[test]
    fn calculate_discount_invalid_rate() {
        let result = calculate_discount(100.0, 1.5);
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn fetch_user_returns_user() {
        let mock_server = MockServer::start().await;
        // ...
    }
}
```

### 測試指令

```bash
# 執行所有測試
cargo test

# 包含忽略的測試
cargo test -- --include-ignored

# 覆蓋率（使用 cargo-llvm-cov）
cargo llvm-cov --html

# 未使用依賴檢查
cargo +nightly udeps
```

---

## 安全性

- 禁止 `unsafe` 區塊（除非有充分理由並加註解說明）
- 使用 `cargo audit` 檢查依賴漏洞
- 使用 `cargo deny` 檢查授權與漏洞
- Secret 從環境變數讀取，禁止硬編碼

```rust
let api_key = std::env::var("API_KEY")
    .expect("API_KEY environment variable must be set");
```

---

## 程式碼品質工具

| 工具 | 用途 | 指令 |
|------|------|------|
| `rustfmt` | 格式化 | `cargo fmt` |
| `clippy` | Linting | `cargo clippy -- -D warnings` |
| `cargo audit` | 依賴漏洞 | `cargo audit` |
| `cargo deny` | 授權 / 漏洞 / 重複 | `cargo deny check` |
| `cargo test` | 測試 | `cargo test` |
| `cargo llvm-cov` | 覆蓋率 | `cargo llvm-cov` |
| `cargo doc` | 文件 | `cargo doc --open` |

### Clippy 設定（`clippy.toml` 或 `Cargo.toml`）

```toml
# Cargo.toml
[lints.clippy]
pedantic = "warn"
nursery = "warn"
unwrap_used = "deny"
expect_used = "warn"
```

### rustfmt 設定（`rustfmt.toml`）

```toml
edition = "2021"
max_width = 120
tab_spaces = 4
use_field_init_shorthand = true
use_try_shorthand = true
```

---

## 專案結構

```
src/
├── main.rs                  ← 應用程式進入點
├── lib.rs                   ← 函式庫進入點
├── domain/                  ← 領域模型
│   ├── mod.rs
│   └── user.rs
├── service/                 ← 業務邏輯
├── repository/              ← 資料存取
├── handler/                 ← HTTP 處理器
└── error.rs                 ← 錯誤型別定義
tests/                       ← 整合測試
benches/                     ← 效能基準測試
```
