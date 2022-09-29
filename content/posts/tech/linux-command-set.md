---
title: "set命令详解" 
date: 2022-09-28
lastmod: 2022-09-28
tags: 
- linux
keywords:
- linux
- set
description: "" 
---

Bash有一个内置的`set`命令，可以用来查看、设置、取消shell选项

set设置的选项无法被继承，仅对当前的bash环境有效，bash命令也可以直接使用set的单字符选项来开启一个自定义参数的子bash环境，比如执行的脚本

- 查看： echo $- 和 set -o 和 echo ${SHELLOPTS}
- 设置： set -abefhkmnptuvxBCHP 和 set -o options-name
- 取消： set +abefhkmnptuvxBCHP 和 set +o options-name

`set -`和`set +`设置单字符选项，使用`echo $-`查看当前shell**开启**的单字符选项

`set -o `和`set +o `设置多字符选项，使用`set -o`查看当前shell所有的多字符选项的状态(**开启或关闭**)

使用`echo ${SHELLOPTS}`查看当前shell开启的长格式选项

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
