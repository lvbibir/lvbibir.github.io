---
title: "cephadm 安装 ceph-v16 (pacific) (openeuler) (aarch64)" 
date: 2022-07-22
lastmod: 2022-07-22
tags: 
- linux
- ceph
keywords:
- linux
- ceph
- aarch64
- arm
description: "" 
cover:
    image: "https://image.lvbibir.cn/blog/ceph.png" 
---

# 前言

> 安装过程中会替换相当一部分系统内置的软件包，不建议用于生产环境
>
> cephadm依赖python3.6，而此版本的openeuler内置版本为3.7，且不支持platform-python
>
> 参考：[openeuler的gitee社区issue](https://gitee.com/src-openeuler/python3/issues/I4J8RK?from=project-issue)

ceph：v16.2（pacific）

操作系统：icloudos_v1.0_aarch64（openEuler-20.03-LTS-aarch64）

内核版本：4.19.90-2003.4.0.0037.aarch64

集群角色：


| ip             | 主机名             | 角色                   |
| -------------- | ------------------ | ---------------------- |
| 192.168.47.133 | ceph-aarch64-node1 | cephadm，mgr，mon，osd |
| 192.168.47.135 | ceph-aarch64-node2 | osd                    |
| 192.168.47.130 | ceph-aarch64-node3 | osd                    |

# 基础环境配置(所有节点)

## 关闭 node_exporter

```bash
systemctl stop node_exporter
systemctl disable node_exporter
```

## 修改主机名

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

## 添加 yum 源

```bash
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sed -i 's/$releasever/8/g' /etc/yum.repos.d/docker-ce.repo
```
## 添加 epel 源

```bash
yum install epel-release
# 修改 $releasever
sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel-modular.repo
sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel-playground.repo
sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel.repo
sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel-testing-modular.repo
sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel-testing.repo
```

## 修改 /etc/os-release

```bash
sed -i 's/ID="isoft"/ID="centos"/g' /etc/os-release
sed -i 's/VERSION_ID="1.0"/VERSION_ID="8.0"/g' /etc/os-release
```

## 安装 python3.6

```bash
yum install python3-pip-wheel python3-setuptools-wheel

wget http://mirrors.aliyun.com/centos-vault/8.5.2111/BaseOS/aarch64/os/Packages/python3-libs-3.6.8-41.el8.aarch64.rpm
wget http://mirrors.aliyun.com/centos-vault/8.5.2111/BaseOS/aarch64/os/Packages/libffi-3.1-22.el8.aarch64.rpm

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

## 安装 docker

```bash
yum install docker-ce
systemctl start docker
systemctl status docker
systemctl enable docker
```

## 安装 cephadm & ceph-common


```bash
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/pacific/src/cephadm/cephadm
chmod +x cephadm

./cephadm add-repo --release pacific

yum install cephadm

yum install ceph-common-16.2.9-0.el8
```

# ceph集群配置

## 集群初始化

```bash
cephadm bootstrap --mon-ip 192.168.47.133
```

![image-20220718113317700](https://image.lvbibir.cn/blog/image-20220718113317700.png)

访问：https://192.168.47.133:8443/

>  第一次访问 dashboard 需要修改初始账号密码

## 添加主机

```bash
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-aarch64-node2
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-aarch64-node3
ceph orch host add ceph-aarch64-node2 192.168.47.135 --labels _admin
ceph orch host add ceph-aarch64-node3 192.168.47.130 --labels _admin
```

## 添加磁盘

```bash
# 单盘添加
ceph orch daemon add osd ceph-aarch64-node1:/dev/vdb
# 查看所有可用设备
ceph orch device ls
# 自动添加所有可用设备
ceph orch apply osd --all-available-devices
```

# 其他

## 清除ceph集群

```bash
# 暂停集群，避免部署新的 ceph 守护进程
ceph orch pause
# 验证集群 fsid
ceph fsid
# 清除集群所有主机的 ceph 守护进程
cephadm rm-cluster --force --zap-osds --fsid <fsid>
```

## no active mgr

```bash
cephadm ls 
cephadm run  --name mgr.ceph-aarch64-node3.ipgtzj --fsid 17136806-0735-11ed-9c4f-52546f3387f3
ceph orch  apply  mgr label:_admin
```

## osd误删除

https://blog.csdn.net/cjfcxf010101/article/details/100411984

## 删除 osd 后引起的 cephadm_failed_daemon 错误

https://www.cnblogs.com/st2021/p/15026526.html

## 禁用自动添加osd

```
ceph orch apply osd --all-available-devices --unmanaged=true
```

