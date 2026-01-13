---
title: "Linux cat 和 tee 命令写入文件"
date: 2026-01-13
lastmod: 2026-01-13
tags:
  - linux
keywords:
  - linux
  - cat
  - tee
description: "详细介绍 Linux 中使用 cat 和 tee 命令写入文件的各种方式, 包括 heredoc 语法、EOF 引号和连字符的作用"
cover:
    image: "/images/cover-linux.png"
---

# 0 前言

在 Linux 系统中, cat 和 tee 命令是处理文件内容的常用工具. 本文详细介绍这两个命令写入文件的各种方式, 特别是 heredoc 语法中 EOF 引号和连字符的作用.

# 1 cat 命令写入文件

cat 命令可以通过重定向操作符将内容写入文件:

```bash
# 覆盖写入
cat > filename

# 追加写入
cat >> filename
```

# 2 tee 命令写入文件

tee 命令可以同时将输出写入文件和显示在终端:

```bash
# 覆盖写入
echo "内容" | tee filename

# 追加写入
echo "内容" | tee -a filename
```

# 3 heredoc 语法详解

heredoc (Here Document) 是一种在 shell 中处理多行文本的强大语法, 可以与 cat 和 tee 命令结合使用.

## 3.1 基本用法

```bash
# 与 cat 结合
cat > file.txt << EOF
这是第一行内容
变量值: $USER
EOF

# 与 tee 结合
tee filename << EOF
这是多行内容
会同时显示在终端和写入文件
EOF
```

## 3.2 EOF 引号的作用

**不加引号 (默认)**: 变量和命令会被展开

```bash
name="张三"
cat << EOF
用户名: $name
当前目录: $PWD
EOF
```

**加引号 (单引号或双引号)**: 禁止变量展开, 按字面意思输出

```bash
cat << 'EOF'
用户名: $name
当前目录: $PWD
EOF
```

## 3.3 EOF 连字符 (-) 的作用

连字符 `-` 会**移除 heredoc 内容行首的制表符 (tab)**:

```bash
# 不使用连字符 - tab 会保留
cat << EOF
	这行前面有 tab
EOF

# 使用连字符 - tab 会被移除
cat <<- EOF
	这行前面有 tab, 会被移除
EOF
```

**注意**: 只移除制表符 (tab), 不移除空格, 且必须是真正的 tab 字符

# 4 实际应用场景

## 4.1 创建包含特殊字符的配置文件

```bash
# 创建包含 $ 符号的配置文件 (使用引号防止变量展开)
cat > app.conf << 'EOF'
database_url = "mysql://user:$password@localhost/db"
api_key = "$API_SECRET_KEY"
log_format = "${timestamp} ${level} ${message}"
EOF
```

## 4.2 在函数中生成配置文件

```bash
# 在函数中使用 heredoc (连字符保持代码可读性)
create_nginx_config() {
    local domain=$1
    local port=$2

    if [ -n "$domain" ]; then
        cat > "/etc/nginx/sites-available/$domain" <<- EOF
		server {
		    listen $port;
		    server_name $domain;
		    root /var/www/$domain;

		    location / {
		        try_files \$uri \$uri/ =404;
		    }
		}
	EOF
        echo "配置文件已创建: $domain"
    else
        echo "错误: 域名不能为空"
    fi
}

# 调用函数
create_nginx_config "example.com" 80
```

## 4.3 使用 tee 记录部署日志

```bash
# 同时显示在终端和写入日志文件
tee -a deploy.log << EOF
=== 部署开始 ===
时间: $(date '+%Y-%m-%d %H:%M:%S')
用户: $USER
分支: $(git branch --show-current)
提交: $(git rev-parse --short HEAD)
=== 部署结束 ===
EOF
```

## 4.4 批量创建文件

```bash
# 使用循环和 heredoc 批量创建配置文件
for env in dev test prod; do
    cat > "config-${env}.yml" << EOF
environment: $env
database:
  host: db-${env}.example.com
  port: 5432
redis:
  host: redis-${env}.example.com
EOF
done
```

# 5 最佳实践

- **简单内容**: 使用 `echo` 重定向
- **多行内容**: 使用 heredoc
- **同时显示和保存**: 使用 tee
- **包含特殊字符**: 使用引号包围 EOF
- **避免变量注入**: 配置文件使用引号包围 EOF
- **代码可读性**: 使用有意义的分隔符名称 (如 `DOCKER_COMPOSE` 而不是 `EOF`)

这些技巧能帮你更高效地在 Linux 系统中处理文件内容, 选择最适合场景的方法是关键 ฅ'ω'ฅ
