---
title: "linux | 磁盘扩容" 
date: 2025-04-24
lastmod: 2025-04-24
tags:
  - linux
keywords:
  - linux
  - free
description: "介绍一下 Linux 系统中扩容磁盘的几种方式, 涵盖大部分生产环境中需要对服务器进行磁盘扩容的操作" 
cover:
    image: "https://image.lvbibir.cn/blog/default-cover.webp"
---

# 0 原盘扩容

适用于磁盘未分区或者标准分区后直接挂载到系统目录, 后续通过云平台等方式扩容磁盘后需要在系统内更新容量的场景

```bash
yum install -y cloud-utils-growpart
# 1 代表分区号, 如果是整个盘格式化进行挂载则可以直接尝试 resize2fs 或者 xfs_growfs
growpart /dev/vdb 1
resize2fs /dev/vdb
xfs_growfs /dev/vdb
```

# 1 lvm 原盘扩容

与原盘扩容类似, 需要在 lvm 中对 pv 进行容量更新

```bash
yum install -y cloud-utils-growpart
# 1 代表分区号, 如果整盘作为 pv, 直接跳过此步骤即可
growpart /dev/vdb 1
pvresize /dev/vdb1
vgdisplay
lvextend -l +100%FREE /dev/mapper/vg_home-lv_home
lvextend -L +100G /dev/mapper/vg_home-lv_home
# ext4
resize2fs /dev/mapper/vg_home-lv_home
# xfs
xfs_growfs /dev/mapper/vg_home-lv_home 
```

# 2 lvm 新加盘扩容

最常见也是最合理的扩容方式

```bash
pvcreate /dev/vdc1
vgextend vg_home /dev/vdc1
lvextend -l +100%FREE /dev/mapper/vg_home-lv_home
lvextend -L +100G /dev/mapper/vg_home-lv_home
# ext4
resize2fs /dev/mapper/vg_home-lv_home 
# xfs
xfs_growfs /dev/mapper/vg_home-lv_home 
```

# 3 常见问题

`partprobe` 如果遇到报错 Error: The backup GPT table is not at the end of the disk [参考](https://bbs.huaweicloud.com/blogs/185100)

umount 无法卸载

  ```bash
  umount /data
  lsof +D /data
  ps -elf | grep -v grep | grep " /data"
  # 如果无进程占用仍 busy 状态则查看是否有 nfs 进程
  umount /data
  ```

lvm 命令卡死, 有如下输出, 删除 `/run/lock/lvm/` 下的文件即可, [参考](https://blog.csdn.net/qq_28513801/article/details/130255843)

```plaintext
  Giving up waiting for lock.
  Can't get lock for vg_home
  Cannot process volume group vg_home
```

以上.
