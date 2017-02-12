alter database default tablespace USERS;

CREATE USER rom_sql IDENTIFIED BY rom_sql;

GRANT unlimited tablespace, create session, create table, create sequence,
create procedure, create trigger, create view, create materialized view,
create database link, create synonym, create type, ctxapp TO rom_sql;
