---
title: "git设置代理" #标题
date: 2022-06-01T00:00:00+08:00 #创建时间
lastmod: 2022-06-01T00:00:00+08:00 #更新时间
author: ["lvbibir"] #作者
categories: 
- 
tags: 
- git
description: "" #描述
weight: # 输入1可以顶置文章，用来给文章展示排序，不填就默认按时间排序
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
```git
# 设置全局代理
# http
git config --global https.proxy http://127.0.0.1:1080
# https
git config --global https.proxy https://127.0.0.1:1080
# 使用socks5代理的 例如ss，ssr 1080是windows下ss的默认代理端口,mac下不同，或者有自定义的，根据自己的改
git config --global http.proxy socks5://127.0.0.1:1080
git config --global https.proxy socks5://127.0.0.1:1080

# 只对github.com使用代理，其他仓库不走代理
git config --global http.https://github.com.proxy socks5://127.0.0.1:1080
git config --global https.https://github.com.proxy socks5://127.0.0.1:1080
# 取消github代理
git config --global --unset http.https://github.com.proxy
git config --global --unset https.https://github.com.proxy

# 取消全局代理
git config --global --unset http.proxy
git config --global --unset https.proxy
```

