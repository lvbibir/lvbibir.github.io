---
title: "【置顶】Hello,hugo!"
date: 2022-07-06
lastmod: 2022-09-11
tags: 
- 博客搭建
- docker
keywords:
- hugo
- papermod
- docker
- 博客部署
- 博客优化
description: "记录wordpress迁移至hugo+papermod的过程包含环境搭建、博客美化、功能实现、速度优化等……"
weight: 1
cover:
    image: "https://image.lvbibir.cn/blog/hugo-logo-wide.svg"
---

# 前言

研究 hugo 建站之初是打算采用 `Github Pages` 来发布静态博客

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

# 一键将hugo博客部署到阿里云

> 虽说标题带有一键，但还是有一定的门槛的，需要对`dokcer | docker-compose | nginx`有一定了解

[配置文件下载](https://image.lvbibir.cn/files/blog-docker-compose.zip) 下载完将目录上传到自己的服务器，重命名为 `blog` (当然你可以用其他名字)

1. 确保服务器网络、ssl证书申请、服务器公网ip、服务器安全组权限(80/443)等基础配置已经一应俱全
2. 确保服务器安装了 docker 和 docker-compose
3. 修改`blog/conf/nginx-hugo/nginx.conf`和`blog/conf/nginx-proxy/default.conf`，需要修改的地方在文件中已经标注出来了
4. 将你的ssl证书放到`hugo-blog-dockercompose/ssl/`目录下
5. 在`blog`目录下执行`docker-compose up -d`即可启动容器
6. 将hugo生成的`public`目录上传到服务器`blog/data/hugo/`中，[参考下文](#workflow)
7. 在域名提供商处为你的域名添加A记录，指向服务器的公网ip地址(主域名和twikoo域名都要配置)
   ![image-20230313142456952](https://image.lvbibir.cn/blog/image-20230313142456952.png)
8. 都配置完后 [参考下文](#twikoo评论) 配置twikoo

至此已经配置完成，应该可以通过域名访问hugo站点了，后续更新内容只需要hugo生成静态文件上传到服务即可

所有的配置、应用数据、日志都保存在blog目录下，你可以在不同的服务器上快速迁移hugo环境，无需担心后续想要迁移新服务器时遇到的各种问题

# workflow

## 编辑文章

采用 typora + picgo + 七牛云图床流程，参考我的另一篇文章：[typora+picgo+七牛云上传图片](https://www.lvbibir.cn/posts/blog/typora-picgo-qiniu-upload-image/)

## 生成静态文件

```
hugo -F --cleanDestinationDir
```

后面两个参数表示会先删除之前生成的 public 目录，保证每次生成的 public 都是新的

## 上传静态文件

将`mobaxterm`的命令添加到用户环境变量中，以实现`git bash | vscode | windows terminal`中运行一些 mobaxterm 本地终端附带的命令，也就无需再专门打开一次 mobaxterm 去上传文件了

```
rsync -avuz --progress --delete public/ root@lvbibir.cn:/root/blog/data/hugo/
```

## 归档备份

沿用搭建`Github pages`时使用的 [github仓库](https://github.com/lvbibir/lvbibir.github.io) ，来作为我博客的归档管理，也可以方便家里电脑和工作电脑之间的数据同步



# twikoo评论

所有部署方式：https://twikoo.js.org/quick-start.html

vercel+mongodb+github部署方式参考：https://www.sulvblog.cn/posts/blog/hugo_twikoo/

记录一下账号关系：mongodb使用google账号登录，vercel使用github登录

## 私有部署(docker)

> 如果是使用 [一键将hugo博客部署到阿里云](#一键将hugo博客部署到阿里云) 中的步骤部署了twikoo，这步直接忽略，配置前端代码即可

```
docker run --name twikoo -e TWIKOO_THROTTLE=1000 -p 8080:8080 -v ${PWD}/data:/app/data -d imaegoo/twikoo
```

部署完成后看到如下结果即成功

```
[root@lvbibir ~]# curl http://localhost:8080
{"code":100,"message":"Twikoo 云函数运行正常，请参考 https://twikoo.js.org/quick-start.html#%E5%89%8D%E7%AB%AF%E9%83%A8%E7%BD%B2 完成前端的配置","version":"1.6.7"}
```

后续最好套上反向代理，加上域名和证书

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

## 更新

1. 拉取新版本`docker pull imaegoo/twikoo`
2. 停止旧版本容器`docker stop twikoo`
3. 删除旧版本容器`docker rm twikoo`
4. 部署新版本容器`docker-compose up -d`
5. 在hugo配置文件 config.yml 中修改 twikoo版本

## 修改数据

直接修改`blog/data/twikoo/`目录下的文件后重启容器，❗慎重修改

## 修改smms图床的api地址

由于`sm.ms`域名国内无法访问，twikoo官方还没有出具体的修改方式，自己修改容器配置文件进行修改

```bash
# 复制配置文件
[root@lvbibir blog]# docker cp twikoo:/app/node_modules/twikoo-func/utils/image.js /root/blog/conf/twikoo/

# 修改配置文件，原来的配置是 https://sm.ms/api.v2/upload
[root@lvbibir blog]# grep smms conf/twikoo/image.js
      } else if (config.IMAGE_CDN === 'smms') {
    const uploadResult = await axios.post('https://smms.app/api/v2/upload', formData, {

# 将配置文件映射进容器内，重启容器即可
[root@lvbibir blog]# grep twikoo docker-compose.yml
  twikoo:
    image: imaegoo/twikoo
    container_name: twikoo
      - $PWD/data/twikoo:/app/data
      - $PWD/conf/twikoo/image.js:/app/node_modules/twikoo-func/utils/image.js
```

# 自定义字体

可以使用一些在线的字体，可能会比较慢，推荐下载想要的字体放到自己的服务器或者cdn上

修改`assets\css\extended\fonts.css`，添加`@font-face`

```css
@font-face {
    font-family: "LXGWWenKaiLite-Bold";
    src: url("https://your.domain.com/fonts/test.woff2") format("woff2");
    font-display: swap;
}
```

修改`assets\css\extended\blank.css`，推荐将英文字体放在前面，可以实现英文和中文使用不同字体。

```css
.post-content {
    font-family: Consolas, "LXGWWenKaiLite-Bold"; //修改
}

body {
    font-family: Consolas, "LXGWWenKaiLite-Bold"; //修改
}
```

# 修改链接颜色

在 hugo+papermod 默认配置下，链接颜色是黑色字体带下划线的组合，个人非常喜欢[typora-vue](https://github.com/blinkfox/typora-vue-theme)的渲染风格[hugo官方文档](https://gohugo.io/templates/render-hooks/#link-with-title-markdown-example)给出了通过`render hooks`覆盖默认的markdown渲染link的方式

新建`layouts/_default/_markup/render-link.html`文件，内容如下。在官方给出的示例中添加了 `style="color:#42b983`，颜色可以自行修改

```html
<a href="{{ .Destination | safeURL }}"{{ with .Title}} title="{{ . }}"{{ end }}{{ if strings.HasPrefix .Destination "http" }} target="_blank" rel="noopener" style="color:#42b983";{{ end }}>{{ .Text | safeHTML }}</a>
```

# Artitalk说说

[官方文档](https://artitalk.js.org/doc.html)

需要注意的是如果使用的是国际版的LeadCloud，需要绑定自定义域名后才能正常访问

记录一下账号关系：LeadCloud使用163邮箱登录

## leancloud配置

1. 前往 [LeanCloud 国际版](https://leancloud.app/)，注册账号。
2. 注册完成之后根据 LeanCloud 的提示绑定手机号和邮箱。
3. 绑定完成之后点击`创建应用`，应用名称随意，接着在`结构化数据`中创建 `class`，命名为 `shuoshuo`。
4. 在你新建的应用中找到`结构化数据`下的`用户`。点击`添加用户`，输入想用的用户名及密码。
5. 回到`结构化数据`中，点击 `class` 下的 `shuoshuo`。找到权限，在 `Class 访问权限`中将 `add_fields` 以及 `create` 权限设置为指定用户，输入你刚才输入的用户名会自动匹配。为了安全起见，将 `delete` 和 `update` 也设置为跟它们一样的权限。
6. 然后新建一个名为`atComment`的class，权限什么的使用默认的即可。
7. 点击 `class` 下的 `_User` 添加列，列名称为 `img`，默认值填上你这个账号想要用的发布说说的头像url，这一项不进行配置，说说头像会显示为默认头像 —— Artitalk 的 logo。
8. 在最菜单栏中找到设置-> 应用 keys，记下来 `AppID` 和 `AppKey` ，一会会用。
9. 最后将 `_User` 中的权限全部调为指定用户，或者数据创建者，为了保证不被篡改用户数据以达到强制发布说说。
10. 在设置->域名绑定中绑定自定义域名

> ❗ 关于设置权限的这几步
>
> 这几步一定要设置好，才可以保证不被 “闲人” 破解发布说说的验证

## hugo配置

新增 `content/talk.md` 页面，内容如下，注意修改标注的内容，front-matter 的内容自行修改

```markdown
---
title: "💬 说说"
date: 2021-08-31
hidemeta: true
description: "胡言乱语"
comments: true
reward: false
showToc: false 
TocOpen: false 
showbreadcrumbs: false
---

<body>
<!-- 引用 artitalk -->
<script type="text/javascript" src="https://unpkg.com/artitalk"></script>
<!-- 存放说说的容器 -->
<div id="artitalk_main"></div>
<script>
new Artitalk({
    appId: '**********', // Your LeanCloud appId
    appKey: '************', // Your LeanCloud appKey
    serverURL: '*********' // 绑定的自定义域名
})
</script>
</body>
```

这个时候已经可以直接访问了，`https://your.domain.com/talk`

输入 leancloud配置 步骤中的第4步配置的用户名密码登录后就可以发布说说了


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

> 添加完下面的页脚内容后要修改 `assets\css\extended\blank.css` 中的 `--footer-height` 的大小，具体数字需要考虑到行数和字体大小

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

# 其他修改

前端知识比较匮乏，其他 css样式修改 基本都是通过 f12控制台 一点点摸索改的，不太规范且比较琐碎就不单独记录了，~~其实我根本已经忘记还改了哪些东西~~



