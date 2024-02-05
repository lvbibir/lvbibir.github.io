---
title: "shell | sshpass 批量传输文件及执行命令" 
date: 2024-02-01
lastmod: 2024-02-01
tags:
  - shell
  - docker
keywords:
  - shell
  - docker
  - harbor
description: "介绍一下使用 sshpass 通过读取配置文件的方式批量下发文件和执行命令" 
cover:
    image: "https://image.lvbibir.cn/blog/shell.png" 
---

```shell
#!/bin/bash

username="root"
password="123123"
port="22"

# 判断ip检查文件是否存在
if [ ! -f "./ip_check.txt" ]; then
  # 清空检查文件
  /usr/bin/true >./ip_check.txt
else
  # 创建检查文件
  /usr/bin/touch ./ip_check.txt
fi

# 传输文件
execut_ftp_file() {
  IFS=$'\n'
  for file in $(cat ./ftp_file.conf); do
    /opt/sshpass/bin/sshpass -p $password scp -o StrictHostKeyChecking=no ./$file $username@$1:/opt/
    echo "$1 ---- $file 文件传输完成"
  done
}

execut_commad_file() {
  IFS=$'\n'
  for com in $(cat ./execut_commad.conf); do
    /opt/sshpass/bin/sshpass -p $password ssh -o StrictHostKeyChecking=no $username@$1 $com
    echo "$1 ---------- $com 命令执行完成"
    sleep 3
  done
}

for line in $(cat ./ip.txt); do
  Ture_ip=$(/usr/bin/ping -c 2 $line)
  if [ $? != "0" ]; then
    echo "$line is blocked" >>./ip_check.txt
  else
    execut_ftp_file $line
    sleep 2
    execut_commad_file $line
  fi

done
```
