#!/bin/bash

obj_owner=`sqlplus -silent $DB_CONN_STR@$SH_DB_SID<<END
set head on
set pages 150
set linesize 150
col owner format a20
col object_name format a30
col object_Type format a15
select owner,object_name,object_type,status,to_char(created,'yyyy-mm-dd')create_date 
from dba_objects where object_id=dbms_rowid.ROWID_OBJECT('$1')
group by  owner,object_name,object_type,status,to_char(created,'yyyy-mm-dd');
exit; 
END` 

if [ -z "$obj_owner" ]; then 
 exit 0 
else 
 echo '#################################'
 echo "$obj_owner" 
 echo '#################################'
fi 

sqlplus -silent $DB_CONN_STR@$SH_DB_SID<<EOF
select dbms_rowid.ROWID_OBJECT('$1') object_id,
dbms_rowid.ROWID_RELATIVE_FNO('$1') file_no,
dbms_rowid.rowid_row_number('$1') row_no,
dbms_rowid.rowid_block_number('$1') blk_number
from dual;
prompt #################################
EOF
exit
