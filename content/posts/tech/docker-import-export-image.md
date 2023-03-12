---
title: "docker | 脚本方式批量导出/导入镜像" 
date: 2022-02-01
lastmod: 2021-02-01
tags: 
- docker
- python
- shell
keywords:
- linux
- docker
- python
- shell
description: "通过shell | python的方式批量导入导出docker镜像" 
cover:
    image: "https://image.lvbibir.cn/blog/docker.png" 
---
# python方式

批量导出，运行后所有tar包都在当前目录下

```python
# encoding: utf-8

import re
import os
import subprocess

if __name__ == "__main__":
    p = subprocess.Popen('docker images', shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    for line in p.stdout.readlines():

        # 此处的正则表达式是为了匹配镜像名以kolla为开头的镜像
        # 实际使用中根据需要自行调整
        m = re.match(r'(^kolla[^\s]*\s*)\s([^\s]*\s)', line)

        if not m:
            continue

        # 镜像名
        iname = m.group(1).strip()
        # tag
        itag = m.group(2).strip()
        # tar包的名字
        if iname.find('/'):
            tarname = iname.split('/')[0] + '_' + iname.split('/')[-1]  + '_' + itag + '.tar'
        else:
            tarname = iname + '_' + itag + '.tar'
        print tarname
        ifull = iname + ':' + itag
        #save
        cmd = 'docker save -o ' + tarname + ' ' + ifull
        print os.system(cmd)

    retval = p.wait()
```

批量导入，同理导入当前目录下的所有的tar包

```python
import  os

images = os.listdir(os.getcwd())
for imagename in images:
    if imagename.endswith('.tar'):
        print(imagename)
        os.system('docker load -i %s'%imagename)
```

# bash方式

## 导出

```bash
#!/bin/bash
docker images > images.txt
awk '{print $1}' images.txt > images_cut.txt
sed -i '1d' images_cut.txt
while read LINE
do
docker save $LINE > ${LINE//\//_}.train.tar
echo ok
done < images_cut.txt
echo finish
```

## 导入

```bash
#!/bin/bash
while read LINE
do
docker  load -i $LINE
echo ok
done < tarname.txt
echo finish
```


# 参考

https://www.cnblogs.com/ksir16/p/8865525.html