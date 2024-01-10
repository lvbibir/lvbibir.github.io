---
title: "autohotkey 常用脚本"
date: 2021-12-01
lastmod: 2024-01-07
tags:
  - windows
keywords:
  - windows
  - autohotkey
  - ahk
description: ""
cover:
    image: "https://source.unsplash.com/random/400x200?code" 
---

# 0.前言

基于 autohotkey v1 版本

使用方法: 安装 autohotkey 后, 将下述代码保存为 `.ahk` 文件, 双击执行即可

如需开机自启, 在 `运行` 中执行 `shell:startup`, 将 `.ahk` 文件放到自启动目录即可

# 1.prtsc 改为 shift insert

我的机械键盘是 80 配列, 没有 insert, `shift+insert` 几乎是所有软件都支持的粘贴方式, 遂将很不常用的 `prtsc` 键改为 `shfit+insert` 的组合键

```textile
PrintScreen::+Insert
```

# 2.typora 快捷修改字体颜色

实现 `alt` + 数字键快速将光标选中的文本改为对应的颜色

```textile
; 分号以及分号后的内容代表注释，以下为代码解释
#IfWinActive ahk_exe Typora.exe
{
    ; alt+0 黑色
    !0::addFontColor("black")
    ; alt+1 珊瑚色
    !1::addFontColor("coral")
    ; alt+2 红色
    !2::addFontColor("red")
    ; alt+3 黄色
    !3::addFontColor("yellow")
    ; alt+4 绿色
    !4::addFontColor("green")
    ; alt+5 浅蓝色
    !5::addFontColor("cornflowerblue")
    ; alt+6 青色
    !6::addFontColor("cyan") 
    ; alt+7 紫色
    !7::addFontColor("purple")
}

; 快捷增加字体颜色
addFontColor(color){
    clipboard := "" ; 清空剪切板
    Send {ctrl down}c{ctrl up} ; 复制
    ; SendInput {Text} ; 解决中文输入法问题
    SendInput {TEXT}<font color='%color%'>
    SendInput {ctrl down}v{ctrl up} ; 粘贴
    If(clipboard = ""){
        SendInput {TEXT}</font> ; Typora 在这不会自动补充
    }else{
        SendInput {TEXT}</ ; Typora中自动补全标签
    }
}
```
