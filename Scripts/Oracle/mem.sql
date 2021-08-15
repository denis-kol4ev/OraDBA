set serveroutput on;
whenever sqlerror exit;
set verify off
set term off

column c new_value vMemTotal
select to_char(&1) c from dual;

column c new_value vMemLock
select to_char(floor(&vMemTotal * 0.9)) c from dual;

set term on

PROMPT
PROMPT SGA percent to PGA ratios:
PROMPT 1 = 50 / 50
PROMPT 2 = 60 / 40
PROMPT 3 = 70 / 30
PROMPT 4 = 80 / 20
PROMPT 5 = 90 / 10
PROMPT

accept v_ratio number prompt 'Select a value of SGA to PGA ratio from the table above (1 to 5) '

variable vRatioPct varchar2(100)
variable vSgaTarget varchar2(100)
variable vSgaMax varchar2(100)
variable vPgaLimit varchar2(100)
variable vPgaTarget varchar2(100)
variable vSgaSize number
variable vPgaSize number

declare
  MemLockMb   number := floor(&vMemLock / 1024);
  v_ratio_pct  varchar2(100);
  v_sga_target number;
  v_pga_limit  number;
  v_pga_target number;

begin
  if &v_ratio = 1 then
    v_ratio_pct  := '50 / 50';
    v_sga_target := floor(MemLockMb * 0.5 - 20);
    v_pga_limit  := floor(MemLockMb * 0.5);
    v_pga_target := floor(v_pga_limit * 0.5);
  elsif &v_ratio = 2 then
    v_ratio_pct  := '60 / 40';
    v_sga_target := floor(MemLockMb * 0.6 - 20);
    v_pga_limit  := floor(MemLockMb * 0.4);
    v_pga_target := floor(v_pga_limit / 2);
  elsif &v_ratio = 3 then
    v_ratio_pct  := '70 / 30';
    v_sga_target := floor(MemLockMb * 0.7 - 20);
    v_pga_limit  := floor(MemLockMb * 0.3);
    v_pga_target := floor(v_pga_limit / 2);
  elsif &v_ratio = 4 then
    v_ratio_pct  := '80 / 20';
    v_sga_target := floor(MemLockMb * 0.8 - 20);
    v_pga_limit  := floor(MemLockMb * 0.2);
    v_pga_target := floor(v_pga_limit / 2);
  elsif &v_ratio = 5 then
    v_ratio_pct  := '90 / 10';
    v_sga_target := floor(MemLockMb * 0.9 - 20);
    v_pga_limit  := floor(MemLockMb * 0.1);
    v_pga_target := floor(v_pga_limit / 2);
  else
    raise_application_error(-20000, 'Not valid ratio');
  end if;
:vRatioPct := 'SGA percent to PGA ratio = ' || v_ratio_pct;
:vSgaTarget := 'alter system set sga_target = ' || v_sga_target || 'M scope=spfile;';
:vSgaMax := 'alter system set sga_max_size = ' || v_sga_target || 'M scope=spfile;';
:vPgaLimit := 'alter system set pga_aggregate_limit = ' || v_pga_limit || 'M scope=spfile;';
:vPgaTarget := 'alter system set pga_aggregate_target = ' || v_pga_target || 'M scope=spfile;';
:vSgaSize := v_sga_target;
:vPgaSize := v_pga_limit;
end;
/

set term off
column c new_value vRatioPct noprint
select :vRatioPct c from dual;

column c new_value vSgaTarget noprint
select :vSgaTarget c from dual;

column c new_value vSgaMax noprint
select :vSgaMax c from dual;

column c new_value vPgaLimit noprint
select :vPgaLimit c from dual;

column c new_value vPgaTarget noprint
select :vPgaTarget c from dual;

column c new_value vSgaSize noprint
select :vSgaSize c from dual;

column c new_value vPgaSize noprint
select :vPgaSize c from dual;

column c new_value vHugePages noprint
select to_char(ceil(&vSgaSize * 1024 / 2048 + 10)) c from dual;
set term on

declare
 v1 number;
 v2 number;
begin
    v1 := &vSgaSize * 1024 + &vPgaSize * 1024;
    v2 := &vHugePages * 2048 + &vPgaSize * 1024;
    
    if v1 > &vMemLock or v2 > &vMemLock 
    then 
    dbms_output.put_line('vSgaSize + vPgaSize = ' || v1);
    dbms_output.put_line('vHugePages + vPgaSize = ' || v2);
    dbms_output.put_line('vMemLock = ' || &vMemLock);
    raise_application_error(-20000, 'MemLock limit exceeded');
    end if;
end;
/

PROMPT
PROMPT The value of MemTotal is: &vMemTotal kB 
PROMPT
PROMPT Recommended settings:
PROMPT
PROMPT oracle soft memlock &vMemLock
PROMPT oracle hard memlock &vMemLock
PROMPT
PROMPT vm.nr_hugepages = &vHugePages
PROMPT
PROMPT &vRatioPct
PROMPT &vSgaTarget
PROMPT &vSgaMax
PROMPT &vPgaLimit
PROMPT &vPgaTarget

exit
