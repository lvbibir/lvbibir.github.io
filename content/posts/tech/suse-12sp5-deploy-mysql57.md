---
title: "suse 12sp5 部署 mysql 5.7" 
date: 2024-05-15
lastmod: 2024-05-15
tags:
  - suse
  - mysql
keywords:
  - suse
  - mysql
description: "" 
cover:
    image: "images/logo-suse.png" 
---

# 0 前言

系统使用 Gnome 环境

# 1 安装

安装依赖

```bash
zypper in libatomic1
zypper in perl-JSON
```

下载 mysql 安装包, [链接](https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.44-1.sles12.x86_64.rpm-bundle.tar)

```bash
tar xf mysql-5.7.44-1.sles12.x86_64.rpm-bundle.tar
rpm -ivh mysql-community-common-5.7.44-1.sles12.x86_64.rpm
rpm -ivh mysql-community-libs-5.7.44-1.sles12.x86_64.rpm
rpm -ivh mysql-community-client-5.7.44-1.sles12.x86_64.rpm
rpm -ivh mysql-community-server-5.7.44-1.sles12.x86_64.rpm
mkdir -p /data/mysql/{data,tmp}
chown -R mysql /data/mysql
mysqld --initialize --datadir=/data/mysql/data/ --user=mysql
```

修改 /etc/my.cnf 配置文件

```plaintext
[client]
port = 3306
socket = /data/mysql/mysql.sock
default-character-set=utf8

[mysqld]
port = 3306
skip-grant-tables
datadir = /data/mysql/data
tmpdir = /data/mysql/tmp
socket = /data/mysql/mysql.sock
character-set-server = utf8
collation-server = utf8_general_ci
pid-file = /data/mysql/mysql.pid
user = mysql
explicit_defaults_for_timestamp
lower_case_table_names = 1
max_connections = 1000
back_log = 1024
open_files_limit = 10240
table_open_cache = 5120
skip-external-locking
local-infile = 1
key_buffer_size = 32M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M


log-bin = /data/mysql/mysql-bin
binlog_format = mixed
server-id = 1

innodb_data_file_path = ibdata1:10M:autoextend
innodb_buffer_pool_size = 256M
innodb_buffer_pool_instances = 2
innodb_read_io_threads = 8
innodb_write_io_threads = 8
innodb_purge_threads = 1

slow_query_log = 1
long_query_time = 10
log-queries-not-using-indexes

log-error = /data/mysql/mysql.err

expire-logs-days = 10

[mysqldump]
quick
max_allowed_packet = 512M
net_buffer_length = 16384

[mysql]
auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
```

# 2 配置

首次启动并修改密码

```sql
systemctl start mysql
mysql -uroot -p 

use mysql;
update user set authentication_string = password('D`N~Wv`%=XJeX'), password_expired = 'N', password_last_changed = now() where user = 'root';
```

修改完密码后注释掉 /etc/my.cnf 中的 `skip-grant-tables` 并重启 mysql

```bash
systemctl restart mysql
```

设置远程访问

```sql
mysql -uroot -p

use mysql;
grant all PRIVILEGES on *.* to root@'%' identified by 'D`N~Wv`%=XJeX';
flush privileges;
```

以上.
