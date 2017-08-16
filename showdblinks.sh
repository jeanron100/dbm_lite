
sqlplus -s $DB_CONN_STR@$SH_DB_SID <<EOF
set lines 152
col DB_LINK format a30 heading "Link Name"
col OWNER format a25 heading "Owned by ..."
col USERNAME format a25 heading "Connect to..."
col HOST format a25 heading "Located in ..." 

select replace(DB_LINK,'.WORLD','') AS DB_LINK,OWNER,USERNAME,HOST
  from dba_db_links;
EOF
