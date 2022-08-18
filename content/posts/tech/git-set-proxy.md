---
title: "git设置代理" 
date: 2022-06-01
lastmod: 2022-06-01
author: ["lvbibir"] 
categories: 
- 
tags: 
- git
description: "" 
weight: 
slug: ""
draft: false # 是否为草稿
comments: true #是否展示评论
showToc: true # 显示目录
TocOpen: true # 自动展开目录
hidemeta: false # 是否隐藏文章的元信息，如发布日期、作者等
disableShare: true # 底部不显示分享栏
showbreadcrumbs: true #顶部显示当前路径
cover:
    image: "" #图片路径：posts/tech/文章1/picture.png
    caption: "" #图片底部描述
    alt: ""
    relative: false
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
git config --global http.https://github.com.proxy socks5://127.0.0.1:20081
git config --global https.https://github.com.proxy socks5://127.0.0.1:20081
```

取消 github.com 代理

```
git config --global --unset http.https://github.com.proxy
git config --global --unset https.https://github.com.proxy
```

