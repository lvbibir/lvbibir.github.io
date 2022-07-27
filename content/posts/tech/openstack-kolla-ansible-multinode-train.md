---
title: "kolla-ansible部署多节点openstack（Train版）" 
date: 2022-06-01
lastmod: 2022-06-01
author: ["lvbibir"] 
categories: 
- 
tags: 
- openstack
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
    image: "" #图片路径：posts/tech/文章1/picture.png
    caption: "" #图片底部描述
    alt: ""
    relative: false
---
# 添加节点

管理防火墙及selinux

安装docker-ce

提前下载docker镜像

修改网卡名称

修改主机名

配置ssh免密

```
kolla-ansible -i ./multinode bootstrap-servers --limit node135
kolla-ansible -i ./multinode prechecks --limit node135
kolla-ansible -i ./multinode deploy --limit node135
```

# 参考

https://blog.csdn.net/qq_33316576/article/details/107457111

https://blog.csdn.net/networken/article/details/106745167