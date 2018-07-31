---
layout: page
title: Links
description: 没有链接的博客是孤独的
keywords: 友情链接
comments: true
menu: 链接
permalink: /links/
---

> 圣贤是思想的先声；朋友是心灵的希望。

<ul>
{% for link in site.data.links %}
<!-- * [{{ link.name }}]({{ link.url }}) -->
  <li>
  	<p>
		<a href="{{ link.url }}" target="_blank">{{ link.name }}</a>
	</p>
  </li>
{% endfor %}
</ul>
