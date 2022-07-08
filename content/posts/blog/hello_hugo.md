---
title: "【置顶】Hello,hugo!" #标题
date: 2022-07-06T00:00:00+08:00 #创建时间
lastmod: 2022-07-06T00:00:00+08:00 #更新时间
author: ["lvbibir"] #作者
categories: 
- 
tags: 
- hugo
- papermod
description: "记录wordpress迁移至hugo的过程，大多参考sulv大佬的博客，很详尽就只贴链接了" #描述
weight: 1 # 输入1可以顶置文章，用来给文章展示排序，不填就默认按时间排序
slug: ""
draft: false # 是否为草稿
comments: true #是否展示评论
showToc: true # 显示目录
TocOpen: true # 自动展开目录
hidemeta: false # 是否隐藏文章的元信息，如发布日期、作者等
disableShare: true # 底部不显示分享栏
showbreadcrumbs: true #顶部显示当前路径
cover:
    image: "https://image.lvbibir.cn/blog/hugo-logo-wide.svg" #图片路径：posts/tech/文章1/picture.png
    caption: "" #图片底部描述
    alt: ""
    relative: false
---


# 博客流水线

1. 修改posts下文章内容
2. `hugo -F --cleanDestinationDir`
3. `rsync -avuz --progress --delete Desktop/lvbibir/2-www.lvbibir.cn/public/ root@101.201.150.47:/root/wordpress-blog/hugo-public/`
4. 确认后git push到github做归档


# seo优化

https://www.sulvblog.cn/posts/blog/hugo_seo/

# 添加twikoo评论组件

基本完全按照sulv博主的文章来操作，某些地方官方有更新，不过也只是更改了页面罢了

https://www.sulvblog.cn/posts/blog/hugo_twikoo/

顺便记录一下账号关系：mongodb使用google账号登录，vercel使用github登录

# 修改博客url

https://gohugo.io/content-management/urls/



# todo

- [x] 修改所有文章的文件名为全英文
- [ ] 百度seo优化
- [x] 谷歌seo优化
- [x] 必应seo优化





