---
title: "wsl | 自动更新系统代理"
date: 2024-01-12
lastmod: 2025-12-19
tags:
  - wsl
keywords:
  - windows
  - wsl
  - proxy
  - clash
description: "wsl 中配置系统代理, apt 代理, git 代理, 以及 docker 代理, 包含 clash 等客户端提供的代理或者使用指定的代理地址"
cover:
    image: "images/logo-wsl.png"
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

# 提示用户必须使用 source 执行
if [ "$0" = "$BASH_SOURCE" ]; then
    echo "错误: 请使用 'source ~/proxy-unset' 或 '. ~/proxy-unset' 来执行此脚本"
    echo "直接执行无法清除当前 shell 的环境变量和 alias"
    exit 1
fi

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
# 只在配置变化时才更新并重启 docker
docker_config=$(cat <<- EOF
{
  "insecure-registries" : ["http://11.14.1.40"],
  "proxies": {
    "http-proxy": "${proxy}",
    "https-proxy": "${proxy}",
    "no-proxy": "localhost,127.0.0.0/8"
  }
}
EOF
)

current_config=""
if [ -f /etc/docker/daemon.json ]; then
    current_config=$(sudo cat /etc/docker/daemon.json 2>/dev/null)
fi

if [ "$docker_config" != "$current_config" ]; then
    echo "$docker_config" | sudo tee /etc/docker/daemon.json > /dev/null
    sudo systemctl reset-failed docker 2>/dev/null
    sudo systemctl restart docker
fi

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

# git-bash 环境: ProxyCommand "C:\\APP\\Git\\mingw64\\bin\\connect" -S ${proxy_ip}:${proxy_port} -a none %h %p
# Centos7 环境: ProxyCommand ncat --proxy ${proxy_ip}:${proxy_port} --proxy-type ${proxy_type} %h %p
# Ubuntu 环境: ProxyCommand nc -v -x ${proxy_ip}:${proxy_port} -X ${proxy_type} %h %p

Host github.com
  User git
  Port 22
  Hostname github.com
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

# 提示用户必须使用 source 执行
if [ "$0" = "$BASH_SOURCE" ]; then
    echo "错误: 请使用 'source ~/proxy-unset' 或 '. ~/proxy-unset' 来执行此脚本"
    echo "直接执行无法清除当前 shell 的环境变量和 alias"
    exit 1
fi

# 清除环境变量
unset http_proxy
unset https_proxy
unset all_proxy
unset ALL_PROXY

# docker 代理
# 只在配置变化时才更新并重启 docker
docker_config=$(cat <<- 'EOF'
{
  "insecure-registries" : ["http://11.14.1.40"]
}
EOF
)

current_config=""
if [ -f /etc/docker/daemon.json ]; then
    current_config=$(sudo cat /etc/docker/daemon.json 2>/dev/null)
fi

if [ "$docker_config" != "$current_config" ]; then
    echo "$docker_config" | sudo tee /etc/docker/daemon.json > /dev/null
    sudo systemctl reset-failed docker 2>/dev/null
    sudo systemctl restart docker
    echo "Docker 配置已更新并重启"
fi

# 清除 alias
unalias sudo 2>/dev/null
unalias apt 2>/dev/null
unalias apt-get 2>/dev/null

# 清除 git 的 http/https 代理
git config --global --unset http.https://github.com.proxy 2>/dev/null
git config --global --unset https.https://github.com.proxy 2>/dev/null

# git 的 ssh 代理
tee ~/.ssh/config > /dev/null <<- EOF

Host github.com
  User git
  Port 22
  Hostname github.com
  IdentityFile "/home/lvbibir/.ssh/id_rsa"
  TCPKeepAlive yes

EOF

echo "代理配置已清除 (当前 shell 会话)"
echo "注意: 新开的 shell 会话仍会通过 .bashrc 加载 proxy"

# 手动调用
source ~/proxy-unset
```

以上
