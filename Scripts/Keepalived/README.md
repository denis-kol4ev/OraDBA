# Keepalived

Keepalived — ПО для обеспечения высокой доступности (high availabilitty) и балансировки нагрузки (load balancing) для Linux серверов.

HA (high availabilitty) реализован на базе протокола VRRP (Virtual Router Redundancy Protocol) и решает задачу доступности виртуального IP адреса (VIP).

LB (load balancing) реализован на базе IPVS (IP Virtual Server), механизма балансировки встроенного в ядро Linux, с его помощью решается задача балансировки нагрузки.

Мы используем только функционал высокой доступности, для того чтобы обеспечить доступность БД по определенному адресу в зависимости от текущей роли БД. 

Если роль БД primary, то она будет доступна по VIP1 , если роль изменилась на standby то БД будет доступна по VIP2.
Это дает возможность ничего 

Задача: обеспечить доступность БД по одному и тому же IP адресу вне зависимости от роли БД primary или standby

As Is
При смене ролей БД необходимо вручную переносить VIP на другой сервер. 
Клиенты имеющие право подключения только на standby после смены ролей получают ошибку и им требуется вручную менять строку подключения.   

To Be
Каждый из серверов primary и standby имеет собственный VIP 
При смене ролей БД нужный VIP поднимается автоматически 
Клиенты имеющие право подключения только на standby всегда подключаются к одному и тому же VIP, после смены ролей менять строку подключения не нужно.

Так же поставленная задача может быть реплизована с использованием
How To Configure Client Failover For Data Guard Connections Using Database Services (Doc ID 1429223.1)
Мы рассматриваем случае где количество клиентов на которых необходимо поменять строку подключения jdbc или tnsnames.ora неизвестно.
Клиентсоке ПО не поддерживает стро
Для коробочных приложений в которых настройка проводится через инсталлятор и нельзя задать произвольную строку подключения к БД с указанием нескольких серверов.

Настройка keepalived

1. Установка
yum install -y keepalived
keepalived --version
systemctl status keepalived

2. Перенос конфиурационных файлов

cd /etc/keepalived
mv keepalived.conf keepalived.conf.default
mv /home/oracle/maint/keepalived.conf ./keepalived.conf

mkdir -pv /home/oracle/maint/keepalived

chown oracle:oinstall /home/oracle/maint/lsnr_restart.sh
chown oracle:oinstall /home/oracle/maint/primary_check.sh
chown oracle:oinstall /home/oracle/maint/standby_check.sh

chmod 700 /home/oracle/maint/lsnr_restart.sh
chmod 700 /home/oracle/maint/primary_check.sh
chmod 700 /home/oracle/maint/standby_check.sh

mv /home/oracle/maint/keepalived_notify.sh /usr/local/bin/
chmod 700 /usr/local/bin/keepalived_notify.sh

systemctl enable keepalived
systemctl start keepalived
systemctl status keepalived

journalctl -u keepalived -n20


journalctl --disk-usage
journalctl --vacuum-time=7d
journalctl --vacuum-size=10M

1234