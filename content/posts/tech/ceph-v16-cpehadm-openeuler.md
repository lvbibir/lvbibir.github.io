---
title:  "ceph | openeuler 部署 ceph-v16" 
date:  2022-09-24
lastmod: 2024-01-27
tags:
  - ceph
keywords:
  - linux
  - ceph
  - openeuler
description:  "在 openeuler 2003 系统中使用 cephadm 部署 ceph-v16 (pacific) 集群" 
cover: 
    image:  "https: //image.lvbibir.cn/blog/ceph.png" 
---

# 0 前言

> 安装过程中会替换相当一部分系统内置的软件包, 不建议用于生产环境
> cephadm 依赖 python3.6, 而此版本的 openeuler 内置版本为 3.7, 且不支持 platform-python, 参考 [openeuler 的 gitee 社区 issue](https: <//gitee.com/src-openeuler/python3/issues/I4J8RK?from=project-issue>)

基础环境:

- ceph: v16.2 (pacific)
- 操作系统: openEuler-20.03-LTS-SP3
- 内核版本: 4.19.90-2112.8.0.0131.oe1.x86_64

集群角色:

| ip        | 主机名     | 角色                |
| --------- | ---------- | ------------------- |
| 1.1.1.101 | ceph-node1 | cephadm, mgr, mon, osd |
| 1.1.1.102 | ceph-node2 | osd, mgr, mon         |
| 1.1.1.103 | ceph-node3 | osd, mgr, mon         |

# 1 基础环境配置 (所有节点)

## 1.1 防火墙

```bash
systemctl stop firewalld
systemctl disable firewalld
```

## 1.2 修改主机名

```bash
hostnamectl set-hostname ceph-node1
hostnamectl set-hostname ceph-node2
hostnamectl set-hostname ceph-node3

vi /etc/hosts
# 添加
1.1.1.101 ceph-node1
1.1.1.102 ceph-node2
1.1.1.103 ceph-node3
```

## 1.3 配置 yum & epel

```bash
rpm -e openEuler-release-20.03LTS_SP3-52.oe1.x86_64
wget -O /etc/yum.repos.d/CentOS-Base.repo https: //mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo
yum install epel-release
rm -f /etc/yum.repos.d/CentOS-Linux-*
yum-config-manager --add-repo https: //mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

## 1.4 安装 python3.6

```bash
yum install python3-pip-wheel python3-setuptools-wheel

wget http: //mirrors.aliyun.com/centos-vault/8.5.2111/BaseOS/x86_64/os/Packages/python3-libs-3.6.8-41.el8.x86_64.rpm
wget http: //mirrors.aliyun.com/centos-vault/8.5.2111/BaseOS/x86_64/os/Packages/libffi-3.1-22.el8.x86_64.rpm

rpm -ivh libffi-3.1-22.el8.x86_64.rpm --force

cp /usr/lib64/libpython3.so /usr/lib64/libpython3.so-3.7.4
rpm -ivh python3-libs-3.6.8-41.el8.x86_64.rpm  --force --nodeps
mv /lib64/libpython3.so /lib64/python3.so-3.6.8
ln -s /usr/lib64/libpython3.so /lib64/libpython3.so

yum install platform-python

yum install python3-pip

vi /usr/bin/yum # 将 #!/usr/bin/python3 改成 #!/usr/bin/python3.7

yum install python3-prettytable-0.7.2-14.el8
yum install python3-gobject-base-3.28.3-2.el8
rpm -e --nodeps firewalld-doc-0.6.6-4.oe1.noarch
yum install firewalld-0.9.3-7.el8
```

## 1.5 安装 docker

```bash
yum install docker-ce
systemctl start docker
systemctl status docker
systemctl enable docker
```

## 1.6 安装 cephadm & ceph-common

```bash
curl --silent --remote-name --location https: //github.com/ceph/ceph/raw/pacific/src/cephadm/cephadm
chmod +x cephadm

./cephadm add-repo --release pacific

yum install cephadm
rpm -e --nodeps libicu-62.1-6.oe1.x86_64
yum install ceph-common-16.2.9-0.el8
```

# 2 ceph 集群配置

## 2.1 集群初始化

```bash
cephadm bootstrap --mon-ip 1.1.1.101
```

出现如下提示说明安装成功

```plaintext
......
Generating a dashboard self-signed certificate...
Creating initial admin user...
Fetching dashboard port number...
Ceph Dashboard is now available at: 

             URL:  https: //ceph-node1:8443/
            User:  admin
        Password:  dkk08l0czz

Enabling client.admin keyring and conf on hosts with "admin" label
Enabling autotune for osd_memory_target
You can access the Ceph CLI as following in case of multi-cluster or non-default config: 

        sudo /usr/sbin/cephadm shell --fsid aac4d9ba-3be0-11ed-b415-000c29211f5f -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring

Or,  if you are only running a single cluster on this host: 

        sudo /usr/sbin/cephadm shell

Please consider enabling telemetry to help improve Ceph: 

        ceph telemetry on

For more information see: 

        https: //docs.ceph.com/en/pacific/mgr/telemetry/

Bootstrap complete.
```

访问: <https://1.1.1.101:8443/>

> 第一次访问 dashboard 需要修改初始账号密码

## 2.2 添加主机

```bash
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-node2
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-node3
ceph orch host add ceph-node2 1.1.1.102 --labels _admin
ceph orch host add ceph-node3 1.1.1.103 --labels _admin
```

## 2.3 添加磁盘

```bash
# 单盘添加
ceph orch daemon add osd ceph-node1:/dev/vdb
# 查看所有可用设备
ceph orch device ls
# 自动添加所有可用设备
ceph orch apply osd --all-available-devices
```

以上
