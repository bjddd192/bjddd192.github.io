---
layout: post
title: install kubernetes-dashboard v1.7.1
date: 2017-10-17 17:41:30 +0800
description: 安装 kubernetes-dashboard v1.7.1
categories: kubernetes
tags: dashboard
keywords: kubernetes dashboard
---

在部署完heapster后（参考：[install kubernetes-heapster v1.4.0](https://bjddd192.github.io/kubernetes/2017/10/16/install-kube-heapster-v1.4.0.html)），发现看板的监控数据一直上不来，而grafana中能够正常展示监控数据：

![dashboard](/assets/2017-10-17-install-kube-dashboard-v1.7.1/dashboard.jpg)

这就有点奇怪了，很多网友的帖子都表明部署完成heapster后dashboard就能自动展示出监控数据的，于是我就想，是不是因为我的dashboard版本是kubernetes-dashboard-amd64:v1.6.3，不支持最新的v1.76集群的缘故。于是我顺藤摸瓜，找到了[dashboard官网](https://github.com/kubernetes/dashboard)，以及[安装手册](https://github.com/kubernetes/dashboard/wiki/Installation)，发现真的有收获，官方已经出了kubernetes-dashboard-amd64:v1.7.1的版本，并且增加了RBAC的内容。貌似看到了曙光，得马上试试看。




### kubernetes-dashboard.yaml

本文件来源与官网：

```
wget https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
```

**说明：我的镜像已经下载到了私仓，使用的是内部仓库地址。**

**`reg.blf1.org/k8s`等同于`gcr.io/google_containers`。**

```yaml
# Copyright 2015 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Configuration to deploy release version of the Dashboard UI compatible with
# Kubernetes 1.7.
#
# Example usage: kubectl create -f <this_file>

# ------------------- Dashboard Secret ------------------- #

apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-certs
  namespace: kube-system
type: Opaque

---
# ------------------- Dashboard Service Account ------------------- #

apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system

---
# ------------------- Dashboard Role & Role Binding ------------------- #

kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: kubernetes-dashboard-minimal
  namespace: kube-system
rules:
  # Allow Dashboard to create and watch for changes of 'kubernetes-dashboard-key-holder' secret.
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["create", "watch"]
- apiGroups: [""]
  resources: ["secrets"]
  # Allow Dashboard to get, update and delete 'kubernetes-dashboard-key-holder' secret.
  resourceNames: ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs"]
  verbs: ["get", "update", "delete"]
  # Allow Dashboard to get metrics from heapster.
- apiGroups: [""]
  resources: ["services"]
  resourceNames: ["heapster"]
  verbs: ["proxy"]

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: kubernetes-dashboard-minimal
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: kubernetes-dashboard-minimal
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system

---
# ------------------- Dashboard Deployment ------------------- #

kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kubernetes-dashboard
  template:
    metadata:
      labels:
        k8s-app: kubernetes-dashboard
    spec:
      initContainers:
      - name: kubernetes-dashboard-init
        image: reg.blf1.org/k8s/kubernetes-dashboard-init-amd64:v1.0.1
        volumeMounts:
        - name: kubernetes-dashboard-certs
          mountPath: /certs
      containers:
      - name: kubernetes-dashboard
        image: reg.blf1.org/k8s/kubernetes-dashboard-amd64:v1.7.1
        ports:
        - containerPort: 9090
          protocol: TCP
        args:
          - --tls-key-file=/certs/dashboard.key
          - --tls-cert-file=/certs/dashboard.crt
          # - --authentication-mode=basic
          # Uncomment the following line to manually specify Kubernetes API server Host
          # If not specified, Dashboard will attempt to auto discover the API server and connect
          # to it. Uncomment only if the default does not work.
          # - --apiserver-host=http://my-address:port
        volumeMounts:
        - name: kubernetes-dashboard-certs
          mountPath: /certs
          readOnly: true
          # Create on-disk volume to store exec logs
        - mountPath: /tmp
          name: tmp-volume
        livenessProbe:
          httpGet:
            scheme: HTTPS
            path: /
            port: 8443
          initialDelaySeconds: 30
          timeoutSeconds: 30
      volumes:
      - name: kubernetes-dashboard-certs
        secret:
          secretName: kubernetes-dashboard-certs
      - name: tmp-volume
        emptyDir: {}
      serviceAccountName: kubernetes-dashboard
      # Comment the following tolerations if Dashboard must not be deployed on master
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule

---
# ------------------- Dashboard Service ------------------- #

kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  ports:
  - port: 443
    targetPort: 8443
    nodePort: 30080
  type: NodePort
  selector:
    k8s-app: kubernetes-dashboard
```

---

### 部署 dashboard

不废话，直接上脚本：

``` sh
# 删除v1.63的老版本
kubectl delete -f http://down.belle.cn/package/kubernetes/v1.7.6/kube-dashboard.yaml

kubectl create -f http://down.belle.cn/package/kubernetes/v1.7.6/kube-dashboard-v1.7.1/kubernetes-dashboard.yaml
```

部署完成后访问地址：https://172.20.32.78:30080，发现增加了一个登录验证的界面：

![login](/assets/2017-10-17-install-kube-dashboard-v1.7.1/login.jpg)

完全不知道要填啥，我试了下将kubeconfig文件拷贝到本地，然后用文件登录，发现无法登录，报错如下：

![error1](/assets/2017-10-17-install-kube-dashboard-v1.7.1/error1.jpg)

于是先SKIP跳过进去看看，发现能进去，却什么数据都看不了：

![error2](/assets/2017-10-17-install-kube-dashboard-v1.7.1/error2.jpg)

这下就很纳闷了，不知道哪里有问题。直到google到这篇文章：[使用kubeadm安装Kubernetes 1.8](http://blog.frognew.com/2017/09/kubeadm-install-kubernetes-1.8.html#8dashboard%E6%8F%92%E4%BB%B6%E9%83%A8%E7%BD%B2)，文中提到 kubernetes-dashboard.yaml 文件中的 ServiceAccount `kubernetes-dashboard` 只有相对较小的权限，因此需要创建一个 `kubernetes-dashboard-admin` 的 ServiceAccount 并授予集群 admin 的权限，真是非常感谢作者的分享。大致操作如下：

* 创建 kubernetes-dashboard-admin.rbac.yaml

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-admin
  namespace: kube-system
  
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard-admin
  labels:
    k8s-app: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard-admin
  namespace: kube-system
```

* 执行创建

```sh
$ kubectl create -f http://down.belle.cn/package/kubernetes/v1.7.6/kube-dashboard-v1.7.1/kubernetes-dashboard-admin.rbac.yaml
serviceaccount "kubernetes-dashboard-admin" created
clusterrolebinding "kubernetes-dashboard-admin" created
```

* 获取 `kubernetes-dashboard-admin` 的 `token`

```sh
$ kubectl -n kube-system get secret | grep kubernetes-dashboard-admin
kubernetes-dashboard-admin-token-8b3zs   kubernetes.io/service-account-token   3         8s

$ kubectl describe secret kubernetes-dashboard-admin-token-8b3zs -n kube-system > kubernetes-dashboard-admin.token

$ cat kubernetes-dashboard-admin.token
Name:		kubernetes-dashboard-admin-token-8b3zs
Namespace:	kube-system
Labels:		<none>
Annotations:	kubernetes.io/service-account.name=kubernetes-dashboard-admin
		kubernetes.io/service-account.uid=53b90385-b309-11e7-9995-00505692276a

Type:	kubernetes.io/service-account-token

Data
====
ca.crt:		1025 bytes
namespace:	11 bytes
token:		eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJrdWJlcm5ldGVzLWRhc2hib2FyZC1hZG1pbi10b2tlbi04YjN6cyIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJrdWJlcm5ldGVzLWRhc2hib2FyZC1hZG1pbiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjUzYjkwMzg1LWIzMDktMTFlNy05OTk1LTAwNTA1NjkyMjc2YSIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTprdWJlcm5ldGVzLWRhc2hib2FyZC1hZG1pbiJ9.iVLKcLltQLfDrt8_oNFvlbTDKk6LxBH4brSM5_CcI34MkJMskd5fXRLEreqCmeJ3uP06ZrpJq4-LrgUGHlvQ1g4WObogsmfnSfadN6K6LGehItCmEZcaJ02fXkNGvQ6hEilIWXehBTak_dZXsBloKL23DY7UWdJIyc2cvdKN1yT39tDl2tRt6jcMiK3FpWxQoNxSMBwhh-rXYNZ_u-3rhnfXwlNKOeX3C7HGgsdZbPN44xbkpY6c1Fvv-e7vjeDT0kBSkVYFjA7GuTHv9opEjGFhoUiLjW29Yj58CL1xsGVOik3j96S7pg9ZtOsKPpGjFEtBvE1SCdvoyTKm71hO5g
```

将长长的 `token` 复制出来，**注意：不能换行哦**，然后选择 token 登录方式，即可看到期盼已久的看板数据了：

![dashboard](/assets/2017-10-17-install-kube-dashboard-v1.7.1/dashboard.jpg)

### 总结

1.7.x 版本的 dashboard 对安全做了增强，默认需要以 https 的方式访问，增加了登录的认证页面，同时增加了一个 `gcr.io/google_containers/kubernetes-dashboard-init-amd64` 的 init 容器。

个人感觉这个是安全性里程碑的更新，真心不错，用新东西也总是惊喜不断啊。

不过对于 RBAC 权限这块我还是比较陌生，下次找个时间好好学习一下。


### 参考资料

[Kubernetes Dashboard 1.7.0部署二三事](http://tonybai.com/2017/09/26/some-notes-about-deploying-kubernetes-dashboard-1-7-0/)

[使用kubeadm安装Kubernetes 1.8](http://blog.frognew.com/2017/09/kubeadm-install-kubernetes-1.8.html#8dashboard%E6%8F%92%E4%BB%B6%E9%83%A8%E7%BD%B2)

---

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [Mars丶小石头](https://www.zorin.xin) 所有。
