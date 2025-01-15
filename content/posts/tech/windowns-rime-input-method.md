---
title: "windows | rime 输入法 & 雾凇方案" 
date: 2024-02-04
lastmod: 2024-02-04
tags:
  - windows
keywords:
  - windows
  - rime
  - rime-ice
description: "介绍一下 windows 下安装 rime 小狼毫输入法使用雾凇方案, 以及一些好用的配置"
cover:
    image: "https://image.lvbibir.cn/blog/default-cover.webp"
---

# 0 前言

用了很多年的搜狗输入法, 苦于越来越多的后台, 又换到微软原生的输入法, 结果又出现了 vscode vim 中使用中文输入法的时候会一直乱跳, 遂又产生了换输入法的想法

我对输入法的要求很简单: 简洁方便, 后台干净, 自带良好的词库即可, 最后了解到了小狼毫输入法 ([rime](https://rime.im/) 的 windows 版本, 又称 rime weasel) 加 [雾凇方案](https://github.com/iDvel/rime-ice), 可定制项非常多, 也可以集成其他方案, 慢慢打磨成自己顺手的输入法

# 1 安装

安装前确认区域和语言设置中文的输入法为微软默认的输入法, 安装完成后在区域和语言设置中新增小狼毫输入法并删除微软默认输入法

- rime

由于 windows 上的 rime 更新有点慢, 当前版本的 vim mode 有些问题, 所以这里我采用了 [rime nightly build](https://github.com/rime/weasel/releases/tag/latest) 预览版, 下载 exe 安装包进行安装即可

安装位置选择 `D:\software\Rime`, 用户文件夹选择 `D:\software\Rime\profile`

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
  "style/font_face": "LXGW WenKai, Segoe UI Emoji:30:39, Segoe UI Emoji:23:23, Segoe UI Emoji:2a:2a, Segoe UI Emoji:fe0f:fe0f, Segoe UI Emoji:20e3:20e3, Microsoft YaHei, SF Pro, Segoe UI Emoji, Noto Color Emoji"
  # 标签字体
  "style/label_font_face": "LXGW WenKai"
  # 注释字体
  "style/comment_font_face": "LXGW WenKai"
  # 全局字体字号
  "style/font_point": 16
  # 标签字体字号，不设定 fallback 到 font_point
  "style/label_font_point": 16
  # 注释字体字号，不设定 fallback 到 font_point
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

以上
