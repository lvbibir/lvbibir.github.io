---
title: "markdown 图片存储方案 | typora + picgo + 七牛云"
date: 2021-07-01
lastmod: 2024-01-28
tags:
  - 博客搭建
keywords:
  - markdown
  - typora
  - picgo
  - 七牛云
  - https
  - ssl
description: "在使用 markdown 写作的过程中，图片的存储是困扰很多人的一个问题，分享下我目前采用的 typora + picgo + 七牛云 的图床配置流程"
cover:
    image: "images/cover-default.webp"
---

# 1 七牛云配置

## 1.1 注册七牛云，新建存储空间

七牛云新用户有 10G 的免费空间，作为个人博客来说基本足够了

## 1.2 为存储空间配置加速域名

![image-20210722111948353](/images/image-20210722-121833.png)

## 1.3 配置 https 证书

### 1.3.1 购买免费证书

![image-20210722144416642](/images/image-20210722-144416.png)

![image-20210722144429953](/images/image-20210722-144429.png)

### 1.3.2 补全域名信息

![image-20210722144515614](/images/image-20210722-144515.png)

![image-20210722145538079](/images/image-20210722-145538.png)

### 1.3.3 域名验证

根据在域名提供商处新建解析

dns 配置好之后等待 CA 机构审核后颁发证书就可以了

![image-20210722152240625](/images/image-20210722-152240.png)

![image-20210722153133297](/images/image-20210722-153133.png)

### 1.4.4 开启 https

![image-20210722153339766](/images/image-20210722-153339.png)

# 2 PicGo 配置

## 2.1 下载安装

下载链接：<https://github.com/Molunerfinn/PicGo/releases/>

建议下载稳定版

![image-20210722111023745](/images/image-20210722-121831.png)

## 2.2 配置七牛云图床

ak 和 sk 在七牛云→个人中心→密钥管理中查看

![image-20210722121639391](/images/image-20210722-121834.png)

在 picgo 端配置各项信息，注意网址要改成 https

![image-20210722112127613](/images/image-20210722-121835.png)

# 3 typora 测试图片上传

下载地址：<https://www.typora.io/>

在文件→偏好设置→图像中配置图片上传，选择安装好的 PicGo 的应用程序

![image-20210722112417378](/images/image-20210722-121836.png)

点击验证图片上传

![image-20210722112645385](/images/image-20210722-121837.png)

到七牛云存储空间看是否有这两个文件

![image-20210722112812563](/images/image-20210722-121838.png)

typora 可以实现自动的图片上传，并将本地连接自动转换为外链地址

![image-20210722121155935](/images/image-20210722-121839.png)

![image-20210722121519040](/images/image-20210722-121519.png)

# 4 可能的报错

一般报错原因都可在 picgo 的日志文件找到，路径：`C:\Users\username\AppData\Roaming\picgo`

## 4.1 failed to fetch

![image-20210721100740621](/images/image-20210721-100850.png)

日志报错如下

![image-20210721100850294](/images/image-20210721-102004.png)

问题在于端口冲突，如果你打开了多个 picgo 程序，就会端口冲突，picgo 自动帮你把 36677 端口改为 366771 端口，导致错误。

![image-20210721102004403](/images/image-20210721-101018.png)

重新验证

![image-20210721101039272](/images/image-20210721-100740.png)

以上
