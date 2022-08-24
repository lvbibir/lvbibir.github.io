---
title: "H3C服务器配置raid" 
date: 2021-08-01
lastmod: 2021-08-01
author: ["lvbibir"] 
categories: 
- 
tags: 
- linux
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
1、进入bios修改启动模式，将 UEFI 改为 Legacy bios

2、 重启服务器，ctrl + r 进入 lsi 阵列卡管理

![img](https://image.lvbibir.cn/blog/image004(08-26-10-12-53).jpg)

3、选择对应阵列卡

![img](https://image.lvbibir.cn/blog/image005(08-26-10-12-53).jpg)

4、配置逻辑盘

![img](https://image.lvbibir.cn/blog/image006(08-26-10-12-53).jpg)

5、配置完逻辑盘后可以选择从某一块逻辑盘启动

Ctrl-P 进入到ctrl mgmt. -> TAB切换到boot device

![img](https://image.lvbibir.cn/blog/image007(08-26-10-12-53).jpg)

回车后可以看到当前的逻辑盘，上下选择要引导的逻辑盘即可。

![img](https://image.lvbibir.cn/blog/image008(08-26-10-12-53).jpg)

Apply保存退出完成。

![img](https://image.lvbibir.cn/blog/image009(08-26-10-12-53).jpg)

