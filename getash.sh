#!/bin/bash

sqlplus -silent $DB_CONN_STR@$SH_DB_SID<<EOF
set lin 200
set pages 50
col SID         for 99999 trunc
col running_sec for a11 head "ELAP_SEC"
col inst_id     for 9 trunc head "I"
col serial#     for 99999 trunc     head SER#
col username    for a12 trunc       head "USERNAME"
col osuser      for a10 trunc       head "OSUSER"
col status      for a3 trunc            head "STAT"
col machine     for a10 trunc
col process     for a7 trunc        head "RPID"
col spid        for a6 trunc        head "SPID"
col program     for a20 trunc
col module      for a13 trunc
col temp_mb     for 999999              head "TEMP_MB"
col undo_mb     for 999999              head "UNDO_MB"
col logon_time  for a11
col rm_grp      for a6 trunc
col sql_id      for a13
col sql         for a49 trunc
col tsps        for a6 trunc
SELECT /* use_hash(sess,proc,undo,tmp) use_nl(s)*/ distinct
        sess.inst_id,
        sess.sid,
        sess.serial#,
        sess.username,
        substr(osuser,1,10) osuser,
        status,
        sess.process,
        proc.spid,
        sess.machine,
        sess.program,
        regexp_substr(NUMTODSINTERVAL(nvl((SYSDATE-SQL_EXEC_START)*24*60*60,last_call_et), 'SECOND'),'+\d{2} \d{2}:\d{2}:\d{2}') running_sec,
        TEMP_MB, UNDO_MB,
        s.sql_id ,
        TSPS.NAME TSPS,
        decode(sess.action,null,'',sess.action||', ')||replace(s.sql_text,chr(13),' ') sql
FROM
        gv\$session sess,
        gv\$process proc,
        gv\$sql s,
        (select ses_addr as saddr,sum(used_ublk/128) UNDO_MB from v\$transaction group by ses_addr) undo,
        (select session_addr as saddr, SESSION_NUM serial#, sum((blocks/128)) TEMP_MB from gv\$sort_usage group by  session_addr, SESSION_NUM) tmp,
        (select inst_id,sid,serial#,event,t.name from gv\$session ls, sys.file$ f, sys.ts$ t where status='ACTIVE' and ls.p1text in ('file number','file#') and ls.p1=f.file#  and f.ts#=t.ts#) tsps
WHERE sess.inst_id=proc.inst_id (+)  
and   sess.saddr=tmp.saddr (+) and sess.serial#=tmp.serial# (+)
AND   sess.status='ACTIVE' and sess.username is not null
and   sess.sid=tsps.sid (+) and sess.inst_id=tsps.inst_id(+) and sess.serial#=tsps.serial#(+)
AND   sess.paddr=proc.addr (+)
and   sess.sql_id = s.sql_id (+)
and   sess.saddr=undo.saddr (+)
ORDER BY running_sec desc,4,1,2,3
;
EOF
