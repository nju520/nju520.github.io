---
layout: post
toc: true
permalink: /rails-mysql-sharing
title: Rails实现MySQL读写分离
tags: Rails MySQL Sharing
desc:

---


常用的实现读写分离的方式有如下两种

* 第三方中间件，比较成熟的有Mysql官方提供的 [MySQL Router](https://dev.mysql.com/downloads/router/)以及 360公司基于MySQL-Proxy 0.8.2开发的开源 [Atlas](https://github.com/Qihoo360/Atlas)等

* 其次就是在应用中做解决，在 `ActiveRecord`中做做处理， 如：[octopus](https://github.com/thiagopradi/octopus)

本次实践的是用 `gem octopus`来实现读写分离。

为了模拟读写分离，将 `MySQL` 分别安装在了本地 `Mac` 和阿里云 `Linux` 系统上，`Mac` 的 `MySQL` 作为写入数据库，而Linux的作为读取数据库。

## 配置 MySQL 主从复制

### 创建账号

在 `Master` 的数据库中建立一个备份帐户：每个 `slave` 使用标准的 `MySQL` 用户名和密码连接 `master`。进行复制操作的用户会授予 `REPLICATION SLAVE` 权限. 命令如下：

```bash
mysql > GRANT REPLICATION SLAVE ON *.* TO 'backup'@'113.66.254.238' IDENTIFIED BY '12345678';
mysql > flush privileges;
```

命令是建立一个帐户 `backup`，并且只能允许从 `113.66.254.238` 这个地址上来登陆，密码是 `12345678`。

### 配置 master

修改主服务器 `Master`的 `MySQL` 配置文件

```bash
$ vi /etc/my.cnf（默认）
[mysqld]
log-bin=mysql-bin     //[必须]启用二进制日志
server-id=112         //[必须]服务器唯一ID，默认是1，一般取IP最后一段
# 指定同步的数据库， 如果 不指定则同步全部数据库
binlog-do-db= eshop_development
```

重启 `master` `service mysqld restart`，运行 `SHOW MASTER STATUS`，输出如下：

```
+------------------+----------+-------------------+------------------+-------------------+
| File             | Position | Binlog_Do_DB      | Binlog_Ignore_DB | Executed_Gtid_Set |
+------------------+----------+-------------------+------------------+-------------------+
| mysql-bin.000004 |     308  | eshop_development | mysql            |                   |
+------------------+----------+-------------------+------------------+-------------------+
```
注：执行完此步骤后不要再操作主服务器 `MYSQL`，防止主服务器状态值变化

### 配置slave

修改从服务器 `slave`

```bash
$ vi /etc/my.cnf
[mysqld]
server-id=238      //[必须]服务器唯一ID，默认是1，一般取IP最后一段
```

配置从服务器 `Slave`， 设置需要链接主服务器的地址与登录用户名跟密码

```bash
mysql> change master to master_dhost='47.106.177.112',master_user='backup',master_password='12345678',
master_log_file='mysql-bin.000004',master_log_pos=308;
mysql> start slave;    //启动从服务器复制功能
```

检查从服务器(Slave)复制功能状态：
```bash
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 47.106.177.112
                  Master_User: backup
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000012
          Read_Master_Log_Pos: 2258
               Relay_Log_File: edu-mysql-relay-bin.000014
                Relay_Log_Pos: 2424
        Relay_Master_Log_File: mysql-bin.000012
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 2258
              Relay_Log_Space: 2848
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 1
                  Master_UUID: c908538b-db65-11e8-8419-00163e1037ab
             Master_Info_File: /usr/local/var/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                ......
```
`Slave_IO` 及 `Slave_SQL` 进程必须正常运行，即 `YES` 状态，否则都是错误的状态(如：其中一个 `NO` 均属错误)。

## Rails 应用配置

### 添加如下一行到 Gemfile

```ruby
gem 'ar-octopus'
```

执行 `bundle install`

### 配置文件
在 `Rails` 项目的 `config` 目录下新建文件 `shards.xml`,该文件用于保 `存Linux` 下 `MySQL read` 数据库, 该文件长成这个样子：

``` yml
octopus:
  replicated: true
  environments:
    - development

  development:
    slave1:
      host: 113.66.254.238
      port: 3306
      adapter: mysql2
      database: eshop_development
      usename: root
      password: root
```

`rails` 会将 `database.yml` 中配置的数据库作为写数据库(master)。

测试下是否如预期的从主库写入数据，从库读取数据, 在 `rails console`中执行如下

```ruby
2.3.1 :001 > AdminUser.create(email: "xifengzhu520@gmail.com")
2.3.1 :002 > AdminUser.find_by_email("xifengzhu520@gmail.com")
```
结果输出为:
```ruby
[Shard: slave1]  AdminUser Load (27.4ms)  SELECT  `admin_users`.* FROM `admin_users` WHERE `admin_users`.`email` = 'xifengzhu520@gmail.com' LIMIT 1
```

可以看到数据已经写入主数据库，并且能从从库中读取出来，说明此时读写分离已经配置成功。
