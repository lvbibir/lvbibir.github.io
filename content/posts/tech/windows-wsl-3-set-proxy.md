---
title: "wsl | 自动更新系统代理"
date: 2024-01-12
lastmod: 2024-01-13
tags:
  - wsl
keywords:
  - windows
  - wsl
  - proxy
  - clash
description: "wsl 中配置系统代理, 包含 clash 等客户端提供的代理或者使用指定的代理地址"
cover:
    image: "https://image.lvbibir.cn/blog/logo-wsl.png"
---

# 0.前言

目前我使用 wsl 过程中有以下两个场景需要使用到代理:

- 场景一: 某些科学上网的场景, 比如 github 加速等
- 场景二: 公司内网机器需要通过公司提供的代理上网

针对场景一, 可以通过将代理设置为 clash 或者其他客户端提供的端口, 如使用 clash 记得打开设置中的允许局域网

针对场景二, 直接设置公司提供的代理地址即可

# 1.脚本

wsl 中添加如下脚本

```bash
cat > ${HOME}/proxy <<- 'EOF'
#!/bin/bash

# normal proxy
# 指定 url 的方式
proxy_type="http"
proxy_ip="proxy1.bj.petrochina"
proxy_port="8080"

# 使用 windows 主机上运行的代理程序, 例如 clash
# wsl 中的地址是不固定的, 这里通过脚本获取, 每次启动 wsl 都可以实时更新
# proxy_type="http"
# proxy_ip=$(cat /etc/resolv.conf |grep "nameserver" |cut -f 2 -d " ")
# proxy_port="7890"

proxy="${proxy_type}://${proxy_ip}:${proxy_port}"

export ALL_PROXY="${proxy}"
export all_proxy="${proxy}"
export http_proxy="${proxy}"
export https_proxy="${proxy}"

git config --global http.https://github.com.proxy ${proxy}
git config --global https.https://github.com.proxy ${proxy}

# 如果不加 sudo, 会导致用 sudo 执行 apt 等命令时无法识别 alias
alias sudo='sudo '
alias apt="apt -o Acquire::http::proxy=${proxy}"
alias apt-get="apt-get -o Acquire::http::proxy=${proxy}"
EOF
```

加入环境变量, 每次启动 wsl 自动设置 proxy

```bash
cat >> ${HOME}/.bash_profile <<- 'EOF'
source ${HOME}/proxy
EOF

source ${HOME}/.bash_profile
```

以上
