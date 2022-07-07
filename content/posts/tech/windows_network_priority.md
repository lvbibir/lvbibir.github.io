---
title: "windows双网卡时设置网络优先级" #标题
date: 2022-06-01T00:00:00+08:00 #创建时间
lastmod: 2022-06-01T00:00:00+08:00 #更新时间
author: ["lvbibir"] #作者
categories: 
- 
tags: 
- windows
description: "" #描述
weight: # 输入1可以顶置文章，用来给文章展示排序，不填就默认按时间排序
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
# 前言

仅在win10测试可用

在工作中需要连接公司内网（有线，不可联网），访问外网时需要连接无线

同时接入这两个网络时，内网访问正常，外网无法访问。

此时可以通过调整网络优先级及配置路由实现内外网同时访问



>  一般来说，内网的网段数量较少，我们可以配置使默认路由走外网，走内网时通过配置的路由走

# 调整网络优先级

查看默认路由

```powershell
route print 0.0.0.0
```

![image-20220426100126587](http://image.lvbibir.cn/blog/image-20220426100126587.png)

这两个路由分别是内网和外网的默认路由，绝大部分情况网络都是走的默认路由，但这里有两条默认路由，默认路由的优先级是按照跃点数的多少决定的，跃点数越少，优先级越高

通过tracert命令测试下

![image-20220427095601804](http://image.lvbibir.cn/blog/image-20220427095601804.png)

此时访问外网默认走内网网卡，自然是不通的。

将外网无线的跃点数调小点再试试

![image-20220427095904443](http://image.lvbibir.cn/blog/image-20220427095904443.png)

route print可以看到跃点数修改成功了，此时外网无线的跃点数更小，优先级更高

![image-20220427100101830](http://image.lvbibir.cn/blog/image-20220427100101830.png)

tracert&ping再试一下

![image-20220427100403307](http://image.lvbibir.cn/blog/image-20220427100403307.png)

# 配置路由

配置路由需要以管理员权限运行powershell或者cmd

![image-20220427100911342](http://image.lvbibir.cn/blog/image-20220427100911342.png)

配置路由后，内网访问也没有问题了

```powershell
route add 172.16.2.0 mask 255.255.255.0 172.30.4.254 metric 3
route add 172.16.3.0 mask 255.255.255.0 172.30.4.254 metric 3
route add 172.16.4.0 mask 255.255.255.0 172.30.4.254 metric 3
```

这里配置的路由重启系统后会消失，加 `-p`选项设置为永久路由

```powershell
route add -p 172.16.2.0 mask 255.255.255.0 172.30.4.254 metric 3
```

![image-20220427101256061](http://image.lvbibir.cn/blog/image-20220427101256061.png)
