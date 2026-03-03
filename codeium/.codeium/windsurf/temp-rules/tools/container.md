# Docker / Podman 容器化開發準則

> 適用於本地開發環境、CI/CD Pipeline、以及 Kubernetes 部署。支援 Docker 與 Podman 雙工具。
>
> 參考來源：Docker 官方最佳實踐、Podman 官方文件、Google Container Best Practices、Meta 容器化指引

---

## 工具選擇

| 項目 | Docker | Podman |
|------|--------|--------|
| **架構** | Daemon-based | Daemonless，無需 root |
| **安全性** | 需 root daemon | 原生 rootless 支援 |
| **Compose 工具** | `docker compose` | `podman-compose` 或 `podman kube` |
| **macOS 本地開發** | Docker Desktop | Podman Desktop / podman-machine |
| **CI/CD** | 廣泛支援 | 公司環境限制時適用 |
| **Kubernetes 相容性** | 退出 OCI 標準 | 原生 OCI，支援 `podman generate kube` |

**選擇建議**：
- 將 `docker` 與 `podman` 視為可互換指令（Podman 支援 `alias docker=podman`）
- 小型 / CI 環境限制：Podman rootless 更安全
- 開發團隊已統一使用 Docker Desktop：繼續使用 Docker

### 基礎映像 / OS 選擇

| 用途 | 優先選擇 | 次選 | 判斷依據 |
|------|---------|------|---------|
| **Container 映像** | Alpine / Debian (slim) | Arch | 映像大小優先；Alpine 極輕量，Debian slim 套件生態完整 |
| **VM 部署環境** | Debian | Alpine / Arch | 穩定性與套件支援優先；長期維運首選 Debian |

**選擇原則**：主要判斷開發時所需套件是否能良好支援該系統。
- **Alpine**：極小映像（~5MB），適合 Container；但 musl libc 可能導致部分套件不相容
- **Debian (slim)**：套件生態最完整，glibc 相容性最佳；VM 與 Container 均適用
- **Arch**：滾動更新，套件最新；適合需要最新版套件的場景，但穩定性風險較高

---

## Dockerfile 最佳實踐

### 多階段建置（Multi-stage Build）

```dockerfile
# Node.js 應用範例（多階段建置）
FROM node:22-alpine AS base
WORKDIR /app
COPY package*.json ./

# 依賴安裝階段（可快取）
FROM base AS deps
RUN npm ci --only=production

# 建置階段
FROM base AS builder
RUN npm ci
COPY . .
RUN npm run build

# 最終執行映像（最小化）
FROM node:22-alpine AS runner
WORKDIR /app

# 安全：建立非 root 使用者
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 appuser

COPY --from=deps --chown=appuser:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:nodejs /app/dist ./dist
COPY --chown=appuser:nodejs package.json ./

USER appuser
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

### PHP Laravel 範例

```dockerfile
FROM php:8.3-fpm-alpine AS base
WORKDIR /var/www/html

# 安裝系統依賴（合併 RUN 減少層數）
RUN apk add --no-cache \
    postgresql-dev \
    && docker-php-ext-install pdo_pgsql opcache \
    && rm -rf /var/cache/apk/*

# Composer 安裝依賴階段
FROM base AS deps
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY composer*.json ./
RUN composer install --no-dev --optimize-autoloader --no-interaction

# 最終執行映像
FROM base AS runner
COPY --from=deps /var/www/html/vendor ./vendor
COPY . .

# 建立非 root 使用者
RUN adduser -D -u 1001 appuser \
    && chown -R appuser:appuser /var/www/html

USER appuser
```

---

## Dockerfile 規則

### 層次快取最佳化

```dockerfile
# 原則：改動頻率低的層放前面，高的放後面
# 依賴（低頻）→ 設定（中頻）→ 程式碼（高頻）

# 先複製依賴描述檔（利用快取）
COPY package*.json ./
RUN npm ci

# 後複製原始碼（避免每次程式碼變更都重新安裝依賴）
COPY . .
RUN npm run build
```

### 映像大小最佳化

```dockerfile
# 使用 Alpine 基礎映像（大幅縮小映像大小）
FROM node:22-alpine    # ~50MB vs node:22 ~900MB

# 合併多個 RUN 指令（減少層數）
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*    # 清理快取

# 使用 .dockerignore 排除不必要的檔案
```

### `.dockerignore`

```
node_modules/
.git/
.env
.env.local
*.log
dist/
coverage/
.DS_Store
README.md
docs/
tests/
```

---

## Docker Compose / Podman Compose

### 本地開發環境設定

```yaml
# docker-compose.yml / podman-compose.yml
services:
  app:
    build:
      context: .
      target: runner           # 指定多階段建置的目標
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
    env_file:
      - .env.development       # 從環境變數檔案載入
    volumes:
      - ./src:/app/src:delegated  # 熱重載
    depends_on:
      db:
        condition: service_healthy  # 等待資料庫健康檢查通過
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./infra/postgres/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    ports:
      - "5432:5432"           # 僅在本地開發暴露；生產環境移除
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

volumes:
  postgres_data:
  redis_data:
```

### 多環境設定

```yaml
# docker-compose.override.yml（本地開發覆蓋，不提交到 Git）
services:
  app:
    volumes:
      - ./src:/app/src         # 開發時熱重載
    environment:
      - DEBUG=true
    ports:
      - "9229:9229"            # Node.js debug port
```

---

## 安全性準則

### 禁止以 root 執行

```dockerfile
# 建立非 root 使用者（所有映像都必須這麼做）
RUN addgroup --system --gid 1001 appgroup \
    && adduser --system --uid 1001 --ingroup appgroup appuser
USER appuser
```

### 禁止儲存機密在映像中

```dockerfile
# 禁止（機密會留在映像層中）
RUN echo "DB_PASSWORD=secret123" >> /etc/environment
ENV SECRET_KEY=hardcoded-secret

# 正確：透過執行時的環境變數注入
# docker run -e SECRET_KEY=$SECRET_KEY myapp
# 或使用 Docker Secrets / Kubernetes Secrets
```

### 映像漏洞掃描

```bash
# 使用 Trivy 掃描映像漏洞
trivy image myapp:latest

# 在 CI 中加入漏洞掃描（CRITICAL 或 HIGH 漏洞則失敗）
trivy image --exit-code 1 --severity CRITICAL,HIGH myapp:latest
```

---

## 健康檢查（Health Check）

```dockerfile
# 所有服務必須定義健康檢查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1
```

```typescript
// 健康檢查 API 端點（應回傳服務狀態）
router.get('/health', async (req, res) => {
  const dbOk = await checkDatabaseConnection();
  const redisOk = await checkRedisConnection();

  const status = dbOk && redisOk ? 'healthy' : 'unhealthy';
  const httpStatus = status === 'healthy' ? 200 : 503;

  res.status(httpStatus).json({
    status,
    timestamp: new Date().toISOString(),
    services: { database: dbOk, redis: redisOk },
  });
});
```

---

## 資源限制

```yaml
# 在 Compose 中設定資源限制（防止單一服務耗盡資源）
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

---

## 日誌管理

```dockerfile
# 輸出至 stdout/stderr（讓容器平台處理日誌聚合）
# 禁止將日誌寫入容器內的檔案

# 確保應用程式日誌寫入 stdout
CMD ["node", "dist/main.js"]
```

```yaml
# Compose 日誌設定
services:
  app:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

---

## 本地開發常用指令

### Docker 指令

```bash
# 啟動所有服務
docker compose up -d

# 查看日誌
docker compose logs -f app

# 進入容器 shell（除錯用）
docker compose exec app sh

# 重新建置並啟動
docker compose up -d --build

# 清理（包含 volumes）
docker compose down -v

# 查看容器資源使用
docker stats

# 檢查映像層大小
docker history myapp:latest

# 建置映像
docker build -t myapp:latest .

# 加入 BuildKit 快取（加速建置）
DOCKER_BUILDKIT=1 docker build -t myapp:latest .
```

### Podman 指令

Podman CLI 與 Docker 高度相容，大多數情況可直接用 `podman` 取代 `docker`：

```bash
# 建議設定 alias（加入 ~/.zshrc 或 ~/.bashrc）
alias docker=podman
alias docker-compose=podman-compose

# 建置映像
podman build -t myapp:latest .

# 啟動容器（rootless）
podman run -d -p 3000:3000 myapp:latest

# 使用 podman-compose
podman-compose up -d
podman-compose logs -f app
podman-compose down -v

# 過渡工具：從 Dockerfile 生成 Kubernetes YAML
podman generate kube myapp-container > deployment.yaml

# 查看容器資源
podman stats

# 清理未使用資源
podman system prune
```

### Podman Machine（macOS 本地開發）

```bash
# 建立並啟動 Podman machine
podman machine init
podman machine start

# 查看狀態
podman machine list
podman machine inspect

# 停止
podman machine stop
```

---

## CI/CD 建置最佳化

```yaml
# GitHub Actions 範例（使用 BuildKit 快取）
- name: Build Docker image
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: myapp:${{ github.sha }}
    cache-from: type=gha              # 使用 GitHub Actions 快取
    cache-to: type=gha,mode=max
    build-args: |
      BUILDKIT_INLINE_CACHE=1
```
