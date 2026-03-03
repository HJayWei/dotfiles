# Docker / 容器化開發準則

> 適用於本地開發環境、CI/CD Pipeline、以及 Kubernetes 部署。
>
> 參考來源：Docker 官方最佳實踐、Google Container Best Practices、Meta 容器化指引

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
