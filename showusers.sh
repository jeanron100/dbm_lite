#*********************************************************
# This script is used to show all users with default and temporary tablespace,created date and size
#
# USAGE : showusers
#
#*********************************************************

echo "set pages 70 lines 99 feedback off
col DEFAULT_TABLESPACE head 'Default TBS' for a15 trunc
col TEMPORARY_TABLESPACE head 'TEMP TBS' for a15 trunc
col MB head 'Size (Mb)' for 999,999,999
col username format a30
set linesize 150

break on report
compute sum of MB on report

select 
		USERNAME,
		DEFAULT_TABLESPACE,
		TEMPORARY_TABLESPACE,
		CREATED,
		nvl(sum(seg.blocks*ts.blocksize)/1024/1024,0) MB
from 
		sys.ts$ ts,
		sys.seg$ seg,
		sys.user$ us,
		dba_users du
where
			  us.name (+)= du.username
	 	and	  seg.user# (+)= us.user# 
		and       ts.ts# (+)= seg.ts#
group by USERNAME,DEFAULT_TABLESPACE,TEMPORARY_TABLESPACE,CREATED
order by MB desc,username,created
/
" | sqlplus -s  $DB_CONN_STR@$SH_DB_SID


