---
title: "ceph创建pool时pg_num的配置" 
date: 2022-02-01
lastmod: 2022-02-01
author: ["lvbibir"] 
categories: 
- 
tags: 
- ceph
description: "" 
weight: 
slug: ""
draft: false # 是否为草稿
comments: true #是否展示评论
showToc: true # 显示目录
TocOpen: true # 自动展开目录
hidemeta: false # 是否隐藏文章的元信息，如发布日期、作者等
disableShare: true # 底部不显示分享栏
showbreadcrumbs: true #顶部显示当前路径
cover:
    image: "https://image.lvbibir.cn/blog/Snipaste_2022-09-14_16-02-26.png" #图片路径：posts/tech/文章1/picture.png
    caption: "" #图片底部描述
    alt: ""
    relative: false
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