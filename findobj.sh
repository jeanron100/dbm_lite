#!/bin/bash
obj_owner=`sqlplus -silent $DB_CONN_STR@$SH_DB_SID<<END
set head on
set pages 150
set linesize 150
col owner format a20
col object_name format a30
col object_Type format a20
select owner,object_name,object_type,status,to_char(created,'yyyy-mm-dd')create_date 
from dba_objects where owner=upper('$1') and object_name like '%'||upper('$2')||'%' 
group by  owner,object_name,object_type,status,to_char(created,'yyyy-mm-dd')
order by owner,object_type desc,owner asc; 
exit; 
END` 

if [ -z "$obj_owner" ]; then 
 exit 0 
else 
 echo '#################################'
 echo "$obj_owner" 
 echo '#################################'
fi 
