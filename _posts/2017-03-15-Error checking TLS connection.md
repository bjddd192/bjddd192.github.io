---
layout: post
title: Error checking TLS connection
date: 2017-03-15 16:18:30 +0800
description: Error checking TLS connection
categories: docker
tags: toolbox
keywords: docker toolbox
---

今天需要使用 win7 上的 `docker toolbox` 加速下载一个镜像，却发现程序启动报错了，如下：

```sh
docker-machine env
Error checking TLS connection: Error checking and/or regenerating the certs: There was an error validating certificates for host "192.168.99.100:2376": x509: certificator 192.168.99.101, not 192.168.99.100
You can attempt to regenerate them using 'docker-machine regenerate-certs [name]'.
Be advised that this will trigger a Docker daemon restart which might stop running containers.
```




回忆了一下，当时创建的 `default machine` IP 地址是 192.168.99.101，怎么重启后变成了 192.168.99.100 了呢，在 VirtualBox 中查看了 IP 地址，确实是 192.168.99.100 了，看来是因为重启了电脑，虚拟机自动获取 IP 地址发生了改变。因为这台虚拟机已经安装 docker 应用，肯定不能采用重装的方式，必须要将其恢复。最后，在 `docker toolbox` 的 issues 找到了解决办法，如下：

```sh
docker-machine regenerate-certs default
Regenerate TLS machine certs?  Warning: this is irreversible. (y/n): y
Regenerating TLS certificates
Waiting for SSH to be available...
Detecting the provisioner...
Copying certs to the local machine directory...
Copying certs to the remote machine...
Setting Docker configuration on the remote daemon...
```

其实就是重新生成一下证书就可以了，回头看一下，在报错信息中已经提示解决错误的方案了，太粗心了！囧… 自此，问题解决，再重新启动 `docker toolbox` 发现已经可以正常使用了。

### 参考资料

> [Error checking TLS connection](https://github.com/docker/toolbox/issues/346)

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [Mars丶小石头](https://www.zorin.xin) 所有。
