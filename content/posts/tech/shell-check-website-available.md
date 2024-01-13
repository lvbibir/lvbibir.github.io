---
title: "shell | 检测网站存活并自动钉钉告警" 
date: 2023-12-07
lastmod: 2023-12-07
tags: 
  - shell
keywords:
  - shell
  - centos
description: "" 
cover:
    image: "https://image.lvbibir.cn/blog/shell.png" 
---

脚本内容如下, 替换钉钉 bot 的 token, 将脚本放至 crontab 执行即可

```bash
#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# 设置要检测的网页URL
urls=("https://emp.cnpc.com.cn/index.html" "https://mdm.cnpc.com.cn/")
#urls=("https://emp.cnpc.com.cn/index.html" "https://mdm.cnpc.com.cn/" "https://www.956100.com" "https://mm.956100.com" "https://app.956100.com")

# 钉钉机器人的 webhook 地址
webhook="https://oapi.dingtalk.com/robot/send?access_token=******************************"

# 最大连续无法访问次数
max_attempts=3

# 设置并发进程数为 URL 数量
max_concurrent=${#urls[@]}

# 初始化计数器
completed=0

for url in "${urls[@]}"; do
    # 在后台启动一个子进程进行测试
    (
        attempts=0
        while [ $attempts -lt $max_attempts ]; do
            # 使用curl获取网页内容，并保存HTTP状态码到变量response_code
            response_code=$(curl -s --connect-timeout 5  -o /dev/null -w "%{http_code}" "$url")

            # 判断HTTP状态码来确定网页是否可访问
            if [ "$response_code" -eq 200 ]; then
                break
            else
                attempts=$((attempts + 1))
            fi

            if [ $attempts -ge $max_attempts ]; then
                message="告警: $(date +"%Y年%m月%d日-%H:%M:%S") ${url} 网页无法访问，HTTP状态码: $response_code"
                curl -X POST ${webhook} -H "Content-Type: application/json" -d "{\"msgtype\": \"text\", \"text\": {\"content\":\"$message\"}}"
                break
            fi

            sleep 60  # 等待 20 秒后再次尝试
        done

            completed=$((completed + 1))
    ) &

    # 控制并发进程数
    if [ $completed -ge $max_concurrent ]; then
        wait
        completed=0
    fi
done

# 等待剩余的并发进程完成
wait

exit 0
```
