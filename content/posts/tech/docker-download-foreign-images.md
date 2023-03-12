---
title: "docker | 下载外网镜像的几种方式" 
date: 2023-03-09
lastmod: 2023-03-09
tags: 
- docker
- kubernetes
keywords:
- linux
- docker
description: "通过阿里云免费的容器镜像服务，构建平常无法下载的 gcr.io 或者 quay.io 等仓库的镜像" 
cover:
    image: "https://image.lvbibir.cn/blog/docker.png" 
---

# 1. 阿里云构建

## 1.1 git仓库设置

### 1.1.1 创建仓库

用于存放Dockerfile

![image-20230309160649438](https://image.lvbibir.cn/blog/image-20230309160649438.png)

### 1.1.2 上传Dockerfile

```bash
#换成自己的仓库地址
git clone https://github.com/lvbibir/docker-images
cd docker-images
mkdir -p k8s.gcr.io/pause-3.2/
echo "FROM k8s.gcr.io/pause:3.2" > k8s.gcr.io/pause-3.2/Dockerfile
git add .
git commit -m 'new image: k8s.gcr.io/pause:3.2'
# 默认分支可能是main，取决于你的github设置
git push origin master
```

![image-20230309163259040](https://image.lvbibir.cn/blog/image-20230309163259040.png)

## 1.2 阿里云设置

登陆阿里云，访问[阿里云容器镜像服务](https://cr.console.aliyun.com/cn-hangzhou/instances)

### 1.2.1 创建个人实例

![image-20230309160101014](https://image.lvbibir.cn/blog/image-20230309160101014.png)

### 1.2.2 进入个人实例创建命名空间

![image-20230309160146287](https://image.lvbibir.cn/blog/image-20230309160146287.png)

### 1.2.3 创建访问凭证

![image-20230309160252483](https://image.lvbibir.cn/blog/image-20230309160252483.png)

### 1.2.4 绑定github账号

![image-20230309160359915](https://image.lvbibir.cn/blog/image-20230309160359915.png)

### 1.2.5 新建镜像仓库

![image-20230309162613107](https://image.lvbibir.cn/blog/image-20230309162613107.png)

指定刚才创建的github仓库，记得勾选海外机器构建

![image-20230309162914840](https://image.lvbibir.cn/blog/image-20230309162914840.png)

### 1.2.6 新建构建

![image-20230309163430105](https://image.lvbibir.cn/blog/image-20230309163430105.png)

手动触发构建，正常状况应该可以看到构建成功

![image-20230309163539554](https://image.lvbibir.cn/blog/image-20230309163539554.png)

### 1.2.7 镜像下载

操作指南里可以看到如何下载镜像，标签即刚才**新建构建**时指定的**镜像版本**

![image-20230309163731277](https://image.lvbibir.cn/blog/image-20230309163731277.png)

# 2. gcr.io_mirror

[项目地址](https://github.com/anjia0532/gcr.io_mirror/)

该项目通过 `Github Actions` 将 `gcr.io、k8s.gcr.io、registry.k8s.io、quay.io、ghcr.io` 镜像仓库的镜像搬运至dockerhub

直接提交issue，在模板issue的`[PORTER]`后面添加想要搬运的镜像tag，也可以直接在关闭的issue列表中检索，可能也会有其他人搬运过，直接用就行了

![image-20230309164622746](https://image.lvbibir.cn/blog/image-20230309164622746.png)

稍等一小会可以看到镜像已经搬运到dockerhub了

![image-20230309164858625](https://image.lvbibir.cn/blog/image-20230309164858625.png)

# 3. Docker Playground

[Docker Playground](https://labs.play-with-docker.com/) 是一个免费的线上docker环境，由于是外网环境所以下载镜像、推送到dockerhub都很快，也可以直接推到阿里云的仓库

![image-20230309170605907](https://image.lvbibir.cn/blog/image-20230309170605907.png)

# 4. http proxy

如果有代理软件可以在docker中配置代理实现

```json
{
 "proxies":
 {
   "default":
   {
     "httpProxy": "http://127.0.0.1:1080",
     "httpsProxy": "http://127.0.0.1:1080",
     "noProxy": "*.test.example.com,.example2.com"
   }
 }
}
```

# 5. 使用国内现成的镜像站

这种方式的问题主要是镜像不全，且没有统一的管理，建议使用之前的四种方式

阿里云仓库

```bash
docker pull k8s.gcr.io/sig-storage/csi-node-driver-registrar:v2.3.0
# 换成
docker pull registry.aliyuncs.com/google_containers/csi-node-driver-registrar:v2.3.0
```

也可以使用 lank8s.cn，他们的对应关系 k8s.gcr.io –> lank8s.cn，gcr.io –> gcr.lank8s.cn

```bash
docker pull k8s.gcr.io/sig-storage/csi-node-driver-registrar:v2.3.0
# 换成
docker pull lank8s.cn/sig-storage/csi-node-driver-registrar:v2.3.0
```

中科大

```bash
docker image pull quay.io/kubevirt/virt-api:v0.45.0
# 换成
docker pull quay.mirrors.ustc.edu.cn/kubevirt/virt-api:v0.45.0
```

