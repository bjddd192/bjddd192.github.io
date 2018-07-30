---
layout: "post"
title: "mac-docker-test"
date: "2017-12-05 11:47:11"
description: 
categories: 
tags: 
keywords: 
---

* content
{:toc}

docker stop my_centos01 && docker rm -v my_centos01  

sudo docker run --privileged -d --name my_centos01 -p 50022:50022 \
  -v /Users/yanglei/03_docker/docker_test/my_centos01/cgroup:/sys/fs/cgroup \
  -v /Users/yanglei/03_docker/docker_test/my_centos01/docker:/var/lib/docker \
  registry.eyd.com:5000/basic/centos:7.3.1611.dind


docker stop my_centos02 && docker rm -v my_centos02  

sudo docker run --privileged -d --name my_centos02 -p 50122:50022 \
  -v /Users/yanglei/03_docker/docker_test/my_centos02/cgroup:/sys/fs/cgroup \
  -v /Users/yanglei/03_docker/docker_test/my_centos02/docker:/var/lib/docker \
  registry.eyd.com:5000/basic/centos:7.3.1611.dind

先建立目录，并映射好卷才能有权限挂载文件夹。

wget http://down.belle.cn/package/docker-engine-selinux-1.12.5-1.el7.centos.noarch.rpm

wget http://down.belle.cn/package/docker-engine-1.12.5-1.el7.centos.x86_64.rpm

curl -sSL https://get.daocloud.io/docker | sh
yum list installed | grep docker
yum -y remove docker-engine.x86_64
yum -y remove docker-engine-selinux.noarch
yum -y remove docker-ce.x86_64
yum -y remove docker-selinux
rpm -ivh docker-engine-selinux-1.12.5-1.el7.centos.noarch.rpm
rpm -ivh docker-engine-1.12.5-1.el7.centos.x86_64.rpm
rm -rf docker-engine-*
systemctl restart docker

echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-arptables = 1" >> /etc/sysctl.conf
/sbin/sysctl -p
cat /etc/sysctl.conf

tee /etc/docker/daemon.json <<-'EOF'
{
  "ip-forward": true,
  "bip": "192.169.100.1/24",
  "registry-mirrors": [
    "http://7c81ea9c.m.daocloud.io"
  ],
  "insecure-registries": [
    "registry.eyd.com:5000"
  ]
}
EOF

systemctl daemon-reload && systemctl enable docker && systemctl restart docker && systemctl status docker

---

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [ん乖乖龙ん](https://bjddd192.github.io) 所有。