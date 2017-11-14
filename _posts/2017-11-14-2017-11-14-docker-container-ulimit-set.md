---
layout: "post"
title: "docker 容器 ulimit 参数设置"
date: "2017-11-14 16:04:31"
description: docker 容器 ulimit 参数设置
categories: docker
tags: docker WebSocket
keywords: docker ulimit WebSocket
---

* content
{:toc}

这几天发现部署的一个 WebSocket 应用容器很不稳定，WebSocket 连接老是会无缘无故的批量掉线。跟踪了一下 haproxy 路由转发容器的日志，发现以下报错：

```sh
[WARNING] 311/072614 (22534) : [haproxy.main()] Cannot raise FD limit to 131116, limit is 65536.
```

带着这个错误信息，找到了以下帖子：

[linux 最大文件描述符 fd](http://www.cnblogs.com/zengkefu/p/5602473.html)

[使用四种框架分别实现百万 websocket 常连接的服务器](http://www.cnblogs.com/cnsanshao/p/4652305.html)

这里详细地描述了如何通过调优实现 WebSocket 的百万连接，而我的应用不过几千的连接，服务器的配置也差不太多，理论上应该是完全不会有问题发生的，现在有问题肯定就是没有调优造成的。

**需要解决的问题是：作者是在物理机上直接进行的调优，那么在容器里面该如何做呢？**





当时的第一反应就是 docker exec 进入容器直接进行参数调整，发现会报错：

```sh
ulimit: open files: cannot modify limit: Operation not permitted
```

原因是：docker 容器默认移除 sys_resource（Linux 能力），因而 ulimit -n 设置只能改小无法改大，改大会报错。

详情见：[深入理解docker ulimit](https://weibo.com/p/1001603867707551442110) 。

那应该怎么办呢，经过对资料的一番思考与尝试（艰辛的过程就不多说了），终于找到了解决办法：

### 一、调整宿主机的 ulimit

```sh
# 查看文件最大的打开数
$ cat /proc/sys/fs/file-max

# 如果数值较小，则需要调大，这里我是调整为 100W

# 临时设置
$ echo 1000000 > /proc/sys/fs/file-max

# 永久设置
$ echo "fs.file-max = 1000000" >> /etc/sysctl.conf
$ echo "fs.nr_open = 1000000" >> /etc/sysctl.conf

# 修改文件，将最后 4 行的 65535 改为 1000000
$ vi /etc/security/limits.conf 

# 改成大于 1000000，这里我设置为 2000000
$ echo 2000000 > /proc/sys/fs/nr_open

# 查看当前系统使用的打开文件描述符数
$ cat /proc/sys/fs/file-nr

$ ulimit -a
core file size          (blocks, -c) 0
data seg size           (kbytes, -d) unlimited
scheduling priority             (-e) 0
file size               (blocks, -f) unlimited
pending signals                 (-i) 63470
max locked memory       (kbytes, -l) 64
max memory size         (kbytes, -m) unlimited
open files                      (-n) 1000000
pipe size            (512 bytes, -p) 8
POSIX message queues     (bytes, -q) 819200
real-time priority              (-r) 0
stack size              (kbytes, -s) 8192
cpu time               (seconds, -t) unlimited
max user processes              (-u) 63470
virtual memory          (kbytes, -v) unlimited
file locks                      (-x) unlimited
```

---

### 二、调整系统容器的 ulimit

由于应用请求需要走 haproxy 路由转发容器，这个是某云的系统容器，因此需要走特别的途径进行修改（这也算是某云的一个 Bug 吧），解决的方式也很变态，因为这个容器是使用 docker-compose 编排文件发布的，因此需要改写 docker-compose 编排文件。这里需要使用谷歌浏览器的开发工具，从前端找到对应的隐藏的系统按钮，去掉 `ng-hide` 属性，将按钮显示出来，就可以修改编排文件了。追加以下 yaml 文件内容即可：

```yaml
ulimits:
  nofile:
    soft: 1000000
    hard: 1000000
privileged: true
```

系统容器重启后，使用以下命令查看系统容器的进程 ID 还会不会变化（变化说明容器挂掉重启了）：

```sh
docker exec -ti <routing_container_id> ps aux
```

**这步看不懂的请跳过即可。**

---

### 三、调整应用容器的 ulimit

应用容器我也是使用 docker-compose 编排文件启动的，而且完全受我控制，这就比较简单了，一样的处理方式，追加以下 yaml 文件内容即可：

```yaml
ulimits:
  nofile:
    soft: 1000000
    hard: 1000000
privileged: true
```

---

### 总结

调整完成后，重启相应的容器，并进入容器用 `ulimit -a` 可以查看到文件打开数限制已经生效，haproxy 路由转发容器不再频繁挂掉重启，而 WebSocket 应用容器也变得稳定起来了。

经过这次的问题处理过程，我们应该对 docker 的 ulimit 重视起来，在一些复杂的应用场景下，需要将容器就看作是物理机，来考虑调优的事宜。

这一点是我们使用容器后容易忽略的事情，希望能给大家在上生产前一些警示。

---

### 参考资料

[linux 最大文件描述符 fd](http://www.cnblogs.com/zengkefu/p/5602473.html)

[使用四种框架分别实现百万 websocket 常连接的服务器](http://www.cnblogs.com/cnsanshao/p/4652305.html)

[深入理解docker ulimit](https://weibo.com/p/1001603867707551442110)

---

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [ん乖乖龙ん](https://bjddd192.github.io) 所有。