NAME=`echo $1|cut -d. -f1`
if [ -z "$NAME" ] 
then
  echo -e "User must be provided: \c"; read NAME
fi

sqlplus -s $DB_CONN_STR@$SH_DB_SID <<EOF
clear buffer
set feed off
set verify off
set line 132
set pages 200

column bytes format 9999,999,999,999 head "Bytes Used"
column max_bytes format 9,999,999,999 head Quota
column default_tablespace format a20 head "Default Tablespace"
column tablespace_name for a25 
column username format a25 

prompt ******************************************************************************************************
prompt *                                       General Details                                              *
prompt ******************************************************************************************************
col profile format a10
col password_versions format a10
select username, default_tablespace,  created ,profile, password_versions  
from dba_users 
 where  username=upper('${NAME}')
/

prompt.
prompt ******************************************************************************************************
prompt *                                      Objects General Info                                          *
prompt ******************************************************************************************************
select object_type,status,count(*) obj_count 
  from dba_objects
 where owner=upper('$1') group by object_type,status order by obj_count desc
/
prompt.
prompt ******************************************************************************************************
prompt *                                            Quotas                                                  *
prompt ******************************************************************************************************
select tablespace_name, 
       bytes, 
      decode( max_bytes,-1,'UNLIMITED',max_bytes) max_bytes
  from dba_ts_quotas where username=upper('${NAME}')
/
prompt.
prompt ******************************************************************************************************
prompt *                                          Bytes Used                                                               
prompt ******************************************************************************************************
col tablespace_name  for a15 trunc
col MB head 'Size (Mb)' for 999,999,999

break on report 
compute sum of bytes on REPORT
/*
select 
		ts.tablespace_name tablespace_name,
		nvl(sum(seg.blocks*ts.block_size)/1024/1024,0) MB
from 
		dba_tablespaces  ts,
		dba_segments seg,
		dba_users us
where
			--  du.username=upper('${NAME}') 
		us.username=upper('${NAME}') 	
	 	and	  seg.owner (+)= us.username 
		and       ts.tablespace_name (+)= seg.TABLESPACE_NAME
group by ts.tablespace_name
order by ts.tablespace_name
*/

select 
		ts.name tablespace_name,
		nvl(sum(seg.blocks*ts.blocksize)/1024/1024,0) MB
from 
		sys.ts$ ts,
		sys.seg$ seg,
		sys.user$ us,
		dba_users du
where
			  du.username=upper('${NAME}') 
		and	  us.name (+)= du.username
	 	and	  seg.user# (+)= us.user# 
		and       ts.ts# (+)= seg.ts#
group by ts.name
order by ts.name
/
prompt .
prompt ******************************************************************************************************
prompt *                                             Grants/Roles                                                 *
prompt ******************************************************************************************************
set feed off verify off line 132 pages 200

col owner format a15
break on owner
prompt ********* OWNER ROLE *********** 
prompt ********************************
select d.owner,d.grantee role_name,r.PASSWORD_REQUIRED,s.admin_option,s.DEFAULT_ROLE
from dba_tab_privs d,dba_roles r,dba_role_privs s
where
 d.grantee=r.role
and d.grantee=s.grantee(+)
and d.owner=nvl(upper('$1'),' ')
group by d.grantee,d.owner,r.password_required,s.admin_option,s.DEFAULT_ROLE
order by d.owner;
column grantee format a20
column granted_role format a35
column admin_option heading admin format a10

prompt .
prompt ********** GRANTED ROLE ********
prompt ********************************
select d.grantee role_name
from dba_tab_privs d
where   owner=upper('$1')
group by d.grantee
union
select granted_role
from dba_role_privs
 where grantee=upper('$1');
prompt .
prompt ******************************************************************************************************
prompt *                                         Sys privileges                                             *
prompt ******************************************************************************************************
set feed off verify off line 132 pages 200
column privilege format a25
column admin_option heading admin format a8

select privilege, 
       admin_option  
  from dba_sys_privs where grantee = upper('${NAME}')
/
!echo "******************************************************************************************************"
EOF
exit
