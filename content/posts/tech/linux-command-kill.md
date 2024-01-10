---
title: "linux | kill命令详解以及linux中的信号" 
date: 2023-04-09
lastmod: 2024-01-10
description: "" 
tags: 
- linux
keywords:
- linux
- kill
- sig
cover:
    image: "https://source.unsplash.com/random/400x200?code"
---

# 1. 简介

kill 命令很容易让人产生误解, 以为仅仅是用来终止 linux 中的进程.

在 man 手册中对 kill 命令的解释如下, 不难看出, kill 命令是一个用于将指定的 signal 发送给进程的工具

> DESCRIPTION
> The command kill sends the specified signal to the specified process or process group. If no signal is specified, the TERM signal is sent. The TERM signal will kill processes which do not catch this signal. For other processes, it may be necessary to use the KILL (9) signal, since this signal cannot be caught.
> Most modern shells have a builtin kill function, with a usage rather similar to that of the command described here. The '-a' and '-p' options, and the possibility to specify processes by command name are a local extension.
> If sig is 0, then no signal is sent, but error checking is still performed.

命令格式

```bash
kill [-s signal|-p] [-q sigval] [-a] [--] pid...
```

常用参数

```bash
-l      # 列出所有支持的signal
-s NAME # 使用NAME指定signal
-NUM    # 使用编号指定signal

kill -s HUP 和 kill -1 效果一样
```

# 2. 支持的信号

```bash
[root@lvbibir ~]# kill -l
 1) SIGHUP       2) SIGINT       3) SIGQUIT      4) SIGILL       5) SIGTRAP
 6) SIGABRT      7) SIGBUS       8) SIGFPE       9) SIGKILL     10) SIGUSR1
11) SIGSEGV     12) SIGUSR2     13) SIGPIPE     14) SIGALRM     15) SIGTERM
16) SIGSTKFLT   17) SIGCHLD     18) SIGCONT     19) SIGSTOP     20) SIGTSTP
21) SIGTTIN     22) SIGTTOU     23) SIGURG      24) SIGXCPU     25) SIGXFSZ
26) SIGVTALRM   27) SIGPROF     28) SIGWINCH    29) SIGIO       30) SIGPWR
31) SIGSYS      34) SIGRTMIN    35) SIGRTMIN+1  36) SIGRTMIN+2  37) SIGRTMIN+3
38) SIGRTMIN+4  39) SIGRTMIN+5  40) SIGRTMIN+6  41) SIGRTMIN+7  42) SIGRTMIN+8
43) SIGRTMIN+9  44) SIGRTMIN+10 45) SIGRTMIN+11 46) SIGRTMIN+12 47) SIGRTMIN+13
48) SIGRTMIN+14 49) SIGRTMIN+15 50) SIGRTMAX-14 51) SIGRTMAX-13 52) SIGRTMAX-12
53) SIGRTMAX-11 54) SIGRTMAX-10 55) SIGRTMAX-9  56) SIGRTMAX-8  57) SIGRTMAX-7
58) SIGRTMAX-6  59) SIGRTMAX-5  60) SIGRTMAX-4  61) SIGRTMAX-3  62) SIGRTMAX-2
63) SIGRTMAX-1  64) SIGRTMAX
```

可以看到 kill 支持的信号非常多, 在这些信号中只有 `9) SIGKILL` 可以无条件地终止 process, 其他信号都将依照 process 中定义的信号处理规则来进行忽略或者处理.

上述信号中常用的其实很少, 如下表所示

| 编号 | 名称    | 解释                                                         |
| ---- | ------- | ------------------------------------------------------------ |
| 1    | SIGHUP  | 启动被终止的程序, 也可以让进程重新读取自己的配置文件, 类似重新启动 |
| 2    | SIGINT  | 相当于输入 ctrl-c 来中断一个程序                             |
| 9    | SIGKILL | 强制中断一个程序, 不会进行资源的清理工作. 如果该程序进行到一半, 可能会有半成品产生, 类似 vim 的 .filename.swp 保留下来 |
| 15   | SIGTERM | 以正常 (优雅) 的方式来终止进程, 由程序自身决定该如何终止       |
| 19   | SIGSTOP | 相当于输入 ctrl-z 来暂停一个程序                             |

# 3. 常用命令

以正常的方式终止进程, 由于信号 15 是最常用也是最佳的程序退出方式, 所以 kill 命令不指定信号时, 默认使用的就是信号 15

```bash
kill pid
# 或者
kill -15 pid
```

强制终止进程

```bash
kill -9 pid
```
