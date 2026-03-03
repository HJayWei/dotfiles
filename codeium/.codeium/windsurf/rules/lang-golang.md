---
trigger: glob
globs: "**/*.go, **/go.mod, **/go.sum"
---

# Go 開發準則

> 適用於 Go 後端服務、CLI 工具、微服務等專案。
>
> 參考來源：Effective Go、Google Go Style Guide、Uber Go Style Guide、Everything Claude Code

---

## 版本與環境管理

- 最低支援 Go 1.22+
- 使用 Go Modules 管理依賴
- 使用 `gofmt` 與 `goimports` 自動格式化（不可協商）

---

## 命名慣例

| 類型 | 慣例 | 範例 |
|------|------|------|
| 套件 | 全小寫、簡短、無底線 | `user`, `httputil` |
| 介面（單方法）| 動詞 + `er` 後綴 | `Reader`, `Writer`, `Closer` |
| 匯出名稱 | `PascalCase` | `NewUserService`, `ErrNotFound` |
| 未匯出名稱 | `camelCase` | `validateEmail`, `userCount` |
| 常數 | `PascalCase`（匯出）或 `camelCase`（未匯出）| `MaxRetryCount`, `defaultTimeout` |
| 錯誤變數 | `Err` 前綴 | `ErrNotFound`, `ErrInvalidInput` |
| 縮寫 | 全大寫或全小寫 | `HTTPClient`, `xmlParser`（非 `HttpClient`）|

---

## 設計原則

### Accept Interfaces, Return Structs

```go
// ✅ 接受介面（彈性），回傳具體結構（明確）
func NewUserService(repo UserRepository, logger Logger) *UserService {
    return &UserService{repo: repo, logger: logger}
}

// ❌ 回傳介面（過度抽象）
func NewUserService(repo UserRepository) UserRepository {
    return &userServiceImpl{repo: repo}
}
```

### 小介面（Interface Segregation）

```go
// ✅ 小而聚焦的介面
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

// 組合介面
type ReadWriter interface {
    Reader
    Writer
}

// ❌ 肥大的介面
type Repository interface {
    FindAll() ([]Entity, error)
    FindByID(id string) (*Entity, error)
    Create(entity *Entity) error
    Update(entity *Entity) error
    Delete(id string) error
    Count() (int, error)
    Search(query string) ([]Entity, error)
}
```

**介面定義在使用端**，而非實作端。

---

## Functional Options 模式

```go
type Option func(*Server)

func WithPort(port int) Option {
    return func(s *Server) { s.port = port }
}

func WithTimeout(d time.Duration) Option {
    return func(s *Server) { s.timeout = d }
}

func NewServer(opts ...Option) *Server {
    s := &Server{port: 8080, timeout: 30 * time.Second}
    for _, opt := range opts {
        opt(s)
    }
    return s
}
```

---

## 錯誤處理

### 永遠檢查錯誤

```go
// ❌ 忽略錯誤
result, _ := doSomething()

// ✅ 處理錯誤
result, err := doSomething()
if err != nil {
    return fmt.Errorf("doSomething failed: %w", err)
}
```

### 使用 `fmt.Errorf` 包裝錯誤（加上下文）

```go
func (s *UserService) GetUser(id string) (*User, error) {
    user, err := s.repo.FindByID(id)
    if err != nil {
        return nil, fmt.Errorf("get user %s: %w", id, err)
    }
    return user, nil
}
```

### 自定義錯誤型別

```go
type NotFoundError struct {
    Resource string
    ID       string
}

func (e *NotFoundError) Error() string {
    return fmt.Sprintf("%s (id: %s) not found", e.Resource, e.ID)
}

// 使用 errors.Is / errors.As 檢查
if errors.As(err, &notFound) {
    // 處理 not found
}
```

---

## 並行（Concurrency）

### Context 與 Timeout

```go
// ✅ 永遠使用 context.Context 控制 timeout
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()

result, err := s.repo.FindByID(ctx, id)
```

### Goroutine 安全

```go
// ✅ 使用 errgroup 管理並行任務
g, ctx := errgroup.WithContext(ctx)

g.Go(func() error {
    user, err = fetchUser(ctx, userID)
    return err
})

g.Go(func() error {
    orders, err = fetchOrders(ctx, userID)
    return err
})

if err := g.Wait(); err != nil {
    return fmt.Errorf("fetch dashboard data: %w", err)
}
```

### Channel 使用原則

- 優先使用 `sync.Mutex` 保護共享狀態（簡單場景）
- Channel 適用於 goroutine 間通訊
- 永遠確保 channel 會被關閉（避免 goroutine leak）

---

## 依賴注入

```go
// ✅ 透過建構函式注入依賴
type UserService struct {
    repo   UserRepository
    logger Logger
    cache  Cache
}

func NewUserService(repo UserRepository, logger Logger, cache Cache) *UserService {
    return &UserService{
        repo:   repo,
        logger: logger,
        cache:  cache,
    }
}
```

---

## 測試

### 框架與工具

- 使用標準 `go test`，搭配 **table-driven tests**
- 永遠使用 `-race` flag 偵測競態條件
- 使用 `testify` 提供更清晰的斷言（可選）

### Table-Driven Tests

```go
func TestCalculateDiscount(t *testing.T) {
    tests := []struct {
        name     string
        price    float64
        rate     float64
        expected float64
        wantErr  bool
    }{
        {"normal discount", 100.0, 0.1, 90.0, false},
        {"zero discount", 100.0, 0.0, 100.0, false},
        {"full discount", 100.0, 1.0, 0.0, false},
        {"invalid rate", 100.0, 1.5, 0, true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result, err := CalculateDiscount(tt.price, tt.rate)
            if tt.wantErr {
                if err == nil {
                    t.Errorf("expected error, got nil")
                }
                return
            }
            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }
            if result != tt.expected {
                t.Errorf("got %v, want %v", result, tt.expected)
            }
        })
    }
}
```

### 測試指令

```bash
# 執行測試（含競態偵測）
go test -race ./...

# 覆蓋率
go test -cover ./...

# 詳細覆蓋率報告
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

---

## 安全性

### Secret 管理

```go
apiKey := os.Getenv("API_KEY")
if apiKey == "" {
    log.Fatal("API_KEY not configured")
}
```

### 安全掃描

```bash
# 使用 gosec 進行靜態安全分析
gosec ./...
```

### Context 與 Timeout

所有外部呼叫（HTTP、DB、gRPC）必須帶 `context.Context` 與 timeout。

---

## 程式碼品質工具

| 工具 | 用途 | 指令 |
|------|------|------|
| `gofmt` | 格式化 | `gofmt -w .` |
| `goimports` | 格式化 + 匯入排序 | `goimports -w .` |
| `golangci-lint` | 綜合 Linting | `golangci-lint run` |
| `gosec` | 安全分析 | `gosec ./...` |
| `go vet` | 靜態分析 | `go vet ./...` |
| `staticcheck` | 進階靜態分析 | `staticcheck ./...` |

### golangci-lint 設定（`.golangci.yml`）

```yaml
run:
  timeout: 5m

linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused
    - gofmt
    - goimports
    - gosec
    - prealloc
    - bodyclose
    - noctx

linters-settings:
  errcheck:
    check-type-assertions: true
  govet:
    check-shadowing: true

issues:
  exclude-rules:
    - path: _test\.go
      linters:
        - gosec
```

---

## 專案結構（推薦）

```
cmd/
├── api/main.go              ← 應用程式進入點
internal/
├── domain/                  ← 領域模型與業務規則
├── service/                 ← 應用層服務
├── repository/              ← 資料存取層
├── handler/                 ← HTTP/gRPC 處理器
└── middleware/              ← 中介層
pkg/                         ← 可匯出的共用套件
```

遵循 [Standard Go Project Layout](https://github.com/golang-standards/project-layout) 慣例。
