---
title: "centos6 部署 openvpn" 
date: 2021-07-01
lastmod: 2021-07-01
tags: 
- linux
- centos
keywords:
- linux
- openvpn
- centos
- 服务部署
- 内网穿透
description: "介绍如何在centos6的环境中部署openvpn服务实现内网穿透" 
cover:
    image: "https://image.lvbibir.cn/blog/OpenVPN_logo.png" 
---
# 1. 实验环境

3台 centos6.5，1台 win10，openvpn-2.4.7，easy-rsa-3.0.5

# 2. 拓扑结构

Win10 安装 openvpn-gui，三台 centos6.5 为 vmware虚拟机，分为 client、vpnserver、proxy

三台 centos6.5 的 eth0 网卡均为内网(lan区段)地址 1.1.1.0/24 网段，proxy 额外添加一块 eth1 网卡设置 nat 模式模拟外网 ip

# 3. 实验目的

win10访问proxy的外网ip对应端口连接到vpnserver，分配到内网ip后可以访问到client

# 4. 实验思路

- proxy配置ipv4转发，将访问到本机eth1网卡相对应的端口上的流量转发给vpnserver的vpn服务端口

- vpnserver为win10分配ip实现访问内网

# 5. 实施步骤

## 5.1 初始化环境

- **虚拟机安装过程**

略

- **配置ip**

| 节点        | ip                            |
| ----------- | ----------------------------- |
| client：    | 1.1.1.1/24                    |
| vpnserver： | 1.1.1.2/24                    |
| proxy：     | 1.1.1.3/24 192.168.150.114/24 |
| win10：     | 192.168.150.1/24              |

- **环境初始化（client和vpnserver关闭iptables和selinux，proxy仅关闭selinux）**

[root@vpnserver ~]# sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
[root@vpnserver ~]# setenforce 0

## 5.2 安装vpnserver及easy-rsa

- **vpnserver安装openvpn**

由于centos6的所有官方源已失效，使用https://www.xiaofeng.org/article/2019/10/centos6buildinstallopenvpnrpm-17.html中的方法将源码编译成rpm包。

openvpn版本：2.4.7

------

![image-20210513152208797](https://image.lvbibir.cn/blog/image-20210513152208797.png)



- **下载easy-rsa**

下载地址：https://github.com/OpenVPN/easy-rsa/tree/v3.0.5

![image-20210513154450075](https://image.lvbibir.cn/blog/image-20210513152355808.png)



## 5.3 创建openvpn目录，配置vars变量

- 解压easy-rsa目录

[root@vpnserver ~]# mkdir openvpn
[root@vpnserver ~]# unzip easy-rsa-3.0.5.zip
[root@vpnserver ~]# mv easy-rsa-3.0.5 easy-rsa
[root@vpnserver ~]# mkdir -p /etc/openvpn
[root@vpnserver ~]# cp -a easy-rsa /etc/openvpn

- 配置/etc/openvpn目录

[root@vpnserver ~]# cd /etc/openvpn/easy-rsa/easyrsa3/
[root@vpnserver easyrsa3]# cp vars.example vars
[root@vpnserver easyrsa3]# vim vars
添加如下变量

```
set_var EASYRSA_REQ_COUNTRY     "CN"
set_var EASYRSA_REQ_PROVINCE    "Beijing"
set_var EASYRSA_REQ_CITY        "Beijing"
set_var EASYRSA_REQ_ORG         "lvbibir"
set_var EASYRSA_REQ_EMAIL       "lvbibir@163.com"
set_var EASYRSA_REQ_OU          "My OpenVPN"
```

## 5.4 创建服务端证书及key

- 创建服务端证书及key

初始化

[root@vpnserver ~]# cd /etc/openvpn/easy-rsa/easyrsa3/
[root@vpnserver easyrsa3]# ./easyrsa init-pki

![image-20210513154251555](https://image.lvbibir.cn/blog/image-20210513154251555.png)

创建根证书

[root@vpnserver easyrsa3]# ./easyrsa build-ca

![image-20210513152355808](https://image.lvbibir.cn/blog/image-20210513154450075.png)

注意：在上述部分需要输入PEM密码 PEM pass phrase，输入两次，此密码必须记住，不然以后不能为证书签名。还需要输入common name 通用名，这个你自己随便设置个独一无二的

创建服务器端证书

[root@vpnserver easyrsa3]# ./easyrsa gen-req server nopass

![image-20210513154701536](https://image.lvbibir.cn/blog/image-20210513154701536.png)

该过程中需要输入common name，随意但是不要跟之前的根证书的一样

签约服务端证书

[root@vpnserver easyrsa3]# ./easyrsa sign server server

![image-20210513154839323](https://image.lvbibir.cn/blog/image-20210513154839323.png)

需要手动输入yes去人，还需要提供创建ca证书时的密码

创建Diffie-Hellman，确保key穿越不安全网络的命令

[root@vpnserver easyrsa3]# ./easyrsa gen-dh

![image-20210513155046945](https://image.lvbibir.cn/blog/image-20210513155046945.png)

## 5.5 创建客户端证书及key

- 创建客户端证书

初始化

[root@vpnserver ~]# mkdir client
[root@vpnserver ~]# cd client/easy-rsa/easyrsa3/
[root@vpnserver easyrsa3]# ./easyrsa init-pki

![需输入yes确认](https://image.lvbibir.cn/blog/image-20210513155822077.png)

需输入yes确认

创建客户端key及生成证书

[root@vpnserver easyrsa3]# ./easyrsa gen-req zhijie.liu

![image-20210513160134188](https://image.lvbibir.cn/blog/image-20210513161517810.png)

名字自己自定义，该密码是用户使用该key登录时输入的密码，可以加nopass参数在客户端登录时无需输入密码

导入req证书

[root@vpnserver ~]# cd /etc/openvpn/easy-rsa/easyrsa3/
[root@vpnserver easyrsa3]# ./easyrsa import-req /root/client/easy-rsa/easyrsa3/pki/reqs/zhijie.liu.req zhijie.liu

![image-20210513161517810](https://image.lvbibir.cn/blog/image-20210513160134188.png)

签约证书

[root@vpnserver easyrsa3]# ./easyrsa sign client zhijie.liu

![image-20210513161637077](https://image.lvbibir.cn/blog/image-20210513162659235.png)

这里生成client，名字要与之前导入名字一致

签约证书期间需要输入yes确认，期间需要输入CA的密码

## 5.6 归置服务器和客户端的证书

- 把服务器端必要文件放到/etc/openvpn下（ca证书、服务端证书、密钥）

[root@vpnserver ~]# cp /etc/openvpn/easy-rsa/easyrsa3/pki/ca.crt /etc/openvpn/
[root@vpnserver ~]# cp /etc/openvpn/easy-rsa/easyrsa3/pki/private/server.key /etc/openvpn/
[root@vpnserver ~]# cp /etc/openvpn/easy-rsa/easyrsa3/pki/issued/server.crt /etc/openvpn/
[root@vpnserver ~]# cp /etc/openvpn/easy-rsa/easyrsa3/pki/dh.pem /etc/openvpn/

- 把客户端必要文件放到/root/client目录下（客户端的证书、密钥）

[root@vpnserver ~]# cp /etc/openvpn/easy-rsa/easyrsa3/pki/ca.crt /root/client
[root@vpnserver ~]# cp /etc/openvpn/easy-rsa/easyrsa3/pki/issued/zhijie.liu.crt /root/client/
[root@vpnserver ~]# cp /root/client/easy-rsa/easyrsa3/pki/private/zhijie.liu.key /root/client

## 5.7 vpn服务端server.conf配置文件修改

- 为服务器端编写配置文件

安装好配置文件后他会提供一个server配置的文件案例，将该文件放到/etc/openvpn下

[root@vpnserver ~]# rpm -ql openvpn | grep server.conf

![image-20210513162659235](https://image.lvbibir.cn/blog/image-20210513161637077.png)

[root@vpnserver ~]# cp /usr/share/doc/openvpn-2.4.7/sample/sample-config-files/server.conf /etc/openvpn/

- 修改配置文件

[root@vpnserver ~]# vim /etc/openvpn/server.conf

```
[root@vpnserver ~]#  grep '^[^#|;]' /etc/openvpn/server.conf
local 0.0.0.0     #监听地址
port 1194     #监听端口
proto tcp     #监听协议
dev tun     #采用路由隧道模式
ca /etc/openvpn/ca.crt      #ca证书路径
cert /etc/openvpn/server.crt       #服务器证书
key /etc/openvpn/server.key  # This file should be kept secret 服务器秘钥
dh /etc/openvpn/dh.pem     #密钥交换协议文件
server 10.8.0.0 255.255.255.0     #给客户端分配地址池，注意：不能和VPN服务器内网网段有相同
ifconfig-pool-persist ipp.txt
push "route 1.1.1.0 255.255.255.0"	#推送内网地址
client-to-client       #客户端之间互相通信
keepalive 10 120       #存活时间，10秒ping一次,120 如未收到响应则视为断线
comp-lzo      #传输数据压缩
max-clients 100     #最多允许 100 客户端连接
user openvpn       #用户
group openvpn      #用户组
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
log         /var/log/openvpn/openvpn.log
verb 3
```

## 5.8 后续设置（用户、iptables和路由转发）

- 后续设置

[root@vpnserver ~]# mkdir /var/log/openvpn/
[root@vpnserver ~]# useradd openvpn -s /sbin/nologin
[root@vpnserver ~]# chown -R openvpn.openvpn /var/log/openvpn/
[root@vpnserver ~]# chown -R openvpn.openvpn /etc/openvpn/*



- iptables设置nat规则和打开路由转发

[root@vpnserver ~]# iptables -A INPUT -p tcp --dport 1194 -j ACCEPT
[root@vpnserver ~]# iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
[root@vpnserver ~]# iptables -vnL -t nat

```
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 MASQUERADE  all  --  *      *       10.8.0.0/24          0.0.0.0/0

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
```

[root@vpnserver ~]# vim /etc/sysctl.conf

```
net.ipv4.ip_forward = 1
```

[root@vpnserver ~]# sysctl -p



- 开启openvpn服务

[root@vpnserver ~]# openvpn --daemon --config /etc/openvpn/server.conf
[root@vpnserver ~]# netstat -anput |  grep 1194

![image-20210513170615121](https://image.lvbibir.cn/blog/image-20210514103246272.png)



- proxy开启端口转发/映射

[root@along ~]# vim /etc/sysctl.conf //打开路由转发

```
net.ipv4.ip_forward = 1
```

[root@proxy ~]# sysctl -p

[root@proxy ~]# iptables -t nat -A PREROUTING -d 192.168.150.114 -p tcp --dport 1194 -j DNAT --to-destination 1.1.1.2:1194
[root@proxy ~]# iptables -t nat -A POSTROUTING -d 1.1.1.2 -p tcp --dport 1194 -j SNAT --to 1.1.1.3
[root@proxy ~]# iptables -A FORWARD -o eth0 -d 1.1.1.2 -p tcp --dport 1194 -j ACCEPT
[root@proxy ~]# iptables -A FORWARD -i eth0 -s 1.1.1.2 -p tcp --sport 1194 -j ACCEPT

[root@proxy ~]# iptables -A INPUT -p tcp --dport 1194 -j ACCEPT

![image-20210514103123530](https://image.lvbibir.cn/blog/image-20210513170615121.png)

[root@proxy ~]# service iptables save
[root@proxy ~]# service iptables reload
[root@proxy ~]# iptables -L -n

![image-20210514103246272](https://image.lvbibir.cn/blog/image-20210514173058861.png)

# 6.客户段连接测试

- 下载openvpn客户端

略



## 6.1 配置client端配置文件

[root@vpnserver ~]# rpm -ql openvpn | grep client.ovpn

/usr/share/doc/openvpn-2.4.7/sample/sample-plugins/keying-material-exporter-demo/client.ovpn

[root@vpnserver ~]# cp /usr/share/doc/openvpn-2.4.7/sample/sample-plugins/keying-material-exporter-demo/client.ovpn /root/client
[root@vpnserver ~]# vim /root/client/client.ovpn

client
dev tun
proto tcp     
remote 192.168.150.114 1194    
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client.crt     
key client.key      
comp-lzo
verb 3

## 6.2 拷贝客户端证书及配置文件

vpnserver没装vmtools所以先将所有文件放到proxy上然后通过远程工具下载

[root@vpnserver openvpn]# scp /root/client/ca.crt root@1.1.1.3:/root/
[root@vpnserver openvpn]# scp /root/client/zhijie.liu.crt root@1.1.1.3:/root/
[root@vpnserver openvpn]# scp /root/client/zhijie.liu.key root@1.1.1.3:/root/
[root@vpnserver openvpn]# scp /root/client/client.ovpn root@1.1.1.3:/root/

将这四个文件放到win10的C:\Users\lvbibir\OpenVPN\config目录下

![image-20210514173058861](https://image.lvbibir.cn/blog/image-20210514173036246.png)

![image-20210514173036246](https://image.lvbibir.cn/blog/image-20210514103123530.png)

## 6.3 ping测试

ping client的内网ip1.1.1.1

![image-20210514173131498](https://image.lvbibir.cn/blog/image-20210514173131498.png)































参考：

centos6源码编译openvpn并打包成rpm

https://www.xiaofeng.org/article/2019/10/centos6buildinstallopenvpnrpm-17.html

openvpn源码下载地址

https://openvpn.net/community-downloads/

centos6搭建openvpn

http://www.likecs.com/show-6021.html

centos6做端口映射/端口转发

https://blog.csdn.net/weixin_30872499/article/details/96654741?utm_medium=distribute.pc_relevant.none-task-blog-baidujs_baidulandingword-0&spm=1001.2101.3001.4242