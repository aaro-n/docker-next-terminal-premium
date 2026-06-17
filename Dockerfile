# ============================================================
# 阶段 1: 获取 Next Terminal 资源
# ============================================================
FROM dushixiang/next-terminal:latest AS source

# ============================================================
# 阶段 2: 最终运行镜像
# ============================================================
FROM dushixiang/guacd:latest

LABEL maintainer="next-terminal-premium-docker" \
      description="Next Terminal Premium - 堡垒机系统 (集成 Guacamole)" \
      version="v3.3.6"

# 设置工作目录
WORKDIR /usr/local/next-terminal

# 从 source 镜像中复制所有必要文件
COPY --from=source /usr/local/next-terminal/next-terminal ./
COPY --from=source /usr/local/next-terminal/bin ./bin
COPY --from=source /usr/local/next-terminal/web ./web

# 环境变量设置
ENV NT_IN_CONTAINER=true \
    TZ=Asia/Shanghai

# 安装 s6 控制器和基础工具，配置时区
RUN apk add --no-cache s6 tzdata logrotate && \
    mkdir -p /etc/next-terminal /usr/local/next-terminal/data && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' > /etc/timezone && \
    # 清理 apk 缓存
    rm -rf /var/cache/apk/*

# 复制启动脚本配置
COPY config/s6 /etc/s6
COPY config/start-run /var/run

# 设置权限
RUN chmod -R +x /etc/s6 && \
    chmod -R +x /var/run/*.sh && \
    chmod +x /usr/local/next-terminal/next-terminal && \
    chmod -R +x /usr/local/next-terminal/bin

# 健康检查 - 检测 next-terminal Web 服务是否存活
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:8088/ || exit 1

# 声明挂载点和端口
VOLUME ["/usr/local/next-terminal/data"]
EXPOSE 8088

# 设置 s6 作为入口点
ENTRYPOINT ["s6-svscan", "/etc/s6"]
