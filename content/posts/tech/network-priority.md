---
title: "windows & linux 多网卡时设置默认路由以及添加静态路由" 
date: 2022-06-01
lastmod: 2022-06-01
tags: 
- linux
- windows
keywords:
- linux
- windows
- network
description: "介绍centos和windows中分别如何配置多网卡时以实现灵活的网络访问" 
cover:
    image: "" 
---
# 前言

在工作中需要连接公司内网（有线，不可联网），访问外网时需要连接无线

同时接入这两个网络时，内网访问正常，外网无法访问。

此时可以通过调整网络优先级及配置路由实现内外网同时访问

>  一般来说，内网的网段数量较少，我们可以配置使默认路由走外网，走内网时通过配置的静态路由

# centos8

在 linux 系统中网络优先级是通过 `metric` 控制的，值越小，优先级越高，通过`route -n` 查看路由

![image-20220817140544169](https://image.lvbibir.cn/blog/image-20220817140544169.png)

可以通过修改配置文件实现，在网卡配置文件中添加或者修改 `IPV4_ROUTE_METRIC=100` 参数实现，之后重启网络服务

```
# network
systemctl restart network

# NetworkManager
nmcli c reload
nmcli c down enp3s0
nmcli c up enp3s0

route -n
```

## 添加路由

临时添加静态路由命令如下（重启服务器或者重启网络服务后消失）

```
route add -net 192.168.45.0  netmask 255.255.255.0 dev enp4s0 metric 3
```

永久添加静态路由

参照 `/etc/init.d/network` 中对 `/etc/sysconfig/static-routes` 是如何处理的

> /etc/sysconfig/static-routes 文件不存在的话，创建一个即可

```shell
 # Add non interface-specific static-routes.
    if [ -f /etc/sysconfig/static-routes ]; then
        if [ -x /sbin/route ]; then
            grep "^any" /etc/sysconfig/static-routes | while read ignore args ; do
                /sbin/route add -$args
            done
        else
            net_log $"Legacy static-route support not available: /sbin/route not found"
        fi
    fi
```

则，如果添加一条静态路由的路由如下

```
route add -net 192.168.45.0  netmask 255.255.255.0 dev enp4s0 metric 3
```

那么，在 `/etc/sysconfig/static-routes` 中对应的则应该写为

```
any -net 192.168.45.0  netmask 255.255.255.0 dev enp4s0 metric 3
```





# win10

## 调整网络优先级

查看默认路由

```powershell
route print 0.0.0.0
```

![image-20220426100126587](http://image.lvbibir.cn/blog/image-20220426100126587.png)

这两个路由分别是内网和外网的默认路由，绝大部分情况网络都是走的默认路由，但这里有两条默认路由，默认路由的优先级是按照跃点数的多少决定的，跃点数越少，优先级越高

将外网无线的跃点数调小

![image-20220427095904443](http://image.lvbibir.cn/blog/image-20220427095904443.png)

route print可以看到跃点数修改成功了，此时外网无线的跃点数更小，优先级更高

![image-20220427100101830](http://image.lvbibir.cn/blog/image-20220427100101830.png)

## 配置路由

配置路由需要以管理员权限运行powershell或者cmd

![image-20220427100911342](http://image.lvbibir.cn/blog/image-20220427100911342.png)

配置路由后，内网访问也没有问题了

```powershell
route add 172.16.2.0 mask 255.255.255.0 172.30.4.254 metric 3
route add 172.16.3.0 mask 255.255.255.0 172.30.4.254 metric 3
route add 172.16.4.0 mask 255.255.255.0 172.30.4.254 metric 3
```

这里配置的路由重启系统后会消失，加 `-p`选项设置为永久路由

```powershell
route add -p 172.16.2.0 mask 255.255.255.0 172.30.4.254 metric 3
```

![image-20220427101256061](http://image.lvbibir.cn/blog/image-20220427101256061.png)

