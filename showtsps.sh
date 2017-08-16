
#!/bin/bash
sqlplus -s $DB_CONN_STR@$SH_DB_SID  <<EOF
set echo off heading on underline on;
column inst_num  heading "Inst Num"  new_value inst_num  format 99999;
column inst_name heading "Instance"  new_value inst_name format a12;
column db_name   heading "DB Name"   new_value db_name   format a12;
column dbid      heading "DB Id"     new_value dbid      format 9999999999 just c;

prompt
prompt Current Instance
prompt ~~~~~~~~~~~~~~~~

select d.dbid            dbid
     , d.name            db_name
     , i.instance_number inst_num
     , i.instance_name   inst_name
  from v\$database d,
       v\$instance i;
       
set term on feedback off lines 130 pagesize 999 tab off trims on
column MB format 999,999,999  heading "Total MB"
column free format 9,999,999 heading "Free MB"
column used format 99,999,999 heading "Used MB"
column Largest format 999,999 heading "LrgstMB"
column tablespace_name format a20 heading "Tablespace"
column status format a3 truncated
column max_extents format 99999999999 heading "MaxExt"
col extent_management           for a1 trunc   head "M"
col allocation_type             for a1 trunc   head "A"
col Ext_Size for a4 trunc head "Init"
column pfree format a3 trunc heading "%Fr"

break on report
compute sum of MB on report
compute sum of free on report
compute sum of used on report

select  
  d.tablespace_name, 
  decode(d.status, 
    'ONLINE', 'OLN',
    'READ ONLY', 'R/O',
    d.status) status,
  d.extent_management, 
  decode(d.allocation_type,
    'USER','',
    d.allocation_type) allocation_type,
  (case 
    when initial_extent < 1048576 
    then lpad(round(initial_extent/1024,0),3)||'K' 
    else lpad(round(initial_extent/1024/1024,0),3)||'M' 
  end) Ext_Size,
  NVL (a.bytes / 1024 / 1024, 0) MB,
  NVL (f.bytes / 1024 / 1024, 0) free, 
  (NVL (a.bytes / 1024 / 1024, 0) - NVL (f.bytes / 1024 / 1024, 0)) used,
  NVL (l.large / 1024 / 1024, 0) largest, 
  d.MAX_EXTENTS ,
  lpad(round((f.bytes/a.bytes)*100,0),3) pfree,
  (case when round(f.bytes/a.bytes*100,0) >= 20 then ' ' else '*' end) alrt
FROM sys.dba_tablespaces d,
  (SELECT   tablespace_name, SUM(bytes) bytes
   FROM dba_data_files
   GROUP BY tablespace_name) a,
  (SELECT   tablespace_name, SUM(bytes) bytes
   FROM dba_free_space
   GROUP BY tablespace_name) f,
  (SELECT   tablespace_name, MAX(bytes) large
   FROM dba_free_space
   GROUP BY tablespace_name) l
WHERE d.tablespace_name = a.tablespace_name(+)
  AND d.tablespace_name = f.tablespace_name(+)
  AND d.tablespace_name = l.tablespace_name(+)
  AND NOT (d.extent_management LIKE 'LOCAL' AND d.contents LIKE 'TEMPORARY')
UNION ALL
select 
  d.tablespace_name, 
  decode(d.status, 
    'ONLINE', 'OLN',
    'READ ONLY', 'R/O',
    d.status) status,
  d.extent_management, 
  decode(d.allocation_type,
    'UNIFORM','U',
    'SYSTEM','A',
    'USER','',
    d.allocation_type) allocation_type,
  (case 
    when initial_extent < 1048576 
    then lpad(round(initial_extent/1024,0),3)||'K' 
    else lpad(round(initial_extent/1024/1024,0),3)||'M' 
  end) Ext_Size,
  NVL (a.bytes / 1024 / 1024, 0) MB,
  (NVL (a.bytes / 1024 / 1024, 0) - NVL (t.bytes / 1024 / 1024, 0)) free,
  NVL (t.bytes / 1024 / 1024, 0) used, 
  NVL (l.large / 1024 / 1024, 0) largest, 
  d.MAX_EXTENTS ,
  lpad(round(nvl(((a.bytes-t.bytes)/NVL(a.bytes,0))*100,100),0),3) pfree,
  (case when nvl(round(((a.bytes-t.bytes)/NVL(a.bytes,0))*100,0),100) >= 20 then ' ' else '*' end) alrt
FROM sys.dba_tablespaces d,
  (SELECT   tablespace_name, SUM(bytes) bytes
   FROM dba_temp_files
   GROUP BY tablespace_name order by tablespace_name) a,
  (SELECT   tablespace_name, SUM(bytes_used  ) bytes
   FROM v\$temp_extent_pool
   GROUP BY tablespace_name) t,
  (SELECT   tablespace_name, MAX(bytes_cached) large
   FROM v\$temp_extent_pool
   GROUP BY tablespace_name order by tablespace_name) l
WHERE d.tablespace_name = a.tablespace_name(+)
  AND d.tablespace_name = t.tablespace_name(+)
  AND d.tablespace_name = l.tablespace_name(+)
  AND d.extent_management LIKE 'LOCAL'
  AND d.contents LIKE 'TEMPORARY'
  ORDER by 1
/
prompt
exit
EOF
