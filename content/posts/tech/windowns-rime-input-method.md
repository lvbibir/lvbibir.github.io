---
title: "windows | rime 输入法 & 雾凇方案" 
date: 2024-02-04
lastmod: 2026-02-06
tags:
  - windows
keywords:
  - windows
  - rime
  - rime-ice
description: "介绍一下 windows 下安装 rime 小狼毫输入法使用雾凇方案, 以及一些好用的配置"
cover:
    image: "images/cover-default.webp"
---

# 0 前言

用了很多年的搜狗输入法, 苦于越来越多的后台, 又换到微软原生的输入法, 结果又出现了 vscode vim 中使用中文输入法的时候会一直乱跳, 遂又产生了换输入法的想法

我对输入法的要求很简单: 简洁方便, 后台干净, 自带良好的词库即可, 最后了解到了小狼毫输入法 ([rime](https://rime.im/) 的 windows 版本, 又称 rime weasel) 加 [雾凇方案](https://github.com/iDvel/rime-ice), 可定制项非常多, 也可以集成其他方案, 慢慢打磨成自己顺手的输入法

# 1 安装

- rime

下载 exe 安装包进行安装即可, 安装位置选择 `D:\software\Rime`, 用户文件夹选择 `D:\software\Rime\profile`

- 雾凇方案

直接下载 zip 解压后将所有文件复制到 `D:\software\Rime\profile` 即可

之后在任务栏的语言栏右击小狼毫图标选择重新部署, 等待部署完成后按 `F4` 选择 `雾凇方案` 即可, 也可以切换简繁体, 中英文标点和全半角等

# 2 配置

[雾凇方案 - 官方配置指南](https://dvel.me/posts/rime-ice/) [rime weasel - wiki](https://github.com/rime/weasel/wiki)

可以通过直接修改 profile 下的 `default.yaml` 和 `weasel.yaml` 实现, 但是后续无法再方便地进行更新, 推荐通过 patch 方式进行修改, 比如 `default.yaml` 的 patch 文件就是 `default.custom.yaml`

修改 `D:\software\Rime\profile\weasel.custom.yaml`, 添加如下

```yaml
patch:

  # 配色方案
  "style/color_scheme": "lost_temple"

  # 字体相关配置
  "style/font_face": "JetBrainsLxgwNerdMono, 'Segoe UI Emoji'"
  # 标签字体
  "style/label_font_face": "JetBrainsLxgwNerdMono, 'Segoe UI Emoji'"
  # 注释字体
  "style/comment_font_face": "JetBrainsLxgwNerdMono, 'Segoe UI Emoji'"
  # 全局字体字号
  "style/font_point": 16
  # 标签字体字号,不设定 fallback 到 font_point
  "style/label_font_point": 16
  # 注释字体字号,不设定 fallback 到 font_point
  "style/comment_font_point": 14
  # 行内取消显示预编辑区, 可以解决 vscode 输入中文的光标跳动问题
  "style/inline_preedit": false

  # 针对不同的应用程序设置输入法的默认状态
  # ascii_mode true 表示使用英文
  # vim_mode true 表示在使用 <Esc> 或者 ctrl + [ 时自动切换到英文
  app_options:
    WindowsTerminal.exe:
      ascii_mode: true
      vim_mode: true
    Obsidian.exe:
      ascii_mode: true
      vim_mode: true
    Code.exe:
      ascii_mode: true
      vim_mode: true
    MobaXterm.exe:
      ascii_mode: true
      vim_mode: true
```

修改 `D:\software\Rime\profile\default.custom.yaml`

```yaml
patch:
  # 方案选单, 我只使用全拼
  schema_list:
    - {schema: rime_ice}

  # 修改了默认配置中的快捷键和是否折叠
  switcher:
    caption: [方案选单]
    # 修改快捷键 F4 呼出方案选单
   hotkeys:
      - F4
    save_options:
      - ascii_punct
      - traditionalization
      - emoji
      - full_shape
      - single_char
    # 呼出时是否折叠
    fold_options: false
    # 折叠时是否缩写选项
    abbreviate_options: true
    # 折叠时的选项分隔符
    option_list_separator: ' | '

  # 添加 , 和 . 翻页
  key_binder/bindings/+:
    - { when: paging, accept: comma, send: Page_Up }
    - { when: has_menu, accept: period, send: Page_Down }

```

修改完成后重新部署即可, 后续更改配置基本只需要修改这两个文件, 更新方案直接通过覆盖文件的方式进行全量更新

# 3 词库同步

## 3.1 修改配置

在配置目录新增或修改 `installation.yaml` 文件, 写入如下内容

```yaml
installation_id: pc_leigod911
sync_dir: "C:/Users/lvbibir/OneDrive/1-lvbibir/软件配置/rime-sync"
```

1. `sync_dir` 配置成同步的目录, 我这里使用 onedrive
2. 不同电脑之间的 `installation_id` 需要配置成不同的, 不然可能会冲突或者互相影响

Rime 的机制是:

- 每台电脑在同一个 `sync_dir` (你的 OneDrive 同步根目录) 里, 用自己的 `installation_id` 建一个子目录 (比如 `pc_leigod911`,`pc_laptop`)
- 同步时会把 " 所有设备子目录里的快照 " 合并到本机,再把合并结果写回本机自己的子目录
- 所以两台电脑最终会互相影响, 互相合并词频/新词 (前提是两台都执行过同步,并且 OneDrive 完成上传/下载)

## 3.2 手动同步

右击小狼毫的状态栏依次执行 `重启算法服务` `重新部署` `用户资料同步`

## 3.3 自动同步

Windows 小狼毫可以用计划任务实现定时同步,本质就是定时执行 `WeaselDeployer.exe /sync` 这个命令.

需要注意的事, `/sync` 可能会导致 `WeaselServer.exe` 重启或短暂中断,正在输入时会打断上屏, 有人就遇到计划任务每小时同步导致输入中断的问题. 所以建议把触发条件设成空闲时段.

1. 找到可执行文件路径, 可以右键任务栏打开 `程序文件夹`
2. 用任务计划程序创建定时任务
    - 打开 `任务计划程序`
    - 右侧点 `创建任务`
    - 常规: 勾选 `仅当用户登录时运行`, `使用最高权限运行`
    - 触发器: 新建, `每天`, `重复任务间隔` 设为 `1 小时`, 持续时间选 `无限期`
    - 操作: 新建
        - 程序或脚本: `WeaselDeployer.exe`
        - 添加参数: `/sync`.
        - 起始于: `D:\software\Rime\weasel-0.17.4`, ❗按实际情况修改
    - 条件: 强烈建议勾选
        - `仅当计算机空闲以下时间后才启动此任务`,比如 10 分钟
        - 这样可以尽量避免打断正在输入.
3. 同步效果检查要点
    - 两台电脑都要配置相同的 `sync_dir` 根目录,并且各自 `installation_id` 不同
    - OneDrive 要先把对方的同步文件下载完成,你再触发 `/sync`,否则看起来像没合并

以上.
