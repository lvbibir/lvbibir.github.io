#!/bin/bash

set -e

rsync -az --info=progress2 --delete --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r /mnt/c/Users/lvbibir/OneDrive/1-lvbibir/obsidian/lvbibir/blog/* content/posts/
rsync -az --info=progress2 --delete --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r /mnt/c/Users/lvbibir/OneDrive/1-lvbibir/obsidian/lvbibir/images/* static/images/

hugo server -D
