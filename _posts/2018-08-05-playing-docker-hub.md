---
layout: "post"
title: "玩转 Docker Hub"
date: "2018-08-05 10:32:02"
description: 介绍并记录一些 docker hub 中的常用玩法
categories: docker
tags: docker
keywords: docker, docker hub
---

刚接触 docker 时就有注册 [Docker Hub](https://hub.docker.com/) 这个官方的 docker 仓库，我习惯叫它 docker 公仓，主要的目的当然就是去下载一个个需要的官方镜像了。随着时间的推移，也发现它有不少的好处，下面说一说我主要接触过的玩法。




## 修改 Docker Hub 上的头像

参考博客文章：[如何修改 Docker Hub 上的头像](https://my.oschina.net/CianLiu/blog/835275)

具体总结步骤如下：

1. 在 [Docker Account Settings](https://hub.docker.com/account/settings/) 中设置 `Primary Email Addresses`；
2. 在 [Gravatar](https://cn.gravatar.com/) 使用这个`Primary Email Addresses` 注册一个账号，并上传你的头像上去；
3. 刷新你的 Docker Hub，发现头像已经变成你上传的了，大功告成。

通过此步骤，我已成功用上了自定义的头像，参见：[我的 Hub 仓库](https://hub.docker.com/r/bjddd192/)。

比原生灰溜溜的头像爽太多了，心动的你赶快行动起来吧，几分钟就搞定了。

## 推送镜像到 Docker Hub

## 创建 AUTOMATED BUILD 的镜像

---

未完待续，部分内容待后续添加。

---

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [Mars丶小石头](https://www.zorin.xin) 所有。