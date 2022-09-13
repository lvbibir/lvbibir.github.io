---
title: "【置顶】Hello,hugo!"
date: 2022-07-06
lastmod: 2022-09-11
author: ["lvbibir"] 
categories: 
- 
tags: 
- hugo
- papermod
- docker
keywords:
- hugo
- papermod
- docker
- 博客部署
- 博客优化
description: "记录wordpress迁移至hugo+papermod的过程包含环境搭建、博客美化、功能实现、速度优化等……"
weight: 1
slug: ""
draft: false # 是否为草稿
comments: true #是否展示评论
showToc: true # 显示目录
TocOpen: true # 自动展开目录
hidemeta: false # 是否隐藏文章的元信息，如发布日期、作者等
disableShare: true # 底部不显示分享栏
showbreadcrumbs: true #顶部显示当前路径
cover:
    image: "https://image.lvbibir.cn/blog/hugo-logo-wide.svg"
    caption: ""
    alt: ""
    relative: false
---

# 前言

这篇文章是个大杂烩，且之后对于我博客的修改基本都会记录在这里，所以本文偏向个人备忘，并不是一个很合格的教程

# 一键将hugo博客部署到阿里云

> 虽说标题带有一键，但还是有一定的门槛的，需要对`dokcer`、`docker-compose`、`nginx`有一定了解

之前的[wordpress博客](https://lvbibir.cn)部署在阿里云的一套 docker-compose 环境下，[wordpress迁移到docker](https://www.lvbibir.cn/posts/blog/wordpress-to-docker/) 有详细记录

基于之前的配置进行了一些优化和调整，基于需求下载对应的配置文件：[hugo](https://image.lvbibir.cn/files/hugo-blog-dockercompose.tar.gz)、[wordpress](https://image.lvbibir.cn/files/wordpress-blog.zip)、[hugo + wordpress](https://image.lvbibir.cn/files/hugo-and-wordpress-dockercompose.tar.gz)

## hugo

> 包含 nginx-proxy、nginx-hugo 和 twikoo 组件

既然已经有了自己的服务器，我将 twikoo 评论组件也集成了进来访问速度要快很多，具体配置参考下文 [twikoo评论](#twikoo评论)

1. 确保服务器网络、ssl证书申请、服务器公网ip、域名解析、服务器安全组权限(80/443)等基础配置已经一应俱全
2. 确保服务器安装了 docker 和 docker-compose
3. 按照下文先把自定义的配置添加进去（域名和证书）
4. 配置完之后在`hugo-blog-dockercompose`目录下执行`docker-compose -f docker-compose.yml up -d`即可启动容器

**hugo-blog-dockercompose/conf/nginx-hugo/nginx.conf**

```nginx
......
server {
    listen       80 default_server; 
    listen       [::]:80 default_server;
    server_name ******; # 修改域名(hugo)
    root /var/www/html;
......
```

**hugo-blog-dockercompose/conf/nginx-proxy/default.conf**

将你的ssl证书放到`hugo-blog-dockercompose/ssl/`目录下

这里共4个`server`，分别对应 `hugo的nginx 和 twikoo`的`http 和 https`，证书申请参考 [阿里云wordpress配置免费ssl证书](https://www.lvbibir.cn/posts/blog/wordpress-ssl/)

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name ******; # 修改域名(hugo)
    return 301 https://$host$request_uri;
}

server {
    listen 80;
    listen [::]:80;
    server_name ******; # 修改域名(twikoo)
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ******; # 修改域名(hugo)
......
    ssl_certificate /etc/nginx/ssl/******; # 证书(hugo)
    ssl_certificate_key /etc/nginx/ssl/******; # 证书(hugo)）
......
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ******; # 修改域名(twikoo)
......
    ssl_certificate /etc/nginx/ssl/******; # 证书(twikoo)
    ssl_certificate_key /etc/nginx/ssl/******; # 证书(twikoo)
......
}
```

## hugo+wordpress

> 包含组件：nginx-proxy | nginx-hugo、twikoo | nginx-wordpress、wordpress-php、redis、mysql

这里就不过多介绍了，是我目前在用的方案，基于 [wordpress迁移到docker](https://www.lvbibir.cn/posts/blog/wordpress-to-docker/) 中介绍到的方案中加入了hugo的元素

# workflow

## 编辑文章

采用 typora + picgo + 七牛云图床流程，参考我的另一篇文章：[typora+picgo+七牛云上传图片](https://www.lvbibir.cn/posts/blog/typora-picgo-qiniu-upload-image/)

## 生成静态文件

```
hugo -F --cleanDestinationDir
```

后面两个参数表示会先删除之前生成的 public 目录，保证每次生成的 public 都是新的

## 上传静态文件

将 `mobaxterm` 的命令添加到用户环境变量中，以实现 `git bash` 、 `vscode` 、以及 `windows terminal` 中运行一些 mobaxterm 本地终端附带的命令，也就无需再专门打开一次 mobaxterm 去上传文件了

```
rsync -avuz --progress --delete public/ root@lvbibir.cn:/root/blog/data/hugo/
```

## 归档备份

研究 hugo 建站之初是打算采用 github pages 来发布静态博客

- 优点
- - 仅需一个github账号和简单配置即可将静态博客发布到 github pages
  - 没有维护的时间成本，可以将精力更多的放到博客内容本身上去
  - 无需备案
  - 无需ssl证书
- 缺点
- - 访问速度较慢
  - 访问速度较慢
  - 访问速度较慢

虽说访问速度较慢可以通过各家的cdn加速来解决，但由于刚开始建立 blog 选择的是 wordpress ，域名、服务器、备案、证书等都已经一应俱全，且之前的架构采用 docker，添加一台 nginx 来跑 hugo 的静态网站是很方便的

所以干脆沿用之前的 [github仓库](https://github.com/lvbibir/lvbibir.github.io) ，来作为我博客的归档管理，也可以方便家里电脑和工作电脑之间的数据同步

# 图片并排展示

当主题默认配置下，图片宽度为 `max-width: 100%;`，如果是手机截图类型的图片，可能一个页面都展示不全一个图片

单张图片建议修改尺寸，多张图片可以并排展示

```html
<center class="half">
    <img src="图片路径" width="194" style="display: unset;"/>
    <img src="图片路径" width="194" style="display: unset;"/>
    <img src="图片路径" width="194" style="display: unset;"/>
    <img src="图片路径" width="194" style="display: unset;"/>
</center>
```

另外也可以通过在线的免费工具拼接图片

# 修改链接颜色

在 hugo+papermod 默认配置下，链接颜色是黑色字体带下划线的组合，个人非常喜欢 [typora-vue](https://github.com/blinkfox/typora-vue-theme) 的渲染风格，[hugo官方文档](https://gohugo.io/templates/render-hooks/#link-with-title-markdown-example)给出了通过`render hooks`覆盖默认的markdown渲染的方式

新建`layouts/_default/_markup/render-link.html`文件，在官方给出的示例中添加了 `style="color:#42b983`，颜色可以自行修改，代码如下

```html
<a href="{{ .Destination | safeURL }}"{{ with .Title}} title="{{ . }}"{{ end }}{{ if strings.HasPrefix .Destination "http" }} target="_blank" rel="noopener" style="color:#42b983";{{ end }}>{{ .Text | safeHTML }}</a>
```

# url管理

https://gohugo.io/content-management/urls/

# seo优化

https://www.sulvblog.cn/posts/blog/hugo_seo/

# twikoo评论

~~基本完全按照 [sulv 博主](https://www.sulvblog.cn/posts/blog/hugo_twikoo/)的文章来操作，某些地方官方有更新，不过也只是更改了页面罢了~~

~~顺便记录一下账号关系：mongodb使用google账号登录，vercel使用github登录~~

> 官方文档：https://twikoo.js.org/quick-start.html
>
> vercel+mongodb+github部署方式参考：https://www.sulvblog.cn/posts/blog/hugo_twikoo/

## 私有部署（docker)

```
docker run --name twikoo -e TWIKOO_THROTTLE=1000 -p 8080:8080 -v ${PWD}/data:/app/data -d imaegoo/twikoo
```

部署完成后看到如下结果即成功

```
[root@lvbibir ~]# curl http://localhost:8080
{"code":100,"message":"Twikoo 云函数运行正常，请参考 https://twikoo.js.org/quick-start.html#%E5%89%8D%E7%AB%AF%E9%83%A8%E7%BD%B2 完成前端的配置","version":"1.6.7"}
```

后续最好套上反向代理，加上域名和证书

## 更新

1. 拉取新版本 `docker pull imaegoo/twikoo`
2. 停止旧版本容器 `docker stop twikoo`
3. 删除旧版本容器 `docker rm twikoo`

4. 部署新版本容器

## 前端代码

创建或者修改 `layouts\partials\comments.html`

```
<!-- Twikoo -->
<div>
    <div class="pagination__title">
        <span class="pagination__title-h" style="font-size: 20px;">💬评论</span>
        <hr />
    </div>
    <div id="tcomment"></div>
    <script src="https://cdn.staticfile.org/twikoo/{{ .Site.Params.twikoo.version }}/twikoo.all.min.js"></script>
    <script>
        twikoo.init({
            envId: "", //填自己的，例如：https://example.com
            el: "#tcomment",
            lang: 'zh-CN',
            path: window.TWIKOO_MAGIC_PATH||window.location.pathname,
        });
    </script>
</div>
```

调用上述twikoo代码的位置：`layouts/_default/single.html`

```
<article class="post-single">
  // 其他代码......
  {{- if (.Param "comments") }}
    {{- partial "comments.html" . }}
  {{- end }}
</article>
```

在站点配置文件config中加上版本号

```
params:
	twikoo:
      version: 1.6.7
```

# shortcode

ppt、bilibili、youtube、豆瓣阅读和电影卡片

https://www.sulvblog.cn/posts/blog/shortcodes/

mermaid

https://www.sulvblog.cn/posts/blog/hugo_mermaid/

图片画廊

https://github.com/liwenyip/hugo-easy-gallery/

https://www.liwen.id.au/heg/

# 自定义footer

自定义页脚内容

![image-20220911150229930](https://image.lvbibir.cn/blog/image-20220911150229930.png)

添加完下面的页脚内容后要修改 `assets\css\extended\blank.css` 中的 `--footer-height` 的大小，具体数字需要考虑到行数和字体大小

## 自定义徽标

> 徽标功能源自：https://shields.io/
> 考虑到访问速度，可以在生成完徽标后放到自己的cdn上

在 `layouts\partials\footer.html` 中的 `<footer>` 添加如下

```html
<a href="https://gohugo.io/" target="_blank">
    <img src="https://img.shields.io/static/v1?&style=plastic&color=308fb5&label=Power by&message=hugo&logo=hugo" style="display: unset;">
</a>
```

## 网站运行时间

在 `layouts\partials\footer.html` 中的 `<footer>` 添加如下

起始时间自行修改

```html
    <span id="runtime_span"></span> 
    <script type="text/javascript">function show_runtime(){window.setTimeout("show_runtime()",1000);X=new Date("7/13/2021 1:00:00");Y=new Date();T=(Y.getTime()-X.getTime());M=24*60*60*1000;a=T/M;A=Math.floor(a);b=(a-A)*24;B=Math.floor(b);c=(b-B)*60;C=Math.floor((b-B)*60);D=Math.floor((c-C)*60);runtime_span.innerHTML="网站已运行"+A+"天"+B+"小时"+C+"分"+D+"秒"}show_runtime();</script>
```

## 访问人数统计

> 统计功能源自：http://busuanzi.ibruce.info/

在 `layouts\partials\footer.html` 中的 `<footer>` 添加如下

```html
<script async src="//busuanzi.ibruce.info/busuanzi/2.3/busuanzi.pure.mini.js"></script>
<span id="busuanzi_container">
    <link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css">
    总访客数: <i class="fa fa-user"></i><span id="busuanzi_value_site_uv"></span>
    |
    总访问量: <i class="fa fa-eye"></i><span id="busuanzi_value_site_pv"></span>
    |
    本页访问量: <i class="fa fa-eye"></i><span id="busuanzi_value_page_pv"></span>
</span>
```

# todo

- [x] 修改所有文章的文件名为全英文
- [x] 百度seo优化
- [x] 谷歌seo优化
- [x] 必应seo优化
- [x] 尝试再次优化nginx的配置，之前的配置对于 php 程序更适用
- [ ] 图床备份
- [x] 将所有文章进行内容整理
- [ ] 说说页面
- [ ] 朋友圈页面





