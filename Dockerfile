# 阶段 1: 引用源镜像
FROM ghcr.io/laboratorys/lunatv:dev AS lunatv-source

# 阶段 2: 运行镜像 - 换成 slim 避免 Alpine 的 glibc 兼容性问题
FROM node:20-slim AS runner

# 安装基础依赖 (Debian 环境)
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    sqlite3 \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# 设置时区
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone

# 创建 Choreo 要求的 10014 用户和组
RUN groupadd -g 10014 choreo && \
    useradd --shell /bin/bash -u 10014 -g choreo -m choreouser

# 明确工作目录
WORKDIR /app

# --- 关键：在 COPY 时直接把源镜像的所有内容赋予 10014 ---
# 使用 . 复制源镜像的工作目录，确保隐藏文件也被带入
COPY --from=lunatv-source --chown=10014:10014 /app/. ./

# 确保数据目录在构建阶段就属于 10014
RUN mkdir -p /app/data && chown -R 10014:10014 /app/data

# 下载并赋予备份工具权限 (此时是构建阶段，可以执行 chmod)
ARG BAK_VERSION=2.2
RUN curl -L "https://github.com/laboratorys/backup2gh/releases/download/v${BAK_VERSION}/backup2gh-linux-amd64.tar.gz" -o backup2gh.tar.gz \
    && tar -xzf backup2gh.tar.gz \
    && rm backup2gh.tar.gz \
    && chmod +x backup2gh \
    && chown 10014:10014 backup2gh

# 环境变量
ENV NODE_ENV=production \
    HOSTNAME=0.0.0.0 \
    PORT=3000 \
    DOCKER_ENV=true \
    SQLITE_PATH=/app/data/tv.db

# 切换到 Choreo 用户
USER 10014

# 挂载卷
VOLUME /app/data
EXPOSE 3000

# 启动命令：先打印路径诊断，再尝试启动
# 如果 start.js 还是找不到，ls 会告诉我们它到底被复制到了哪里
CMD ["/bin/sh", "-c", "echo 'Current Dir Contents:' && ls -F && node start.js"]