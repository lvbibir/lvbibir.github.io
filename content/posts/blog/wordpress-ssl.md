---
title: "阿里云wordpress配置免费ssl证书" 
date: 2021-07-01
lastmod: 2021-07-01
author: ["lvbibir"] 
categories: 
- 
tags: 
- wordpress
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
1、登录阿里云，选择产品中的ssl证书

![image-20210722101058428](https://image.lvbibir.cn/blog/image-20210722101058428.png)

![image-20210722101227085](https://image.lvbibir.cn/blog/image-20210722101823832.png)

![image-20210722101412400](https://image.lvbibir.cn/blog/image-20210722101412400.png)

![image-20210722101823832](https://image.lvbibir.cn/blog/image-20210722102007056.png)

![image-20210722101908523](https://image.lvbibir.cn/blog/image-20210722101908523.png)

![image-20210722102007056](https://image.lvbibir.cn/blog/image-20210722102536194.png)

如果域名是阿里的他会自动创建dns解析，如果是其他厂商需要按照图片配置，等待几分钟进行验证

![image-20210722102536194](https://image.lvbibir.cn/blog/image-20210722103005297.png)

![image-20210722102208389](https://image.lvbibir.cn/blog/image-20210722101227085.png)

点击审核，等待签发

![image-20210722103005297](https://image.lvbibir.cn/blog/image-20210722102208389.png)

签发后根据需求下载所需证书

![image-20210722104732852](https://image.lvbibir.cn/blog/image-20210722104550144.png)

我的wordpress是直接买的阿里轻量应用服务器，打开轻量应用服务器的控制台配置域名

![image-20210722104550144](https://image.lvbibir.cn/blog/image-20210722104732852.png)

选择刚申请好的ssl证书

![image-20210722104631428](https://image.lvbibir.cn/blog/image-20210722104631428.png)

在wordpress后台修改地址

![image-20210722104952260](https://image.lvbibir.cn/blog/image-20210722104952260.png)

大功告成

