---
title: "wordpress配置免费ssl证书和https强制跳转" 
date: 2021-07-01
lastmod: 2021-07-01
tags: 
- wordpress
- 博客搭建
keywords:
- wordpress
- 阿里云
- ssl
- https
- apache
- 伪静态
- Rewrite
description: "介绍如何为阿里轻量应用服务器(wordpress应用)配置ssl证书，开启https访问且实现https强制跳转" 
cover:
    image: "https://image.lvbibir.cn/blog/wordpress.jpg" 
---
# 配置ssl证书

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

# 配置https强制跳转

一般站点需要在httpd.conf中的`<VirtualHost *:80> </VirtualHost>`中配置重定向

wordpress不同，需要在伪静态文件（.htaccess）中配置重定向，无需在httpd.conf中配置

## 修改伪静态文件（.htaccess）

伪静态文件一般在网页根目录，是一个隐藏文件

![image-20210730101401874](https://image.lvbibir.cn/blog/image-20210730101401874.png)

在`#END Wordpress`前添加如下重定向代码，**记得把域名修改成自己的**

```
RewriteEngine On
RewriteCond %{HTTPS} !on
RewriteRule ^(.*)$ https://lvbibir.cn/%{REQUEST_URI} [L,R=301]
```

图中两段重定向代码略有不同

- 第一段代码重定向触发器：**当访问的端口不是443时进行重定向**重定向规则：**重定向到：https://{原域名}/{原url资源}**
- 第二段代码重定向触发器：**当访问的协议不是 TLS/SLL（https）时进行重定向**重定向规则：**重定向到：https://lvbibir.cn/{原url资源}**
- 第一段代码使用端口判断，第二段代码通过访问方式判断，建议使用访问方式判断，这样服务改了端口也可以正常跳转
- 第一段代码重定向的原先的域名，第二段代码可以把ip地址重定向到指定域名

![image-20210730152548351](https://image.lvbibir.cn/blog/image-20210730152548351.png)

## 测试

```
curl -I http://lvbibir.cn
```

![image-20210730153518000](https://image.lvbibir.cn/blog/image-20210730153518000.png)

使用http访问站点的80端口成功通过301跳转到了https

# 参考

https://help.aliyun.com/document_detail/98727.html?spm=5176.smartservice_service_chat.0.0.1508709aJMmZwg

https://blog.csdn.net/weixin_39037804/article/details/102801202
