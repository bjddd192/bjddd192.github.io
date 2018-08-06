## mac jekyll 运行

```sh
ruby --version
gem install jekyll bundler
cd /Users/yanglei/01_git/github_me/bjddd192.github.io
bundle install
bundle exec jekyll serve --watch
```

参见：https://blog.mattclemente.com/2016/02/24/getting-started-with-jekyll-part-3.html

https://help.github.com/articles/setting-up-your-github-pages-site-locally-with-jekyll/

## 其他可以实现的功能记录

### 推荐，置顶功能可以怎么做

可以在每篇日志的顶部加变量标识是否置顶或推荐，比如：

```sh
---
layout: post
...
ahead: true
recommend: true
---
```

然后在 index.html 里遍历所有日志的时候（index.html 里 36-56 行），用 post.ahead 和 post.recommend 来判断，然后做对应的处理。

参见：https://github.com/mzlogin/mzlogin.github.io/issues/49

### 其他参考

https://github.com/xoyabc/xoyabc.github.io

https://haishangyanghang.github.io/

https://github.com/hejianchao/hejianchao.github.io

https://github.com/uk0/uk0.github.io

https://github.com/walkman/walkman.github.io

