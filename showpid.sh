#!/bin/bash

if [ -z "$1" ]; then 
 echo "no process has provided!" 
 exit 0
fi
sh_tmp_process=`sqlplus -silent $DB_CONN_STR@$SH_DB_SID <<END
set pagesize 0 feedback off verify off heading on echo off 
select addr from v\\$process where spid=$1;
exit; 
END` 

if [ -z "$sh_tmp_process" ]; then 
 echo "no process exists or session is not from a DB account" 
 echo 
 echo "####### Process Information from OS level as below ########" 
 ps -ef|grep $1|grep -v "grep"|grep ora
 echo "##############################################" 
 exit 0 
else 
 echo '*******************************************'
 echo "Process has found, pid: $1  ,  addr: $sh_tmp_process    " 
 echo 
 echo "####### Process Information from OS level as below ########" 
 ps -ef|grep $1|grep -v grep|grep ora
 echo "##############################################" 
 sqlplus -s $DB_CONN_STR@$SH_DB_SID <<EOF
col machine format a20
col terminal format a15
col osuser format a15
col process format a15
col username format a15
set linesize 150
select sid,serial#,username,osuser ,machine,process,terminal,type,to_char(LOGON_TIME,'yyyy-mm-dd hh24:mi:ss')login_time from v\$session
where paddr='$sh_tmp_process';
prompt .
col sql_id format a30
col prev_sql_id format a30
col sql_text format a60
set linesize 150
set pages 50
select sql_id,sql_text from v\$sql where sql_id in (select sql_id from v\$session where paddr='$sh_tmp_process' and sql_id is not null  ) and rownum<2;
select sql_id prev_sql_id ,sql_text from v\$sql where sql_id in (select prev_sql_id sql_id from v\$session where paddr='$sh_tmp_process'  ) and rownum<2;
EOF
fi 
