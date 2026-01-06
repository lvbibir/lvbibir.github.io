---
title: "麒麟 7.6 安装谷歌 OTP 认证模块" 
date: 2024-07-31
lastmod: 2024-07-31
tags:
  - keylinos
  - OTP
keywords:
  - keylinos
  - Google
  - OTP
description: ""
cover:
    image: "images/cover-default.webp"
---

# 0 前言

做等保三级项目安全集成建设，测评的时候有个高危不符合项叫做多因子认证（等保里面高危是一票否决项所以必须整改）。这一项要求在登录堡垒机的时候做多因子认证（短信、手机令牌、Ukey 等），在登录堡垒机后每台服务器登录时仍要进行一次多因子认证。但是因为一些原因本来这个事应该由主机安全实现登录，主机安全版本不够升级（华为云企业主机安全）就只能想办法自己折腾。最后还是查到了使用谷歌认证模块，可以实现 OTP 认证，这里就不解释什么是 HOTP 和 TOTP 了有需求的可以自己查原理。

采用 TOTP 方式进行认证也比较蛋疼，在实际的运维开发环境中，并非只有一人需要登录服务器进行操作（不然我要堡垒机干嘛），但是为了使用 OTP 认证，需要每个人都在手机上保留每台服务器的密钥，这不方便管理也不能保证密钥的安全性，如果是三方厂商提供的运维支持就更要命了。

再提醒一下，如果部署了堡垒机，堡垒机可能不支持在登陆的时候使用多因子，此时的解决方案是使用堡垒机登录内网运维主机，从运维主机上再使用 Xshell 等远程连接工具登录其它 Linux 服务器，此时再使用 OTP 认证。

安装过程很简单（yum 等摇轮椅式部署就不说了，以源码方式举例），只需要从 Github 上下载源码，上传到服务器，安装依赖进行编译、安装，配置 PAM 认证模块以及 sshd 配置文件，生成密钥，保存备份密钥，重启 sshd 服务即可。

# 1 安装

下面分步骤记录安装情况

安装环境：中标麒麟 V7.6

## 1.1 从 Github 上下载源码

<https://github.com/google/google-authenticator-libpam>

将源码下载为.zip 或者以你喜欢的方式下载，README 文档写的很详细，除了是英文以外没啥毛病

## 1.2 依赖安装 编译

因为我的环境是内网，连不上互联网的 yum 仓库，内网 yum 源还因为一些原因要关停一段时间所以是完全不能指望，所有缺少的依赖都需要自己下载，为了节省时间我也都下载好了打包到一起，如果有需要可以下载（不保证以后更高版本能用）

> 链接：<https://pan.quark.cn/s/09cc2553daa5>
>
> 提取码：q4Qd
>
> 压缩包密码 Thewind-rises.github.io

```bash
tar -zxf google-authenticator-rpms.tar.gz
cd google-authenticator-rpms.tar.gz
rpm -Uvh *.rpm --nodeps --force
```

我个人在安装的过程中遇到以下两个软件包安装过稍早的版本，使用 --replacefiles 参数可以替代

```bash
rpm -ivh perl-libs-5.16.3-297.el7.x86_64.rpm --replacefiles
rpm -ivh perl-5.16.3-297.el7.x86_64.rpm --replacefiles
```

至此如果没有报错，那么依赖应该就准备好了

```bash
unzip google-authenticator-libpam-master.zip
cd google-authenticator-libpam-master
./bootstrap.sh
make
make install
```

如果编译过程出错需要重新编译那么就在源代码根目录执行以下命令，然后去源代码压缩包把里面的 Makefile.am 重新上传，排完错以后再重新编译

```bash
rm -rf autom4te.cache
rm -rf aclocal.m4
rm -rf config.*
rm -rf configure
rm -rf Makefile*
```

如果没有报错那么执行 google-authenticator 应该会回显版本号等信息，看到就说明安装成功了。

## 1.3 配置

配置主要针对两文件：`/etc/pam.d/sshd` 和 `/etc/ssh/sshd_config`

/etc/pam.d/sshd

将以下内容放到第一行

```plaintext
auth required pam_google_authenticator.so nullok no_increment_hotp
```

其中 `nullok` 和 `no_increment_hotp` 这两个可选参数能够在 Github 上的 README 文件中找到解释

`nullok` 表明目前多因子登录是一个可选项，适用于密钥还没分发到所有人的时候，如果确认所有授权者都拿到了密钥应当将此删除

`no_increment_hotp` 建议配置，此选项可以不把 OTP 认证失败记作 SSH 登陆失败，避免有笨比情况发生（比方说我测试认证的时候头铁，OTP 硬是过不去，去查日志才发现安装后少了一个软连接文件，可能是系统原因）锁定账户

```bash
ln -s /usr/local/lib/security/pam_google_authenticator.so /usr/lib64/security/pam_google_authenticator.so
```

/etc/ssh/sshd_config 保证有以下两个条目

```plaintext
PubkeyAuthentication yes
ChallengeResponseAuthentication yes
```

保存并关闭

至此配置完成，你的系统在 sshd 服务重启之后应该就能正确使用两步认证登录了。

## 1.4 生成二次验证代码 以及如何启停

> 出处 <https://cloud.tencent.com/developer/article/1698883>

使用下面命令运行 Google Authenticator 设置程序：

```plaintext
google-authenticator -t -f -d -w 3 -e 10 -r 3 -R 30

选项说明：

-t : 使用 TOTP 验证
-f : 将配置保存到 ~/.google_authenticator
-d : 不允许重复使用以前使用的令牌
-w 3 : 允许的令牌的窗口大小。 默认情况下，令牌每 30 秒过期一次。 窗口大小 3 允许在当前令牌之前和之后使用令牌进行身份验证以进行时钟偏移。
-e 10 : 生成 10 个紧急备用代码
-r 3 -R 30 : 限速，每 30 秒允许 3 次登录
更多帮助信息可以使用 --help 选项查看。
```

程序运行后，将会更新配置文件，并且显示下面信息：

二维码，您可以使用大多数身份验证器应用程序扫描此代码。

一个密钥，如果您无法扫描二维码，请在您的应用中输入此密钥。

此时程序会提示让你输入初始验证码来测试，输入你用各类验证器获取到的一次性密码即可

完成测试后会给出 10 个一次性使用紧急代码的列表，请妥善保存，如果有所有人都登录不上的情况指不定可以用这个救急，但是注意每一个使用过的验证码都会失效。

如果需要仅对特定用户使用两次验证，那就 su 到对应用户并进入其 home 目录，执行生成代码操作即可，生成完毕后会在 home 目录生成.google_authenticator 文件，里面保存了该账户的 OTP 密钥以及紧急代码。

不需要使用两步验证时，只要删除.google_authenticator 即可，同时建议更改 PAM 配置文件，注释我们添加的内容。

以上.
