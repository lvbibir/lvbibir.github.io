#!/bin/bash

set -e
git add .
git commit -m "update post"
git push origin master

hugo -F --cleanDestinationDir
rsync -avuz --progress   --delete public/ root@lvbibir.cn:/root/blog/data/hugo/
