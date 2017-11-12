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

这是一篇翻译的文章，原文为《[Kubernetes v1.7 security in practice](https://acotten.com/post/kube17-security)》。




安全问题一直被Kubernetes社区长期关注。尽管项目在过去两年中的收获和贡献方面取得了显着的增长，但由于其相对绿色的安全模式，许多组织似乎仍然以非常谨慎的态度对待其生态系统。

我见证了一个竞争对手在销售谈话中正确地提出了这个论点，不禁想到了自己运行Kubernetes的经历。在这一点上，我只运行了所有用户在某种意义上被信任的集群：经过培训，负责，在同一个项目上一起工作。默认无授权方案，以纯文本存储的应用程序机密都不是在特定上下文中的关注。但是，假如这些集群现在落在了多个团队的手中，如何更合理地划分访问权限，减少人为的错误发生呢？

上周五发布的Kubernetes v1.7.0演示了通过引入一系列强化集群功能的功能，使得项目参与者在使用基于角色的访问控制（RBAC）授权模式带来的连续性方面表明了这一点。在这篇文章中，我将展示如何将这些新概念应用到正在运行的集群中，并提供几个例子。

### RBAC（提醒）

RBAC授权模式是在Kubernetes v1.6.0中被评为beta版本的功能。它在Kubernetes参考文档中有一个专用页面：使用RBAC授权。如果您已经熟悉它，请随时跳到下一个标题。

使用RBAC授权模式，默认情况下，Kubernetes REST API上的任何操作都被拒绝。通过显式模型选择性地授予权限，其中一组“动词”（HTTP方法）与一组“资源”（Pods，Services，Nodes，...）相关联。这些权限被分组到可以应用于单个命名空间（Role）或整个集群（ClusterRole）的角色内。然后可以使用绑定将角色分配给用户，组和/或应用程序（ServiceAccount）。

当apisever开始启用标志--authorization-mode=RBAC，它会自动创建一组默认角色和绑定，如下所示：

```sh
$ kubectl get clusterroles
NAME                                           AGE
admin                                          25d
calico-cni-plugin                              25d
calico-policy-controller                       25d
cluster-admin                                  25d
edit                                           25d
kube-state-metrics                             1d
kubeadm:node-autoapprove-bootstrap             25d
prometheus                                     1d
system:auth-delegator                          25d
system:basic-user                              25d
system:controller:attachdetach-controller      25d
system:controller:certificate-controller       25d
system:controller:cronjob-controller           25d
system:controller:daemon-set-controller        25d
system:controller:deployment-controller        25d
system:controller:disruption-controller        25d
system:controller:endpoint-controller          25d
system:controller:generic-garbage-collector    25d
system:controller:horizontal-pod-autoscaler    25d
system:controller:job-controller               25d
system:controller:namespace-controller         25d
system:controller:node-controller              25d
system:controller:persistent-volume-binder     25d
system:controller:pod-garbage-collector        25d
system:controller:replicaset-controller        25d
system:controller:replication-controller       25d
system:controller:resourcequota-controller     25d
system:controller:route-controller             25d
system:controller:service-account-controller   25d
system:controller:service-controller           25d
system:controller:statefulset-controller       25d
system:controller:ttl-controller               25d
system:discovery                               25d
system:heapster                                25d
system:kube-aggregator                         25d
system:kube-controller-manager                 25d
system:kube-dns                                25d
system:kube-scheduler                          25d
system:node                                    25d
system:node-bootstrapper                       25d
system:node-problem-detector                   25d
system:node-proxier                            25d
system:persistent-volume-provisioner           25d
view                                           25d
```

角色system:kube-dns由Kubernetes DNS附加组件使用。我们来检查和解密它：

```sh
kubectl describe clusterrole system:kube-dns
Name:           system:kube-dns
Labels:         kubernetes.io/bootstrapping=rbac-defaults
Annotations:    rbac.authorization.kubernetes.io/autoupdate=true
PolicyRule:
  Resources     Non-Resource URLs       Resource Names  Verbs
  ---------     -----------------       --------------  -----
  endpoints     []                      []              [list watch]
  services      []                      []              [list watch]
```

该ClusterRole允许其主体列出和查看指定为Endpoint和Service类型的资源。它没有以任何方式更新、删除、修改这些资源的权限，也不能创建此类型的新资源）。

对于几乎每个默认的ClusterRole，Kubernetes创建一个相应的ClusterRoleBinding：

```sh 
$ kubectl get clusterrolebinding
NAME                                           AGE
calico-cni-plugin                              25d
calico-policy-controller                       25d
cluster-admin                                  25d
heapster                                       16d
kube-state-metrics                             1d
kubeadm:kubelet-bootstrap                      25d
kubeadm:node-autoapprove-bootstrap             25d
kubeadm:node-proxier                           25d
kubernetes-dashboard-admin                     16d
prometheus                                     1d
system:basic-user                              25d
system:controller:attachdetach-controller      25d
system:controller:certificate-controller       25d
system:controller:cronjob-controller           25d
system:controller:daemon-set-controller        25d
system:controller:deployment-controller        25d
system:controller:disruption-controller        25d
system:controller:endpoint-controller          25d
system:controller:generic-garbage-collector    25d
system:controller:horizontal-pod-autoscaler    25d
system:controller:job-controller               25d
system:controller:namespace-controller         25d
system:controller:node-controller              25d
system:controller:persistent-volume-binder     25d
system:controller:pod-garbage-collector        25d
system:controller:replicaset-controller        25d
system:controller:replication-controller       25d
system:controller:resourcequota-controller     25d
system:controller:route-controller             25d
system:controller:service-account-controller   25d
system:controller:service-controller           25d
system:controller:statefulset-controller       25d
system:controller:ttl-controller               25d
system:discovery                               25d
system:kube-controller-manager                 25d
system:kube-dns                                25d
system:kube-scheduler                          25d
system:node                                    25d
system:node-proxier                            25d
```

让我们看看使用system:kube-dns角色允许访问什么subject：

```sh
$ kubectl describe clusterrolebinding system:kube-dns
Name:           system:kube-dns
Labels:         kubernetes.io/bootstrapping=rbac-defaults
Annotations:    rbac.authorization.kubernetes.io/autoupdate=true
Role:
  Kind: ClusterRole
  Name: system:kube-dns
Subjects:
  Kind                  Name            Namespace
  ----                  ----            ---------
  ServiceAccount        kube-dns        kube-system
```

### 参考资料

[使用RBAC授权](https://kubernetes.io/docs/admin/authorization/rbac/)

[Kubernetes 1.6 部署prometheus和grafana（数据持久）](http://blog.csdn.net/wenwst/article/details/76624019)

[kube-prometheus](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus)

[用 Prometheus 来监控你的 Kubernetes 集群](https://www.kubernetes.org.cn/1954.html)

---

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [ん乖乖龙ん](https://bjddd192.github.io) 所有。
