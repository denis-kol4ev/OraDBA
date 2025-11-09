-- Необходимые привилегии
create user maint identified by Zz123456;
alter user maint quota unlimited on users;
grant create trigger to maint;
grant administer database trigger to maint;
grant select on dba_services to maint;
grant select on v_$active_services to maint;
grant select on v_$database to maint;
grant execute on dbms_service to maint;
grant execute on dbms_system to maint;

-- Таблица настроек
create table maint.services (
   service_name varchar2(64) not null,
   start_on     varchar2(64) default 'BOTH',
   constraint pk_wms_services primary key ( service_name ),
   constraint chk_allowed_values
      check ( start_on in ( 'PRIMARY',
                            'PHYSICAL STANDBY',
                            'BOTH' ) )
);

CREATE OR REPLACE PACKAGE maint.services_processing_pkg as

/*
NAME
 maint.services_processing_pkg - управление сервисами

DESCRIPTION
 Пакет предназначен для управления сервисами через dbms_service 
 на основании таблицы настроек - maint.services
 Для каждого сервиса в таблице настроек определяется при какой
 роли БД он должен быть запущен или же должен запускаться вне
 зависимости от роли.
       
NOTES
 Все процедуры пакета логируют действия в алертлог БД

*/

-- Проверка роли БД
function is_primary return boolean;
function is_standby return boolean;

-- Проверка существования сервиса
function is_service_exist(p_service in dba_services.network_name%type) return boolean;

-- Проверка что сервис запущен
function is_service_running(p_service in v$active_services.network_name%type) return boolean;

-- Запуск и остановка сервиса
procedure start_service(p_service in varchar2);
procedure stop_service(p_service in varchar2);

-- Создание сервиса и его добавление в таблицу настроек 
-- Допустимые значения для p_start_on
-- PRIMARY или PHYSICAL STANDBY - запуск в зависимости от роли БД 
-- BOTH - если необходимо запускать не зависимо от роли БД
procedure create_service(p_service in varchar2, p_start_on in varchar2 default 'BOTH');

-- Удаление сервиса из БД и таблицы настроек 
procedure delete_service(p_service in varchar2);

-- Запуск и остановка сервисов согласно правилам таблицы настроек
procedure bring_services_into_consistent_state;

END services_processing_pkg;
/

CREATE OR REPLACE PACKAGE BODY maint.services_processing_pkg AS
function is_primary return boolean as
    v_role varchar2(100);
  begin
      select d.DATABASE_ROLE
        into v_role
        from v$database d;
    return v_role = 'PRIMARY';
  end is_primary;

function is_standby return boolean as
    v_role varchar2(100);
  begin
      select d.DATABASE_ROLE
        into v_role
        from v$database d;
    return v_role = 'PHYSICAL STANDBY';
  end is_standby;

function is_service_exist(p_service dba_services.network_name%type) return boolean as
    v_service_check dba_services.network_name%type;
  begin
    begin
      select network_name into v_service_check from dba_services where network_name = p_service;
    exception
      when others then
        v_service_check := null;
    end;
    return v_service_check is not null;
  end is_service_exist;

function is_service_running(p_service v$active_services.network_name%type) return boolean as
    v_service_check v$active_services.network_name%type;
  begin
    begin
      select network_name into v_service_check from v$active_services where network_name = p_service;
    exception
      when others then
        v_service_check := null;
    end;
    return v_service_check is not null;
  end is_service_running;

procedure start_service(p_service in varchar2) as 
  begin
    sys.dbms_system.ksdwrt(2, $$plsql_unit||': START_SERVICE '|| p_service);
    sys.dbms_service.start_service(p_service);
  exception
    when others then sys.dbms_system.ksdwrt(2, $$plsql_unit||': ' || SQLERRM);
  end start_service;

procedure stop_service(p_service in varchar2) as 
  begin
    sys.dbms_system.ksdwrt(2, $$plsql_unit||': STOP_SERVICE '|| p_service);
    sys.dbms_service.stop_service(p_service);
  exception
    when others then sys.dbms_system.ksdwrt(2, $$plsql_unit||': ' || SQLERRM);
  end stop_service;

procedure create_service(p_service in varchar2, p_start_on in varchar2 default 'BOTH') as 
  begin
   if not is_service_exist(p_service) then
    sys.dbms_system.ksdwrt(2, $$plsql_unit||': CREATE_SERVICE '|| p_service);
    sys.dbms_service.create_service(p_service,p_service);
    insert into maint.services (service_name, start_on) values (p_service, p_start_on);
    commit;
   end if;
  exception
    when others then sys.dbms_system.ksdwrt(2, $$plsql_unit||': ' || SQLERRM);
  end create_service;

procedure delete_service(p_service in varchar2) as 
  begin
    if is_service_exist(p_service) then 
           if is_service_running(p_service) then 
            stop_service(p_service => p_service);
           end if;
    sys.dbms_system.ksdwrt(2, $$plsql_unit||': DELETE_SERVICE '|| p_service);
    sys.dbms_service.delete_service(p_service);
    delete from maint.services where service_name = p_service;
    commit;
         end if;
  exception
    when others then sys.dbms_system.ksdwrt(2, $$plsql_unit||': ' || SQLERRM);
  end delete_service;

procedure bring_services_into_consistent_state as 
  begin
       if is_primary then
     for i in (select service_name, start_on from maint.services) LOOP
       if i.start_on in ('PRIMARY', 'BOTH') then
         if is_service_exist(i.service_name) then 
           if not is_service_running(i.service_name) then 
            start_service(p_service => i.service_name);
           end if;
         end if;  
       else
        if i.start_on in ('PHYSICAL STANDBY') then
         if is_service_exist(i.service_name) then 
           if is_service_running(i.service_name) then 
            stop_service(p_service => i.service_name);
           end if;
         end if;
        end if;
       end if;
       end loop;
    END IF;
    if is_standby then
     for i in (select service_name, start_on from maint.services) LOOP
       if i.start_on in ('PHYSICAL STANDBY', 'BOTH') then
         if is_service_exist(i.service_name) then 
           if not is_service_running(i.service_name) then 
            start_service(p_service => i.service_name);
           end if;
         end if;  
       else
        if i.start_on in ('PRIMARY') then
         if is_service_exist(i.service_name) then 
           if is_service_running(i.service_name) then 
            stop_service(p_service => i.service_name);
           end if;
         end if;
        end if;
       end if;
       end loop;
       END IF;
  end bring_services_into_consistent_state;

END services_processing_pkg;
/

-- Запускаем необходимые сервисы согласно таблицы maint.services
begin
   maint.services_processing_pkg.bring_services_into_consistent_state;
end;
/

-- Запускаем необходимые сервисы согласно таблицы maint.services после старта БД
create or replace trigger maint.services_after_startup
  after startup on database
begin
  maint.services_processing_pkg.bring_services_into_consistent_state;
end;
/

-- Запускаем необходимые сервисы согласно таблицы maint.services после смены роли БД
create or replace trigger maint.services_after_role_change
  after DB_ROLE_CHANGE on database
begin
  maint.services_processing_pkg.bring_services_into_consistent_state;
end;
/
