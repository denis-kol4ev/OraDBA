# Keepalived

**Keepalived** — ПО для обеспечения высокой доступности (high availabilitty) и балансировки нагрузки (load balancing) для Linux серверов.

**HA (high availabilitty)** реализован на базе протокола VRRP (Virtual Router Redundancy Protocol) и решает задачу доступности виртуального IP адреса (VIP).

**LB (load balancing)** реализован на базе IPVS (IP Virtual Server), механизма балансировки встроенного в ядро Linux, с его помощью решается задача балансировки нагрузки.

Мы будем использовать функционал высокой доступности keepalived, для решения задачи доступности БД по определенному адресу в зависимости от текущей роли БД (primary или standby). \
БД с ролью primary всегда будет доступна по VIP1, в то вермя как БД с ролью standby всегда будет доступна по VIP2. \
После операции switchover VIP1 автоматически поднимется на новом primary, а VIP2 на новом standby. \
Это дает возможность не менять строку подключения на стороне клиента в случае смены ролей БД.

Так же поставленная задача может быть реплизована с использованием решения описанного в \
How To Configure Client Failover For Data Guard Connections Using Database Services (Doc ID 1429223.1) \
Мы же рассматриваем случай когда количество клиентов велико и поменять у них строку подключения jdbc или tnsnames.ora проблематично.
Либо для приложений настройка которых проводится через инсталлятор и нельзя задать произвольную строку подключения к БД с указанием нескольких серверов.

**As Is**

* При смене ролей БД необходимо вручную переносить VIP на другой сервер. 
* Клиенты имеющие право подключения только на standby после смены ролей получают ошибку и им требуется вручную менять строку подключения.   

**To Be**

* Каждый из серверов primary и standby имеет собственный VIP.
* При смене ролей БД нужный VIP поднимается автоматически. 
* Клиенты имеющие право подключения только на standby всегда подключаются к одному и тому же VIP, после смены ролей менять строку подключения не нужно.

## Настройка keepalived

### 1. Установка

```shell
yum install -y keepalived
keepalived --version
systemctl status keepalived
```

### 2. Конфигурационные файлы

Переносим конфигурационные файлы из git проекта по соответствующим папкам

```shell
cp keepalived.conf /etc/keepalived/
chown root:root /etc/keepalived/keepalived.conf
chmod 644 /etc/keepalived/keepalived.conf

cp keepalived_notify.sh /usr/local/bin/
chown root:root /usr/local/bin/keepalived_notify.sh 
chmod 744 /usr/local/bin/keepalived_notify.sh

mkdir -p /home/oracle/maint/keepalived
chown oracle:oinstall /home/oracle/maint/keepalived

cp lsnr_restart.sh /home/oracle/maint/keepalived/
cp primary_check.sh /home/oracle/maint/keepalived/
cp standby_check.sh /home/oracle/maint/keepalived/
cp ora_env /home/oracle/maint/keepalived/

chown oracle:oinstall /home/oracle/maint/keepalived/lsnr_restart.sh
chown oracle:oinstall /home/oracle/maint/keepalived/primary_check.sh
chown oracle:oinstall /home/oracle/maint/keepalived/standby_check.sh
chown oracle:oinstall /home/oracle/maint/keepalived/ora_env

chmod 744 /home/oracle/maint/keepalived/lsnr_restart.sh
chmod 744 /home/oracle/maint/keepalived/primary_check.sh
chmod 744 /home/oracle/maint/keepalived/standby_check.sh
chmod 644 /home/oracle/maint/keepalived/ora_env
```

### 3. Добавляем в автозагрузку и запускаем

```shell
systemctl enable keepalived
systemctl start keepalived
systemctl status keepalived
```

### 4. Просмотр логов

```shell
journalctl -u keepalived -n20
```
