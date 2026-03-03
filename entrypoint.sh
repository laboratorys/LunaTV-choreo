#!/bin/sh
nohup /app/backup2gh > /dev/null 2>&1 &
sleep 5
retry_count=0
max_retries=30
while [ $retry_count -lt $max_retries ]; do
    if [ -f "/tmp/restore.lock" ]; then
        echo "$(date "+%Y-%m-%d %H:%M:%S") Waiting for restore from github..."
        sleep 5
        ((retry_count++))
    else
        break
    fi
done
echo "$(date "+%Y-%m-%d %H:%M:%S") Starting LunaTV server..."
node start.js