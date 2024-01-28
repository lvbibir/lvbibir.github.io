---
title: "wordpress | 添加 icp 备案号" 
date: 2021-07-01
lastmod: 2024-01-28
tags:
  - wordpress
  - 博客搭建
keywords:
  - wordpress
  - icp
  - 备案
description: "记录wordpress中如何添加icp备案号" 
cover:
    image: "https://image.lvbibir.cn/blog/wordpress.jpg" 
---

默认主题下在后台设置里修改即可

![image-20210722165156647](https://image.lvbibir.cn/blog/image-20210722165156647.png)

dux 主题修改方式：在后台管理→dux 主题编辑器→网站底部信息中添加

```html
<a href="http://beian.miit.gov.cn/" rel="external nofollow" target="_blank">京ICP备2021023168号-1</a>
```

![image-20210723092516963](https://image.lvbibir.cn/blog/image-20210723092516963.png)

通用修改方式

在主题目录的 `footer.php` 文件中的 `<footer></footer>` 下添加代码

```php
<a href="http://beian.miit.gov.cn/" rel="external nofollow" target="_blank">你的备案号</a>
```

以上
