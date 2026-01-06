---
title: "vim | 基础配置和使用" 
date: 2024-02-04
lastmod: 2024-02-05
tags:
  - vim
keywords:
  - vim
  - vscode
  - obsidian
description: "本文介绍一下 vim 常用的操作, vimrc 常用配置, vscode 中 vim 插件的额外功能等"
cover:
    image: "images/default-cover.webp"
---

# 0 前言

本文参考以下链接:

- [指尖飞舞: vscode + vim 高效开发](https://www.bilibili.com/video/BV1z541177Jy?p=1)
- [vim 备忘清单](http://reference.jgeek.cn/docs/vim.html)

一直憧憬 vim 的全键盘操作, 于是开始折腾将 obsidian 和 vscode 的编辑模式都转到 vim, obsidian 使用自带的 vim 模式加 [vimrc 插件](https://github.com/esm7/obsidian-vimrc-support), vscode 使用 [vim 插件](https://github.com/VSCodeVim/Vim)

为了保持 obsidian, vscode, wsl 及 linux 中的 vim 习惯一致, 我的 vim 使用理念:

- 尽量使用 vim 原生自带的功能, 拒绝任何三方插件
- 尽量使用各平台通用的 vimrc 配置 (除了 vscode 使用 setting.json)

# 1 vim 通用操作

## 1.1 示例

vim 中的操作都是通过如下方式进行操作的:

- `[数字] <操作符> <动作>/<文本对象> `
- `<操作符> [数字] <动作>/<文本对象> `

```plaintext
>i{      | 将当前 {} 内的内容向右缩进
dfa      | 删除直到 a 字符
d/hello  | 删除直到 hello
ggyG     | 复制整个文档
dip      | 删除整个段落
ciw      | 更改当前 word
cit      | 更改当前 html 标签的内容
```

## 1.2 operator 操作符

```plaintext
d   | 删除
y   | yank (复制)
c   | 更改 (删除然后插入)
p   | 粘贴
=   | 格式代码
g~  | 切换案例
gU  | 大写
gu  | 小写
>   | 右缩进
<   | 左缩进
!   | 外部程序过滤
```

## 1.3 motion 动作

基础动作

```plaintext
h/j/k/l      | 左/下/上/右
ctrl + u/d   | 上/下 半页
ctrl + b/f   | 上/下 翻页
```

字 (词)

```plaintext
b/w   | 上一个/下一个 单词开始
ge/e  | 上一个/下一个 单词末尾
```

行

```plaintext
0/$   | 行首/行尾
^     | 行首 (非空白)
```

字符串

```plaintext
Fe/fe   | 移动到上一个/下一个 e
To/to   | 在上一个/下一个 o 之前/之后移动
| / n|  | 转到一个 /n 列
```

文档

```plaintext
gg/G    | 第一行/最后一行
:n/nG   | 转到第 n 行
{ / }   | 上一个/下一个空行
```

窗口

```plaintext
H/M/L      | 上/中/下 屏幕
zt/zz/zb   | 上/中/下 这条线
```

## 1.4 文本对象

inner(内部) / around(周围)

```plaintext
p         | 段落
w         | 单词
W         | WORD(被空格包围)
s         | 句子
[({<>})]  | [], (), {} 或者 <> 块
'"\`      | 带引号的字符串
b         | 同 ()
B         | 同 {}
t         | html 标签块
```

# 2 vscode 中的 vim

下述功能源于 vscode vim 插件

## 2.1 easymotion

```plaintext
<leader><leader>s<str>  | 可以快速向后查找
<leader><leader>f<str>  | 可以快速向前查找
```

## 2.2 surround
  
```plaintext
cs"'          | 将 `"` 替换为 '
ds"           | 删除包围的 "
ys<motion>"   | 添加包围的 ", 如 ysiw"
```

## 2.3 multi-cursor 多光标

可以使用 `gb` 代替 vscode 中的 `ctrl-d`

## 2.4 其他操作

```plaintext
gh  | 可以模拟鼠标悬浮
gd  | 可以切换定义
```

# 3 vimrc

vimrc 的位置:
- obsidian: 在插件配置中我将 vimrc 的默认文件名从 `.obsidian.vimrc` 改成了 `.vimrc` 存放到了 obsidian 仓库的根目录
- wsl: 我的 wsl 是 ubuntu, 为了使用 sudo 时 vimrc 配置生效, vimrc 修改通过修改 `/etc/vim/vimrc` 实现
- vscode: vscode 直接使用 setting.json 中 vim 的配置

我的 vimrc 配置示例

```vimrc
" 插入模式下使用 jj 快速返回到 normal 模式 
inoremap jj <Esc>

" 使上下移动的时候按照视觉的行数移动, 对于多行的段落很有效
nmap j gj
nmap k gk

" 快捷行首和行尾
" normal 模式使用
nmap H ^
nmap L $
" 操作模式使用, 用于 yL, dH 等操作
omap H ^
omap L $
" visual 模式使用
vmap H ^
vmap L $
```

vscode 中的 vim 配置示例

```json
// vim 相关
"vim.leader": "<space>",
"vim.incsearch": true,
"vim.easymotion": true,
// 使用系统剪贴板作为 vim 寄存器
"vim.useSystemClipboard": true,
// 由 vim 接管 ctrl + any 快捷键
"vim.useCtrlKeys": true,
// 突出显示与当前搜索匹配的所有文本
"vim.hlsearch": true,
// 下列按键由 vscode 接管而不是 vim
"vim.handleKeys": {
    "<C-a>": false,
    "<C-f>": false,
    "<C-k>": false,
    "<C-n>": false,
    "<C-p>": false,
},
"vim.insertModeKeyBindings": [
    {
        "before": ["j", "j"],
        "after": ["<Esc>"]
    }
],
"vim.normalModeKeyBindingsNonRecursive": [
    {
        "before": ["j"],
        "after": ["g", "j"]
    },
    {
        "before": ["k"],
        "after": ["g", "k"]
    },
    {
        "before": ["K"],
        "commands": ["lineBreakInsert"],
        "silent": true
    },
    {
        "before": ["L"],
        "after": ["$"]
    },
    {
        "before": ["H"],
        "after": ["^"]
    }
],
"vim.operatorPendingModeKeyBindings": [
    {
        "before": ["L"],
        "after": ["$"]
    },
    {
        "before": ["H"],
        "after": ["^"]
    }
],
"vim.visualModeKeyBindingsNonRecursive": [
    {
        "before": ["L"],
        "after": ["$"]
    },
    {
        "before": ["H"],
        "after": ["^"]
    }
],
"extensions.experimental.affinity": {
    "vscodevim.vim": 1
},
```

以上
