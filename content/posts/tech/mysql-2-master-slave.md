---
title: "mysql (二) 主从复制原理 GTID 并行复制" 
date: 2022-05-03
lastmod: 2024-01-28
tags:
  - mysql
keywords:
  - mysql
description: "mysql 主从复制的详细原理, 主从复制模式, 主从复制方式, 以及 GTID 复制和并行复制" 
cover:
    image: "images/mysql.png" 
---

# 0 前言

本文参考以下链接:

- [【MySQL】主从复制实现原理详解](https://blog.nowcoder.net/n/b90c959437734a8583fddeaa6d102e43)

基于 `centos-7.9` `mysql-5.7.42`

mysql 安装参考 [mysql 系列文章](https://www.lvbibir.cn/tags/mysql)

# 1 主从复制原理

主从复制涉及到 3 个线程, 4 个文件

![v2-12f36a0aa2ea88020809173182e54e73_1440w](/images/v2-12f36a0aa2ea88020809173182e54e73_1440w.webp)

## 1.1 线程

master:

- log dump : 当 slave 连接 master 时, 主节点会为其创建一个 log dump 线程, 用于发送和读取 binlog 的内容. 在读取 binlog 中的操作时, log dump 线程会对主节点上的 binlog 加锁, 当读取完成, 在发送给从节点之前, 锁会被释放.

  主节点会为自己的每一个从节点创建一个 log dump 线程 .

slave:

- IO : 接受 master 发送的 binlog 文件位置的副本. 然后将数据的更新记录到 relaylog 中.
- SQL : 负责读取 relaylog 中的内容, 解析成具体的操作并执行, 最终保证主从数据的一致性

## 1.2 文件

master:

- binlog : 二进制文件, 记录库中的信息

slave:

- relaylog : 中继日志, 用来同步 master 的 binlog
- relaylog.info : 记录文件复制的进度.
- master.info : 存放 master 信息, 以及上次读取到的 master 同步过来的 binlog 的位置

## 1.3 详细步骤

- slave 执行 `change master to` 命令 ( master 的连接信息 + 复制的起点), 将以上信息记录到 master.info 文件
- slave 执行 `start slave` 命令,开启 IO 线程和 SQL 线程
- slave 的 IO 线程读取 master.info 文件中的信息, 获取到 IP, PORT, User, Pass, binlog 的位置信息
- slave 的 IO 线程请求连接 master, master 提供一个 log dump 线程, 负责和 IO 线程交互
- IO 线程根据 binlog 的位置信息 (mysql-bin.000004 , 444), 请求 master 新的 binlog
- master 通过 log dump 线程将最新的 binlog 传输给 slave 的 IO 线程
- IO 线程接收到新的 binlog 日志, 存储到 TCP/IP 缓存, 立即返回 ACK 给 master , 并更新 master.info
- IO 线程将 TCP/IP 缓存中的数据, 转储到磁盘 relaylog 中
- SQL 线程读取 relaylog.info 中的信息, 获取到上次已经应用过的 relaylog 的位置信息
- SQL 线程会按照上次的位置点回放最新的 relaylog, 再次更新 relaylog.info 信息
- slave 会自动 purge 应用过的 relaylog 进行定期清理

# 2 主从复制模式

mysql 默认一般为异步同步数据

## 2.1 全同步

当 mster 执行完一个事务, 然后所有的 slave 都复制了该事务并成功执行完才返回成功信息给客户端. 因为需要等待所有 slave 执行完该事务才能返回成功信息, 所以全同步复制的性能必然会收到严重的影响.

## 2.2 半同步

介于异步复制和全同步复制之间, master 在执行完客户端提交的事务后不是立刻返回给客户端, 而是等待至少一个 slave 接收到并写到 relaylog 中才返回成功信息给客户端 (只能保证 master 的 binlog 至少传输到了一个 slave 上, 但并不能保证 slave 将此事务执行更新到 db 中), 否则需要等待直到超时时间然后切换成异步模式再提交. 相对于异步复制, 半同步复制提高了数据的安全性, 一定程度的保证了数据能成功备份到 slave, 同时它也造成了一定程度的延迟, 但是比全同步模式延迟要低, 这个延迟最少是一个 TCP/IP 往返的时间. 所以, 半同步复制最好在低延时的网络中使用.

## 2.3 异步

master 不会主动推送 binlog 到 slave, master 在执行完客户端提交的事务后会立即将结果返给给客户端, 并不关心 slave 是否已经接收并处理, 这样就会有一个问题, master 如果崩溃掉了, 此时 master 上已经提交的事务可能并没有传到 slave 上, 如果此时, 强行将 slave 提升为 master, 可能导致新 master 节点上的数据不完整.

# 3 主从复制方式

MySQL 主从复制有三种方式: 基于 SQL 语句的复制 (statement-based replication, SBR), 基于行的复制 (row-based replication, RBR), 混合模式复制 (mixed-based replication, MBR). 对应的 bin-log 文件的格式也有三种: STATEMENT, ROW, MIXED

可通过如下命令查看 binlog 格式

```bash
SHOW VARIABLES LIKE "binlog_format";
```

## 3.1 SBR

就是记录 sql 语句在 bin-log 中, Mysql 5.1.4 及之前的版本都是使用的这种复制格式. 优点是只需要记录会修改数据的 sql 语句到 bin-log 中, 减少了 bin-log 日质量, 节约 I/O, 提高性能. 缺点是在某些情况下, 会导致主从节点中数据不一致 (比如 sleep(), now() 等).

## 3.2 RBR

mysql master 将 SQL 语句分解为基于 Row 更改的语句并记录在 bin-log 中, 也就是只记录哪条数据被修改了, 修改成什么样. 优点是不会出现某些特定情况下的存储过程、或者函数、或者 trigger 的调用或者触发无法被正确复制的问题. 缺点是会产生大量的日志, 尤其是修改 table 的时候会让日志暴增,同时增加 bin-log 同步时间. 也不能通过 bin-log 解析获取执行过的 sql 语句, 只能看到发生的 data 变更.

## 3.3 MBR

MySQL NDB cluster 7.3 和 7.4 使用的 MBR. 是以上两种模式的混合, 对于一般的复制使用 STATEMENT 模式保存到 bin-log, 对于 STATEMENT 模式无法复制的操作则使用 ROW 模式来保存, MySQL 会根据执行的 SQL 语句选择日志保存方式.

# 4 GTID 复制

在原来基于日志的复制中, slave 需要告知 master 要从哪个偏移量进行增量同步, 如果指定错误会造成数据的遗漏, 从而造成数据的不一致.

而基于 GTID 的复制中, slave 会告知 master 已经执行的事务的 GTID 的值, 然后 master 会将所有未执行的事务的 GTID 的列表返回给 slave. 并且可以保证同一个事务只在指定的 slave 执行一次. 通过全局的事务 ID 确定 slave 要执行的事务的方式代替了以前需要用 binlog 和 pos 点确定 slave 要执行的事务的方式.

GTID 是由 server_uuid 和事物 id 组成, 格式为: GTID=server_uuid:transaction_id. server_uuid 是在数据库启动过程中自动生成, 每台机器的 server-uuid 不一样. uuid 存放在数据目录的 auto.cnf 文件中，而 transaction_id 就是事务提交时系统顺序分配的一个不会重复的序列号

master 更新数据时, 会在事务前产生 GTID, 一起记录到 binlog 日志中. slave 的 IO 线程将变更的 binlog 写入到本地的 relaylog 中. SQL 线程从 relaylog 中获取 GTID, 然后对比本地 binlog 是否有记录 (所以 slave 必须要开启 binlog, 并且将 `log_slave_updates` 设置为 ON). 如果有记录，说明该 GTID 的事务已经执行, slave 会忽略. 如果没有记录, slave 就会从 relaylog 中执行该 GTID 的事务, 并记录到 binlog. 在解析过程中会判断是否有主键, 如果没有就用二级索引, 如果有就用全部扫描.

# 5 并行复制

master 大多数情况下都是多线程多客户端去写, 而 slave 只有一个 SQL 线程进行写, 无法避免地会出现主从复制的延迟问题, 并行复制可以指定线程数量, 从而提高 slave 写的速度.

在 mysql 5.6 版本之后引入了并行复制的概念

![img](/images/935163-20210702004720791-198956831.png)

通过上图我们可以发现其实所谓的并行复制, 就是在中间添加了一个分发的环节, 也就是说原来的 SQL 线程变成了现在的 coordinator 组件, 当 relaylog 日志更新后, coordinator 负责读取日志信息以及分发事务, 真正的执行过程是放在了 worker 线程上, 由多个线程并行的去执行.

```sql
# 查看并行的slave的线程的个数，默认是0.表示单线程
show global variables like 'slave_parallel_workers';
# 根据实际情况保证开启多少线程
set global slave_parallel_workers = 4;
# 设置并发复制的方式，默认是一个线程处理一个库，值为database
show global variables like '%slave_parallel_type%';
# 停止slave
stop slave;
# 设置属性值
set global slave_parallel_type='logical_check';
# 开启slave
start slave
# 查看线程数
show full processlist;
```

以上
