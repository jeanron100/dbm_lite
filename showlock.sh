
#!/bin/bash
sqlplus -S $DB_CONN_STR@$SH_DB_SID <<EOF 
set linesize    160
set pages       100
set feedback    off
set verify      off

set echo on
col object_name format a25
col osuser format a10
col machine format a12
col program format a20
--col object_type format a10
col state format a10
col status format a10
col oracle_username format a12
col sid_serial format a12
col sec_wait format 99999999
col lock_type format a5
col mode_held format a10
set linesize 200
prompt Current Locks
prompt --------------

select ses.sid||','||ses.serial# sid_serial,loc.oracle_username,object_name,
--object_type,
ses.LOGON_TIME,ses.SECONDS_IN_WAIT sec_wait,ses.osuser,ses.machine,ses.program,ses.state,ses.status,
 decode(d.type,
                'MR', 'Media Recovery',
                'RT', 'Redo Thread',
                'UN', 'User Name',
                'TX', 'Transaction',
                'TM', 'DML',
                'UL', 'PL/SQL User Lock',
                'DX', 'Distrib Xaction',
                'CF', 'Control File',
                'IS', 'Instance State',
                'FS', 'File Set',
                'IR', 'Instance Recovery',
                'ST', 'Disk Space Transaction',
                'TS', 'Temp Segment',
                'IV', 'Library Cache Invalidation',
                'LS', 'Log Start or Switch',
                'RW', 'Row Wait',
                'SQ', 'Sequence Number',
                'TE', 'Extend Table',
                'TT', 'Temp Table',
                d.type) lock_type,
         decode(d.lmode,
                0, 'None',           /* Mon Lock equivalent */
                1, 'Null',           /* N */
                2, 'Row-S (SS)',     /* L */
                3, 'Row-X (SX)',     /* R */
                4, 'Share',          /* S */
                5, 'S/Row-X (SSX)',  /* C */
                6, 'Exclusive',      /* X */
                to_char(d.lmode)) mode_held
 from v\$locked_object loc,v\$session ses,dba_objects obj,v\$lock d
 where loc.object_id=obj.object_id 
      and loc.session_id=ses.sid
      and obj.object_id=d.id1
      and ses.sid=d.sid
      order by oracle_username,seconds_in_wait desc
;
set head off 
SELECT 'There are also '||count(*)||' transaction locks'
FROM v\$transaction_enqueue
;
prompt
prompt Blocking Session Details
-- select l1.sid, ' IS BLOCKING ', l2.sid
--from v\$lock l1, v\$lock l2
-- where l1.block =1 and l2.request > 0
-- and l1.id1=l2.id1
-- and l1.id2=l2.id2
--/
select  BLOCKING_SESSION  ||'    IS BLOCKING    '||sid||','||serial# from v\$session where blocking_session is not null;
exit
EOF

#set head off
#prompt
#prompt Waiting Sessions
#prompt -----------------


#SELECT  lh.sid     Locked_Sid,
#        lw.sid     Waiter_Sid,
#decode ( lh.type, 'MR', 'Media_recovery',
#                          'RT', 'Redo_thread',
#                          'UN', 'User_name',
#                          'TX', 'Transaction',
#                          'TM', 'Dml',
#                          'UL', 'PLSQL User_lock',
#                          'DX', 'Distrted_Transaxion',
#                          'CF', 'Control_file',
#                          'IS', 'Instance_state',
#                          'FS', 'File_set',
#                          'IR', 'Instance_recovery',
#                          'ST', 'Diskspace Transaction',
#                          'IV', 'Libcache_invalidation',
#                          'LS', 'LogStaartORswitch',
#                          'RW', 'Row_wait',
#                          'SQ', 'Sequence_no',
#                          'TE', 'Extend_table',
#                          'TT', 'Temp_table',
#                          'TO', 'Temporary Objects',
#                                'Nothing-' ) Waiter_Lock_Type,
#        decode ( lw.request, 0, 'None',
#                             1, 'NoLock',
#                             2, 'Row-Share',
#                             3, 'Row-Exclusive',
#                             4, 'Share-Table',
#                             5, 'Share-Row-Exclusive',
#                             6, 'Exclusive',
#                                'Nothing-' ) Waiter_Mode_Req,
#        sysdate Lock_Time
#FROM v\$lock lw, v\$lock lh
#WHERE lh.id1=lw.id1
#  AND lh.id2=lw.id2
#  AND lh.request=0
#  AND lw.lmode=0
#  AND (lh.id1,lh.id2) in ( 
#           SELECT id1,id2 FROM v\$lock WHERE request=0 
#                INTERSECT
#           SELECT id1,id2 FROM v\$lock WHERE lmode=0 )
#;

