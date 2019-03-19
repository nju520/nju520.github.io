---
layout: post
toc: true
permalink: /mysql-splitting-and-sharing
title: MySQL读写分离和主从复制
tags: MySQL Sharing Splitting
desc:

---



### 读写分离



MySQL读写分离基本原理是让`master`数据库处理写操作，`slave`数据库读操作.

`master`将写操作的变更同步更新到各个`slave`节点.





## MySQL 主从设置

### 进入 MySQL Master

#### 创建同步用户

```sql
create user repl;
```

#### 设置同步用户的权限

```sql
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%' IDENTIFIED BY 'repl';
```

#### 显示 master 状态

```sql
mysql> show master status;
+------------------+----------+--------------+------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+------------------+----------+--------------+------------------+-------------------+
| mysql-bin.000004 |      397 |              | mysql            |                   |
+------------------+----------+--------------+------------------+-------------------+
```

记住 `File` 和 `Position` 里面的值，比如 `mysql-bin.000004` 和 `397`。

### 进入 MySQL Slave

#### 设置连接 Master 的参数

记得修改 `MASTER_LOG_FILE` 和 `MASTER_LOG_POS` 的值。

```sql
CHANGE MASTER TO
    MASTER_HOST='mysql-master',
    MASTER_USER='repl',
    MASTER_PASSWORD='repl',
    MASTER_LOG_FILE='mysql-bin.000004',
    MASTER_LOG_POS=397;
```

#### 启动 slave 服务

```sql
start slave;
```

#### 显示 slave 状态

```sql
mysql> show slave status\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: mysql-master
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000004
          Read_Master_Log_Pos: 397
               Relay_Log_File: mysqld-relay-bin.000002
                Relay_Log_Pos: 596
        Relay_Master_Log_File: mysql-bin.000004
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
          Exec_Master_Log_Pos: 710
              Relay_Log_Space: 770
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
                  Master_UUID: c67c8183-feb2-11e8-9a5e-0242ac120006
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for the slave I/O thread to update it
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set:
                Auto_Position: 0
1 row in set (0.00 sec)
```

当 `Slave_IO_Running` 和 `Slave_SQL_Running` 为 `Yes` 时，说明同步服务正常。

这时候就可以运行一些 `SQL` 语句来验证同步服务是否正常了。
