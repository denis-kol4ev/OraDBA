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

<details><summary>As Is</summary>

![as_is](images/as_is.png)

* При смене ролей БД необходимо перенастраивать клиентов на подключение к новому серверу
* Клиенты которые подключались только на standby теперь подключаются на primary, тем самым создавая не запланированнную нагрузку
* Если клиенты имеют право подключения только на standby (триггер на профиль пользователя), то после смены ролей они будут получать ошибку пока не сменят строку подключения

</details>

<details><summary>To Be</summary>

![to_be](images/to_be.png)

* Каждый из серверов primary и standby имеет собственный VIP
* При смене ролей БД нужный VIP поднимается автоматически
* Не нужно менять строку подключения на клиентах, так как они настроены на "плавающий" VIP, который всегда соответствует роли БД

</details>

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
ip a
```

### 4. Просмотр логов

```shell
journalctl -u keepalived -n20
```

## Проверка работы keepalived

### 1. Проверка адресов

```shell
cat /etc/hosts | egrep "angel19|devil19|prm-db|stb-db"

10.10.10.230 angel19 angel19.company.local
10.10.10.231 devil19 devil19.company.local
10.10.10.233 prm-db prm-db.company.local
10.10.10.234 stb-db stb-db.company.local
```

```shell
ip a | egrep "eth1$"
```

в выводе фиксируем по два адреса

для праймари
```shell
    inet 10.10.10.230/24 brd 10.10.10.255 scope global eth1
    inet 10.10.10.233/24 scope global secondary eth1
```

для стендбай
```shell
    inet 10.10.10.231/24 brd 10.10.10.255 scope global eth1
    inet 10.10.10.234/24 scope global secondary eth1
```

2. Проверка tnsnames.ora

```shell
vi $ORACLE_HOME/network/admin/tnsnames.ora

orcl_primary =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = prm-db)(PORT = 1521))
    (CONNECT_DATA = (SERVICE_NAME = keepalive_orcl))
  )

orcl_standby =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = stb-db)(PORT = 1521))
    (CONNECT_DATA = (SERVICE_NAME = keepalive_orcl))
  )
```

orcl_primary и orcl_standby записи ссылающиеся на vip адреса prm-db и stb-db соответственно 

убедимся что записи валидные для подключения

```shell
echo "select HOST_NAME from v\$instance;" | sqlplus -s system/<pass>@orcl_primary

HOST_NAME
---------
angel19

echo "select HOST_NAME from v\$instance;" | sqlplus -s system/<pass>@orcl_standby

HOST_NAME
---------
devil19

```

3. Открываем лог keepalived на обоих серверах

```shell
sudo journalctl -u keepalived -f
```

видим сообщение от службы каждые 5 сек

4. Смена ролей БД

```shell
dgmgrl /
connect sys
show configuration;
validate database orcl_angel19;
validate database orcl_devil19;
switchover to orcl_devil19;
show configuration;
```

5. Анализ лога keepalived на обоих серверах

```shell
sudo journalctl -u keepalived -n 1000 > out.txt
```

<details><summary>Лог бывшего праймари</summary>
<pre>
Dec 24 18:44:26 angel19 Keepalived_vrrp[1275]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1 <b><-- так как роль БД primary, проверка standby_check возвращает ошибку</b>
Dec 24 18:44:31 angel19 Keepalived_vrrp[1275]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1
Dec 24 18:44:36 angel19 Keepalived_vrrp[1275]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1
Dec 24 18:44:41 angel19 Keepalived_vrrp[1275]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1
Dec 24 18:44:46 angel19 Keepalived_vrrp[1275]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1
Dec 24 18:44:52 angel19 Keepalived_vrrp[1275]: /home/oracle/maint/keepalived/primary_check.sh exited with status 255 <b><-- в момент смены ролей обе проверки</b> 
Dec 24 18:44:52 angel19 Keepalived_vrrp[1275]: /home/oracle/maint/keepalived/standby_check.sh exited with status 255 <b><-- возвращают код ошибки</b>
Dec 24 18:44:59 angel19 Keepalived_vrrp[1275]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1
Dec 24 18:45:01 angel19 Keepalived_vrrp[1275]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1
Dec 24 18:45:06 angel19 Keepalived_vrrp[1275]: /home/oracle/maint/keepalived/primary_check.sh exited with status 1
Dec 24 18:45:11 angel19 Keepalived_vrrp[1275]: /home/oracle/maint/keepalived/primary_check.sh exited with status 1
Dec 24 18:45:11 angel19 Keepalived_vrrp[1275]: VRRP_Script(primary_check) failed 
Dec 24 18:45:11 angel19 Keepalived_vrrp[1275]: VRRP_Script(standby_check) succeeded <b><-- смена ролей завершена, проверка standby_check теперь проходит успешно</b>
Dec 24 18:45:12 angel19 Keepalived_vrrp[1275]: VRRP_Instance(VIP_PRIMARY) Entering FAULT STATE
Dec 24 18:45:12 angel19 Keepalived_vrrp[1275]: VRRP_Instance(VIP_PRIMARY) removing protocol VIPs. <b><-- отключение vip адреса primary</b> 
Dec 24 18:45:12 angel19 Keepalived_vrrp[1275]: Opening script file /usr/local/bin/keepalived_notify.sh <b><-- вызов скрипта для рестарта листнера т.к. убрали ip</b>
Dec 24 18:45:12 angel19 Keepalived_vrrp[1275]: VRRP_Instance(VIP_PRIMARY) Now in FAULT state
Dec 24 18:45:12 angel19 su[55630]: (to oracle) root on none
Dec 24 18:45:13 angel19 Keepalived_vrrp[1275]: Kernel is reporting: interface eth1 UP
Dec 24 18:45:13 angel19 Keepalived_vrrp[1275]: VRRP_Instance(VIP_STANDBY): Transition to MASTER STATE
Dec 24 18:45:13 angel19 Keepalived_vrrp[1275]: VRRP_Instance(VIP_STANDBY) Transition to MASTER STATE
Dec 24 18:45:14 angel19 Keepalived_vrrp[1275]: VRRP_Instance(VIP_STANDBY) Entering MASTER STATE
Dec 24 18:45:14 angel19 Keepalived_vrrp[1275]: VRRP_Instance(VIP_STANDBY) setting protocol VIPs. <b><-- активация vip адреса standby</b>
Dec 24 18:45:14 angel19 Keepalived_vrrp[1275]: Sending gratuitous ARP on eth1 for 10.10.10.234
Dec 24 18:45:14 angel19 Keepalived_vrrp[1275]: VRRP_Instance(VIP_STANDBY) Sending/queueing gratuitous ARPs on eth1 for 10.10.10.234
Dec 24 18:45:14 angel19 Keepalived_vrrp[1275]: Sending gratuitous ARP on eth1 for 10.10.10.234
Dec 24 18:45:14 angel19 Keepalived_vrrp[1275]: Sending gratuitous ARP on eth1 for 10.10.10.234
Dec 24 18:45:14 angel19 Keepalived_vrrp[1275]: Sending gratuitous ARP on eth1 for 10.10.10.234
Dec 24 18:45:14 angel19 Keepalived_vrrp[1275]: Sending gratuitous ARP on eth1 for 10.10.10.234
Dec 24 18:45:14 angel19 Keepalived_vrrp[1275]: Opening script file /usr/local/bin/keepalived_notify.sh <b><-- вызов скрипта для рестарта листнера т.к. добавили ip</b>
Dec 24 18:45:14 angel19 su[55745]: (to oracle) root on none
Dec 24 18:45:16 angel19 Keepalived_vrrp[1275]: /home/oracle/maint/keepalived/primary_check.sh exited with status 1
Dec 24 18:45:19 angel19 Keepalived_vrrp[1275]: Sending gratuitous ARP on eth1 for 10.10.10.234
Dec 24 18:45:19 angel19 Keepalived_vrrp[1275]: VRRP_Instance(VIP_STANDBY) Sending/queueing gratuitous ARPs on eth1 for 10.10.10.234
Dec 24 18:45:19 angel19 Keepalived_vrrp[1275]: Sending gratuitous ARP on eth1 for 10.10.10.234
Dec 24 18:45:19 angel19 Keepalived_vrrp[1275]: Sending gratuitous ARP on eth1 for 10.10.10.234
Dec 24 18:45:19 angel19 Keepalived_vrrp[1275]: Sending gratuitous ARP on eth1 for 10.10.10.234
Dec 24 18:45:19 angel19 Keepalived_vrrp[1275]: Sending gratuitous ARP on eth1 for 10.10.10.234
Dec 24 18:45:21 angel19 Keepalived_vrrp[1275]: /home/oracle/maint/keepalived/primary_check.sh exited with status 1 <b><-- так как теперь роль БД standby, проверка primary_check возвращает ошибку</b>
Dec 24 18:45:26 angel19 Keepalived_vrrp[1275]: /home/oracle/maint/keepalived/primary_check.sh exited with status 1
Dec 24 18:45:31 angel19 Keepalived_vrrp[1275]: /home/oracle/maint/keepalived/primary_check.sh exited with status 1
</pre>
</details>

<details><summary>Лог бывшего стендбай</summary>
<pre>
Dec 24 18:44:15 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/primary_check.sh exited with status 1
Dec 24 18:44:20 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/primary_check.sh exited with status 1
Dec 24 18:44:25 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/primary_check.sh exited with status 1
Dec 24 18:44:30 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/primary_check.sh exited with status 1
Dec 24 18:44:35 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/primary_check.sh exited with status 1
Dec 24 18:44:41 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/primary_check.sh exited with status 255
Dec 24 18:44:41 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/standby_check.sh exited with status 255
Dec 24 18:44:45 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1
Dec 24 18:44:45 devil19 Keepalived_vrrp[1285]: VRRP_Script(standby_check) failed
Dec 24 18:44:46 devil19 Keepalived_vrrp[1285]: VRRP_Instance(VIP_STANDBY) Entering FAULT STATE
Dec 24 18:44:46 devil19 Keepalived_vrrp[1285]: VRRP_Instance(VIP_STANDBY) removing protocol VIPs.
Dec 24 18:44:46 devil19 Keepalived_vrrp[1285]: Opening script file /usr/local/bin/keepalived_notify.sh
Dec 24 18:44:46 devil19 Keepalived_vrrp[1285]: VRRP_Instance(VIP_STANDBY) Now in FAULT state
Dec 24 18:44:46 devil19 su[57253]: (to oracle) root on none
Dec 24 18:44:50 devil19 Keepalived_vrrp[1285]: VRRP_Script(primary_check) succeeded
Dec 24 18:44:50 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1
Dec 24 18:44:51 devil19 Keepalived_vrrp[1285]: VRRP_Instance(VIP_PRIMARY) Entering BACKUP STATE
Dec 24 18:44:51 devil19 Keepalived_vrrp[1285]: Opening script file /usr/local/bin/keepalived_notify.sh
Dec 24 18:44:51 devil19 su[57439]: (to oracle) root on none
Dec 24 18:44:55 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1
Dec 24 18:45:00 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1
Dec 24 18:45:05 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1
Dec 24 18:45:10 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1
Dec 24 18:45:12 devil19 Keepalived_vrrp[1285]: VRRP_Instance(VIP_PRIMARY) Transition to MASTER STATE
Dec 24 18:45:13 devil19 Keepalived_vrrp[1285]: VRRP_Instance(VIP_PRIMARY) Entering MASTER STATE
Dec 24 18:45:13 devil19 Keepalived_vrrp[1285]: VRRP_Instance(VIP_PRIMARY) setting protocol VIPs.
Dec 24 18:45:13 devil19 Keepalived_vrrp[1285]: Sending gratuitous ARP on eth1 for 10.10.10.233
Dec 24 18:45:13 devil19 Keepalived_vrrp[1285]: VRRP_Instance(VIP_PRIMARY) Sending/queueing gratuitous ARPs on eth1 for 10.10.10.233
Dec 24 18:45:13 devil19 Keepalived_vrrp[1285]: Sending gratuitous ARP on eth1 for 10.10.10.233
Dec 24 18:45:13 devil19 Keepalived_vrrp[1285]: Sending gratuitous ARP on eth1 for 10.10.10.233
Dec 24 18:45:13 devil19 Keepalived_vrrp[1285]: Sending gratuitous ARP on eth1 for 10.10.10.233
Dec 24 18:45:13 devil19 Keepalived_vrrp[1285]: Sending gratuitous ARP on eth1 for 10.10.10.233
Dec 24 18:45:13 devil19 Keepalived_vrrp[1285]: Opening script file /usr/local/bin/keepalived_notify.sh
Dec 24 18:45:13 devil19 su[57731]: (to oracle) root on none
Dec 24 18:45:15 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1
Dec 24 18:45:18 devil19 Keepalived_vrrp[1285]: Sending gratuitous ARP on eth1 for 10.10.10.233
Dec 24 18:45:18 devil19 Keepalived_vrrp[1285]: VRRP_Instance(VIP_PRIMARY) Sending/queueing gratuitous ARPs on eth1 for 10.10.10.233
Dec 24 18:45:18 devil19 Keepalived_vrrp[1285]: Sending gratuitous ARP on eth1 for 10.10.10.233
Dec 24 18:45:18 devil19 Keepalived_vrrp[1285]: Sending gratuitous ARP on eth1 for 10.10.10.233
Dec 24 18:45:18 devil19 Keepalived_vrrp[1285]: Sending gratuitous ARP on eth1 for 10.10.10.233
Dec 24 18:45:18 devil19 Keepalived_vrrp[1285]: Sending gratuitous ARP on eth1 for 10.10.10.233
Dec 24 18:45:20 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1
Dec 24 18:45:25 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1
Dec 24 18:45:30 devil19 Keepalived_vrrp[1285]: /home/oracle/maint/keepalived/standby_check.sh exited with status 1
</pre>
</details>

6. Проверка подключения

Убедимся что не меняя настройки подключения мы попадаем на сервер БД с нужной нам ролью

```shell
echo "select HOST_NAME from v\$instance;" | sqlplus -s system/<pass>@orcl_primary

HOST_NAME
---------
devil19

echo "select HOST_NAME from v\$instance;" | sqlplus -s system/<pass>@orcl_standby

HOST_NAME
---------
angel19

```