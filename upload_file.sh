#!/bin/bash

set -e

hugo -F --cleanDestinationDir
rsync -avuz --progress   --delete public/ root@lvbibir.cn:/root/blog/data/hugo/
