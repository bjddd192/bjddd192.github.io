---
layout: post
title: 使用jekyll搭建blog
date: 2017-02-20 22:39:30 +0800
description: 使用jekyll搭建免费的个人blog 
categories: 博客技术
tags: jekyll blog
keywords: jekyll blog
---

### 初识 jekyll 

使用 jekyll 搭建 blog 已经有一周的时间了，最初的想法源于看见了网友兄弟 **[漠然](https://mritd.me/)** 的 blog，当时觉得非常的惊艳，厚着脸皮 Q 了他，他非常的大方地把 jekyll 推荐给了我，我立马就去查了一些相关资料，感觉这就是我想要的博客工具，经过了好几天的折腾，这款工具终于被我用上手了，再次感谢 **[漠然](https://mritd.me/)** ，真是一个好人。




### 使用 jekyll 写 blog 的优势

这里先谈一下我总结的 jekyll 的优势所在：

1、从搭建的整个博客的架构来看： jekyll 简单，纯静态，无需数据库支持，代码全开放，自由度高。对于前端水平高的同学完全可以按自己的想法去布局博客，而对于前端水平低或者根本不会前端技术的同学也不用灰心，可以去下载一个喜欢的主题即可，在后面会再仔细说一下怎么玩。 

2、从写作来看：在博客架构搭建好以后，博主可以不用再关心博客其他的地方，只需要按部就班地在固定的文件夹中专注书写自己的文章即可。语法上支持 markdown 语法，书写简单规范，转换 html 页后，浏览赏心悦目，关键字、代码高亮显示，排版整齐，非常适合开发人士使用，也是现在的主流。

3、从博客发布来看：发布到 github 完全免费，稳定可靠，省去了租赁域名、主机的麻烦，而且非常简单，就是 git 的日常操作，并且支持本地发布和远程发布，响应速度极快，文章发布后立马可以分享给其他人阅读。

4、从安全性来看：采用 git 的方式管理整个博客，可以追溯历史版本，不用担心数据丢失。

5、从便携性来看：可以使用电脑、手机、 iPad 随时随地地书写浏览，也有非常多的优秀的写作工具支持，比如 Visual Studio Code 、 Atom 、 作业部落 、 Day One 、 有道云笔记 等等。

以上这些优势可以让博主将知识积累与博客发布的事情融为一体，更能坚持将博客持续地写下去。

### 环境搭建

下面我们就来看看要怎么样才能把环境搭起来，我在搭建的时候也遇到很多问题，花费了不少时间，因此总结记录下来，希望能够帮助更多的人。

#### 环境准备

> 操作系统：windows7

> 可用的翻墙代理软件（在你的网络访问没有受到限制前可以先忽略）：例如 goagent，蓝灯等，在这里不介绍如何使用翻墙软件，还没有的话请百度解决，这个很重要，确保我们下载资源的时候畅通无阻。

> ruby 运行环境：RailsInstaller，建议用 3.2.1 的版本， 本人之前使用 3.3 的版本在配置 ruby 运行环境时包之间总是报依赖错误。   
[官方下载](https://s3.amazonaws.com/railsinstaller/Windows/railsinstaller-3.2.1.exe)    
 [百度网盘下载](http://pan.baidu.com/s/1hsp543M)

> markdown 编辑工具：[Visual Studio Code](http://code.visualstudio.com/docs/?dv=win)，也可以使用 Atom 等其他工具，这个看个人习惯，只是用来写作。

> git 源码管理工具，如果你还没有 git 使用基础，建议先学习 [廖雪峰的 git 教程](http://www.liaoxuefeng.com/wiki/0013739516305929606dd18361248578c67b8067c8c017b000) ，这个 **相当的基础** ，常用的操作一定要会。    
git 翻墙请参考： [Git代理设置](/git/2017/02/13/Git代理设置.html)

> 在 [github](https://github.com/) 注册一个帐号，并建立一个代码仓库，名为 username.github.io （固定格式，username与账号名一致），这个代码仓库就是你的博客源码存放地，你的博客公网链接就是： https://username.github.io 。我们新建的仓库没有任何的内容，这时我们先使用 git 将其 clone 到本地的一个目录（username.github.io）待用。

> 注册以下网站的帐号：   
[多说](http://duoshuo.com/)   
[百度统计](http://tongji.baidu.com/)    
[Google Analytics](http://www.google.com/analytics/)

建议先使用与本人类似的 windows 环境进行搭建，成功后可以举一反三，应用到 Linux 、Mac 系统是很简单的事情了。

#### 搭建步骤

##### 安装 ruby 环境

双击 RailsInstaller 安装包，启动 ruby 安装向导，一直下一步直到完成即可。

安装完成后，可以打开 cmd 进行验证一下，拿到版本信息，如：

``` sh
ruby -v
ruby 2.2.6p396 (2016-11-15 revision 56800) [i386-mingw32]
```

##### 使用 gem 安装 jekyll

首先，需要将 gem 的源更换掉，否则在不翻墙的情况下，绝对会卡的令人难受。这里我使用的是 [Ruby China](https://gems.ruby-china.org/) 的源，速度杠杠的。执行命令如下：

``` sh
gem sources --remove https://rubygems.org/
gem sources --add http://gems.ruby-china.org
gem sources -l
gem sources -u
gem -v
```

注意：这里使用的是 **http://gems.ruby-china.org** ，而不是 https://gems.ruby-china.org ，是为了绕过 SSL 证书问题。

接下来，我们安装好 jekyll 环境：

``` sh
gem install bundle
gem install jekyll
```

如果一切正常，那么恭喜你， jekyll 环境已经搭建成功了。

##### 获取博客框架

我查询了很多网上的博客，到达这一步后都是教你建一个目录，然后 cmd 到这个目录下，使用 `jekyll new blog` 的命令创建一个博客的框架，这个对于了解 jekyll blog 的目录结构有必要，但却不是我们想要的效果，因为它太原始了，运行起来后访问界面一点也不美观，说好的高大尚的博客界面在哪呢？那让我们站在前人的肩膀上前行吧！

[jekyllthemes](http://jekyllthemes.org/) 提供了接近300款的主题（等等，主题是啥？对于 jekyll ，主题说白了就是一套完整的博客框架源码），我们完全可以在这里面挑选一个喜欢的主题，并将之下载到本地目录（建议使用英文目录），这样我们的博客基础框架就成型了。

我将 14 页主题都大概地浏览了一遍，在这里推荐我很喜欢的两款主题：

[Cool Concise High-end](http://jekyllthemes.org/themes/cool-concise-high-end/) : 我的博客也是在这款主题上加工完成的，仅仅做了一些汉化，这款主题是阿里的前端大师 [Gaohaoyang](https://gaohaoyang.github.io) 制作分享的，界面美观大方，功能齐全（包含分类、标签、归档、收藏、目录导航、评论体系、统计体系等），全部都是用前端技术实现的，无需额外的插件。更详细的说明，请一定参考：[关于这个简洁明快的博客主题 ](https://github.com/Gaohaoyang/gaohaoyang.github.io/blob/master/README-zh-cn.md) 。

[Yummy Theme](http://jekyllthemes.org/themes/yummy-theme/)：也非常的漂亮，[漠然](https://mritd.me/) 的博客应该是基于这个主题扩展的。

如果你需要汉化的主题，可以直接克隆我的主题：

``` sh
git clone https://github.com/bjddd192/bjddd192.github.io.git
```

**拿到框架源码后请将其拷贝到 git clone 下来的 github 空仓库中**。

##### 修改博客框架

在拿到博客框架后，这个框架还是别人的内容，因此你需要做一些修改，将它变成你自己的博客框架。在这之前你一定需要了解一下博客框架的 [目录结构](http://jekyll.com.cn/docs/structure/)。

下图是我的一个补充：

![博客结构说明图](/assets/2017-02-20-使用jekyll搭建blog/01.png)

首先需要修改的就是 `_config.yml` 文件，配置不复杂，一看就明白。

然后需要修改 `favicon.ico` 图标，这个选择一个你喜欢的图标替换即可。

然后需要修改 `index.html` 首页里面的一些内容。

最后，你需要删除掉 `_drafts` 、 `_posts` 文件夹里面的文章，因为这个是别人写的文章，可以保留一两篇用来做测试。

其他还有想要扩展的东西，自己后面慢慢完善就好了。

##### 运行博客框架

在此之前我们需要先做一个配置，因为我们都是中国人，写的文章肯定需要用中文命名的，而如果不改这个配置，本地调试就会无法访问到中文命名的文章。

请打开 RailsInstaller 安装目录下 Ruby2.2.0\lib\ruby\2.2.0\webrick\httpservlet 下的 filehandler.rb 文件，找到下列两处，添加一句（+的一行为添加部分），即可支持中文文件名。

``` ruby
path = req.path_info.dup.force_encoding(Encoding.find("filesystem"))
+ path.force_encoding("UTF-8") #增加此句
if trailing_pathsep?(req.path_info)
```

``` ruby
break if base == "/"
+ base.force_encoding("UTF-8") #增加此句
break unless File.directory?(File.expand_path(res.filename + base))
```

然后 cmd 到你的博客根目录，执行热部署命令：

``` sh
jekyll serve --watch
```

会输出如下信息，说明博客框架运行成功：

``` sh
Configuration file: D:/11_Github/bjddd192.github.io/_config.yml
Configuration file: D:/11_Github/bjddd192.github.io/_config.yml
            Source: D:/11_Github/bjddd192.github.io
       Destination: D:/11_Github/bjddd192.github.io/_site
 Incremental build: disabled. Enable with --incremental
      Generating...
                    done in 2.999 seconds.
  Please add the following to your Gemfile to avoid polling for changes:
    gem 'wdm', '>= 0.1.0' if Gem.win_platform?
 Auto-regeneration: enabled for 'D:/11_Github/bjddd192.github.io'
Configuration file: D:/11_Github/bjddd192.github.io/_config.yml
    Server address: http://127.0.0.1:4000/
```

这时，我们用浏览器（建议用谷歌浏览器）打开 http://127.0.0.1:4000 ，即可正常访问到本地的一个博客，这时我们可以一边浏览一边再做些小调整，直到完全满意为止。

### 书写博客

这个很简单，请参考官方的文档：[撰写博客](http://jekyll.com.cn/docs/posts/)

需要注意的是我们必须采用规范的 markdown 语法来书写，养成良好的习惯，才能逐步提升写作的效率。

### 发布博客

这个也非常简单，使用 git commit 提交修改，然后用 git push 将修改推送到 github 服务器，之后访问你的博客公网链接 https://username.github.io ，即可将自己的美文轻松地分享给好友了。

### 自定义域名与实现https

在如 [https://github.com/bjddd192/bjddd192.github.io/settings](https://github.com/bjddd192/bjddd192.github.io/settings) 进行设置即可，里面有官方的说明。

我使用的阿里云的免费证书，并添加 CNAME 重定向到 `www.zorin.xin`，同时在 settings 中开启 https 即可。

### 参考资料

>[Jekyll和Github搭建个人静态博客](http://pwnny.cn/original/2016/06/26/MakeBlog.html)

> [每个人都应该有一个Jekyll博客](http://www.tuicool.com/articles/ruMVjyN)

> [jekyll官网](http://jekyll.com.cn/)

### 结语

这篇文章目的只是教会你搭建一个博客的平台，打开一扇写博客的大门，但是博客的内容需要持之以恒的去添砖加瓦，才能成为一个好的博客，才能让写博客这件事情有意义。这要求我们不断地努力学习，完善自己，并做一个乐于分享的人。相信若干年后，再来回首这些学习、生活、分享的经历，一定会别有一番风味，也会庆幸自己的坚持。

如果你还没有行动起来，来吧，我们一起出发。

如果搭建的过程中还遇到什么问题，请给我留言一起探讨哦。

“没有十全十美的教程，如同不存在彻头彻尾的绝望”（改自村上春树语）

重要的是保持住一颗捣腾不安的心以及对知识的渴望与找寻。 
 

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [Mars丶小石头](https://www.zorin.xin) 所有。
