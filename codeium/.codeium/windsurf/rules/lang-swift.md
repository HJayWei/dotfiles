---
trigger: glob
globs: "**/*.swift, **/Package.swift"
---

# Swift 開發準則

> 適用於 iOS/macOS 應用、Swift Package、Server-Side Swift 等專案。
>
> 參考來源：Apple API Design Guidelines、Swift.org Style Guide、Everything Claude Code

---

## 版本要求

- 最低支援 Swift 5.9+，建議 Swift 6.0+
- 啟用 Swift 6 strict concurrency checking
- Xcode 16+ 或 Swift Package Manager

---

## 格式與工具

- **SwiftFormat** 自動格式化，**SwiftLint** 風格檢查
- `swift-format`（Xcode 16+ 內建）作為替代方案

---

## 命名慣例

遵循 [Apple API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)：

| 類型 | 慣例 | 範例 |
|------|------|------|
| 型別（struct/class/enum/protocol）| `PascalCase` | `UserService`, `Loadable` |
| 函式 / 方法 / 屬性 | `camelCase` | `fetchUser()`, `isActive` |
| 常數 | `static let`（型別內）| `static let maxRetryCount = 3` |
| 布林屬性 | `is`/`has`/`can`/`should` 前綴 | `isValid`, `hasPermission` |
| 列舉 case | `camelCase` | `.loading`, `.failed(Error)` |

**核心原則**：
- 清晰優先於簡潔（clarity at the point of use）
- 省略不必要的字詞
- 依角色命名，而非型別

---

## 不可變性（Immutability）

```swift
// ✅ 優先使用 let
let userName = "Alice"

// ✅ 優先使用 struct（值語義）
struct User: Sendable {
    let id: UUID
    let name: String
    let email: String
}

// 僅在需要 identity 或 reference semantics 時使用 class
```

**規則**：
- 所有變數預設用 `let`，只有編譯器要求時才改用 `var`
- 優先使用 `struct`，僅在需要身份識別或參考語義時使用 `class`

---

## 錯誤處理

### Typed Throws（Swift 6+）

```swift
enum LoadError: Error {
    case fileNotFound(String)
    case invalidFormat
    case networkFailure(underlying: Error)
}

func load(id: String) throws(LoadError) -> Item {
    guard let data = try? read(from: path) else {
        throw .fileNotFound(id)
    }
    return try decode(data)
}
```

### 永不吞掉錯誤

```swift
// ❌ 靜默失敗
let result = try? riskyOperation()

// ✅ 明確處理
do {
    let result = try riskyOperation()
    process(result)
} catch {
    logger.error("Operation failed", metadata: ["error": "\(error)"])
    throw AppError.operationFailed(underlying: error)
}
```

---

## 並行（Concurrency）

### Structured Concurrency

```swift
// ✅ 優先使用 async let 與 TaskGroup
async let user = fetchUser(id)
async let orders = fetchOrders(userId: id)
let (userData, orderData) = try await (user, orders)

// ❌ 避免非結構化的 Task {}（除非必要）
```

### Actor 模式（共享可變狀態）

```swift
actor Cache<Key: Hashable & Sendable, Value: Sendable> {
    private var storage: [Key: Value] = [:]

    func get(_ key: Key) -> Value? { storage[key] }
    func set(_ key: Key, value: Value) { storage[key] = value }
}
```

### Sendable

- 跨隔離邊界傳遞的資料必須符合 `Sendable`
- 使用 `Sendable` 值型別（struct、enum）
- 使用 Actor 保護共享可變狀態

---

## Protocol-Oriented Design

```swift
// ✅ 小而聚焦的 protocol
protocol Repository: Sendable {
    associatedtype Item: Identifiable & Sendable
    func find(by id: Item.ID) async throws -> Item?
    func save(_ item: Item) async throws
}

// 使用 protocol extension 提供預設實作
extension Repository {
    func findOrFail(by id: Item.ID) async throws -> Item {
        guard let item = try await find(by: id) else {
            throw NotFoundError(id: id)
        }
        return item
    }
}
```

---

## 狀態建模（Enum with Associated Values）

```swift
enum LoadState<T: Sendable>: Sendable {
    case idle
    case loading
    case loaded(T)
    case failed(Error)
}
```

---

## 依賴注入

```swift
struct UserService {
    private let repository: any UserRepository

    init(repository: any UserRepository = DefaultUserRepository()) {
        self.repository = repository
    }
}
```

**規則**：使用 protocol + 預設參數，生產用預設實作，測試注入 mock。

---

## 測試

### Swift Testing 框架（推薦）

```swift
import Testing

@Test("User creation validates email")
func userCreationValidatesEmail() throws {
    #expect(throws: ValidationError.invalidEmail) {
        try User(email: "not-an-email")
    }
}

@Test("Validates formats", arguments: ["json", "xml", "csv"])
func validatesFormat(format: String) throws {
    let parser = try Parser(format: format)
    #expect(parser.isValid)
}
```

### 測試隔離

- 每個測試使用獨立實例（`init` 設定，`deinit` 清理）
- 禁止測試間共享可變狀態

### 覆蓋率

```bash
swift test --enable-code-coverage
```

---

## 安全性

### Secret 管理

```swift
// ✅ 使用 Keychain Services 儲存敏感資料
// 禁止使用 UserDefaults 儲存 token/密碼/金鑰

// ✅ 環境變數或 .xcconfig 用於建置時期密鑰
let apiKey = ProcessInfo.processInfo.environment["API_KEY"]
guard let apiKey, !apiKey.isEmpty else {
    fatalError("API_KEY not configured")
}
```

### Transport Security

- App Transport Security (ATS) 預設啟用，禁止關閉
- 關鍵端點使用 certificate pinning
- 驗證所有伺服器憑證

### 輸入驗證

- 所有使用者輸入在處理前必須清理
- 使用 `URL(string:)` 搭配驗證，禁止 force-unwrap
- 驗證外部來源資料（API、deep links、剪貼簿）

---

## 程式碼品質工具

| 工具 | 用途 | 指令 |
|------|------|------|
| `SwiftLint` | Linting | `swiftlint lint` |
| `SwiftFormat` | 格式化 | `swiftformat .` |
| `swift build` | 建置 | `swift build` |
| `swift test` | 測試 | `swift test` |

### SwiftLint 設定（`.swiftlint.yml`）

```yaml
opt_in_rules:
  - closure_body_length
  - empty_count
  - explicit_init
  - fatal_error_message
  - force_unwrapping
  - implicitly_unwrapped_optional
  - multiline_arguments
  - vertical_whitespace_closing_braces

disabled_rules:
  - trailing_whitespace

excluded:
  - .build
  - Packages

line_length:
  warning: 120
  error: 200

file_length:
  warning: 500
  error: 800
```
