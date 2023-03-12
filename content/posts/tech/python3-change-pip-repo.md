---
title: "python3修改pip源" 
date: 2021-12-01
lastmod: 2021-12-01
tags: 
- python
keyword:
- python
- pip
description: "" 
cover:
    image: "" 
---
> 中国科学技术大学 : https://pypi.mirrors.ustc.edu.cn/simple
>
> 清华：https://pypi.tuna.tsinghua.edu.cn/simple
>
> 豆瓣：http://pypi.douban.com/simple/
>
> 华中理工大学 : http://pypi.hustunique.com/simple
>
> 山东理工大学 : http://pypi.sdutlinux.org/simple
>
> 阿里云：https://mirrors.aliyun.com/pypi/simple/

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

打开 cmd 使用 dos命令 set 找到 userprofile 路径，在该路径下创建 pip文件夹，在 pip文件夹下创建 pip.ini

![image-20211109160017309](https://image.lvbibir.cn/blog/image-20211109160017309.png)

pip.ini具体配置

```
[global]
timeout = 6000
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
```

