---
title: "mysql | 线程上限问题处理" 
date: 2025-04-22
lastmod: 2025-04-22
tags:
  - mysql
keywords:
  - mysql
  - thread
description: "由于系统 systemd 限制导致 mysql 可创建的线程数达到上限, 出现无法登陆等问题" 
cover:
    image: "images/logo-mysql.png" 
---

# 0 前言

前段时间应业务需求, 在 suse12sp5 系统上部署了一套 Mysql 8 数据库, 刚开始运行良好, 随着依赖此数据库的功能越来越多, 开发同事反应在应用连接数据库时频繁报错:

```plaintext
[HY000][1135] null, message from server: "Can't create a new thread (errno 11); if you are not out of available memory, you can consult the manual for a possible OS-dependent bug"
```

在数据库服务器使用 root 账户登陆报相同错误, 同时在 mysql 错误日志有大量 innodb 无法创建扫描线程的报错

```plaintext
2025-04-21T22:10:29.220410+08:00 381 [Warning] [MY-013526] [InnoDB] Resource not available to create threads for parallel scan. Falling back to single thread mode.
```

# 1 排查过程

可以看到报错中明确指出了可能是由于内存不足, 遂排查服务器内存占用情况, 但是服务器内存压力很小, 不存在 oom 的问题

mysql 这类资源问题大多是因为 max_connections 的参数配置过小, 请开发人员关停一部分服务释放线程我们登陆 Mysql 进行排查

```sql
SHOW VARIABLES LIKE 'max_connections'; ---3000
```

初始配置已经比较合理, 该参数配置为 3000

继续向下排查, 在查阅相关资料的时候发现了 [这篇文章](https://blog.csdn.net/ihero/article/details/127850954), `Max_used_connections` 达到 `max_connections` 数值的 10% - 85% 比较合理

```sql
SHOW STATUS LIKE 'Threads_connected';     --- 目前已连接的线程
SHOW STATUS LIKE 'Max_used_connections';  --- 启动以来使用的最大链接数
SHOW VARIABLES LIKE 'max_connections';    --- 链接数上限
--- 三个值分别为 472 473 3000
```

mysql 链接数是完全够用的, 那可能是优化没有做好导致 mysql 无法支持更多连接, 遂进行如下性能优化

1. `ulimit -a` 发现系统默认配置为 1024, 在系统 `/etc/security/limits.conf` 中配置 ulimit 之后重启服务器.

    ```plaintext
    * soft nofile 65535
    * hard nofile 65535
    * soft nproc 65535
    * hard nproc 65535
    ```

2. 系统内核线程限制

    ```bash
    # Mysql 当前的线程数
    ps -T -p $(pgrep mysqld) | wc -l
    cat /proc/sys/kernel/threads-max
    cat /proc/sys/kernel/pid_max
    echo 65535 > /proc/sys/kernel/threads-max
    echo 4194304 > /proc/sys/kernel/pid_max
    ```

3. mysql systemd 配置

    ```bash
    systemctl status mysql
    vim /usr/lib/systemd/system/mysql.service
    
    # [service] 下添加如下配置
    LimitNOFILE = 65535
    LimitNPROC = 8192
    LimitSTACK = 512K
    
    systemctl daemon-reload
    systemctl restart mysql
    ```

4. msyql service 配置, 添加或修改如下参数

    ```plaintext
    [mysqld]
    thread_stack = 192K
    sort_buffer_size = 256K
    read_buffer_size = 256K
    read_rnd_buffer_size = 256K
    ```

此时博主心态已经快崩溃了, 服务器重启了, Mysql 服务也重启了很多次, 想到的系统限制或者性能优化的地方都做过了, 报错依然是频频出现.

只好整理思路从头开始, 在观察 Mysql Status 数据的时候发现一个小细节, `Max_used_connections` 和 `Threads_connected` 这个值永远保持在 `472-473` !!!!!!!

思路一下就明确了, 联想到刚才在系统上查看 Mysql 的线程数, 发现这个值一直是 512

```bash
ps -T -p $(pgrep mysqld) | wc -l
```

所以并不是性能优化或者 Mysql 本身的配置有问题, 一定是某一项系统配置, 限制死了 Mysql service 能创建的线程数

按照这个思路去问各大 AI, 通义/豆包/DS 给出的结果都跟我之前的排查过程相差不多, 没有找到问题点, 最后还是 DS 出世后被大家淡忘的 ChatGPT 给出了解决方案

![](/images/image-20250422-111334.png)

执行后, 结果是 512, 跟上文在系统上查看到的 Mysql 线程数一致, 那就是这里的问题了

```bash
cat /sys/fs/cgroup/pids/system.slice/mysql.service/pids.max
```

# 2 解决方案

修改 Mysql service 的 systemd 配置文件

```bash
vim /usr/lib/systemd/system/mysql.service

# 在 [Service] 块添加或修改
TasksMax = infinity

systemctl daemon-reload
systemctl restart mysql
```

以上.
