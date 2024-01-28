---
title: "troubleshooting | 安装 cloud-init 后导致 ssh 连接失败" 
date: 2021-12-01
lastmod: 2024-01-28
tags:
  - openstack
  - troubleshooting
keywords:
  - openstack
  - cloud-init
  - ssh
  - troubleshooting
description: "" 
cover:
    image: "https://source.unsplash.com/random/400x200?code" 
---

# 0 前言

在 openEuler20.03 (LTS-SP1) 系统上进行一些测试，发现某个东西会自动修改 ssh 配置文件导致系统无法通过密码登录，最后排查是由于安装了 cloud-init 导致的。

![image-20211217152941463](https://image.lvbibir.cn/blog/image-20211217152941463.png)

# 排查思路

出现这个问题前做的操作是安装了一些项目组同事指定的包，问题就应该出在这些包上

```bash
yum install -y telnet rsync ntpdate zip unzip libaio dos2unix sos vim vim-enhanced net-tools man ftp lrzsz psmisc gzip network-scripts cloud-init cloud-utils-growpart tar libnsl authselect-compat
```

大致看了下，除了 cloud-Init 和 cloud-utils-growpart 这两个包其他包基本不可能去修改 ssh 的配置

直接检索这两个包的所有文件中的配置，是否与 PasswordAuthentication 有关

```bash
[root@localhost ~]# grep -nr PasswordAuthentication `rpm -ql cloud-utils-growpart`
[root@localhost ~]# grep -nr PasswordAuthentication `rpm -ql cloud-init`
```

找到了修改这个参数代码的具体实现

![image-20211217153934057](https://image.lvbibir.cn/blog/image-20211217153934057.png)

查看该文件

```bash
[root@localhost ~]# vim +98 /usr/lib/python3.7/site-packages/cloudinit/config/cc_set_passwords.py
```

具体的判断操作和修改操作

![image-20211217154333149](https://image.lvbibir.cn/blog/image-20211217154333149.png)

修改操作就不去深究了，主要看下判断操作，可以看到判断操作是使用了 util.is_true() ，该 util 模块也在该文件中引用了

![image-20211217154537176](https://image.lvbibir.cn/blog/image-20211217154537176.png)

再去找这个 util 模块的具体实现

python 引用的模块路径如下，否则会抛出错误

- 文件的同级路径下
- sys.path 路径下

并没有在同级目录下

```bash
[root@localhost ~]# ll /usr/lib/python3.7/site-packages/cloudinit/config/ | grep cloudinit
```

sys.path 路径不知道可以用 python 终端输出下

![image-20211217155010363](https://image.lvbibir.cn/blog/image-20211217155010363.png)

在/usr/lib/python3.7/site-packages 路径下找到了 cloudinit 模块的 util 子模块

![image-20211217155130708](https://image.lvbibir.cn/blog/image-20211217155130708.png)

查看 util.is_true 和 util.is_false 具体的函数实现

![image-20211217160135163](https://image.lvbibir.cn/blog/image-20211217160135163.png)

逻辑很简单，判断 val 参数是否为 bool 值，否则对 val 参数的值进行处理后再查看是否在 check_set 中

![image-20211217160347727](https://image.lvbibir.cn/blog/image-20211217160347727.png)

再回头看之前的 `/usr/lib/python3.7/site-packages/cloudinit/config/cc_set_passwords.py` 文件是怎样对 util.is_true 和 util.is_false 传参的

可以看到是由 handle_ssh_pwauth() 函数传进来的

![image-20211217160810182](https://image.lvbibir.cn/blog/image-20211217160810182.png)

再继续找哪个文件调用了这个函数

还是这个文件，第 230 行

![image-20211217160953184](https://image.lvbibir.cn/blog/image-20211217160953184.png)

这里参数 pw_auth 传的值是 cfg.get('ssh_pwauth')

![image-20211217161055461](https://image.lvbibir.cn/blog/image-20211217161055461.png)

cfg.get() 这个函数 get 的东西是 `/etc/cloud/cloud.cfg` 配置文件下的 `ssh_pwauth` 的值

![image-20211217161359350](https://image.lvbibir.cn/blog/image-20211217161359350.png)

到这里，就可以回头再看整个逻辑了

1. 调用 handle_ssh_pwauth() 函数，传了一个参数 pw_auth=0
2. 调用 util.is_true() 和 util.is_false 函数，传了同一个参数 val=0
3. 上述两个函数执行完后 cfg_val 的值最终为 no
4. 调用 update_ssh_config({cfg_name: cfg_val}) 函数，cfg_name=PasswordAuthentication，cfg_val=no
5. 即将 sshd 的配置文件的 PasswordAuthentication 值改为 no

以上
