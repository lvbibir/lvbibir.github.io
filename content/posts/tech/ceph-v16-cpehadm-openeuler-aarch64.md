---
title:  "ceph | openeuler (aarch64) 部署 ceph-v16" 
date:  2022-07-22
lastmod: 2024-01-27
tags:
  - ceph
keywords:
  - linux
  - ceph
  - aarch64
  - arm
description:  "在 openeuler 2003 aarch64 系统中使用 cephadm 部署 ceph-v16 (pacific) 集群" 
cover: 
    image:  "https: //image.lvbibir.cn/blog/ceph.png" 
---

# 0 前言

> 安装过程中会替换相当一部分系统内置的软件包, 不建议用于生产环境
> cephadm 依赖 python3.6, 而此版本的 openeuler 内置版本为 3.7, 且不支持 platform-python, 参考: [openeuler 的 gitee 社区 issue](https: <//gitee.com/src-openeuler/python3/issues/I4J8RK?from=project-issue>)

基础环境:

- ceph: v16.2（pacific）
- 操作系统: icloudos_v1.0_aarch64（openEuler-20.03-LTS-aarch64）
- 内核版本: 4.19.90-2003.4.0.0037.aarch64

集群角色:

| ip             | 主机名             | 角色                   |
| -------------- | ------------------ | ---------------------- |
| 192.168.47.133 | ceph-aarch64-node1 | cephadm, mgr, mon, osd |
| 192.168.47.135 | ceph-aarch64-node2 | osd                    |
| 192.168.47.130 | ceph-aarch64-node3 | osd                    |

# 1 基础环境配置 (所有节点)

## 1.1 关闭 node_exporter

```bash
systemctl stop node_exporter
systemctl disable node_exporter
```

## 1.2 修改主机名

```bash
hostnamectl set-hostname ceph-aarch64-node1
hostnamectl set-hostname ceph-aarch64-node2
hostnamectl set-hostname ceph-aarch64-node3

vi /etc/hosts
# 添加
192.168.47.133 ceph-aarch64-node1
192.168.47.135 ceph-aarch64-node2
192.168.47.130 ceph-aarch64-node3
```

## 1.3 添加 yum 源

```bash
wget -O /etc/yum.repos.d/CentOS-Base.repo https: //mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo
yum-config-manager --add-repo https: //mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sed -i 's/$releasever/8/g' /etc/yum.repos.d/docker-ce.repo
```

## 1.4 添加 epel 源

```bash
yum install epel-release
# 修改 $releasever
sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel-modular.repo
sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel-playground.repo
sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel.repo
sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel-testing-modular.repo
sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel-testing.repo
```

## 1.5 修改 /etc/os-release

```bash
sed -i 's/ID="isoft"/ID="centos"/g' /etc/os-release
sed -i 's/VERSION_ID="1.0"/VERSION_ID="8.0"/g' /etc/os-release
```

## 1.6 安装 python3.6

```bash
yum install python3-pip-wheel python3-setuptools-wheel

wget http: //mirrors.aliyun.com/centos-vault/8.5.2111/BaseOS/aarch64/os/Packages/python3-libs-3.6.8-41.el8.aarch64.rpm
wget http: //mirrors.aliyun.com/centos-vault/8.5.2111/BaseOS/aarch64/os/Packages/libffi-3.1-22.el8.aarch64.rpm

rpm -ivh libffi-3.1-22.el8.aarch64.rpm --force

cp /usr/lib64/libpython3.so /usr/lib64/libpython3.so-3.7.4
rpm -ivh python3-libs-3.6.8-41.el8.aarch64.rpm  --force --nodeps
mv /lib64/libpython3.so /lib64/python3.so-3.6.8
ln -s /usr/lib64/libpython3.so /lib64/libpython3.so

yum install platform-python

yum install python3-pip-9.0.3-20.el8.noarch

vim /usr/bin/yum # 将 #!/usr/bin/python3 改成 #!/usr/bin/python3.7

yum install python3-prettytable-0.7.2-14.el8
yum install python3-gobject-base-3.28.3-2.el8.aarch64
yum install firewalld-0.9.3-7.el8
```

## 1.7 安装 docker

```bash
yum install docker-ce
systemctl start docker
systemctl status docker
systemctl enable docker
```

## 1.8 安装 cephadm & ceph-common

```bash
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/pacific/src/cephadm/cephadm
chmod +x cephadm

./cephadm add-repo --release pacific
yum install cephadm
yum install ceph-common-16.2.9-0.el8
```

# 2 ceph 集群配置

## 2.1 集群初始化

```bash
cephadm bootstrap --mon-ip 192.168.47.133
```

![image-20220718113317700](https://image.lvbibir.cn/blog/image-20220718113317700.png)

访问: <https://192.168.47.133:8443/>

> 第一次访问 dashboard 需要修改初始账号密码

## 2.2 添加主机

```bash
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-aarch64-node2
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-aarch64-node3
ceph orch host add ceph-aarch64-node2 192.168.47.135 --labels _admin
ceph orch host add ceph-aarch64-node3 192.168.47.130 --labels _admin
```

## 2.3 添加磁盘

```bash
# 单盘添加
ceph orch daemon add osd ceph-aarch64-node1: /dev/vdb
# 查看所有可用设备
ceph orch device ls
# 自动添加所有可用设备
ceph orch apply osd --all-available-devices
```

# 3 其他

## 3.1 清除 ceph 集群

```bash
# 暂停集群, 避免部署新的 ceph 守护进程
ceph orch pause
# 验证集群 fsid
ceph fsid
# 清除集群所有主机的 ceph 守护进程
cephadm rm-cluster --force --zap-osds --fsid <fsid>
```

## 3.2 no active mgr

```bash
cephadm ls 
cephadm run  --name mgr.ceph-aarch64-node3.ipgtzj --fsid 17136806-0735-11ed-9c4f-52546f3387f3
ceph orch  apply  mgr label: _admin
```

## 3.3 osd 误删除

<https://blog.csdn.net/cjfcxf010101/article/details/100411984>

## 3.4 cephadm_failed_daemon

[删除 osd 后引起的 cephadm_failed_daemon 错误](https: <//www.cnblogs.com/st2021/p/15026526.html>)

## 3.5 禁用自动添加 osd

```bash
ceph orch apply osd --all-available-devices --unmanaged=true
```

以上
