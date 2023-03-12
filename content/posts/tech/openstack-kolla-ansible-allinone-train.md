---
title: "kolla-ansible 部署 Train版 openstack（all-in-one）" 
date: 2021-10-01
lastmod: 2021-10-01
tags: 
- openstack
keywords:
- linux
- openstack
- ansible
description: "介绍cenots中使用kolla-ansible+docker的方式快速部署openstack(all-in-one)单节点" 
cover:
    image: "https://image.lvbibir.cn/blog/20200613094347844.png" 
---
# kolla ansible简介

kolla 的使命是为 openstack 云平台提供生产级别的、开箱即用的交付能力。kolla 的基本思想是一切皆容器，将所有服务基于 Docker 运行，并且保证一个容器只跑一个服务（进程），做到最小粒度的运行 docker。

kolla 要实现 openetack 部署总体上分为两步，第一步是制作 docker 镜像，第二步是编排部署。因此，kolla 项目又被分为两个小项目：kolla、kolla-ansible 。

kolla-ansible项目
https://github.com/openstack/kolla-ansible

kolla项目
https://tarballs.opendev.org/openstack/kolla/

dockerhub镜像地址
https://hub.docker.com/u/kolla/

# 部署 openstack 集群

## 安装环境准备

官方部署文档：
https://docs.openstack.org/kolla-ansible/train/user/quickstart.html

本次部署train版all-in-one单节点，使用一台centos7.8 minimal节点进行部署，该节点同时作为控制节点、计算节点、网络节点和cinder存储节点使用，同时也是kolla ansible的部署节点。

kolla安装节点要求：

> 2 network interfaces
> 8GB main memory
> 40GB disk space

如果是vmware workstation环境，勾选处理器选项的虚拟化引擎相关功能，否则后面需要配置`nova_compute_virt_type=qemu`参数，这里选择勾选，跳过以下步骤。

```
cat /etc/kolla/globals.yml
nova_compute_virt_type: "qemu"

#或者部署完成后手动调整
[root@kolla ~]# cat /etc/kolla/nova-compute/nova.conf |grep virt_type
#virt_type = kvm
virt_type = qemu

[root@kolla ~]# docker restart nova_compute
```

kolla的安装要求目标机器至少两块网卡，本次安装使用2块网卡对应管理网络和外部网络两个网络平面，在vmware workstation虚拟机新增一块网卡ens34：

> ens32，NAT模式，管理网络，正常配置静态IP即可。租户网络与该网络复用，租户vm网络不单独创建网卡
> ens34，桥接模式，外部网络，无需配置IP地址，这个其实是让neutron的br-ex 绑定使用，虚拟机通过这块网卡访问外网。

ens34网卡配置参考：
https://docs.openstack.org/install-guide/environment-networking-controller.html

```
cat > /etc/sysconfig/network-scripts/ifcfg-ens34 <<EOF
NAME=ens34
DEVICE=ens34
TYPE=Ethernet
ONBOOT="yes"
BOOTPROTO="none"
EOF

#重新加载ens34网卡设备
nmcli con reload && nmcli con up ens34
```

如果启用cinder还需要额外添加磁盘，这里以添加一块/dev/sdb磁盘为例，创建为物理卷并加入卷组。

```
pvcreate /dev/sdb
vgcreate cinder-volumes /dev/sdb
```

注意卷组名称为cinder-volumes，默认与后面的globals.yml中定义一致。

```
[root@kolla ~]# cat /etc/kolla/globals.yml | grep cinder_volume_group
#cinder_volume_group: "cinder-volumes"
```

## 部署 kolla ansible

配置主机名,kolla预检查时rabbitmq可能需要能够进行主机名解析

```
hostnamectl set-hostname kolla
```

安装依赖

```
yum install -y python-devel libffi-devel gcc openssl-devel libselinux-python python2-pip  python-pbr epel-release ansible
```

配置阿里云pip源，否则pip安装时会很慢

```
mkdir ~/.pip
cat > ~/.pip/pip.conf << EOF 
[global]
trusted-host=mirrors.aliyun.com
index-url=https://mirrors.aliyun.com/pypi/simple/
EOF
```

安装 kolla-ansible

kolla版本与openstack版本对应关系：https://releases.openstack.org/teams/kolla.html

```
pip install setuptools==22.0.5
pip install pip==20.3.4
pip install wheel
pip install kolla-ansible==9.1.0 --ignore-installed PyYAML
```


复制 kolla-ansible配置文件到当前环境

```
mkdir -p /etc/kolla
chown $USER:$USER /etc/kolla

cp -r /usr/share/kolla-ansible/etc_examples/kolla/* /etc/kolla

cp /usr/share/kolla-ansible/ansible/inventory/* .
```

修改ansible配置文件

```
cat << EOF | sed -i '/^\[defaults\]$/ r /dev/stdin' /etc/ansible/ansible.cfg
host_key_checking=False
pipelining=True
forks=100
EOF
```

默认有all-in-one和multinode两个inventory文件，这里使用all-in-one，来规划集群角色，配置默认即可

```
[root@kolla ~]# cat all-in-one | more
```


检查inventory配置是否正确，执行：

```
ansible -i all-in-one all -m ping
```

生成openstack组件用到的密码，该操作会填充/etc/kolla/passwords.yml，该文件中默认参数为空。

```
kolla-genpwd
```

修改keystone_admin_password，可以修改为自定义的密码方便后续horizon登录，这里改为kolla。

```
$ sed -i 's#keystone_admin_password:.*#keystone_admin_password: kolla#g' /etc/kolla/passwords.yml 

$ cat /etc/kolla/passwords.yml | grep keystone_admin_password
keystone_admin_password: kolla
```

修改全局配置文件globals.yml，该文件用来控制安装哪些组件，以及如何配置组件，由于全部是注释，这里直接追加进去，也可以逐个找到对应项进行修改。

```
cp /etc/kolla/globals.yml{,.bak}

cat >> /etc/kolla/globals.yml <<EOF
# Kolla options

kolla_base_distro: "centos"
kolla_install_type: "binary"
openstack_release: "train"
kolla_internal_vip_address: "192.168.150.155"

# Docker options
# docker_registry: "registry.cn-beijing.aliyuncs.com"
# docker_namespace: "kollaimage"

# Neutron - Networking Options
network_interface: "ens32"
neutron_external_interface: "ens34"
neutron_plugin_agent: "openvswitch"
enable_neutron_provider_networks: "yes"

# OpenStack services
enable_cinder: "yes"
enable_cinder_backend_lvm: "yes"

EOF
```

参数说明：

> kolla_base_distro: kolla镜像基于不同linux发型版构建，主机使用centos这里对应使用centos类型的docker镜像即可。
> kolla_install_type: kolla镜像基于binary二进制和source源码两种类型构建，实际部署使用binary即可。
> openstack_release: openstack版本可自定义，会从dockerhub拉取对应版本的镜像
> kolla_internal_vip_address: 单节点部署kolla也会启用haproxy和keepalived，方便后续扩容为高可用集群，该地址是ens32网卡网络中的一个可用IP。
> docker_registry: 默认从dockerhub拉取镜像，也可以本地搭建仓库，提前推送镜像上去。
> docker_namespace: 阿里云kolla镜像仓库所在的命名空间，dockerhub官网默认是kolla。
> network_interface: 管理网络的网卡
> neutron_external_interface: 外部网络的网卡
> neutron_plugin_agent: 默认启用openvswitch
> enable_neutron_provider_networks: 启用外部网络
> enable_cinder: 启用cinder
> enable_cinder_backend_lvm: 指定cinder后端存储为lvm



## 部署 openstack 组件
部署openstack

```
# 预配置，安装docker、docker sdk、关闭防火墙、配置时间同步等
kolla-ansible -i ./all-in-one bootstrap-servers

# 部署前环境检查，可能会报docker版本的错，可以忽略
kolla-ansible -i ./all-in-one prechecks

# 拉取镜像，也可省略该步骤，默认会自动拉取
kolla-ansible -i ./all-in-one pull

# 执行实际部署，拉取镜像，运行对应组件容器
kolla-ansible -i ./all-in-one deploy

# 生成openrc文件
kolla-ansible post-deploy
```

以上部署没有报错中断说明部署成功，所有openstack组件以容器方式运行，查看容器

```
[root@kolla ~]# docker ps -a
```


确认没有Exited等异常状态的容器

```
[root@kolla ~]# docker ps -a  | grep -v Up
```


本次部署运行了38个容器

```
[root@localhost kolla-env]# docker ps -a | wc -l
39
```


查看拉取的镜像

```
[root@kolla ~]# docker images | wc -l
39
[root@kolla ~]# docker images
REPOSITORY                       TAG       IMAGE ID       CREATED         SIZE
kolla/centos-binary-heat-api     train     b97df3444b35   10 months ago   1.11GB
kolla/centos-binary-heat-engine  train     e19de6feec32   10 months ago   1.11GB
......
```


查看cinder使用的卷，自动创建了lvm

```
[root@kolla ~]# lsblk | grep cinder
├─cinder--volumes-cinder--volumes--pool_tmeta 253:3    0   20M  0 lvm  
│ └─cinder--volumes-cinder--volumes--pool     253:5    0   19G  0 lvm  
└─cinder--volumes-cinder--volumes--pool_tdata 253:4    0   19G  0 lvm  
  └─cinder--volumes-cinder--volumes--pool     253:5    0   19G  0 lvm  
  
[root@kolla ~]# lvs | grep cinder
  cinder-volumes-pool cinder-volumes twi-a-tz--  19.00g             0.00   10.55
```


另外需要注意，不要在该节点安装libvirt等工具，这些工具安装后可能会启用libvirtd和iscsid.sock等服务，kolla已经在容器中运行了这些服务，这些服务会调用节点上的sock文件，如果节点上也启用这些服务去抢占这些文件，会导致容器异常。默认kolla在预配置时也会主动禁用节点上的相关服务。

## 安装 openStack 客户端
> 可以直接安装到服务器上或者使用docker安装容器
>
> 推荐使用docker容器方式运行客户端

使用docker容器作为客户端

```
docker run -d --name client \
  --restart always \
  -v /etc/kolla/admin-openrc.sh:/admin-openrc.sh:ro \
  -v /usr/share/kolla-ansible/init-runonce:/init-runonce:rw \
  kolla/centos-binary-openstack-base:train sleep infinity

docker exec -it client bash
source /admin-openrc.sh
openstack service list
```

yum安装openstack客户端

```
#启用openstack存储库
yum install -y centos-release-openstack-train

#安装openstack客户端
yum install -y python-openstackclient

#启用selinux,安装openstack-selinux软件包以自动管理OpenStack服务的安全策略
yum install -y openstack-selinux

#报错处理
pip uninstall urllib3
yum install -y python2-urllib3
```

## 运行 cirros 实例

kolla ansible提供了一个快速创建cirros demo实例的脚本/usr/share/kolla-ansible/init-runonce。

脚本需要cirros镜像，如果网络较慢可以使用浏览器下载放在/opt/cache/files目录下：

```
wget https://github.com/cirros-dev/cirros/releases/download/0.4.0/cirros-0.4.0-x86_64-disk.img
mkdir -p /opt/cache/files/
mv cirros-0.4.0-x86_64-disk.img /opt/cache/files/
```


定义init-runonce示例脚本外部网络配置：

```
#定义init-runonce示例脚本外部网络配置
vim /usr/share/kolla-ansible/init-runonce
EXT_NET_CIDR=${EXT_NET_CIDR:-'192.168.35/24'}
EXT_NET_RANGE=${EXT_NET_RANGE:-'start=192.168.35.150,end=192.168.35.188'}
EXT_NET_GATEWAY=${EXT_NET_GATEWAY:-'192.168.35.1'}

#执行脚本，上传镜像到glance，创建内部网络、外部网络、flavor、ssh key，并运行一个实例
source /etc/kolla/admin-openrc.sh 
/usr/share/kolla-ansible/init-runonce
```

参数说明：

> EXT_NET_CIDR 指定外部网络，由于使用桥接模式，直接桥接到了电脑的无线网卡，所以这里网络就是无线网卡的网段。
> EXT_NET_RANGE 指定从外部网络取出一个地址范围，作为外部网络的地址池
> EXT_NET_GATEWAY 外部网络网关，这里与wifi网络使用的网关一致

根据最终提示运行实例

```
openstack server create \
    --image cirros \
    --flavor m1.tiny \
    --key-name mykey \
    --network demo-net \
    demo1
```

## 访问 openstack horizon
访问openstack horizon需要使用vip地址，节点上可以看到由keepalived容器生成的vip

```
[root@kolla ~]# ip a |grep ens32
2: ens32: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet 192.168.150.101/24 brd 192.168.150.255 scope global noprefixroute dynamic ens32
    inet 192.168.150.155/32 scope global ens32
```


浏览器直接访问该地址即可登录到horizon

http://192.168.150.155

我这里的用户名密码为admin/kolla，信息可以从admin-openrc.sh中获取

```
[root@kolla ~]# cat /etc/kolla/admin-openrc.sh
# Clear any old environment that may conflict.
for key in $( set | awk '{FS="="}  /^OS_/ {print $1}' ); do unset $key ; done
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=kolla
export OS_AUTH_URL=http://192.168.150.155:35357/v3
export OS_INTERFACE=internal
export OS_ENDPOINT_TYPE=internalURL
export OS_IDENTITY_API_VERSION=3
export OS_REGION_NAME=RegionOne
export OS_AUTH_PLUGIN=password
```

默认登录后如下

![image-20211027141126853](https://image.lvbibir.cn/blog/image-20211027141126853.png)

在horizion查看创建的网络和实例

![image-20211029133654821](https://image.lvbibir.cn/blog/image-20211029133654821.png)

登录实例控制台，验证实例与外网的连通性，cirros用户密码在初次登录时有提示：

![image-20211029143245929](https://image.lvbibir.cn/blog/image-20211029143245929.png)

为实例绑定浮动IP地址，方便从外部ssh远程连接到实例

点击+随机分配一个浮动IP

![image-20211029142830822](https://image.lvbibir.cn/blog/image-20211029142830822.png)

![image-20211029142911908](https://image.lvbibir.cn/blog/image-20211029142911908.png)

在实例界面可以看到绑定的浮动ip

![image-20211029143343691](https://image.lvbibir.cn/blog/image-20211029143343691.png)

在kolla节点上或者在集群外部使用SecureCRT等ssh工具连接到实例。cirros镜像默认用户密码为cirros/gocubsgo，该镜像信息官网有介绍：
https://docs.openstack.org/image-guide/obtain-images.html#cirros-test

```
[root@kolla ~]# ssh cirros@192.168.35.183
cirros@192.168.35.183's password: 
```

## 运行 centos 实例
centos官方维护有相关cloud image，如果不需要进行定制，可以直接下载来运行实例。

参考：https://docs.openstack.org/image-guide/obtain-images.html

CentOS官方维护的镜像下载地址：
http://cloud.centos.org/centos/7/images/

也可以使用命令直接下载镜像，但是下载可能较慢，建议下载好在进行上传。以centos7.8为例：

```
wget http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-2003.qcow2c
```


下载完成后上传镜像到openstack，直接在horizon上传即可。也可以使用命令上传。

注意：默认该镜像运行的实例只能使用ssh key以centos用户身份登录，如果需要使用root远程ssh连接到实例需要在上传前为镜像配置root免密并开启ssh访问。

参考：https://blog.csdn.net/networken/article/details/106713658

另外我们的命令客户端在容器中，所有这里有些不方便，首先要将镜像复制到容器中，然后使用openstack命令上传。

这里复制到client容器的根目录下。

```
[root@kolla ~]# docker cp CentOS-7-x86_64-GenericCloud-2003.qcow2c client:/

[root@kolla ~]# docker exec -it client bash
()[root@f11a103c5ade /]# 
()[root@f11a103c5ade /]# source /admin-openrc.sh 

()[root@f11a103c5ade /]# ls | grep CentOS
CentOS-7-x86_64-GenericCloud-2003.qcow2c
```


执行以下openstack命令上传镜像

```
openstack image create "CentOS78-image" \
  --file CentOS-7-x86_64-GenericCloud-2003.qcow2c \
  --disk-format qcow2 --container-format bare \
  --public
```

创建实例

```
openstack server create \
    --image CentOS78-image \
    --flavor m1.small \
    --key-name mykey \
    --network demo-net \
    demo-centos
```

创建完成后为实例绑定浮动IP。

![image-20211029160645697](https://image.lvbibir.cn/blog/image-20211029160645697.png)

如果实例创建失败可以查看相关组件报错日志

```
[root@kolla ~]# tail -100f /var/log/kolla/nova/nova-compute.log 
```

如果没有提前定制镜像修改root密码，只能使用centos用户及sshkey登录，由于是在容器中运行的demo示例，ssh私钥也保存在容器的默认目录下，在容器中连接实例浮动IP测试

```
[root@kolla ~]# docker exec -it client bash
()[root@b86f87f7f101 ~]# ssh -i /root/.ssh/id_rsa centos@192.168.35.186
Last login: Fri Oct 29 08:10:42 2021 from 192.168.35.188
[centos@demo-centos ~]$ sudo -i
[root@demo-centos ~]# 
```


## 运行 ubuntu 实例
下载镜像

```
wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
docker cp bionic-server-cloudimg-amd64.img client:/
```


上传镜像

```
openstack image create "Ubuntu1804" \
  --file bionic-server-cloudimg-amd64.img \
  --disk-format qcow2 --container-format bare \
  --public
```

创建实例

```
openstack server create \
    --image Ubuntu1804 \
    --flavor m1.small \
    --key-name mykey \
    --network demo-net \
    demo-ubuntu
```

绑定浮动ip

![image-20211029162115403](https://image.lvbibir.cn/blog/image-20211029162115403.png)ubuntu镜像默认用户为ubuntu，首次登陆使用sshkey方式

![image-20211029162258334](https://image.lvbibir.cn/blog/image-20211029162258334.png)

# 调整集群配置

## 新增 magnum & ironic 组件

`magnum` 和 `ironic` 默认状态下是没有安装的，在 `/etc/kolla/globals.yml` 可以看到默认配置

```
#enable_magnum: "no"
#enable_ironic: "no"
```

在 `/etc/kolla/globals.yml` 之前的配置下面新增如下，参数的具体含义查看 [官方文档](https://docs.openstack.org/kolla-ansible/train/reference/index.html)

```
# ironic
enable_ironic: true
ironic_dnsmasq_interface: "enp11s0f1"
ironic_dnsmasq_dhcp_range: "192.168.45.200,192.168.45.210"
ironic_dnsmasq_default_gateway: 192.168.45.1
ironic_cleaning_network: "public1"
ironic_dnsmasq_boot_file: pxelinux.0

# magnum
enable_magnum: true
```

ironic 组件还需要一些其他操作

```bash
mkdir -p /etc/kolla/config/ironic/
curl https://tarballs.openstack.org/ironic-python-agent/dib/files/ipa-centos7-master.kernel -o /etc/kolla/config/ironic/ironic-agent.kernel
curl https://tarballs.openstack.org/ironic-python-agent/dib/files/ipa-centos7-master.initramfs -o /etc/kolla/config/ironic/ironic-agent.initramfs
```

在现有集群中新增组件

```
kolla-ansible -i all-in-one deploy --tags horizon,magnum,ironic
```

## 修改组件配置

集群部署完成后需要开启新的组件或者扩容，可以修改/etc/kolla/global.yml调整参数。
或者在/etc/kolla/config目录下创建自定义配置文件，例如

```
# mkdir -p /etc/kolla/config/nova

# vim /etc/kolla/config/nova/nova.conf

[DEFAULT]
block_device_allocate_retries = 300
block_device_allocate_retries_interval = 3
```


重新配置openstack，kolla会自动重建配置变动的容器组件。

```
kolla-ansible -i all-in-one reconfigure -t nova
```

## kolla配置和日志文件

- 各个组件配置文件目录： /etc/kolla/
- 各个组件日志文件目录：/var/log/kolla/

## 清理kolla ansilbe集群

```
kolla-ansible destroy --include-images --yes-i-really-really-mean-it
# 或者
[root@kolla ~]# cd /usr/share/kolla-ansible/tools/
[root@all tools]# ./cleanup-containers
[root@all tools]# ./cleanup-host
#重置cinder卷，谨慎操作
vgremove cinder-volumes
```

## 重新部署 kolla ansible 集群

```
## 清除操作

先关闭所有运行的实例，再进行下面操作

[root@kolla ~]# cd /usr/share/kolla-ansible/tools/
[root@all tools]# ./cleanup-containers
vgremove cinder-volumes

## 重建操作

pvcreate /dev/sdb
vgcreate cinder-volumes /dev/sdb

kolla-ansible -i ./all-in-one deploy
kolla-ansible post-deploy
```

# 可能遇到的问题

## 虚拟ip分配失败

![image-20211130161356609](https://image.lvbibir.cn/blog/image-20211130161356609.png)

这种情况多半是由于虚拟ip没有分配到，并不是端口问题

- 解决方法1

在全局的配置中添加/修改这个id值，必须是0-255之间的数字，并且确保在整个二层网络中是唯一的

```
vim /etc/kolla/globals.yml

keepalived_virtual_router_id: "199"
```

https://www.bianchengquan.com/article/506138.html

- 解决方法2

https://www.nuomiphp.com/serverfault/en/5fff3e4524544316281a16b0.html

# 参考

[官方文档](https://docs.openstack.org/kolla-ansible/train/reference/index.html)

https://blog.csdn.net/networken/article/details/106728002

https://blog.csdn.net/qq_33316576/article/details/107457111

https://blog.csdn.net/networken/article/details/106745167















