---
title: "docker | 部署静态网站（nginx）" 
date: 2019-08-01
lastmod: 2019-08-01
tags: 
- docker
keywords:
- linux
- docker
description: "在docker中快速部署一个可以提供web服务的nginx服务器" 
cover:
    image: "https://image.lvbibir.cn/blog/docker.png" 
---

# 创建映射80端口的交互式容器

```
[root@localhost ~]# docker run -it  -p 80 --name web centos /bin/bash
```

# 安装nginx
安装wget、vim、make以及一些所需要的库文件和语言环境
```
[root@ca453e479d0c /]# yum -y install wget gcc vim make
[root@ca453e479d0c ~]# yum -y install gcc gcc-c++ automake pcre pcre-devel zlib zlib-devel open openssl-devel
```
下载nginx，解压安装

```
[root@ca453e479d0c ~]# cd /usr/local/
[root@ca453e479d0c local]# wget http://nginx.org/download/nginx-1.7.4.tar.gz
[root@ca453e479d0c local]# tar zxf nginx-1.7.4.tar.gz 
[root@ca453e479d0c local]# cd nginx-1.7.4
[root@ca453e479d0c nginx-1.7.4]# ./configure prefix=/usr/local/nginx && make && make install
```

# 创建静态页面

```
[root@ca453e479d0c ~]# mkdir -p /var/www/html
[root@ca453e479d0c ~]# cd /var/www/html/
[root@ca453e479d0c html]# vim index.html
```
```html
<html>
<head>
        <title>Nginx in docker</title>
</head>
<body>
        <h1>Hello, I'm website in Docker!</h1>
</body>
</html>
```



# 修改nginx配置文件

```
[root@ca453e479d0c ~]# vim /usr/local/nginx/conf/nginx.conf

 location / {
            root   /var/www/html; 
            index  index.html index.htm;
        }
```

# 运行nginx

```
[root@ca453e479d0c sbin]# ln -s /usr/local/nginx/sbin/nginx /usr/local/sbin/
[root@ca453e479d0c sbin]# nginx
[root@ca453e479d0c ~]# ps -ef
UID         PID   PPID  C STIME TTY          TIME CMD
root          1      0  0 07:16 pts/0    00:00:00 /bin/bash
root       5417      1  0 07:54 ?        00:00:00 nginx: master process ./nginx
nobody     5418   5417  0 07:54 ?        00:00:00 nginx: worker process
root       5422      1  0 07:55 pts/0    00:00:00 ps -ef
```

# 验证网站访问
查看映射端口
```
[root@localhost ~]# docker ps
[root@localhost ~]# docker port web
80/tcp -> 0.0.0.0:32769
```
![在这里插入图片描述](https://image.lvbibir.cn/blog/20190801155750884.png)
验证nginx是否可以对外提供服务

```
[root@localhost ~]# curl http://127.0.0.1:32769
<html>
<head>
	<title>Nginx in docker</title>
</head>
<body>
	<h1>Hello, I'm website in Docker!</h1>
</body>
</html>
```
浏览器访问（宿主机ip地址）

![在这里插入图片描述](https://image.lvbibir.cn/blog/20190801160902763.png)

查看容器的ip地址

```
[root@localhost ~]# docker inspect web | grep IPAddress
            "SecondaryIPAddresses": null,
            "IPAddress": "172.17.0.3",
                    "IPAddress": "172.17.0.3",
                    
[root@localhost ~]# curl http://172.17.0.3
<html>
<head>
	<title>Nginx in docker</title>
</head>
<body>
	<h1>Hello, I'm website in Docker!</h1>
</body>
</html>
```
浏览器访问（容器ip地址）

![在这里插入图片描述](https://image.lvbibir.cn/blog/20190801160941569.png)