#!/bin/bash
VIEW_OWNER=`sqlplus -silent $DB_CONN_STR@$SH_DB_SID <<END
set pagesize 50 feedback off verify off heading on echo off
col owner format a20
col mview_name format a30
set linesize 150
select owner, mview_name,query_len,updatable,rewrite_enabled,refresh_mode,refresh_method,build_mode,last_refresh_type,
last_refresh_date,compile_state
  from dba_mviews 
  where mview_name like upper('%'||'$2'||'%') and owner=upper('$1') ;
exit;
END`

if [ -z "$VIEW_OWNER" ]; then
 echo "no object exists, please check again"
 exit 0
else
 echo '*******************************************'
 echo " $VIEW_OWNER    "
 echo '*******************************************'
fi
