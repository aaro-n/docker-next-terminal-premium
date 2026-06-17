# Next Terminal Premium Docker

基于 s6 进程管理器的 Next Terminal + Guacamole 一体化 Docker 镜像。

## 特性

- 🚀 **一体化**: Next Terminal + Guacamole 整合在同一个容器中
- ⚙️ **自动配置**: 通过环境变量自动生成配置文件
- 🔄 **进程管理**: 使用 s6 进程管理器同时守护 next-terminal 和 guacd
- 🩺 **健康检查**: 内置容器健康检查机制

## 快速开始

### 使用 Docker Compose（推荐）

```bash
# 1. 克隆项目
git clone <your-repo-url>
cd docker-next-terminal-premium

# 2. 创建数据目录
mkdir -p data

# 3. 构建并启动（需要先配置好 PostgreSQL 数据库）
docker compose -f docker-compose-build.yml up -d

# 4. 查看日志
docker compose -f docker-compose-build.yml logs -f
```

### 使用 Docker CLI

```bash
# 构建镜像
docker build -t next-terminal-premium .

# 运行容器
docker run -d \
  --name next-terminal \
  -p 8088:8088 \
  -v ./data:/usr/local/next-terminal/data \
  next-terminal-premium
```

## 环境变量说明

### 数据库配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `APP_DATABASE_URL` | (空) | 数据库完整连接 URL，优先级高于分体参数 |
| `APP_DATABASE_ENABLED` | `true` | 是否启用数据库 |
| `APP_DATABASE_POSTGRES_HOSTNAME` | `postgresql` | PostgreSQL 主机名 |
| `APP_DATABASE_POSTGRES_PORT` | `5432` | PostgreSQL 端口 |
| `APP_DATABASE_POSTGRES_USERNAME` | `next-terminal` | 数据库用户名 |
| `APP_DATABASE_POSTGRES_PASSWORD` | `next-terminal` | 数据库密码 |
| `APP_DATABASE_POSTGRES_DATABASE` | `next-terminal` | 数据库名 |
| `APP_DATABASE_SHOW_SQL` | `false` | 是否打印 SQL 日志 |

### 服务器配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `APP_SERVER_ADDR` | `0.0.0.0:8088` | 服务监听地址 |
| `APP_LOG_LEVEL` | `debug` | 日志级别 (debug/info/warn/error) |
| `APP_LOG_FILENAME` | `./logs/nt.log` | 日志文件路径 |

### Guacd 配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `APP_APP_GUACD_HOSTS_HOSTNAME` | `guacd` | Guacd 主机名 |
| `APP_APP_GUACD_HOSTS_PORT` | `4822` | Guacd 端口 |
| `APP_APP_GUACD_HOSTS_WEIGHT` | `1` | 权重 |

### 录屏与存储配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `APP_APP_RECORDING_TYPE` | `local` | 录屏存储类型 (local/s3) |
| `APP_APP_RECORDING_PATH` | `/usr/local/next-terminal/data/recordings` | 录屏存储路径 |
| `APP_APP_GUACD_DRIVE` | `/usr/local/next-terminal/data/drive` | 文件传输路径 |

### 反向代理配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `APP_REVERSE_PROXY_ENABLED` | `false` | 是否启用反向代理 |
| `APP_REVERSE_PROXY_SELF_DOMAIN` | `nt.yourdomain.com` | 自代理域名 |
| `APP_REVERSE_PROXY_IP_EXTRACTOR` | `direct` | IP 提取方式 |

### 主机配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `HOSTS_CONFIG` | (空) | 自定义 hosts 配置（Base64 编码） |
| `SSH_AUTHORIZED_KEYS` | (空) | SSH 授权密钥（Base64 编码） |

## 与 PostgreSQL 配合使用

创建 `docker-compose.yml`:

```yaml
services:
  postgresql:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_USER: next-terminal
      POSTGRES_PASSWORD: next-terminal
      POSTGRES_DB: next-terminal
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U next-terminal"]
      interval: 10s
      timeout: 5s
      retries: 5

  next-terminal:
    build:
      context: .
      dockerfile: Dockerfile
    restart: always
    container_name: next-terminal
    depends_on:
      postgresql:
        condition: service_healthy
    environment:
      APP_DATABASE_POSTGRES_HOSTNAME: postgresql
      APP_DATABASE_POSTGRES_USERNAME: next-terminal
      APP_DATABASE_POSTGRES_PASSWORD: next-terminal
      APP_DATABASE_POSTGRES_DATABASE: next-terminal
    ports:
      - "8088:8088"
    volumes:
      - ./data:/usr/local/next-terminal/data

volumes:
  postgres-data:
```

## 项目结构

```
.
├── Dockerfile                  # 镜像构建文件
├── docker-compose-build.yml    # 构建用 Compose 配置
├── docker-compose-example.yml  # 使用示例
├── .dockerignore               # Docker 构建忽略规则
├── config/
│   ├── s6/                     # s6 服务目录
│   │   ├── next-guacd/run      # Guacd 启动脚本
│   │   ├── next-terminal/run   # Next Terminal 启动脚本
│   │   └── start/              # 初始化服务
│   │       ├── run             # 初始化运行脚本
│   │       └── finish          # 初始化完成脚本（防止重启）
│   └── start-run/              # 初始化脚本
│       ├── generate_config.sh  # 配置文件生成器
│       └── start-config.sh     # Hosts 配置脚本
├── sql/
│   └── config.yaml             # 示例配置文件
└── version                     # 版本信息
```
