---
layout: "post"
title: "Windows下nfs的使用"
date: "2018-10-11 09:57:08"
description: Windows下nfs的使用
categories: windows
tags: nfs
keywords: windows nfs 
---

最近在研究网络存储，首先是在 centos7 服务器上搭建了一个 nfs 服务，对于 linux 操作系统下挂载使用都没有什么问题。

但某同学希望能在 windows 下使用一下 nfs 共享，原因是常用的 smb 文件共享服务由于漏洞的问题，被公司网管封了端口了，无法正常使用。所以研究了一下在 windows 下如何将 linux 上搭建的 nfs 服务，相对 smb 步骤会繁琐很多。




## nfs 服务端搭建

首先，得有一个提供 nfs 的 linux 服务器，这块比较简单，不展开说，可以百度解决。

## windows 开启 nfs 客户端

参考：[教你怎么在windows上挂载nfs](https://jingyan.baidu.com/article/0a52e3f4dc3f4abf63ed7259.html)

开启后，在 cmd 窗口使用命令，可以先查看一下共享是否正常：

```cmd
C:\Users\Administrator>showmount -e 172.20.32.47
导出列表在 172.20.32.47:
/share                             172.20.32.0/24
/share/es0                         172.20.32.0/24
/share/es1                         172.20.32.0/24
/share/es2                         172.20.32.0/24
/share1                            172.20.32.0/24, 172.17.232.0/24,
                                   172.20.50.0/24
```

例如，这里我查看了 172.20.32.47 服务器的 nfs 共享情况，这里要注意共享目录对于当前 windows 所在的网段是不是已经开启了访问的权限，如果服务器没有开通权限，客户端挂载时会报无法访问的错误哦。

确定权限正常后，我们就可以使用命令进行挂载：

```cmd
C:\Users\Administrator>mount 172.20.32.47:/share1 x:
x: 现已成功连接到 172.20.32.47:/share1
```

这样，就发现共享目录被成功挂载到了 x 盘了。

如要取消共享，可以执行命令：

```cmd
C:\Users\Administrator>umount x:

正在断开连接            x:      \\172.20.32.47\share1
连接上存在打开的文件和/或未完成的目录搜索。

要继续此操作吗? (Y/N) [N]:y

命令已成功完成。
```

## 解决无法写入的问题

在挂载成功后，会发现无法向共享目录写入，有2个办法可以解决：

1. 在服务器给这个共享目录 777 的权限(可能有安全性问题，不推荐)
2. 更改一下 windows 的注册表，在挂载 NFS 的时候将 UID 和 GID 改成 0，即 root 用户。(推荐)

注册表修改方法：

找到 `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default`，增加两项：AnonymousUid，AnonymousGid

如何重新启动计算机，重新 mount，发现共享目录就可以正常写入了。

## 解决中文乱码的问题

这个问题主要会出现在 windows 与 linux 互用的情况，比如 windows 下建立一个中文的文件夹，到服务端查看会乱码。

**如果都只是在 windows 机器之间使用，是可以不用去理会服务器上看到的是不是乱码的，可以跳过此步骤。**

如果有强迫症，可以参考：[windows挂载nfs的中文乱码问题的解决](http://www.nihao001.com/archives/1574.html)

总结一下，就是要使用 [ms-nfs41-client](https://github.com/cbodley/ms-nfs41-client)，它支持 utf-8 编码。

但我在使用后发现用它挂载后，可以解决字符但问题，又无法向共享目录写入了，上一步修改注册表的行为对它不起作用，后面我的解决方式是在服务端给共享目录 777 的权限，就可以进行写入文件了。

## 总结

整个处理好以后，nfs 共享服务是可以正常使用了，测试了一下读写，速度大概只有 1.5M/s，不是很理想，勉强能用吧。

nfs 在 windows 下的使用还是挺麻烦的，期待未来的 windows 对它会有更好的支持吧。

## 参考资料

[win7与linux网络共享挂载nfs配置](http://www.codeweblog.com/win7%E4%B8%8Elinux%E7%BD%91%E7%BB%9C%E5%85%B1%E4%BA%AB%E6%8C%82%E8%BD%BDnfs%E9%85%8D%E7%BD%AE/)

---

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [Mars丶小石头](https://www.zorin.xin) 所有。