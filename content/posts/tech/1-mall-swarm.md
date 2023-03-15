---
title: "jenkins流水线搭建" 
date: 2023-03-15
lastmod: 2023-03-15
tags: 
- devops
- docker
keywords:
- devops
- cicd
- jenkins
- gitlab
- docker
description: "以 mall-swarm 项目为例，部署一套 jenkis + gitlab + docker + 钉钉机器人的一套 CICD 流水线" 
---

# 前言

基础环境

- 系统：Centos 7.9.2009 minimal
- 配置：4 cpus / 16G mem / 50G disk
- 网卡：1.1.1.4/24

我这里采用的是 all-in-one 的配置，即所有操作都在一台主机上，如资源充足可以将 jenkins和gitlab 与后续项目容器分开部署，建议机器内存不少于 16G，磁盘容量不少于 50G。

# 1. 系统配置

防火墙、selinux、yum

```bash
sed -i '/SELINUX/s/enforcing/disabled/' /etc/sysconfig/selinux
setenforce 0
iptables -F
systemctl disable firewalld
systemctl stop firewalld

mkdir /etc/yum.repos.d/bak
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak/

curl http://mirrors.aliyun.com/repo/Centos-7.repo -o /etc/yum.repos.d/Centos-Base.repo
sed -i '/aliyuncs.com/d' /etc/yum.repos.d/Centos-Base.repo

yum clean all
yum makecache fast
yum install -y wget net-tools vim bash-completion

mkdir /mydata
```

# 2. docker

先安装docker-compose

```bash
wget https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-linux-x86_64 -O /usr/local/bin/docker-compose
chmod a+x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose version
```

安装docker

```bash
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
yum -y install docker-ce
mkdir -p /etc/docker
# 镜像加速器
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://jc0srqak.mirror.aliyuncs.com"]
}
EOF
```

允许docker守护进程的tcp访问，为了后续jenkins构建时调用，以生成docker镜像

```bash
[root@localhost ~]# vim /usr/lib/systemd/system/docker.service
# 修改如下内容
# ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix://var/run/docker.sock

systemctl daemon-reload
systemctl restart docker && systemctl enable docker
```

查看端口，确保修改正确

```bash
[root@localhost ~]# ss -tnlp | grep 2375
LISTEN   0   128  [::]:2375   [::]:*  users:(("dockerd",pid=1124,fd=4))
```

安装一系列后续需要的镜像，镜像文件比较大，这步比较耗时

```bash
docker pull jenkins/jenkins:lts
docker pull gitlab/gitlab-ce:latest
docker pull mysql:5.7
docker pull redis:7
docker pull nginx:1.22
docker pull rabbitmq:3.9-management
docker pull elasticsearch:7.17.3
docker pull logstash:7.17.3
docker pull kibana:7.17.3
docker pull mongo:4
docker pull nacos/nacos-server:v2.1.0
```

# 3. jenkins

## 3.1 启动容器

```bash
docker run -d --restart=always \
-p 8080:8080 -p 50000:5000 \
--name jenkins -u root \
-v /mydata/jenkins_home:/var/jenkins_home \
jenkins/jenkins:lts

# 获取初始管理员密码
[root@localhost ~]# cat /mydata/jenkins_home/secrets/initialAdminPassword
bd5b64c7c8c8467985a0faa6fbe1848f
```

## 3.2 跳过在线验证

启动成功访问 http://1.1.1.4:8080 ，等出现密码界面后输入密码应该会进入一个离线页面，如下

![image-20230315161553373](https://image.lvbibir.cn/blog/image-20230315161553373.png)

❗ 这个界面不要关，新开一个窗口访问 http://1.1.1.4:8080/pluginManager/advanced

将 update site 的 url 修改为 `http://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json`，这步是为了加速插件安装

![image-20230315161635537](https://image.lvbibir.cn/blog/image-20230315161635537.png)

接下来跳过jenkins的在线验证，在终端再执行

```bash
docker exec -it jenkins /bin/sh -c "echo 127.0.0.1 www.google.com >> /etc/hosts"
docker exec -it jenkins cat /etc/hosts
```

然后回到第一个离线页面刷新一下，应该可以看到离线状态消除了，这里是因为jenkins在 `/mydata/jenkins_home/updates/default.json` 中定义了通过访问 google 来判断 jenkins 节点是否是在线状态

之后选择安装推荐的插件，进入插件安装界面，这个过程耗时会比较长，如果有插件安装失败可以重试

![image-20230315162316804](https://image.lvbibir.cn/blog/image-20230315162316804.png)

之后创建管理员用户，一路确定后到主页

## 3.3 插件配置

dashboard -> 系统管理 -> 插件管理中安装`ssh`插件和`Role-based Authorization Strategy`插件，安装完成后重启jenkins

![image-20230315171029905](https://image.lvbibir.cn/blog/image-20230315171029905.png)

新增 ssh 凭据

![image-20230315172425485](https://image.lvbibir.cn/blog/image-20230315172425485.png)

新增 ssh 配置，配置好之后右下角测试一下，连接正常后保存

![image-20230315172224961](https://image.lvbibir.cn/blog/image-20230315172224961.png)

新增 maven 配置

![image-20230315170741500](https://image.lvbibir.cn/blog/image-20230315170741500.png)

## 3.4 权限配置

> 我们可以使用Jenkins的角色管理插件来管理Jenkins的用户，比如我们可以给管理员赋予所有权限，运维人员赋予执行任务的相关权限，其他人员只赋予查看权限。

在系统管理->全局安全配置中启用基于角色的权限管理：

![image-20230315172813560](https://image.lvbibir.cn/blog/image-20230315172813560.png)

关闭代理，保存

![image-20230315172855436](https://image.lvbibir.cn/blog/image-20230315172855436.png)

分配管理员、运维和other三个角色，分别配置对应权限

![image-20230315173418268](https://image.lvbibir.cn/blog/image-20230315173418268.png)

![image-20230315173251456](https://image.lvbibir.cn/blog/image-20230315173251456.png)

将用户和角色绑定

![image-20230315173353689](https://image.lvbibir.cn/blog/image-20230315173353689.png)

# 4. gitlab

## 4.1 启动容器

```bash
docker run --detach --restart=always\
  -p 10443:443 -p 1080:80 -p 1022:22 \
  --name gitlab \
  --restart always \
  --volume /mydata/gitlab/config:/etc/gitlab \
  --volume /mydata/gitlab/logs:/var/log/gitlab \
  --volume /mydata/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest
  
# 获取密码
docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

访问http://1.1.1.4:1080/，默认用户为root

## 4.2 配置

配置中文，修改完后刷新网页即可

![image-20230315174825623](https://image.lvbibir.cn/blog/image-20230315174825623.png)

## 4.3 上传项目























