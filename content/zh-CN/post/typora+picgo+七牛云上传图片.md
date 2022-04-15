# 七牛云配置
## 1、注册七牛云，新建存储空间

这里就不介绍七牛云的注册和新建空间了

七牛云新用户有10G的免费空间，作为个人博客来说基本足够了

![image-20210722105644661](https://image.lvbibir.cn/blog/20210722121825.png)

## 2、为存储空间配置加速域名

![image-20210722105809443](https://image.lvbibir.cn/blog/20210722121826.png)

这里使用http就可，https还需要证书，有点麻烦

![image-20210722110411130](https://image.lvbibir.cn/blog/20210722121827.png)

## 3、配置域名解析

![image-20210722110659897](https://image.lvbibir.cn/blog/20210722121828.png)

到域名厂商配置cname记录，我的域名是阿里的

在控制台首页进入dns配置

![image-20210722110816158](https://image.lvbibir.cn/blog/20210722121829.png)

![image-20210722110858518](https://image.lvbibir.cn/blog/20210722121830.png)

配置cname

![image-20210722111023745](https://image.lvbibir.cn/blog/20210722121831.png)

# PicGo配置

## 下载安装

下载链接：https://github.com/Molunerfinn/PicGo/releases/

建议下载稳定版

![image-20210722111913493](https://image.lvbibir.cn/blog/20210722121832.png)

## 配置七牛云图床

主流图床都有支持

![image-20210722111948353](https://image.lvbibir.cn/blog/20210722121833.png)

配置七牛图床

![image-20210722121639391](https://image.lvbibir.cn/blog/20210722121834.png)

ak和sk在七牛云→个人中心→密钥管理中查看

![image-20210722112127613](https://image.lvbibir.cn/blog/20210722121835.png)

# typora测试图片上传

下载地址：https://www.typora.io/

在文件→偏好设置→图像中配置图片上传，选择安装好的PicGo的应用程序

![image-20210722112417378](https://image.lvbibir.cn/blog/20210722121836.png)

点击验证图片上传

![image-20210722112645385](https://image.lvbibir.cn/blog/20210722121837.png)

到七牛云存储空间看是否有这两个文件

![image-20210722112812563](https://image.lvbibir.cn/blog/20210722121838.png)

typora可以实现自动的图片上传，并将本地连接自动转换为外链地址

![image-20210722121155935](https://image.lvbibir.cn/blog/20210722121839.png)

![image-20210722121519040](https://image.lvbibir.cn/blog/20210722121519.png)



