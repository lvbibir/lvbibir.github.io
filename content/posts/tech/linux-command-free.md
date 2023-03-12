---
title: "free命令详解" 
date: 2021-08-01
lastmod: 2021-08-01
tags: 
- linux
keywords:
- linux
- free
description: "centos中free命令详解，以及centos6和centos7中free命令的不同" 
cover:
    image: "" 
---
# CentOS6及以前

在CentOS6及以前的版本中，free命令输出是这样的：

```shell
[root@wordpress ~]# free -m
             total           used      free    shared    buffers     cached
Mem:         1002            769       233       0         62         421
-/+ buffers/cache:           286       716
Swap:         1153           0         1153
```

第一行：

​	系统内存主要分为五部分：`total`(系统内存总量)，`used`(程序已使用内存)，`free`(空闲内存)，`buffers`(buffer cache)，`cached`(Page cache)。

​	系统总内存total = used + free； buffers和cached被算在used里，因此第一行系统已使用内存used = buffers + cached + 第二行系统已使用内存used

​	由于buffers和cached在系统需要时可以被回收使用，因此系统可用内存 = free + buffers + cached；

​	shared为程序共享的内存空间，往往为0。

第二行：

　　正因为buffers和cached中的一部分内存容量在系统需要时可以被回收使用，因此buffer和cached中有部分内存其实可以算作可用内存，因此：

- 系统已使用内存，即第二行的used = total - 第二行free

- 系统可用内存，即第二行的free = 第一行的free + buffers + cached

第三行：

　　swap内存交换空间使用情况

#  CentOS7及以后

CentOS7及以后free命令的输出如下：

```shell
[root@wordpress ~]# free -m
              total        used        free      shared  buff/cache   available
Mem:           1839         866          74          97         897         695
Swap:             0           0           0
```

buffer和cached被合成一组，加入了一个available，关于此available，文档上的说明如下：

>  MemAvailable: An estimate of how much memory is available for starting new applications, without swapping.

即系统可用内存，之前说过由于buffer和cache可以在需要时被释放回收，系统可用内存即 free + buffer + cache，在CentOS7之后这种说法并不准确，因为并不是所有的buffer/cache空间都可以被回收。

即available = free + buffer/cache - 不可被回收内存(共享内存段、tmpfs、ramfs等)。

因此在CentOS7之后，用户不需要去计算buffer/cache，即可以看到还有多少内存可用，更加简单直观。

#  buffer/cache相关介绍

## 什么是buffer/cache？

　　buffer 和 cache 是两个在计算机技术中被用滥的名词，放在不通语境下会有不同的意义。在 Linux 的内存管理中，这里的 buffer 指 Linux 内存的： Buffer cache 。这里的 cache 指 Linux 内存中的： Page cache 。翻译成中文可以叫做缓冲区缓存和页面缓存。在历史上，它们一个（ buffer ）被用来当成对 io 设备写的缓存，而另一个（ cache ）被用来当作对 io 设备的读缓存，这里的 io 设备，主要指的是块设备文件和文件系统上的普通文件。但是现在，它们的意义已经不一样了。在当前的内核中， page cache 顾名思义就是针对内存页的缓存，说白了就是，如果有内存是以 page 进行分配管理的，都可以使用 page cache 作为其缓存来管理使用。当然，不是所有的内存都是以页（ page ）进行管理的，也有很多是针对块（ block ）进行管理的，这部分内存使用如果要用到 cache 功能，则都集中到 buffer cache 中来使用。（从这个角度出发，是不是 buffer cache 改名叫做 block cache 更好？）然而，也不是所有块（ block ）都有固定长度，系统上块的长度主要是根据所使用的块设备决定的，而页长度在 X86 上无论是 32 位还是 64 位都是 4k 。

　　明白了这两套缓存系统的区别，就可以理解它们究竟都可以用来做什么了。

## 什么是 page cache

　　Page cache 主要用来作为文件系统上的文件数据的缓存来用，尤其是针对当进程对文件有 read ／ write 操作的时候。如果你仔细想想的话，作为可以映射文件到内存的系统调用： mmap 是不是很自然的也应该用到 page cache ？在当前的系统实现里， page cache 也被作为其它文件类型的缓存设备来用，所以事实上 page cache 也负责了大部分的块设备文件的缓存工作。

## 什么是 buffer cache

　　Buffer cache 则主要是设计用来在系统对块设备进行读写的时候，对块进行数据缓存的系统来使用。这意味着某些对块的操作会使用 buffer cache 进行缓存，比如我们在格式化文件系统的时候。一般情况下两个缓存系统是一起配合使用的，比如当我们对一个文件进行写操作的时候， page cache 的内容会被改变，而 buffer cache 则可以用来将 page 标记为不同的缓冲区，并记录是哪一个缓冲区被修改了。这样，内核在后续执行脏数据的回写（ writeback ）时，就不用将整个 page 写回，而只需要写回修改的部分即可。

## 如何回收 cache ？

　　Linux 内核会在内存将要耗尽的时候，触发内存回收的工作，以便释放出内存给急需内存的进程使用。一般情况下，这个操作中主要的内存释放都来自于对 buffer ／ cache 的释放。尤其是被使用更多的 cache 空间。既然它主要用来做缓存，只是在内存够用的时候加快进程对文件的读写速度，那么在内存压力较大的情况下，当然有必要清空释放 cache ，作为 free 空间分给相关进程使用。所以一般情况下，我们认为 buffer/cache 空间可以被释放，这个理解是正确的。

　　但是这种清缓存的工作也并不是没有成本。理解 cache 是干什么的就可以明白清缓存必须保证 cache 中的数据跟对应文件中的数据一致，才能对 cache 进行释放。所以伴随着 cache 清除的行为的，一般都是系统 IO 飙高。因为内核要对比 cache 中的数据和对应硬盘文件上的数据是否一致，如果不一致需要写回，之后才能回收。

　　在系统中除了内存将被耗尽的时候可以清缓存以外，我们还可以使用下面这个文件来人工触发缓存清除的操作

[root@tencent64 ~]# cat /proc/sys/vm/drop_caches 

方法是：

```
echo 3 > /proc/sys/vm/drop_caches
```

当然，这个文件可以设置的值分别为 1 、 2 、 3 。它们所表示的含义为：

```bash
表示清除 pagecache 
echo 1 > /proc/sys/vm/drop_caches

表示清除回收 slab 分配器中的对象（包括目录项缓存和 inode 缓存）。 slab 分配器是内核中管理内存的一种机制，其中很多缓存数据实现都是用的 pagecache 
echo 2 > /proc/sys/vm/drop_caches

表示清除 pagecache 和 slab 分配器中的缓存对象。
echo 3 > /proc/sys/vm/drop_caches
```

# 参考

https://blog.csdn.net/qq_41781322/article/details/87187957



