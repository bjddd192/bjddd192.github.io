---
layout: "post"
title: "Mac GitBook安装和使用"
date: "2018-08-29 10:59:59"
description: Mac GitBook安装和使用
categories: GitBook
tags: GitBook
keywords: Mac, GitBook, Mac GitBook安装和使用
---

在认识 `GitBook` 之前，我主要是用 Word 来记录大型的知识，但是随着日积月累，Word 文档会越来越大，而用 Word 文档不利于版本的管理，也不方便携带，老是会担心丢失，也不利于分享，因此希望能够像写代码的方式一样来记录文档，形成自己的知识库。

GitBook 是一个非常优秀，容易上手的电子书制作工具，同时支持 Markdown 语法，与博客相比，更适合进行一些大型知识体系的整理与分享。

目前正好有这方面的需求，而手头上又有 Mac 神器，在网上撸来一圈下来，也带着自己的不少问题经过了一番折腾，最终记录了此文档。




### GitBook 安装

从[官网](https://nodejs.org/en/download/)下载 LTS 稳定版本(.pkg 的安装文件)

然后双击进行安装即可，安装完成后，在命令行执行：

```sh
# 检查 npm 版本
npm -v
# 检查 node 版本
node -v
# 安装 gitbook-cli
sudo npm install -g gitbook-cli
# 检查 gitbook 版本
gitbook --version
gitbook -V
# 查看 gitbook 帮助
gitbook help
# 更新 gitbook
# gitbook update
# 卸载 gitbook
# npm uninstall -g gitbook
```

### 安装 GitBook Editor

官方编辑器

[下载地址](https://legacy.gitbook.com/editor)

由于需要翻墙才能连，软件又没有代理功能，用起来比较麻烦，暂不推荐使用。我是继续使用 Atom 神器进行文档的编写。

### Gitbook 官网与 Github 集成

[与 Github 集成](https://docs.gitbook.com/integrations/github)

尝试后发现就是用 Github 的账号在 Gitbook官网 注册，然后将 Github 构建项目与 Gitbook 项目进行绑定即可，最后在本地拉取 Github 项目进行电子书的编辑即可。

但是目前 Gitbook 新版本免费账号只支持 1 个公共仓库，而且不支持自定义的插件展示，而收费版太贵，而且要绑定信用卡，因此暂不考虑花这个钱，后续有需求再考虑。理论上使用付费版本与 Github 集成是最佳方案，因为两边都可以对项目进行编辑，自动同步，非常方便。

在尝试阶段，建议不用去 Gitbook 官网浪费时间了，等用习惯有需要了再考虑集成到 Gitbook 官网。

### 初始化书籍

在 Github 新建一个代码仓库，然后 `git clone` 下来，并使用 `gitbook init` 进行初始化：

```sh
cd /Users/yanglei/01_git/github_me
git clone git@github.com:bjddd192/declaimer.git
cd /Users/yanglei/01_git/github_me/declaimer
gitbook init
```

### 配置书籍

配置书籍其实就是配置 book.json 文件的过程。具体参数的意义网上有很多资料，不复杂，配置之前先找资料看看，就可以了。

可能每个项目最不同的就是使用的插件不同，关于插件的使用，需要自己花点时间去看看插件的资料，或者根据别人的插件配置去搜索插件的详细配置，这里给出官方插件的传送门：

[GitBook Plugins](https://plugins.gitbook.com)

### 编译书籍

当配置好书籍以后，需要用命令安装插件，并编译成静态资源：

```sh
gitbook install
gitbook build
```

### 本地发布书籍

```sh
gitbook serve
```

使用上面的命令进行本地发布，然后访问：http://localhost:4000 即可看到本地发布的电子书效果了。

### 公网发布书籍

我们写的电子书，很多时候都希望能够随时随地浏览，并方便地分享给其他人，这样就需要考虑将电子书发布到公网了。

我搜了一堆资料了解了一下，大概有几种方式（推荐使用第四种方式）：

1. 发布到 Gitbook，优点是绑定 Github 即可，官方支持，集成度最高，缺点是要付费，还有可能被墙，所以只能先呵呵了。
2. 发布到 [看云](https://www.kancloud.cn/)，优点是平台化，如果发布的是优质资源，可以通过看云平台推广并获利，缺点是仓库多了也要收费，仓库空间大小也有限制，但是比老外的要便宜很多，如果代码托管在 Github，与[看云](https://www.kancloud.cn/)的代码需要 Git 处理多源同步推送。这个适合直接在[看云](https://www.kancloud.cn/)进行以盈利为目的的创作，暂时不符合我的需求，先略过，后续有需求可以考虑它。
3. 发布到私人的服务器，这个当然是可行的，优点不受任何约束，当然前提是要有一台公网的服务器，缺点是存在服务器的运维成本。
4. 利用 Github 发布，原理是每个 Github 的仓库可以创建 `gh-pages 分支`，任何通过 `github page/你项目的名称` 就可以访问到那个分支的静态文件。优点是仓库个数、资源不受限制，可以与现有博客域名结合使用，缺点是使用的是公共仓库，因此书籍是开源的，不适合知识产权的保护。因为目前我整理的资料是希望开源的，所以我推荐大家构建开源书籍时开源采用此方式。

利用 Github 发布，还有个麻烦就是如何将电子书推送到 gh-pages 分支，有大神推荐使用 `grunt`，[传送门在此](https://skyao.io/learning-gitbook/publish/github.html)。不过由于我对 `grunt` 不熟，故没有采纳，后续有需要再使用。

我使用的方式是使用脚本直接操作 git，个人觉得这种方式比较直接、好理解，缺点是在执行脚本前要记得先将代码全部提交推送远端，然后在文本编辑器中打开的项目文件也要全部关闭，因为脚本过程中会切换分支，并且包含了删除文件的操作，这样做的目的是防止文件未提交而丢失。当然，注意一下就好了，目前我使用的就是这种方式，感觉还挺顺手，发布速度也挺快。下面是使用的脚本：

```sh
#! /bin/bash

# 编译构建 gitbook
gitbook install
gitbook build
# 查远程分支
# git branch -r
# 删除本地 gh-pages 分支
git branch -D gh-pages
# 删除远端的 gh-pages 分支
git branch -r -d origin/gh-pages
git push origin :gh-pages
# 创建新的 gh-pages 分支
git checkout --orphan gh-pages
# 发布文件，整理与推送
git rm -f --cached -r .
sleep 5
git clean -df
sleep 5
# rm -rf *~
# echo "*~" > .gitignore
echo "_book" >> .gitignore
echo "node_modules" >> .gitignore
git add .gitignore
git commit -m "Ignore some files"
cp -r _book/* .
git add .
git commit -m "Publish book"
# 推送 gh-pages 分支
git push -u origin gh-pages
# 切回 master 分支
git checkout master
```

### 转换 PDF

电子书写完后，可以转换成 PDF 格式的文件，方便一些私密文件的分享，或者在不能上网的环境下查看，操作却是很简单。

首先，下载 [calibre 插件](https://calibre-ebook.com/download_osx)

然后，双击进行安装即可，安装完成后，在命令行执行脚本：

```sh
# 创建软链接
ln -s /Applications/calibre.app/Contents/MacOS/ebook-convert /usr/local/bin

# 导出 PDF
gitbook pdf /Users/yanglei/01_git/github_me/declaimer /Users/yanglei/Downloads/declaimer.pdf
```

### 书籍编写技巧

这个需要日积月累，大家慢慢体验，有好的方法我会再补充。

### 尾声

看完这个文档，希望大家立刻构建一个电子书项目来尝试一下，内容不重要，重要的是理清楚使用的流程。然后就只剩下慢慢享受书写、积累资料的快乐过程了。相信这样的习惯会对你有积极的影响。

如果大家有问题，可以参考一下我的电子书项目：https://www.zorin.xin/declaimer/

Github 仓库地址：https://github.com/bjddd192/declaimer/tree/gh-pages

或者，与我联系。

### 参考资料

[使用 Gitbook 打造你的电子书](https://blog.csdn.net/stu059074244/article/details/77767835)

[GitBook使用入门](https://www.imooc.com/article/details/id/30528)

[GitBook 使用](https://wuxiaolong.gitbooks.io/wuxiaolong/GitBookGuide.html)

[GitBook使用指南](https://www.kancloud.cn/xiaoyulive/gitbook)

[GitBook Plugins](https://plugins.gitbook.com)

[GitBook 插件](http://gitbook.zhangjikai.com/plugins.html)

---

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [Mars丶小石头](https://www.zorin.xin) 所有。