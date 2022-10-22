-- Версия запроса без доп полей
-- Добавление файла в табличное пространтсво.
-- Находим файл с макисмальным номером в имени и увеличиваем на единицу.
-- Предполагается что все файлы имеют стандартное расширение .dbf
-- Запрос учитывает:
-- a.Цифры могут быть не только в конце имени файла, например arc_wh1_data_137.dbf
-- b.Файл может не содержать цифр в имени, тогда последующий файл будет иметь имя <file_name>02.dbf
-- c.Табличное пространство не является bigfile

select file_name as last_file,
       case
         when regexp_count(regexp_substr(lower(file_name), '\d+\.dbf'), '\d+') > 0 then
          regexp_replace(lower(file_name),
                         to_number(regexp_substr(regexp_substr(lower(file_name), '\d+\.dbf'),'\d+')),
                         to_number(regexp_substr(regexp_substr(lower(file_name),'\d+\.dbf'),'\d+')) + 1)
         else
          regexp_replace(lower(file_name), '\.dbf', '02.dbf')
       end as next_file,
       case
         when regexp_count(regexp_substr(lower(file_name), '\d+\.dbf'), '\d+') > 0 then
          'alter tablespace ' || tablespace_name || ' add datafile ''' ||
          regexp_replace(lower(file_name),
                         to_number(regexp_substr(regexp_substr(lower(file_name), '\d+\.dbf'), '\d+')),
                         to_number(regexp_substr(regexp_substr(lower(file_name), '\d+\.dbf'), '\d+')) + 1) ||
          ''' size 1024m autoextend on next 256m maxsize unlimited;'
         else
          'alter tablespace ' || tablespace_name || ' add datafile ''' ||
          regexp_replace(lower(file_name), '\.dbf', '02.dbf') ||
          ''' size 1024m autoextend on next 256m maxsize unlimited;'
       end as next_file_cmd
  FROM dba_data_files
 where tablespace_name = upper('&TABLESPACE_NAME')
   and exists
 (select 1
          from dba_tablespaces
         where bigfile = 'NO'
           and tablespace_name = upper('&TABLESPACE_NAME'))
 order by to_number(regexp_substr(regexp_substr(lower(file_name),
                                                '\d+\.dbf'),
                                  '\d+')) desc nulls last
 fetch first row only;

-- Полная версия запроса с доп полями
-- Добавление файла в табличное пространтсво.
-- Находим файл с макисмальным номером в имени и увеличиваем на единицу.
-- Предполагается что все файлы имеют стандартное расширение .dbf
-- Запрос учитывает:
-- a.Цифры могут быть не только в конце имени файла, например arc_wh1_data_137.dbf
-- b.Файл может не содержать цифр в имени, тогда последующий файл будет иметь имя <file_name>02.dbf
-- c.Табличное пространство не является bigfile

select file_name as last_file,
       file_id,
       substr(file_name, instr(file_name, '/', -1) + 1) as name_short,
       to_number(regexp_substr(regexp_substr(lower(file_name), '\d+\.dbf'), '\d+')) as name_digit,
       case
         when regexp_count(regexp_substr(lower(file_name), '\d+\.dbf'), '\d+') > 0 then
          to_number(regexp_substr(regexp_substr(lower(file_name), '\d+\.dbf'), '\d+')) + 1
         else
          2
       end as next_name_digit,
       case
         when regexp_count(regexp_substr(lower(file_name), '\d+\.dbf'), '\d+') > 0 then
          regexp_replace(lower(file_name),
                         to_number(regexp_substr(regexp_substr(lower(file_name), '\d+\.dbf'),'\d+')),
                         to_number(regexp_substr(regexp_substr(lower(file_name),'\d+\.dbf'),'\d+')) + 1)
         else
          regexp_replace(lower(file_name), '\.dbf', '02.dbf')
       end as next_file,
       case
         when regexp_count(regexp_substr(lower(file_name), '\d+\.dbf'), '\d+') > 0 then
          'alter tablespace ' || tablespace_name || ' add datafile ''' ||
          regexp_replace(lower(file_name),
                         to_number(regexp_substr(regexp_substr(lower(file_name), '\d+\.dbf'), '\d+')),
                         to_number(regexp_substr(regexp_substr(lower(file_name), '\d+\.dbf'), '\d+')) + 1) ||
          ''' size 1024m autoextend on next 256m maxsize unlimited;'
         else
          'alter tablespace ' || tablespace_name || ' add datafile ''' ||
          regexp_replace(lower(file_name), '\.dbf', '02.dbf') ||
          ''' size 1024m autoextend on next 256m maxsize unlimited;'
       end as next_file_cmd
  FROM dba_data_files
 where tablespace_name = upper('&TABLESPACE_NAME')
   and exists
 (select 1
          from dba_tablespaces
         where bigfile = 'NO'
           and tablespace_name = upper('&TABLESPACE_NAME'))
 order by to_number(regexp_substr(regexp_substr(lower(file_name),
                                                '\d+\.dbf'),
                                  '\d+')) desc nulls last
 fetch first row only;
