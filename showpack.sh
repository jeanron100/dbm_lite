#!/bin/bash

PROC_OWNER=`sqlplus -silent $DB_CONN_STR@$SH_DB_SID <<END 
set pagesize 40 feedback off verify off heading on echo off
col owner format a20
col object_name format a30
col subobject_name format a10
set linesize 150
break on object_name
select object_name,owner,subobject_name,object_type,object_id, created,last_ddl_time,status from dba_objects where object_type like 'PACKAGE%' and object_name=upper('$2') and owner=upper('$1')
ORDER BY OBJECT_ID
/
exit;
END`

if [ -z "$PROC_OWNER" ]; then
 echo "no object exists, please check again"
 exit 0
else
 echo '*******************************************'
 echo " $PROC_OWNER    "
 echo '*******************************************'
fi


sqlplus -silent $DB_CONN_STR@$SH_DB_SID <<EOF
prompt .
desc $1.$2
prompt .
set long 99999
set pages 0
col text format a150
select text
from dba_source 
where type in ('PACKAGE BODY','PACKAGE') and name=upper('$2') and owner=upper('$1')
order by type, line;



EOF
exit
