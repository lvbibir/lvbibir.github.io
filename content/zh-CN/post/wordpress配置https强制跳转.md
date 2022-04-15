本文介绍如何在阿里轻量服务器wordpress站点配置http强制跳转到https

配置强制跳转前需要站点已经安装了ssl证书，可以通过https正常访问

[[阿里云wordpress配置免费ssl证书](https://lvbibir.cn/archives/245)]

一般站点需要在httpd.conf中的`<VirtualHost *:80> </VirtualHost>`中配置重定向

与一般站点不同，wordpress需要在伪静态文件（.htaccess）中配置重定向，无需在httpd.conf中配置

# 修改伪静态文件（.htaccess）

伪静态文件一般在网页根目录，是一个隐藏文件

![image-20210730101401874](https://image.lvbibir.cn/blog/image-20210730101401874.png)

在`#END Wordpress`前添加如下重定向代码，**记得把域名修改成自己的**

```
RewriteEngine On
RewriteCond %{HTTPS} !on
RewriteRule ^(.*)$ https://lvbibir.cn/%{REQUEST_URI} [L,R=301]
```

图中两段重定向代码略有不同

- 第一段代码重定向触发器：**当访问的端口不是443时进行重定向**重定向规则：**重定向到：https://{原域名}/{原url资源}**
- 第二段代码重定向触发器：**当访问的协议不是 TLS/SLL（https）时进行重定向**重定向规则：**重定向到：https://lvbibir.cn/{原url资源}**
- 第一段代码使用端口判断，第二段代码通过访问方式判断，建议使用访问方式判断，这样服务改了端口也可以正常跳转
- 第一段代码重定向的原先的域名，第二段代码可以把ip地址重定向到指定域名

![image-20210730152548351](https://image.lvbibir.cn/blog/image-20210730152548351.png)

# 测试

```
curl -I http://lvbibir.cn
```

![image-20210730153518000](https://image.lvbibir.cn/blog/image-20210730153518000.png)

使用http访问站点的80端口成功通过301跳转到了https

# 参考

https://help.aliyun.com/document_detail/98727.html?spm=5176.smartservice_service_chat.0.0.1508709aJMmZwg

https://blog.csdn.net/weixin_39037804/article/details/102801202