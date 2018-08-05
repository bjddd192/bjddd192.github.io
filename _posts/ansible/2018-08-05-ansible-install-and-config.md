---
layout: "post"
title: "ansible 安装与配置"
date: "2018-08-05 12:29:21"
description: 记录 ansible 安装与配置的详细过程
categories: ansible
tags: ansible
keywords: ansible
---

学习与使用 ansible 已经有大约半年时间了，基本已经上手了，这期间改造了 [gjmzj/kubeasz](https://github.com/gjmzj/kubeasz) 项目，主要使用 mac + atom 完成，好处是 mac 上用 atom 编写 ansible 工程非常方便美观，与 sourceTree 结合管理源码更是天衣无缝；也做了一些其他项目，如 mysql、大数据相关组件的一键部署。通过这些项目的锤炼，让我感到前所未有的快乐，也看到了 ansible 这款神器的魅力，它能汇聚我们部署中的经验，并模版化，这样整个安装的过程就可控了，不会换一个人安装就有不同的玩法，更方便管理了，另外就是它的快速部署大大节约了运维人员的时间，而且准确度也大大提升了。未来的我已经认准了 ansible 阵营，因此准备整理一个系列来记录我所涉及到的整个 ansible 工具使用过程。下面，就从 ansible 的安装与配置开始吧。




## Mac 安装 ansible

## CentOS7 安装 ansible

```sh
yum -y install epel-release
yum -y install ansible
```

## 参考资料

[how-to-install-and-configure-ansible-on-centos-7](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-ansible-on-centos-7)



---

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [Mars丶小石头](https://www.zorin.xin) 所有。