---
title: "docker | centos7 部署 docker" 
date: 2024-02-07
lastmod: 2024-02-07
tags:
  - docker
keywords:
  - docker
  - centos
description: "本文介绍一下 centos7 安装部署 docker 的步骤" 
cover:
    image: "images/docker.png"
---

# 0 前言

一直没有单独记录过 docker 的安装步骤, 故有此文

# 1 安装 docker

```bash
# 如没有 wget, 可以使用 curl, -O 替换成 -o
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
yum list docker-ce --show-duplicates
yum install docker-ce-20.10.23-3.el7.x86_64
```

# 2 镜像加速器

```bash
mkdir /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
    "http://hub-mirror.c.163.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://jc0srqak.mirror.aliyuncs.com"
  ]
}
EOF

systemctl daemon-reload
systemctl enable docker && systemctl start docker
docker info # 应看到配置的镜像地址
```

以上
