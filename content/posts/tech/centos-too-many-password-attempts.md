---
title: "CentOS | 密码尝试次数过多" 
date: 2022-01-01
lastmod: 2022-01-01
tags: 
- linux
- centos
keywords:
- linux
- centos
- pam
description: "介绍centos系统中的pam模块，以及出现尝试密码次数过多如何处理" 
cover:
    image: "" 
---
# pam模块

pam：`Pluggable Authentication Modules` 可插拔的认证模块，linux 中的认证方式，“可插拔的”说明可以按需对认证内容进行变更。与nsswitch一样，也是一个通用框架。只不过是提供认证功能的。

# 重置密码失败次数

```bash
pam_tally2 -r -u root

## 或者 ##

faillock --user root --reset
```

具体取决于在规则文件中使用的是 `pam_faillock.so`模块还是 `pam_tally2.so` 模块

例：

```
vim /etc/pam.d/system-auth
```

![image-20220127100540162](https://image.lvbibir.cn/blog/image-20220127100540162.png)

