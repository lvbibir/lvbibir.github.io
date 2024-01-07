#!/bin/bash

set -e

rsync -avzc --progress --delete --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r /mnt/c/Users/lvbibir/OneDrive/1-lvbibir/obsidian/lvbibir/blog/* content/posts/

hugo server -D
