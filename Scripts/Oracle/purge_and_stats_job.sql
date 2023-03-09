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
