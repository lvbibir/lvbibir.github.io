---
title: "wsl | 安装配置 miniconda 虚拟环境"
date: 2024-01-13
lastmod: 2024-01-14
tags:
  - wsl
  - python
keywords:
  - windows
  - wsl
  - python
  - miniconda
description: "wsl 中安装 miniconda python 虚拟环境的步骤, 包含修改 conda 源, pip 源, conda 基础使用, 以及管理 conda 的一些小建议"
cover:
    image: "https://image.lvbibir.cn/blog/logo-wsl.png"
---

# 0.前言

之前写过一篇 [windows 安装 miniconda](https://www.lvbibir.cn/posts/tech/windows-miniconda/) 的文章, 后面在接触了 wsl 后发现用起来要比在原生 windows 上舒服很多, 毕竟我写 python 多是为了在 linux 服务器上跑, 用 wsl 会更顺滑一些, 虚拟环境同样选择更轻量的 miniconda

# 1.安装

下载并安装, 一路 yes 即可

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
sh Miniconda3-latest-Linux-x86_64.sh
```

# 2.配置

修改 conda 配置文件

```bash
cat > ${HOME}/.condarc <<- 'EOF'
channels:
  - defaults
show_channel_urls: true
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  msys2: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  bioconda: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  menpo: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch-lts: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  simpleitk: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  deepmodeling: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/
# 不自动激活 base 环境
auto_activate_base: false
# 虚拟环境存放路径
envs_dirs:
  - /home/lvbibir/miniconda3/envs
# pkg 存放路径
pkgs_dirs:
  - /home/lvbibir/miniconda3/pkgs
EOF
```

为了不搞坏 conda 的默认 base 环境, 我们创建一个虚拟环境, 每次默认进这个虚拟环境

```bash
cat >> ${HOME}/.bash_profile <<- 'EOF'
conda activate py37
EOF
```

退出重进后发现已经默认激活 py37 了

最后我们修改一下 pip 的配置, 添加清华源

```bash
mkdir ${HOME}/.pip
cat > ${HOME}/.pip/pip.conf <<- 'EOF'
[global]
timeout = 6000
index-url = http://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF

pip config list
```

测试一下 pip

```bash
pip install paramiko
```

# 3.虚拟环境

创建虚拟环境

```bash
# 安装一个虚拟环境
conda create -n py37 python=3.7
# 从现有环境复制一个虚拟环境
conda create -n py37-temp --clone py37
```

激活虚拟环境

```bash
conda activate py37
```

退出虚拟环境

```bash
conda deactivate
```

查看虚拟环境列表, 带有 `*` 的行就是当前所处的虚拟环境

```bash
conda env list
```

删除虚拟环境,

```bash
conda env remove -n py37
```

# 4.其他

conda 最为人诟病的点应该是包管理跟 pip 可能会产生一些冲突, conda 官方给出的最佳方案是

- 全程使用 `conda install` 来安装模块, 实在不行再用 `pip`
- 使用 conda 创建完虚拟环境后, 一直用 `pip` 来管理模块
    - pip 应使用 `–upgrade-strategy only-if-needed` 参数运行, 以防止通过 conda 安装的软件包进行不必要的升级. 这是运行 pip 时的默认设置, 不应更改
    - 不要将 pip 与 `–user` 参数一起使用，避免所有用户安装

总结一下就是不要来回地用 pip 和 conda, 专一一点 (笑

以上
