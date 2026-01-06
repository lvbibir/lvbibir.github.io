---
title: "mysql | 杂记" 
date: 2022-05-01
lastmod: 2025-04-24
tags:
  - mysql
keywords:
  - mysql
description: "" 
cover:
    image: "images/cover-mysql.png" 
---

# 0 下载地址

<https://dev.mysql.com/downloads/mysql/>

# 1 常用 Sql

## 1.1 查看用户权限

```sql
SELECT u.user, u.host, d.db, u.select_priv, u.insert_priv, u.update_priv, u.delete_priv, u.create_priv, u.drop_priv, u.grant_priv
FROM mysql.user u
LEFT JOIN mysql.db d ON u.user = d.user
ORDER BY u.user, u.host, d.db;
```

## 1.2 查看所有库的表数量

```sql
SELECT table_schema, COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_type = 'BASE TABLE'
GROUP BY table_schema;
```

## 1.3 加载的配置文件顺序

```bash
mysql --help |grep -i "my.cnf"
/etc/mysql/my.cnf /etc/my.cnf ~/.my.cnf
```

## 1.4 查看库的表数量及占用空间

```sql
select
table_schema as '数据库',
table_name as '表名',
table_rows as '记录数',
truncate(data_length/1024/1024, 2) as '数据容量(MB)',
truncate(index_length/1024/1024, 2) as '索引容量(MB)'
from information_schema.tables
where table_schema='xxxxxxxxxx'
order by data_length desc, index_length desc;
```

# 2 修改 binlog 保存时间

在 /etc/my.cnf 的 `[mysqld]` 下添加 `expire_logs_days = 30`

```sql
show variables like '%expire%';
set global expire_logs_days = 30;

# 删除 30 天前的 binlog
PURGE MASTER LOGS BEFORE DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY);
```

以上.
