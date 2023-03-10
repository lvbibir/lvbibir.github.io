---
title: "git常用设置" 
date: 2022-06-01
lastmod: 2022-11-10
tags: 
- linux
keywords:
- git
- proxy
- 网络代理
description: "介绍如何为git设置网络代理，优化git的连接速度" 
cover:
    image: "" 
---

# 设置代理

查看 git 设置

```bash
# 当前仓库
git config --list
# 全局配置
git config --global --list
```

设置全局代理，使用 http 代理

```bash
git config --global https.proxy http://127.0.0.1:1080
git config --global https.proxy https://127.0.0.1:1080
```

设置全局代理，使用socks5代理

```bash
git config --global http.proxy socks5://127.0.0.1:1080
git config --global https.proxy socks5://127.0.0.1:1080
```

取消全局代理

```bash
git config --global --unset http.proxy
git config --global --unset https.proxy
```

只对 github.com 使用代理

```bash
git config --global http.https://github.com.proxy http://127.0.0.1:20081
git config --global https.https://github.com.proxy http://127.0.0.1:20081
```

取消 github.com 代理

```bash
git config --global --unset http.https://github.com.proxy
git config --global --unset https.https://github.com.proxy
```

# CRLF 和 LF 自动转换

```bash
# 提交时转换为LF，检出时转换为CRLF
git config --global core.autocrlf true   
# 提交时转换为LF，检出时不转换
git config --global core.autocrlf input   
# 提交检出均不转换
git config --global core.autocrlf false

# 拒绝提交包含混合换行符的文件
git config --global core.safecrlf true   
# 允许提交包含混合换行符的文件
git config --global core.safecrlf false   
# 提交包含混合换行符的文件时给出警告
git config --global core.safecrlf warn
```
