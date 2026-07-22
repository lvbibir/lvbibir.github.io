---
title: "easytier 部署" 
date: 2026-07-22
lastmod: 2026-07-22
tags:
  - easytier
keywords:
  - easytier
description: "使用阿里云 vps 部署 easytier 中继服务器及 easytier-web 配置管理器" 
cover:
    image: "images/cover-default.webp" 
---

# 0 前言

使用一台阿里云 vps 作为中继和 windows 端的 easytier 配置管理器, 中继只作为打洞失败时使用

# 1 ecs 部署

服务器防火墙和安全组放通 `11010/tcp` `11010/udp` `11211/tcp` `11212/udp` 四个端口

## 1.1 docker compose

```yaml
services:

  easytier-web:
    image: easytier/easytier:v2.4.5
    container_name: easytier-web
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./data/easytier-web:/app
    environment:
      - TZ=Asia/Shanghai
    entrypoint:
      - /sbin/tini
      - --
      - /usr/local/bin/easytier-web-embed
    command:
      - --api-server-port
      - "11211"
      - --api-host
      - "http://<你的公网ip>:11211"
      - --config-server-port
      - "11212"
      - --config-server-protocol
      - udp

  easytier-core:
    image: easytier/easytier:v2.4.5
    container_name: easytier-core
    restart: unless-stopped
    network_mode: host
    privileged: true
    environment:
      - TZ=Asia/Shanghai
    volumes:
      - /etc/machine-id:/etc/machine-id:ro
    depends_on:
      - easytier-web
    command:
      - -w
      - "udp://127.0.0.1:11212/<web配置端用户名>"
      # 这里的用户名可以自定义, 在下一步中创建该用户
```

## 1.2 web 控制台注册用户

访问 `http://<你的公网ip>:11211` 注册一个用户

> 如果遇到验证码刷新不出来, 各种奇怪的报错一般都是 `访问地址` 和 `API 主机地址` 配置的不一样导致的

![](images/image-20260430-144316.png)

## 1.3 easytier 配置

使用新注册的用户登陆到 web 控制台之后应该能看到 ecs 的 easytier 已经注册到 web 控制台了

![](images/image-20260430-150525.png)

给 ecs 添加一个网络, ip 地址/网络名称/网络密码 都自定义, 因为 ecs 是用做中继服务器的, 所以 `网络方式` 这里选择 `独立` 即可

![](images/image-20260430-150827.png)

# 2 windows 电脑端配置

## 2.1 安装服务

参考 [官方文档](https://easytier.rs/guide/network/install-as-a-windows-service.html) 安装服务, 外部 config-server 填 `udp://<你的公网ip>:11212/<username>`

![](images/image-20260430-152510.png)

## 2.2 基础设置

访问 web 控制台应该能看到节点注册上了

![](images/image-20260430-112541.png)

1. 配置虚拟 ipv4 地址, DHCP 或者自定义均可
2. 网络名称和网络密码, 跟 ecs 一致
3. 配置中继服务器为 ecs 的公网 ip 加端口

![](images/image-20260420-161225.png)

## 2.3 高级设置

按下图配置, 如果经常使用 tun 模式的话不要开 `仅使用物理网卡` 功能

![](images/image-20260420-161454.png)

以上.
