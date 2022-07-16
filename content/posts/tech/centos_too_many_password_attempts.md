---
title: "CentOS密码尝试次数过多" 
date: 2022-01-01
lastmod: 2022-01-01
author: ["lvbibir"] 
categories: 
- 
tags: 
- centos
- pam
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
# pam模块

pam：Pluggable Authentication Modules 可插拔的认证模块，linux 中的认证方式，“可插拔的“说明可以按需对认证内容进行变更。与nsswitch一样，也是一个通用框架。只不过是提供认证功能的。

# 重置密码失败次数

```bash
pam_tally2 -r -u root

## 或者 ##

faillock --user root --reset
```

具体取决于在规则文件中使用的是 <font color="red">**pam_faillock.so**</font> 模块还是 <font color="red">**pam_tally2.so**</font> 模块

例：

```
vim /etc/pam.d/system-auth
```

![image-20220127100540162](https://image.lvbibir.cn/blog/image-20220127100540162.png)

