---
title: "wsl | 自动更新系统代理"
date: 2024-01-12
lastmod: 2025-12-11
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

# 1 配置代理

wsl 中添加如下脚本, 实现全局的系统代理, git 的 http(s) 代理和 ssh 代理, apt 代理, docker 镜像的代理按需开启, 使用国内的加速站也可

```bash
cat > ~/proxy 

#!/bin/bash

# normal proxy
# 指定 url 的方式
proxy_type="http"
proxy_ip="proxy1.bj.petrochina"
proxy_port="8080"

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
sudo systemctl reset-failed docker
sudo systemctl restart docker

# apt 代理
# 如果不加 sudo, 会导致用 sudo 执行 apt 等命令时无法识别 alias
alias sudo='sudo '
alias apt="apt -o Acquire::http::proxy=${proxy}"
alias apt-get="apt-get -o Acquire::http::proxy=${proxy}"

# git 的 http 或者 https 代理
git config --global http.https://github.com.proxy ${proxy}
git config --global https.https://github.com.proxy ${proxy}

# git 的 ssh 代理
tee ~/.ssh/config > /dev/null <<- EOF

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


# 手动调用
source ~/proxy
```

# 2 取消代理

```bash
cat ~/proxy-unset

#!/bin/bash

unset http_proxy
unset https_proxy
unset all_proxy
unset ALL_PROXY

# docker 代理
sudo tee /etc/docker/daemon.json > /dev/null <<- 'EOF'
{
  "insecure-registries" : ["http://11.14.1.40"]
}
EOF
sudo systemctl reset-failed docker
sudo systemctl restart docker

unalias sudo
unalias apt
unalias apt-get

git config --global --unset http.https://github.com.proxy
git config --global --unset https.https://github.com.proxy

# git 的 ssh 代理
truncate -s 0 ~/.ssh/config

tee ~/.ssh/config > /dev/null <<- EOF
# 默认配置
EOF

# 手动调用
source ~/proxy-unset
```

以上
