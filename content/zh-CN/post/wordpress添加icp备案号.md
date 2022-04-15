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

