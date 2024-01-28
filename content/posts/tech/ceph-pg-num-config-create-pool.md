---
title: "ceph | pool pg_num 配置" 
date: 2022-02-01
lastmod: 2024-01-27
tags:
  - ceph
keywords:
  - linux
  - ceph
description: "介绍在 ceph 集群创建 pool 时 pg_num 参数如何配置以及较为通用的取值" 
cover:
    image: "https://image.lvbibir.cn/blog/ceph.png" 
---

# 0 前言

本文参考以下链接

- [Ceph 存储池 pg_num 配置详解](https://www.cnblogs.com/varden/p/13921172.html)

# 1 pg_num

用此命令创建存储池时：

```plaintext
ceph osd pool create {pool-name} pg_num
```

确定 pg_num 取值是强制性的，因为不能自动计算。常用的较为通用的取值：

- 少于 5 个 osd，pg_num 设置为 128
- osd 数量在 5 到 10 个时，pg_num 设置为 512
- osd 数量在 10 到 50 个时，pg_num = 4096
- osd 数量大于 50 是，需要理解 ceph 的权衡算法，自己计算 pg_num 取值
- 自行计算 pg_num 取值时可使用 ceph 配套的 pg_num 取值工具 [pgcalc](https://old.ceph.com/pgcalc)
