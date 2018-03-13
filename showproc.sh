#!/bin/bash

PROC_OWNER=`sqlplus -silent $DB_CONN_STR@$SH_DB_SID <<END
set pagesize 40 feedback off verify off heading on echo off
col owner format a20
col object_name format a30
set linesize 150
select owner, object_name,object_id,object_type,aggregate,pipelined,parallel,interface,deterministic,authid from dba_procedures
where owner=upper('$1')   and  object_type='PROCEDURE' and object_name like '%'||upper('$2')||'%'
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
set long 99999
set pages 0
select text
from dba_source 
where type='PROCEDURE' and name=upper('$2') and owner=upper('$1')
order by line;



EOF
exit
