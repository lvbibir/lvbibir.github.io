---
title: "wordpress迁移到docker" 
date: 2021-08-01
lastmod: 2021-08-01
tags: 
- wordpress
- docker
- 博客搭建
keywords:
- wordpress
- docker
- docker compose
- 博客搭建
- 博客迁移
description: "记录从阿里云轻量应用服务器(wordpress应用)迁移到docker部署，并针对博客的一些优化" 
cover:
    image: "https://image.lvbibir.cn/blog/wordpress.jpg" 
---
# 前言

前段时间着手开始搭建自己的wordpress博客，刚开始图方便直接买了阿里云的轻量应用服务器，它是一套预先搭建好的lamp架构，并已经做了一些初始化配置，直接访问ip就可以进行wordpress的安装和配置了。

这套wordpress的一个非常好的优点就是可以在阿里云的控制台一键配置https证书，当然仅限在阿里云购买的ssl证书

![image-20210809155214499](https://image.lvbibir.cn/blog/image-20210809155214499.png)

后续还是决定将wordpress整体迁移到docker中，全部服务都用docker跑。这样只要数据做好持久化，使用docker的灵活性会好很多，做全站备份和迁移也很方便。

# 备份&迁移

wordpress迁移起来还是比较方便的，需要备份的内容大概有这些：插件、主题、uploads、数据库

备份插件：UpdraftPlus，这是一款个人使用过一款比较优秀的备份/迁移插件，免费版的功能基本满足大部分人需求，支持手动备份和定时备份、备份和恢复都支持部分备份，比如只备份数据库，只恢复数据库的某一张表。

免费版的并不支持wordpress迁移，但我们可以通过导入导出备份文件的方式实现站点迁移，前提是做好测试。

![image-20210817161111839](https://image.lvbibir.cn/blog/image-20210817161111839.png)

备份步骤：

1. 在备份插件中手动备份一次
2. 下载备份文件

迁移步骤：

1. 准备好系统环境和docker环境（docker-compose）
2. 启动docker容器
4. http访问wordpress地址初始化安装
5. 安装备份插件和ssl插件（really simple ssl）
6. 上传备份文件并进行恢复操作（不恢复wp-options表）
7. 为nginx反代服务器配置ssl证书，开启https访问
8. 在really simple ssl中为wordpress启用https
9. 恢复wp-options表

## 手动备份&下载备份文件

备份完之后可以直接从web端下载，但是建议从web端下载一份，通过ssh或者ftp等方式再下载一份，避免备份文件出现问题

![image-20210818095127218](https://image.lvbibir.cn/blog/image-20210818095127218.png)

备份的文件在`wordpress目录/wp-content/updraft`目录中

![image-20210818095405178](https://image.lvbibir.cn/blog/image-20210818095405178.png)

通过scp下载到本地

![image-20210818100025884](https://image.lvbibir.cn/blog/image-20210818100025884.png)

## 准备系统环境

安装好docker和docker-compose即可，docker的安装和使用教程在本博客中docker分类有

## docker-compose一键启动wordpress环境

这里我提供了一键部署的docker-compose文件和各服务进行了优化的配置文件，可以直接拿来用[下载链接](https://image.lvbibir.cn/blog/wordpress-blog.zip)

> 注意：
>
> 使用前建议修改数据库相关信息
>
> 建议不要随意改动ip
>
> 所有的数据文件和配置文件默认都在当前的目录下
>
> 如果前面不加nginx反代，记得把注释掉的端口映射改成自己想要的
>
> 所有的配置文件都在nginx目录下，已经预先定义好，可以自行进行修改
>
> 内置的wordpress目录权限用户和组是 33:tape

```yaml
version: '3.1'

services:

  proxy:
    image: superng6/nginx:debian-stable-1.18.0
    container_name: nginx-proxy
    restart: always
    networks:
      wordpress_net:
        ipv4_address: 172.19.0.6
    ports: 
      - 80:80
      - 443:443
    volumes:
      - /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime:ro
      - $PWD/conf/proxy/nginx.conf:/etc/nginx/nginx.conf
      - $PWD/conf/proxy/default.conf:/etc/nginx/conf.d/default.conf
      - $PWD/ssl:/etc/nginx/ssl
      - $PWD/logs/proxy:/var/log/nginx
    depends_on:
      - web

  web:
    image: superng6/nginx:debian-stable-1.18.0
    container_name: wordpress-nginx
    restart: always
    networks:
      wordpress_net:
        ipv4_address: 172.19.0.5
    volumes:
      - /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime:ro
      - $PWD/conf/nginx/nginx.conf:/etc/nginx/nginx.conf
      - $PWD/conf/nginx/default.conf:/etc/nginx/conf.d/default.conf
      - $PWD/conf/fastcgi.conf:/etc/nginx/fastcgi.conf
      - /dev/shm/nginx-cache:/var/run/nginx-cache
      # - $PWD/nginx-cache:/var/run/nginx-cache
      - $PWD/wordpress:/var/www/html
      - $PWD/logs/nginx:/var/log/nginx
    depends_on:
      - wordpress

  wordpress:
    image: wordpress:5-fpm
    container_name: wordpress-php
    restart: always
    networks:
      wordpress_net:
        ipv4_address: 172.19.0.4
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime:ro
      - $PWD/wordpress:/var/www/html
      - /dev/shm/nginx-cache:/var/run/nginx-cache
      # - $PWD/nginx-cache:/var/run/nginx-cache
      - $PWD/conf/uploads.ini:/usr/local/etc/php/php.ini
    depends_on:
      - redis
      - db

  redis:
    image: redis:5
    container_name: wordpress-redis
    restart: always
    networks:
      wordpress_net:
        ipv4_address: 172.19.0.3
    volumes:
      - /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime:ro
      - $PWD/redis-data:/data
    depends_on:
      - db
    
  db:
    image: mysql:5.7
    container_name: wordpress-mysql
    restart: always
    networks:
      wordpress_net:
        ipv4_address: 172.19.0.2
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
      MYSQL_RANDOM_ROOT_PASSWORD: '1'
    volumes:
      - /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime:ro
      - $PWD/mysql-data:/var/lib/mysql
      - $PWD/conf/mysqld.cnf:/etc/mysql/mysql.conf.d/mysqld.cnf


networks:
  wordpress_net:
    driver: bridge
    ipam:
     config:
       - subnet: 172.19.0.0/16

```

进入到 wordpress-blog 目录下使用` docker-compose up -d`启动docker容器

![image-20210819161800249](https://image.lvbibir.cn/blog/image-20210819161800249.png)

## 配置nginx反向代理

> 配置80和443端口的反代
>
> **把域名、证书路径以及后端服务器等信息换成自己的**

免费ssl证书的申请我在 [阿里云wordpress配置免费ssl证书](https://lvbibir.cn/archives/245) 中介绍过，直接下载nginx版的证书放到wordpress-blog/ssl/目录下即可

```nginx
[root@lvbibir ~]# vim wordpress-blog/conf/proxy/default.conf
server {
    listen 80;
    listen [::]:80;
    server_name lvbibir.cn;
    # return 301 https://$host$request_uri;
    location / {
        proxy_pass http://172.19.0.5:80;
        proxy_redirect off;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Real-Port $remote_port;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header HTTP_X_FORWARDED_FOR $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
        proxy_set_header X-NginX-Proxy true;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name lvbibir.cn;
    location / {
        proxy_pass http://172.19.0.5:80;
        proxy_redirect off;
        # 保证获取到真实IP
        proxy_set_header X-Real-IP $remote_addr;
        # 真实端口号
        proxy_set_header X-Real-Port $remote_port;
        # X-Forwarded-For 是一个 HTTP 扩展头部。
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # 在多级代理的情况下，记录每次代理之前的客户端真实ip
        proxy_set_header HTTP_X_FORWARDED_FOR $remote_addr;
        # 获取到真实协议
        proxy_set_header X-Forwarded-Proto $scheme;
        # 真实主机名
        proxy_set_header Host $host;
        # 设置变量
        proxy_set_header X-NginX-Proxy true;
        # 开启 brotli
        proxy_set_header Accept-Encoding "gzip";
    }

    # 日志
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;
    # 证书
    ssl_certificate /etc/nginx/ssl/lvbibir.cn.pem;
    ssl_certificate_key /etc/nginx/ssl/lvbibir.cn.key;

    # curl https://ssl-config.mozilla.org/ffdhe2048.txt > /path/to/dhparam
    # ssl_dhparam /etc/nginx/ssl/dhparam;

    # HSTS (ngx_http_headers_module is required) (63072000 seconds)
    add_header Strict-Transport-Security "max-age=63072000" always;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;

    # verify chain of trust of OCSP response using Root CA and Intermediate certs
    # ssl_trusted_certificate  /etc/nginx/ssl/all.sleele.com/fullchain.cer;
    # replace with the IP address of your resolver
    resolver 223.5.5.5;
    resolver_timeout 5s;
}

[root@lvbibir ~]# docker exec -i nginx-proxy nginx -s reload
```

## 安装wordpress



现在已经可以通过http访问nginx反代的80端口访问wordpress了

![image-20210818103413991](https://image.lvbibir.cn/blog/image-20210818103413991.png)



安装信息跟之前站点设置一样即可

![image-20210818103606977](https://image.lvbibir.cn/blog/image-20210818103606977.png)



## 恢复备份

![image-20210818103904446](https://image.lvbibir.cn/blog/image-20210818103904446.png)

安装好之后启用插件，把备份文件上传到备份目录

![image-20210818104212233](https://image.lvbibir.cn/blog/image-20210818104212233.png)

记得修改权限

```
[root@lvbibir ~]# chown -R 33:tape wordpress-blog/wordpress/wp-content/
```

恢复备份

注：如果站点之前开启了https，在这步不要恢复wp-options表，不然会导致后台访问不了

![image-20210818104414236](https://image.lvbibir.cn/blog/image-20210818104414236.png)



![image-20210818104436603](https://image.lvbibir.cn/blog/image-20210818104436603.png)





![image-20210818104500067](https://image.lvbibir.cn/blog/image-20210818104500067.png)

点击恢复即可

## 配置ssl

启用 really simple ssl 插件，因为之前在nginx反代配置了ssl证书，虽然我们没有通过https访问，但是这个插件已经检测到了证书，可以一键为wordpress配置ssl

![image-20210818110929227](https://image.lvbibir.cn/blog/image-20210818110929227.png)

这里我们已经可以通过https访问我们的wordpress了

![image-20210818111202110](https://image.lvbibir.cn/blog/image-20210818111202110.png)

站点路径该插件也会自动修改，之前不恢复wp-options表的原因就在这，在我们没有配置好ssl之前，直接覆盖wordpress的各项设置会导致站点访问不了，重定向循环等各种各样的问题。

![image-20210818111238643](https://image.lvbibir.cn/blog/image-20210818111238643.png)

## 恢复 wp-options 表

开启了ssl之后，通过备份插件再恢复一次，可以只恢复一张wp-options表，也可以再全量恢复下数据库，至此，站点迁移工作基本完成了。

# 后续优化

## 开启https强制跳转

开启https强制跳转后，所有使用http访问我们站点的请求都会转到https，提高站点安全性

```nginx
[root@lvbibir ~]# vim /etc/nginx/nginx.conf

server {
    listen 80;
    listen [::]:80;
    server_name lvbibir.cn;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name lvbibir.cn;
    location / {
        proxy_pass http://172.19.0.5:80;
        proxy_redirect off;
        # 保证获取到真实IP
        proxy_set_header X-Real-IP $remote_addr;
        # 真实端口号
        proxy_set_header X-Real-Port $remote_port;
        # X-Forwarded-For 是一个 HTTP 扩展头部。
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # 在多级代理的情况下，记录每次代理之前的客户端真实ip
        proxy_set_header HTTP_X_FORWARDED_FOR $remote_addr;
        # 获取到真实协议
        proxy_set_header X-Forwarded-Proto $scheme;
        # 真实主机名
        proxy_set_header Host $host;
        # 设置变量
        proxy_set_header X-NginX-Proxy true;
        # 开启 brotli
        proxy_set_header Accept-Encoding "gzip";
    }

    # 日志
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;
    # 证书
    ssl_certificate /etc/nginx/ssl/lvbibir.cn.pem;
    ssl_certificate_key /etc/nginx/ssl/lvbibir.cn.key;

    # curl https://ssl-config.mozilla.org/ffdhe2048.txt > /path/to/dhparam
    # ssl_dhparam /etc/nginx/ssl/dhparam;

    # HSTS (ngx_http_headers_module is required) (63072000 seconds)
    add_header Strict-Transport-Security "max-age=63072000" always;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;

    # verify chain of trust of OCSP response using Root CA and Intermediate certs
    # ssl_trusted_certificate  /etc/nginx/ssl/all.sleele.com/fullchain.cer;
    # replace with the IP address of your resolver
    resolver 223.5.5.5;
    resolver_timeout 5s;
}


[root@lvbibir ~]# docker exec -i nginx-proxy nginx -s reload
```

## 开启redis缓存

[wordpress搭配redis加速网站访问速度](https://sleele.com/2020/03/29/wordpress%e6%90%ad%e9%85%8dredis%e5%8a%a0%e9%80%9f%e7%bd%91%e7%ab%99%e8%ae%bf%e9%97%ae%e9%80%9f%e5%ba%a6/)

## 搭配jsdelivr-CDN实现全站cdn

[WordPress+jsDelivr开启伪全站CDN](https://sleele.com/2020/05/09/wordpressjsdelivr-伪全站cdn/)

# 参考

[从能用到好用-快速搭建高性能WordPress指南](https://sleele.com/2021/02/26/best-wordpress-deployment-guide/)

