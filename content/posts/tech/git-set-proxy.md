---
title: "git设置代理" 
date: 2022-06-01
lastmod: 2022-06-01
tags: 
- git
keywords:
- git
- proxy
- 网络代理
description: "介绍如何为git设置网络代理，优化git的连接速度" 
cover:
    image: "" 
---

查看 git 全局设置

```
git config --global --list
```

查看当前仓库的 git 设置

```
git config --list
```

设置全局代理，使用 http 代理

```git
git config --global https.proxy http://127.0.0.1:1080
git config --global https.proxy https://127.0.0.1:1080
```

设置全局代理，使用socks5代理

```
git config --global http.proxy socks5://127.0.0.1:1080
git config --global https.proxy socks5://127.0.0.1:1080
```

取消全局代理

```
git config --global --unset http.proxy
git config --global --unset https.proxy
```

只对 github.com 使用代理

```
git config --global http.https://github.com.proxy http://127.0.0.1:20081
git config --global https.https://github.com.proxy http://127.0.0.1:20081
```

取消 github.com 代理

```
git config --global --unset http.https://github.com.proxy
git config --global --unset https.https://github.com.proxy
```

