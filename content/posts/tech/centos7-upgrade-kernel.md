---
title: "centos7 | 升级内核" 
date: 2026-01-28
lastmod: 2026-05-21
tags:
  - linux
  - centos
keywords:
  - linux
  - centos
  - kernel
description: "" 
cover:
    image: "images/cover-default.webp" 
---

# 0 前言

> ⚠️ **注意**：CentOS 7 已于 2024-06-30 EOL，ELRepo 已停止提供新内核。以下使用归档版本。

# 1 可用内核版本

| 类型                   | 最新版本    | 发布日期       |
| -------------------- | ------- | ---------- |
| **kernel-lt** (长期支持) | 5.4.278 | 2024-06-16 |
| **kernel-ml** (主线版)  | 6.9.7   | 2024-06-27 |

**推荐**：生产环境使用 `kernel-lt 5.4.278`（更稳定）

# 2 升级步骤

## 2.1 升级前准备

```bash
# 查看当前内核
uname -r

# 备份重要数据（建议创建快照）
```

## 2.2 下载内核 RPM

**方案 A：kernel-lt 5.4.278（推荐）**

```bash
cd /tmp

# 下载内核主包
wget http://mirrors.coreix.net/elrepo-archive-archive/kernel/el7/x86_64/RPMS/kernel-lt-5.4.278-1.el7.elrepo.x86_64.rpm

# 可选：下载开发包（编译内核模块需要）
wget http://mirrors.coreix.net/elrepo-archive-archive/kernel/el7/x86_64/RPMS/kernel-lt-devel-5.4.278-1.el7.elrepo.x86_64.rpm
```

**方案 B：kernel-ml 6.9.7（最新功能）**

```bash
cd /tmp

wget http://mirrors.coreix.net/elrepo-archive-archive/kernel/el7/x86_64/RPMS/kernel-ml-6.9.7-1.el7.elrepo.x86_64.rpm
wget http://mirrors.coreix.net/elrepo-archive-archive/kernel/el7/x86_64/RPMS/kernel-ml-devel-6.9.7-1.el7.elrepo.x86_64.rpm
```

## 2.3 安装内核

```bash
# 安装（以 kernel-lt 为例）
yum localinstall -y kernel-lt-5.4.278-1.el7.elrepo.x86_64.rpm

# 如需开发包
yum localinstall -y kernel-lt-devel-5.4.278-1.el7.elrepo.x86_64.rpm
```

## 2.4 设置默认启动

```bash
# 查看已安装内核
awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg

# 设置新内核为默认（0 = 第一个/最新）
grub2-set-default 0

# 生成 GRUB 配置
grub2-mkconfig -o /boot/grub2/grub.cfg
```

## 2.5 重启验证

```bash
reboot

# 重启后验证
uname -r
# 预期输出：5.4.278-1.el7.elrepo.x86_64
```

# 3 回滚方法

```bash
# 重启时在 GRUB 菜单选择旧内核
# 或设置旧内核为默认
grub2-set-default 1
grub2-mkconfig -o /boot/grub2/grub.cfg
reboot
```
