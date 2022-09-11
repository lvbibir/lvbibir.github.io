---
title: "七牛云配置免费ssl证书" 
date: 2021-07-01
lastmod: 2021-07-01
author: ["lvbibir"] 
categories: 
- 
tags: 
- blog
description: "记录七牛云配置ssl证书的过程" 
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
# 1、购买免费证书

![image-20210722144416642](https://image.lvbibir.cn/blog/image-20210722144416642.png)

![image-20210722144429953](https://image.lvbibir.cn/blog/image-20210722144429953.png)

# 2、补全域名信息

![image-20210722144515614](https://image.lvbibir.cn/blog/image-20210722144515614.png)

![image-20210722145538079](https://image.lvbibir.cn/blog/image-20210722145538079.png)

# 3、域名验证

根据在域名提供商处新建解析

dns配置好之后等待CA机构审核后颁发证书就可以了

![image-20210722152240625](https://image.lvbibir.cn/blog/image-20210722152240625.png)

![image-20210722153133297](https://image.lvbibir.cn/blog/image-20210722153133297.png)

# 4、 为域名开启https

![image-20210722153339766](https://image.lvbibir.cn/blog/image-20210722153339766.png)

# 5、修改PicGo的配置

![image-20210722153530522](https://image.lvbibir.cn/blog/image-20210722153530522.png)

