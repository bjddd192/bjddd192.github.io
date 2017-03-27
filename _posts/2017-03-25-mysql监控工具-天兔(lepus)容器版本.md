---
layout: post
title: mysql监控工具-天兔(lepus)容器版本
date: 2017-03-25 21:18:30 +0800
description: mysql监控工具-天兔(lepus)容器版本
categories: mysql
tags: lepus
keywords: lepus mysql mysql监控工具
---

* content
{:toc}

最近迁移了一个数据库监控工具 `天兔(lepus)` 到容器，lepus 是一款国产开源企业级数据库监控系统，支持 MySQL/Oracle/MongoDB/Redis 一站式性能监控，目的让数据库监控更简单。目前最新版本是 v3.8 bata 版本，上一版本为 v3.7 版本。我用这个工具来监控生产环境 `mysql 5.6.19` 版本的数据库（20台）已经有三年时间，还算比较实用了，主要是它的看板功能非常漂亮直观，慢查询语句跟踪与邮件推送功能也挺不错。因为之前部署在虚拟机内，现在虚拟机需要物理化，因此需要进行迁移。我首先想到的肯定是容器化了，因为这个工具安装过程比较麻烦，很容易出错，我之前安装过几次，每次安装都要踩几天坑，容器化以后就可以一劳永逸了，何乐而不为。当然这次容器化的过程也不是那么顺利，依然折腾了我好几天，差点放弃了，不过好在最终还是折腾出来了，以后使用就方便了，同时在这里分享给更多需要这个工具的人，节约大家的宝贵时间。




下面是效果图：

![效果图](/assets/2017-03-25-mysql监控工具-天兔(lepus)容器版本/1.jpg)

### 使用介绍

这个 lepus 容器版跟官方的有点不同，是根据我的实际应用经验来构建的，对 lepus 工具进行了解耦，分为数据库、前端应用、监控应用三个部分，个人感觉这样拆分后更好理解与使用。目前的版本是 3.7 ，后续有时间再做一个 3.8 版本的。

#### 支持的功能

* 支持 MySQL/Oracle/MongoDB/Redis 的监控数据采集，并针对 MongoDB 的 python 插件进行了处理，支持高版本的 MongoDB，具体指标请参考官网说明。
* 支持 MySQL 慢查询日志归集以及慢查询日志邮件定时推送。

#### 不支持的功能

* 不支持使用 snmp 对主机进行监控，因为这个监控主机的功能不如专业的 zabbix 好用，而且配置比较繁琐，因此在此容器版弃用，实在需要这个功能的请安装官方的版本。

#### 数据库

数据库指的是 lepus 工具的后端数据存储，使用的是 mysql 数据库，我的版本来源于官方，但是做了一些调整：

* 官方使用 5.1.73 版本的 mysql，我使用的是 5.6.19 版本的 mysql，理论上其他版本的 mysql 应该也都支持。

* 修复了在实际应用过程中发现了一些 BUG，主要是对数据类型做了一些调整。

* 官方使用的 collate 是 utf8_general_ci，我使用的是 utf8_bin，主要是与我平时使用的数据库集成在一起，不用再单独搭建一个老版本的数据库了，更方便管理。

以下是我抽取的完整数据库脚本：

[01_lepus_db.sql](/downloads/2017-03-25-mysql监控工具-天兔(lepus)容器版本/01_lepus_db.sql)

[02_lepus_table.sql](/downloads/2017-03-25-mysql监控工具-天兔(lepus)容器版本/02_lepus_table.sql)

[03_lepus_data.sql](/downloads/2017-03-25-mysql监控工具-天兔(lepus)容器版本/03_lepus_data.sql)

大家下载数据库脚本后完全可以根据自己数据库服务器的实际情况再进行一些调整，匹配自己的习惯。

#### 前端应用

##### Quick Start

```sh
docker stop lepus-php && docker rm lepus-php  

docker run -d --name lepus-php -p 40080:80 \
  -e MYSQL_HOST="172.20.32.37" \
  -e MYSQL_PORT=3306 \
  -e MYSQL_USER="user_lepus" \
  -e MYSQL_PASS="user_lepus" \
  -e MYSQL_DBNAME="user_lepus" \
  -e MYSQL_CHARSETT="utf8" \
  -e MYSQL_COLLATE="utf8_bin" \
  -e SMTP_HOST="smtp.163.com" \
  -e SMTP_PORT=25 \
  -e SMTP_USER="XXX@163.com" \
  -e SMTP_PASS="XXX" \
  -e SMTP_TIMEOUT=10 \
  bjddd192/lepus:v3.7-php
```

##### 环境变量说明

|环境变量|默认值|说明
|:--|:--|:--
|MYSQL_HOST|127.0.0.1|lepus 后台所在 mysql 数据库的主机地址。
|MYSQL_PORT|3306|lepus 后台所在 mysql 数据库的主机端口。
|MYSQL_USER|user_lepus|lepus 后台所在 mysql 数据库的用户名。
|MYSQL_PASS|user_lepus|lepus 后台所在 mysql 数据库的密码。
|MYSQL_DBNAME|3306|lepus 后台所在 mysql 数据库的数据库名。
|MYSQL_CHARSET|utf8|lepus 后台所在 mysql 数据库的 char set。
|MYSQL_COLLATE|utf8_bin|lepus 后台所在 mysql 数据库的 char collate。
|SMTP_HOST|smtp.163.com|lepus 慢查询邮件推送服务器 smtp。
|SMTP_PORT|25|lepus 慢查询邮件推送服务器 smtp 端口。
|SMTP_USER|smtp_user|lepus 慢查询邮件推送服务器 smtp 用户名。
|SMTP_PASS|smtp_pass|lepus 慢查询邮件推送服务器 smtp 密码。
|SMTP_TIMEOUT|0|lepus 慢查询邮件推送服务器 smtp 超时时间。

##### 前端验证

假设部署在 172.20.32.36 的 40080 端口，那么访问 http://172.20.32.36:40080，可以正常登录，即验证成功。

* 用户名：admin   
* 密&emsp;码：Lepusadmin 

#### 监控应用

监控应用是一个 python 的程序，封装了对 MySQL/Oracle/MongoDB/Redis 进行监控数据抽取，容器版已安装好了所有需要的 python 插件，只需要简单配置即可使用。同时，我将 mysql 的慢查询邮件定时推送的功能也集成到了这个监控容器当中。

##### Quick Start

```sh
docker stop lepus-python && docker rm lepus-python

docker run -d --name lepus-python \
  -e MYSQL_HOST="172.20.32.37" \
  -e MYSQL_PORT=3306 \
  -e MYSQL_USER="user_lepus" \
  -e MYSQL_PASS="user_lepus" \
  -e MYSQL_DBNAME="user_lepus" \
  -e LEPUS_WEB_HOST="172.20.32.36:40080" \
  -e MYSQL_SLOW_QUERY_SEND_CRONTAB="00 07 * * *" \
  bjddd192/lepus:v3.7-python
```

##### 环境变量说明

|环境变量|默认值|说明
|:--|:--|:--
|MYSQL_HOST|127.0.0.1|lepus 后台所在 mysql 数据库的主机地址。
|MYSQL_PORT|3306|lepus 后台所在 mysql 数据库的主机端口。
|MYSQL_USER|user_lepus|lepus 后台所在 mysql 数据库的用户名。
|MYSQL_PASS|user_lepus|lepus 后台所在 mysql 数据库的密码。
|MYSQL_DBNAME|3306|lepus 后台所在 mysql 数据库的数据库名。
|LEPUS_WEB_HOST|127.0.0.1:80|lepus web 前端访问地址。
|MYSQL_SLOW_QUERY_SEND_CRONTAB|00 07 * * *|lepus 慢查询邮件推送频率，默认为每天早上 7 点执行邮件推送任务。

##### 监控验证

首先使用前端页面配置一些服务器信息，然后查看监控日志没有异常的报错信息，即验证通过。

```sh
docker logs --tail 10 -f lepus_monitor
```

##### 慢查询验证准备

mysql 慢查询日志抓取与推送功能是 lepus 的重要价值功能之一，这个功能的配置会稍微麻烦一点，我也做了一些整理，下面跟着我的步骤来完成它。

首先远程登录要监控的 mysql 服务器，增加一个监控的帐号，脚本如下：

```sql
grant select,super,process on *.* to 'user_monitor'@'%' identified by 'user_monitor'; 
flush privileges;  
```

然后 ssh 远程登录要监控的 mysql 服务器主机(以 centos 为例)，执行以下脚本：

```sh
set -x && \
yum -y install perl-IO-Socket-SSL perl-DBI perl-DBD-MySQL perl-Time-HiRes perl-TermReadKey && \
wget https://www.percona.com/downloads/percona-toolkit/2.2.14/RPM/percona-toolkit-2.2.14-1.noarch.rpm -P /tmp && \
rpm -ivh /tmp/percona-toolkit-2.2.14-1.noarch.rpm && \
touch /usr/local/sbin/lepus_slowquery.sh && \
chmod +x /usr/local/sbin/lepus_slowquery.sh && \
echo '
# 每10分钟做一次慢查询语句抓取
*/10 * * * * root /usr/local/sbin/lepus_slowquery.sh > /dev/null 2>&1' >> /etc/crontab && \
vi /usr/local/sbin/lepus_slowquery.sh      
```

lepus_slowquery.sh 脚本的内容如下：

```sh
#!/bin/bash

#****************************************************************#
# ScriptName: /usr/local/sbin/lepus_slowquery.sh
# Create Date: 2014-03-25 10:01
# Modify Date: 2014-03-25 10:01
#***************************************************************#

#config lepus database server
lepus_db_host="172.20.32.37"
lepus_db_port=3306
lepus_db_user="user_lepus"
lepus_db_password="user_lepus"
lepus_db_database="user_lepus"

#config mysql server
mysql_client="/usr/bin/mysql"
mysql_host="localhost"
mysql_port=3306
mysql_user="root"
mysql_password="root"
mysql_sock="/var/lib/mysql/3306.sock"

#config slowqury
slowquery_dir="/data/mysql_3306_slowquery/"
slowquery_long_time=2
slowquery_file=`$mysql_client -h$mysql_host -P$mysql_port -u$mysql_user -p$mysql_password -S$mysql_sock -e "show variables like 'slow_query_log_file'"|grep log|awk '{print $2}'`
pt_query_digest="/usr/bin/pt-query-digest"

#config server_id
lepus_server_id=1

#collect mysql slowquery log into lepus database
$pt_query_digest --user=$lepus_db_user --password=$lepus_db_password --port=$lepus_db_port --review h=$lepus_db_host,D=$lepus_db_database,t=mysql_slow_query_review  --history h=$lepus_db_host,D=$lepus_db_database,t=mysql_slow_query_review_history  --no-report --limit=100% --filter=" \$event->{add_column} = length(\$event->{arg}) and \$event->{serverid}=$lepus_server_id " $slowquery_file > /tmp/lepus_slowquery.log

##### set a new slow query log ###########
tmp_log=`$mysql_client -h$mysql_host -P$mysql_port -u$mysql_user -p$mysql_password -S$mysql_sock -e "select concat('$slowquery_dir','slowquery_',date_format(now(),'%Y%m%d%H'),'.log');"|grep log|sed -n -e '2p'`

#config mysql slowquery
$mysql_client -h$mysql_host -P$mysql_port -u$mysql_user -p$mysql_password -S$mysql_sock -e "set global slow_query_log=1;set global long_query_time=$slowquery_long_time;"
$mysql_client -h$mysql_host -P$mysql_port -u$mysql_user -p$mysql_password -S$mysql_sock -e "set global slow_query_log_file = '$tmp_log'; "

#delete log before 7 days
cd $slowquery_dir
/usr/bin/find ./ -name 'slowquery_*' -mtime +7|xargs rm -rf ;

####END####
```

这时候需要根据实际情况调整 lepus_server_id 之前的配置，从上面的脚本，可以看出实际上是做了一个定时任务，定时任务会定时修改 mysql slowquery 的配置（这里要注意配置的 mysql 帐号的权限），从而使 slowquery 日志没有那么庞大，同时也会将拿到的 slowquery 日志内容写入 lepus 所在的后端数据库。

**尤其要注意的一点**

* lepus_server_id 不是数据库配置文件 my.cnf 中配置的 server_id ，而是 lepus 中 mysql 配置中心产生的 id 值，这个非常重要，如果配置错误，很可能就在慢查询界面就查询不到抓取到的语句了。

##### 慢查询验证

在做完上面的事情，就可以做慢查询的验证了。先执行脚本：

```sh
sh /usr/local/sbin/lepus_slowquery.sh
```

然后使用 mysql 的一个用户构造一个较长时间的查询语句并执行。例如：

```sql
select * from information_schema.`tables` a , information_schema.`tables` b;
```

**重要提示**

* 这里要注意不能用 root 用户来测试，lepus 默认屏蔽了 root 用户产生的慢查询语句，最好使用 test 用户进行验证，否则会造成在数据库中看到有产生慢查询语句，但是前端怎么也查不到的现象。

查看一下慢查询日志文件，例如：

```sh
cat /data/mysql_3306_slowquery/slowquery_2017032623.log
```

看看里面是否已经记录了刚才测试的慢查询语句。

如果 OK，再执行脚本：

```sh
sh /usr/local/sbin/lepus_slowquery.sh
```

然后登录 lepus 的后端数据库 user_lepus，查看 mysql_slow_query_review 表是否已经记录了刚才测试的慢查询语句。

如果OK，就可以进行最后一步慢查询邮件推送的实验。

```
docker exec -it lepus_monitor bash
links http://172.20.32.36:40080/index.php/task/send_mysql_slowquery_mail > /dev/null 2>&1
```

这里的地址改为 lepus 所在 web 前端的地址即可，在执行完成后，登录慢查询推送邮箱，看看是否收取到了邮件，如果收到了邮件，则说明功能验证通过。

效果如下：

![效果图](/assets/2017-03-25-mysql监控工具-天兔(lepus)容器版本/2.jpg)

如需要再次进行验证，可以清除 mysql_slow_query_sendmail_log 表的数据后继续使用 links 命令推送即可。

### 结语

容器版的 lepus 相比原生的已经简化的很多的安装步骤，减少了出错的概率，大家只要耐心地按照步骤去配置，肯定都能正常跑起来。如果在使用的过程中还发现什么问题，欢迎给我留言一起进行探讨。

### lepus 的生态

[天兔官网](http://www.lepus.cc/)    
[github官方版本](https://hub.docker.com/r/georce/lepus/)

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [ん乖乖龙ん](https://bjddd192.github.io) 所有。
