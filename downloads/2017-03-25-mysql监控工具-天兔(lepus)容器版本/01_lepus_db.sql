/*
创建数据库与用户
*/

create database user_lepus default character set utf8 collate utf8_bin;
grant all PRIVILEGES on user_lepus.* to 'user_lepus'@'%' identified by 'user_lepus';

