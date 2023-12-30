---
title: "shell | centos 初始化" 
date: 2023-08-01
lastmod: 2022-08-01
tags: 
- shell
- centos
keywords:
- shell
- centos
description: "" 
cover:
    image: "https://image.lvbibir.cn/blog/shell.png" 
---
# 前言

以 centos7 为例, 通常我们新装完操作系统后需要进行配置 yum 源, iptables, selinux, ntp 以及优化 kernel 等操作, 现分享一些较为通用的配置. 同时博主将这些配置整理成了脚本, 可以一键执行.

# 常用配置

## iptables & selinux

```bash
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
setenforce 0

iptables -F
systemctl disable --now firewalld
```

## PS1 终端美化

```bash
cat > /etc/profile.d/PS1_conf.sh << 'EOF'
export PS1="\n[\[\e[31m\]\u\[\e[m\]@\[\e[32m\]\h\[\e[m\]] -\$?- \[\e[33m\]\$(pwd)\[\e[m\] \[\e[34m\]\$(date +'%F %T')\[\e[m\] \n(\#)$ "
EOF

source /etc/profile.d/PS1_conf.sh
```

## history 格式化

```bash
cat > /etc/profile.d/history_conf.sh << 'EOF'
export HISTFILE="$HOME/.bash_history"  # 写入文件
export HISTSIZE=1000  # history输出记录数
export HISTFILESIZE=10000  # HISTFILE文件记录数
export HISTIGNORE="cmd1:cmd2:..."  # 忽略指定cmd1,cmd2...的命令不被记录到文件；(加参数时会记录)
export HISTCONTOL=ignoredups   # ignoredups 不记录“重复”的命令；连续且相同 方为“重复” 
export PROMPT_COMMAND="history -a"  # 设置每条命令执行完立即写入HISTFILE(默认等待退出会话写入)
export HISTTIMEFORMAT="$(whoami) %F %T "  # 设置命令执行时间格式，记录文件增加时间戳
shopt -s histappend  # 防止会话退出时覆盖其他会话写到HISTFILE的内容
EOF

source /etc/profile.d/history_conf.sh
```

## ssh 公钥

```bash
mkdir /root/.ssh || true
chmod 700 /root/.ssh
cat > /root/.ssh/authorized_keys << 'EOF'
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCeQZmPg93SNx6zzR/l4RiPnHtFPbDTSOL7AtJOIvrlMm300x1OM8a48VqYuKEx7B7WM7UhszVndg8efJv9UdOtOaa0o8L0Wd2uujn2rFKKok69c5i7c/jmU1my9MkEsKpkx1MHQWVZTFqayv/DB9L5GaE/ShChsTSlXoQ6rc6JC4k1zgSsoNSTLwPrbZcDOZWprt/AOhqCklf9mL1E50WTx9XsjxBLqJIwwVEzmHAhzIiVowjBKjJpQ6hEvygCz67gNVn0vAvHPvCz3amrkCQa333Z9r8tbY7mJpq2Anj4qWtlnL9kHreVK6YoKGvM8+DrbVoT5/zM7wMZ+tdLmreUsu4OhgDkE4IgUMHWQ3T1GyD1EjCkqCdSfJbrLaAR8v7g92uDXO5irIyYMc/iQJ8v4okus9Iid61zFF0SPgZEykOVfT7jJqH0a/630D41uD0TK90v5PicVdh1FfEfok8P4F4UHGLUly2jRVBESQ/TXVGPaMITHPEtYEpmT3kmnOk= 15810243114@163.com
EOF

chmod 600 /root/.ssh/authorized_keys
```

## 加速 ssh 连接

```bash
echo "UseDNS no" >> /etc/ssh/sshd_config
```

## 配置 yum 源

以实测最快的清华源为例

```bash
mkdir /etc/yum.repos.d/bak || true
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak/ || true

cat > /etc/yum.repos.d/centos-tuna.repo << 'EOF'
[base]
name=CentOS-$releasever - Base
baseurl=http://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/os/$basearch/
gpgcheck=0

[updates]
name=CentOS-$releasever - Updates
baseurl=http://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/updates/$basearch/
gpgcheck=0

[extras]
name=CentOS-$releasever - Extras
baseurl=http://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/extras/$basearch/
gpgcheck=0

EOF

yum clean all
yum makecache fast
yum install -y wget net-tools vim bash-completion ntpdate
```

## 时间配置

```bash
timedatectl set-timezone Asia/Shanghai
ntpdate time.windows.com
```

## limit

```bash
cat >> /etc/security/limits.conf << 'EOF'
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
EOF
```

## proxy

```bash
cat > /root/proxy << 'EOF'
#!/bin/bash
case "$1" in
set)
    export http_proxy="http://1.1.1.1:7890"
    export https_proxy="http://1.1.1.1:7890"
	export all_proxy="socks5://1.1.1.1:7890"
	export ALL_PROXY="socks5://1.1.1.1:7890"
	;;
unset)
    unset http_proxy
    unset https_proxy
	unset all_proxy
	unset ALL_PROXY
    ;;
*)
    echo "Usage: source $0 {set|unset}"
    ;;
esac
EOF
```

## kernel

```bash
cat >> /etc/sysctl.d/99-sysctl.conf << 'EOF'
# 关闭ipv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

# 避免放大攻击
net.ipv4.icmp_echo_ignore_broadcasts = 1

# 开启恶意icmp错误消息保护
net.ipv4.icmp_ignore_bogus_error_responses = 1

# 开启反向路径过滤
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# 关闭sysrq功能
kernel.sysrq = 0

# core文件名中添加pid作为扩展名
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1

# 修改消息队列长度
kernel.msgmnb = 65536
kernel.msgmax = 65536

# 设置最大内存共享段大小bytes
kernel.shmmax = 68719476736
kernel.shmall = 4294967296

# timewait的数量，默认180000
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096        87380   4194304
net.ipv4.tcp_wmem = 4096        16384   4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144

# 限制仅仅是为了防止简单的DoS 攻击
net.ipv4.tcp_max_orphans = 3276800

# 收到客户端确认信息的连接请求的最大值
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0

# 内核放弃建立连接之前发送SYNACK 包的数量
net.ipv4.tcp_synack_retries = 1

# 内核放弃建立连接之前发送SYN 包的数量
net.ipv4.tcp_syn_retries = 1

# 启用timewait 快速回收
net.ipv4.tcp_tw_recycle = 1

# 开启重用。允许将TIME-WAIT sockets 重新用于新的TCP连接
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1

# 当keepalive 起用的时候，TCP 发送keepalive 消息的频度。缺省是2 小时
net.ipv4.tcp_keepalive_time = 30

# 修改防火墙表大小，默认65536
#net.netfilter.nf_conntrack_max=655350
#net.netfilter.nf_conntrack_tcp_timeout_established=1200

EOF

sysctl -p
```

# 一键脚本

```bash
#!/bin/bash

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "当前用户不是管理员。请使用管理员权限运行此脚本。"
    exit 1
fi

echo "========start============="

function disable_selinux_firewalld() {

    echo "========selinux==========="
    sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
    setenforce 0
    
    echo "========firewalld========="
    iptables -F
    systemctl disable --now firewalld

}

function format_history() {

    echo "========history format========"
    cat > /etc/profile.d/history_conf.sh << 'EOF'
export HISTFILE="$HOME/.bash_history"  # 写入文件
export HISTSIZE=1000  # history输出记录数
export HISTFILESIZE=10000  # HISTFILE文件记录数
export HISTIGNORE="cmd1:cmd2:..."  # 忽略指定cmd1,cmd2...的命令不被记录到文件；(加参数时会记录)
export HISTCONTOL=ignoredups   # ignoredups 不记录“重复”的命令；连续且相同 方为“重复” 
export PROMPT_COMMAND="history -a"  # 设置每条命令执行完立即写入HISTFILE(默认等待退出会话写入)
export HISTTIMEFORMAT="$(whoami) %F %T "  # 设置命令执行时间格式，记录文件增加时间戳
shopt -s histappend  # 防止会话退出时覆盖其他会话写到HISTFILE的内容
EOF

    source /etc/profile.d/history_conf.sh

}

function setup_ssh() {

    echo "========add ssh key========"
    mkdir /root/.ssh || true
    chmod 700 /root/.ssh
    cat > /root/.ssh/authorized_keys << 'EOF'
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCeQZmPg93SNx6zzR/l4RiPnHtFPbDTSOL7AtJOIvrlMm300x1OM8a48VqYuKEx7B7WM7UhszVndg8efJv9UdOtOaa0o8L0Wd2uujn2rFKKok69c5i7c/jmU1my9MkEsKpkx1MHQWVZTFqayv/DB9L5GaE/ShChsTSlXoQ6rc6JC4k1zgSsoNSTLwPrbZcDOZWprt/AOhqCklf9mL1E50WTx9XsjxBLqJIwwVEzmHAhzIiVowjBKjJpQ6hEvygCz67gNVn0vAvHPvCz3amrkCQa333Z9r8tbY7mJpq2Anj4qWtlnL9kHreVK6YoKGvM8+DrbVoT5/zM7wMZ+tdLmreUsu4OhgDkE4IgUMHWQ3T1GyD1EjCkqCdSfJbrLaAR8v7g92uDXO5irIyYMc/iQJ8v4okus9Iid61zFF0SPgZEykOVfT7jJqH0a/630D41uD0TK90v5PicVdh1FfEfok8P4F4UHGLUly2jRVBESQ/TXVGPaMITHPEtYEpmT3kmnOk= 15810243114@163.com
EOF
    chmod 600 /root/.ssh/authorized_keys

	echo "=========setup ssh========"
	echo "UseDNS no" >> /etc/ssh/sshd_config

}

function setup_yum() {

    echo "====backup repo==========="
    mkdir /etc/yum.repos.d/bak || true
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak/ || true

    echo "====configure tuna repo===="
    cat > /etc/yum.repos.d/centos-tuna.repo << 'EOF'
[base]
name=CentOS-$releasever - Base
baseurl=http://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/os/$basearch/
gpgcheck=0

[updates]
name=CentOS-$releasever - Updates
baseurl=http://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/updates/$basearch/
gpgcheck=0

[extras]
name=CentOS-$releasever - Extras
baseurl=http://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/extras/$basearch/
gpgcheck=0

EOF

    echo "====upgrade yum============"
    yum clean all
    yum makecache fast

    echo "====dowload tools========="
    yum install -y wget net-tools vim bash-completion ntpdate

}

function time_limit_proxy() {

    echo "=======setup timezone and ntp======"
    timedatectl set-timezone Asia/Shanghai
    ntpdate time.windows.com
    
    echo "=======modify limit========="
    cat >> /etc/security/limits.conf << 'EOF'
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
EOF

    echo "========http proxy=========="
    cat > /root/proxy << 'EOF'
#!/bin/bash
case "$1" in
set)
    export http_proxy="http://1.1.1.1:7890"
    export https_proxy="http://1.1.1.1:7890"
	export all_proxy="socks5://1.1.1.1:7890"
	export ALL_PROXY="socks5://1.1.1.1:7890"
	;;
unset)
    unset http_proxy
    unset https_proxy
	unset all_proxy
	unset ALL_PROXY
    ;;
*)
    echo "Usage: source $0 {set|unset}"
    ;;
esac
EOF

}

function setup_kernel() {

    echo "========Optimize kernel========"
    cat >> /etc/sysctl.d/99-sysctl.conf << 'EOF'
# 关闭ipv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

# 避免放大攻击
net.ipv4.icmp_echo_ignore_broadcasts = 1

# 开启恶意icmp错误消息保护
net.ipv4.icmp_ignore_bogus_error_responses = 1

# 开启反向路径过滤
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# 关闭sysrq功能
kernel.sysrq = 0

# core文件名中添加pid作为扩展名
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1

# 修改消息队列长度
kernel.msgmnb = 65536
kernel.msgmax = 65536

# 设置最大内存共享段大小bytes
kernel.shmmax = 68719476736
kernel.shmall = 4294967296

# timewait的数量，默认180000
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096        87380   4194304
net.ipv4.tcp_wmem = 4096        16384   4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144

# 限制仅仅是为了防止简单的DoS 攻击
net.ipv4.tcp_max_orphans = 3276800

# 收到客户端确认信息的连接请求的最大值
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0

# 内核放弃建立连接之前发送SYNACK 包的数量
net.ipv4.tcp_synack_retries = 1

# 内核放弃建立连接之前发送SYN 包的数量
net.ipv4.tcp_syn_retries = 1

# 启用timewait 快速回收
net.ipv4.tcp_tw_recycle = 1

# 开启重用。允许将TIME-WAIT sockets 重新用于新的TCP连接
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1

# 当keepalive 起用的时候，TCP 发送keepalive 消息的频度。缺省是2 小时
net.ipv4.tcp_keepalive_time = 30

# 修改防火墙表大小，默认65536
#net.netfilter.nf_conntrack_max=655350
#net.netfilter.nf_conntrack_tcp_timeout_established=1200

EOF

    sysctl -p

}

disable_selinux_firewalld
format_history
setup_ssh
setup_yum
time_limit_proxy
setup_kernel

echo "=========finish============"

exit 0
```

