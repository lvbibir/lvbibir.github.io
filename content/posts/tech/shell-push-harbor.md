---
title: "shell | 将本地镜像批量推送到harbor" 
date: 2022-10-12
lastmod: 2022-10-12
tags: 
- shell
- docker
keywords:
- shell
- docker
- harbor
description: "经常会下一些外网镜像用于测试，手动修改镜像tag然后推送在镜像较多的情况下比较繁琐，本文采用bash脚本方式批量推送不同格式的镜像" 
cover:
    image: "https://image.lvbibir.cn/blog/shell.png" 
---

**流程图**

![](https://image.lvbibir.cn/blog/harbor_push.png.png)

**代码示例**

> 使用前需要登录harbor
>
> 确保镜像的项目名在harbor中已存在
>
> 格式三类型的镜像会推送到harbor的library项目中

```bash
#!/bin/bash
# author: Amadeus Liu
# date: 2022-10-11 17:02:13
# version: 1.0

harbor_url="local.harbor.com"
log_file="/var/log/push-harbor.log"
image_id=$(docker images -q | sort -u)

ls ${log_file} || touch ${log_file}
echo "############# $(date "+%Y-%m-%d %H:%M:%S") #############" >> ${log_file}

get_image_tags () {
  docker inspect $1 --format='{{.RepoTags}}' | sed 's/\[//g' | sed 's/\]//g'
}

image_tag_and_push () {
  docker tag $1 $2 && echo "docker tag  $1 $2" >> ${log_file}
  docker push $2 && echo "docker pull $1 $2" >> ${log_file}
}

for i in ${image_id}; do
  # 判断镜像是否有harbor仓库的标签，有则视为harbor仓库中已有
  if [[  $(get_image_tags $i) =~ ${harbor_url} ]]; then
      echo "已有${harbor_url}仓库标签-----$(get_image_tags $i)"
    else
      # 镜像的第一个完整标签
      image_tag_first=$(echo $(get_image_tags $i) | awk -F' ' '{print $1}')
      # 镜像的第一个完整标签并去除版本
      image_tag_first_delete_ver=$(echo ${image_tag_first} | awk -F':' '{print $1}')
      
      # 判断标签属于哪种格式
      if [[ ${image_tag_first_delete_ver} =~ "/" ]]; then
        # 镜像的第一个完整标签的第一部分（'/'分割后的$1）
        image_tag_first_repo=$(echo ${image_tag_first_delete_ver}| awk -F'/' '{print $1}')
        if [[ "${image_tag_first_repo}" =~ "." ]]; then
            # 格式一
            image_tag_harbor="${harbor_url}/$(echo ${image_tag_first} | awk -F'/' '{print $2}')/$(echo ${image_tag_first} | awk -F'/' '{print $3}')"
            echo "${image_tag_first} >>>>>tag to>>>>> ${image_tag_harbor}"
            image_tag_and_push $i ${image_tag_harbor}
          else
            # 格式二
            image_tag_harbor="${harbor_url}/${image_tag_first}"
            echo "${image_tag_first} >>>>>tag to>>>>> ${image_tag_harbor}"
            image_tag_and_push $i ${image_tag_harbor}
        fi
      else
        # 格式三
        image_tag_harbor="${harbor_url}/library/${image_tag_first}"
        echo "${image_tag_first} >>>>>tag to>>>>> ${image_tag_harbor}"
        image_tag_and_push $i ${image_tag_harbor}
      fi
  fi
done
```

**腾讯云搬迁声明**

我的博客即将同步至腾讯云开发者社区，邀请大家一同入驻：https://cloud.tencent.com/developer/support-plan?invite_code=3ielzwnut2qsg