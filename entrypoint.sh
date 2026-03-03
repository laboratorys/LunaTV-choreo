#!/bin/sh

mkdir -p /app/data/next-cache
touch /app/data/manifest.json

nohup /app/backup2gh > /dev/null 2>&1 &
ldd /app/backup2gh

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

echo "$(date "+%Y-%m-%d %H:%M:%S") Starting LunaTV server..."

exec node start.js