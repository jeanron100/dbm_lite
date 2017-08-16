#!/bin/bash
sqlplus -s $DB_CONN_STR@$SH_DB_SID <<EOF
REM ------------------------------------------------------------------------

set pagesize 20
set feedback off
set verify off
set head on
alter session set nls_date_format='HH:MI:SS DD-MON-YY';

col host_name for a15
col instance_name format a11
col version format a15
col status format a8
col RAC for a5
col log_mode format a10
col platform_name format a20
set lines 150
PROMPT
--PROMPT --------------- Instance  general information ------------------

select (select decode(value,'TRUE','YES','NO')from v\$option WHERE Parameter = 'Real Application Clusters') RAC,
       (select log_mode||','||database_role from v\$database where rownum<2)log_mode,
       (select platform_name from v\$database where rownum<2)platform_name,
inst_id, instance_name, host_name, version, status, startup_time
from gv\$instance
order by inst_id;
PROMPT 

EOF
exit
