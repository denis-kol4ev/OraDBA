-- Procedure add_user_prc allow non administrative user to create database users

-- grant privs
grant create user to system;
grant create session to system with admin option;
grant create table to system with admin option; 

-- create proc
create or replace procedure system.add_user_prc(username in varchar2) as
begin
  execute immediate 'create user ' || username ||' identified by Xxx default tablespace USERS temporary tablespace TEMP profile DEFAULT quota 50G on USERS';
  execute immediate 'grant create session to ' || username;
  execute immediate 'grant create table to ' || username;
end;
/
