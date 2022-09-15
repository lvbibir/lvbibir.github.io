---
title: "wordpress加载图片失败" 
date: 2021-07-01
lastmod: 2021-07-01
tags: 
- wordpress
keywords:
- wordpress
- ssl
- https
description: "" 
cover:
    image: "https://image.lvbibir.cn/blog/wordpress.jpg" 
---
# 现象

- 博客加载不出来我在七牛云的图片资源
- 使用浏览器直接访问图片url却是可以成功的
- 我将之前csdn的博客迁移到了wordpress，图片外链地址就是csdn的，都可以正常加载。

![image-20210722140511459](https://image.lvbibir.cn/blog/image-20210722140511459.png)

![image-20210722140632949](https://image.lvbibir.cn/blog/image-20210722140632949.png)

使用浏览器直接访问图片url却是可以成功的

![image-20210722140852643](https://image.lvbibir.cn/blog/image-20210722140852643.png)

我将之前csdn的博客迁移到了wordpress，图片外链地址就是csdn的，都可以正常加载。

![image-20210722141709373](https://image.lvbibir.cn/blog/image-20210722141709373.png)

# 排查

1、由于浏览器直接访问七牛云图床的url地址是可以访问的，证明地址并没错，有没有可能是referer防盗链的配置问题

查看防盗链配置，并没有开

![image-20210722142153981](https://image.lvbibir.cn/blog/image-20210722142153981.png)

2、wordpress可以加载出来csdn的外链图片，期间也试了其他图床都是没问题的。

3、看看七牛的图片外链和csdn的有何区别

注意到七牛的图片外链是http，当时嫌麻烦并没有配置https，看来问题是出在这了

![image-20210722143457886](https://image.lvbibir.cn/blog/image-20210722143457886.png)

因为我的网站配置了ssl证书，可能由于安全问题浏览器不予加载http项目，用http访问站点测试下图片是否可以加载

![image-20210722143758890](https://image.lvbibir.cn/blog/image-20210722143758890.png)

访问成功了！

# 解决

给图床服务器安装ssl证书，开启https访问，参考：[typora-picgo-qiniu-upload-image](https://www.lvbibir.cn/posts/blog/typora-picgo-qiniu-upload-image/)



