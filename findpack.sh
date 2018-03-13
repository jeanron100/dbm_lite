#!/bin/bash

PROC_OWNER=`sqlplus -silent $DB_CONN_STR@$SH_DB_SID <<END 
set pagesize 50 feedback off verify off heading on echo off
col owner format a20
col object_name format a30
col subobject_name format a10
set linesize 150
break on object_name
select object_name,owner,subobject_name,object_type,object_id, created,last_ddl_time,status 
from dba_objects where object_type like 'PACKAGE%' and object_name like upper('$2%') and owner=upper('$1')
order by object_name
/
exit;
END`

if [ -z "$PROC_OWNER" ]; then
 echo "no object exists, please check again"
 exit 0
else
 echo '*******************************************'
 echo " $PROC_OWNER    "
 
 PACK_LIST=` sqlplus -s  $DB_CONN_STR@$SH_DB_SID <<END
 col name format a30 
 col text format a100 
 set linesize 200
 set pages 50
 break on name
 select name,text  from dba_source where owner like UPPER('$1') and name like upper('$2%') and type='PACKAGE'
 and (text like '%PROCEDURE %' or text like '%FUNCTION %' )
 order by name,line;

 exit;
 END`
 echo "  $PACK_LIST    "
echo '*******************************************'
fi


exit
