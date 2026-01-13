---
title: "linux | dns 配置文件中 search 和 options ndots 详解" 
date: 2023-04-13
lastmod: 2024-01-27
tags:
  - linux
keywords:
  - linux
  - dns
  - network
description: "linux 中 dns 配置文件中的 search 和 options ndots 详解"
cover:
    image: "/images/cover-linux.png"
---

# 0 前言

dns 配置文件 `/etc/resolv.conf` 中常看到有 `search` 设置，以前以为是根据 search 中的域去指定 nameserver，其实不是这样用的。它的一个用处是程序只需要知道主机名就可以解析到 ip，不必知道域名后缀 `domain` 是什么

FQDN (Fully Qualified Domain Name) 含义是完整的域名. 例如, 一台机器主机名 (hostname) 是 `www`, 域名后缀 (domain) 是 `baidu.com`, 那么该主机的 FQDN 应该是 `www.baidu.com.` 最后是以 `.` 来结尾的, 但是大部分的应用和服务器都允许忽略最后这个点 `.` 所有大家直接输入 `www.baidu.com` 也可以识别

> <https://www.man7.org/linux/man-pages/man5/resolv.conf.5.html>

# 1 search

下面以几个示例演示一下 `search` 是如何工作的

/etc/resolv.conf 配置文件内容

```none
nameserver 8.8.8.8
search foo.local bar.local
```

解析 `test` ，优先以 `hostname` 的形式拼接到 `search` 中配置的 `domain` 上进行查询，如果失败直接以 `FQDN` 的形式查询

```bash
[root@k8s-node1 ~]# host -a test
Trying "test.foo.local"
Trying "test.bar.local"
Trying "test"
Host test not found: 3(NXDOMAIN)
Received 97 bytes from 8.8.8.8#53 in 53 ms
```

解析 `test.hello` ，优先以 `FQDN` 的形式查询，如果失败则以 `hostname` 的形式拼接到 `search` 中配置的 `domain` 上进行查询

```bash
[root@k8s-node1 ~]# host -a test.hello
Trying "test.hello"
Received 103 bytes from 8.8.8.8#53 in 48 ms
Trying "test.hello.foo.local"
Trying "test.hello.bar.local"
Host test.hello not found: 3(NXDOMAIN)
Received 113 bytes from 8.8.8.8#53 in 49 ms
```

解析 `test.` ，直接认定为 `FQDN` ，以 `FQDN` 的形式查询，不会进行拼接查询

```bash
[root@k8s-node1 ~]# host -a test.
Trying "test"
Host test. not found: 3(NXDOMAIN)
Received 97 bytes from 8.8.8.8#53 in 54 ms
```

# 2 options ndots

可以发现，配置了 `search` 之后，除非以最后一种形式查询，总会将 `hostname` 和 `search` 进行拼接查询

其实它是由 `options ndots:[number]` 选项控制的：当查询的域名有 `>=` number 个 `.` 时，优先以 `FQDN` 的形式查询，如果失败再拼接查询

配置 `/etc/resolv.conf`

```none
nameserver 8.8.8.8
search foo.local bar.local
options ndots:2
```

观察下述示例

- test

  ```bash
  [root@k8s-node1 ~]# host -a test
  Trying "test.foo.local"
  Trying "test.bar.local"
  Trying "test"
  Host test not found: 3(NXDOMAIN)
  Received 97 bytes from 8.8.8.8#53 in 45 ms
  ```

- test.hello

  ```bash
  [root@k8s-node1 ~]# host -a test.hello
  Trying "test.hello.foo.local"
  Trying "test.hello.bar.local"
  Trying "test.hello"
  Host test.hello not found: 3(NXDOMAIN)
  Received 103 bytes from 8.8.8.8#53 in 46 ms
  ```

- test.hello.world

  ```bash
  [root@k8s-node1 ~]# host -a test.hello.world
  Trying "test.hello.world"
  Received 119 bytes from 8.8.8.8#53 in 57 ms
  Trying "test.hello.world.foo.local"
  Trying "test.hello.world.bar.local"
  Host test.hello.world not found: 3(NXDOMAIN)
  Received 119 bytes from 8.8.8.8#53 in 45 ms
  ```

- test.

  ```bash
  [root@k8s-node1 ~]# host -a test.
  Trying "test"
  Host test. not found: 3(NXDOMAIN)
  Received 97 bytes from 8.8.8.8#53 in 45 ms
  ```

以上
