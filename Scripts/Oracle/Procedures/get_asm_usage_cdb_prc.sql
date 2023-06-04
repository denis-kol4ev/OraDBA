grant create procedure to c##maint;
grant select on v_$instance to c##maint;
grant select on v_$asm_disk to c##maint;
grant select on v_$asm_diskgroup_stat to c##maint;

create or replace procedure c##maint.get_asm_usage_prc as
  /*
    NAME
      get_asm_usage_prc - получение информации об ASM группах
   
    DESCRIPTION
     Процедура оценивает процент использования ASM групп и выводит рекомендации 
     по количеству и объёму дисков которые необходимо добавить.
    
    NOTES
    
    MODIFIED   (MM/DD/YY)
    dkolchev    28/04/23 - создание процедуры
  */
  l_gr_full_cnt      number;
  l_tech_owner_info  clob := 'Информация для ТВ:';
  l_tech_owner_alert clob;
  l_tech_owner_rec   clob;
  l_asm_usage_info   clob := 'Информация об утилизации дисковых групп:';
  l_asm              number;
  l_host             varchar2(50);
  procedure print_prc(p_label in varchar2, p_msg in varchar2) is
  begin
    dbms_output.put_line(rpad(to_nchar(p_label), 45, '.') || p_msg);
  end;

  procedure print_clob(p_clob in clob) as
    l_offset number default 1;
  begin
    loop
      exit when l_offset > dbms_lob.getlength(p_clob);
      dbms_output.put_line(dbms_lob.substr(p_clob, 512, l_offset));
      l_offset := l_offset + 512;
    end loop;
  end;

begin
  select count(*) into l_asm from v$asm_diskgroup_stat;
  if l_asm = 0 then
    raise_application_error(-20001,
                            'Нет данных в v$asm_diskgroup_stat, похоже что ASM не используется для данной БД');
  end if;

  select host_name into l_host from v$instance;

  with t as
   (SELECT (100 - round(usable_file_mb / total_mb * 100)) as pct_used
      FROM v$asm_diskgroup_stat)
  select count(*) into l_gr_full_cnt from t where pct_used >= 80;
  if l_gr_full_cnt = 0 then
    l_tech_owner_info := l_tech_owner_info || chr(10) || 'На сервере ' ||
                         l_host ||
                         ' нет дисковых групп ASM с утилизацией 80% или выше, добавление дисков не требуется.' ||
                         chr(10);
    print_clob(l_tech_owner_info);
  else
    l_tech_owner_info := l_tech_owner_info || chr(10) || 'На сервере ' ||
                         l_host ||
                         ' есть ASM группы с утилизацией 80% или выше, требуется добавление ресурсов.';
    print_clob(l_tech_owner_info);
    for group_info in (select name as asm_group,
                              type,
                              round(total_mb / 1024) as total_gb,
                              (round(total_mb / 1024) -
                              round(usable_file_mb / 1024)) as used_gb,
                              round(usable_file_mb / 1024) as free_gb,
                              (100 - round(usable_file_mb / total_mb * 100)) as pct_used,
                              round(usable_file_mb / total_mb * 100) as pct_free,
                              case
                                when (100 -
                                     round(usable_file_mb / total_mb * 100)) between 80 and 89 then
                                 'Warning'
                                when (100 -
                                     round(usable_file_mb / total_mb * 100)) >= 90 then
                                 'Critical'
                                else
                                 'Normal'
                              end as severity,
                              case
                                when (100 -
                                     round(usable_file_mb / total_mb * 100)) >= 80 then
                                 greatest(0,
                                          ceil(((total_mb - usable_file_mb) / 75 * 100 -
                                               total_mb) / 1024))
                                else
                                 0
                              end as need_to_add_gb,
                              case
                                when (100 -
                                     round(usable_file_mb / total_mb * 100)) >= 80 then
                                 greatest(0,
                                          ceil(((total_mb - usable_file_mb) / 75 * 100 -
                                               total_mb) /
                                               (select min(d.OS_MB)
                                                  from v$asm_disk d
                                                 where d.GROUP_NUMBER =
                                                       g.GROUP_NUMBER)) *
                                          decode(g.TYPE,
                                                 'EXTERN',
                                                 1,
                                                 'NORMAL',
                                                 2,
                                                 'HIGH',
                                                 3,
                                                 1))
                                else
                                 0
                              end as need_to_add_disk_count,
                              (select ceil(min(d.OS_MB) / 1024)
                                 from v$asm_disk d
                                where d.GROUP_NUMBER = g.GROUP_NUMBER) as disk_size_gb,
                              (select count(d.DISK_NUMBER)
                                 from v$asm_disk d
                                where d.GROUP_NUMBER = g.GROUP_NUMBER) as disk_cnt
                         FROM v$asm_diskgroup_stat g
                        where (100 - round(usable_file_mb / total_mb * 100)) >= 80
                        order by round(usable_file_mb / total_mb * 100)) loop
      l_tech_owner_alert := 'Дисковая группа ' || group_info.asm_group ||
                            ' утилизирована на ' || group_info.pct_used ||
                            '% (критичность - ' || group_info.severity ||
                            '). Для снижения утилизации до 75% необходимо добавление ' ||
                            group_info.need_to_add_gb ||
                            ' Гб. С учётом минимального размера диска в группе, а так же типа избыточности, необходимо добавить диск(и) в количестве ' ||
                            group_info.need_to_add_disk_count ||
                            ' шт. объём одного диска ' ||
                            group_info.disk_size_gb || ' Гб.';
      print_clob(l_tech_owner_alert);
    
    end loop;
    
    l_tech_owner_rec := 'Наша рекомендация - поддерживать утилизацию менее 80%, что покрывает потенциально возможные скачки роста БД, а так же даёт время для поиска дополнительных дисковых ресурсов или для проведения работ по удалению не актуальных данных из БД. Если для БД предусмотрен резервный сервер (standby), то в этом случае на него так же требуется добавление ресурсов.' || chr(10);

    print_clob(l_tech_owner_rec);
  end if;

  print_clob(l_asm_usage_info);

  for group_info in (select name as asm_group,
                            type,
                            round(total_mb / 1024) as total_gb,
                            (round(total_mb / 1024) -
                            round(usable_file_mb / 1024)) as used_gb,
                            round(usable_file_mb / 1024) as free_gb,
                            (100 - round(usable_file_mb / total_mb * 100)) as pct_used,
                            round(usable_file_mb / total_mb * 100) as pct_free,
                            case
                              when (100 -
                                   round(usable_file_mb / total_mb * 100)) between 80 and 89 then
                               'Warning'
                              when (100 -
                                   round(usable_file_mb / total_mb * 100)) >= 90 then
                               'Critical'
                              else
                               'Normal'
                            end as severity,
                            case
                              when (100 -
                                   round(usable_file_mb / total_mb * 100)) >= 80 then
                               greatest(0,
                                        ceil(((total_mb - usable_file_mb) / 75 * 100 -
                                             total_mb) / 1024))
                              else
                               0
                            end as need_to_add_gb,
                            case
                              when (100 -
                                   round(usable_file_mb / total_mb * 100)) >= 80 then
                               greatest(0,
                                        ceil(((total_mb - usable_file_mb) / 75 * 100 -
                                             total_mb) /
                                             (select min(d.OS_MB)
                                                from v$asm_disk d
                                               where d.GROUP_NUMBER =
                                                     g.GROUP_NUMBER)))
                              else
                               0
                            end as need_to_add_disk_count,
                            (select ceil(min(d.OS_MB) / 1024)
                               from v$asm_disk d
                              where d.GROUP_NUMBER = g.GROUP_NUMBER) as disk_size_gb,
                            (select count(d.DISK_NUMBER)
                               from v$asm_disk d
                              where d.GROUP_NUMBER = g.GROUP_NUMBER) as disk_cnt
                       FROM v$asm_diskgroup_stat g
                      order by round(usable_file_mb / total_mb * 100)) loop
    print_prc('Имя дисковой группы', group_info.asm_group);
    print_prc('Суммарный объём Гб', group_info.total_gb);
    print_prc('Использовано Гб', group_info.used_gb);
    print_prc('Свободно Гб', group_info.free_gb);
    print_prc('Использовано %', group_info.pct_used);
    print_prc('Свободно %', group_info.pct_free);
    print_prc('Алерт', group_info.severity);
    print_prc('Минимальный размер диска Гб',
              group_info.disk_size_gb);
    print_prc('Количество дисков в группе',
              group_info.disk_cnt);
    print_prc('Тип избыточности', group_info.type);
    dbms_output.put_line('');
  end loop;
end;
/
