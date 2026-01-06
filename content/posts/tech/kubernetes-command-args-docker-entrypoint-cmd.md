---
title: "kubernetes |  command args 和 dockerfile 中的 ENTRYPOINT CMD" 
date: 2023-04-12
lastmod: 2024-01-28
tags:
  - kubernetes
  - docker
keywords:
  - kubernetes
  - docker
  - entrypoint
description: "" 
cover:
    image: "images/cover-kubernetes.png"
---

# 1 command args

- 如果指定了 containers.command，Dockerfile 中的 ENTRYPOINT 会被覆盖且 CMD 指令被忽略
- 如果指定了 containers.args，Dockerfile 中的 ENTRYPOINT 继续执行， CMD 指令 被覆盖

| ENTRYPOINT | CMD            | command   | args           | finally      |
| ---------- | -------------- | --------- | -------------- | ------------ |
| ["/ep1"]   | ["foo", "bar"] | <not set> | <not set>      | ep-1 foo bar |
| ["/ep1"]   | ["foo", "bar"] | ["/ep-2"] | <not set>      | ep-2         |
| ["/ep1"]   | ["foo", "bar"] | <not set> | ["zoo", "boo"] | ep-1 zoo boo |
| ["/ep1"]   | ["foo", "bar"] | ["/ep-2"] | ["zoo", "boo"] | ep-2 zoo boo |

# 2 CMD ENTRYPOINT

我们大概可以总结出下面几条规律：

- 如果 ENTRYPOINT 使用了 shell 模式，CMD 指令会被忽略。
- 如果 ENTRYPOINT 使用了 exec 模式，CMD 指定的内容被追加为 ENTRYPOINT 指定命令的参数。
- 如果 ENTRYPOINT 使用了 exec 模式，CMD 也应该使用 exec 模式。

还有一点需要注意，如果使用 `docker run --entrypoint` 覆盖了 Dockerfile 中的 ENTRYPOINT , 同时 CMD 指令也会被忽略

真实的情况要远比这三条规律复杂，好在 docker 给出了 [官方的解释](https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact)，如下图所示：

![image-20230410160304323](/images/image-20230410-160304.png)

以上