---
title: "Zabbix | 监控主机到指定 ip 的流量大小"
date: 2023-08-04
lastmod: 2024-01-28
tags:
  - zabbix
  - shell
keywords:
  - zabbix
  - shell
description: "zabbix 中通过 shell 监控定时监控流量, 配置聚合图形, 以及日志输出"
cover:
    image: "images/cover-zabbix.png"
---

# 0 前言

分享一下如何监控某个主机上的网卡到指定 ip 的流量大小, 测试环境已安装 tcpdump 并配置了 zabbix_agent

被检测端 ip 为 1.1.1.11, 要检测到 1.1.1.12-17 这些 ip 的出口流量

大致流程为:

- 创建一个监控脚本, 分析 1 分钟内指定网卡发送到指定 ip 的数据包大小并输出到日志文件
- 将该脚本放到 crontab 中, 每分钟执行一次
- 配置 zabbix-agent
    - 创建数据采集脚本, 提取日志文件中的内容
    - 添加自定义配置, 创建采集的键值
- 配置 zabbix-server
    - 添加监控项
    - 添加触发器
    - 添加仪表盘

# 1 监控脚本

添加 /opt/traffic_monitor.sh

```bash
#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

set -e

# 检查是否安装了tcpdump命令
if which tcpdump >/dev/null 2>&1; then
    # 如果已安装，则不进行任何提示
    :
else
    echo "系统中未安装 tcpdump 命令，请先安装 tcpdump。"
    exit 1
fi

# 检查是否有 tcpdump 残留进程
existing_tcpdump_pids=$(pgrep -f "tcpdump -i ens32 -nn dst") || true

# 检查 tcpdump 进程数量
tcpdump_count=$(echo "${existing_tcpdump_pids}" | wc -w)
if [ "$tcpdump_count" -gt 6 ]; then
    # 如果数量大于 6 视为之前的进程未正确关闭, 杀死所有 tcpdump 进程
    kill -9 ${existing_tcpdump_pids}
fi

IPLIST=("1.1.1.12" "1.1.1.13" "1.1.1.14" "1.1.1.15" "1.1.1.16" "1.1.1.17")

LOG_DIRECTORY=/var/log/traffic_monitor
LOG_FILE=${LOG_DIRECTORY}/traffic_monitor.log
[ -d "${LOG_DIRECTORY}" ] || mkdir -p "${LOG_DIRECTORY}"
[ -f "${LOG_FILE}" ] || touch "${LOG_FILE}"

# 获取文件大小（以字节为单位）
log_file_size=$(du -b "$LOG_FILE" | cut -f1)

# 设置100M对应的字节数
limit_size=$((100 * 1024 * 1024))

# 检查文件大小是否大于100M
if [ "$log_file_size" -gt "$limit_size" ]; then
    # 清空文件
    echo "" > "$LOG_FILE"
fi


start_time=$(date +"%Y%m%d-%H%M%S")

for ip in "${IPLIST[@]}"; do
    (
        # 开始 tcpdump 抓包
        output_file=/tmp/monitor-${ip}-${start_time}.output
        nohup tcpdump -i ens32 -nn dst ${ip} and not icmp 2>/dev/null > ${output_file} &

        # 等待 60 秒后关闭 tcpdump
        tcpdump_pid=$!
        sleep 60 && kill ${tcpdump_pid}
        stop_time=$(date +"%Y%m%d-%H%M%S")

        # 分析流量大小, 以 KB 为单位
        traffic_size=$(cat ${output_file} | awk -F'length ' '{print $2}' | awk '{sum+=$1} END {printf "%.2f", sum / 1024}')

        # 删除 tcpdump 的输出文件
        rm -f ${output_file}
        echo "${ip} ==== ${start_time} ----> ${stop_time} ===== (KB) ${traffic_size}" >> ${LOG_FILE}
    ) &
done

# 等待所有后台任务完成
wait

exit 0
```

放到 crontab 中

```plaintext
* * * * * /bin/bash /opt/traffic_monitor.sh >/dev/null 2>&1
```

日志文件应有类似如下输出

```plaintext
$ tail -12 /var/log/traffic_monitor/traffic_monitor.log
1.1.1.14 ==== 20230804-154601 ----> 20230804-154701 ===== (KB) 1964.99
1.1.1.12 ==== 20230804-154601 ----> 20230804-154701 ===== (KB) 0.23
1.1.1.17 ==== 20230804-154601 ----> 20230804-154701 ===== (KB) 1029.35
1.1.1.16 ==== 20230804-154601 ----> 20230804-154701 ===== (KB) 1029.35
1.1.1.15 ==== 20230804-154601 ----> 20230804-154701 ===== (KB) 1029.35
1.1.1.13 ==== 20230804-154601 ----> 20230804-154701 ===== (KB) 1029.35
1.1.1.12 ==== 20230804-154701 ----> 20230804-154801 ===== (KB) 1029.49
1.1.1.14 ==== 20230804-154701 ----> 20230804-154801 ===== (KB) 0.00
1.1.1.15 ==== 20230804-154701 ----> 20230804-154801 ===== (KB) 0.00
1.1.1.16 ==== 20230804-154701 ----> 20230804-154801 ===== (KB) 1029.35
1.1.1.13 ==== 20230804-154701 ----> 20230804-154801 ===== (KB) 0.00
1.1.1.17 ==== 20230804-154701 ----> 20230804-154801 ===== (KB) 3086.44
```

# 2 配置 zabbix-agent

添加 /opt/zabbix_traffic_monitor.sh, 根据 ip 筛选最后一个匹配项的数值

```bash
#!/bin/bash

LOG_DIRECTORY=/var/log/traffic_monitor
LOG_FILE=${LOG_DIRECTORY}/traffic_monitor.log

grep "$1" "${LOG_FILE}" | awk '{last_column=$NF} END {print last_column}'
```

添加 /etc/zabbix/zabbix_agentd.d/get_traffic_monitor.conf 配置文件

```plaintext
UserParameter=get_traffic_monitor[*],/opt/zabbix_traffic_monitor.sh $1
```

重启 zabbix-agent

```bash
systemctl restart zabbix-agent
```

# 3 配置 zabbix-server

创建监控项, 有几个 ip 创建几个监控项

![image-20230804155344575](/images/image-20230804-155344.png)

监控项测试, 此处应有值

![image-20230804155732762](/images/image-20230804-155732.png)

创建触发器, 同样的, 有几个 ip 创建几个

![image-20230804155851395](/images/image-20230804-155851.png)

仪表盘添加图形

![image-20230804160014573](/images/image-20230804-160014.png)

# 4 测试

找一台服务器配置多 ip

```plaintext
IPADDR=1.1.1.12
NETMASK=255.255.255.0
GATEWAY=1.1.1.254
DNS1=8.8.8.8
DNS2=114.114.114.114

IPADDR1=1.1.1.13
NETMASK1=255.255.255.0
IPADDR2=1.1.1.14
NETMASK2=255.255.255.0
IPADDR3=1.1.1.15
NETMASK3=255.255.255.0
IPADDR4=1.1.1.16
NETMASK4=255.255.255.0
IPADDR5=1.1.1.17
NETMASK5=255.255.255.0
```

重启 network

![image-20230804160238120](/images/image-20230804-160238.png)

配置 1.1.1.11 到 1.1.1.12-17 的免密登录

```bash
ssh-keygen
ssh-copy-id root@1.1.1.12

# 每个 ip 都 ssh 一下, 添加一下 hotkey
ssh root@1.1.1.13
ssh root@1.1.1.14
ssh root@1.1.1.15
ssh root@1.1.1.16
ssh root@1.1.1.17
```

运行一个脚本模拟网络流量

```bash
#!/bin/bash

# 设置目标IP地址列表
ip_list=("1.1.1.12" "1.1.1.13" "1.1.1.14" "1.1.1.15" "1.1.1.16" "1.1.1.17")

dd if=/dev/zero of=/tmp/test bs=1M count=1

while true; do
    # 生成一个随机数，范围为 0 到 5
    random_index=$((RANDOM % 6))
    
    # 随机选择一个IP
    target_ip="${ip_list[random_index]}"
    
    echo ${target_ip}
    /usr/bin/scp /tmp/test root@${target_ip}:/tmp/
    
    # 等待10秒
    sleep 10
done
```

运行脚本, 应有如下输出

![image-20230804160852278](/images/image-20230804-160852.png)

过段时间后查看仪表盘, 能看到流量数据

![image-20230804161027483](/images/image-20230804-161027.png)

触发器也应正常工作

![image-20230804161124280](/images/image-20230804-161124.png)

以上
