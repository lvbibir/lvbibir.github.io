---
title: "shell | 不同执行方式的区别" 
date: 2022-06-01
lastmod: 2022-06-01
tags: 
- shell
keywords:
- shell
description: "" 
cover:
    image: "https://image.lvbibir.cn/blog/shell.png" 
---


shell 脚本通常有 `sh filename`、`bash filename`、`./filename`、`source filename` 这四种执行方式

- `source filename` 可以使用 `. filename` 代替，在当前的 bash 环境下读取并执行脚本文件中的命令，且脚本文件的变量，在脚本执行完成后会保存下来
- `./filename` 和  `sh filename` 或者  `bash filename`  是等效的，都是开启一个子shell来运行脚本文件，脚本中设置的变量执行完毕后不会保存

> 除`./filename` 外，`source filename` 、`. filename` 、`sh filename`  、`bash filename` 都是不需要执行权限的                                    

变量和权限问题示例

```bash
# 设置临时变量，仅在当前 bash 环境生效
[root@lvbibir ~]# name=lvbibir
[root@lvbibir ~]# echo $name
lvbibir
[root@lvbibir ~]#
[root@lvbibir ~]# cat test.sh
#!/bin/bash
echo $name

# source 或者 . 可以获取到父 bash 环境的变量
[root@lvbibir ~]# source test.sh
lvbibir
[root@lvbibir ~]# . test.sh
lvbibir

# sh、bash、./三种方式都使用了子 bash 环境，所以无法获取父 bash 环境的变量
# ./ 方式需要脚本有执行权限
[root@lvbibir ~]# sh test.sh

[root@lvbibir ~]# bash test.sh

[root@lvbibir ~]# ./test.sh
-bash: ./test.sh: Permission denied
[root@lvbibir ~]# chmod a+x test.sh
[root@lvbibir ~]# ./test.sh

```

同理，使用 source 或者 . 也可以在 bash 环境中获取到脚本中设置的变量

```bash
[root@lvbibir ~]# cat > test.sh << EOF
> #!/bin/bash
> number=22
>
> EOF
[root@lvbibir ~]# echo $number

# sh bash ./ 三种方式无法获取脚本中的变量
[root@lvbibir ~]#
[root@lvbibir ~]# sh test.sh
[root@lvbibir ~]# echo $number

[root@lvbibir ~]# bash test.sh
[root@lvbibir ~]# echo $number

[root@lvbibir ~]# ./test.sh
[root@lvbibir ~]# echo $number

# source 方式可以获取脚本中的变量
[root@lvbibir ~]# source test.sh
[root@lvbibir ~]# echo $number
22
[root@lvbibir ~]#
```

# 其他问题

关于是否在子 bash 环境运行的区别出了变量问题还会存在一些其他影响，如下测试

已知目前存在一个 mysqld 进程，其 pid 为 29426 ，写一个监控pid的脚本

```bash
[root@lvbibir ~]# cat test.sh
#!/bin/bash
process=$1
pid=$(ps -elf | grep $process | grep -v grep | awk '{print $4}')
echo $pid
```

两种方式分别运行一下

```bash
[root@lvbibir ~]# sh test.sh mysqld
27038 27039 29426
[root@lvbibir ~]# bash test.sh mysqld
27047 27048 29426
[root@lvbibir ~]# ./test.sh mysqld
27056 27057 29426
[root@lvbibir ~]#
[root@lvbibir ~]# source test.sh mysqld
29426
[root@lvbibir ~]# . test.sh mysqld
29426
[root@lvbibir ~]#
```

问题出现了，由于某种原因导致子 bash 环境中执行的脚本监控到多个 pid ，给脚本添加个 sleep 来看下

```bash
[root@lvbibir ~]# cat test.sh
#!/bin/bash
process=$1
pid=$(ps -elf | grep $process | grep -v grep | awk '{print $4}')
echo $pid
sleep 30

[root@lvbibir ~]# ./test.sh mysqld
27396 27397 29426
```

新开一个终端，查看进程

![image-20220630160731914](https://image.lvbibir.cn/blog/image-20220630160731914.png)

- 第一个pid是在子shell中执行监控脚本的进程号
- 第二个pid不太清楚哪里来的，也grep不到这个进程号，应该是脚本执行一瞬间就释放掉了
- 第三个pid是mysql实际运行中的进程号

实际中脚本的pid和mysqld的pid顺序不太一样，取决于pid的大小

在脚本再添加个 grep 过滤掉脚本本身的进程来规避这个问题

```bash
[root@lvbibir ~]# cat test.sh
#!/bin/bash
process=$1
pid=$(ps -elf | grep $process | grep -v grep | grep -v bash | awk '{print $4}')
echo $pid

[root@lvbibir ~]# ./test.sh mysqld
29426
```



# 参考

https://blog.csdn.net/houxiaoni01/article/details/105161356