---
layout: "post"
title: "Apache-Kylin学习"
date: "2018-05-28 14:06:12"
description: 
categories: 
tags: 
keywords: 
---

* content
{:toc}

[kylin官网](http://kylin.apache.org/cn/)

Apache Kylin是一个开源的分布式分析引擎。完全由eBay Inc.中国团队开发并贡献至开源社区。提供Hadoop之上的SQL查询接口及多维分析（MOLAP）能力以支持大规模数据能在亚秒内查询巨大的Hive表(十亿百亿的海量数据)。





大数据分析面临的挑战：

* Huge volume data (海量的数据)
* Table scan (表扫描)
* Big table joins (大表连接)
* Data shuffling (数据转移)
* Analysis on different granularity (多维度的分析)
* Runtime aggregation expensive (高昂的聚合成本)
* Map Reduce job (MapReduce job 程序)
* Batch processing (批处理)
* High Concurrency (高并发)

在现在的大数据时代，越来越多的企业开始使用Hadoop管理数据，但是现有的业务分析工具（如Tableau，Microstrategy等）往 往存在很大的局限，如难以水平扩展、无法处理超大规模数据、缺少对Hadoop的支持；而利用Hadoop做数据分析依然存在诸多障碍，例如大多数分析师 只习惯使用SQL，Hadoop难以实现快速交互式查询等等。神兽Apache Kylin就是为了解决这些问题而设计的。

Kylin的核心思想是预计算，即对多维分析可能用到的度量进行预计算，将计算好的结果保存成Cube，供查询时直接访问。把高复杂度的聚合运算、多表连接等操作转换成对预计算结果的查询，这决定了Kylin能够拥有很好的快速查询和高并发能力。

根据公开数据显示，Kylin的查询性能不只是针对个别的SQL，而是对上万种SQL的平均表现，生产环境下90%file查询能够在3s内返回。在上个月举办的Apache Kylin Meetup中，来自美团、京东、百度等互联网公司分享了他们的使用情况。例如在京东云海的案例中，单个Cube最大有8个维度，最大数据条数4亿，最大存储空间800G，30个Cube共占存储空间4T左右。查询性能上，当QPS在50左右，所有查询平均在200ms以内，当QPS在200左右，平均响应时间在1s以内。

目前，有越来越多的国内外公司将Kylin作为大数据生产环境中的重要组件，如eBay、银联、百度、中国移动等。

Apache Kylin旨在减少Hadoop在10亿及百亿规模以上数据级别的情况下的查询延迟，目前底层数据存储基于HBase，具有较强的可伸缩性。Apache Kylin为Hadoop数据提供了ANSI-SQL接口，并且支持大多数的ANSI-SQL的函数；能够支持在秒级别延迟的情况下同Hadoop进行交互式查询；支持多维联机分析处理数据仓库(MOLAP Cube);用户能够定义数据模型；并且通过Apache Kylin能够预建超过10多亿行原始记录的数据模型；可与其他BI工具无缝集成，包括Tableau，Excel，PowerBI等；并提供了JDBC，ODBC接口；可分布式部署，Query Server可以水平扩展，存储基于HBase也可以水平扩展。并且Apache Kylin将在后续版本支持流式近实时Cube计算，支持实时数据多维分析等各种场景。

### 名词解释

Mondrian

Mondrian是一个开源项目。一个用Java写成的OLAP（在线分析性处理）引擎。它用MDX语言实现查询，从关系数据库(RDBMS)中读取数据。然后经过Java API用多维的方式对结果进行展示。多维数据中，维度（dimension），层次（Hierarchies），级别(Level)等概念很重要。Mondrian是olap服务器，而不是数据仓库服务器，因此Mondrian的元数据主要包括olap建模的元数据，不包括从外部数据源到数据库转换的元数据。也就是说Mondria的元数据仅仅包括了多维逻辑模型，从关系型数据库到多维逻辑模型的映射，存取权限等信息。在功能上，Mondrian支持共享维和成员计算，支持星型模型和雪花模型的功能。

MOLAP

被人们称为Multidimension OLAP，简称MOLAP，是Arbor Software严格遵照Codd的定义，自行建立了多维数据库，来存放联机分析系统数据，开创了多维数据存储的先河，后来的很多家公司纷纷采用多维数据存储。代表产品有Hyperion(原Arbor Software) Essbase、Showcase Strategy等。

Calcite

Apache Calcite 是独立于存储与执行的SQL解析、优化引擎，广泛应用于各种离线、搜索、实时查询引擎，如Drill、Hive、Kylin、Solr、flink、Samza等。

dimension

维度

cardinality

我们称每一个dimension中不同成员个数为cardinatily。

measure

估量

partition

分割

Mandatory维度

这种维度意味着每次查询的group by中都会携带的，将某一个dimension设置为mandatory可以将cuboid的个数减少一半

hierarchy维度

这种维度是最常见的，尤其是在mondrian中，我们对于多维数据的操作经常会有上卷下钻之类的操作，这也就需要要求维度之间有层级关系，例如国家、省、城市，年、季度、月等。有层级关系的维度也可以大大减少cuboid的个数。

derived维度

这类维度的意思是可推导的维度，需要该维度对应的一个或者多个列可以和维度表的主键是一对一的，这种维度可以大大减少cuboid个数



### hadoop 安装

[官方下载地址](http://hadoop.apache.org/releases.html)

Hadoop是使用Java编写，允许分布在集群，使用简单的编程模型的计算机大型数据集处理的Apache的开源框架。 Hadoop框架应用工程提供跨计算机集群的分布式存储和计算的环境。 Hadoop是专为从单一服务器到上千台机器扩展，每个机器都可以提供本地计算和存储。

修改主机名

配置hosts

关闭防火墙

关闭selinux

安装jdk

安装Hadoop

export JAVA_HOME="/opt/modules/jdk1.8.0_102"
export PATH=$JAVA_HOME/bin:$PATH
export HADOOP_HOME=/opt/modules/hadoopstandalone/hadoop-3.1.0
export PATH=$HADOOP_HOME/bin:$PATH

source /etc/profile

vim $HADOOP_HOME/etc/hadoop/hadoop-env.sh

配置参数：
export JAVA_HOME=/opt/modules/jdk1.8.0_102
export HADOOP_HOME=/opt/modules/hadoopstandalone/hadoop-3.1.0
export HADOOP_CLASSPATH=${HADOOP_HOME}
export HADOOP_SSH_OPTS="-p 50022"

本地模式验证：

vim /opt/data.input
hadoop mapreduce hive
hbase spark storm  
sqoop hadoop hive
spark hadoop

cd /opt/modules/hadoopstandalone/hadoop-3.1.0
hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-3.1.0.jar wordcount /opt/data.input output

cd ./output
 
ls
part-r-00000  _SUCCESS
[root@9924149b17e0 output]# cat _SUCCESS 
[root@9924149b17e0 output]# cat part-r-00000 
hadoop  3
hbase   1
hive    2
mapreduce       1
spark   2
sqoop   1
storm   1

_success表示成功，统计结果方在part-r-00000文件中

伪分布式操作

vim $HADOOP_HOME/etc/hadoop/core-site.xml 
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://<hostname>:9000</value>
  </property>
</configuration>

vim $HADOOP_HOME/etc/hadoop/hdfs-site.xml
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
</configuration>

$ vim sbin/start-dfs.sh
$ vim sbin/stop-dfs.sh

在顶部空白处添加内容：
HDFS_DATANODE_USER=root
HADOOP_SECURE_DN_USER=hdfs
HDFS_NAMENODE_USER=root
HDFS_SECONDARYNAMENODE_USER=root

格式化配置HDFS文件系统
bin/hdfs namenode -format 
sbin/start-dfs.sh

jps 
3110 NameNode
6680 Jps
6348 DataNode
6557 SecondaryNameNode

hdfs dfs -mkdir /user
hdfs dfs -mkdir /user/yanglei
hdfs dfs -ls /user
hdfs dfs -put /tmp/yum.log /user/yanglei
hdfs dfs -ls /user/yanglei 
hdfs dfs -cat /user/yanglei/yum.log
bin/hdfs dfs -put etc/hadoop/*.xml /user/yanglei
bin/hdfs dfs -ls /user/yanglei 
bin/hdfs dfs -get /user/yanglei/yum.log /tmp/yum.log
bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-3.1.0.jar grep /user/yanglei output 'dfs[a-z.]+'
bin/hdfs dfs -ls .
bin/hdfs dfs -cat output/*
bin/hdfs dfs -rm output/*
bin/hdfs dfs -rmdir output/
sbin/stop-dfs.sh

启用yarn
vim $HADOOP_HOME/etc/hadoop/mapred-site.xml
<property>
	<name>mapreduce.framework.name</name>
	<value>yarn</value>
</property>

vim $HADOOP_HOME/etc/hadoop/yarn-site.xml
<property>
	<name>yarn.nodemanager.aux-services</name>
	<value>mapreduce_shuffle</value>
</property>

vim $HADOOP_HOME/sbin/start-yarn.sh
vim $HADOOP_HOME/sbin/stop-yarn.sh


$HADOOP_HOME/sbin/start-yarn.sh


#### 问题

1、如果在 namenode 上的 hdfs-site.xml 配置文件中没有设置 dfs.namenode.name.dir 这个项，那默认的存储目录是哪个？

默认在／tmp下。

#### 学习资料

[Hadoop易百教程](https://www.yiibai.com/hadoop/hadoop_10mins_start.html)

#### 参考资料

[HDFS知识点总结](https://www.cnblogs.com/caiyisen/p/7395843.html)

[分布式文件系统(HDFS）与linux系统文件系统关系](https://blog.csdn.net/qq_32041579/article/details/77752733)

[Hadoop YARN架构设计要点](http://shiyanjun.cn/archives/1119.html)

[理解Hadoop YARN架构](https://blog.csdn.net/bingduanlbd/article/details/51880019)

[Hadoop NameNode元数据相关文件目录解析](https://www.iteblog.com/archives/967.html)

[hadoop安装和本地模式实现](https://blog.csdn.net/hahachenchen789/article/details/79902758)

[Hadoop3-伪分布式模式安装](https://blog.csdn.net/kongxx/article/details/79350554)

[Hadoop3.1.0（伪分布式）安装教程](https://blog.csdn.net/sven119/article/details/79930878)

[hadoop3.1.0 HDFS快速搭建伪分布式环境](https://blog.csdn.net/Artisters/article/details/80101404)

[Centos7 安装Hadoop3.x 完全分布式部署](https://blog.csdn.net/afgasdg/article/details/79277926)

[Hadoop3.1.0完全分布式集群部署超详细记录](https://blog.csdn.net/dream_an/article/details/80258283)

[hadoop安装教程](https://www.cnblogs.com/xzjf/p/7231519.html)

[史上最详细的Hadoop环境搭建](http://gitbook.cn/books/5954c9600326c7705af8a92a/index.html)

[Hadoop3.0稳定版的安装部署](https://blog.csdn.net/rlnLo2pNEfx9c/article/details/78816075)

[Centos 7 搭建 Hadoop3.1教程](https://www.cnblogs.com/dxdxh/p/9015191.html)

[centos7下hadoop-3.1.0集群搭建](https://my.oschina.net/orrin/blog/1816023)

[ansible编写hadoop群集](http://blog.51cto.com/13120271/2104632?cid=704897)

[Ansible实战：部署分布式日志系统](https://www.cnblogs.com/zhaojiankai/p/7678700.html)

[ansible-hadoop](https://bitbucket.org/lalinsky/ansible-hadoop)

[hadoop-ansible](https://gitee.com/pippozq/hadoop-ansible)

[Hadoop参数汇总](https://segmentfault.com/a/1190000000709725)

[Hadoop配置文件参数详解](https://www.cnblogs.com/yinghun/p/6230436.html)

[Yarn下Mapreduce的内存参数理解](https://segmentfault.com/a/1190000003777237)

[YARN 内存参数终极详解](http://blog.51cto.com/meiyiprincess/1747113)

### Hive

Hive适合用来对一段时间内的数据进行分析查询，例如，用来计算趋势或者网站的日志。Hive不应该用来进行实时的查询。因为它需要很长时间才可以返回结果。

#### 安装

准备一个mysql库

```sql
create database db_metastore;
grant all on db_metastore.* to hive@'%'  identified by 'hive';
flush privileges;
```

#### 参考资料

[Hive学习之Metastore及其配置管理](https://blog.csdn.net/skywalker_only/article/details/26219619)

[hive配置参数的说明](http://www.cnblogs.com/duanxingxing/p/4535842.html)

### HBase

Hbase非常适合用来进行大数据的实时查询。Facebook用Hbase进行消息和实时的分析。它也可以用来统计Facebook的连接数。

[官方文档](https://hbase.apache.org/book.html)

[官方下载地址](http://mirrors.hust.edu.cn/apache/hbase/)

#### 参考资料

[HBase hbase-site.xml中各参数意义](https://blog.csdn.net/u014782458/article/details/56679136)

[Regionserver 频繁挂掉故障处理实践](https://itw01.com/5CIKEAM.html)

[HBase 基本操作](https://www.cnblogs.com/charlist/p/7120377.html)

[HBase命令行基本操作](https://blog.csdn.net/scgaliguodong123_/article/details/46626779)

### kylin安装

[kylin-docker](https://github.com/Kyligence/kylin-docker/)

#### 参考资料

[CDH与原生态hadoop之间的区别](https://www.cnblogs.com/shellshell/p/6102777.html)

### 参考资料

[OLAP引擎——Kylin介绍](https://blog.csdn.net/yu616568/article/details/48103415)

[Kylin介绍，功能特点](https://blog.csdn.net/xuzhenmao_soft/article/details/79012798)

[大数据分析神兽麒麟](https://www.cnblogs.com/huajiezh/p/6020880.html)

[Kylin基础教程（一）](https://www.cnblogs.com/wzlbigdata/p/8481991.html)

[Hadoop-CDH5.7.0 for CentOS7](https://www.cnblogs.com/fujiangong/p/5620050.html)

[离线安装Cloudera Manager 5.11.1和CDH5.11.1完全教程](https://blog.csdn.net/u011026329/article/details/79166626)

---

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [ん乖乖龙ん](https://bjddd192.github.io) 所有。