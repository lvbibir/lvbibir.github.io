---
title: "git" 
date: 2022-06-01
lastmod: 2024-01-28
tags:
  - git
keywords:
  - git
  - proxy
  - 网络代理
description: "介绍使用 git 过程中常用的基础使用、参数设置、常见问题、配置优化等。" 
cover:
    image: "images/cover-default.webp" 
---

# 1 git

## 1.1 submodule

当 clone 一个含有子模块的 git 仓库时可以使用如下命令安装所有子模块

```bash
git submodule init
git submodule update
```

## 1.2 branch 管理

查看分支

```bash
git branch -a
```

创建分支

```bash
# 以当前分支为模板创建并切换分支
git checkout -b dev
# 以 master 为模板创建并切换分支, master 可以是哈希值或者 origin/master 这种远程地址
git checkout -b dev master

# 推送分支, 如远端不存在则自动创建
git checkout dev
git push origin dev
```

删除分支

```bash
# 本地删除
git checkout master
git branch -d dev
# 如果分支包含未合并的更改，使用 `-D` 强制删除
git branch -D dev

# 远端删除
git push origin --delete dev
# 或
git push origin :dev
```

# 2 git 配置

查看 git 设置

```bash
# 当前仓库
git config --list
# 全局配置
git config --global --list
```

## 2.1 设置代理

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

## 2.2 CRLF 和 LF

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

# 3 常见问题

## 3.1 git clone 报错

> fatal: early EOF
>
> fatal: fetch-pack: invalid index-pack output

解决

```bash
git config --global http.sslVerify "false"

git config --global core.compression -1
```

以上
