--Проверка наличия джобов со временем работы более 60 мин
with t1 as
 (select extract(day from(elapsed_time)) * 24 * 60 * 60 +
         extract(hour from(elapsed_time)) * 60 * 60 +
         extract(minute from(elapsed_time)) * 60 +
         extract(second from(elapsed_time)) duration_sec
    from dba_scheduler_running_jobs
   where owner in ('MAINT', 'C##MAINT', 'SYS'))
select count(*) as c from t1 where duration_sec > 3600;

grant PURGE DBA_RECYCLEBIN to maint;
grant PURGE DBA_RECYCLEBIN, ANALYZE ANY DICTIONARY, ANALYZE ANY to maint;
begin
  execute immediate 'PURGE DBA_RECYCLEBIN';
  DBMS_STATS.GATHER_DICTIONARY_STATS;
  DBMS_STATS.GATHER_FIXED_OBJECTS_STATS;
end;
/
begin
dbms_scheduler.drop_job('MAINT.PURGE_AND_STATS_JOB');
end;

-- Оптимизируем скорость запросов Zabbix к системным представлениям
-- Queries on DBA_FREE_SPACE are Slow (Doc ID 271169.1)
-- How to Gather Statistics on Objects Owned by the 'SYS' User and 'Fixed' Objects (Doc ID 457926.1)

grant PURGE DBA_RECYCLEBIN, ANALYZE ANY DICTIONARY, ANALYZE ANY to maint;

begin
  sys.dbms_scheduler.create_job(job_name        => 'MAINT.PURGE_AND_STATS_JOB',
                                job_type        => 'PLSQL_BLOCK',
                                job_action      => 'begin 
                                                         execute immediate ''PURGE DBA_RECYCLEBIN'';
                                                         DBMS_STATS.GATHER_DICTIONARY_STATS;
                                                         DBMS_STATS.GATHER_FIXED_OBJECTS_STATS;
                                                        end;',
                                start_date      => to_date('10-03-2023 10:00:00',
                                                           'dd-mm-yyyy hh24:mi:ss'),
                                repeat_interval => 'Freq=Hourly;Interval=24',
                                end_date        => to_date(null),
                                job_class       => 'DEFAULT_JOB_CLASS',
                                enabled         => true,
                                auto_drop       => false,
                                comments        => 'Оптимизируем скорость запросов Zabbix к системным представлениям');
end;
/

--Тестовый запуск
begin
	 dbms_scheduler.run_job('MAINT.PURGE_AND_STATS_JOB');
end;

--Проверка лога
select * from dba_scheduler_job_run_details d where d.job_name='PURGE_AND_STATS_JOB' order by d.log_date desc;
