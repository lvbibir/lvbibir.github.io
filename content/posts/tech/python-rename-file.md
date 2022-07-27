---
title: "python批量修改目录下文件名" 
date: 2022-07-27
lastmod: 2022-07-27
author: ["lvbibir"] 
categories: 
- 
tags: 
- python
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

```python
import os

# 输入文件夹地址
path = "C://Users//lvbibir//Desktop//lvbibir.github.io//content//posts//read//"
files = os.listdir(path)

# 输出所有文件名，只是为了确认一下
for file in files:
    print(file)

# 获取旧名和新名
i = 0
for file in files:
    # 旧名称的信息
    old = path + os.sep + files[i]
    # 新名称的信息
    new = path + os.sep + file.replace('_','-')
    # 新旧替换
    print(new)
    os.rename(old,new)
    i+=1
```

