---
layout: post
title: 近期开发内容
lang: zh
permalink: /2016-05-31/recent-development/
---

最近主要是实现之前PACKMAN所具有的一些基本功能，同时测试预编译包系统，主要是完成如下设计：

- 默认使用`/opt/starman/software`作为安装根目录，只有使用该目录才能使用预编译包，其它目录需本地编译；
- 使用SHA256来构造软件包安装路径`prefix`，里面包含操作系统、编译器、编译设置信息，这样做的原因是去除之前`prefix`中含有的编译器集合编号，因为该编号可能会变化，而路径信息是嵌入到编译的文件中，一定不能变；
- 增加`shell`命令，用来开启一个子shell，其中的环境变量（如`PATH`、`LD_LIBRARY_PATH`等）都是设置正确，同时也与默认shell环境的隔离。

尚未解决的难点：

- 同一个软件包可能采用不同的编译配置编译，如何通过`shell`命令来切换？