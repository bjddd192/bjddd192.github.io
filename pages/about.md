---
layout: page
title: About
description: "欢迎来到 Mars丶小石头 的个人博客"
keywords: bjddd192, Mars丶小石头
comments: true
menu: 关于
permalink: /about/
---

## 个人简介

> 本人从事 IT 行业已经十余年了，目前已是超级奶爸，主要给零售鞋服企业内部提供技术服务，做过软件开发，兼职过 DBA，目前在做服务器管理、系统运维、容器技术、大数据的研究，深感基础知识还不够扎实，前方的路还有很长。但我骨子里总还有一颗开发的心，也喜欢捣腾各种计算机相关技术，虽然搞的东西有点杂，但我会一直坚持下去，相信每天进步一点点，最终能汇聚成属于自己的 IT 大道。

## 职业技能

{% for category in site.data.skills %}
### {{ category.name }}
<div class="btn-inline">
{% for keyword in category.keywords %}
<button class="btn btn-outline" type="button">{{ keyword }}</button>
{% endfor %}
</div>
{% endfor %}
	
## 学习计划

项目  |  状态  
:---  |  :--- 
python  |  学习中
java  |  刚接触
ant.design  |  刚接触
go  |  未来计划

## 联系我

扫一扫下方的二维码，加我为微信好友即可。

![微信](/assets/images/Wechat_me.jpeg)

也可以通过以下方式与我联系：

{% for website in site.data.social %}
* {{ website.sitename }}：[@{{ website.name }}]({{ website.url }})
{% endfor %}

## See You Tomorrow

See You Again

