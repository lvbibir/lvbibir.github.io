---
title: "set命令详解" 
date: 2022-09-28
lastmod: 2022-09-28
tags: 
- linux
keywords:
- linux
description: "" 
---

Bash有一个内置的`set`命令，可以用来查看、设置、取消shell选项

- 查看： echo $- 和 set -o
- 设置： set -abefhkmnptuvxBCHP 和 set -o options-name
- 取消： set +abefhkmnptuvxBCHP 和 set +o options-name

`set -`和`set +`设置短格式参数，使用`echo $-`查看**开启**的短格式参数

`set -o `和`set +o `设置长格式参数，使用`set -o`查看所有的长格式参数的状态(**开启或关闭**)

所有的短格式选项都可以找到对应的长格式选项，长格式选项多了emacs、history、ignoreeof、nolog、pipefail、posix、vi。详见set命令的man手册

例如 `set -B` 和`set -o braceexpand` 是等效的，注意这里的设置和取消有点反常识：**设置用 -，关闭反而是用 +**

```
[root@lvbibir ~]# echo $-
himBH

# set + 方式去除B选项，相应的 set -o 中的 braceexpand 选项也关闭了
[root@lvbibir ~]# set +B
[root@lvbibir ~]# echo $-
himH
[root@lvbibir ~]# set -o | grep braceexpand
braceexpand     off

# set -o 开启 braceexpand 选项，相应的 echo $- 中的 B 选项也开启了
[root@lvbibir ~]# set -o braceexpand
[root@lvbibir ~]# echo $-
himBH
[root@lvbibir ~]# set -o | grep braceexpand
braceexpand     on
```
