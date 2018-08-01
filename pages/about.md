---
layout: page
title: About
description: "欢迎来到 Mars丶小石头 的个人博客"
keywords: bjddd192, Mars丶小石头
comments: true
menu: 关于
permalink: /about/
---

## 工作状况

## 职业技能
	
## 学习计划


## 联系我

{% for website in site.data.social %}
* {{ website.sitename }}：[@{{ website.name }}]({{ website.url }})
{% endfor %}

## Skill Keywords

{% for category in site.data.skills %}
### {{ category.name }}
<div class="btn-inline">
{% for keyword in category.keywords %}
<button class="btn btn-outline" type="button">{{ keyword }}</button>
{% endfor %}
</div>
{% endfor %}
