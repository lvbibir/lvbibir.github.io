# Picgo配置完七牛云图床，使用typora测试图片上传

![image-20210721100740621](https://image.lvbibir.cn/blog/image-20210721100850294.png)

# 报错：failed to fetch

![image-20210721100850294](https://image.lvbibir.cn/blog/image-20210721102004403.png)

# 看日志

日志路径：C:\Users\lvbibir\AppData\Roaming\picgo

问题在于端口冲突，如果你打开了多个picgo程序，就会端口冲突，picgo自动帮你把36677端口改为366771端口，导致错误。log文件里也写得很清楚。

![image-20210721102004403](https://image.lvbibir.cn/blog/image-20210721101018536.png)

# 解决

修改picgo的监听端口

![image-20210721100946278](https://image.lvbibir.cn/blog/image-20210721100946278.png)

![image-20210721101018536](https://image.lvbibir.cn/blog/image-20210721101039272.png)

# 重新验证

![image-20210721101039272](https://image.lvbibir.cn/blog/image-20210721100740621.png)

