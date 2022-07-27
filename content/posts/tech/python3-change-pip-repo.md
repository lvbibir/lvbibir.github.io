---
title: "python3修改pip源" 
date: 2021-12-01
lastmod: 2021-12-01
author: ["lvbibir"] 
categories: 
- 
tags: 
- python
- pip
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
中国科学技术大学 : https://pypi.mirrors.ustc.edu.cn/simple

清华：https://pypi.tuna.tsinghua.edu.cn/simple

豆瓣：http://pypi.douban.com/simple/

华中理工大学 : http://pypi.hustunique.com/simple

山东理工大学 : http://pypi.sdutlinux.org/simple

阿里云：https://mirrors.aliyun.com/pypi/simple/

# linux环境

```
mkdir ~/.pip
cat > ~/.pip/pip.conf << EOF 
[global]
trusted-host=mirrors.aliyun.com
index-url=https://mirrors.aliyun.com/pypi/simple/
EOF
```

# windows环境

使用dos命令set找到 userprofile 路径，在该路径下创建pip文件夹，在pip文件夹下创建pip.ini

![image-20211109160017309](https://image.lvbibir.cn/blog/image-20211109160017309.png)

![image-20211109155952483](https://image.lvbibir.cn/blog/image-20211109155952483.png)

pip.ini具体配置

```
[global]
timeout = 6000
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
```

