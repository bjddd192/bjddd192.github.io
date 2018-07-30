---
layout: post
title: 在 centos7.x 上安装 mysql5.6.x
date: 2017-10-20 09:41:30 +0800
description: 在 centos7.x 上安装 mysql5.6.x
categories: mysql
tags: mysql
keywords: mysql centos mysql5.6 centos7
---

* content
{:toc}

做为兼职DBA，安装 mysql 已经好多次了，记得最初是在 centos6.5 上安装 mysql，到最近玩容器了，经常需要在 centos7 上安装软件，与容器版的 mysql 相比，我觉得数据库还是直接在机器安装更好，一个是我没有网络存储，另外就是在容器内安装不好区分安装目录，都是在一个文件夹，与我的习惯有冲突。这都是些题外话，下面开始分享记录一下安装的整个过程。




### 镜像准备

* gcr.io/google_containers/kube-state-metrics:v1.1.0
* prom/node-exporter:v0.15.0


### kube-state-metrics

[kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)

### 创建命名空间

```
mkdir /usr/local/prometheus
```

#### /usr/local/prometheus/namespace.yaml

``` yaml
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
```

#### /usr/local/prometheus/exporter-daemonset.yaml

``` yaml
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: prometheus-node-exporter
  namespace: monitoring
  labels:
    app: prometheus
    component: node-exporter
spec:
  template:
    metadata:
      name: prometheus-node-exporter
      labels:
        app: prometheus
        component: node-exporter
    spec:
      containers:
      - image: reg.blf1.org/prom/node-exporter:v0.15.0
        name: prometheus-node-exporter
        ports:
        - name: prom-node-exp
          #^ must be an IANA_SVC_NAME (at most 15 characters, ..)
          containerPort: 9100
          hostPort: 9100
      hostNetwork: true
      hostPID: true
```

#### /usr/local/prometheus/exporter-service.yaml

``` yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    prometheus.io/scrape: 'true'
  name: prometheus-node-exporter
  namespace: monitoring
  labels:
    app: prometheus
    component: node-exporter
spec:
  clusterIP: None
  ports:
    - name: prometheus-node-exporter
      port: 9100
      protocol: TCP
  selector:
    app: prometheus
    component: node-exporter
  type: ClusterIP
```

```sh 
kubectl create -f /usr/local/prometheus/namespace.yaml
namespace "monitoring" created

kubectl get namespace | grep monitoring
monitoring    Active    6m

kubectl create -f /usr/local/prometheus/rbac.yaml
clusterrolebinding "kube-state-metrics" created
clusterrole "kube-state-metrics" created
serviceaccount "kube-state-metrics" created
clusterrolebinding "prometheus" created
clusterrole "prometheus" created
serviceaccount "prometheus-k8s" created

kubectl create -f /usr/local/prometheus/exporter-service.yaml
service "prometheus-node-exporter" created

kubectl create -f /usr/local/prometheus/exporter-daemonset.yaml
daemonset "prometheus-node-exporter" created

kubectl -n monitoring get daemonset,svc
NAME                          DESIRED   CURRENT   READY     UP-TO-DATE   AVAILABLE   NODE-SELECTOR   AGE
ds/prometheus-node-exporter   3         3         1         3            1           <none>          33s

NAME                           CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
svc/prometheus-node-exporter   None         <none>        9100/TCP   39s

# 访问 http://172.20.32.46:9100/ 进行验证

```





### 参考资料

[Prometheus官网的非官方中文手册](https://github.com/1046102779/prometheus)

[Kubernetes 1.6 部署prometheus和grafana（数据持久）](http://blog.csdn.net/wenwst/article/details/76624019)

[kube-prometheus](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus)

[用 Prometheus 来监控你的 Kubernetes 集群](https://www.kubernetes.org.cn/1954.html)

---

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [Mars丶小石头](https://www.zorin.xin) 所有。
