---
layout: page
title: Links
description: 没有链接的博客是孤独的
keywords: 友情链接
comments: true
menu: 链接
permalink: /links/
---

> 相遇、相识、相知、我们 一起前行！

{% for link in site.data.links %}
<!-- * [{{ link.name }}]({{ link.url }}) -->
<a href="{{ link.url }}" target="_blank">{{ link.name }}</a>
{% endfor %}
