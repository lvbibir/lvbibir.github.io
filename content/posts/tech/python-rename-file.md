---
title: "python批量修改目录下文件名" 
date: 2022-07-27
lastmod: 2022-07-27
tags: 
- python
keywrods:
- windows
- python
description: "将windows中某个目录下的所有文件中的下划线_替换为中划线-" 
cover:
    image: "" 
---

示例代码

```python
import os

# 输入文件夹地址
path = "C://Users//lvbibir//Desktop//lvbibir.github.io//content//posts//read//"
files = os.listdir(path)

# 输出所有文件名，只是为了确认一下
for file in files:
    print(file)

# 获取旧名和新名
i = 0
for file in files:
    # 旧名称的信息
    old = path + os.sep + files[i]
    # 新名称的信息
    new = path + os.sep + file.replace('_','-')
    # 新旧替换
    print(new)
    os.rename(old,new)
    i+=1
```

