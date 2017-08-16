#!/bin/bash
TAB_OWNER=`sqlplus -silent $DB_CONN_STR@$SH_DB_SID <<END
set pagesize 40 feedback off verify off heading on echo off 
col owner_name format a20
col table_name format a30
select owner,object_name table_name from dba_objects where object_name=upper('$2') and owner=upper('$1') and object_type='TABLE'; 
exit; 
END` 

if [ -z "$TAB_OWNER" ]; then 
 echo "no object exists, please check again" 
 exit 0 
else 
 echo '*******************************************'
 echo " $TAB_OWNER    " 
 echo '*******************************************'
fi 


sqlplus -s $DB_CONN_STR@$SH_DB_SID <<EOF
set serveroutput on
set pages 1000 
set head on
set linesize 200
col table_name format a30
col partitoned format a10
col tablespace_name format a10
col status format a6
!echo '********** TABLE GENERAL INFO *****************';
select table_name,partitioned,tablespace_name,status,ini_trans,num_rows,blocks,empty_blocks,logging,monitoring,row_movement,last_analyzed from dba_tables where owner=upper('$1') and table_name=upper('$2');
!echo '********** TABLE STORAGE INFO *****************';
col initext format  99999999
col nxtext format 99999999
col minext format 999999999
col maxext format 9999999999
col compres format a10
select initial_extent initext,next_extent nxtext,min_extents minext,max_extents maxext,freelists,avg_space,chain_cnt,avg_row_len,cache,temporary,dependencies,compression compres from dba_tables where owner=upper('$1') and table_name=upper('$2'); 
!echo '********** TABLE columns INFO *****************';
col name format a20
set pages 1000
col table_name format a30 
col column_name format a30
col data_type format a15
col nullable format a10
col data_default format a20
SELECT  t1.column_id, 
        t1.COLUMN_NAME,  
        t1.DATA_TYPE  
        || DECODE (  
             t1.DATA_TYPE,  
              'NUMBER', DECODE (  
                              '('  
                           || NVL (TO_CHAR (t1.DATA_PRECISION), '*')  
                           || ','  
                           || NVL (TO_CHAR (t1.DATA_SCALE), '*')  
                           || ')',  
                           '(*,*)', NULL,  
                           '(*,0)', '(38)',  
                              '('  
                           || NVL (TO_CHAR (t1.DATA_PRECISION), '*')  
                           || ','  
                           || NVL (TO_CHAR (t1.DATA_SCALE), '*')  
                           || ')'),  
              'FLOAT', '(' || t1.DATA_PRECISION || ')',  
              'DATE', NULL,  
              'TIMESTAMP(6)', NULL,  
              '(' || t1.DATA_LENGTH || ')')  
           AS DATA_TYPE,  
        t1.DATA_LENGTH,  
        t1.NULLABLE ,
        t1.DATA_DEFAULT
   FROM dba_TAB_COLUMNS t1
where table_name=upper('$2')
      and owner=upper('$1')
order by t1.column_id;

!echo '********** CONSTRAINTS DETAILS INFO *****************';
col column_name format a20
col search_condition format a45
col constraint_name format a30
col r_owner format a10
col r_constraint_name format a15
col index_name format a30
select t2.column_name, t1.constraint_name,t1.constraint_type,t1.search_condition,t1.deferred,t1.deferrable,t1.rely,t1.index_name
from (select constraint_name,constraint_type,search_condition,deferred,deferrable,rely,index_name from dba_constraints
where table_name=upper('$2') and owner=upper('$1') ) t1,
(select constraint_name,column_name from dba_cons_columns where table_name=upper('$2') and owner=upper('$1') ) t2
where  t1.constraint_name=t2.constraint_name
;


!echo '********** INDEX DETAILS INFO *****************';
col column_list format a30
col index_name format a30
col index_type format a10
col table_type format a10
select ind.index_name,ind.tablespace_name,ind.index_type,ind.uniqueness,ind.partitioned,temp_cols.column_list,
ind.table_type,ind.status,ind.num_rows,ind.last_analyzed,ind.generated from 
(SELECT index_name, SUBSTR (MAX (SYS_CONNECT_BY_PATH (column_name, ',')), 2) column_list
FROM (SELECT /*+rule*/ index_name, column_name, rn, LEAD (rn) OVER (PARTITION BY index_name ORDER BY rn) rn1
         FROM (SELECT index_name, column_name, ROW_NUMBER () OVER (ORDER BY column_position desc) rn
                   FROM dba_ind_columns where table_name=upper('$2') and table_owner=upper('$1')))
START WITH rn1 IS NULL
CONNECT BY rn1 = PRIOR rn
GROUP BY index_name) temp_cols,dba_indexes ind
where ind.table_name=upper('$2') and ind.table_owner=upper('$1')
and ind.index_name=temp_cols.index_name
;

  select  t.table_name,i.index_name,
          i.clustering_factor,t.blocks,t.num_rows
     from dba_indexes i,dba_tables t
    where i.table_name=t.table_name
      and i.table_owner=t.owner
      and t.table_name = upper('$2')
      and t.owner=upper('$1')
    order by t.table_name,i.index_name;



!echo '********** ROLE GRANTS DETAILS INFO *****************';

col grantor format a15
col privilege format a15
col object_name format a30
col role_name format a20
select grantor,privilege,table_name object_name,grantee role_name,grantable,hierarchy 
from dba_tab_privs 
where  table_name=upper('$2') and owner=upper('$1') 
and grantee in (select role from dba_roles )
;



!echo '********** OBJECT GRANTS DETAILS INFO *****************';

select grantor,privilege,table_name object_name,grantee role_name,grantable,hierarchy 
from dba_tab_privs 
where table_name=upper('$2') and owner=upper('$1') 
and grantee in (select username from dba_users);


!echo '********** SYNONYMS DETAILS INFO *****************';
col db_link format a20
col owner format a20
col synonym_name format a30
col table_name format a30
col table_owner format a15
select owner,synonym_name,table_owner,table_name,db_link 
from dba_synonyms
 where table_name=upper('$2') and table_owner=upper('$1');
!echo '********** TRIGGER DETAIL INFO *****************';
col triggering_event format a20
col owner format a15
col trigger_name format a20
col trigger_type format a15
col base_object_type format a10
col status format a8
select owner,trigger_name,trigger_Type,triggering_event,base_object_Type,status,action_type 
from dba_triggers where  table_name=upper('$2') and owner=upper('$1'); 
EOF
exit
