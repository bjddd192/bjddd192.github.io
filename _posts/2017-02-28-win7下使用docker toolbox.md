---
layout: post
title: win7下使用docker toolbox
date: 2017-02-28 09:18:30 +0800
description: windows7 下使用 docker toolbox 工具
categories: docker
tags: toolbox
keywords: docker toolbox
---

* content
{:toc}

&emsp;&emsp;在去年接触 docker 的时候就知道 docker 可以在 windows 下被支持，但一直未去尝试，都是在 linux 服务器上操作学习，现在 docker 也玩的比较熟了，于是想在自己的工作电脑上（windows7）也安装一个 docker 环境，以便不在公司的时候也能做一些练习。安装的过程并不复杂，不过用在 windows 下 docker 被多封装了一层虚拟机，所以没有在 linux 上面来的那么直接，昨天我在安装的过程中也遇到一些问题，在这里也一起记录一下。




### 安装说明

我的电脑操作系统是 `windows7 64位 旗舰版`，如果是` windows 10 `及以上的版本，建议直接安装 docker ，安装配置请参考以下官方文档：

[Install Docker for Windows](https://docs.docker.com/docker-for-windows/install/)

[Get started with Docker for Windows](https://docs.docker.com/docker-for-windows/)

[安装包下载](https://download.docker.com/win/stable/InstallDocker.msi)

具体我没有去尝试，不过看了下官方文档介绍应该很好用。由于我的电脑操作系统比较旧，只能选择 `docker toolbox` 工具，也有详细的官方文档：

[Install Docker Toolbox on Windows](https://docs.docker.com/toolbox/toolbox_install_windows/)

[安装包下载](https://download.docker.com/win/stable/DockerToolbox.exe)

文档里面对安装步骤、机器配置要求已经讲解的非常详细，因此在这里就不多说了,只是强调一下：
* 操作系统必须是 64 位的，也就是意味着要 win7 以上的版本
* 我的机器在安装 docker toolbox 之前就已经安装好了 git，因此在安装过程中我没有选择 git 的安装，在启动 `Docker Quickstart Terminal` 时会报错说找不到快捷方式，这时只要右键快捷方式，更改目标为机器 git 安装目录即可。如我的 git 安装在 `D:\Program Files (x86)\Git` 下，因此我的需要调整为：`"D:\Program Files (x86)\Git\bin\bash.exe" --login -i "D:\Program Files\Docker Toolbox\start.sh"`
* 手工下载 [boot2docker.iso](https://github.com/boot2docker/boot2docker/releases/download/v17.03.0-ce-rc1/boot2docker.iso) ，并在 docker toolbox 安装完毕后将其拷贝到 C:\Users\用户名\.docker\machine\cache 下，否则启动程序它会自己去下载，会卡的不要不要的。

如果安装过程一切顺利的话，安装完成后运行 `Docker Quickstart Terminal`，会看到以下界面：

```sh
                        ##         .
                  ## ## ##        ==
               ## ## ## ## ##    ===
           /"""""""""""""""""\___/ ===
      ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~
           \______ o           __/
             \    \         __/
              \____\_______/

docker is configured to use the default machine with IP 192.168.99.100
For help getting started, check out the docs at https://docs.docker.com

Start interactive shell
Welcome to Git (version 1.9.4-preview20140611)


Run 'git help git' to display the help index.
Run 'git help <command>' to display help for specific commands.
```

我们可以检查一下安装的版本：

```sh
$ docker version
time="2017-02-28T10:44:59+08:00" level=info msg="Unable to use system certificate pool: crypto/x509: system root pool is not available on Windows"
Client:
 Version:      1.13.1
 API version:  1.26
 Go version:   go1.7.5
 Git commit:   092cba3
 Built:        Wed Feb  8 08:47:51 2017
 OS/Arch:      windows/amd64

Server:
 Version:      1.13.1
 API version:  1.26 (minimum version 1.12)
 Go version:   go1.7.5
 Git commit:   092cba3
 Built:        Wed Feb  8 08:47:51 2017
 OS/Arch:      linux/amd64
 Experimental: false
```

### 使用说明

在启动成功 Docker Quickstart Terminal 后，默认自动创建了一个名为 default 的虚拟机，在 `C:\Users\用户名\.docker\machine\machines` 下可以找到，我们会发现在控制台中常用的 docker 命令都可以正常的使用。但我有两点疑问需要解决：

* docker 的配置文件在哪里？在 linux 中，我在安装完 docker 后会调整配置文件 `/lib/systemd/system/docker.service` ，用于设置网络、私仓、镜像加速等，但是 windows 版本的配置文件在哪里呢？我也需要做类似的设置。
* docker pull 下来的 image 是存放在哪里的，如果在 C 盘的话，很明显不太合适，用久了以后会撑爆 C 盘，需要调整目录。

要想解决这些问题，我们需要再深入了解下 windows 下 docker toolbox 的工作原理，让我们来看看 `docker-machine` 的一些基础操作命令。

#### 查看安装的 docker 虚拟机

```sh
$ docker-machine ls
NAME      ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER    ERRORS
default   *        virtualbox   Running   tcp://192.168.99.100:2376           v1.13.1
```

#### 查看安装的 docker 的环境变量

```sh
$ docker-machine env default
You can further specify your shell with either 'cmd' or 'powershell' with the --shell flag.

SET DOCKER_TLS_VERIFY=1
SET DOCKER_HOST=tcp://192.168.99.100:2376
SET DOCKER_CERT_PATH=C:\Users\yang.l1\.docker\machine\machines\default
SET DOCKER_MACHINE_NAME=default
SET COMPOSE_CONVERT_WINDOWS_PATHS=true
REM Run this command to configure your shell:
REM     @FOR /f "tokens=*" %i IN ('"d:\Program Files\Docker Toolbox\docker-machine.exe" env default') DO @%i
```

#### 移除安装的 docker 虚拟机

```sh
$ docker-machine rm default
About to remove default
WARNING: This action will delete both local reference and remote instance.
Are you sure? (y/n): y
Successfully removed default
```

#### 创建 docker 虚拟机

```sh
$ docker-machine create --driver=virtualbox default
Running pre-create checks...
Creating machine...
(default) Copying C:\Users\yang.l1\.docker\machine\cache\boot2docker.iso to C:\Users\yang.l1\.docker\machine\machines\default\boot2docker.iso...
(default) Creating VirtualBox VM...
(default) Creating SSH key...
(default) Starting the VM...
(default) Check network to re-create if needed...
(default) Waiting for an IP...
Waiting for machine to be running, this may take a few minutes...
Detecting operating system of created instance...
Waiting for SSH to be available...
Detecting the provisioner...
Provisioning with boot2docker...
Copying certs to the local machine directory...
Copying certs to the remote machine...
Setting Docker configuration on the remote daemon...
Checking connection to Docker...
Docker is up and running!
To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: d:\Program Files\Docker Toolbox\docker-machine.exe env default
```

从创建 docker 的过程我们可以看出实际上是创建了一台 virtualbox 的虚拟机，安装完成后看一下 `C:\Users\用户名\.docker\machine\machines\default` 文件夹的大小大概为 49M 。    
安装完成后，我想要 pull 私仓的镜像，发现有报错：

```sh
$ docker pull registry.eyd.com:5000/tools/mycat:1.3.0.3
time="2017-02-28T11:50:49+08:00" level=info msg="Unable to use system certificate pool: crypto/x509: system root pool is not available on Windows"
Error response from daemon: Get https://registry.eyd.com:5000/v1/_ping: http: server gave HTTP response to HTTPS client
```

这个错误是由于我的私仓使用的是最简单的 http 免密验证导致的，在 linux 中可以通过配置文件来解决。下面我们来看看在 windows 下要到哪里配置。

#### 连接 docker 虚拟机

```sh
$ docker-machine ssh default
                        ##         .
                  ## ## ##        ==
               ## ## ## ## ##    ===
           /"""""""""""""""""\___/ ===
      ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~
           \______ o           __/
             \    \         __/
              \____\_______/
 _                 _   ____     _            _
| |__   ___   ___ | |_|___ \ __| | ___   ___| | _____ _ __
| '_ \ / _ \ / _ \| __| __) / _` |/ _ \ / __| |/ / _ \ '__|
| |_) | (_) | (_) | |_ / __/ (_| | (_) | (__|   <  __/ |
|_.__/ \___/ \___/ \__|_____\__,_|\___/ \___|_|\_\___|_|
Boot2Docker version 1.13.1, build HEAD : b7f6033 - Wed Feb  8 20:31:48 UTC 2017
Docker version 1.13.1, build 092cba3
docker@default:~$ docker -v
Docker version 1.13.1, build 092cba3
```

连接到机器后，发现跟远程连接到 linux 的服务器差不多，事情就好办了，呵呵。

#### 修改 docker 虚拟机配置

```sh
docker@default:~$ sudo cat /var/lib/boot2docker/profile
EXTRA_ARGS='
--label provider=virtualbox

'
CACERT=/var/lib/boot2docker/ca.pem
DOCKER_HOST='-H tcp://0.0.0.0:2376'
DOCKER_STORAGE=aufs
DOCKER_TLS=auto
SERVERKEY=/var/lib/boot2docker/server-key.pem
SERVERCERT=/var/lib/boot2docker/server.pem
```

熟悉 linux docker 环境的朋友应该可以看出，这个和 linux 下 docker 的配置文件 `/lib/systemd/system/docker.service` 类似。你可以修改此文件来配置你的 docker ，由于我们安装 docker 客户端版本大于1.10，我们可以通过修改 daemon 配置文件这种更好的的方式来达到目的。详情可以参考云栖社区博文：[Docker 镜像加速器](https://yq.aliyun.com/articles/29941) 。

```sh
docker@default:~$ sudo tee /var/lib/boot2docker/etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://ekj7ys2t.mirror.aliyuncs.com"
  ],
  "insecure-registries": [
    "registry.eyd.com:5000"
  ]
}
EOF
```

在这里，我配置了我的 docker 私仓 `registry.eyd.com:5000`，我的阿里云镜像加速器 `https://ekj7ys2t.mirror.aliyuncs.com`，从参数可以看出，它们是可以配置多个的，这就是优势所在。

#### 生效 docker 虚拟机配置

```sh
docker@default:~$ exit

$ docker-machine restart default
Restarting "default"...
(default) Check network to re-create if needed...
(default) Waiting for an IP...
Waiting for SSH to be available...
Detecting the provisioner...
Restarted machines may have new IP addresses. You may need to re-run the `docker-machine env` command.
```

重启完虚拟机后，接下来我们查看一下配置是否有生效，

```sh
$ docker info
Insecure Registries:
 registry.eyd.com:5000
 127.0.0.0/8
Registry Mirrors:
 https://ekj7ys2t.mirror.aliyuncs.com
```

可以在返回结果最后面看到配置的参数已经生效。让我们来测试一下：

```sh
$ docker pull registry.eyd.com:5000/tools/mycat:1.3.0.3
time="2017-02-28T14:46:46+08:00" level=info msg="Unable to use system certificate pool: crypto/x509: system root pool is not available on Windows"
1.3.0.3: Pulling from tools/mycat
5040bd298390: Pull complete
fce5728aad85: Pull complete
c42794440453: Pull complete
9789263043d1: Pull complete
6c6ea13aad15: Pull complete
9b79b765908e: Pull complete
7d6125eef71b: Pull complete
e6e32be681f3: Pull complete
4e25190d2905: Pull complete
a2a35b454e37: Pull complete
0dc70e8e8093: Pull complete
e246c340df9b: Pull complete
6e46a9769514: Pull complete
Digest: sha256:1e15f9466987c82dafd39a0f67999f848a74a414afabba480d858246c8b14e46
Status: Downloaded newer image for registry.eyd.com:5000/tools/mycat:1.3.0.3

$ docker pull nginx
time="2017-02-28T15:10:09+08:00" level=info msg="Unable to use system certificate pool: crypto/x509: system root pool is not available on Windows"
Using default tag: latest
latest: Pulling from library/nginx
5040bd298390: Already exists
31123d939af1: Pull complete
23f1bdd267a9: Pull complete
Digest: sha256:4296639ebdf92f035abf95fee1330449e65990223c899838283c9844b1aaac4c
Status: Downloaded newer image for nginx:latest

$ docker images
time="2017-02-28T15:12:56+08:00" level=info msg="Unable to use system certificate pool: crypto/x509: system root pool is not available on Windows"
REPOSITORY                          TAG                 IMAGE ID            CREATED             SIZE
registry.eyd.com:5000/tools/mycat   1.3.0.3             41346296504c        5 days ago          437 MB
nginx                               latest              db079554b4d2        12 days ago         182 MB
```

可以看到，不管是下载私仓的镜像还是官方的镜像，都没有问题，速度也是相当可以的。这样配置的问题基本上就解决了，如果还有其他的需求可以做类似的处理即可。

最后，我们启动一个容器来看看效果：

```sh
$ docker run -d -p 80:80 --name nginx nginx:latest
time="2017-02-28T15:21:02+08:00" level=info msg="Unable to use system certificate pool: crypto/x509: system root pool is not available on Windows"
051fcf3a426c237d26bb1f6726ad3e3cf8f4c3ac01fb073d4302dd98a3903c28

$ docker ps
time="2017-02-28T15:21:13+08:00" level=info msg="Unable to use system certificate pool: crypto/x509: system root pool is not available on Windows"
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                         NAMES
051fcf3a426c        nginx:latest        "nginx -g 'daemon ..."   11 seconds ago      Up 11 seconds       0.0.0.0:80->80/tcp, 443/tcp   nginx
```

我们打开浏览器，输入虚拟机的 IP 地址，我这里是 http://192.168.99.100/，发现可以正常访问到 nginx 的欢迎界面。

这里要**注意**一下： docker 容器是在 VirtualBox 的虚拟机里面，不是在 Windows 里面，所以不能用 127.0.0.1 访问。

#### 更换 docker 虚拟机文件存储

首先，我们需要停止虚拟机：

```sh
$ docker-machine stop default
Stopping "default"...
Machine "default" was stopped.
```

然后开始操作：

* 运行 `Oracle VM VirtualBox`，选择`管理`菜单下的`虚拟介质管理`，我们可以看到 Docker 虚拟机用的虚拟硬盘的文件 `disk`。

* 选中`disk`，然后点击菜单中的`复制`命令，根据向导，把当前的 disk 复制到另一个盘上面去。

* 回到 `VirtualBox` 主界面，选中`default`这个虚拟机，在右侧双击`存储`选项。

* 把 disk 从`控制器SATA`中删除，然后重新添加我们刚才复制到另外一个磁盘上的那个文件。

最后，开启虚拟机：

```sh
$ docker-machine start default
Starting "default"...
(default) Check network to re-create if needed...
(default) Waiting for an IP...
Machine "default" was started.
Waiting for SSH to be available...
Detecting the provisioner...
Started machines may have new IP addresses. You may need to re-run the `docker-machine env` command.
```

确保使用新磁盘的虚拟机没有问题后，就可以把C盘那个disk文件删除了。

<font color=#0099ff size=5 face="黑体">**注意**</font>：不能在 Window 中直接去复制粘贴 disk 文件，否则在添加硬盘时会报错的，所以一定要在 VirtualBox 中去复制！

### 参考资料

[在Windows中玩转Docker Toolbox](https://yq.aliyun.com/articles/65076)

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [ん乖乖龙ん](https://bjddd192.github.io) 所有。
