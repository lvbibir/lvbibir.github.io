---
title: "mysql (一) 部署" 
date: 2022-05-02
lastmod: 2024-01-28
tags:
  - mysql
keywords:
  - mysql
description: "在 centos7 中部署 mysql-5.7 " 
cover:
    image: "images/logo-mysql.png" 
---

# 0 前言

基于 `centos-7.9` `mysql-5.7.42`

# 1 基础环境

配置 hostname

```bash
hostnamectl set-hostname master
bash
```

关闭防火墙及 selinux

```bash
iptables -F
systemctl disable firewalld
systemctl stop firewalld

sed -i '/SELINUX/s/enforcing/disabled/' /etc/sysconfig/selinux
setenforce 0
```

配置 yum 源

```bash
mkdir /etc/yum.repos.d/bak || true
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak/ || true

curl http://mirrors.aliyun.com/repo/Centos-7.repo -o /etc/yum.repos.d/Centos-Base.repo
sed -i '/aliyuncs.com/d' /etc/yum.repos.d/Centos-Base.repo
# curl http://mirrors.aliyun.com/repo/epel-7.repo -o /etc/yum.repos.d/epel.repo

yum clean all
yum makecache fast
yum install -y wget net-tools vim bash-completion ntpdate
timedatectl set-timezone Asia/Shanghai
ntpdate time.windows.com
```

卸载自带的 mariadb

```bash
yum remove -y $(rpm -qa | grep mariadb)
```

# 2 配置 yum 源

提供清华源和官方源两种方式, 任选其一, 前者速度稍快一些

## 2.1 清华源

这里使用的是清华的源

```bash
cat > /etc/yum.repos.d/mysql-community.repo << EOF
[mysql-connectors-community]
name=MySQL Connectors Community
baseurl=https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql-connectors-community-el7-\$basearch/
enabled=1
gpgcheck=1
gpgkey=https://repo.mysql.com/RPM-GPG-KEY-mysql

[mysql-tools-community]
name=MySQL Tools Community
baseurl=https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql-tools-community-el7-\$basearch/
enabled=1
gpgcheck=1
gpgkey=https://repo.mysql.com/RPM-GPG-KEY-mysql

[mysql-5.7-community]
name=MySQL 5.7 Community Server
baseurl=https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql-5.7-community-el7-\$basearch/
enabled=1
gpgcheck=1
gpgkey=https://repo.mysql.com/RPM-GPG-KEY-mysql
EOF
```

## 2.2 官方源

```bash
wget http://dev.mysql.com/get/mysql57-community-release-el7-8.noarch.rpm
yum localinstall mysql57-community-release-el7-8.noarch.rpm
```

# 3 安装 mysql

执行安装

```bash
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
yum install mysql-community-server
```

启动服务

```bash
systemctl enable --now mysqld
```

获取默认密码

```bash
# grep "password" /var/log/mysqld.log
2023-05-07T02:31:54.375626Z 1 [Note] A temporary password is generated for root@localhost: QZFuIayXk0:l
```

如果没有返回，找不到 root 密码，解决方案如下

```bash
# 删除原来安装过的mysql残留的数据
rm -rf /var/lib/mysql
# 重启 mysqld 服务, 会重新初始化数据
systemctl restart mysqld
# 再去找临时密码
grep 'temporary password' /var/log/mysqld.log
```

登录并修改密码

```bash
mysql -uroot -p # 输入默认密码
ALTER USER 'root'@'localhost' IDENTIFIED BY '<pass>'; # 修改密码, 需要有大小写和特殊符号
exit;
```

以上
