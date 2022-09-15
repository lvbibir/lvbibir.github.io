---
title: "ssh服务异常 | cloud-init自动修改ssh配置文件" 
date: 2021-12-01
lastmod: 2021-12-01
tags: 
- openstack
keywords:
- openstack
- cloud-init
- ssh
description: "介绍cloud-init是如何将ssh配置文件的PasswordAuthentication参数值修改为no的" 
cover:
    image: "" 
---
# 前言
在openEuler20.03 (LTS-SP1)系统上进行一些测试，发现某个东西会自动修改ssh配置文件导致系统无法通过密码登录，最后排查是由于安装了cloud-init导致的。

![image-20211217152941463](https://image.lvbibir.cn/blog/image-20211217152941463.png)

以下是大致的排查思路

出现这个问题前做的操作是安装了一些项目组同事指定的包，问题就应该出在这些包上

```
yum install -y telnet rsync ntpdate zip unzip libaio dos2unix sos vim vim-enhanced net-tools man ftp lrzsz psmisc gzip network-scripts cloud-init cloud-utils-growpart tar libnsl authselect-compat
```

大致看了下，除了cloud-Init和cloud-utils-growpart这两个包其他包基本不可能去修改ssh的配置

直接检索这两个包的所有文件中的配置，是否与PasswordAuthentication有关

```
[root@localhost ~]# grep -nr PasswordAuthentication `rpm -ql cloud-utils-growpart`
[root@localhost ~]# grep -nr PasswordAuthentication `rpm -ql cloud-init`
```

找到了修改这个参数代码的具体实现

![image-20211217153934057](https://image.lvbibir.cn/blog/image-20211217153934057.png)

查看该文件

```
[root@localhost ~]# vim +98 /usr/lib/python3.7/site-packages/cloudinit/config/cc_set_passwords.py
```

具体的判断操作和修改操作

![image-20211217154333149](https://image.lvbibir.cn/blog/image-20211217154333149.png)

修改操作就不去深究了，主要看下判断操作，可以看到判断操作是使用了 util.is_true() ，该util模块也在该文件中引用了

![image-20211217154537176](https://image.lvbibir.cn/blog/image-20211217154537176.png)

再去找这个util模块的具体实现

python引用的模块路径如下，否则会抛出错误

- 文件的同级路径下
- sys.path 路径下

并没有在同级目录下

```
[root@localhost ~]# ll /usr/lib/python3.7/site-packages/cloudinit/config/ | grep cloudinit
```

sys.path 路径不知道可以用python终端输出下

![image-20211217155010363](https://image.lvbibir.cn/blog/image-20211217155010363.png)

在/usr/lib/python3.7/site-packages路径下找到了cloudinit模块的util子模块

![image-20211217155130708](https://image.lvbibir.cn/blog/image-20211217155130708.png)

查看util.is_true和util.is_false具体的函数实现

![image-20211217160135163](https://image.lvbibir.cn/blog/image-20211217160135163.png)

逻辑很简单，判断 val 参数是否为bool值，否则对val参数的值进行处理后再查看是否在check_set中

![image-20211217160347727](https://image.lvbibir.cn/blog/image-20211217160347727.png)

再回头看之前的`/usr/lib/python3.7/site-packages/cloudinit/config/cc_set_passwords.py`文件是怎样对util.is_true和util.is_false传参的

可以看到是由handle_ssh_pwauth()函数传进来的

![image-20211217160810182](https://image.lvbibir.cn/blog/image-20211217160810182.png)

再继续找哪个文件调用了这个函数

还是这个文件，第230行

![image-20211217160953184](https://image.lvbibir.cn/blog/image-20211217160953184.png)

这里参数pw_auth传的值是cfg.get('ssh_pwauth')

![image-20211217161055461](https://image.lvbibir.cn/blog/image-20211217161055461.png)

cfg.get()这个函数get的东西是`/etc/cloud/cloud.cfg`配置文件下的`ssh_pwauth`的值

![image-20211217161359350](https://image.lvbibir.cn/blog/image-20211217161359350.png)

到这里，就可以回头再看整个逻辑了

1. 调用handle_ssh_pwauth()函数，传了一个参数 pw_auth=0
2. 调用util.is_true()和util.is_false函数，传了同一个参数 val=0
3. 上述两个函数执行完后cfg_val的值最终为no
4. 调用update_ssh_config({cfg_name: cfg_val})函数，cfg_name=PasswordAuthentication，cfg_val=no
5. 即将sshd的配置文件的PasswordAuthentication值改为no
