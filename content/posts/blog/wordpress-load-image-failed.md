---
title: "wordpress | 加载图片失败" 
date: 2021-07-01
lastmod: 2024-01-28
tags:
  - wordpress
  - 博客搭建
keywords:
  - wordpress
  - ssl
  - https
description: "" 
cover:
    image: "images/logo-wordpress.jpg" 
---

# 1 现象

- 博客加载不出来我在七牛云的图片资源
- 使用浏览器直接访问图片 url 却是可以成功的
- 我将之前 csdn 的博客迁移到了 wordpress，图片外链地址就是 csdn 的，都可以正常加载。

![image-20210722140511459](/images/image-20210722140511459.png)

![image-20210722140632949](/images/image-20210722140632949.png)

使用浏览器直接访问图片 url 却是可以成功的

![image-20210722140852643](/images/image-20210722140852643.png)

我将之前 csdn 的博客迁移到了 wordpress，图片外链地址就是 csdn 的，都可以正常加载。

![image-20210722141709373](/images/image-20210722141709373.png)

# 2 排查

1、由于浏览器直接访问七牛云图床的 url 地址是可以访问的，证明地址并没错，有没有可能是 referer 防盗链的配置问题

查看防盗链配置，并没有开

![image-20210722142153981](/images/image-20210722142153981.png)

2、wordpress 可以加载出来 csdn 的外链图片，期间也试了其他图床都是没问题的。

3、看看七牛的图片外链和 csdn 的有何区别

注意到七牛的图片外链是 http，当时嫌麻烦并没有配置 https，看来问题是出在这了

![image-20210722143457886](/images/image-20210722143457886.png)

因为我的网站配置了 ssl 证书，可能由于安全问题浏览器不予加载 http 项目，用 http 访问站点测试下图片是否可以加载

![image-20210722143758890](/images/image-20210722143758890.png)

访问成功了！

# 3 解决

给图床服务器安装 ssl 证书，开启 https 访问，参考：[typora-picgo-qiniu-upload-image](https://www.lvbibir.cn/posts/blog/typora-picgo-qiniu-upload-image/)

以上
