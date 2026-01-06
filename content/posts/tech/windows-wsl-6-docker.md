---
title: "wsl | 原生 linux 方式安装 docker"
date: 2024-01-25
lastmod: 2024-02-02
tags:
  - wsl
  - docker
keywords:
  - windows
  - wsl
  - docker
  - docker-compose
description: "wsl2 使用原生 linux 方式安装 docker 和 docker-compose, 以及修改 docker 镜像加速地址"
cover:
    image: "images/cover-wsl.png"
---

# 0 前言

本文参考以下链接:

- [docker 文档 - 使用便利性脚本进行安装 docker engine](https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script)
- [docker 文档 - 配置 http proxy](https://docs.docker.com/config/daemon/systemd/)

记录一下 wsl2 原生 linux 方式安装 docker 的过程

# 1 安装

安装过程中会提示建议使用 `docker desktop`, 等待 20s 即可

```bash
curl https://get.docker.com -o get-docker.sh
sudo bash get-docker.sh

sudo docker info
```

安装完之后 docker 会默认开机自启, 之后管理 docker 使用 systemctl 即可

```bash
sudo systemctl stop|start|restart docker
```

# 2 配置

## 2.1 修改镜像源

proxies 部分可以不用配置, 因为我这里环境特殊, 必须走代理才能访问互联网

```bash
sudo vim /etc/docker/daemon.json
# 添加如下内容
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://jc0srqak.mirror.aliyuncs.com",
    "http://hub-mirror.c.163.com"
  ],
  "proxies": {
    "http-proxy": "http://proxy1.bj.petrochina:8080",
    "https-proxy": "http://proxy1.bj.petrochina:8080",
    "no-proxy": "localhost,127.0.0.0/8"
  }
}

sudo systemctl daemon-reload
sudo systemctl restart docker
sudo docker info # 应看到镜像仓库信息和代理信息
```

## 2.2 docker-compose

使用安装脚本完后会默认安装 docker-compose-plugin, 可以使用 `docker compose` 调用, 如果你更习惯使用 `docker-compose`, 可以手动添加一下软连接

```bash
sudo ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/sbin/docker-compose
sudo docker-compose --version
```

# 3 测试

最后简单测试一下

```bash
mkdir docker; cd docker
cat > docker-compose.yml <<-'EOF'
version: '3.1'

services:

  nginx:
    image: superng6/nginx:debian-stable-1.18.0
    container_name: nginx
    restart: always
    ports:
      - 80:80
EOF

sudo docker-compose up -d
```

由于 wsl2 解决了和 windows 使用相同的网络 (镜像网络), 所以可以直接通过 windows 端浏览器访问 `http://localhost` 即可跳转到 docker 中运行的 nginx 容器

以上
