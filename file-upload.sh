#!/bin/bash

set -e

# 生成静态文件
hugo -F --cleanDestinationDir

# 同步静态文件至服务器
rsync -avzc --progress --delete public/* root@lvbibir.cn:/root/blog/data/hugo/
