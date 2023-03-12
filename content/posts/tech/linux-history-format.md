---
title: "linux中history命令的格式化输出" 
date: 2022-11-07
lastmod: 2022-11-07
tags: 
- linux
keywords:
- linux
- history
description: "" 
---

在`/etc/prifile.d`目录下新建一个文件，用户登录系统时自动生效

```bash
vim  /etc/profile.d/history_conf.sh
source /etc/profile.d/history_conf.sh # 手动生效
```

文件内容

```bash
export HISTFILE="$HOME/.bash_history"  # 指定命令写入文件(默认~/.bash_history)
export HISTSIZE=1000  # history输出记录数
export HISTFILESIZE=10000  # HISTFILE文件记录数
export HISTIGNORE="cmd1:cmd2:..."  # 忽略指定cmd1,cmd2...的命令不被记录到文件；(加参数时会记录)
export HISTCONTOL=ignoredups   # ignoredups 不记录“重复”的命令；连续且相同 方为“重复” ；
                               # ignorespace 不记录所有以空格开头的命令；
                               # ignoreboth 表示ignoredups:ignorespace ,效果相当于以上两种的组合；
                               # erasedups 删除重复命令；
export PROMPT_COMMAND="history -a"  # 设置每条命令执行完立即写入HISTFILE(默认等待退出会话写入)
export HISTTIMEFORMAT="`whoami` %F %T "  # 设置命令执行时间格式，记录文件增加时间戳
shopt -s histappend  # 防止会话退出时覆盖其他会话写到HISTFILE的内容；
```

效果如下

![image-20221107142133035](https://image.lvbibir.cn/blog/image-20221107142133035.png)
