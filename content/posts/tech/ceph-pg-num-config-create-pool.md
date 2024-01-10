---
title: "ceph创建pool时pg_num的配置" 
date: 2022-02-01
lastmod: 2022-02-01
tags: 
- ceph
keywords:
- linux
- ceph
description: "介绍在ceph集群创建pool时pb_num参数如何配置以及较为通用的取值" 
cover:
    image: "https://image.lvbibir.cn/blog/ceph.png" 
---

# pg_num

用此命令创建存储池时：

```textile
ceph osd pool create {pool-name} pg_num
```

确定 pg_num 取值是强制性的，因为不能自动计算。常用的较为通用的取值：

- 少于 5 个 osd，pg_num 设置为 128
- osd 数量在 5 到 10 个时，pg_num 设置为 512
- osd 数量在 10 到 50 个时，pg_num = 4096
- osd 数量大于 50 是，需要理解 ceph 的权衡算法，自己计算 pg_num 取值
- 自行计算 pg_num 取值时可使用 ceph 配套的 pg_num 取值工具 pgcalc（<https://old.ceph.com/pgcalc/>）

# 参考

<https://www.cnblogs.com/varden/p/13921172.html>
