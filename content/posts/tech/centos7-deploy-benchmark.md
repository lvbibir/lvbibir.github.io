---
title: "centos7 | benchmark 平台部署" 
date: 2021-07-01
lastmod: 2024-01-26
tags: 
  - linux
  - centos
keywords:
  - linux
  - centos
  - benchmark
  - 基线检查
description: "介绍在 centos7 环境中部署开源的 benchmark 基线检查平台，并通过 web 界面可视化展示" 
cover:
    image: "https://image.lvbibir.cn/blog/image-20210719165252503.png" 
---

# 0 介绍

[项目地址](https://github.com/chroblert/SecurityBaselineCheck)

这个项目准备打造一个安全基线检查平台，期望能够以最简单的方式在需要进行检查的服务器上运行。能够达到这么一种效果：基线检查脚本 (以后称之为 agent) 可以单独在目标服务器上运行，并展示出相应不符合基线的地方，并且可以将检查时搜集到的信息以 json 串的形式上传到后端处理服务器上，后端服务器可以进行统计并进行可视化展示。

Agent 用到的技术：

- Shell 脚本
- Powershell 脚本

后端服务器用到的技术：

- python
- django
- bootstrap
- html

存储所用：

- sqlite3

# 1 前端页面部署

## 1.1 环境

- 系统 centos7.8(最小化安装)
- 前端：192.168.150.101
- client 端：192.168.150.102

## 1.2 安装 python3.6

[源码包下载地址](https://www.python.org/downloads/source/)

```bash
yum install gcc gcc-c++ zlib-devel sqlite-devel mariadb-server mariadb-devel openssl-devel tcl-devel tk-devel tree libffi-devel -y

tar -xf Python-3.6.10.tgz
./configure --enable-optimizations 
make
make install

python3 -V
```

## 1.3 安装 pip3+django

[源码包下载地址](https://github.com/pypa/pip/releases/tag/21.0.1)

```bash
tar zxvf pip-21.0.1.tar.gz
cd pip-21.0.1/
python3 setup.py build
python3 setup.py install
pip3 install django==2.2.15
```

![image-20210719164840514](https://image.lvbibir.cn/blog/image-20210719164840514.png)

## 1.4 clone 项目到本地

```bash
yum install -y git
git clone https://github.com/chroblert/assetmanage.git
```

![image-20210719162320356](https://image.lvbibir.cn/blog/image-20210719162320356.png)

## 1.5 部署 server 端

```bash
cd assetManage
# 使用 python3 安装依赖包
python3 -m pip install -r requirements.txt
python3 manage.py makemigrations
python3 manage.py migrate
python3 manage.py runserver 0.0.0.0:8888
# 假定该服务器的 IP 为 112.112.112.112
```

![image-20210719165032945](https://image.lvbibir.cn/blog/image-20210721093225342.png)

访问测试：<http://192.168.150.101:8888/>

![image-20210719165252503](https://image.lvbibir.cn/blog/image-20210719165252503.png)

# 2 客户端进行检查

- 将项目目录中的 Agent 目录 copy 到需要进行基线检查的客户端

```bash
scp -r assetmanage/Agent/ 192.168.150.102:/root/
```

![image-20210721092835125](https://image.lvbibir.cn/blog/image-20210721092835125.png)

```bash
cd Agent/
chmod a+x ./*.sh
```

- 修改 linux_baseline_check.sh 文件的最后一行，配置前端 django 项目的 ip 和端口

![image-20210721093225342](https://image.lvbibir.cn/blog/image-20210721093304920.png)

- 运行脚本即可，终端会有检查结果的输出，前端页面相应也会有数据

![image-20210721093304920](https://image.lvbibir.cn/blog/image-20210719165252503.png)

![image-20210721094328627](https://image.lvbibir.cn/blog/image-20210719165032945.png)

![image-20210721094411728](https://image.lvbibir.cn/blog/image-20210721094423226.png)

![image-20210721094423226](https://image.lvbibir.cn/blog/image-20210721094411728.png)

以上
