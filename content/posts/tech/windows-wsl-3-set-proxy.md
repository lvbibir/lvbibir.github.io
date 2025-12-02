---
title: "wsl | 自动更新系统代理"
date: 2024-01-12
lastmod: 2025-05-28
tags:
  - wsl
keywords:
  - windows
  - wsl
  - proxy
  - clash
description: "wsl 中配置系统代理, apt 代理, git 代理, 以及 docker 代理, 包含 clash 等客户端提供的代理或者使用指定的代理地址"
cover:
    image: "https://image.lvbibir.cn/blog/logo-wsl.png"
---

# 0 前言

目前我使用 wsl 过程中有以下两个场景需要使用到代理:

- 场景一: 某些科学上网的场景, 比如 github 加速等
- 场景二: 公司内网机器需要通过公司提供的代理上网

针对场景一, 可以通过将代理设置为 clash 或者其他客户端提供的端口, 如使用 clash 记得打开设置中的允许局域网

针对场景二, 直接设置公司提供的代理地址即可

# 1 配置

wsl 中添加如下脚本, 实现常规的系统代理, git 仓库代理以及 apt 的代理

```bash
cat > ~/proxy 

#!/bin/bash

# normal proxy
# 指定 url 的方式
# proxy_type="http"
# proxy_ip="proxy1.bj.petrochina"
# proxy_port="8080"

# 使用 windows 主机上运行的代理程序, 例如 clash
# wsl 中的地址是不固定的, 这里通过脚本获取, 每次启动 wsl 都可以实时更新
proxy_type="http"
proxy_ip=$(cat /etc/resolv.conf |grep "nameserver" |cut -f 2 -d " ")
proxy_port="7890"

proxy="${proxy_type}://${proxy_ip}:${proxy_port}"

# 系统全局代理
export ALL_PROXY="${proxy}"
export all_proxy="${proxy}"
export http_proxy="${proxy}"
export https_proxy="${proxy}"

# docker 代理
sudo tee /etc/docker/daemon.json > /dev/null <<- EOF
{
  "insecure-registries" : ["http://11.14.1.40"],
  "proxies": {
    "http-proxy": "${proxy}",
    "https-proxy": "${proxy}",
    "no-proxy": "localhost,127.0.0.0/8"
  }
}
EOF
sudo systemctl restart docker

# apt 代理
# 如果不加 sudo, 会导致用 sudo 执行 apt 等命令时无法识别 alias
alias sudo='sudo '
alias apt="apt -o Acquire::http::proxy=${proxy}"
alias apt-get="apt-get -o Acquire::http::proxy=${proxy}"

# git 的 http 或者 https 代理
sudo git config --global http.https://github.com.proxy ${proxy}
sudo git config --global https.https://github.com.proxy ${proxy}

# git 的 ssh 代理
sudo tee ~/.ssh/config > /dev/null <<- EOF

# git-bash 环境: 注意替换端口号和 connect.exe 的路径
# ProxyCommand "C:\\APP\\Git\\mingw64\\bin\\connect" -S ${proxy_ip}:${proxy_port} -a none %h %p

# linux 环境: 注意替换你的端口号
# ProxyCommand nc -v -x ${proxy_ip}:${proxy_port} %h %p

Host github.com
  User git
  Port 22
  Hostname github.com
  ProxyCommand nc -v -x ${proxy_ip}:${proxy_port} %h %p
  IdentityFile "/home/lvbibir/.ssh/id_rsa"
  TCPKeepAlive yes

Host ssh.github.com
  User git
  Port 443
  Hostname ssh.github.com
  ProxyCommand nc -v -x ${proxy_ip}:${proxy_port} %h %p
  IdentityFile "/home/lvbibir/.ssh/id_rsa"
  TCPKeepAlive yes

EOF
```

加入环境变量, 每次启动 wsl 自动设置 proxy

```bash
cat >> ~/.bashrc <<- 'EOF'
source ${HOME}/proxy
EOF

source ~/.bashrc
```

# 2 docker 代理

修改 docker pull 等操作的代理可以通过 docker 的 daemon.json 文件或者 service 两种方式进行修改, 推荐使用第一种

- 修改 `/etc/docker/daemon.json`

```json
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
```

- 修改 docker service

```bash
sudo vim /lib/systemd/system/docker.service

# 在 [Service] 下添加如下三行
Environment=HTTP_PROXY=http://proxy1.bj.petrochina:8080
Environment=HTTPS_PROXY=http://proxy1.bj.petrochina:8080
Environment=NO_PROXY=localhost,127.0.0.1
```

上述两种方式任意一种修改完成后重启 docker 即可

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo docker info | grep proxy
```

以上
