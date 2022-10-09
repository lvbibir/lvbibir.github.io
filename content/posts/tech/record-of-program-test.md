---
title: "记一次程序测试" 
date: 2021-09-01
lastmod: 2021-09-01
tags: 
- linux
- 故障处理
keywords:
- linux
- openeuler
- C
- glibc
description: "" 
cover:
    image: "" 
---
# 前言

有需求需要在 openeuler 的操作系统上测试一个 C 程序，做了一个简化版的程序，程序很简单，循环读取一个文件并打印文件内容，在程序执行过程中使用 echo 手动向文件中追加内容，程序要能读取到，效果如下：

![e2796ca3c4850af67b578be9bb0148d](https://image.lvbibir.cn/blog/e2796ca3c4850af67b578be9bb0148d.png)

测试程序代码如下：

```c
#include<stdlib.h>
#include<stdio.h>
#include<unistd.h>

int main(int argc, char **argv)
{
        FILE *f = fopen("./Syslog.log", "rb");
        if (f == NULL) return 1;
        char buffer[1024] = {0};
        size_t len = 0;
        while(1)
        {
                len = fread(buffer, 1, sizeof(buffer), f);
                if (len > 0)
                {
                        buffer[len] = '\0';
                        printf("read:%s\n",buffer);
                }
                else
                {
                printf("noread\n");
                }
                sleep(2);
        }
        return 0;
}
```

在 Rhel-7.5 上测试一切正常，开始在 openeuler 上进行测试，结果发现后续追加的内容没有输出：

![dfaaeee2427fbc2fb21f825c9350cf9](https://image.lvbibir.cn/blog/dfaaeee2427fbc2fb21f825c9350cf9.png)

# 故障排查

考虑到影响程序执行结果的几个因素：程序本身，内核版本，gcc版本，glibc版本。

程序本身应该是没问题的，内核版本一般对C语言程序的影响也不会很大，还是优先看gcc版本和glibc版本。

按照思路进行了一些测试，测试结果：

- 可行：
- centos7.5（gcc-4.8.5，kernel-3.10，glibc<=2.28）
- centos7.5（gcc-7.3.0，kernel-3.10，glibc<=2.28）
- centos7.5（gcc-7.3.0，kernel-5.12，glibc<=2.28）
- 不可行：
- isoft-server-6.0（gcc-7.3.0，4.19.90，glibc>=2.28）
- centos8（gcc-8.4.0，kernel-4.18.0，glibc>=2.28）
- openeuler-20.03-LTS-SP1（gcc-7.3.0，kernel-4.19.90，glibc>=2.28）

按照测试结果，似乎 gcc 版本和内核版本对程序没什么影响，大概率应该是 glibc 版本导致的。由于程序很简单，只是以 rb 方式 fopen 打开文件循环读取文件内容，求证(google)起来也比较轻松，很快就找到了问题在哪：**glibc 2.28修复了 fread 的行为**

这个 glibc 的 bug 是05年提的，到18年才修复，也是担心 break 之前大量的代码。https://sourceware.org/bugzilla/show_bug.cgi?id=1190

现在再修改一下代码：

```c
#include<stdlib.h>
#include<stdio.h>
#include<unistd.h>

int main(int argc, char **argv)
{
        FILE *f = fopen("./Syslog.log", "rb");
        if (f == NULL) return 1;
        char buffer[1024] = {0};
        size_t len = 0;
        while(1)
        {
                len = fread(buffer, 1, sizeof(buffer), f);
                if (len > 0)
                {
                        buffer[len] = '\0';
                        printf("read:%s\n",buffer);
                }
                else
                {
                if (feof (f)) {
                        printf("Read error, clear error flag to retry...\n");
                        clearerr (f);
                }
                }
                sleep(2);
        }
        return 0;
}
```

![1adf1e265c52983b9d4fb3dadd27199](https://image.lvbibir.cn/blog/1adf1e265c52983b9d4fb3dadd27199.png)

添加了一块清除标记的片段，在 glibc>=2.28 的系统上程序也可以正常运行了

![image-20210910151213242](https://image.lvbibir.cn/blog/image-20210910151213242.png)

