---
title: docker 部署 piclist
date: 2023-12-29
lastmod: 2023-12-30
tags:
  - docker
  - obsidian
keywords:
  - linux
  - docker
  - centos
  - piclist
  - obsidian
description: 介绍如何使用 docker 部署 piclist 实现 obsidian 远程上传图片至阿里云 OSS 图床
cover:
  image: https://image.lvbibir.cn/blog/docker.png
---

# 前言

感谢 piclist 作者的 [不吝解答](https://github.com/Kuingsmile/PicList/issues/127)

最近从 typora 迁移到了 obsidian, typora 可以很方便的自动调用 [picgo](https://github.com/Molunerfinn/PicGo) 实现图片上传, obsidian 得益于丰富的插件市场, 可以通过 [Image Auto Upload Plugin](https://github.com/renmu123/obsidian-image-auto-upload-plugin) 插件调用 picgo, 但是必须手动启动 picgo 后才能正常使用

在插件配置的注释中发现了 [piclist](https://github.com/Kuingsmile/PicList), 经了解发现这个二开版本支持 docker 部署, 综合考虑了一下还是值得折腾一下的, 既能避免手动打开 picgo 的繁琐, 也可以在我所有的 pc 上卸载掉一个软件, ~~同时还能水一文~~

> 注意本文以已有服务器/ip/域名且 web 服务使用 nginx 为前提, 如果不满足上述前提, 需要将 piclist 的 36677 端口映射到主机, 部署完 piclist 后直接通过 ip 加端口的形式调用即可

# 部署

## piclist 配置

`docker-compose.yml` 中添加如下配置

```yaml
version: '3.1'

services:

  piclist:
    image: 'kuingsmile/piclist:v1.7.0'
    container_name: piclist
    restart: always
    networks:
      blog_net:
        ipv4_address: 172.19.0.5
    volumes:
      - '$PWD/data/piclist:/root/.piclist'
    # 需要设置 piclist_key 环境变量
    command: node /usr/local/bin/picgo-server -k ${piclist_key}

networks:
  blog_net:
    driver: bridge
    ipam:
     config:
       - subnet: 172.19.0.0/16
```

添加环境变量并启动 piclist 容器, 此环境变量用于 client(obsidian) 和 piclist server 之间的鉴权

```bash
echo "export piclist_key='123456'" >> ${HOME}/.bash_profile # 将 123456 设置为自定义的密码
source ${HOME}/.bash_profile
docker-compose up -d
```

修改 `data/piclist/config.json` 的配置, 以阿里云 OSS 为例添加图床配置, 内容自行修改, 官方没有配置文件的详细文档, 可以折中一下, 先 windows 安装 piclist 后修改配置, 测试后导出配置

```bash
{
  "picBed": {
    "current": "aliyun",
    "uploader": "aliyun",
    "aliyun": {
      "accessKeyId": "******",
      "accessKeySecret": "******",
      "bucket": "lvbibir-image",
      "area": "oss-cn-beijing",
      "path": "blog/",
      "customUrl": "https://image.lvbibir.cn",
      "options": ""
    }
  },
  "picgoPlugins": {}
}
```

最后再重启一下 piclist

```bash
docker restart piclist
```

## nginx 配置

nginx 中添加如下 location 配置

```nginx
    location /piclist/ {
        proxy_pass http://172.19.0.5:36677/;
        proxy_redirect off;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Real-Port $remote_port;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header HTTP_X_FORWARDED_FOR $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
        proxy_set_header X-NginX-Proxy true;
        proxy_set_header Accept-Encoding "br";
    }
```

执行 `docker restart nginx-proxy` 重启 nginx

最后修改 obsidian 的 `Image auto upload Plugin` 插件的配置

![](https://image.lvbibir.cn/blog/image-20231229-155939.png)

1. 打开远程服务器模式
2. 将接口 url 设置为 `https://<你的域名>/piclist/upload?key=<你的key>`, 这里的 key 就是启动容器时配置的环境变量的值, 需注意如果 key 中有特殊字符需要 url 转义一下

# 常见问题

最后测试一下图片上传即可, 如果有报错可以通过 `docker logs -f piclist` 查看日志

1. obsdian 直接提示上传失败, 可能是 key 中有特殊字符没有转义或者没有打开远程服务器模式
2. 日志中有如下 `Unauthorized access` 报错, 一般是 key 不匹配

至此
