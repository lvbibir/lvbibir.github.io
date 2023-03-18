---
title: "cicd | jenkins部署mall-swarm项目" 
date: 2022-03-15
lastmod: 2022-03-15
tags: 
- cicd
- docker
keywords:
- devops
- cicd
- jenkins
- gitlab
- docker
description: "以 mall-swarm 项目为例，部署一套 jenkis + gitlab + docker的一套 CICD 流水线" 
cover:
    image: "https://image.lvbibir.cn/blog/cicd.png" 
    hidden: true
    hiddenInSingle: true 
---

# 前言

基础环境

- 系统：Centos 7.9.2009 minimal
- 配置：4 cpus / 24G mem / 50G disk
- 网卡：1.1.1.4/24

我这里采用的是 all-in-one 的配置，即所有操作都在一台主机上，如资源充足可以将 jenkins和gitlab 与后续项目容器分开部署

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
yum install -y wget net-tools vim bash-completion unzip

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

修改默认密码

![image-20230316102521034](https://image.lvbibir.cn/blog/image-20230316102521034.png)

## 4.3 上传项目

新建空白项目

![image-20230316100124782](https://image.lvbibir.cn/blog/image-20230316100124782.png)

新建 mall-swarm 项目

![image-20230316103923131](https://image.lvbibir.cn/blog/image-20230316103923131.png)





clone github上的原项目，我是windows系统，所以这里用的是git-bash

```bash
git clone https://github.com/macrozheng/mall-swarm.git
cd mall-swarm

# 重命名github远端仓库
git remote rename origin github
# 添加gitlab仓库
git remote add gitlab http://1.1.1.4:1080/root/mall-swarm.git
git remote -v
```

![image-20230316101527597](https://image.lvbibir.cn/blog/image-20230316101527597.png)

修改一下 docker.host 变量

![image-20230316101902285](https://image.lvbibir.cn/blog/image-20230316101902285.png)

新建 commit 并提交到 gitlab 仓库，初次提交需要输入 gitlab 的用户名密码

```bash
git add .
git commit -m "change docker.host -> 1.1.1.4"
git push gitlab master
```

![image-20230316103602343](https://image.lvbibir.cn/blog/image-20230316103602343.png)

默认配置不合理，修改 docker-compose-env.yml 中 nginx 的配置文件挂载

```
      - /data/nginx/nginx.conf:/etc/nginx/nginx.conf #配置文件挂载
```

![image-20230316123226022](https://image.lvbibir.cn/blog/image-20230316123226022.png)

上传到gitlab

```bash
git add .
git commit -m "update nginx volume config in document/docker/docker-compose.env.yml"
git push gitlab master
```

# 5. 依赖服务部署

需要上传到服务器的配置文件准备，如下图所示，为了方便可以将整个`document`目录传到服务器

![image-20230316105111389](https://image.lvbibir.cn/blog/image-20230316105111389.png)

## 5.1 前期配置

Elasticsearch

- 设置内核参数，否则会因为内存不足无法启动

  ```bash
  sysctl -w vm.max_map_count=262144
  sysctl -p
  ```

- 创建数据目录并设置权限，否则会报权限错误

  ```bash
  mkdir -p /mydata/elasticsearch/data/
  chmod 777 /mydata/elasticsearch/data/
  ```

Nginx

- 创建目录，上传配置文件
  ```bash
  mkdir -p /mydata/nginx/conf/
  cp /mydata/document/docker/nginx.conf /mydata/nginx/conf/
  ```

Logstash

- 创建目录上传配置文件
  ```bash
  mkdir /mydata/logstash
  cp /mydata/document/elk/logstash.conf /mydata/logstash/
  ```

## 5.2 启动服务

```bash
docker-compose -f /mydata/document/docker/docker-compose-env.yml up -d
```

docker-compose 会自动创建一个 `docker_default` 网络，所有容器都在这个网络下

![image-20230316110813031](https://image.lvbibir.cn/blog/image-20230316110813031.png)

启动完成后 rabbitmq 由于权限问题未能正常启动，给 log 目录设置权限，再执行 docker-compose 启动异常的容器

```bash
chmod 777 /mydata/rabbitmq/log/
docker-compose -f /mydata/document/docker/docker-compose-env.yml up -d
```

确保所有容器正常启动

```bash
docker ps | grep -v "Up"
```

## 5.3 服务配置

mysql

> 需要创建 mall 数据库并授权给 reader 用户

- 将 sql 文件拷贝到容器

  ```bash
  docker cp /mydata/document/sql/mall.sql mysql:/
  ```

- 进入mysql容器执行如下操作

  ```bash
  # 进入mysql容器
  docker exec -it mysql /bin/bash
  # 连接到mysql服务
  mysql -uroot -proot --default-character-set=utf8
  # 创建远程访问用户
  grant all privileges on *.* to 'reader' @'%' identified by '123456';
  # 创建mall数据库
  create database mall character set utf8;
  # 使用mall数据库
  use mall;
  # 导入mall.sql脚本
  source /mall.sql;
  # 退出数据库
  exit
  # 退出容器
  ctrl + d
  ```

Elasticsearch

- 需要安装中文分词器 IKAnalyzer [下载地址](https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v7.17.3/elasticsearch-analysis-ik-7.17.3.zip)

  注意版本需要与 elasticsearch 的版本一致

- 上传到服务器并解压到 plugins 目录

  ```bash
  mkdir /mydata/elasticsearch/plugins/analysis-ik
  unzip /mydata/elasticsearch-analysis-ik-7.17.3.zip -d /mydata/elasticsearch/plugins/analysis-ik/
  ```

- 重启容器

  ```bash
  docker restart elasticsearch
  ```

Logstash

- 安装 `json_lines` 插件并重启

  ```bash
  docker exec -it logstash /bin/bash
  logstash-plugin install logstash-codec-json_lines
  docker restart logstash
  ```

rabbitmq

> 需要创建一个mall用户并设置虚拟host为/mall

- 访问管理页面: http://1.1.1.4:15672/ 
  默认账户密码: guest / guest

- 创建管理员用户: mall / mall

  ![image-20230316121205905](https://image.lvbibir.cn/blog/image-20230316121205905.png)

- 创建一个新的虚拟host为 /mall

  ![image-20230316121307706](https://image.lvbibir.cn/blog/image-20230316121307706.png)

- 点击mall用户进入用户配置界面

  ![image-20230316121408922](https://image.lvbibir.cn/blog/image-20230316121408922.png)

- 给mall账户配置虚拟host /mall 的权限

  ![image-20230316121547316](https://image.lvbibir.cn/blog/image-20230316121547316.png)

nacos

- 由于我们使用Nacos作为配置中心，统一管理配置，所以我们需要将项目`config`目录下的所有配置都添加到Nacos中
  Nacos访问地址：http://1.1.1.4:8848/nacos/
  账号密码：nacos / nacos

- 需要上传的配置

  <img src="https://image.lvbibir.cn/blog/image-20230316124304792.png" alt="image-20230316124304792"  />

- 上传配置

  ![image-20230316124618771](https://image.lvbibir.cn/blog/image-20230316124618771.png)

- 全部上传完成

  ![image-20230316124828650](https://image.lvbibir.cn/blog/image-20230316124828650.png)

# 6. jenkins手动发布项目

## 6.1 脚本配置

> Jenkins自动化部署是需要依赖Linux执行脚本的

添加执行权限

```bash
chmod a+x /mydata/document/sh/*.sh
```

> 之前使用的是`Docker Compose`启动所有依赖服务，会默认创建一个网络，所有的依赖服务都会在此网络之中，不同网络内的服务无法互相访问。所以需要指定`sh`脚本中服务运行的的网络，否则启动的应用服务会无法连接到依赖服务。

修改脚本内容，为每个脚本添加`--network docker_default \`

```bash
sed -i '/^docker run/ a\--network docker_default \\' /mydata/document/sh/*.sh
```

确认修改是否成功

![image-20230316125833420](https://image.lvbibir.cn/blog/image-20230316125833420.png)

## 6.2 jenkins配置

### 6.2.1 mall-admin工程配置

> 由于各个模块执行任务的创建都大同小异，下面将详细讲解`mall-admin`模块任务的创建，其他模块将简略讲解。

![image-20230316131035301](https://image.lvbibir.cn/blog/image-20230316131035301.png)

源码管理

![image-20230316131241019](https://image.lvbibir.cn/blog/image-20230316131241019.png)

创建一个构建，构建`mall-swarm`项目中的依赖模块，否则当构建可运行的服务模块时会因为无法找到这些模块而构建失败

```bash
# 只install mall-common,mall-mbg两个模块
clean install -pl mall-common,mall-mbg -am
```

创建一个构建，单独构建并打包`mall-admin`模块

```
clean package
${WORKSPACE}/mall-admin/pom.xml
```

![image-20230316131838994](https://image.lvbibir.cn/blog/image-20230316131838994.png)

再创建一个构建，通过SSH去执行`sh`脚本，这里执行的是`mall-admin`的运行脚本：

![image-20230316132503984](https://image.lvbibir.cn/blog/image-20230316132503984.png)

### 6.2.2 其他模块工程配置

以 mall-gateway 为例

输入任务名称，直接复制 mall-admin 工程配置

![image-20230316132845976](https://image.lvbibir.cn/blog/image-20230316132845976.png)

修改第二步构建中的 pom 文件位置和第三步构建中的 sh 文件位置

![image-20230316133013058](https://image.lvbibir.cn/blog/image-20230316133013058.png)

## 6.3 开始构建

单击开始构建即可开始构建任务，可以实时看到任务的控制台输出

![image-20230316134827150](https://image.lvbibir.cn/blog/image-20230316134827150.png)

> 由于作为注册中心和配置中心的Nacos已经启动了，其他模块基本没有启动顺序的限制，但是最好还是按照下面的顺序启动。

推荐启动顺序：

- mall-auth
- mall-gateway
- mall-monitor
- mall-admin
- mall-portal
- mall-search
