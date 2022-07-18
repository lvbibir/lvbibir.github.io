# 前言

ceph：v16.2（pacific）

操作系统：icloudos_aarch64（openEuler-20.03-LTS-aarch64）

内核版本：4.19.90-2003.4.0.0037.aarch64

集群角色：


| ip             | 主机名             | 角色                   |
| -------------- | ------------------ | ---------------------- |
| 192.168.47.130 | ceph-aarch64-node1 | cephadm，mgr，mon，osd |
| 192.168.47.133 | ceph-aarch64-node2 | osd                    |
| 192.168.47.135 | ceph-aarch64-node3 | osd                    |

# 环境配置

## 修改主机名

```
hostnamectl set-hostname ceph-aarch64-node1
hostnamectl set-hostname ceph-aarch64-node2
hostnamectl set-hostname ceph-aarch64-node3

vi /etc/hosts
# 添加
192.168.47.130 ceph-aarch64-node1
192.168.47.133 ceph-aarch64-node2
192.168.47.135 ceph-aarch64-node3
```

## 添加 yum 源

```
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo
```

## 安装 docker

```
rpm -ivh --nodeps platform-python-3.6.8-47.el8.aarch64.rpm
rm -f /usr/libexec/platform-python
ln -s /usr/bin/python3.7 /usr/libexec/platform-python

yum install -y docker-ce
```

## 安装 epel-release

```
yum install -y epel-release
```

## 修改 $releasever

```
sed -i 's/$releasever/8/g' epel-modular.repo
sed -i 's/$releasever/8/g' epel-playground.repo
sed -i 's/$releasever/8/g' epel.repo
sed -i 's/$releasever/8/g' epel-testing-modular.repo
sed -i 's/$releasever/8/g' epel-testing.repo
```

## 修改 /etc/os-release

```
ID="centos"
VERSION_ID="8.0"
```

# 安装ceph

## 安装 cephadm & ceph-common


```
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/pacific/src/cephadm/cephadm
chmod +x cephadm

./cephadm add-repo --release pacific

yum install -y cephadm
which cephadm
# /usr/sbin/cephadm

cephadm install ceph-common
```

## ceph 集群初始化

```
cephadm bootstrap --mon-ip 192.168.47.130
```

![image-20220718113317700](https://image.lvbibir.cn/blog/image-20220718113317700.png)

访问：https://192.168.47.130:8443/

第一次访问 dashboard 需要修改初始账号密码
