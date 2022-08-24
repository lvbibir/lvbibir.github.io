---
title: "wordpress添加icp备案号" 
date: 2021-07-01
lastmod: 2021-07-01
author: ["lvbibir"] 
categories: 
- 
tags: 
- wordpress
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
    image: "" #图片路径：posts/tech/文章1/picture.png
    caption: "" #图片底部描述
    alt: ""
    relative: false
---
默认主题下在后台设置里修改即可

![image-20210722165156647](https://image.lvbibir.cn/blog/image-20210722165156647.png)

自定义主题或者其他主题需要修改footer.php文件

![image-20210722165549886](https://image.lvbibir.cn/blog/image-20210722165549886.png)

在\<footer>\</footer>中添加如下代码

![image-20210722165642646](https://image.lvbibir.cn/blog/image-20210722165642646.png)

```php+HTML
<div  style="text-align:center">
  <a href="http://beian.miit.gov.cn/" rel="external nofollow" target="_blank">
    <?php echo  get_option( 'zh_cn_l10n_icp_num' ); ?>
  </a>
</div>

```

dux主题修改方式：在后台管理→dux主题编辑器→网站底部信息中添加

```html
<a href="http://beian.miit.gov.cn/" rel="external nofollow" target="_blank">京ICP备2021023168号-1</a>
```

![image-20210723092516963](https://image.lvbibir.cn/blog/image-20210723092516963.png)

