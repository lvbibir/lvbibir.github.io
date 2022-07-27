---
title: "wordpress文章编辑页和发不出来内容不一样（http变成了https）" 
date: 2021-07-01
lastmod: 2021-07-01
author: ["lvbibir"] 
categories: 
- 
tags: 
- wordpress
- http
- https
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
文章编辑界面和预览界面都是没问题的，发布出来后文章内容的http变成了https，而且仅有本博客域名lvbibir.cn出现这种情况，其他都正常

![image-20210730141923357](https://image.lvbibir.cn/blog/image-20210730141923357.png)

发布后：

![image-20210730141947018](https://image.lvbibir.cn/blog/image-20210730141947018.png)

初步判断是由于在wordpress的伪静态文件中配置了http强制跳转导致的

![image-20210730142044368](https://image.lvbibir.cn/blog/image-20210730142044368.png)

