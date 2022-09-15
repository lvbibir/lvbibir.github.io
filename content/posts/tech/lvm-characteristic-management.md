---
title: "lvm基本特性及日常管理" 
date: 2019-08-01
lastmod: 2019-08-01
tags: 
- linux
keywords:
- linux
- lvm
description: "" 
cover:
    image: "https://image.lvbibir.cn/blog/20190818145125498.png" 
---

# LVM基本特性：（可以通过插件CLVM，实现群集逻辑卷管理）

PV物理卷

LV逻辑卷（逻辑卷管理：会在物理存储上生成抽象层，以便创建逻辑存储卷，方便设备命名）（下面是逻辑卷的分类）
Linear		线性卷(这是默认的lvm形式，即按顺序占用磁盘，一块写完了再写另一块)
Stripe		条带逻辑卷
RAID		raid逻辑卷
Mirror		镜像卷
Thinly-Provision	精简配置逻辑卷
Snapshot	快照卷
Thinly-Provisioned Snapshot	精简配置快照卷
Cache		缓存卷

创建PV时（一同被创建的有）
1：接近设备起始处，放置一个标签，包括uuid，元数据的位置　#(这个标签每个磁盘默认都保持一份)
2：lvm元数据，包含lvm卷组的配置详情
3：剩余空间，用于存储数据

# lvm逻辑卷概念 及　创建lvm的步骤

## LVM的组成
	PE：（物理拓展，是VG卷组的基本组成单位）
	PV：（物理卷）
	VG：（卷组）
	LV：（逻辑卷）

## 创建lvm的步骤
	1：将磁盘创建为PV（物理卷），其实物理磁盘被条带化为PV，划成了一个一个的PE，默认每个PE大小是4MB
	2：创建VG（卷组），其实它是一个空间池，不同PV加入同一VG
	3：创建LV（逻辑卷），组成LV的PE可能来自不同的物理磁盘
	4：格式化LV，挂载使用
# lvm相关命令工具

## pv操作命令
	pvchange	更改物理卷的属性
	pvck		检查物理卷元数据
	pvcreate	初始化磁盘或分区以供lvm使用
	pvdisplay	显示物理卷的属性
	pvmove		移动物理Exent
	pvremove	删除物理卷
	pvresize	调整lvm2使用的磁盘或分区的大小
	pvs		报告有关物理卷的信息
	pvscan		扫描物理卷的所有磁盘

## vg操作命令
	vgcfgbackup	备份卷组描述符区域
	vgcfgrestore	恢复卷组描述符区域
	vgchange	更改卷组的属性
	vgck		检查卷组元数据
	vgconvert	转换卷组元数据格式
	vgcreate	创建卷组
	vgdisplay	显示卷组的属性
	vgexport	使卷组对系统不了解（这是个什么）
	vgextend	将物理卷添加到卷组
	vgimportclone	导入并重命名重复的卷组（例如硬件快照）
	vgmerge		合并两个卷组
	vgmknodes	重新创建卷组目录和逻辑卷特殊文件
	vgreduce	通过删除一个或多个物理卷来减少卷组（将物理卷踢出VG）
	vgremove	删除卷组
	vgrename	重命名卷组
	vgs		报告有关卷组信息
	vgscan		扫描卷组的所有磁盘并重建高速缓存
	vgsplit		将卷组拆分为两个，通过移动整个物理卷将任何逻辑卷从一个卷组移动到另一个卷组

## lv操作命令
	lvchange	更改逻辑卷属性
	lvconvert	将逻辑卷从线性转换为镜像或快照
	lvcreate	将现有卷组中创建逻辑卷
	lvdisplay	显示逻辑卷的属性
	lvextend	扩展逻辑卷的大小
	lvmconfig	在加载lvm.conf和任何其他配置文件后显示配置信息
	lvmdiskscan	扫描lvm2可见的所有设备
	lvmdump		创建lvm2信息转储以用于诊断目的
	lvreduce	减少逻辑卷的大小
	lvremove	删除逻辑卷
	lvrename	重命名逻辑卷
	lvresize	调整逻辑卷大小
	lvs		报告有关逻辑卷的信息
	lvscan		扫描所有的逻辑卷
# PV管理

制作PV
pvcreate /dev/sdb1

删除pv撤销PV（需先踢出vg）
pvremove /dev/sdb1
# VG管理

制作VG
vgcreate datavg /dev/sdb1
vgcreate datavg /dev/sdb1 /dev/sdb2
#解释：vgcreate vg名 分区

vgcreate -s 16M datavg2 /dev/sdb3
#解释：-s 指定pe的大小为16M，默认不指定是4M

从卷组中移除缺失的磁盘
vgreduce --removemissing datavg
vgreduce --removemissing datavg --force		#强制移除

扩展VG空间
vgextend datavg /dev/sdb3
pvs

踢出vg中的某个成员
vgreduce datavg /dev/sdb3
vgs
# LV管理

制作LV
lvcreate -n lvdata1 -L 1.5G datavg
#解释：-n lv的name，-L 指定lv的大小，datavg 是vg的名字，表示从那个vg

激活修复后的逻辑卷
lvchange -ay /dev/datavg/lvdata1
lvchange -ay /dev/datavg/lvdata1 -K	#强制激活
# LVM的快照

用途：注意用途是数据一致性备份，先做一个快照，冻结当前系统，这样快照里面的内容可暂时保持不变，系统本身继续运行，通过重新挂载备份快照卷，实现不中断服务备份。

lvcreate -s -n kuaizhao01 -L 100M /dev/datavg/lvdata1
# 查看，删除使用方法

1：查看物理卷信息
pvs,pvdisplay

2：查看卷组信息
vgs,vgdisplay

3：查看逻辑卷信息
lvs,lvdisplay

4：删除LV
lvremove /dev/mapper/VG-mylv

5：删除VG
vgremove VG

6：删除PV（注意删除顺序是LV，VG，PV）
pvremove /dev/sdb
# vg卷组改名

vgrename xxxx-vgid-xxxx-xxxx xinname
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190818145354774.png)
细述LVM基本特性及日常管理细述LVM基本特性及日常管理

# 拉伸一个逻辑卷LV

1:用vgdisplay查看vg还有多少空余空间
2:扩充逻辑卷
lvextend -L +1G /dev/VG/LV01
lvextend -L +1G /dev/VG/LV01 -r  #这个命令表示在扩展的同时也更新文件系统，但是不是所有的发行版本都支持，部分文件系统不支持在线扩展的除外
3:进行扩充操作后，df -h你会发现大小并没有变
4:更新文件系统（争对不同的文件系统，其更新的命令也不一样）
e2fsck -f /dev/datavg/lvdata1	#ext4文件系统，检查lv的文件系统
resize2fs /dev/VG/LV01		#ext4文件系统命令，该命令后面接lv的设备名就行

xfs_growfs /nas			#xfs文件系统，该命令后面直接跟的是挂载点
当更新文件系统后，你就会发现，df -h正常了
# 缩小逻辑卷LV（必须离线，umount）

1：卸载

2：缩小文件系统	
resize2fs /dev/VG/LV01 2G

3：缩小LV	
lvreduce -L -1G /dev/VG/LV01

4：查看lvs，挂载使用
# 拉伸一个卷组VG

1:新插入一块硬盘，若不是热插拔的磁盘，可以试试这个在系统上强制刷新硬盘接口
for i in /sys/class/scsi_host/*; do echo "- - -" > $i/scan; done

2:将/dev/sdd条带化，格式化为PE
pvcreate /dev/sdd

3:将一块新的PV加入到现有的VG中
vgextend VG /dev/sdd

4:查看大小
vgs
# 缩小卷组VG（注意不要有PE在占用）

1：将一个PV从指定卷中移除	
vgreduce VG /dev/sdd

2：查看缩小后的卷组大小
# 将磁盘加入和踢出VG

将sdd1踢出datavg组里
vgreduce datavg /dev/sdd1

将sdb1加入datavg组里
vgextend datavg /dev/sdb1
# lvm灾难恢复场景案例

## 场景再现：
三块盘做lvm,现在有一块物理坏了，将剩下两块放到其他linux服务器上

## 恢复步骤
第一，查看磁盘信息，lvm信息，确认能查到lvm相关信息，找到VG组的名字（pvs,lvs,vgs,fidsk,blkid）
第二：删除lvm信息中损坏的磁盘角色，（强制提出故障磁盘）"vgreduce --removemissing VG_name "
第三：强制激活VG组 "vgchange -ay"
第四：强制激活LVM  "lvchange -ay /dev/VG_name"
第五：挂载