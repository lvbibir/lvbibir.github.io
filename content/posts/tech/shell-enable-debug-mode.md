---
title: "shell | 开启 debug 模式" 
date: 2022-06-01
lastmod: 2024-01-28
tags:
  - shell
keywords:
  - shell
description: "" 
cover:
    image: "images/cover-shell.png" 
---

# 0 前言

本文参考以下链接:

- [Bash 脚本中的 set -euxo pipefail](https://zhuanlan.zhihu.com/p/107135290)

shell 脚本是没有 debug 模式的，不过可以通过 `set` 指令实现简单的 debug 功能

shell 脚本中默认每条指令都会从上到下依次执行，但是当某行指令报错时，我们大多数情况下是不希望继续执行后续指令的

这时可以使用 shell 脚本中 `set` 指令的四个参数：`-e、-u、-x、-o pipefail`

> 命令报错即返回值（$?）不为 0

# 1 set -e

`set -e` 选项可以在脚本出现异常的时候立即退出，后续命令不再执行，相当于打上了一个断点

`if` 判断条件里出现异常也会直接退出，如果不希望退出可以在判断语句后面加上 `|| true` 来阻止退出

## 1.1 before

脚本内容

foo 是一个不存在的命令，用于模拟命令报错

```bash
#!/bin/bash

foo
echo "hello"
```

执行结果

```bash
./test.sh: line 3: foo: command not found
hello
```

## 1.2 after

脚本内容

```bash
#!/bin/bash

set -e

foo
echo "hello"
```

执行结果

```bash
./test.sh: line 5: foo: command not found
```

## 1.3 阻止立即退出的例子

```bash
#!/bin/bash

set -e

foo || true
echo "hello"
```

```bash
./test.sh: line 5: foo: command not found
hello
```

# 2 set -o pipefail

默认情况下 bash 只会检查管道（pipelie）操作的最后一个命令的返回值，即最后一个命令返回值为 0 则判断整条管道语句是正确的

如下

![image-20220629145221486](/images/image-20220629-145221.png)

`set -o pipefail` 的作用就是管道中只要有一个命令失败，则整个管道视为失败

## 2.1 before

```bash
#!/bin/bash

set -e

foo | echo "a"
echo "hello"
```

```bash
./test.sh: line 5: foo: command not found
a
hello
```

## 2.2 after

```bash
#!/bin/bash

set -eo pipefail

foo | echo "a"
echo "hello"
```

```bash
./test.sh: line 5: foo: command not found
a
```

# 3 set -u

`set -u` 的作用是将所有未定义的变量视为错误，默认情况下 bash 会将未定义的变量视为空

## 3.1 before

```bash
#!/bin/bash

set -eo pipefail

echo $a
echo "hello"
```

```bash

hello
```

## 3.2 after

```bash
#!/bin/bash

set -euo pipefail

echo $a
echo "hello"
```

```bash
./test.sh: line 5: a: unbound variable
```

# 4 set -x

`set -x ` 可以让 bash 把每个命令在执行前先打印出来，好处显而易见，可以快速方便的找到出问题的脚本位置，坏处就是 bash 的 log 会格外的乱

另外，它在打印的时候会先把变量解析出来

纵然 log 可能会乱一些，但也比 debug 的时候掉头发强

```bash
#!/bin/bash

set -euox pipefail

a=2
echo $a
echo "hello"
```

```bash
+ a=2
+ echo 2   # 这里已经将变量 a 解析为 2 了
2
+ echo hello
hello
```

以上
