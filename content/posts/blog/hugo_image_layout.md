---
title: "修改hugo的图片布局，使多张图片可以并排显示" 
date: 2022-07-07 
lastmod: 2022-07-07
author: ["lvbibir"] 
categories: 
- 
tags: 
- hugo
- paper
- css
- html
description: ""
weight:  
slug: ""
draft: false # 是否为草稿
comments: true #是否展示评论
showToc: true # 显示目录
TocOpen: true # 自动展开目录
hidemeta: false # 是否隐藏文章的元信息，如发布日期、作者等
disableShare: true # 底部不显示分享栏
showbreadcrumbs: true #顶部显示当前路径
cover:
    image: ""
    caption: ""
    alt: ""
    relative: false
---

# 前言

仅是对前端一窍不通的我的一次尝试，如果有更好的实现方法可以评论或者发邮件告诉我~

# md文件中图片并排显示

先贴结论，并排显示图片只需要一段简单的 html 代码

> 图片路径可以是网络路径，也可以是本地文件路径
>
> 图片个数和width(宽度)按照自己需求来

```html
<center class="half">
    <img src="图片路径" width="194"/>
    <img src="图片路径" width="194"/>
    <img src="图片路径" width="194"/>
    <img src="图片路径" width="194"/>
</center>
```

大多数情况我们使用 markdown 进行图片插入时会直接调用 markdown 语法，如下

```markdown
![图片描述](图片路径)
```

当需要插入多张图片时，比如手机截图，通常这种图片挨个显示未免太丑，如下

图片实在太长，甚至一张图片都没截完，可以看到并排显示的空间利用率和美观性要比下面单张的好太多

![image-20220707143841758](https://image.lvbibir.cn/blog/image-20220707143841758.png)

# hugo-papermod主题中修改图片并排显示

先贴结论，按照上文中先在 post 文章中修改好图片代码，再修改站点主目录下面的` assets\css\core\reset.css`  文件

修改好之后，`hugo server` 预览文章就可以看到图片可以并排显示了

> 经测试，单张图片默认最大是792px，四张图片下，每张图片width属性最大设置为194px

 ```css
 img {
     /* 注释掉下面这行
     display: block; 
     */
     max-width: 100%;
 }
 ```

下面是我误打误撞发现修改方法的过程~

首先在typora中实现图片并排显示，百度了一下很快就找到了解决方法，但在 hugo server 预览文章时，发现图片依旧是多张图片依次显示

![image-20220707150118572](https://image.lvbibir.cn/blog/image-20220707150118572.png)

这里不难想通，typora 和 hugo 对 markdown 中图片的渲染可能有所区别

接下来使用 chrome 的开发者工具，尝试找到蛛丝马迹（之前最多用开发者工具看一下是否有报错，什么资源请求失败什么的~）

这里先是通过选取界面元素进行检查，看到了第三列的样式，而且这些样式或者说属性是可以点选的！

![image-20220707150700039](https://image.lvbibir.cn/blog/image-20220707150700039.png)

于是我就随便点了点，当把 img-display 这个样式前面的对钩去掉后，惊讶的发现，图片可以并排显示了！\\(^o^)/

![image-20220707151145385](https://image.lvbibir.cn/blog/image-20220707151145385.png)

到这里问题基本就解决了，先是尝试找请求的这个css文件，发现在 hugo 编译时生成的 public 下，没什么意义，通过 vscode 的全局查找，找到了 ` assets\css\core\reset.css`  文件，注释掉 `display: block`  后，图片就可以正常并排显示了。

# 引发了友链页面某个问题

修改了上述css文件后发现友链界面的图片变成了下面这样

![image-20220708152642148](https://image.lvbibir.cn/blog/image-20220708152642148.png)

多出来两个奇怪的东西，按照之前的方法再次尝试

![image-20220708152816463](https://image.lvbibir.cn/blog/image-20220708152816463.png)

去掉该属性后

![image-20220708152859231](https://image.lvbibir.cn/blog/image-20220708152859231.png)

最终修改的文件是`assets\css\extended\friend-link.css`  注释掉 `overflow: auto;` 之后恢复正常

目前尚不清楚还会不会有其他影响









