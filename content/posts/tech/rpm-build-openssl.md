---
title: "openssl源码打包编译成rpm包" 
date: 2022-03-01
lastmod: 2022-03-01
tags: 
- linux
keywords:
- linux
- rpm
- openssh
- 源码
- rpm构建
description: "记录一下centos7系统中通过源码构建openssh rpm包的过程" 
cover:
    image: "" 
---
# 环境

iSoftserver-v4.2(Centos-7)

openssl version：1.0.2k

# 编译

从github上看到的编译脚本，本地修改后：

```bash
#!/bin/bash
set -e
set -v
mkdir ~/openssl && cd ~/openssl
yum -y install \
    curl \
    which \
    make \
    gcc \
    perl \
    perl-WWW-Curl \
    rpm-build
# Get openssl tarball
cp /root/openssl-1.1.1m.tar.gz ./

# SPEC file
cat << 'EOF' > ~/openssl/openssl.spec
Summary: OpenSSL 1.1.1m for Centos
Name: openssl
Version: %{?version}%{!?version:1.1.1m}
Release: 1%{?dist}
Obsoletes: %{name} <= %{version}
Provides: %{name} = %{version}
URL: https://www.openssl.org/
License: GPLv2+

Source: https://www.openssl.org/source/%{name}-%{version}.tar.gz

BuildRequires: make gcc perl perl-WWW-Curl
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
%global openssldir /usr/openssl

%description
OpenSSL RPM for version 1.1.1m on Centos

%package devel
Summary: Development files for programs which will use the openssl library
Group: Development/Libraries
Requires: %{name} = %{version}-%{release}

%description devel
OpenSSL RPM for version 1.1.1m on Centos (development package)

%prep
%setup -q

%build
./config --prefix=%{openssldir} --openssldir=%{openssldir}
make

%install
[ "%{buildroot}" != "/" ] && %{__rm} -rf %{buildroot}
%make_install

mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_libdir}
ln -sf %{openssldir}/lib/libssl.so.1.1 %{buildroot}%{_libdir}
ln -sf %{openssldir}/lib/libcrypto.so.1.1 %{buildroot}%{_libdir}
ln -sf %{openssldir}/bin/openssl %{buildroot}%{_bindir}

%clean
[ "%{buildroot}" != "/" ] && %{__rm} -rf %{buildroot}

%files
%{openssldir}
%defattr(-,root,root)
/usr/bin/openssl
/usr/lib64/libcrypto.so.1.1
/usr/lib64/libssl.so.1.1

%files devel
%{openssldir}/include/*
%defattr(-,root,root)

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig
EOF


mkdir -p /root/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
cp ~/openssl/openssl.spec /root/rpmbuild/SPECS/openssl.spec

mv openssl-1.1.1m.tar.gz /root/rpmbuild/SOURCES
cd /root/rpmbuild/SPECS && \
    rpmbuild \
    -D "version 1.1.1m" \
    -ba openssl.spec

# Before Uninstall  Openssl :   rpm -qa openssl
# Uninstall Current Openssl Vesion : yum -y remove openssl
# For install:  rpm -ivvh /root/rpmbuild/RPMS/x86_64/openssl-1.1.1m-1.el7.x86_64.rpm --nodeps
# Verify install:  rpm -qa openssl
#                  openssl version
```

运行脚本

```
chmod 755 install_openssl-1.1.1m.sh
./isntall_openssl-1.1.1m.sh
tree rpmbuild/*RPMS
```

![image-20220302154139155](https://image.lvbibir.cn/blog/image-20220302154139155.png)

# 升级

```
rpm -e openssl --nodeps
rpm -ivh  openssl-1.1.1m-1.el7.isoft.x86_64.rpm --nodeps
openssl version
```

![image-20220302154321811](https://image.lvbibir.cn/blog/image-20220302154321811.png)





