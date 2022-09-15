---
title: "kolla-ansible部署Train版openstack（multinode）" 
date: 2022-06-01
lastmod: 2022-06-01
categories: 
- 
tags: 
- openstack
description: "介绍cenots中使用kolla-ansible+docker的方式快速部署openstack(multinode)集群式" 
cover:
    image: "https://image.lvbibir.cn/blog/20200613094347844.png" 
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