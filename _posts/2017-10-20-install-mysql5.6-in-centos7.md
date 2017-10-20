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




### mysql 版本说明

[MySQL 的官网下载地址](http://www.mysql.com/downloads)

在这个下载界面会有几个版本的选择：
1. MySQL Community Server 社区版本，开源免费，但不提供官方技术支持。
2. MySQL Enterprise Edition 企业版本，需付费，可以试用30天。
3. MySQL Cluster 集群版，开源免费。可将几个MySQL Server封装成一个Server。
4. MySQL Cluster CGE 高级集群版，需付费。
5. MySQL Workbench（GUI TOOL）一款专为MySQL设计的ER/数据库建模工具。它是著名的数据库设计工具DBDesigner4的继任者。MySQL Workbench又分为两个版本，分别是社区版（MySQL Workbench OSS）、商用版（MySQL Workbench SE）。

MySQL Community Server 是开源免费的，这也是我们通常用的MySQL的版本，本文介绍的也是基于此版本的安装。

---

### 环境准备

```sh
# 检查操作系统
$ cat /etc/redhat-release
CentOS Linux release 7.2.1511 (Core) 

# 准备好安装包，请自行从官网或百度下载
$ ll |grep MySQL         
-rw-r--r-- 1 root root 18360416 Mar 30  2015 MySQL-client-5.6.19-1.el6.x86_64.rpm
-rw-r--r-- 1 root root  3368712 Apr  1  2015 MySQL-devel-5.6.19-1.el6.x86_64.rpm
-rw-r--r-- 1 root root 54592892 Mar 30  2015 MySQL-server-5.6.19-1.el6.x86_64.rpm
-rw-r--r-- 1 root root  1944976 Apr  1  2015 MySQL-shared-5.6.19-1.el6.x86_64.rpm
-rw-r--r-- 1 root root  3969740 May 16  2015 MySQL-shared-compat-5.6.19-1.el6.x86_64.rpm
```

---

### 卸载 Mariadb

Centos7 将默认数据库由 mysql 替换成了 Mariadb，如果直接安装 mysql，会报出很多的安装包冲突，因此，需要将先 Mariadb 进行卸载。

``` sh
# 查询 mariadb 是否被安装
$ rpm -qa|grep mariadb
mariadb-libs-5.5.44-2.el7.centos.x86_64

$ yum -y remove mariadb-libs
```

---

### 安装依赖的包

```sh
yum -y install libaio perl-Module-Install.noarch 
```

---

### 安装 mysql 数据库

```sh
$ rpm -ivh MySQL-devel-5.6.19-1.el6.x86_64.rpm
Preparing...                          ################################# [100%]
Updating / installing...
   1:MySQL-devel-5.6.19-1.el6         ################################# [100%]

$ rpm -ivh MySQL-shared-5.6.19-1.el6.x86_64.rpm
Preparing...                          ################################# [100%]
Updating / installing...
   1:MySQL-shared-5.6.19-1.el6        ################################# [100%]

$ rpm -ivh MySQL-shared-compat-5.6.19-1.el6.x86_64.rpm
Preparing...                          ################################# [100%]
Updating / installing...
   1:MySQL-shared-compat-5.6.19-1.el6 ################################# [100%]

$ rpm -ivh MySQL-client-5.6.19-1.el6.x86_64.rpm
Preparing...                          ################################# [100%]
Updating / installing...
   1:MySQL-client-5.6.19-1.el6        ################################# [100%]

$ rpm -ivh MySQL-server-5.6.19-1.el6.x86_64.rpm
Preparing...                          ################################# [100%]
Updating / installing...
   1:MySQL-server-5.6.19-1.el6        ################################# [100%]

2017-10-20 13:39:42 0 [Warning] TIMESTAMP with implicit DEFAULT value is deprecated. Please use --explicit_defaults_for_timestamp server option (see documentation for more details).
2017-10-20 13:39:42 19541 [Note] InnoDB: Using atomics to ref count buffer pool pages
2017-10-20 13:39:42 19541 [Note] InnoDB: The InnoDB memory heap is disabled
2017-10-20 13:39:42 19541 [Note] InnoDB: Mutexes and rw_locks use GCC atomic builtins
2017-10-20 13:39:42 19541 [Note] InnoDB: Compressed tables use zlib 1.2.3
2017-10-20 13:39:42 19541 [Note] InnoDB: Using Linux native AIO
2017-10-20 13:39:42 19541 [Note] InnoDB: Using CPU crc32 instructions
2017-10-20 13:39:42 19541 [Note] InnoDB: Initializing buffer pool, size = 128.0M
2017-10-20 13:39:42 19541 [Note] InnoDB: Completed initialization of buffer pool
2017-10-20 13:39:42 19541 [Note] InnoDB: The first specified data file ./ibdata1 did not exist: a new database to be created!
2017-10-20 13:39:42 19541 [Note] InnoDB: Setting file ./ibdata1 size to 12 MB
2017-10-20 13:39:42 19541 [Note] InnoDB: Database physically writes the file full: wait...
2017-10-20 13:39:42 19541 [Note] InnoDB: Setting log file ./ib_logfile101 size to 48 MB
2017-10-20 13:39:43 19541 [Note] InnoDB: Setting log file ./ib_logfile1 size to 48 MB
2017-10-20 13:39:44 19541 [Note] InnoDB: Renaming log file ./ib_logfile101 to ./ib_logfile0
2017-10-20 13:39:44 19541 [Warning] InnoDB: New log files created, LSN=45781
2017-10-20 13:39:44 19541 [Note] InnoDB: Doublewrite buffer not found: creating new
2017-10-20 13:39:44 19541 [Note] InnoDB: Doublewrite buffer created
2017-10-20 13:39:44 19541 [Note] InnoDB: 128 rollback segment(s) are active.
2017-10-20 13:39:44 19541 [Warning] InnoDB: Creating foreign key constraint system tables.
2017-10-20 13:39:44 19541 [Note] InnoDB: Foreign key constraint system tables created
2017-10-20 13:39:44 19541 [Note] InnoDB: Creating tablespace and datafile system tables.
2017-10-20 13:39:44 19541 [Note] InnoDB: Tablespace and datafile system tables created.
2017-10-20 13:39:44 19541 [Note] InnoDB: Waiting for purge to start
2017-10-20 13:39:44 19541 [Note] InnoDB: 5.6.19 started; log sequence number 0
A random root password has been set. You will find it in '/root/.mysql_secret'.
2017-10-20 13:39:45 19541 [Note] Binlog end
2017-10-20 13:39:45 19541 [Note] InnoDB: FTS optimize thread exiting.
2017-10-20 13:39:45 19541 [Note] InnoDB: Starting shutdown...
2017-10-20 13:39:46 19541 [Note] InnoDB: Shutdown completed; log sequence number 1625977


2017-10-20 13:39:46 0 [Warning] TIMESTAMP with implicit DEFAULT value is deprecated. Please use --explicit_defaults_for_timestamp server option (see documentation for more details).
2017-10-20 13:39:46 19615 [Note] InnoDB: Using atomics to ref count buffer pool pages
2017-10-20 13:39:46 19615 [Note] InnoDB: The InnoDB memory heap is disabled
2017-10-20 13:39:46 19615 [Note] InnoDB: Mutexes and rw_locks use GCC atomic builtins
2017-10-20 13:39:46 19615 [Note] InnoDB: Compressed tables use zlib 1.2.3
2017-10-20 13:39:46 19615 [Note] InnoDB: Using Linux native AIO
2017-10-20 13:39:46 19615 [Note] InnoDB: Using CPU crc32 instructions
2017-10-20 13:39:46 19615 [Note] InnoDB: Initializing buffer pool, size = 128.0M
2017-10-20 13:39:46 19615 [Note] InnoDB: Completed initialization of buffer pool
2017-10-20 13:39:46 19615 [Note] InnoDB: Highest supported file format is Barracuda.
2017-10-20 13:39:46 19615 [Note] InnoDB: 128 rollback segment(s) are active.
2017-10-20 13:39:46 19615 [Note] InnoDB: Waiting for purge to start
2017-10-20 13:39:46 19615 [Note] InnoDB: 5.6.19 started; log sequence number 1625977
2017-10-20 13:39:46 19615 [Note] Binlog end
2017-10-20 13:39:46 19615 [Note] InnoDB: FTS optimize thread exiting.
2017-10-20 13:39:46 19615 [Note] InnoDB: Starting shutdown...
2017-10-20 13:39:48 19615 [Note] InnoDB: Shutdown completed; log sequence number 1625987




A RANDOM PASSWORD HAS BEEN SET FOR THE MySQL root USER !
You will find that password in '/root/.mysql_secret'.

You must change that password on your first connect,
no other statement but 'SET PASSWORD' will be accepted.
See the manual for the semantics of the 'password expired' flag.

Also, the account for the anonymous user has been removed.

In addition, you can run:

  /usr/bin/mysql_secure_installation

which will also give you the option of removing the test database.
This is strongly recommended for production servers.

See the manual for more instructions.

Please report any problems at http://bugs.mysql.com/

The latest information about MySQL is available on the web at

  http://www.mysql.com

Support MySQL by buying support/licenses at http://shop.mysql.com

New default config file was created as /usr/my.cnf and
will be used by default by the server when you start it.
You may edit this file to change server settings
```

---

### 启动 mysql 数据库

```sh
$ systemctl start mysql 

$ systemctl status mysql
● mysql.service - LSB: start and stop MySQL
   Loaded: loaded (/etc/rc.d/init.d/mysql; bad; vendor preset: disabled)
   Active: active (running) since Fri 2017-10-20 13:42:53 CST; 1s ago
     Docs: man:systemd-sysv-generator(8)
  Process: 21362 ExecStart=/etc/rc.d/init.d/mysql start (code=exited, status=0/SUCCESS)
   Memory: 432.4M
   CGroup: /system.slice/mysql.service
           ├─21368 /bin/sh /usr/bin/mysqld_safe --datadir=/var/lib/mysql --pid-file=/var/lib/mysql/leo-web2.pid
           └─21473 /usr/sbin/mysqld --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib64/mysql/plugin 
```

---

### 开启远程登录

```sh
# 查看mysql的初始密码
$ cat /root/.mysql_secret
# The random password set for the root user at Fri Oct 20 13:39:44 2017 (local time): XVxoGQcC84YXxY8W

# 使用密码登录数据库
$ mysql -pXVxoGQcC84YXxY8W
Warning: Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 1
Server version: 5.6.19

Copyright (c) 2000, 2014, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

# 修改数据库初始密码
mysql> set password = password('DataMan2017'); 
Query OK, 0 rows affected (0.00 sec)

# 查看数据库root用户
mysql> select user,password,host from mysql.user where user='root';
+------+-------------------------------------------+-----------+
| user | password                                  | host      |
+------+-------------------------------------------+-----------+
| root | *0BF985C95774D3B684D911698DEE4BC9DECAFCE1 | localhost |
| root | *A0397B3C66340B2FC83D091408B445C1594AF440 | leo-web2  |
| root | *A0397B3C66340B2FC83D091408B445C1594AF440 | 127.0.0.1 |
| root | *A0397B3C66340B2FC83D091408B445C1594AF440 | ::1       |
+------+-------------------------------------------+-----------+

# 更改所有的root帐号密码为一致
mysql> update mysql.user set password=password('DataMan2017') where user='root'; 
Query OK, 4 rows affected (0.00 sec)
Rows matched: 4  Changed: 3  Warnings: 0

# 设置在服务器免密登录数据库
mysql> update mysql.user set password=password('') where user='root' and host='localhost';
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0

# 添加root远程登录帐号
mysql> grant all privileges on *.* to 'root'@'%' identified by 'DataMan2017' with grant option;         
Query OK, 0 rows affected (0.00 sec)

# 刷新权限使生效
mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)

# 退出mysql
mysql> exit
Bye

# 验证本地免密登录
$ mysql -e "show databases"    
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| test               |
+--------------------+

# 验证远程登录
$ mysql -h"xxx.xxx.xxx.xxx" -u"root" -p"DataMan2017" -P"3306" -e "show databases"
Warning: Using a password on the command line interface can be insecure.
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| test               |
+--------------------+
```

---

### 调整 mysql 配置

#### 关闭 mysql

```sh
systemctl stop mysql
```

#### 调整 mysql 目录

```sh
$ mkdir /home/mysql/

$ cd /home/mysql/

$ mkdir mysql_5000 mysql_5000_backup mysql_5000_binlog mysql_5000_command mysql_5000_tmp

$ ls
mysql_5000  mysql_5000_backup  mysql_5000_binlog  mysql_5000_command  mysql_5000_tmp

# 复制mysql数据文件
$ cp -r /var/lib/mysql/* /home/mysql/mysql_5000/

# 将自定义目录赋权给mysql
$ chown -R mysql:mysql /home/mysql/*
```

#### 调整 my.cnf 文件

以下调整为本人在开发环境的常用配置，大家可以根据各自的机器资源情况进行调整。

```sh
# 移动mysql配置文件
mv /usr/my.cnf /etc/my.cnf
```

```sh
# 使用自定义配置文件
tee /etc/my.cnf <<-'EOF'
[mysqld]

# MySQL数据文件存储目录
datadir=/home/mysql/mysql_5000

# 临时目录设置  
tmpdir = /home/mysql/mysql_5000_tmp  
slave-load-tmpdir = /home/mysql/mysql_5000_tmp

# 默认端口设置
port=5000

# 表名用小写保存到硬盘上，并且表名比较时不对大小写敏感。应在所有平台上将该变量设置为1，强制将名字转换为小写。
lower_case_table_names=1

# 服务器的默认字符集设置
character_set_server=utf8

# 默认服务器校对规则设置，新数据库或数据表的默认排序方式。
collation-server=utf8_bin

# 设定默认的事务隔离级别，可用的级别如下:
# READ-UNCOMMITTED, READ-COMMITTED, REPEATABLE-READ, SERIALIZABLE
transaction_isolation=READ-COMMITTED

# 二进制日志文件前缀配置。这些路径相对于datadir。
log_bin=/home/mysql/mysql_5000_binlog/mysql-bin
log_bin_trust_function_creators=1
binlog_format=ROW
binlog_cache_size=16K

# 开启慢日志监控设置
slow_query_log=on
# 查询超过5秒的视为慢查询，记录日志
long_query_time=5
# 慢日志文件名
slow_query_log_file=mysqld-slow.log

# 建表或修改表时,指定的存储引擎不可用，会报错。
# STRICT_TRANS_TABLES模式：严格模式，进行数据的严格校验，错误数据不能插入，报error错误。
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES

# MySQL服务器同时处理的数据库连接的最大数量
max_connections=100

# 连接等待超时时间，服务器关闭非交互连接之前等待活动的秒数。
wait_timeout=86400
# 事务交互超时时间，服务器关闭交互式连接前等待活动的秒数。
interactive_timeout=7200

###########主库配置###########
server_id=105

##########innodb 配置#########
# InnoDB 存储引擎的表数据和索引数据的最大内存缓冲区大小。可以设置为机器物理内存大小的70%~80%
innodb_buffer_pool_size=256M

# InnoDB 存储引擎用来存储数据库结构和其他内部数据结构的内存池的大小
innodb_additional_mem_pool_size=8M

# 日志缓存的大小
innodb_log_buffer_size=8M

# 在每个事务提交时，日志缓冲被写到日志文件，并且对日志文件做向磁盘刷新的操作。
innodb_flush_log_at_trx_commit=2

# 允许多表空间，InnoDB存储每个新创建的表到它所属的数据库目录下的文件tbl_name.ibd里。
innodb_file_per_table=on

# 设置一个日志组中每个日志文件的大小，通常设置为256M。
innodb_log_file_size=256M

# 设置使用多少个日志文件，通常来说2~3是比较好的。
innodb_log_files_in_group=3

# 查询缓冲常被用来缓冲 SELECT 的结果并且在下一次同样查询的时候不再执行直接返回结果.
# 打开查询缓冲可以极大的提高服务器速度, 如果你有大量的相同的查询并且很少修改表.
# 查看 “Qcache_lowmem_prunes” 状态变量来检查是否当前值对于你的负载来说是否足够高.
# 注意: 在你表经常变化的情况下或者如果你的查询原文每次都不同,
# 查询缓冲也许引起性能下降而不是性能提升.
query_cache_size=8M

# 指定用于索引的缓冲区大小，增加它可得到更好的索引处理性能。
# 注意：该参数值设置的过大反而会是服务器整体效率降低！
key_buffer_size=8M

# 此缓冲被使用来优化全联合，通过 “Select_full_join” 状态变量查看全联合的数量
join_buffer_size=16K

# 排序缓冲，查看 “Sort_merge_passes” 状态变量
sort_buffer_size=32K

# 随机读取数据缓冲区使用内存，通过 “read_rnd_buffer_size” 参数所设置的内存缓冲区
read_rnd_buffer_size=16K
read_buffer_size=16k

# 增加一张临时表的大小
tmp_table_size=32K

table_open_cache=500

# 不使用高速缓存区来存放主机名和IP地址的对应关系。 
skip-host-cache

# 不把IP地址解析为主机名; 与访问控制(mysql.user数据表)有关的检查全部通过IP地址行进。
skip-name-resolve

# 启用事件调度功能   
event-scheduler=on
EOF
```

#### 重启 mysql

```sh
$ systemctl restart mysql

# 设置为开机自启动
$ systemctl enable mysql 
mysql.service is not a native service, redirecting to /sbin/chkconfig.
Executing /sbin/chkconfig mysql on
```

---

自此，mysql v5.6.19 在 centos7.2 安装完成，在外部可以使用 `navicat` 客户端进行连接了，好好享受数据库带来的精彩世界吧。

---

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [ん乖乖龙ん](https://bjddd192.github.io) 所有。
