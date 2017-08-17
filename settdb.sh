#!/bin/bash
tmp_username=$SH_USERNAME
tmp_password=$SH_PASSWORD
tmp_db_sid=$SH_DB_SID

#check $1 and $2 should be mandatory from input
if [[ -z $1 ]] || [[ -z $2 ]]; then
echo '***********************************************'
echo 'WARNING :UserName And PassWord Is Needed!'
echo '***********************************************'

exit
fi
if [[ -z $3 ]] && [[ -z $ORACLE_SID ]];then
echo '***********************************************'
echo 'WARNING :There is Instance can be used !'
echo '***********************************************'
exit
fi

SH_USERNAME=`echo "$1"|tr '[a-z]' '[A-Z]'`
SH_PASSWORD=$2
echo '***********************************************'

if [[  -z $3 ]]
then
   SH_DB_SID=$ORACLE_SID
   echo 'Using Default Instance :'$ORACLE_SID
   echo .
else
   SH_DB_SID=`echo "$3"|tr '[a-z]' '[A-Z]'`
fi

if [[  $SH_DB_SID = $tmp_db_sid ]] && [[ $SH_USERNAME = $tmp_username ]] &&  [[ $SH_PASSWORD = $tmp_password ]];then
   echo 'Instance '$SH_DB_SID 'has been connected'
   echo '***********************************************'
   exit
fi

export SH_USERNAME=$SH_USERNAME
export SH_DB_SID=$SH_DB_SID
export SH_PASSWORD=$SH_PASSWORD
export DB_CONN_STR=$SH_USERNAME/$SH_PASSWORD
#echo $DB_CONN_STR
listfile=`pwd`/listdb
Num=`echo show user | $ORACLE_HOME/bin/sqlplus -s $DB_CONN_STR@$SH_DB_SID| grep -i 'USER ' | wc -l`
if [ $Num -gt 0 ]
        then
                ## ok - instance is up
               echo 'Instance '$SH_DB_SID 'has been connected'
               echo -e '--' `date`'-- \n--'$SH_USERNAME@$SH_DB_SID 'has been connected --\n' >> listdb
               echo '***********************************************'
        cat icon.lst
        $SHELL
             
        else
                ## inst is inaccessible 
                echo Instance: $SH_DB_SID Is Invalid Or UserName/PassWord Is Wrong  
                echo '***********************************************'
        exit
        fi
del_length=3
tmp_txt=$(sed -n '$=' listdb) 
echo '***********************************************'
echo '********* ' $SH_USERNAME'@'$SH_DB_SID '**********'
echo '***********************************************'
curr_len=`cat $listfile|wc -l`
if [ $curr_len -gt $del_length ]; then
echo ' There Are Below Sessions Still Alive '
echo '***********************************************'
fi
sed $((${tmp_txt}-${del_length}+1)),${tmp_txt}d $listfile | tee  tmp_listfile
mv tmp_listfile $listfile
