
#!/bin/bash
issue_program1="sum(decode(program,'JDBC Thin Client',cnt,0))"
issue_program2="sum(decode(substr(program,1,11),'application1',cnt,0))"
issue_program3="sum(decode(substr(program,1,11),'application2',cnt,0))"
sqlplus -s $DB_CONN_STR@$SH_DB_SID <<EOF
set feed off
set verify off
set line 132
set pages 200

col username format a15
col sql_id format a20
col sql_address format a20
col machine format a30
col osuser format a15
col logon_time format a10
col program format a35
break on report
compute sum of  cnt  on report
select status,count(*) cnt from v\$session group by status;
prompt .

select program,cnt,status from (select program,count(*) cnt,status from v\$session group by program,status order by cnt desc) where rownum<10;

prompt .
  select username,
      sum(cnt) total_cnt,
      sum(decode(status,'ACTIVE', cnt,0)) ACTIVE,
      sum(decode(status,'INACTIVE', cnt,0)) INACTIVE,
      sum(decode(status,'KILLED', cnt,0)) KILLED,
      sum(decode(status,'SNIPED', cnt,0)) SNIPED,
     $issue_program1 "JDBC Thin Client",
     $issue_program2  "application1",
     $issue_program3  "application2"
     from (select program,username,status,count(*) cnt from V\$SESSION   group by program,username,status  ) 
    group by username having sum(cnt)>50 order by total_cnt desc;

EOF
exit
