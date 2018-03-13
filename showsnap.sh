#!/bin/bash

sqlplus -s $DB_CONN_STR@$SH_DB_SID <<EOF
break on db_name
set pages 50
set linesize 100
col snapdate format a20
prompt
prompt Current Instance
prompt ~~~~~~~~~~~~~~~~
select d.dbid            dbid
     , d.name            db_name
     , i.instance_number inst_num
     , i.instance_name   inst_name
  from v\$database d,
       v\$instance i;
select 
db_name
,begin_snap
,end_snap
,snapdate
,lvl
,round(((END_INTERVAL_TIME+0)-(BEGIN_INTERVAL_TIME+0 ))*24*60) duration_mins
,round((select round((sum(e.value) -
                        sum(b.value)) / 1000000 /60,2) dbtime
                        FROM DBA_HIST_SYS_TIME_MODEL e, DBA_HIST_SYS_TIME_MODEL b
                        WHERE
                         e.STAT_NAME = 'DB time'
                         and b.snap_id=begin_snap
                        and e.snap_id =end_snap
                        AND b.STAT_NAME = 'DB time'
                        group by e.snap_id,b.snap_id)) dbtime
from
(       
select 
      di.db_name                                        db_name
     , s.snap_id                                         begin_snap
     ,lead(s.snap_id ,1,s.snap_id ) over(order by s.end_interval_time ) end_snap
     , to_char(s.end_interval_time,'dd Mon YYYY HH24:mi') snapdate
     , s.snap_level                                      lvl     
     ,s.end_interval_time
     ,s.begin_interval_time
  from dba_hist_snapshot s
     , dba_hist_database_instance di
 where 
  ( di.dbid,di.instance_number) in
 (select d.dbid            dbid
     , i.instance_number inst_num
  from v\$database d,
       v\$instance i)
   and di.dbid             = s.dbid
   and di.instance_number  = s.instance_number
   and di.startup_time     = s.startup_time
   and to_char(END_INTERVAL_TIME,'yyyymmdd')='$1'
   and EXTRACT(HOUR FROM END_INTERVAL_TIME) between $2-1 and $3+1 
 order by db_name, instance_name, snap_id
 );  
EOF
