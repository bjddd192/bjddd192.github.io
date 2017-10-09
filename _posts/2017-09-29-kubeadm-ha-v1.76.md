---
layout: post
title: kubeadm-ha-v1.76
date: 2017-09-29 10:41:30 +0800
description: kubeadm的kubernetes高可用集群v.176部署 
categories: kubernetes
tags: kubeadm-ha
keywords: kubernetes kubeadm v.176
---

* content
{:toc}

# kubeadm-highavailiability

本文绝大部分内容来源于[cookeem](https://github.com/cookeem)的[kubeadm-ha](https://github.com/cookeem/kubeadm-ha/blob/master/README_CN.md)一文，非常感谢作者的分享，本人在他的分享之上探索基于kubeadm的kubernetes高可用集群v.176部署，因为部署的点比较多，因此有必要详细记录一下，给自己一个备忘，同时也分享给大家，一起完善k8s的学习，有问题可以与我联系交流。






### 部署架构

#### 概要部署架构

![ha logo](/assets/2017-09-29-kubeadm-ha-v1.76/ha.png)

> kubernetes高可用的核心架构是master的高可用，kubectl、客户端以及nodes访问load balancer实现高可用。

#### 详细部署架构

![k8s ha](/assets/2017-09-29-kubeadm-ha-v1.76/k8s-ha.png)

> kubernetes组件说明

* etcd：集群的数据中心，用于存放集群的配置以及状态信息，非常重要，如果数据丢失那么集群将无法恢复；因此高可用集群部署首先就是etcd是高可用集群；

* kube-apiserver：集群核心，集群API接口、集群各个组件通信的中枢；集群安全控制；

* kube-scheduler：集群Pod的调度中心；默认kubeadm安装情况下--leader-elect参数已经设置为true，保证master集群中只有一个kube-scheduler处于活跃状态；

* kube-controller-manager：集群状态管理器，当集群状态与期望不同时，kcm会努力让集群恢复期望状态，比如：当一个pod死掉，kcm会努力新建一个pod来恢复对应replicas set期望的状态；默认kubeadm安装情况下--leader-elect参数已经设置为true，保证master集群中只有一个kube-controller-manager处于活跃状态；

* kubelet：kubernetes node agent，负责与node上的docker engine打交道；

* kube-proxy: 每个node上一个，负责service vip到endpoint pod的流量转发，当前主要通过设置iptables规则实现。

> 负载均衡

* keepalived集群设置一个虚拟ip地址，虚拟ip地址指向master1、master2、master3。

* nginx用于master1、master2、master3的apiserver的负载均衡。外部kubectl以及nodes访问apiserver的时候就可以用过keepalived的虚拟ip(172.20.32.78)以及nginx端口(8443)访问master集群的apiserver。

#### 主机节点清单

 主机名 | IP地址 | 说明 | 组件 
 :--- | :--- | :--- | :---
 k8s-m44 | 172.20.32.44 | master节点1 | etcd、kube-apiserver、kube-scheduler、kube-proxy、kubelet、calico、keepalived、nginx、kube-dashboard
 k8s-m45 | 172.20.32.45 | master节点2 | etcd、kube-apiserver、kube-scheduler、kube-proxy、kubelet、calico、keepalived、nginx、kube-dashboard
 k8s-m47 | 172.20.32.47 | master节点3 | etcd、kube-apiserver、kube-scheduler、kube-proxy、kubelet、calico、keepalived、nginx、kube-dashboard
 无 | 172.20.32.78 | keepalived虚拟IP | 无
 zabbix-46 | 172.20.32.46 | node节点 | kubelet、kube-proxy
 oooooooo | ooooooooooo | oooooooooooooo | 占位行，用于固定网格的宽度

### 前期准备

#### 安装操作系统

```sh
$ cat /etc/redhat-release 
CentOS Linux release 7.2.1511 (Core) 
```
可以安装7.2及以上的centos版本。其他linux版本未验证，仅做参考。

---

#### 准备域名解析服务器

域名解析服务器主要用于统一规划私有网络中的路由，减少重复设置的工作量。（***当然，这个不是必须的，你可以采用自己的方式做类似的处理***）

由于本人非网络运维人员，无法接触到路由器，因此自己准备了一个容器版的域名解析路由器，安装步骤很简单，请参考：[dnsmasq](https://hub.docker.com/r/andyshinn/dnsmasq/)。

本人的域名解析服务器地址为：`172.20.32.132` ，本文中的 `down.belle.cn` `registry.eyd.com` `reg.blf1.org` 皆来源于本人自定义的域名服务。

---

#### 准备文件下载服务器

文件下载服务器主要用于存放一些安装过程中需要的资源。（***当然，这个不是必须的，你可以采用自己的方式做类似的处理***）

由于安装过程中很多资源需要翻墙下载，还有一些配置文件下载之后需要根据实际情况进行调整，因此，本人采用的方式是将这些资源统一放置在一个文件下载服务器当中，加速后续的安装进程。

搭建文件下载服务器很简单，可以采用 nginx 来实现。

```sh
$ mkdir /home/docker/sfds

$ docker run -d --name sfds -p 80:9000 \
  --env 'TZ=Asia/Shanghai' --restart=always \
  -v /home/docker/sfds/nginx.conf:/etc/nginx/nginx.conf \
  -v /usr/local/sfds:/usr/share/nginx/html \
  nginx:1.11.4
```

nginx.conf 文件内容如下：

```sh
#user  nginx;
worker_processes  1;

#error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    #include /etc/nginx/conf.d/*.conf;

    server 
    {
        listen        9000;             #端口
        server_name  localhost;         #服务名
        root /usr/share/nginx/html;     #显示的根索引目录   
        autoindex on;                   #开启索引功能
        autoindex_exact_size off;       #关闭计算文件确切大小（单位bytes），只显示大概大小（单位kb、mb、gb）
        autoindex_localtime on;         #显示本机时间而非 GMT 时间
    }

}
```

---

#### 修改主机名

> k8s-m44
```sh
echo k8s-m44 > /etc/hostname 
sysctl kernel.hostname=k8s-m44
echo "172.20.32.44 k8s-m44" >> /etc/hosts
su -
```

> k8s-m45
```sh
echo k8s-m45 > /etc/hostname 
sysctl kernel.hostname=k8s-m45
echo "172.20.32.45 k8s-m45" >> /etc/hosts
su -
```

> k8s-m47
```sh
echo k8s-m47 > /etc/hostname 
sysctl kernel.hostname=k8s-m47
echo "172.20.32.47 k8s-m47" >> /etc/hosts
su -
```

同时将各机器使用统一的域名解析服务器，如下：

```sh
$ cat /etc/resolv.conf 
nameserver 172.20.32.132
```

并在域名解析服务器增加：

```sh
k8s-m44 172.20.32.44
k8s-m45 172.20.32.45
k8s-m47 172.20.32.47
```

---

#### 禁用 Selinux、防火墙

注意：通过运行禁用 SELinux `setenforce 0` 是必需的，以允许容器访问主机文件系统，例如pod网络请求。您必须执行此操作，直到在 kubelet 中 SELinux 支持得到改进。

```sh
$ sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

$ sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config

$ setenforce 0

$ /usr/sbin/sestatus -v
SELinux status:                 disabled
```

**注意：有时未立即生效则需要重启机器。**

```sh
$ systemctl disable firewalld && systemctl stop firewalld
```

---

#### 安装docker

官方推荐使用 1.12.x 的版本，本人统一采用 1.12.5 的版本。安装包可以从[官方下载](https://yum.dockerproject.org/repo/main/centos/7/Packages/)。

本人是先下载到文件下载服务器，再从自己的服务器下载。

```sh
$ wget http://down.belle.cn/package/docker-engine-selinux-1.12.5-1.el7.centos.noarch.rpm

$ wget http://down.belle.cn/package/docker-engine-1.12.5-1.el7.centos.x86_64.rpm

$ curl -sSL https://get.daocloud.io/docker | sh

$ yum list installed | grep docker

$ yum -y remove docker-engine.x86_64

$ yum -y remove docker-engine-selinux.noarch

$ yum -y remove docker-ce.x86_64

$ yum -y remove docker-selinux

$ rpm -ivh docker-engine-selinux-1.12.5-1.el7.centos.noarch.rpm

$ rpm -ivh docker-engine-1.12.5-1.el7.centos.x86_64.rpm

$ rm -rf docker-engine-*

$ systemctl restart docker
```

整个过程是先安装官方最新的版本以自动安装好所有的依赖，然后卸载掉最新版本重装 1.12.5 版本。

安装过程若卡死在：

```sh
Metadata Cache Created
+ sh -c 'yum install -y -q docker-ce'
Delta RPMs disabled because /usr/bin/applydeltarpm not installed.
```

需要先执行：

```sh
$  yum -y install deltarpm
```

安装成功后，可以查看一下版本：

```sh
$ docker version
Client:
 Version:      1.12.5
 API version:  1.24
 Go version:   go1.6.4
 Git commit:   7392c3b
 Built:        Fri Dec 16 02:23:59 2016
 OS/Arch:      linux/amd64

Server:
 Version:      1.12.5
 API version:  1.24
 Go version:   go1.6.4
 Git commit:   7392c3b
 Built:        Fri Dec 16 02:23:59 2016
 OS/Arch:      linux/amd64
```

---

#### 开启路由转发、iptables

```sh
$ echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

$ echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf

$ echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf

$ echo "net.bridge.bridge-nf-call-arptables = 1" >> /etc/sysctl.conf

$ /sbin/sysctl -p

$ cat /etc/sysctl.conf
```

---

#### 调整 docker 参数

```sh
# 重定义对docker0网桥 
$ vim /lib/systemd/system/docker.service
# 修改为以下内容 ExecStart=/usr/bin/dockerd --bip=192.168.144.1/24 --ip-forward=true

# 设置镜像加速器和信任仓库
$ tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "http://7c81ea9c.m.daocloud.io"
  ],
  "insecure-registries": [
    "registry.eyd.com:5000"
  ]
}
EOF

$ cat /etc/docker/daemon.json

# 重启服务
$ systemctl daemon-reload && systemctl enable docker && systemctl restart docker && systemctl status docker
```

---

#### 下载 k8s 镜像

在安装k8s的过程中，需要拉取很多镜像，因为很多镜像源在国外，因此下载速度会比较慢，或者无法下载，导致安装失败。

因此本人通过翻墙的手段，先将镜像下载到本地。（这里大家各显神通吧，我翻墙下载也经历了耗时痛苦的过程）

在一台有代理的 docker 机器上 pull 镜像：

```sh
# 172.20.30.95:8087 为本人的代理服务器
export http_proxy="http://172.20.30.95:8087"
export https_proxy="http://172.20.30.95:8087"

docker pull quay.io_coreos_etcd_v3.1.10 quay.io/coreos/etcd:v3.1.10
docker pull quay.io_calico_node_v2.5.1 quay.io/calico/node:v2.5.1
docker pull quay.io_calico_cni_v1.10.0 quay.io/calico/cni:v1.10.0
docker pull quay.io_calico_kube-policy-controller_v0.7.0 quay.io/calico/kube-policy-controller:v0.7.0

docker pull gcr.io_google_containers_kube-controller-manager-amd64_v1.7.6 gcr.io/google_containers/kube-controller-manager-amd64:v1.7.6
docker pull gcr.io_google_containers_kube-scheduler-amd64_v1.7.6 gcr.io/google_containers/kube-scheduler-amd64:v1.7.6
docker pull gcr.io_google_containers_kube-apiserver-amd64_v1.7.6 gcr.io/google_containers/kube-apiserver-amd64:v1.7.6
docker pull gcr.io_google_containers_kube-proxy-amd64_v1.7.6 gcr.io/google_containers/kube-proxy-amd64:v1.7.6
docker pull gcr.io_google_containers_k8s-dns-sidecar-amd64_1.14.4 gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.4
docker pull gcr.io_google_containers_k8s-dns-dnsmasq-nanny-amd64_1.14.4 gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.4
docker pull gcr.io_google_containers_k8s-dns-kube-dns-amd64_1.14.4 gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.4
docker pull gcr.io_google_containers_etcd-amd64_3.0.17 gcr.io/google_containers/etcd-amd64:3.0.17
docker pull gcr.io_google_containers_pause-amd64_3.0 gcr.io/google_containers/pause-amd64:3.0
docker pull gcr.io_google_containers_kubernetes-dashboard-amd64_v1.6.3 gcr.io/google_containers/kubernetes-dashboard-amd64:v1.6.3
```

保存镜像：

```sh
docker save -o quay.io_coreos_etcd_v3.1.10 quay.io/coreos/etcd:v3.1.10
docker save -o quay.io_calico_node_v2.5.1 quay.io/calico/node:v2.5.1
docker save -o quay.io_calico_cni_v1.10.0 quay.io/calico/cni:v1.10.0
docker save -o quay.io_calico_kube-policy-controller_v0.7.0 quay.io/calico/kube-policy-controller:v0.7.0

docker save -o gcr.io_google_containers_kube-controller-manager-amd64_v1.7.6 gcr.io/google_containers/kube-controller-manager-amd64:v1.7.6
docker save -o gcr.io_google_containers_kube-scheduler-amd64_v1.7.6 gcr.io/google_containers/kube-scheduler-amd64:v1.7.6
docker save -o gcr.io_google_containers_kube-apiserver-amd64_v1.7.6 gcr.io/google_containers/kube-apiserver-amd64:v1.7.6
docker save -o gcr.io_google_containers_kube-proxy-amd64_v1.7.6 gcr.io/google_containers/kube-proxy-amd64:v1.7.6
docker save -o gcr.io_google_containers_k8s-dns-sidecar-amd64_1.14.4 gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.4
docker save -o gcr.io_google_containers_k8s-dns-dnsmasq-nanny-amd64_1.14.4 gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.4
docker save -o gcr.io_google_containers_k8s-dns-kube-dns-amd64_1.14.4 gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.4
docker save -o gcr.io_google_containers_etcd-amd64_3.0.17 gcr.io/google_containers/etcd-amd64:3.0.17
docker save -o gcr.io_google_containers_pause-amd64_3.0 gcr.io/google_containers/pause-amd64:3.0
docker save -o gcr.io_google_containers_kubernetes-dashboard-amd64_v1.6.3 gcr.io/google_containers/kubernetes-dashboard-amd64:v1.6.3
```

然后将保存的镜像复制到下载服务器。（使用 scp 命令，这里略过）

在各 master 服务器装载镜像：

```sh
# 下载镜像包
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/quay.io_coreos_etcd_v3.1.10
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/quay.io_calico_node_v2.5.1
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/quay.io_calico_cni_v1.10.0
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/quay.io_calico_kube-policy-controller_v0.7.0

wget http://down.belle.cn/package/kubernetes/v1.7.6/images/gcr.io_google_containers_k8s-dns-kube-dns-amd64_1.14.4
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/gcr.io_google_containers_kube-controller-manager-amd64_v1.7.6 
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/gcr.io_google_containers_kube-scheduler-amd64_v1.7.6
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/gcr.io_google_containers_kube-apiserver-amd64_v1.7.6
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/gcr.io_google_containers_kube-proxy-amd64_v1.7.6
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/gcr.io_google_containers_k8s-dns-sidecar-amd64_1.14.4
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/gcr.io_google_containers_k8s-dns-dnsmasq-nanny-amd64_1.14.4
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/gcr.io_google_containers_etcd-amd64_3.0.17
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/gcr.io_google_containers_pause-amd64_3.0

# 装载镜像包
docker load --input quay.io_coreos_etcd_v3.1.10
docker load --input quay.io_calico_node_v2.5.1
docker load --input quay.io_calico_cni_v1.10.0
docker load --input quay.io_calico_kube-policy-controller_v0.7.0

docker load --input gcr.io_google_containers_kube-controller-manager-amd64_v1.7.6 
docker load --input gcr.io_google_containers_kube-scheduler-amd64_v1.7.6
docker load --input gcr.io_google_containers_kube-apiserver-amd64_v1.7.6
docker load --input gcr.io_google_containers_kube-proxy-amd64_v1.7.6
docker load --input gcr.io_google_containers_k8s-dns-sidecar-amd64_1.14.4
docker load --input gcr.io_google_containers_k8s-dns-dnsmasq-nanny-amd64_1.14.4 
docker load --input gcr.io_google_containers_k8s-dns-kube-dns-amd64_1.14.4
docker load --input gcr.io_google_containers_etcd-amd64_3.0.17
docker load --input gcr.io_google_containers_pause-amd64_3.0

# 删除镜像包
rm -rf quay.io_*
rm -rf gcr.io_google_containers_*
```

在各 node 服务器装载镜像：

```sh
# 下载镜像包
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/gcr.io_google_containers_kubernetes-dashboard-amd64_v1.6.3
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/quay.io_calico_node_v2.5.1
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/quay.io_calico_cni_v1.10.0
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/gcr.io_google_containers_kube-proxy-amd64_v1.7.6
wget http://down.belle.cn/package/kubernetes/v1.7.6/images/gcr.io_google_containers_pause-amd64_3.0 

# 装载镜像包
docker load --input gcr.io_google_containers_kubernetes-dashboard-amd64_v1.6.3
docker load --input quay.io_calico_node_v2.5.1
docker load --input quay.io_calico_cni_v1.10.0
docker load --input gcr.io_google_containers_kube-proxy-amd64_v1.7.6
docker load --input gcr.io_google_containers_pause-amd64_3.0

# 删除镜像包
rm -rf quay.io_*
rm -rf gcr.io_google_containers_*
```

---


#### 设置 kubernetes 仓库

本人采用的是翻墙安装的方式自己构建的yum仓库，先将 [https://packages.cloud.google.com/yum/](https://packages.cloud.google.com/yum/)  下面的内容下载到本地服务器。pool文件夹的内容看不到，需要在安装过程中获取。 

```sh
$ cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
#baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
baseurl=http://down.belle.cn/package/kubernetes/v1.7.6/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
#gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
#       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
gpgkey=http://down.belle.cn/package/kubernetes/v1.7.6/doc/yum-key.gpg
       http://down.belle.cn/package/kubernetes/v1.7.6/doc/rpm-package-key.gpg
EOF
```

也可以不这么麻烦，使用阿里云的yum仓库（未验证，应该没有问题，网页可以正常访问）

```sh
$ cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
EOF
```

---

#### 安装 kubernetes 服务

```sh
$ yum install -y kubelet kubeadm kubectl kubernetes-cni

$ systemctl daemon-reload && systemctl restart kubelet

$ kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"7", GitVersion:"v1.7.5", GitCommit:"17d7182a7ccbb167074be7a87f0a68bd00d58d97", GitTreeState:"clean", BuildDate:"2017-08-31T08:56:23Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}

$ kubelet --version
Kubernetes v1.7.5

$ kubectl version
Client Version: version.Info{Major:"1", Minor:"7", GitVersion:"v1.7.5", GitCommit:"17d7182a7ccbb167074be7a87f0a68bd00d58d97", GitTreeState:"clean", BuildDate:"2017-08-31T09:14:02Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"7", GitVersion:"v1.7.6", GitCommit:"4bc5e7f9a6c25dc4c03d4d656f2cefd21540e28c", GitTreeState:"clean", BuildDate:"2017-09-14T06:36:08Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
```

如要指定版本安装，可以采用以下方式：

```sh
$ yum search kubelet --showduplicates
$ yum install kubelet-1.7.5-0.x86_64

$ yum search kubeadm --showduplicates  
$ yum install kubeadm-1.7.5-0.x86_64

$ yum search kubernetes-cni --showduplicates
$ yum install kubernetes-cni-0.5.1-0.x86_64
```

安装docker 1.12.5版本需要设置`cgroup-driver=cgroupfs`：

```sh
$ sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

$ systemctl daemon-reload && systemctl restart 

# 查看kubelet service的日志
$ journalctl -t kubelet -f 
```

---

#### 下载 harbor 私仓证书

由于本人已经切换使用 harbor 私仓，并开启了 https 服务，因此，需要在各节点下载 harbor 的证书，否则在从私仓下载镜像时会报错：

x509: certificate signed by unknown authority.

```sh
mkdir -p /etc/docker/certs.d/reg.blf1.org
cd /etc/docker/certs.d/reg.blf1.org
wget http://down.belle.cn/package/harbor/ca.crt
```

---

### 部署 etcd 集群

etcd 是集群的数据中心，用于存放集群的配置以及状态信息，非常重要，如果数据丢失那么集群将无法恢复，因此需要首先部署 etcd 高可用集群。

在这之前我尝试过改造kubeadm自带的etcd为集群方式，主要是参考文章：

[一步步打造基于Kubeadm的高可用Kubernetes集群-第一部分](http://tonybai.com/2017/05/15/setup-a-ha-kubernetes-cluster-based-on-kubeadm-part1/)

[一步步打造基于Kubeadm的高可用Kubernetes集群-第二部分](http://tonybai.com/2017/05/15/setup-a-ha-kubernetes-cluster-based-on-kubeadm-part2/)

改造方式大概就是 etcd 数据迁移的方式，但操作过于繁琐，而后续的集群改造方式又会遇到有不少问题，而部署出错以后 etcd 操作又要重来一遍，可操作性很差，因此放弃了这种改造的方式，换成独立的部署方式。不过作者的探索精神，思考问题的方式值得借鉴，也不失为好文章。



#### k8s etcd 集群

在 k8s-m44(master1) 上以docker方式启动etcd集群

```sh
yum -y install etcd

ETCDCTL_API=3 etcdctl version

docker stop etcd && docker rm etcd

rm -rf /var/lib/etcd-cluster

mkdir -p /var/lib/etcd-cluster

docker run -d --name etcd --restart always \
  -p 4001:4001 \
  -p 2379:2379 \
  -p 2380:2380 \
  -v /etc/ssl/certs:/etc/ssl/certs \
  -v /var/lib/etcd-cluster:/var/lib/etcd \
  gcr.io/google_containers/etcd-amd64:3.0.17 etcd \
  --name=k8s-m44 \
  --initial-advertise-peer-urls=http://172.20.32.44:2380 \
  --listen-peer-urls=http://0.0.0.0:2380 \
  --listen-client-urls=http://0.0.0.0:2379,http://0.0.0.0:4001 \
  --advertise-client-urls=http://172.20.32.44:2379 \
  --initial-cluster-token=k8s-etcd-cluster \
  --initial-cluster=k8s-m44=http://172.20.32.44:2380,k8s-m45=http://172.20.32.45:2380,k8s-m47=http://172.20.32.47:2380 \
  --initial-cluster-state=new \
  --auto-tls \
  --peer-auto-tls \
  --data-dir=/var/lib/etcd
```

在 k8s-m45(master2) 上以docker方式启动etcd集群

```
yum -y install etcd

ETCDCTL_API=3 etcdctl version

docker stop etcd && docker rm etcd

rm -rf /var/lib/etcd-cluster

mkdir -p /var/lib/etcd-cluster

docker run -d --name etcd --restart always \
  -p 4001:4001 \
  -p 2379:2379 \
  -p 2380:2380 \
  -v /etc/ssl/certs:/etc/ssl/certs \
  -v /var/lib/etcd-cluster:/var/lib/etcd \
  gcr.io/google_containers/etcd-amd64:3.0.17 etcd \
  --name=k8s-m45 \
  --initial-advertise-peer-urls=http://172.20.32.45:2380 \
  --listen-peer-urls=http://0.0.0.0:2380 \
  --listen-client-urls=http://0.0.0.0:2379,http://0.0.0.0:4001 \
  --advertise-client-urls=http://172.20.32.45:2379 \
  --initial-cluster-token=k8s-etcd-cluster \
  --initial-cluster=k8s-m44=http://172.20.32.44:2380,k8s-m45=http://172.20.32.45:2380,k8s-m47=http://172.20.32.47:2380 \
  --initial-cluster-state=new \
  --auto-tls \
  --peer-auto-tls \
  --data-dir=/var/lib/etcd
```

在 k8s-m47(master3) 上以docker方式启动etcd集群

```
yum -y install etcd

ETCDCTL_API=3 etcdctl version

docker stop etcd && docker rm etcd

rm -rf /var/lib/etcd-cluster

mkdir -p /var/lib/etcd-cluster

docker run -d --name etcd --restart always \
  -p 4001:4001 \
  -p 2379:2379 \
  -p 2380:2380 \
  -v /etc/ssl/certs:/etc/ssl/certs \
  -v /var/lib/etcd-cluster:/var/lib/etcd \
  gcr.io/google_containers/etcd-amd64:3.0.17 etcd \
  --name=k8s-m47 \
  --initial-advertise-peer-urls=http://172.20.32.47:2380 \
  --listen-peer-urls=http://0.0.0.0:2380 \
  --listen-client-urls=http://0.0.0.0:2379,http://0.0.0.0:4001 \
  --advertise-client-urls=http://172.20.32.47:2379 \
  --initial-cluster-token=k8s-etcd-cluster \
  --initial-cluster=k8s-m44=http://172.20.32.44:2380,k8s-m45=http://172.20.32.45:2380,k8s-m47=http://172.20.32.47:2380 \
  --initial-cluster-state=new \
  --auto-tls \
  --peer-auto-tls \
  --data-dir=/var/lib/etcd
```

在master1、master2、master3上检查etcd启动状态：

```
$ ETCDCTL_API=2 etcdctl member list
2de54c0ebb659480: name=k8s-m47 peerURLs=http://172.20.32.47:2380 clientURLs=http://172.20.32.47:2379 isLeader=false
31db8ed40ce6cb25: name=k8s-m45 peerURLs=http://172.20.32.45:2380 clientURLs=http://172.20.32.45:2379 isLeader=false
9fce1e7d2ae7a3b6: name=k8s-m44 peerURLs=http://172.20.32.44:2380 clientURLs=http://172.20.32.44:2379 isLeader=true

$ ETCDCTL_API=3 etcdctl endpoint status --endpoints=172.20.32.44:2379,172.20.32.45:2379,172.20.32.47:2379
172.20.32.44:2379, 9fce1e7d2ae7a3b6, 3.0.17, 25 kB, true, 129, 529
172.20.32.45:2379, 31db8ed40ce6cb25, 3.0.17, 25 kB, false, 129, 529
172.20.32.47:2379, 2de54c0ebb659480, 3.0.17, 25 kB, false, 129, 529

$ etcdctl cluster-health
member 2de54c0ebb659480 is healthy: got healthy result from http://172.20.32.47:2379
member 31db8ed40ce6cb25 is healthy: got healthy result from http://172.20.32.45:2379
member 9fce1e7d2ae7a3b6 is healthy: got healthy result from http://172.20.32.44:2379
```

---

#### calico etcd (可忽略)

由于calico可以直接使用k8s的etcd集群，因此没有必要再重新部署一套。这里仅做备忘使用。

在 k8s-m44(master1) 上以docker方式启动etcd集群

```
docker stop etcd_calico && docker rm etcd_calico

rm -rf /var/etcd

mkdir -p /var/etcd

docker run -d --name etcd_calico --restart always \
  --expose=6668 --expose=6667 --expose=6666 \
  -p 6668:6668 \
  -p 6667:6667 \
  -p 6666:6666 \
  -v /etc/ssl/certs:/etc/ssl/certs \
  -v /var/etcd:/var/etcd \
  quay.io/coreos/etcd:v3.1.10 etcd \
  --name=etcd-calico-m44 \
  --initial-advertise-peer-urls=http://172.20.32.44:6666 \
  --listen-peer-urls=http://0.0.0.0:6666 \
  --listen-client-urls=http://0.0.0.0:6667,http://0.0.0.0:6668 \
  --advertise-client-urls=http://172.20.32.44:6667 \
  --initial-cluster-token=k8s-etcd-calico \
  --initial-cluster=etcd-calico-m44=http://172.20.32.44:6666,etcd-calico-m45=http://172.20.32.45:6666,etcd-calico-m47=http://172.20.32.47:6666 \
  --auto-tls \
  --peer-auto-tls \
  --data-dir=/var/etcd/calico-data
```

在 k8s-m45(master2) 上以docker方式启动etcd集群

```
docker stop etcd_calico && docker rm etcd_calico

rm -rf /var/etcd

mkdir -p /var/etcd

docker run -d --name etcd_calico --restart always \
  --expose=6668 --expose=6667 --expose=6666 \
  -p 6668:6668 \
  -p 6667:6667 \
  -p 6666:6666 \
  -v /etc/ssl/certs:/etc/ssl/certs \
  -v /var/etcd:/var/etcd \
  quay.io/coreos/etcd:v3.1.10 etcd \
  --name=etcd-calico-m45 \
  --initial-advertise-peer-urls=http://172.20.32.45:6666 \
  --listen-peer-urls=http://0.0.0.0:6666 \
  --listen-client-urls=http://0.0.0.0:6667,http://0.0.0.0:6668 \
  --advertise-client-urls=http://172.20.32.45:6667 \
  --initial-cluster-token=k8s-etcd-calico \
  --initial-cluster=etcd-calico-m44=http://172.20.32.44:6666,etcd-calico-m45=http://172.20.32.45:6666,etcd-calico-m47=http://172.20.32.47:6666 \
  --auto-tls \
  --peer-auto-tls \
  --data-dir=/var/etcd/calico-data
```

在 k8s-m47(master3) 上以docker方式启动etcd集群

```
docker stop etcd_calico && docker rm etcd_calico

rm -rf /var/etcd

mkdir -p /var/etcd

docker run -d --name etcd_calico --restart always \
  --expose=6668 --expose=6667 --expose=6666 \
  -p 6668:6668 \
  -p 6667:6667 \
  -p 6666:6666 \
  -v /etc/ssl/certs:/etc/ssl/certs \
  -v /var/etcd:/var/etcd \
  quay.io/coreos/etcd:v3.1.10 etcd \
  --name=etcd-calico-m47 \
  --initial-advertise-peer-urls=http://172.20.32.47:6666 \
  --listen-peer-urls=http://0.0.0.0:6666 \
  --listen-client-urls=http://0.0.0.0:6667,http://0.0.0.0:6668 \
  --advertise-client-urls=http://172.20.32.47:6667 \
  --initial-cluster-token=k8s-etcd-calico \
  --initial-cluster=etcd-calico-m44=http://172.20.32.44:6666,etcd-calico-m45=http://172.20.32.45:6666,etcd-calico-m47=http://172.20.32.47:6666 \
  --auto-tls \
  --peer-auto-tls \
  --data-dir=/var/etcd/calico-data
```

* 在master1、master2、master3上检查etcd启动状态

```
$ ETCDCTL_API=3 etcdctl endpoint status --endpoints=172.20.32.44:6667,172.20.32.45:6667,172.20.32.47:6667
172.20.32.44:6667, d6841eecddfe0a54, 3.1.10, 25 kB, false, 8, 9
172.20.32.45:6667, 54d7ebb6fd304151, 3.1.10, 25 kB, true, 8, 9
172.20.32.47:6667, 3484ffcbcf1e0b7, 3.1.10, 25 kB, false, 8, 9
```

---

### 第一台master初始化

#### 机器清理(可选)

```sh
kubeadm reset
```

---

#### kubeadm初始化

这里使用配置文件的高级方式初始化master，更多资料可以参考：[config-file](https://kubernetes.io/docs/admin/kubeadm/#config-file)

```sh
tee /root/kubeadm-init-v1.7.6.yaml <<-'EOF'
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
api:
  advertiseAddress: 0.0.0.0
  bindPort: 6443
etcd:
  endpoints:
  - http://172.20.32.44:2379
  - http://172.20.32.45:2379
  - http://172.20.32.47:2379
networking:
  dnsDomain: 172.20.32.132
  serviceSubnet: 10.96.0.0/12
  podSubnet: 192.168.0.0/16
kubernetesVersion: v1.7.6
apiServerCertSANs:
- k8s-m44
- k8s-m45
- k8s-m47
- 127.0.0.1
- 192.168.0.1
- 10.96.0.1
- 172.20.32.44
- 172.20.32.45
- 172.20.32.47
- 172.20.32.78
EOF
```

在master1上使用kubeadm初始化kubernetes集群，连接外部etcd集群

```sh
$ kubeadm init --config=/root/kubeadm-init-v1.7.6.yaml
[kubeadm] WARNING: kubeadm is in beta, please do not use it for production clusters.
[init] Using Kubernetes version: v1.7.6
[init] Using Authorization modes: [Node RBAC]
[preflight] Running pre-flight checks
[preflight] Starting the kubelet service
[kubeadm] WARNING: starting in 1.8, tokens expire after 24 hours by default (if you require a non-expiring token use --token-ttl 0)
[certificates] Generated CA certificate and key.
[certificates] Generated API server certificate and key.
[certificates] API Server serving cert is signed for DNS names [k8s-m44 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.172.20.32.132 k8s-m44 k8s-m45 k8s-m47] and IPs [127.0.0.1 192.168.0.1 10.96.0.1 172.20.32.44 172.20.32.45 172.20.32.47 172.20.32.78 10.96.0.1 172.20.32.44]
[certificates] Generated API server kubelet client certificate and key.
[certificates] Generated service account token signing key and public key.
[certificates] Generated front-proxy CA certificate and key.
[certificates] Generated front-proxy client certificate and key.
[certificates] Valid certificates and keys now exist in "/etc/kubernetes/pki"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/scheduler.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/admin.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/kubelet.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/controller-manager.conf"
[apiclient] Created API client, waiting for the control plane to become ready
[apiclient] All control plane components are healthy after 31.002131 seconds
[token] Using token: 0ae401.fa0fdf56d19ffb6f
[apiconfig] Created RBAC rules
[addons] Applied essential addon: kube-proxy
[addons] Applied essential addon: kube-dns

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run (as a regular user):

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  http://kubernetes.io/docs/admin/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join --token 0ae401.fa0fdf56d19ffb6f 172.20.32.44:6443

$ rm -rf /root/kubeadm-init-v1.7.6.yaml
```

在master1上修改kube-apiserver.yaml的admission-control，v1.7.x使用了NodeRestriction等安全检查控制，务必设置成v1.6.x推荐的admission-control配置：

``` sh
sed -i 's/Initializers,//g' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i 's/NodeRestriction,//g' /etc/kubernetes/manifests/kube-apiserver.yaml  
```

在master1上设置kubectl的环境变量`KUBECONFIG`：

```sh
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bashrc
source ~/.bashrc
```

在master1上重启docker kubelet服务

```sh
systemctl restart docker kubelet
```

---

#### k8s与 harbor 集成

主要是让K8s调度发布应用时可以正常拉取对象，需要建立 secret 。

```sh
# 创建 secret
$ kubectl create secret docker-registry reg.blf1.org \
  --docker-server=reg.blf1.org --docker-username=admin \
  --docker-password=dockerMan2017 --docker-email=leo.admin@wonhigh.cn

# kube-system 系统命名空间专用
$ kubectl create secret docker-registry reg.blf1.org --namespace=kube-system \
  --docker-server=reg.blf1.org --docker-username=admin \
  --docker-password=dockerMan2017 --docker-email=leo.admin@wonhigh.cn

$ kubectl get secret --all-namespaces | grep reg.blf1.org
default       reg.blf1.org                             kubernetes.io/dockercfg               1         3s
kube-system   reg.blf1.org                             kubernetes.io/dockercfg               1         8d
```

---


#### calico网络组件安装

在master1上安装calico网络组件（必须安装网络组件，否则kube-dns pod会一直处于ContainerCreating）。

```sh
$ kubectl apply -f http://down.belle.cn/package/kubernetes/v1.7.6/calico.yaml
```

官方路径安装方式：

```sh
$ kubectl apply -f https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml
```

在master1上验证kube-dns成功启动，大概等待3分钟，验证所有pods的状态为Running。

```sh
$ kubectl get pods --all-namespaces -o wide
NAMESPACE     NAME                                       READY     STATUS    RESTARTS   AGE       IP               NODE
kube-system   calico-etcd-plxvk                          1/1       Running   0          1m        172.20.32.44     k8s-m44
kube-system   calico-node-tvn6r                          2/2       Running   0          1m        172.20.32.44     k8s-m44
kube-system   calico-policy-controller-336633499-j394h   1/1       Running   0          1m        172.20.32.44     k8s-m44
kube-system   kube-apiserver-k8s-m44                     1/1       Running   1          4m        172.20.32.44     k8s-m44
kube-system   kube-controller-manager-k8s-m44            1/1       Running   2          13m       172.20.32.44     k8s-m44
kube-system   kube-dns-2881600278-490k4                  3/3       Running   0          14m       192.168.130.68   k8s-m44
kube-system   kube-proxy-xsfc3                           1/1       Running   1          14m       172.20.32.44     k8s-m44
kube-system   kube-scheduler-k8s-m44                     1/1       Running   1          13m       172.20.32.44     k8s-m44
```

---

#### dashboard组件安装

在master1上安装dashboard组件。

注意：这里的yaml文件为本人从官网下载，并做了些许小调整，其实完全就可以用官网提供的即可，详情参见官网：[Installing Addons](https://kubernetes.io/docs/concepts/cluster-administration/addons/)。

```sh
$ kubectl create -f http://down.belle.cn/package/kubernetes/v1.7.6/kube-dashboard.yaml
serviceaccount "kubernetes-dashboard" created
clusterrolebinding "kubernetes-dashboard" created
deployment "kubernetes-dashboard" created
service "kubernetes-dashboard" created

$ kubectl get pods --all-namespaces -o wide
NAMESPACE     NAME                                       READY     STATUS    RESTARTS   AGE       IP               NODE
kube-system   calico-etcd-plxvk                          1/1       Running   0          7m        172.20.32.44     k8s-m44
kube-system   calico-node-tvn6r                          2/2       Running   0          7m        172.20.32.44     k8s-m44
kube-system   calico-policy-controller-336633499-j394h   1/1       Running   0          7m        172.20.32.44     k8s-m44
kube-system   kube-apiserver-k8s-m44                     1/1       Running   1          11m       172.20.32.44     k8s-m44
kube-system   kube-controller-manager-k8s-m44            1/1       Running   2          20m       172.20.32.44     k8s-m44
kube-system   kube-dns-2881600278-490k4                  3/3       Running   0          21m       192.168.130.68   k8s-m44
kube-system   kube-proxy-xsfc3                           1/1       Running   1          21m       172.20.32.44     k8s-m44
kube-system   kube-scheduler-k8s-m44                     1/1       Running   1          20m       172.20.32.44     k8s-m44
kube-system   kubernetes-dashboard-3714700809-j6tft      1/1       Running   0          1m        192.168.130.70   k8s-m44
```

部署完成后访问dashboard地址:`http://172.20.32.44:30080`，验证dashboard成功启动。

![dashboard](/assets/2017-09-29-kubeadm-ha-v1.76/dashboard.png)

至此，第一台master成功安装，并已经完成calico、dashboard。

---

### master集群高可用设置

#### 复制配置

在master1上把/etc/kubernetes/复制到master2、master3：

```sh
scp -r /etc/kubernetes/ 172.20.32.45:/etc/
scp -r /etc/kubernetes/ 172.20.32.47:/etc/
```

在master2、master3上重启kubelet服务，并检查kubelet服务状态为active (running)：

```sh
$ systemctl daemon-reload && systemctl restart kubelet

$ systemctl status kubelet
● kubelet.service - kubelet: The Kubernetes Node Agent
   Loaded: loaded (/etc/systemd/system/kubelet.service; enabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/kubelet.service.d
           └─10-kubeadm.conf
   Active: active (running) since Tue 2017-06-27 16:24:22 CST; 1 day 17h ago
     Docs: http://kubernetes.io/docs/
 Main PID: 2780 (kubelet)
   Memory: 92.9M
   CGroup: /system.slice/kubelet.service
           ├─2780 /usr/bin/kubelet --kubeconfig=/etc/kubernetes/kubelet.conf --require-...
           └─2811 journalctl -k -f
```

在master2、master3上设置kubectl的环境变量`KUBECONFIG`：

```sh
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bashrc
source ~/.bashrc
```

在master2、master3检测节点状态，发现节点已经加进来：

```sh
$ kubectl get node -o=wide              
NAME      STATUS    AGE       VERSION   EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION
k8s-m44   Ready     33m       v1.7.5    <none>        CentOS Linux 7 (Core)   3.10.0-327.el7.x86_64
k8s-m45   Ready     2m        v1.7.5    <none>        CentOS Linux 7 (Core)   3.10.0-327.el7.x86_64
k8s-m47   Ready     47s       v1.7.5    <none>        CentOS Linux 7 (Core)   3.10.0-327.el7.x86_64

$ kubectl get node --show-labels
NAME      STATUS    AGE       VERSION   LABELS
k8s-m44   Ready     34m       v1.7.5    beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=k8s-m44,node-role.kubernetes.io/master=
k8s-m45   Ready     3m        v1.7.5    beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=k8s-m45
k8s-m47   Ready     1m        v1.7.5    beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=k8s-m47

$ kubectl get pods --all-namespaces -o wide 
NAMESPACE     NAME                                       READY     STATUS    RESTARTS   AGE       IP               NODE
kube-system   calico-etcd-plxvk                          1/1       Running   0          25m       172.20.32.44     k8s-m44
kube-system   calico-node-glmmp                          2/2       Running   1          8m        172.20.32.45     k8s-m45
kube-system   calico-node-tvn6r                          2/2       Running   0          25m       172.20.32.44     k8s-m44
kube-system   calico-node-vvjmr                          2/2       Running   1          6m        172.20.32.47     k8s-m47
kube-system   calico-policy-controller-336633499-j394h   1/1       Running   0          25m       172.20.32.44     k8s-m44
kube-system   kube-apiserver-k8s-m44                     1/1       Running   1          29m       172.20.32.44     k8s-m44
kube-system   kube-apiserver-k8s-m45                     1/1       Running   0          8m        172.20.32.45     k8s-m45
kube-system   kube-apiserver-k8s-m47                     1/1       Running   0          6m        172.20.32.47     k8s-m47
kube-system   kube-controller-manager-k8s-m44            1/1       Running   2          38m       172.20.32.44     k8s-m44
kube-system   kube-controller-manager-k8s-m45            1/1       Running   0          8m        172.20.32.45     k8s-m45
kube-system   kube-controller-manager-k8s-m47            1/1       Running   0          6m        172.20.32.47     k8s-m47
kube-system   kube-dns-2881600278-490k4                  3/3       Running   0          38m       192.168.130.68   k8s-m44
kube-system   kube-proxy-1pzjr                           1/1       Running   0          6m        172.20.32.47     k8s-m47
kube-system   kube-proxy-qfssw                           1/1       Running   0          8m        172.20.32.45     k8s-m45
kube-system   kube-proxy-xsfc3                           1/1       Running   1          38m       172.20.32.44     k8s-m44
kube-system   kube-scheduler-k8s-m44                     1/1       Running   1          38m       172.20.32.44     k8s-m44
kube-system   kube-scheduler-k8s-m45                     1/1       Running   0          8m        172.20.32.45     k8s-m45
kube-system   kube-scheduler-k8s-m47                     1/1       Running   0          6m        172.20.32.47     k8s-m47
kube-system   kubernetes-dashboard-3714700809-j6tft      1/1       Running   0          19m       192.168.130.70   k8s-m44
```

---

#### 修改配置

在master2上修改以下配置，改为k8s-m45的IP

```sh
sed -i 's/=172.20.32.44/=172.20.32.45/g' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i 's/172.20.32.44/172.20.32.45/g' /etc/kubernetes/kubelet.conf
sed -i 's/172.20.32.44/172.20.32.45/g' /etc/kubernetes/admin.conf
sed -i 's/172.20.32.44/172.20.32.45/g' /etc/kubernetes/controller-manager.conf
sed -i 's/172.20.32.44/172.20.32.45/g' /etc/kubernetes/scheduler.conf
```

在master3上修改以下配置，改为k8s-m47的IP

```sh
sed -i 's/=172.20.32.44/=172.20.32.47/g' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i 's/172.20.32.44/172.20.32.47/g' /etc/kubernetes/kubelet.conf
sed -i 's/172.20.32.44/172.20.32.47/g' /etc/kubernetes/admin.conf
sed -i 's/172.20.32.44/172.20.32.47/g' /etc/kubernetes/controller-manager.conf
sed -i 's/172.20.32.44/172.20.32.47/g' /etc/kubernetes/scheduler.conf
```

在master1、master2、master3上重启所有服务：

```sh
$ systemctl daemon-reload && systemctl restart docker kubelet
```

在master1、master2、master3任意节点上检测服务启动情况，发现kube-apiserver、kube-controller-manager、kube-scheduler、kube-proxy、calico-node已经在master1、master2、master3成功启动。

```sh
$ kubectl get pods --all-namespaces -o wide | grep k8s-m47
kube-system   calico-node-vvjmr                          2/2       Running   3          21m       172.20.32.47     k8s-m47
kube-system   kube-apiserver-k8s-m47                     1/1       Running   1          3m        172.20.32.47     k8s-m47
kube-system   kube-controller-manager-k8s-m47            1/1       Running   1          21m       172.20.32.47     k8s-m47
kube-system   kube-proxy-1pzjr                           1/1       Running   1          21m       172.20.32.47     k8s-m47
kube-system   kube-scheduler-k8s-m47                     1/1       Running   1          21m       172.20.32.47     k8s-m47

$ kubectl get pods --all-namespaces -o wide | grep k8s-m45
kube-system   calico-node-glmmp                          2/2       Running   3          24m       172.20.32.45     k8s-m45
kube-system   kube-apiserver-k8s-m45                     1/1       Running   0          1m        172.20.32.45     k8s-m45
kube-system   kube-controller-manager-k8s-m45            1/1       Running   1          24m       172.20.32.45     k8s-m45
kube-system   kube-proxy-qfssw                           1/1       Running   1          24m       172.20.32.45     k8s-m45
kube-system   kube-scheduler-k8s-m45                     1/1       Running   1          24m       172.20.32.45     k8s-m45
```

---

#### 组件扩容

在master1、master2、master3任意节点上查看deployment的情况：

```sh
$ kubectl get deploy --all-namespaces
NAMESPACE     NAME                       DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
kube-system   calico-policy-controller   1         1         1            1           4d
kube-system   kube-dns                   1         1         1            1           4d
kube-system   kubernetes-dashboard       1         1         1            1           4d
```

在master1、master2、master3任意节点上把 kubernetes-dashboard、kube-dns 扩容成replicas=3，保证各个master节点上都有运行：

```sh
$ kubectl scale --replicas=3 -n kube-system deployment/kube-dns
deployment "kube-dns" scaled

$ kubectl get pods --all-namespaces -o wide| grep kube-dns
kube-system   kube-dns-2881600278-1hfml                  3/3       Running   0          42s       192.168.137.1     k8s-m47
kube-system   kube-dns-2881600278-490k4                  3/3       Running   0          6d        192.168.130.66    k8s-m44
kube-system   kube-dns-2881600278-dfw13                  3/3       Running   0          42s       192.168.169.129   k8s-m45

$ kubectl get pods --all-namespaces -o wide| grep kube-dns
kube-system   kube-dns-2881600278-490k4                  3/3       Running   0          4d        192.168.130.68   k8s-m44

$ kubectl scale --replicas=3 -n kube-system deployment/kubernetes-dashboard
deployment "kubernetes-dashboard" scaled

$ kubectl get pods --all-namespaces -o wide| grep kubernetes-dashboard
kube-system   kubernetes-dashboard-3714700809-2t954      1/1       Running   0          14s       192.168.137.2     k8s-m47
kube-system   kubernetes-dashboard-3714700809-8s0tw      1/1       Running   0          14s       192.168.169.146   k8s-m45
kube-system   kubernetes-dashboard-3714700809-j6tft      1/1       Running   0          4d        192.168.130.70    k8s-m44

$ kubectl get pods --all-namespaces -o wide| grep calico-policy-controller
kube-system   calico-policy-controller-336633499-j394h   1/1       Running   0          4d        172.20.32.44      k8s-m44

$ kubectl scale --replicas=3 -n kube-system deployment/calico-policy-controller
deployment "calico-policy-controller" scaled

$ kubectl get pods --all-namespaces -o wide| grep calico-policy-controller
kube-system   calico-policy-controller-336633499-j394h   1/1       Running   0          4d        172.20.32.44      k8s-m44
kube-system   calico-policy-controller-336633499-p2vw5   1/1       Running   0          32s       172.20.32.45      k8s-m45
kube-system   calico-policy-controller-336633499-tw2qj   1/1       Running   0          32s       172.20.32.47      k8s-m47
```

---

#### keepalived安装配置

在k8s-master、master2、master3上安装keepalived

```sh
$ yum -y install keepalived
```

在master1、master2、master3上设置apiserver监控脚本，当apiserver检测失败的时候关闭keepalived服务，转移虚拟IP地址

```
tee /etc/keepalived/check_apiserver.sh <<-'EOF'
#!/bin/bash

err=0

for k in $( seq 1 10 )
do
    check_code=$(ps -ef | grep kube-apiserver | wc -l)
    if [ "$check_code" = "1" ]; then
        err=$(expr $err + 1)
        sleep 3
        continue
    else
        err=0
        break
    fi
done

if [ "$err" != "0" ]; then
    echo "systemctl stop keepalived"
    /usr/bin/systemctl stop keepalived
    exit 1
else
    exit 0
fi

EOF

chmod +x /etc/keepalived/check_apiserver.sh
```

在master1、master2、master3上查看接口名字为：ens160 

```sh
$ ip a | grep 172.20.32
    inet 172.20.32.47/24 brd 172.20.32.255 scope global ens160
```

在master1上设置keepalived

```
tee /etc/keepalived/keepalived.conf <<-'EOF'
! Configuration File for keepalived

global_defs {
    router_id LVS_DEVEL
}

vrrp_script chk_apiserver {
    script "/etc/keepalived/check_apiserver.sh"
    interval 2
    weight -5
    fall 3  
    rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface ens160
    mcast_src_ip 172.20.32.44
    virtual_router_id 78
    priority 150
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 4be37dc3b4c90194d1600c483e10ad1d
    }
    virtual_ipaddress {
        172.20.32.78
    }
    track_script {
       chk_apiserver
    }
}
EOF
```

在master2上设置keepalived

```
tee /etc/keepalived/keepalived.conf <<-'EOF'
! Configuration File for keepalived

global_defs {
    router_id LVS_DEVEL
}

vrrp_script chk_apiserver {
    script "/etc/keepalived/check_apiserver.sh"
    interval 2
    weight -5
    fall 3  
    rise 2
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens160
    mcast_src_ip 172.20.32.45
    virtual_router_id 78
    priority 120
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 4be37dc3b4c90194d1600c483e10ad1d
    }
    virtual_ipaddress {
        172.20.32.78
    }
    track_script {
       chk_apiserver
    }
}
EOF
```

在master3上设置keepalived

```
tee /etc/keepalived/keepalived.conf <<-'EOF'
! Configuration File for keepalived

global_defs {
    router_id LVS_DEVEL
}

vrrp_script chk_apiserver {
    script "/etc/keepalived/check_apiserver.sh"
    interval 2
    weight -5
    fall 3  
    rise 2
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens160
    mcast_src_ip 172.20.32.47
    virtual_router_id 78
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 4be37dc3b4c90194d1600c483e10ad1d
    }
    virtual_ipaddress {
        172.20.32.78
    }
    track_script {
       chk_apiserver
    }
}
EOF
```

重启keepalived服务，并验证vip已绑定

```sh 
$ systemctl enable keepalived && systemctl restart keepalived
$ systemctl status keepalived
$ ip a | grep 172.20.32
    inet 172.20.32.44/24 brd 172.20.32.255 scope global ens160
    inet 172.20.32.78/32 scope global ens160
```

---

#### nginx负载均衡配置

在master1、master2、master3上通过nginx把访问apiserver的6443端口负载均衡到8433端口上：

```sh
$ mkdir -p /home/docker/ha/nginx

$ cd /home/docker/ha/nginx

$ rm -rf /home/docker/ha/nginx/nginx-slb.conf

$ wget http://down.belle.cn/package/kubernetes/v1.7.6/nginx-slb.conf
```

nginx-slb.conf的文件内容如下：

```sh   
user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}

stream {
        upstream apiserver {
            server 172.20.32.44:6443 weight=5 max_fails=3 fail_timeout=30s;
            server 172.20.32.45:6443 weight=5 max_fails=3 fail_timeout=30s;
            server 172.20.32.47:6443 weight=5 max_fails=3 fail_timeout=30s;
        }

    server {
        listen 8443;
        proxy_connect_timeout 1s;
        proxy_timeout 3s;
        proxy_pass apiserver;
    }
}
```

在master1、master2、master3上启动nginx容器

```sh
$ docker stop nginx-slb && docker rm nginx-slb 

$ docker run -d --name nginx-slb -p 8443:8443 \
    --env 'TZ=Asia/Shanghai' --restart=always \
    -v /home/docker/ha/nginx/nginx-slb.conf:/etc/nginx/nginx.conf \
    reg.blf1.org/tools/nginx:1.10.1
```

注意：业务恢复后务必重启keepalived，否则keepalived会处于关闭状态。

```
$ systemctl restart keepalived
$ systemctl status keepalived
```

---


#### kube-proxy配置vip

在master1上设置kube-proxy使用keepalived的虚拟IP地址，避免master1异常的时候所有节点的kube-proxy连接不上

```sh
$ kubectl get -n kube-system configmap
NAME                                 DATA      AGE
calico-config                        3         5d
extension-apiserver-authentication   6         5d
kube-proxy                           1         5d
```

在master1上修改configmap/kube-proxy的server指向keepalived的虚拟IP地址

```sh
$ kubectl edit -n kube-system configmap/kube-proxy
        server: https://172.20.32.78:6443

$ kubectl get -n kube-system configmap/kube-proxy -o yaml
```

在master1上删除所有kube-proxy的pod，让proxy重建

```
$ kubectl get pods --all-namespaces -o wide | grep proxy 
kube-system   kube-proxy-1pzjr                           1/1       Running   1          5d        172.20.32.47      k8s-m47
kube-system   kube-proxy-qfssw                           1/1       Running   1          5d        172.20.32.45      k8s-m45
kube-system   kube-proxy-xsfc3                           1/1       Running   1          5d        172.20.32.44      k8s-m44

$ kubectl delete pod kube-proxy-1pzjr --namespace=kube-system
pod "kube-proxy-1pzjr" deleted

$ kubectl delete pod kube-proxy-qfssw --namespace=kube-system
pod "kube-proxy-qfssw" deleted

$ kubectl delete pod kube-proxy-xsfc3 --namespace=kube-system
pod "kube-proxy-xsfc3" deleted

$ kubectl get pods --all-namespaces -o wide | grep proxy 
kube-system   kube-proxy-36tg0                           1/1       Running   0          15s       172.20.32.45      k8s-m45
kube-system   kube-proxy-46t3m                           1/1       Running   0          24s       172.20.32.47      k8s-m47
kube-system   kube-proxy-q4bhn                           1/1       Running   0          7s        172.20.32.44      k8s-m44
```

在master1、master2、master3上重启docker kubelet keepalived服务

```sh
$ systemctl restart docker kubelet keepalived
```

---

#### calico配置调整

调整calico使用外部的 etcd，消除单点故障。

主要调整有2块：

* 删掉canal.yaml中关于etcd的部署代码

* 修改`etcd_endpoints`为已部署的etcd集群

```sh
$ kubectl delete -f http://down.belle.cn/package/kubernetes/v1.7.6/calico.yaml

$ kubectl apply -f http://down.belle.cn/package/kubernetes/v1.7.6/calico_external_etcd.yaml

$ kubectl get pods --all-namespaces -o wide| grep calico-policy-controller
kube-system   kubernetes-dashboard-3714700809-wncnc      1/1       Running   0          9s        192.168.130.84    k8s-m44
```

这里要注意下，calico-policy-controller是否在master1上发布成功，如果发布到其他的节点，可能会导致无法创建，这时需要重复上面的步骤，直到发布到master1上即可，报错如下：

```sh 
User "system:node:k8s-m44" cannot get secrets in the namespace "kube-system".: "no path found to object" (get secrets calico-policy-controller-token-x079r)
```

具体原因在后续再跟进。

calico-policy-controller发布成功后执行扩容：

```sh
$ kubectl scale --replicas=3 -n kube-system deployment/calico-policy-controller

$ kubectl get pods --all-namespaces -o wide| grep calico-policy-controller
kube-system   kubernetes-dashboard-3714700809-6p70t      1/1       Running   0          9s        192.168.137.12    k8s-m47
kube-system   kubernetes-dashboard-3714700809-k2lpj      1/1       Running   0          11s       192.168.169.142   k8s-m45
kube-system   kubernetes-dashboard-3714700809-wncnc      1/1       Running   0          9s        192.168.130.84    k8s-m44
```

---


#### 查看master集群高可用

在master1上检查各个节点pod的启动状态，每个上都成功启动kube-apiserver、kube-controller-manager、kube-dns、kube-proxy、kube-scheduler、kubernetes-dashboard、calico。并且所有pod都处于Running状态表示正常。

```
$ kubectl get pods --all-namespaces -o wide | grep k8s-m44

$ kubectl get pods --all-namespaces -o wide | grep k8s-m45

$ kubectl get pods --all-namespaces -o wide | grep k8s-m47
```

---

#### 禁用master发布应用

在master1上禁止在所有master节点上发布应用。（可选项，个人认为没有太大的必要）

```
$ kubectl patch node k8s-m44 -p '{"spec":{"unschedulable":true}}'

$ kubectl patch node k8s-m45 -p '{"spec":{"unschedulable":true}}'

$ kubectl patch node k8s-m47 -p '{"spec":{"unschedulable":true}}'
```

---

#### node节点加入集群

在master1上查看集群的token

```sh
$ kubeadm token list
TOKEN                     TTL         EXPIRES   USAGES                   DESCRIPTION
4bd22d.62d8457a9558abbb   <forever>   <never>   authentication,signing   The default bootstrap token generated by 'kubeadm init'.
```

在zabbix-46上执行：

```sh
$ kubeadm join --token 4bd22d.62d8457a9558abbb 172.20.32.78:8443

$ systemctl enable kubelet && systemctl restart kubelet && systemctl status kubelet
```

启动成功后，在master1查看节点：

```sh
$ kubectl get nodes 
NAME        STATUS    AGE       VERSION
k8s-m44     Ready     14h       v1.7.5
k8s-m45     Ready     14h       v1.7.5
k8s-m47     Ready     14h       v1.7.5
zabbix-46   Ready     1m        v1.7.5
```

---

#### 部署应用验证集群

发布一个测试的nginx应用，可以正常访问：`http://172.20.32.78:30800/`即说明成功。

```sh
$ kubectl create -f http://down.belle.cn/package/kubernetes/v1.7.6/test_cluster/app_namespace.yaml

$ kubectl create -f http://down.belle.cn/package/kubernetes/v1.7.6/test_cluster/app_deploy_rc.yaml

$ kubectl create -f http://down.belle.cn/package/kubernetes/v1.7.6/test_cluster/app_deploy_service.yaml

$ kubectl get pods --all-namespaces -o=wide  | grep nginx
dev-web       nginx.1.10.1-flrrt                         1/1       Running   0          34s       192.168.224.129   zabbix-46
```

app_namespace.yaml

```sh
kind: Namespace
apiVersion: v1
metadata:
  name: dev-web
```

app_deploy_rc.yaml

```sh
kind: ReplicationController
apiVersion: v1
metadata:
  name: nginx.1.10.1
  namespace: dev-web
  labels:
    name: nginx
    version: "1.10.1"
spec:
  replicas: 1
  selector:
    name: nginx
    version: "1.10.1"
  template:
    metadata:
      labels:
        name: nginx
        version: "1.10.1"
    spec:
      imagePullSecrets:
      - name: reg.blf1.org
      containers:
      - name: nginx
        image: reg.blf1.org/tools/nginx:1.10.1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        env:
        - name: TZ
          value: "Asia/Shanghai"
        command: ["nginx", "-g", "daemon off;"]
        resources:
          requests:
            cpu: 50m
            memory: 50Mi
          limits:
            cpu: 100m
            memory: 100Mi
```

app_deploy_service.yaml

```sh
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: dev-web
  labels:
    name: nginx
spec:
  type: NodePort
  ports:
  - port: 80
    name: container-port
    nodePort: 30800
  selector:
    name: nginx
```

---

至此，kubernetes高可用集群成功部署。

### 其他参考资料

> * [kubernetes 1.7.3 + calico 多 Master](https://jicki.me/2017/08/08/kubernetes-1.7.3/)
> * [k8s kubeadm部署高可用集群](http://www.cnblogs.com/caiwenhao/p/6196014.html)

