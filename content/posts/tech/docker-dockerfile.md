---
title: "docker | dockerfile详解" 
date: 2023-04-09
lastmod: 2023-04-09
tags: 
- docker
keywords:
- docker
- dockerfile
description: "dockerfile的简介、所有指令以及一些优化和最佳实践" 
cover:
    image: "https://image.lvbibir.cn/blog/docker.png" 
---

# 1. 简介

Dockerfile用于构建docker镜像, 实际上就是把在linux下的命令操作写到了Dockerfile中, 通过Dockerfile去执行设置好的操作命令, 保证通过Dockerfile的构建镜像是一致的.

# 2. 所有指令

## FROM 指定基础镜像

命令格式

```dockerfile
FROM image_name@[tag | digset]
```



我们可以用任意已存在的镜像为基础构建我们的自定义镜像

比如:

- 系统镜像: `centos`, `ubuntu`, `debian`, `alpine`

- 应用镜像: `nginx`, `redis`, `mongo`, `mysql`, `httpd`
- 运行环境镜像: `php`, `java`, `golang`
- 工具镜像: `busybox`







# 3. 优化









