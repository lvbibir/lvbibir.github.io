---
title: "git" 
date: 2022-06-01
lastmod: 2022-11-10
tags: 
- linux
keywords:
- git
- proxy
- 网络代理
description: "介绍使用git过程中常用的基础使用、参数设置、常见问题、配置优化等。" 
cover:
    image: "" 
---

# git命令

## submodule

当clone一个含有子模块的git仓库时可以使用如下命令安装所有子模块

```bash
git submodule init
git submodule update
```

# git配置

查看 git 设置

```bash
# 当前仓库
git config --list
# 全局配置
git config --global --list
```

## 设置代理

设置全局代理，使用 http 代理

```bash
git config --global https.proxy http://127.0.0.1:1080
git config --global https.proxy https://127.0.0.1:1080
```

取消 github.com 代理

```bash
git config --global --unset http.https://github.com.proxy
git config --global --unset https.https://github.com.proxy
```

设置全局代理，使用 socks5 代理

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
git config --global http.https://github.com.proxy http://127.0.0.1:7890
git config --global https.https://github.com.proxy http://127.0.0.1:7890
```

## CRLF 和 LF 

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

# 常见问题

## git clone 报错

> fatal: early EOF 
>
> fatal: fetch-pack: invalid index-pack output

解决

```bash
git config --global http.sslVerify "false"

git config --global core.compression -1
```

