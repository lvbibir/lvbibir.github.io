---
title: "linux | 常用命令总结"
date: 2023-12-30
lastmod: 2025-09-01
tags:
  - linux
keywords:
  - linux
description: "记录 linux 系统如文本处理, 进程处理, 网络及其他的常用命令"
cover:
    image: "images/default-cover.webp"
---

# 1 文本处理

## 1.1 sed

截取 rpm 包名

```bash
cat rpms | sed -e s/-[[:digit:]]./@/ |  awk -F '@' '{print $1}'
```

## 1.2 awk

```bash
# 打印某列之后的所有列
awk ‘{ $1=""; print $0 }’ file_name
```

## 1.3 grep

```bash
# 去除注释和空行
grep -Ev '^$|#' filename
# 查找一个目录中不包含 "description" 的文件
grep -Lr "description" /your/directory/*
# 查找一个目录中包含 "title" 但是不包含 "description" 的文件
grep -r -l 'title' /your/directory/* | xargs grep -L 'description'
```

## 1.4 tee

```bash
# << EOF 要求结束符 EOF 必须顶格写且单独一行
# <<- EOF 允许结束符 EOF 之前存在制表符
# EOF 不加引号, 会进行变量扩展
# 'EOF' 加引号, 不会进行变量扩展

tee test.txt <<- 'EOF'
line 1
line 2
EOF
```

# 2 系统进程

## 2.1 ps

```bash
# 查看获取服务器内存占用内存较高的10个进程
ps aux | head -1; ps aux | grep -v PID | sort -rn -k +4 | head -10
# 查看获取服务器 CPU 占用内存较高的10个进程
ps aux | head -1; ps aux | grep -v PID | sort -rn -k +3 | head -10
# 查看进程启动时间
ps -eo pid,lstart,etime,cmd | grep java | grep 8082
```

# 3 网络

## 3.1 traceroute

```bash
# tcp
traceroute -n -T -p <port> <ip>
tcptraceroute <ip> <port>
# udp
traceroute -n -U -p <port> <ip>
```

## 3.2 nc

```bash
# tcp
nc -zvw 5 10.30.214.22 7001
# udp
nc -zvuw 5 11.53.89.7 5030
```

# 4 other

## 4.1 find

```bash
# 查找文件并删除
find . -type f -name '*flac' -print0| xargs -0 rm -f
# 查看所有文件的文件类型
find . -type f -exec file "{}" ";" | awk -F ': ' '$2 !~ /ASCII/ {print $1 ": " $2}'
# 将目录内所有的 crlf 文件转为 lf
find . -type f -exec file "{}" ";" | awk -F ': ' '$2 !~ /ASCII/ {print $1 ": " $2}' | grep CRLF | awk -F':' '{print $1}' | xargs dos2unix
# 查看目录下30天内未改动的文件
find /var/log -type f -mtime +30
# 删除目录下30天内未改动的文件
find /var/log -type f -mtime +30 -delete
# 查找一级目录下的二级目录包含的三级目录数量
for dir in $(ls /home/media/media/500509/servicerecord); do echo $dir $(find $dir  -maxdepth 1 -type d | wc -l); done | sort -nk2
```

## 4.2 tar

xz 多核压缩

```bash
# 多核压缩
tar cf - linux-3.10.0-327.36.4.el7/ | xz -4e -T8 > linux-3.10.0-327.36.4.el7.tar.xz
rpm -qpi <rpm_pkg> --changelog
rpm -qi <installed_pkg> --changelog
cat /root/rpmbuild/SOURCES/openssh-5.8p1-packet.patch | patch -p1 -b --suffix .packet --fuzz=0
```

## 4.3 rsync

```bash
# 将 test1 目录下的所有文件和目录复制进 test2, 如果 test1 后面没有跟 /, 则表示将 test1 目录复制进 test2
rsync -avuzc test1/* test2/
# 使 test1 与 test2 目录完全同步
rsync -avzc --delete test1/* test2/
```

## 4.4 du

```bash
# 查看目录内文件和子目录的大小并按照大小排序
du -sh ./* | sort -rh | head
```

## 4.5 置空 docker 容器日志

```bash
container_name_or_id="acs-admin-web" && cid=$(docker inspect --format='{{.Id}}' $container_name_or_id 2>/dev/null) && sudo truncate -s 0 /var/lib/docker/containers/$cid/$cid-json.log
```

以上
