文章编辑界面和预览界面都是没问题的，发布出来后文章内容的http变成了https，而且仅有本博客域名lvbibir.cn出现这种情况，其他都正常

![image-20210730141923357](https://image.lvbibir.cn/blog/image-20210730141923357.png)

发布后：

![image-20210730141947018](https://image.lvbibir.cn/blog/image-20210730141947018.png)

初步判断是由于在wordpress的伪静态文件中配置了http强制跳转导致的

![image-20210730142044368](https://image.lvbibir.cn/blog/image-20210730142044368.png)

