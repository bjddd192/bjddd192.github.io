---
layout: "post"
title: "mysql5.6 范围分区表实战"
date: "2017-12-16 22:25:45"
description: mysql5.6 范围分区表实战
categories: mysql
tags: 分区表
keywords: mysql mysql5.6 partition range
---

最近由于用到一些大数据的表，需要进行改造为分区表，来提高查询的效率，分区表在 mysql 学习的时候就已经做过一些基本的测试，这里针对常用的范围分区表进行更深层次的问题进行探讨。




### 分区个数限制

在 MySQL5.6.7 之前，NDB 存储引擎的给定表的最大分区数是 1024。从 MySQL 5.6.7 开始，这个限制增加到 8192 个分区，包含子分区。

### 分区文件结构

innodb 的索引与数据文件是放一起的，都在 `.ibd` 文件下，删除索引不会释放索引占用的空间，需要整理表（如：alter table my_play_stat engine = innodb;）才能释放空间。

### 分区索引

分区索引应避免包含分区字段。

### 分区表示例

```sql
-- drop table my_play_stat;

CREATE TABLE `my_play_stat` 
(
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `record_no` varchar(32) COLLATE utf8_bin NOT NULL DEFAULT '0' COMMENT '播放流水',
  `store_no` varchar(10) COLLATE utf8_bin DEFAULT NULL comment '门店编号',
  `device_no` varchar(10) COLLATE utf8_bin NOT NULL COMMENT '设备编号',
  `material_no` varchar(20) COLLATE utf8_bin NOT NULL,
  `play_time` datetime NOT NULL COMMENT '开始播放时间',
  `play_end_time` datetime DEFAULT NULL COMMENT '播放结束时间',
  `creator` varchar(20) COLLATE utf8_bin DEFAULT NULL COMMENT '建档人',
  `create_time` datetime NOT NULL COMMENT '建档时间',
  `modifier` varchar(20) COLLATE utf8_bin DEFAULT NULL COMMENT '修改人',
  `modify_time` datetime DEFAULT NULL COMMENT '修改时间',
  `remarks` varchar(64) COLLATE utf8_bin DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`,create_time),
  KEY `idx_ac_play_stat1` (`record_no`),
  KEY `idx_ac_play_stat2` (`material_no`),
  KEY `idx_ac_play_stat3` (`create_time`,`store_no`),
  KEY `idx_ac_play_stat4` (`play_time`)
)
partition by range columns (create_time)
( 
partition p_20171201 values less than ('2017-12-02'),
partition p_20171202 values less than ('2017-12-03'),
partition p_20171203 values less than ('2017-12-04'),
partition p_20171204 values less than ('2017-12-05'),
partition p_20171205 values less than ('2017-12-06'),
partition p_20171206 values less than ('2017-12-07'),
partition p_20171207 values less than ('2017-12-08'),
partition p_20171208 values less than ('2017-12-09'),
partition p_20171209 values less than ('2017-12-10'),
partition p_20171210 values less than ('2017-12-11'),
partition p_20171211 values less than ('2017-12-12'),
partition p_20171212 values less than ('2017-12-13'),
partition p_20171213 values less than ('2017-12-14'),
partition p_20171214 values less than ('2017-12-15'),
partition p_20171215 values less than ('2017-12-16'),
partition p_20171216 values less than ('2017-12-17'),
partition p_20171217 values less than ('2017-12-18'),
partition p_20171218 values less than ('2017-12-19'),
partition p_20171219 values less than ('2017-12-20'),
partition p_20171220 values less than ('2017-12-21'),
partition p_20171221 values less than ('2017-12-22'),
partition p_20171222 values less than ('2017-12-23'),
partition p_20171223 values less than ('2017-12-24'),
partition p_20171224 values less than ('2017-12-25'),
partition p_20171225 values less than ('2017-12-26'),
partition p_20171226 values less than ('2017-12-27'),
partition p_20171227 values less than ('2017-12-28'),
partition p_20171228 values less than ('2017-12-29'),
partition p_20171229 values less than ('2017-12-30'),
partition p_20171230 values less than ('2017-12-31'),
partition p_20171231 values less than ('2018-01-01')
);
```

### 自动生成分区条件

#### 按月自动生成分区条件

```sql
select concat('partition p_',p_month,' values less than (''',p_less,'''),') script
from 
(
	select date_format(@x,'%Y%m') p_month,@x:=date_add(@x,INTERVAL 1 month) p_less
	from information_schema.columns a 
	INNER JOIN 
	(select @x:=date('2017-01-01') date) b
) a
where p_month <= '202012';
```

#### 按日自动生成分区条件

```sql
select concat('partition p_',p_day,' values less than (''',p_less,'''),') script
from 
(
	select date_format(@x,'%Y%m%d') p_day,@x:=date_add(@x,INTERVAL 1 day) p_less
	from information_schema.columns a 
	INNER JOIN 
	(select @x:=date('2017-01-01') date) b
) a
where p_day <= '20201231';
```

更高级的功能待后续继续补充。

---

**转载**请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权，版权归 [Mars丶小石头](https://www.zorin.xin) 所有。