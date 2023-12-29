---
title: "Zabbix 监控端口连通性并自动追踪 TCP 路由" 
date: 2023-12-07
lastmod: 2023-12-07
tags: 
- zabbix
- shell
keywords:
- zabbix
- shell
description: "" 
cover:
    image: "https://image.lvbibir.cn/blog/Zabbix_logo.png" 
---

# 0. 前言

本文实现被检测主机到特定 ip 的特定端口的连通性, 通过 `nc` 命令测试端口可用性, 当 `nc` 超时时自动执行 `traceroute` 追踪路由定位网络故障点, 本文的案例是监控我们生产的短信业务服务器到运营商提供的短信接口之间的连通性.

环境信息:

- CentOS 7.6
- Zabbix 3.4

确保需要检测端口连通性的服务器安装了 `nc` 及 `traceroute`

# 1. 服务器配置

> 每个需要检测的服务器都要做如下操作

修改 traceroute 权限

```bash
chmod u+s /usr/bin/traceroute
```

创建检测脚本, 脚本传入三个参数: `nc` 命令的超时时间, 要检测的 ip 以及端口, traceroute 日志保存到 `/var/log/smslink_monitor` 目录

```bash
vim /etc/zabbix/zabbix_agentd.d/smslink.sh

#!/bin/bash

start_time=$(date +"%Y%m%d-%H%M%S")

timeout=$1
ip=$2
port=$3

LOG_DIRECTORY=/var/log/smslink_monitor
[ -d "${LOG_DIRECTORY}" ] || mkdir -p "${LOG_DIRECTORY}"

# 开始 nc 测试连通性
nc_result=$(/bin/nc -z -w ${timeout} ${ip} ${port}; echo $?)
echo ${nc_result}

# 如果 nc 测试失败则执行 traceroute
if [ ${nc_result} -ne 0 ]; then
    log_file="${LOG_DIRECTORY}/${start_time}-${ip}-${port}.log"
    /bin/nohup /usr/bin/traceroute -n -T -p ${port} ${ip} > ${log_file} 2>&1 &
fi

exit 0
```

此步可以略过, 如果用 root 用户执行过脚本进行测试, 需要执行一下, 因为 root 用户执行过脚本后, 这个目录的属主将是 root, 而 zabbix 执行脚本使用的是 zabbix 用户, 会导致没有权限写入 

```bash
chown zabbix:zabbix /var/log/smslink_monitor
```

新增 zabbix agent 配置文件, 通过调用我们刚才创建的脚本实现

```bash
vim /etc/zabbix/zabbix_agentd.d/smslink.conf

# $1: timeout
# $2: ip
# $3: port
UserParameter=get_smslink_status[*],/bin/sh /etc/zabbix/zabbix_agentd.d/smslink.sh $1 $2 $3
```

重启 zabbix agent

```bash
systemctl restart zabbix-agent
```

在 `zabbix server` 端测试监控项, `*` 为占位符, 改成自己的实际 ip, 返回值 0 为正常, 其他值为异常

```bash
[root@klmy-kfyy-jxwh-0003 ~]# zabbix_get -s 192.168.4.72 -p 10050 -k get_smslink_status[3,10.**.**.22,7001]
0
[root@klmy-kfyy-jxwh-0003 ~]# zabbix_get -s 192.168.4.73 -p 10050 -k get_smslink_status[3,10.**.**.22,7001]
0
[root@klmy-kfyy-jxwh-0003 ~]# zabbix_get -s 192.168.4.74 -p 10050 -k get_smslink_status[3,10.**.**.22,7001]
0
```

改成一个错误的端口, 可以看到返回值变成了 `1`

```bash
[root@klmy-kfyy-jxwh-0003 ~]# zabbix_get -s 192.168.4.72 -p 10050 -k get_smslink_status[3,10.**.**.22,7002]
1
```

在 `4.72` 上看下 traceroute 日志输出

```bash
[root@klmy-kfyy-dxpt-0003 ~]# ls -ltr  /var/log/smslink_monitor/
-rw-rw-r-- 1 zabbix zabbix 595 Dec  7 11:21 20231207-112058-10.**.**.22-7002.log
[root@klmy-kfyy-dxpt-0003 ~]# cat /var/log/smslink_monitor/20231207-112058-10.**.**.22-7002.log
traceroute to 10.**.**.22 (10.**.**.22), 30 hops max, 60 byte packets
 1  * * *
 2  * * *
 3  100.32.34.2  5.202 ms  5.198 ms  5.187 ms
 4  * * *
 5  11.54.13.201  6.103 ms  6.076 ms  6.074 ms
 6  11.54.13.1  6.873 ms  2.104 ms  1.598 ms
 7  * * *
 8  10.33.253.129  2.086 ms  3.160 ms  3.110 ms
 9  10.11.1.153  71.703 ms  70.821 ms  69.009 ms
10  10.33.0.82  77.203 ms  69.230 ms  69.315 ms
11  * * *
12  * * *
13  * * *
```

可以看到中断的点, 这里中断是因为我们集团广域网没开 `7002` 端口的策略, 所以到广域网直接断掉了

# 2. zabbix 配置

## 2.1 创建模板

选择链接的主机或者主机群组

![image-20231019161050562](https://image.lvbibir.cn/blog/image-20231019161050562.png)

## 2.2 创建应用集

![image-20231019165227390](https://image.lvbibir.cn/blog/image-20231019165227390.png)

## 2.3 创建监控项

![image-20231207151703881](https://image.lvbibir.cn/blog/image-20231207151703881.png)

八条链路都创建一下

![image-20231207151818203](https://image.lvbibir.cn/blog/image-20231207151818203.png)

在最新数据处看下键值获取是否正常

![image-20231207151953485](https://image.lvbibir.cn/blog/image-20231207151953485.png)

## 2.4 创建触发器

这里的表达式代表如果连续的两个值的最小值不为 0 则触发告警, 即连续两次值都不为 0 触发告警, 这是考虑到整体网络比较复杂, 网络波动可能会导致误报

![image-20231207152335550](https://image.lvbibir.cn/blog/image-20231207152335550.png)



八条链路分别添加一下触发器

![image-20231207152847941](https://image.lvbibir.cn/blog/image-20231207152847941.png)

## 2.5 配置告警动作

![image-20231207152936737](https://image.lvbibir.cn/blog/image-20231207152936737.png)

## 2.6 测试验证

我这里是找网络侧的同事中断了一下链路进行测试的, 各位可以自行选择适合自己的方法

![image-20231207153129294](https://image.lvbibir.cn/blog/image-20231207153129294.png)

## 2.7 添加聚合图形

最后可以添加一个聚合图形, 方便后续查看

在模板处添加图形

![image-20231207153341550](https://image.lvbibir.cn/blog/image-20231207153341550.png)

在 `监测中` -> `聚合图形` 处添加聚合图形, 三台主机, 选择一行显示出来

![image-20231207153748336](https://image.lvbibir.cn/blog/image-20231207153748336.png)

进入刚才创建的聚合图形, 选择右上角的编辑聚合图形, 然后点击 `更改` 添加图形

![image-20231207154620691](https://image.lvbibir.cn/blog/image-20231207154620691.png)

把三个节点都添加一下

![image-20231207154840761](https://image.lvbibir.cn/blog/image-20231207154840761.png)

最后将此聚合图形通过右上角的按钮添加到常用, 就可以在首页直接点击进来了

至此