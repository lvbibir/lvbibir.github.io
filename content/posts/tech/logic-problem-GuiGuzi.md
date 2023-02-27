---
title: "逻辑题 | 鬼谷子数学问题" 
date: 2023-02-27
lastmod: 2023-02-27
tags: 
- python
keywords:
- math
- python
description: "一道乍看毫无逻辑，细想却很有趣的逻辑题"  
cover:
    image: "https://image.lvbibir.cn/blog/guiguzi.png" 
    hidden: true
    hiddenInSingle: true
---

原题如下

>鬼谷子随意从2-99中选取了两个数。他把这两个数的和告诉了庞涓， 把这两个数的乘积告诉了孙膑。但孙膑和庞涓彼此不知道对方得到的数。第二天， 庞涓很有自信的对孙膑说：虽然我不知道这两个数是什么，但我知道你一定也不知道。随后，孙膑说：那我知道了。庞涓说：那我也知道了。这两个数是什么？

代码示例

```python
#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
第一步
庞告诉孙，已知和Sum满足有至少两种ab组合，且任意一组ab的乘积Pro都满足至少有两种ab组合，通过isPang函数将可能的ab组合放入abList_1
第二步
孙告诉庞，abList_1中的ab组合乘积得pro，该pro满足至少有两种ab组合，且所有的ab组合有且仅有一组ab组合满足isPang函数，通过isSun函数将abList中满足条件的ab组合放入abList_2，ab组合的积放入proList
第三步
庞告诉孙，abList_2中的ab组合相加得Sum，该Sum满足至少有两种ab组合，且所有的ab组合有且仅有一组ab所得乘积pro在proList中，将满足条件的ab组合放入abList，即最终答案
'''

# 根据给出的sum，遍历所有可能的a和b的组合
def getCombinationSum(sum):
    combination = []
    for a in range(2, 100):
        for b in range(2, 100):
            if a + b == sum and a <= b:
                combination.append((a, b))
    return combination


# 根据给出的pro，遍历所有可能的a和b的组合
def getCombinationPro(pro):
    combination = []
    for a in range(2, 100):
        for b in range(2, 100):
            if a * b == pro and a <= b:
                combination.append((a, b))
    return combination


def isPang(sum):
    '''
    第一步，传入的sum满足以下条件返回True，否则False:
    1. 可以拆分成若干组ab的加和
    2. 每一组拆分出来的ab乘积运算得pro，该pro满足有至少两组ab的乘积
    '''
    if len(getCombinationSum(sum)) < 2:
        return False
    else:
        combinationSum = getCombinationSum(sum)
        for i in combinationSum:
            status = 0
            pro = i[0] * i[1]
            # 有其中一组ab不满足就打断循环
            if len(getCombinationPro(pro)) < 2:
                status = 1
                break
    if status == 0:
        return True
    else:
        return False


def isSun(pro):
    '''
    第二步，传入的pro满足以下条件返回一组ab组合(元组)，否则False
    1. 可以拆分成若干组ab的乘积
    2. 每一组拆分出来的ab相加运算得sum，所有ab加和的sum有且仅有一个满足第一步的条件(放入isPang函数后返回True)
    '''
    combination = []
    combinationPro = getCombinationPro(pro)
    if len(combinationPro) > 1:
        for i in combinationPro:
            sum = i[0] + i[1]
            if isPang(sum):
                combination.append(i)
    if len(combination) == 1:
        return combination
    else:
        return False


if __name__ == '__main__':

    # 第一步
    abList_1 = []
    for sum in range(4, 198+1):
        if isPang(sum):
            abList_1 += getCombinationSum(sum)

    # 第二步
    abList_2 = []
    proList = []
    for i in abList_1:
        pro = i[0] * i[1]
        if isSun(pro):
            abList_2.append(i)
            proList.append(pro)

    # 第三步
    abList = []
    for i in abList_2:
        sum = i[0] + i[1]
        n = 0
        for j in getCombinationSum(sum):
            if j[0] * j[1] in proList:
                n += 1
        if n == 1:
            abList.append(i)
    print(abList)
```

