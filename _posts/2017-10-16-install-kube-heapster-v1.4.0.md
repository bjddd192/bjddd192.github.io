---
layout: post
title: install kubernetes-heapster v1.4.0
date: 2017-10-16 18:33:30 +0800
description: 安装 kubernetes-heapster v1.4.0
categories: kubernetes
tags: heapster
keywords: kubernetes heapster
---

* content
{:toc}

在我的上篇文章[《kubeadm的kubernetes高可用集群v1.76部署》](https://bjddd192.github.io/kubernetes/2017/09/29/kubeadm-ha-v1.76.html)完成后，我们会很想将整个集群监控起来，[heapster + influxdb + grafana](https://github.com/kubernetes/heapster) 是kubernetes官方推荐的方案。而我在v1.4的k8s集群就已经使用过此方案，正所谓轻车熟路，[官方的教程](https://github.com/kubernetes/heapster/blob/master/docs/influxdb.md)也很简单，不过一代补丁一代神，因为东西比较新，直接按官方文档部署，还是遇到了不少坑。在这里记录一下我的解决方案，给困惑的朋友一些帮助。




### 集群环境说明

 主机名 | IP地址 | 说明 
 :--- | :--- | :--- 
 k8s-m44 | 172.20.32.44 | master节点1
 k8s-m45 | 172.20.32.45 | master节点2
 k8s-m47 | 172.20.32.47 | master节点3
 无 | 172.20.32.78 | master keepalived虚拟IP
 zabbix-46 | 172.20.32.46 | node节点

### 开启 cAdvisor

cAdvisor是谷歌开源的一个容器监控工具，该工具提供了webUI和REST API两种方式来展示数据，从而可以帮助管理者了解主机以及容器的资源使用情况和性能数据。

cAdvisor集成到了kubelet组件内，因此在k8s集群中每个启动了kubelet的节点可以使用cAdvisor来查看该节点的运行数据。cAdvisor对外提供web服务的默认端口为4194，rest API服务端口默认为10255.

kubeadm v1.76版本默认关闭了cAdvisor，由于Heapster需要通过cAdvisor的API采集监控数据，因此需要修改配置文件以开启：

```sh
$ sed -i 's/cadvisor-port=0/cadvisor-port=4194/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

$ systemctl daemon-reload &&  systemctl restart kubelet
```

开启之后，分别访问集群的各节点cAdvisor的web服务，如：

```
http://172.20.32.44:4194
http://172.20.32.45:4194
http://172.20.32.46:4194
http://172.20.32.47:4194
```

发现可以正常访问以下页面说明开启成功：

![cAdvisor](/assets/2017-10-16-install-kube-heapster-v1.4.0/cAdvisor.jpg)

---

### 部署 Heapster

首先git clone官网的代码文件，使用官方命令：

```
$ kubectl create -f deploy/kube-config/influxdb/
$ kubectl create -f deploy/kube-config/rbac/heapster-rbac.yaml
```

发现可以部署成功，但是查看heapster容器的日志，会发现大量的报错，如下：

```sh
E1016 12:26:38.469563       1 reflector.go:190] k8s.io/heapster/metrics/processors/namespace_based_enricher.go:84: Failed to list *v1.Namespace: Get https://kubernetes.default/api/v1/namespaces?resourceVersion=0: dial tcp: lookup kubernetes.default on 10.96.0.10:53: no such host
```

说明，heapster访问k8s的API出了问题，对比之前v1.4版本的成功案例，发现需要修改以下内容：

```
        - --source=kubernetes:https://kubernetes.default
        - --sink=influxdb:http://monitoring-influxdb.kube-system.svc:8086
```

为：

```
        - --source=kubernetes:https://172.20.32.78:6443
        - --sink=influxdb:http://172.20.32.78:32086
```

其中`https://172.20.32.78:6443`为master API的地址，`http://172.20.32.78:32086`为influxdb暴露的地址。

master API的地址可以使用下列方式查看，我使用的是vip的地址：

```sh
$ kubectl cluster-info
Kubernetes master is running at https://172.20.32.45:6443
Heapster is running at https://172.20.32.45:6443/api/v1/namespaces/kube-system/services/heapster/proxy
KubeDNS is running at https://172.20.32.45:6443/api/v1/namespaces/kube-system/services/kube-dns/proxy
```

修改完成后再次部署heapster：

```
kubectl delete -f http://down.belle.cn/package/kubernetes/v1.7.6/heapster/grafana.yaml
kubectl delete -f http://down.belle.cn/package/kubernetes/v1.7.6/heapster/heapster.yaml
kubectl delete -f http://down.belle.cn/package/kubernetes/v1.7.6/heapster/influxdb.yaml
kubectl delete -f http://down.belle.cn/package/kubernetes/v1.7.6/heapster/heapster-rbac.yaml

kubectl create -f http://down.belle.cn/package/kubernetes/v1.7.6/heapster/heapster-rbac.yaml
kubectl create -f http://down.belle.cn/package/kubernetes/v1.7.6/heapster/influxdb.yaml
kubectl create -f http://down.belle.cn/package/kubernetes/v1.7.6/heapster/heapster.yaml
kubectl create -f http://down.belle.cn/package/kubernetes/v1.7.6/heapster/grafana.yaml
```

然后查看heapster的容器日志，发现已经运行正常：

```
I1017 00:57:40.252906       1 heapster.go:72] /heapster --source=kubernetes:https://172.20.32.78:6443 --sink=influxdb:http://172.20.32.78:32086 --metric_resolution=60s
I1017 00:57:40.252993       1 heapster.go:73] Heapster version v1.4.0
I1017 00:57:40.253540       1 configs.go:61] Using Kubernetes client with master "https://172.20.32.78:6443" and version v1
I1017 00:57:40.253576       1 configs.go:62] Using kubelet port 10255
I1017 00:57:40.365717       1 influxdb.go:278] created influxdb sink with options: host:172.20.32.78:32086 user:root db:k8s
I1017 00:57:40.365779       1 heapster.go:196] Starting with InfluxDB Sink
I1017 00:57:40.365800       1 heapster.go:196] Starting with Metric Sink
I1017 00:57:40.953964       1 heapster.go:106] Starting heapster on port 8082
I1017 00:58:07.351947       1 influxdb.go:241] Created database "k8s" on influxDB server at "172.20.32.78:32086"
```

---

### 我的yaml文件

**说明：我的镜像已经下载到了私仓，使用的是内部仓库地址。**

**`reg.blf1.org/k8s`等同于`gcr.io/google_containers`。**

#### heapster-rbac.yaml（权限）

```yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: heapster
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:heapster
subjects:
- kind: ServiceAccount
  name: heapster
  namespace: kube-system
```

#### influxdb.yaml（数据库）

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: monitoring-influxdb
  namespace: kube-system
spec:
  replicas: 1
  template:
    metadata:
      labels:
        task: monitoring
        k8s-app: influxdb
    spec:
      containers:
      - name: influxdb
        # image: gcr.io/google_containers/heapster-influxdb-amd64:v1.3.3
        image: reg.blf1.org/k8s/heapster-influxdb-amd64:v1.3.3
        volumeMounts:
        - mountPath: /data
          name: influxdb-storage
      volumes:
      - name: influxdb-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  labels:
    task: monitoring
    # For use as a Cluster add-on (https://github.com/kubernetes/kubernetes/tree/master/cluster/addons)
    # If you are NOT using this as an addon, you should comment out this line.
    kubernetes.io/cluster-service: 'true'
    kubernetes.io/name: monitoring-influxdb
  name: monitoring-influxdb
  namespace: kube-system
spec:
  type: NodePort
  ports:
  - port: 8086
    targetPort: 8086
    nodePort: 32086
  selector:
    k8s-app: influxdb
```

#### heapster.yaml（采集器）

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: heapster
  namespace: kube-system
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: monitoring-heapster
  namespace: kube-system
spec:
  replicas: 1
  template:
    metadata:
      labels:
        task: monitoring
        k8s-app: heapster
    spec:
      serviceAccountName: heapster
      containers:
      - name: heapster
        # image: gcr.io/google_containers/heapster-amd64:v1.4.0
        image: reg.blf1.org/k8s/heapster-amd64:v1.4.0
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            cpu: 50m
            memory: 100Mi
          requests:
            cpu: 50m
            memory: 100Mi
        command:
        - /heapster
        - --source=kubernetes:https://172.20.32.78:6443
        - --sink=influxdb:http://172.20.32.78:32086
---
apiVersion: v1
kind: Service
metadata:
  labels:
    task: monitoring
    # For use as a Cluster add-on (https://github.com/kubernetes/kubernetes/tree/master/cluster/addons)
    # If you are NOT using this as an addon, you should comment out this line.
    kubernetes.io/cluster-service: 'true'
    kubernetes.io/name: Heapster
  name: heapster
  namespace: kube-system
spec:
  ports:
  - port: 80
    targetPort: 8082
  selector:
    k8s-app: heapster
```

#### grafana.yaml（展示UI）

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: monitoring-grafana
  namespace: kube-system
spec:
  replicas: 1
  template:
    metadata:
      labels:
        task: monitoring
        k8s-app: grafana
    spec:
      containers:
      - name: grafana
        # image: gcr.io/google_containers/heapster-grafana-amd64:v4.4.3
        image: reg.blf1.org/k8s/heapster-grafana-amd64:v4.4.3
        ports:
        - containerPort: 3000
          protocol: TCP
        volumeMounts:
        - mountPath: /etc/ssl/certs
          name: ca-certificates
          readOnly: true
        - mountPath: /var
          name: grafana-storage
        env:
        - name: INFLUXDB_HOST
          value: monitoring-influxdb
        - name: GF_SERVER_HTTP_PORT
          value: "3000"
          # The following env variables are required to make Grafana accessible via
          # the kubernetes api-server proxy. On production clusters, we recommend
          # removing these env variables, setup auth for grafana, and expose the grafana
          # service using a LoadBalancer or a public IP.
        - name: GF_AUTH_BASIC_ENABLED
          value: "false"
        - name: GF_AUTH_ANONYMOUS_ENABLED
          value: "true"
        - name: GF_AUTH_ANONYMOUS_ORG_ROLE
          value: Admin
        - name: GF_SECURITY_ADMIN_USER
          value: root
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: dockerMan
        - name: GF_SECURITY_LOGIN_REMEMBER_DAYS
          value: "1"
        - name: GF_USERS_ALLOW_SIGN_UP
          value: "false"
        - name: GF_USERS_DEFAULT_THEME
          value: dark # Default UI theme ("dark" or "light")
        - name: GF_SERVER_ROOT_URL
          # If you're only using the API Server proxy, set this value instead:
          # value: /api/v1/proxy/namespaces/kube-system/services/monitoring-grafana/
          value: /
      volumes:
      - name: ca-certificates
        hostPath:
          path: /etc/ssl/certs
      - name: grafana-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  labels:
    # For use as a Cluster add-on (https://github.com/kubernetes/kubernetes/tree/master/cluster/addons)
    # If you are NOT using this as an addon, you should comment out this line.
    kubernetes.io/cluster-service: 'true'
    kubernetes.io/name: monitoring-grafana
  name: monitoring-grafana
  namespace: kube-system
spec:
  # In a production setup, we recommend accessing Grafana through an external Loadbalancer
  # or through a public IP.
  # type: LoadBalancer
  # You could also use NodePort to expose the service at a randomly-generated port
  type: NodePort
  ports:
  - port: 80
    targetPort: 3000
    nodePort: 32080
  selector:
    k8s-app: grafana
```

### 配置Grafana

部署完成后，访问地址：`http://172.20.32.78:32080`，发现界面会报错：

```
Templating init failed
Network Error: Bad Gateway(502)
```

这时需要修改 data source：

![grafana](/assets/2017-10-16-install-kube-heapster-v1.4.0/grafana.jpg)

将Url改为：http://172.20.32.78:32086，Access改为：direct，即可正常使用grafana了。

至此，heapster部署成功。

---

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [ん乖乖龙ん](https://bjddd192.github.io) 所有。
