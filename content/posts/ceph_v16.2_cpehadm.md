# 前言

ceph：v16.2（pacific）

操作系统：icloudos_v1.0_aarch64（openEuler-20.03-LTS-aarch64）

内核版本：4.19.90-2003.4.0.0037.aarch64

集群角色：


| ip             | 主机名             | 角色                   |
| -------------- | ------------------ | ---------------------- |
| 192.168.47.133 | ceph-aarch64-node1 | cephadm，mgr，mon，osd |
| 192.168.47.135 | ceph-aarch64-node2 | osd                    |
| 192.168.47.130 | ceph-aarch64-node3 | osd                    |

# 环境配置(所有节点)

## 关闭 node_exporter

```
systemctl stop node_exporter
systemctl disable node_exporter
```

## 修改主机名

```
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

```
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sed -i 's/$releasever/8/g' /etc/yum.repos.d/docker-ce.repo
```
## 添加 epel 源

```
yum install epel-release
# 修改 $releasever
sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel-modular.repo
sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel-playground.repo
sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel.repo
sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel-testing-modular.repo
sed -i 's/$releasever/8/g' /etc/yum.repos.d/epel-testing.repo
```

## 修改 /etc/os-release

```
sed -i 's/ID="isoft"/ID="centos"/g' /etc/os-release
sed -i 's/VERSION_ID="1.0"/VERSION_ID="8.0"/g' /etc/os-release
```

## 安装 python3.6

```
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

```
yum install docker-ce
systemctl start docker
systemctl status docker
systemctl enable docker
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

yum install ceph-common-16.2.9-0.el8
```

## ceph 集群初始化

```
cephadm bootstrap --mon-ip 192.168.47.133
```

![image-20220718113317700](https://image.lvbibir.cn/blog/image-20220718113317700.png)

访问：https://192.168.47.133:8443/

>  第一次访问 dashboard 需要修改初始账号密码

## 添加主机

```
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-aarch64-node2
ssh-copy-id -f -i /etc/ceph/ceph.pub root@ceph-aarch64-node3
ceph orch host add ceph-aarch64-node2 192.168.47.135 --labels _admin
ceph orch host add ceph-aarch64-node3 192.168.47.130 --labels _admin

```

## 添加磁盘

```
ceph orch daemon add osd ceph-aarch64-node1:/dev/vdb
ceph orch apply osd --all-available-devices
```

## 清除ceph集群

```
# 暂停集群，避免部署新的 ceph 守护进程
ceph orch pause
# 验证集群 fsid
ceph fsid
# 清除集群所有主机的 ceph 守护进程
cephadm rm-cluster --force --zap-osds --fsid <fsid>
```

# 故障问题

## no active mgr

```
cephadm ls 
cephadm run  --name mgr.ceph-aarch64-node3.ipgtzj --fsid 17136806-0735-11ed-9c4f-52546f3387f3
ceph orch  apply  mgr label:_admin
```

