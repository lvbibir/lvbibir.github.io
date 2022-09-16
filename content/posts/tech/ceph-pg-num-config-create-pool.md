---
title: "ceph创建pool时pg_num的配置" 
date: 2022-02-01
lastmod: 2022-02-01
tags: 
- linux
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

```
ceph osd pool create {pool-name} pg_num
```

确定pg_num取值是强制性的，因为不能自动计算。常用的较为通用的取值：

- 少于5个osd，pg_num设置为128
- osd数量在 5 到 10 个时，pg_num设置为512
- osd数量在 10 到 50 个时，pg_num = 4096
- osd数量大于50是，需要理解ceph的权衡算法，自己计算pg_num取值
- 自行计算pg_num取值时可使用ceph配套的pg_num取值工具 pgcalc（https://old.ceph.com/pgcalc/）



# 参考

https://www.cnblogs.com/varden/p/13921172.html