
sqlplus -s $DB_CONN_STR@$SH_DB_SID <<EOF

set linesize    150
set pages       100
set feedback    off
set verify      off

col dbname      new_value dbname
col time_stamp  new_value time_stamp
col timestamp_np        noprint
col year_np             noprint
col month_np            noprint
col mon                 for a3
col day                 for a2

ttitle off
SELECT name dbname, substr(to_char(sysdate,'YYYY-Mon-DD HH24:MI:SS'),1,20)
       time_stamp
FROM v\$database
/

col bytes format 9,999,999,999,999
col member format a60

select group#,thread#,sequence#,members,bytes/1024/1024 size_MB,archived,status
from v\$log order by 1,2;

ttitle left "Redo Switch times per hour" center "&dbname" right "&time_stamp" 
set term on
col tps00 for 999 head "00"
col tps01 for 999 head "01"
col tps02 for 999 head "02"
col tps03 for 999 head "03"
col tps04 for 999 head "04"
col tps05 for 999 head "05"
col tps06 for 999 head "06"
col tps07 for 999 head "07"
col tps08 for 999 head "08"
col tps09 for 999 head "09"
col tps10 for 999 head "10"
col tps11 for 999 head "11"
col tps12 for 999 head "12"
col tps13 for 999 head "13"
col tps14 for 999 head "14"
col tps15 for 999 head "15"
col tps16 for 999 head "16"
col tps17 for 999 head "17"
col tps18 for 999 head "18"
col tps19 for 999 head "19"
col tps20 for 999 head "20"
col tps21 for 999 head "21"
col tps22 for 999 head "22"
col tps23 for 999 head "23"

SELECT *
FROM
( SELECT substr(year_np,1,8)  timestamp_np,
       substr(year_np,5,2) Mon, substr(year_np,7,2) Day,
       sum(decode(substr(year_np,9,2),'00',cnt,0))   tps00,
       sum(decode(substr(year_np,9,2),'01',cnt,0))   tps01,
       sum(decode(substr(year_np,9,2),'02',cnt,0))   tps02,
       sum(decode(substr(year_np,9,2),'03',cnt,0))   tps03,
       sum(decode(substr(year_np,9,2),'04',cnt,0))   tps04,
       sum(decode(substr(year_np,9,2),'05',cnt,0))   tps05,
       sum(decode(substr(year_np,9,2),'06',cnt,0))   tps06,
       sum(decode(substr(year_np,9,2),'07',cnt,0))   tps07,
       sum(decode(substr(year_np,9,2),'08',cnt,0))   tps08,
       sum(decode(substr(year_np,9,2),'09',cnt,0))   tps09,
       sum(decode(substr(year_np,9,2),'10',cnt,0))   tps10,
       sum(decode(substr(year_np,9,2),'11',cnt,0))   tps11,
       sum(decode(substr(year_np,9,2),'12',cnt,0))   tps12,
       sum(decode(substr(year_np,9,2),'13',cnt,0))   tps13,
       sum(decode(substr(year_np,9,2),'14',cnt,0))   tps14,
       sum(decode(substr(year_np,9,2),'15',cnt,0))   tps15,
       sum(decode(substr(year_np,9,2),'16',cnt,0))   tps16,
       sum(decode(substr(year_np,9,2),'17',cnt,0))   tps17,
       sum(decode(substr(year_np,9,2),'18',cnt,0))   tps18,
       sum(decode(substr(year_np,9,2),'19',cnt,0))   tps19,
       sum(decode(substr(year_np,9,2),'20',cnt,0))   tps20,
       sum(decode(substr(year_np,9,3),'21',cnt,0))   tps21,
       sum(decode(substr(year_np,9,3),'22',cnt,0))   tps22,
       sum(decode(substr(year_np,9,2),'23',cnt,0))   tps23
  FROM (SELECT to_char(first_time,'YYYYMMDDHH24') year_np,count(*) cnt
        FROM v\$log_history where first_time>sysdate -15
        GROUP BY to_char(first_time,'YYYYMMDDHH24')
       )      
  GROUP BY substr(year_np,1,8), substr(year_np,5,2), substr(year_np,7,2)
)
ORDER BY timestamp_np
/
EOF
exit;
