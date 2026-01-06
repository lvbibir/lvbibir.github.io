---
title: "troubleshooting | ssh 成功但是 scp 失败"
date: 2024-01-09
lastmod: 2024-01-28
tags:
  - openssh
  - troubleshooting
keywords:
  - linux
  - openssh
  - scp
  - troubleshooting
description: ""
cover:
    image: "images/cover-default.webp"
---

# 0 前言

前段时间在配置 jenkins publish over ssh 时发现 jenkins 无法连接某个服务器, 经测试 ssh 可以正常登录, 但是 scp 时报错 `subsystem request failed on channel 0`, 记录一下这个问题的排查思路

# 1 大致思路

影响到 ssh 的配置无非是以下这些:

- 网络问题: server 和 client 之间的网络不通或者防火墙配置
- 认证问题: 账号密码或者密钥错误
- 配置问题:
    - server 端本身 sshd 服务报错未正常
    - server 端拒绝 client 的加密算法, 常出现在旧版本 ssh 连接高版本时出现
    - server 端拒绝某些用户的登录, 比如生产环境基本都禁止 root 登录

大致思路是尽量找相同配置的 server 和 client 进行交叉验证对比, 定位问题点, 涉及到如下四个角色, 本次故障是在 `client-docker` 在 scp `server-1` 时出现的

| 角色 | OS 版本 | ssh 版本 | 备注 |
| ---- | ---- | ---- | ---- |
| client-1 | Centos 7.9 | OpenSSH_7.4p1 |  |
| client-docker | docker container | OpenSSH_9.2p1 | fail |
| server-1 | Centos 7.9 | OpenSSH_7.4p1 | fail |
| server-2 | Centos 7.9 | OpenSSH_7.4p1 |  |

经测试, 除了上述故障, 所有 client 对所有 server 执行 ssh 或者 scp 都是没有问题的, 能 ssh 成功其实就代表出现问题的地方并不是我们之前预想的那些

# 2 debug

那就纳闷了, 幸好 scp 命令提供了 `-v` 参数, 可以展示出更多的 debug 信息, 于是着手将异常 scp 的 debug 信息与正常 scp 的 debug 信息进行对比, 开始愉快的 `找不同` 环节

(正常情况) client-1 scp server-1 的 debug 信息

```plaintext
# scp -v test app@server-1:/home/app/
......
debug1: Authentication succeeded (password).
Authenticated to 11.53.57.80 ([11.53.57.80]:22).
debug1: channel 0: new [client-session]
debug1: Requesting no-more-sessions@openssh.com
debug1: Entering interactive session.
debug1: pledge: network
debug1: client_input_global_request: rtype hostkeys-00@openssh.com want_reply 0
debug1: Sending environment.
debug1: Sending env LANG = en_US.UTF-8
debug1: Sending command: scp -v -t /home/app/
Sending file modes: C0644 0 test
Sink: C0644 0 test
test       100%    0     0.0KB/s   00:00
debug1: client_input_channel_req: channel 0 rtype exit-status reply 0
debug1: channel 0: free: client-session, nchannels 1
debug1: fd 0 clearing O_NONBLOCK
debug1: fd 1 clearing O_NONBLOCK
Transferred: sent 2120, received 2344 bytes, in 0.2 seconds
Bytes per second: sent 12262.0, received 13557.6
debug1: Exit status 0
```

(正常情况) client-docker scp server-2 的 debug 信息

```plaintext
# scp -v test app@server-2:/home/app/
......
Authenticated to 11.53.57.74 ([11.53.57.74]:22) using "password".
debug1: channel 0: new session [client-session] (inactive timeout: 0)
debug1: Requesting no-more-sessions@openssh.com
debug1: Entering interactive session.
debug1: pledge: filesystem
debug1: client_input_global_request: rtype hostkeys-00@openssh.com want_reply 0
debug1: client_input_hostkeys: searching /root/.ssh/known_hosts for 11.53.57.74 / (none)
debug1: client_input_hostkeys: searching /root/.ssh/known_hosts2 for 11.53.57.74 / (none)
debug1: client_input_hostkeys: hostkeys file /root/.ssh/known_hosts2 does not exist
debug1: Sending environment.
debug1: channel 0: setting env LANG = "C.UTF-8"
debug1: Sending subsystem: sftp
debug1: client_global_hostkeys_prove_confirm: server used untrusted RSA signature algorithm ssh-rsa for key 0, disregarding
debug1: update_known_hosts: known hosts file /root/.ssh/known_hosts2 does not exist
debug1: pledge: fork
test      100%    0     0.0KB/s   00:00
scp: debug1: truncating at 0
debug1: client_input_channel_req: channel 0 rtype exit-status reply 0
debug1: channel 0: free: client-session, nchannels 1
Transferred: sent 3124, received 3084 bytes, in 0.0 seconds
Bytes per second: sent 88478.9, received 87346.1
debug1: Exit status 0
```

(异常情况) client-docker scp server-1 的 debug 信息

```plaintext
# scp -v test app@server-1:/home/app/
......
Authenticated to 11.53.57.80 ([11.53.57.80]:22) using "password".
debug1: channel 0: new session [client-session] (inactive timeout: 0)
debug1: Requesting no-more-sessions@openssh.com
debug1: Entering interactive session.
debug1: pledge: filesystem
debug1: client_input_global_request: rtype hostkeys-00@openssh.com want_reply 0
debug1: client_input_hostkeys: searching /root/.ssh/known_hosts for 11.53.57.80 / (none)
debug1: client_input_hostkeys: searching /root/.ssh/known_hosts2 for 11.53.57.80 / (none)
debug1: client_input_hostkeys: hostkeys file /root/.ssh/known_hosts2 does not exist
debug1: Sending environment.
debug1: channel 0: setting env LANG = "C.UTF-8"
debug1: Sending subsystem: sftp
debug1: client_global_hostkeys_prove_confirm: server used untrusted RSA signature algorithm ssh-rsa for key 0, disregarding
debug1: update_known_hosts: known hosts file /root/.ssh/known_hosts2 does not exist
debug1: pledge: fork
subsystem request failed on channel 0
scp: Connection closed
```

排除冗余信息后可以发现:

- (正常情况) client-1 scp server-1 的 debug 信息中, `Sending environment` 之后的步骤是 `Sending command: scp -v -t /home/app/`
- (正常情况) client-docker scp server-2 的 debug 信息中, `Sending environment` 之后的步骤是 `Sending subsystem: sftp`
- (异常情况) client-docker scp server-1 的 debug 信息中, `Sending environment` 之后的步骤是 `Sending subsystem: sftp`, 但是 `subsystem request failed`

可以推断出问题点在于 scp 的流程中调用了 sftp, 但由于 sftp 的某些原因导致出现了问题

# 3 sftp

遂去对比一下两个 server 的 ssh 配置中关于 sftp 的配置

正常 server 的配置

```plaintext
# grep -i 'sftp' /etc/ssh/sshd_config

#Subsystem      sftp    /usr/libexec/openssh/sftp-server
Subsystem sftp internal-sftp
Match Group sftp
ChrootDirectory /data/sftp/mysftp
ForceCommand internal-sftp
```

异常 server 的配置

```plaintext
# grep -i 'sftp' /etc/ssh/sshd_config

#Subsystem      sftp    /usr/libexec/openssh/sftp-server
```

可以看到异常 server 的 sftp 是没开的

去掉 sftp 的注释后重启 sshd, 再次进行尝试后不出意料地恢复正常了

# 4 总结

至此, 我们可以确定问题点是由于 scp 中使用 sftp 协议进行传输, 而 server 端未开启 sftp 导致 scp 失败

最后就是确认一下为什么 scp 会调用 sftp, 在 [openssh 9.0p1 release](https://www.openssh.com/txt/release-9.0) 中发现如下说明:

> This release switches [scp(1)](https://man.openbsd.org/scp.1) from using the legacy scp/rcp protocol to using the SFTP protocol by default.

从 9.0p1 开始, scp 将默认使用 sftp 进行传输, 可以使用 `-O` 选项使 scp 使用 `legacy SCP protocol` 进行传输

以上
