#!/bin/sh

# 1. 确保挂载的持久化目录中存在必要的子文件夹和文件
# 这样 Dockerfile 里的软链接才能找到目标
mkdir -p /app/data/next-cache
touch /app/data/manifest.json

# 2. 启动备份/恢复工具
nohup /app/backup2gh > /dev/null 2>&1 &

# 3. 等待恢复完成
echo "$(date "+%Y-%m-%d %H:%M:%S") Checking for restore status..."
sleep 5
retry_count=0
max_retries=30

while [ $retry_count -lt $max_retries ]; do
    if [ -f "/tmp/restore.lock" ]; then
        echo "$(date "+%Y-%m-%d %H:%M:%S") Waiting for restore from github... ($retry_count/$max_retries)"
        sleep 5
        # 使用 sh 兼容的自增语法
        retry_count=$((retry_count + 1))
    else
        echo "$(date "+%Y-%m-%d %H:%M:%S") Restore lock not found, proceeding..."
        break
    fi
done

# 4. 启动主程序
echo "$(date "+%Y-%m-%d %H:%M:%S") Starting LunaTV server..."
# 使用 exec 确保 node 进程成为 PID 1，以便正确处理容器信号
exec node start.js