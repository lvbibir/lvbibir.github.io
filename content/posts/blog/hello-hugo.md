---
title: "【置顶】Hello, hugo!"
date: 2022-07-06
lastmod: 2025-12-11
tags:
  - 博客搭建
keywords:
  - hugo
  - papermod
  - docker
  - 博客部署
  - 博客优化
description: "记录 wordpress 迁移至 hugo+papermod 的过程, 包含环境搭建、博客美化、功能实现、速度优化等……"
weight: 1
cover:
    image: "https://image.lvbibir.cn/blog/hugo-logo-wide.svg"
    hidden: false
    hiddenInSingle: false
---

# 0 前言

本文内容比较杂乱, 无法保证实时更新, 如果遇到问题, 可以在 github 查看最新的配置:

- [hugo 相关配置](https://github.com/lvbibir/lvbibir.github.io)
- [docker 相关配置](https://github.com/lvbibir/blog-bak)

研究 hugo 建站之初是打算采用 `Github Pages` 来发布静态博客

- 优点
    - 仅需一个 github 账号和简单配置即可将静态博客发布到 github pages
    - 没有维护的时间成本, 可以将精力更多的放到博客内容本身上去
    - 无需备案
    - 无需 ssl 证书
- 缺点
    - 访问速度较慢
    - 访问速度较慢
    - 访问速度较慢

虽说访问速度较慢可以通过各家的 cdn 加速来解决, 但由于刚开始建立 blog 选择的是 wordpress, 域名, 服务器, 备案, 证书等都已经一应俱全, 且之前的架构采用 docker, 添加一台 nginx 来跑 hugo 的静态网站是很方便的

# 1 将博客部署到阿里云

整个步骤最难的地方可能就是 docker-compose 和 nginx 的配置了, 如果之前没有接触过可能会比较吃力, 因此我打包了一份开袋即食的配置文件, 只需要修改一些必要配置, [点此链接下载](https://image.lvbibir.cn/files/blog-docker-compose.zip)

下载完将压缩包上传到自己的服务器, 解压后重命名为 `blog` (当然你可以用其他名字)

下面正式开始部署:

1. 确保服务器公网 ip、安全组权限 (80/443), 域名绑定, ssl 证书等基础配置已经一应俱全
2. 确保服务器安装了 docker 和 docker-compose
3. 修改 `blog/conf/nginx-hugo/nginx.conf` 和 `blog/conf/nginx-proxy/default.conf`, 需要修改的地方在文件中已经标注出来了
4. 将你的 ssl 证书放到 `blog/ssl/` 目录下
5. 在 `blog` 目录下执行 `docker-compose up -d` 即可启动容器
6. 配置 twikoo 的前端代码, 见本文章节 3.2
7. 将 hugo 生成的静态文件上传到 `blog/data/hugo/` 目录, 见本文章节 2

至此已经配置完成, 应该可以通过域名访问 hugo 站点了, 后续更新内容只需要重复最后一步, 将 hugo 生成的静态文件上传到服务器即可

所有的配置、应用数据、日志都保存在 blog 目录下, 你可以在不同的服务器上快速迁移 hugo 环境, 无需担心后续想要迁移新服务器时遇到的各种问题

# 2 workflow

在这里简单介绍一下我从写博客 -> 发布到服务器 -> 归档备份的整个流程

总体流程:

1. obsidian 编辑文章, 图片通过 `Image Auto Upload Plugin` 插件配合 piclist 上传到阿里云 OSS, 具体配置和操作见 [docker 部署 piclist](https://www.lvbibir.cn/posts/blog/docker-deploy-piclist)
2. 编辑完成后将通过 [此脚本](https://github.com/lvbibir/lvbibir.github.io/blob/master/update-file.sh) 将编辑后的文章更新到 hugo site 目录, 同时也是 git 仓库
3. 使用 `hugo server -D` 预览变更, 如有问题重复前两个步骤
4. 确认无误后通过 [此脚本](https://github.com/lvbibir/lvbibir.github.io/blob/master/upload-file.sh) 生成静态文件, 并将文件远程同步到公网服务器, 完成博客内容变更
5. 最后将 git 仓库的变更提交后同步到 github 远程仓库, 完成归档备份

其实如果使用 vscode 直接编辑 git 仓库中的博客文章可以让整个流程更加简化, 但是 vscode 的 markdown 编辑体验实在是比不上 typora 或者 obsidian, 工欲善其事必先利其器, 有了好的编辑体验才更愿意输出内容

# 3 twikoo

## 3.1 部署

twikoo 官方提供了 [丰富的部署方式](https://twikoo.js.org/quick-start.html), 考虑到访问速度, 本文使用的是 docker 方式部署到阿里云服务器

> 如果是使用本文章节 1 步骤中的配置文件部署了 twikoo, 这步直接忽略, 配置前端代码即可

```bash
docker run --name twikoo -e TWIKOO_THROTTLE=1000 -p 8080:8080 -v ${PWD}/data:/app/data -d imaegoo/twikoo
```

部署完成后看到如下结果即成功

```bash
[root@lvbibir ~]# curl http://localhost:8080
{"code":100, "message":"Twikoo 云函数运行正常, 请参考 https://twikoo.js.org/quick-start.html#%E5%89%8D%E7%AB%AF%E9%83%A8%E7%BD%B2 完成前端的配置", "version":"1.6.7"}
```

后续最好套上反向代理, 加上域名和证书

## 3.2 前端代码

创建或者修改 `layouts\partials\comments.html`

```html
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
            envId: "",  //填自己的, 例如：https://example.com
            el: "#tcomment", 
            lang: 'zh-CN', 
            path: window.TWIKOO_MAGIC_PATH||window.location.pathname, 
        });
    </script>
</div>
```

调用上述 twikoo 代码的位置：`layouts/_default/single.html`

```html
<article class="post-single">
  // 其他代码......
  {{- if (.Param "comments") }}
    {{- partial "comments.html" . }}
  {{- end }}
</article>
```

在站点配置文件 config 中加上版本号

```yaml
params:
	twikoo:
      version: 1.6.7
```

## 3.3 更新

1. 修改 dockerfile.yml 中的镜像 tag
2. 部署新版本容器 `docker-compose up -d`
3. 在 hugo 配置文件 config.yml 中修改 twikoo 版本

## 3.4 修改数据

直接修改 `blog/data/twikoo/` 目录下的文件后重启容器, ❗慎重修改

## 3.5 修改 smms 图床的 api 地址

> 已于 1.6.12 新版本修复, <https://github.com/imaegoo/twikoo/releases/tag/1.6.12>

由于 `sm.ms` 域名国内无法访问, ~~twikoo 官方还没有出具体的修改方式~~, 自己修改容器配置文件进行修改

```bash
# 复制配置文件
[root@lvbibir blog]# docker cp twikoo:/app/node_modules/twikoo-func/utils/image.js /root/blog/conf/twikoo/

# 修改配置文件, 原来的配置是 https://sm.ms/api.v2/upload
[root@lvbibir blog]# grep smms conf/twikoo/image.js
      } else if (config.IMAGE_CDN === 'smms') {
    const uploadResult = await axios.post('https://smms.app/api/v2/upload',  formData,  {

# 将配置文件映射进容器内, 重启容器即可
[root@lvbibir blog]# grep twikoo docker-compose.yml
  twikoo:
    image: imaegoo/twikoo
    container_name: twikoo
      - $PWD/data/twikoo:/app/data
      - $PWD/conf/twikoo/image.js:/app/node_modules/twikoo-func/utils/image.js
```

# 4 Artitalk

[官方文档](https://artitalk.js.org/doc.html)

需要注意的是如果使用的是国际版的 LeadCloud, 需要绑定自定义域名后才能正常访问

## 4.1 leancloud 配置

1. 前往 [LeanCloud 国际版](https://leancloud.app/), 注册账号
2. 注册完成之后根据 LeanCloud 的提示绑定手机号和邮箱
3. 绑定完成之后点击 `创建应用`, 应用名称随意, 接着在 `结构化数据` 中创建 `class`, 命名为 `shuoshuo`
4. 在你新建的应用中找到 `结构化数据` 下的 `用户` 点击 `添加用户`, 输入想用的用户名及密码
5. 回到 `结构化数据` 中, 点击 `class` 下的 `shuoshuo` 找到权限, 在 `Class 访问权限` 中将 `add_fields` 以及 `create` 权限设置为指定用户, 输入你刚才输入的用户名会自动匹配为了安全起见, 将 `delete` 和 `update` 也设置为跟它们一样的权限
6. 然后新建一个名为 `atComment` 的 class, 权限什么的使用默认的即可
7. 点击 `class` 下的 `_User` 添加列, 列名称为 `img`, 默认值填上你这个账号想要用的发布说说的头像 url, 这一项不进行配置, 说说头像会显示为默认头像 —— Artitalk 的 logo
8. 在最菜单栏中找到设置 -> 应用 keys, 记下来 `AppID` 和 `AppKey` , 一会会用
9. 最后将 `_User` 中的权限全部调为指定用户, 或者数据创建者, 为了保证不被篡改用户数据以达到强制发布说说
10. 在设置 ->域名绑定中绑定自定义域名

> ❗ 关于设置权限的这几步
> 这几步一定要设置好, 才可以保证不被 “闲人” 破解发布说说的验证

## 4.2 hugo 配置

新增 `content/talk.md` 页面, 内容如下, 注意修改标注的内容, front-matter 的内容自行修改

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
    appId: '**********',  // Your LeanCloud appId
    appKey: '************',  // Your LeanCloud appKey
    serverURL: '*********' // 绑定的自定义域名
})
</script>
</body>
```

这个时候已经可以直接访问了, `https://your.domain.com/talk`

输入 leancloud 配置步骤中的第 4 步配置的用户名密码登录后就可以发布说说了

# 5 自建不蒜子统计平台

[原版不蒜子](https://busuanzi.ibruce.info/) 是一个独立开发者免费提供给所有人使用的平台, 随着使用人数越来越多, 访问速度不尽如人意, 遂决定自建不蒜子平台

[自建不蒜子项目](https://github.com/soxft/busuanzi) [不蒜子迁移项目](https://github.com/soxft/busuanzi-sync)

## 5.1 部署

使用 docker compose 部署

```yaml
services:
  busuanzi-redis:
    image: "docker.1ms.run/library/redis:8.4.0-alpine3.22"
    container_name: busuanzi-redis
    restart: always
    ports:
      - "6379:6379" # 数据迁移完之后可以关闭端口
    volumes:
      - ./data/busuanzi-redis:/data

  busuanzi:
    image: "docker.1ms.run/xcsoft/busuanzi:v2.8.8"
    container_name: busuanzi
    restart: always
    ports:
      - "8080:8080"  # 我通过 Nginx 前端代理的, 所以数据迁移完之后直接关闭端口了
    links:
      - busuanzi-redis
    depends_on:
      - busuanzi-redis
    environment:
      WEB_LOG: true      # 是否开启日志
      WEB_DEBUG: false   # 是否开启debug模式
      WEB_CORS: "*"      # 跨域访问
      BSZ_EXPIRE: 0      # 统计数据过期时间 单位秒, 请输入整数 (无任何访问, 超过这个时间后, 统计数据将被清空, 0为不过期)
      BSZ_SECRET: "bsz"   # 签名密钥 // 请设置为任意长度的随机值
      API_SERVER: https://lvbibir.cn/busuanzi   # 填写你的 API 地址
      REDIS_ADDRESS: busuanzi-redis:6379  # redis 地址
      BSZ_PATHSTYLE: true
      BSZ_ENCRYPT: MD516
```

## 5.2 同步数据

```bash
wget https://github.com/soxft/busuanzi-sync/releases/download/v0.0.5/busuanzi-sync-linux-amd64-v0.0.5
chmod a+x busuanzi-sync-linux-amd64-v0.0.5

cat > .env <<-'EOF'
# 在此处指定您的博客 sitemap 地址
SITEMAP_URL: https://lvbibir.cn/sitemap.xml

# 线程数 避免过高导致 QPS 限制 / 不要超过5
THREADS: 2
# 单 URL 最大重试次数
MAX_RETRY: 10

REDIS_ADDR: 127.0.0.1:6379
REDIS_DB: 0
REDIS_PWD: ""
REDIS_PREFIX: bsz
REDIS_TLS: false

# 路径样式 与加密方案
BSZ_PATH_STYLE: true
BSZ_ENCRYPT: MD516
EOF

./busuanzi-sync-linux-amd64-v0.0.5
```

## 5.3 升级数据

```bash
wget https://github.com/soxft/busuanzi-transfer/releases/download/v0.0.4/busuanzi-transfer-linux-amd64-v0.0.4

cat > config.yaml <<-'EOF'
Redis:  
  Address: 127.0.0.1:6379  
  Password: ""  
  Database: 0  
  Prefix: "bsz"  
  ToPrefix: "bsz_transfer"
EOF

./busuanzi-transfer-linux-amd64-v0.0.4
```

## 5.4 手动更新站点数据

按理说这一步是不需要的, 但是我升级完数据之后文章页的访问数据是正常的, 站点的 pv 和 uv 还是没有, 所以这里手动更新一下数据, pv 和 uv 的数据手动从原版不蒜子获取.

```bash
docker exec -it busuanzi-redis /bin/sh
redis-cli -h 127.0.0.1 -p 6379
SET bsz:site_pv:f4a42bbb359a9e01 "91750"
EVAL "redis.call('DEL', KEYS[1]); for i=1,tonumber(ARGV[1]) do redis.call('PFADD', KEYS[1], 'u-'..i) end; return redis.call('PFCOUNT', KEYS[1])" 1 bsz:site_uv:f4a42bbb359a9e01 55649
```

## 5.5 使用

见 6.3

# 6 自定义 footer

自定义页脚内容

![image-20220911150229930](https://image.lvbibir.cn/blog/image-20220911150229930.png)

> 添加完下面的页脚内容后要修改 `assets\css\extended\blank.css` 中的 `--footer-height` 的大小, 具体数字需要考虑到行数和字体大小

## 6.1 自定义徽标

> 徽标功能源自：<https://shields.io/>
> 考虑到访问速度, 可以在生成完徽标后放到自己的 cdn 上

在 `layouts\partials\footer.html` 中的 `<footer>` 添加如下

```html
<a href="https://gohugo.io/" target="_blank">
    <img src="https://img.shields.io/static/v1?&style=plastic&color=308fb5&label=Power by&message=hugo&logo=hugo" style="display: unset;">
</a>
```

## 6.2 网站运行时间

在 `layouts\partials\footer.html` 中的 `<footer>` 添加如下

起始时间自行修改

```html
    <span id="runtime_span"></span> 
    <script type="text/javascript">function show_runtime(){window.setTimeout("show_runtime()", 1000);X=new Date("7/13/2021 1:00:00");Y=new Date();T=(Y.getTime()-X.getTime());M=24*60*60*1000;a=T/M;A=Math.floor(a);b=(a-A)*24;B=Math.floor(b);c=(b-B)*60;C=Math.floor((b-B)*60);D=Math.floor((c-C)*60);runtime_span.innerHTML="网站已运行"+A+"天"+B+"小时"+C+"分"+D+"秒"}show_runtime();</script>
```

## 6.3 访问人数统计

统计数据源于自建的不蒜子平台, 见 章节 5

全站数据统计, 修改 `layouts\partials\footer.html`

```html
<footer>
    <!-- 添加如下行 -->
    <script defer src="https://lvbibir.cn/busuanzi/js"></script>
    <span id="busuanzi_container">
        总访客数: <span id="busuanzi_site_uv"></span>
        |
        总访问量: <span id="busuanzi_site_pv"></span>
    </span>
</footer>
```

文章页数据统计

```html
<div class="post-meta">
    <!-- 添加如下三行 -->
    <span id="busuanzi_container_page_pv">
        &nbsp;|&nbsp;访问:&nbsp;<span id="busuanzi_page_pv"></span>
    </span>
<div class="post-meta">
```

# 7 自定义字体

可以使用一些在线的字体, 可能会比较慢, 推荐下载想要的字体放到自己的服务器或者 cdn 上

修改 `assets\css\extended\fonts.css`, 添加 `@font-face`

```css
@font-face {
    font-family: "LXGWWenKaiLite-Bold";
    src: url("https://your.domain.com/fonts/test.woff2") format("woff2");
    font-display: swap;
}
```

修改 `assets\css\extended\blank.css`, 推荐将英文字体放在前面, 可以实现英文和中文使用不同字体

```css
.post-content {
    font-family: Consolas,  "LXGWWenKaiLite-Bold"; //修改
}

body {
    font-family: Consolas,  "LXGWWenKaiLite-Bold"; //修改
}
```

# 8 修改链接颜色

在 hugo+papermod 默认配置下, 链接颜色是黑色字体带下划线的组合, 个人非常喜欢 [typora-vue](https://github.com/blinkfox/typora-vue-theme) 的渲染风格 [hugo官方文档](https://gohugo.io/templates/render-hooks/#link-with-title-markdown-example) 给出了通过 `render hooks` 覆盖默认的 markdown 渲染 link 的方式

新建 `layouts/_default/_markup/render-link.html` 文件, 内容如下在官方给出的示例中添加了 `style="color:#42b983`, 颜色可以自行修改

```html
<a href="{{ .Destination | safeURL }}"{{ with .Title}} title="{{ . }}"{{ end }}{{ if strings.HasPrefix .Destination "http" }} target="_blank" rel="noopener" style="color:#42b983";{{ end }}>{{ .Text | safeHTML }}</a>
```

# 9 shortcode

[ppt、bilibili、youtube、豆瓣阅读和电影卡片](https://www.sulvblog.cn/posts/blog/shortcodes/)

[mermaid](https://www.sulvblog.cn/posts/blog/hugo_mermaid/)

[图片画廊](https://github.com/liwenyip/hugo-easy-gallery/)

# 10 其他修改

其他 css 样式修改基本都是通过 f12 控制台一点点摸索改的, 不太规范且比较琐碎就不单独记录了, ~~其实我根本已经忘记还改了哪些东西~~

以上
