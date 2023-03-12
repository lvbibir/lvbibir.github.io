---
title: "pxe 如何应对复杂的服务器硬件环境" 
date: 2022-08-18
lastmod: 2022-08-18
tags: 
- linux
keywords:
- linux
- pxe
- aarch64
- dhcp
description: "本文主要探讨如何配置dhcp来使pxe可以应对复杂的服务器环境" 
cover:
    image: "" 
---

# 前言

在 pxe 的一般场景下，通常在只需要在 dhcp 服务中配置一个通用的 `filename` 来指定客户端在 `tftp` 服务端获取的引导程序，但是在略微复杂的场景中，比如可能有些服务器默认是 `legacy` 模式，而有些服务器是 `UEFI` 模式，这两种模式使用的引导程序是不同的，但我们又不想频繁的去修改 dhcp 配置文件。本文主要探讨的就是这个问题，如何配置 dhcp 来应对复杂的服务器环境

难点主要有两个，一个是区分某些 dhcp 客户端是否需要 pxe 引导程序，另外一个是如何区分不同的模式和架构来去分配对应的 pxe 引导程序

# RFC

Request For Comments（RFC），是一系列以编号排定的文件。文件收集了有关互联网相关信息，以及UNIX和[互联网](https://baike.baidu.com/item/互联网/199186)社区的[软件](https://baike.baidu.com/item/软件/12053)文件。RFC文件是由Internet Society（ISOC）赞助发行。基本的互联网通信协议都有在RFC文件内详细说明。RFC文件还额外加入许多在标准内的论题，例如对于互联网新开发的协议及发展中所有的记录。因此几乎所有的互联网标准都有收录在RFC文件之中。

# dhcp option 60

`DHCP Option 60 Vendor class identifier`为厂商类标识符。这个选项作用于客户端可选地识别客户端厂商类型和配置。这个信息是N个8位编码，由DHCP服务端解析。厂商可能会为客户端选择定义特殊的厂商类标识符信息，以便表达特殊的配置或者其他关于客户端的信息。比如：这个标识符可能编码了客户端的硬件配置。客户端发送过来的服务器不能解析的类规范信息必须被忽略（尽管可能会有报告）。

# dhcp option 93

`dhcp-options` 的 man 手册中有提到对于架构类型在 [RFC 4578](https://www.rfc-editor.org/rfc/rfc4578.html) 中有一套标准，可通过 if 语句判断 dhcp 客户端的Arch代码来提供不同的PXE引导程序给客户端

```
# man dhcp-options

option pxe-system-type uint16 [, uint16 ... ];
         A list of one ore more 16-bit integers which allows a client to specify its pre-boot architecture type(s).
         This option is included based on RFC 4578.
```

下述为 RFC 4578 标准中对 arch 代码制定的标准，`name` 字段包含启动模式和 cpu 架构信息（自己的猜测，这里没找到对于 name 更详细的解释）

```
Type   Architecture Name
            ----   -----------------
              0    Intel x86PC
              1    NEC/PC98
              2    EFI Itanium
              3    DEC Alpha
              4    Arc x86
              5    Intel Lean Client
              6    EFI IA32
              7    EFI BC
              8    EFI Xscale
              9    EFI x86-64
```

# 抓包获取arch代码

通过前文描述，我们得知 arch 代码主要是由硬件厂商定义好的，配置好 pxe 服务，arch 代码的获取至关重要，去咨询硬件厂商效率太慢，这里通过更为方便的抓包获取

> 抓包主要获取提供 dhcp 服务的网卡的数据包，需服务端开启 dhcp 服务，客户端通过网卡启动
>
> windows端通过 `wireshark` 来完成
>
> linux服务端使用 `tcpdump -i <interface> -w <file>` 生成到文件然后用 wireshark 分析

以下提供几个 `dhcp option 60` 和  `dhcp option 93` 报文示例：

- AMD Ryzen 7 4800U with Radeon Graphics (x86)

- vmware workstation v16 平台
- ` UEFI` 模式下

这里获取到的 arch 代码为 7

![image-20220818170219859](https://image.lvbibir.cn/blog/image-20220818170219859.png)

- AMD Ryzen 7 4800U with Radeon Graphics (x86)

- vmware workstation v16 平台
- ` legacy` 模式下

这里获取到的 arch 代码为 0

![image-20220818171359788](https://image.lvbibir.cn/blog/image-20220818171359788.png)

- kunpeng 920 （aarch64）

- kvm 平台
- ` UEFI` 模式下

这里获取到的 arch 代码为 11

![image-20220818172222043](https://image.lvbibir.cn/blog/image-20220818172222043.png)

以上抓包都是在网络引导的环境下进行的，在使用已安装操作系统中的网卡去发送 dhcp 请求时，整个数据包传输过程都没有 `option 60` 和 `option 93`  这两个选项的参与，我猜测这两个选项只有在网络引导的环境下才会去参与

# dhcp 配置文件示例

在上述论证基础之上，我们就可以通过配置 dhcp 服务来使 pxe 足以应对复杂的网络环境和硬件环境

解决前言中提到的两个难点分别通过 `option 60` 和 `option 93` 分别解决

```
# 这里应该是将 option 93 的值格式化成 16 进制，用于下面的 if 判断（猜测）
option arch code 93 = unsigned integer 16;
class "pxeclients" {
    # 这里判断 option 60 选项的值的前9个字符是否是 PXEClient
    match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
    next-server 10.17.25.17;
    # 这里通过 if 判断 arch 代码来决定如何去分配对应的 pxe 引导程序
    if option arch = 00:07 {
      filename "/BOOTX64.efi";
    } else if option arch = 00:09 {
      filename "/BOOTX64.efi";
    } else {
      filename "/pxelinux.0";
    }
    }
```

较为详细的配置文件示例，后面有简化版

```
# 启用 PXE 支持
allow booting;
allow bootp;

# PXE 定义命名空间
option space PXE;
option PXE.mtftp-ip  code 1 = ip-address;
option PXE.mtftp-cport code 2 = unsigned integer 16;
option PXE.mtftp-sport code 3 = unsigned integer 16;
option PXE.mtftp-tmout code 4 = unsigned integer 8;
option PXE.mtftp-delay code 5 = unsigned integer 8;
option arch code 93 = unsigned integer 16; # RFC4578

authoritative;
one-lease-per-client true;
# 不使用DNS动态更新
ddns-update-style none;
# 忽略客户端DNS更新
ignore client-updates;

# 不使用 PXE 的网络
shared-network main {
subnet 10.17.25.0 netmask 255.255.255.0 {
  option routers 10.17.25.254;
  option subnet-mask 255.255.255.0;
  option domain-name "zhijie-liu.com";
  # 在此网络关闭PXE支持
  deny bootp;
  pool {
    range 10.17.25.200 10.17.25.210;
    host nagios-test {
    hardware ethernet 00:0d:56:66:82:c3;
    fixed-address 10.17.25.200;
    }
  }
}
}

# 使用 PXE 的网络
shared-network pxe {
subnet 10.17.15.0 netmask 255.255.255.0 {
  option routers 10.17.15.254;
  option subnet-mask 255.255.255.0;
  option domain-name "xiyang-liu.com";
  option domain-name-servers 10.17.26.88, 8.8.8.8;
  default-lease-time 86400;
  max-lease-time 172800;
  pool {
    range 10.17.15.1 10.17.15.20;
    class "pxeclient" {
    match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
    next-server 10.17.25.17;
    if option arch = 00:07 {
      filename "/BOOTX64.efi";
    } else if option arch = 00:09 {
      filename "/BOOTX64.efi";
    } else {
      filename "/pxelinux.0";
    }
    }
  # 根据 MAC 地址单独分配地址和指定的 PXE 引导程序
  host gpxelinux {
    option host-name "gpxelinux.zhijie-liu.com";
    hardware ethernet 00:50:56:24:0B:30;
    fixed-address 10.17.15.8;
    filename "/gpxelinux.0"
    }
  }
}
}
```

简化版（仅kvm平台测试通过）

```
option domain-name "example.org";
option domain-name-servers 8.8.8.8, 114.114.114.114;
default-lease-time 84600;
max-lease-time 100000;
log-facility local7;

option arch code 93 = unsigned integer 16;

subnet 1.1.1.0 netmask 255.255.255.0 {
  range 1.1.1.100 1.1.1.200;
  option routers 1.1.1.253;
  class "pxeclients" {
    match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
    next-server 1.1.1.21;
    if option arch = 00:11 {
      filename "/grubaa64.efi";
    }
  }
}
```

# 参考

https://blog.csdn.net/u012145252/article/details/125405273

https://www.cnblogs.com/boowii/p/6475921.html

https://www.rfc-editor.org/rfc/rfc4578.html