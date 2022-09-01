---
title: "【置顶】Hello,hugo!"
date: 2022-07-06
lastmod: 2022-07-08
author: ["lvbibir"] 
categories: 
- 
tags: 
- hugo
description: ""
weight: 1
slug: ""
draft: false # 是否为草稿
comments: true #是否展示评论
showToc: true # 显示目录
TocOpen: true # 自动展开目录
hidemeta: false # 是否隐藏文章的元信息，如发布日期、作者等
disableShare: true # 底部不显示分享栏
showbreadcrumbs: true #顶部显示当前路径
cover:
    image: "https://image.lvbibir.cn/blog/hugo-logo-wide.svg"
    caption: ""
    alt: ""
    relative: false
---

# 前言

记录 wordpress 迁移至 hugo+[papermod](https://github.com/adityatelange/hugo-PaperMod) 的过程，大多参考[sulv大佬](https://www.sulvblog.cn/)的博客，本文更偏向于个人备忘，并不是一篇很合格的教程

# 博客流水线

## 编辑文章

采用 typora + picgo + 七牛云图床流程，[参考文章](https://www.lvbibir.cn/posts/blog/typora-picgo-qiniu-upload-image/)

## 生成静态文件

```
hugo -F --cleanDestinationDir
```

后面两个参数表示会先删除之前生成的 public 目录，保证每次生成的 public 都是新的

## 上传静态文件

~~[mobaxterm](https://mobaxterm.mobatek.net/) 是我一直以来的主力终端，它的本地终端自带了很多linux命令，用`rsync`命令上传静态文件至阿里服务器，且会先删除服务器上之前的静态文件，保证博客的内容保持最新~~

将 mobaxterm 的命令添加到用户环境变量中，以实现 `git bash` 、 `vscode` 、以及 `windows terminal` 中运行一些 mobaxterm 本地终端附带的命令，也就无需再专门打开一次 mobaxterm 去上传文件了

```
rsync -avuz --progress --delete public/ root@lvbibir.cn:/root/wordpress-blog/hugo-public/
```

## 归档备份

研究 hugo 建站之初是打算采用 github pages 来发布静态博客

- 优点
- - 仅需一个github账号和简单配置即可将静态博客发布到 github pages
  - 没有维护的时间成本，可以将精力更多的放到博客内容本身上去
  - 无需备案
  - 无需ssl证书
- 缺点
- - 访问速度较慢
  - 访问速度较慢
  - 访问速度较慢

虽说访问速度较慢可以通过各家的cdn加速来解决，但由于刚开始建立 blog 选择的是 wordpress ，域名、服务器、备案、证书等都已经一应俱全，且之前的架构采用 docker，添加一台 nginx 来跑 hugo 的静态网站是很方便的

所以干脆沿用之前的 [github仓库](https://github.com/lvbibir/lvbibir.github.io) ，来作为我博客的归档管理，也可以方便家里电脑和工作电脑之间的数据同步

# 将hugo博客部署到阿里云

之前的[wordpress博客](https://lvbibir.cn)部署在阿里云的一套 docker-compose 环境下，[这篇文章](https://www.lvbibir.cn/posts/blog/wordpress-to-docker/)有详细记录

要做的仅仅是在之前的docker-compose.yml 中添加一个新的nginx环境用于跑hugo生成的静态文件，代理nginx中配置一下新nginx服务器，ssl证书依旧沿用之前的即可

以下是一些配置文件示例

## wordpress-blog/docker-compose.yml

新增了hugo-nginx容器

```yaml
version: '3.1'

services:

  proxy: # 前端代理nginx
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

  web: # wordpress的nginx
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

  hugo: # hugo的nginx
    image: superng6/nginx:debian-stable-1.18.0
    container_name: hugo-nginx
    restart: always
    networks:
      wordpress_net:
        ipv4_address: 172.19.0.7
    volumes:
      - /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime:ro
      - $PWD/conf/hugo/nginx.conf:/etc/nginx/nginx.conf
      - /dev/shm/nginx-cache:/var/run/nginx-cache
      - $PWD/hugo-public:/var/www/html
      - $PWD/logs/hugo:/var/log/nginx


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
      WORDPRESS_DB_PASSWORD: #密码填自己的
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

## wordpress-blog/conf/proxy/default.conf

前端代理nginx的配置文件，原先只有 lvbibir.cn ，新增了 www.lvbibir.cn 相关配置

```nginx
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
        proxy_set_header Accept-Encoding "br";
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
server {
    listen 80;
    listen [::]:80;
    server_name www.lvbibir.cn;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name www.lvbibir.cn;
    location / {
        proxy_pass http://172.19.0.7:80;
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
        proxy_set_header Accept-Encoding "br";
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
```

## wordpress-blog/conf/hugo/nginx.conf

```nginx
user root;

worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;

    # 配置http
    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name www.lvbibir.cn;
        root /var/www/html;

        include /etc/nginx/default.d/*.conf;

        location / {
            root /var/www/html;
            index  index.html index.htm;
        }

        error_page 404 /404.html;
        location = /40x.html {
            root   /var/www/html;
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }

}
```

# 修改链接颜色

在 hugo+papermod 默认配置下，链接颜色是黑色字体带下划线的组合，个人非常喜欢 [typora-vue主题](https://github.com/blinkfox/typora-vue-theme) 的渲染风格，[hugo官方文档](https://gohugo.io/templates/render-hooks/#link-with-title-markdown-example)给出了通过`render hooks`覆盖默认的markdown渲染的方式

新建`layouts/_default/_markup/render-link.html`文件，在官方给出的示例中添加了 `style="color:#42b983`，颜色可以自行修改，代码如下

```html
<a href="{{ .Destination | safeURL }}"{{ with .Title}} title="{{ . }}"{{ end }}{{ if strings.HasPrefix .Destination "http" }} target="_blank" rel="noopener" style="color:#42b983";{{ end }}>{{ .Text | safeHTML }}</a>
```

# url管理

https://gohugo.io/content-management/urls/

# seo优化

https://www.sulvblog.cn/posts/blog/hugo_seo/

# twikoo评论组件

基本完全按照 sulv 博主的文章来操作，某些地方官方有更新，不过也只是更改了页面罢了

https://www.sulvblog.cn/posts/blog/hugo_twikoo/

顺便记录一下账号关系：mongodb使用google账号登录，vercel使用github登录

# todo

- [x] 修改所有文章的文件名为全英文
- [ ] 百度seo优化
- [x] 谷歌seo优化
- [x] 必应seo优化
- [ ] 尝试再次优化nginx的配置，之前的配置对于wordpress可能更适用
- [ ] 图床备份
- [x] 将所有文章进行内容整理





