tab_owner=`sqlplus -silent $DB_CONN_STR@$SH_DB_SID<<END
set head on
set pages 80
set linesize 150
col PROFILE  format a30
col RESOURCE_NAME format a30
col RESOURCE_TYPE format a30
col LIMIT format a30
break on owner
select * from dba_profiles where profile in (select profile from dba_users where username=upper('$1'));
exit; 
END` 

if [ -z "$tab_owner" ]; then 
 exit 0 
else 
 echo '#################################'
 echo "$tab_owner" 
 echo
fi
