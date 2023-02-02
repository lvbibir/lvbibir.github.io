#!/bin/bash

set -e
git add .
git commit -m "update post"
git push origin master

hugo -F --cleanDestinationDir
rsync -avuz --progress   --delete public/ root@101.201.150.47:/root/blog/data/hugo/
