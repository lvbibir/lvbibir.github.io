---
title: "suse 12sp5 升级 openssh 及 openssl" 
date: 2024-05-15
lastmod: 2024-06-13
tags:
  - suse
  - openssh
  - openssl
keywords:
  - suse
  - openssh
  - openssl
description: "以源码编译的方式, 将 suse12sp5 默认的 openssl 从 1.0.2j 升级到 1.1.1i, openssh 从 7.2p2 升级至 9.7p1."
cover:
    image: "https://image.lvbibir.cn/blog/logo-suse.png" 
---

```bash
# 上传 openssh 和 openssl 到 /opt
# https://www.openssl.org/source/openssl-1.1.1i.tar.gz
# https://mirrors.aliyun.com/pub/OpenBSD/OpenSSH/portable/openssh-9.7p1.tar.gz


# openssl
cd /opt/
tar zxf openssl-1.1.1i.tar.gz
mv /usr/bin/openssl{,-1.0.2j-fips}
mv /usr/include/openssl{,-1.0.2j-fips}
cd openssl-1.1.1i/
./config shared && make && make install
ln -s /usr/local/bin/openssl /usr/bin/openssl
ln -s /usr/local/include/openssl/ /usr/include/openssl
echo "/usr/local/lib64" >> /etc/ld.so.conf
/sbin/ldconfig
openssl version

# openssh
mv /etc/ssh{,-7.2p2}
cd /opt
tar zxf openssh-9.7p1.tar.gz
cd openssh-9.7p1/
./configure --prefix=/usr/local/openssh --sysconfdir=/etc/ssh --with-openssl-includes=/usr/local/include --with-ssl-dir=/usr/local/lib64 --with-zlib --with-md5-passwords
make
make install
sed -i 's/^#UseDNS.*/UseDNS no/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#X11Forwarding.*/X11Forwarding yes/' /etc/ssh/sshd_config
sed -i 's/^#X11UseLocalhost.*/X11UseLocalhost no/' /etc/ssh/sshd_config
sed -i 's%^#XAuthLocation.*%XAuthLocation /usr/bin/xauth%' /etc/ssh/sshd_config
mv /usr/sbin/sshd{,-7.2p2}
mv /usr/bin/ssh{,-7.2p2}
mv /usr/bin/ssh-keygen{,-7.2p2}
ln -s /usr/local/openssh/bin/ssh /usr/bin/ssh
ln -s /usr/local/openssh/bin/ssh-keygen /usr/bin/ssh-keygen
ln -s /usr/local/openssh/sbin/sshd /usr/sbin/sshd
mv /usr/lib/systemd/system/sshd.service{,-7.2p2}
cp -a contrib/suse/rc.sshd /etc/init.d/sshd
chmod +x /etc/init.d/sshd
chkconfig --add sshd
systemctl enable sshd --now
systemctl restart sshd
```

以上.
