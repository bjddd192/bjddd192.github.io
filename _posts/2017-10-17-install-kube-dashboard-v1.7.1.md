---
layout: post
title: install kubernetes-dashboard v1.7.1
date: 2017-10-17 17:41:30 +0800
description: 安装 kubernetes-dashboard v1.7.1
categories: kubernetes
tags: dashboard
keywords: kubernetes dashboard
---

* content
{:toc}

在部署完heapster后，发现看板的监控数据一直上不来，而grafana中能够正常展示数据

![grafana](/assets/2017-10-16-install-kube-heapster-v1.4.0/grafana.jpg)




### 一、git 仓库整理

我首先将我的 git 仓库做了一次整理，将其放置到了同一个目录，并按照仓库来源进行了分类，之前的 git 仓库东一个西一个，东西多了很不好找。整理了以后看起来舒服多了，效果如下：

``` bash
D:\01_git
├─github
│  ├─bjddd192.github.io
│  ├─dongchuan.github.io
│  ├─gaohaoyang.github.io
│  └─mritd.github.io
├─gitlab
│  ├─eyd-om-docker
│  ├─eyd-om-docker.wiki
│  ├─eyd-om-private
│  ├─eyd-om-private.wiki
│  ├─eyd-om-resources
│  └─eyd-om-resources.wiki
└─oschina
    ├─doc
    └─shell
```

### 二、git_pull_all.sh

不废话，直接上脚本：

``` sh
#!/bin/bash

# 获取 git 仓库路径
find `pwd` -type d -name ".git" > git_dir.txt
sed -i "s/\/.git/\//g" git_dir.txt

# 循环文件中的路径拉取数据
while read LINE
do
	echo $LINE
	cd "$LINE"
	git pull
done < git_dir.txt
```

将此脚本放置在根目录（如：D:\01_git）下，然后在 git bash 中执行即可实现批量拉取功能。

### 三、注意事项

**这里放置的 git 仓库都要是可以免密获取的，如使用 ssh 协议或者 https 的公共仓库。**

---

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [ん乖乖龙ん](https://bjddd192.github.io) 所有。
