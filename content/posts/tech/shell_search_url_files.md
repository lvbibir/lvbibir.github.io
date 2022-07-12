---
title: "shell脚本之检索某url中所有文件的内容" #标题
date: 2022-07-01T00:00:00+08:00 #创建时间
lastmod: 2022-07-01T00:00:00+08:00 #更新时间
author: ["lvbibir"] #作者
categories: 
- 
tags: 
- shell
description: "" #描述
weight: # 输入1可以顶置文章，用来给文章展示排序，不填就默认按时间排序
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
# 前言

cve 官网或者工信部会发布一些 cve 漏洞，可以看到该漏洞在某次 commit 提交代码后修复的，可以通过检索 kernel.org 中所有内核版本的 ChangeLog 文件中是否包含该 commit 来判断漏洞影响的内核版本（仅针对 linux 的 kernel 相关的漏洞）

# 脚本

```shell
#!/bin/bash
# author: lvbibir
# date:   2022-06-23
# 检索 kernel.org 下的所有 ChangeLog 文件，是否包含某项特定的 commit 号

commit='520778042ccca019f3ffa136dd0ca565c486cedd'
version=4
number=0

curl  -ks https://cdn.kernel.org/pub/linux/kernel/v$version\.x/  > list_$version
cat list_$version | grep Change | grep -v sign | awk -F\" '{print $2}' > list_$version\_cut

total=`wc -l list_$version\_cut | awk '{print $1}'`

while read line; do

    let 'number+=1'
    url="https://cdn.kernel.org/pub/linux/kernel/v$version.x/$line"

    echo -e "\033[31m---------------------正在检索$url----------------第$number 个文件，共$total 个文件\033[0m"

    curl -ks $url | grep $commit

    if [ $? -eq 0 ]; then
        echo $url >> ./result_$version
    fi

done < ./list_$version\_cut

echo -e "\033[32m脚本执行完成，结果已保存至当前目录的 result_$version \033[0m"
```

