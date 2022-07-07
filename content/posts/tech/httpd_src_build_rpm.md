---
title: "httpd源码构建rpm" #标题
date: 2022-03-01T00:00:00+08:00 #创建时间
lastmod: 2022-03-01T00:00:00+08:00 #更新时间
author: ["lvbibir"] #作者
categories: 
- 
tags: 
- httpd
- rpm
description: "" #描述
weight: # 输入1可以顶置文章，用来给文章展示排序，不填就默认按时间排序
slug: ""
draft: false # 是否为草稿
comments: true #是否展示评论
showToc: true # 显示目录
TocOpen: true # 自动展开目录
hidemeta: false # 是否隐藏文章的元信息，如发布日期、作者等
disableShare: true # 底部不显示分享栏
showbreadcrumbs: true #顶部显示当前路径
cover:
    image: "" #图片路径：posts/tech/文章1/picture.png
    caption: "" #图片底部描述
    alt: ""
    relative: false
---
系统版本：isoft-serveros-v4.2（centos7）

源码下载链接：

- https://dlcdn.apache.org//apr/apr-1.7.0.tar.bz2

- https://dlcdn.apache.org//apr/apr-util-1.6.1.tar.bz2
- https://dlcdn.apache.org//httpd/httpd-2.4.52.tar.bz2

安装依赖

```bash
yum install -y wget gcc rpm-build 
yum install -y autoconf zlib-devel libselinux-devel libuuid-devel apr-devel apr-util-devel pcre-devel openldap-devel lua-devel libxml2-devel openssl-devel
yum install -y libtool doxygen
yum install -y postgresql-devel mysql-devel sqlite-devel unixODBC-devel nss-devel
```

libdb4-devel依赖需要使用epel源安装，这里使用阿里的epel源

```
# 添加阿里yum源
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
# 手动修改repo文件中的系统版本，因为本系统检测到的版本号是4
sed -i 's/$releasever/7/g' /etc/yum.repos.d/CentOS-Base.repo
# 安装epel源
yum install -y epel-release
# 安装libdb4-devel
yum install -y libdb4-devel
```

编译准备

```
[root@localhost ~]# mkdir -p /root/rpmbuild/{SPECS,SOURCES}
[root@localhost ~]# cd /root/rpmbuild/SOURCES/
[root@localhost SOURCES]# wget --no-check-certificate https://dlcdn.apache.org//apr/apr-util-1.6.1.tar.bz2
[root@localhost SOURCES]# tar  jxf apr-1.7.0.tar.bz2
[root@localhost SOURCES]# tar  jxf apr-util-1.6.1.tar.bz2
[root@localhost SOURCES]# tar  jxf httpd-2.4.52.tar.bz2
[root@localhost SOURCES]# cp apr-1.7.0/apr.spec ../SPECS/
[root@localhost SOURCES]# cp apr-util-1.6.1/apr-util.spec ../SPECS/
[root@localhost SOURCES]# cp httpd-2.4.52/httpd.spec ../SPECS/
```

开始编译

```
[root@localhost SOURCES]# cd ../SPECS/

# 修改spec文件
[root@localhost SPECS]# vim apr.spec
Release: 1%dist
[root@localhost SPECS]# vim apr-util.spec
Release: 1%dist
[root@localhost SPECS]# vim httpd.spec
Release: 1%dist

[root@localhost SPECS]# rpmbuild -ba apr.spec
[root@localhost SPECS]# rpm -Uvh /root/rpmbuild/RPMS/x86_64/apr-*

[root@localhost SPECS]# rpmbuild -ba apr-util.spec
[root@localhost SPECS]# rpm -Uvh /root/rpmbuild/RPMS/x86_64/apr-util-*

[root@localhost SPECS]# rpmbuild -ba httpd.spec
[root@localhost SPECS]# rpm -Uvh /root/rpmbuild/RPMS/x86_64/httpd-*
[root@localhost SPECS]# rpm -Uvh /root/rpmbuild/RPMS/x86_64/mod_*

# 打包所有的软件包
[root@localhost ~]# tar zcf httpd-2.4.25.tar.gz x86_64/
```

![image-20220304112802458](https://image.lvbibir.cn/blog/image-20220304112802458.png)

这里修改%dist是为了修改编译后生成的软件包的名字，dist具体代表什么可以在/etc/rpm/macros.dist文件中看到

![image-20220308100545732](https://image.lvbibir.cn/blog/image-20220308100545732.png)



![image-20220304113646615](https://image.lvbibir.cn/blog/image-20220304113646615.png)



