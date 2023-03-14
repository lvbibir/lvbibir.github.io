---
title: "elasticsearch 安装插件报错 java.nio.file.NotDirectoryException" 
date: 2023-03-15
lastmod: 2023-03-15
tags: 
- linux
keywords:
- elastic
- elasticsearch
- elasticsearch-analysis-ik
description: "" 
cover:
    image: "" 
---

报错详细信息

```
Exception in thread "main" java.nio.file.NotDirectoryException: /usr/share/elasticsearch/plugins/plugin-descriptor.properties
        at java.base/sun.nio.fs.UnixFileSystemProvider.newDirectoryStream(UnixFileSystemProvider.java:439)
        at java.base/java.nio.file.Files.newDirectoryStream(Files.java:482)
        at java.base/java.nio.file.Files.list(Files.java:3793)
        at org.elasticsearch.tools.launchers.BootstrapJvmOptions.getPluginInfo(BootstrapJvmOptions.java:49)
        at org.elasticsearch.tools.launchers.BootstrapJvmOptions.bootstrapJvmOptions(BootstrapJvmOptions.java:34)
        at org.elasticsearch.tools.launchers.JvmOptionsParser.jvmOptions(JvmOptionsParser.java:137)
        at org.elasticsearch.tools.launchers.JvmOptionsParser.main(JvmOptionsParser.java:86)
```

安装插件时直接将插件的zip解压到了 plugins目录 导致的，每个插件应以目录的形式存放在 plugins目录 中

```
[root@21-centos-7 ~]# ls /data/elasticsearch/plugins/
commons-codec-1.9.jar
commons-logging-1.2.jar
config
elasticsearch-analysis-ik-7.17.3.jar
httpclient-4.5.2.jar
httpcore-4.4.4.jar
plugin-descriptor.properties
plugin-security.policy
```

只需要为每个插件创建一个目录，并把插件解压到对应目录即可

```
mkdir /data/elasticsearch/plugins/elasticsearch-analysis-ik/
unzip elasticsearch-analysis-ik-7.17.3.zip -d /data/elasticsearch/plugins/elasticsearch-analysis-ik/
```

参考: https://github.com/medcl/elasticsearch-analysis-ik/issues/638
