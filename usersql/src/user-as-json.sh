#!/bin/bash

#check for the config
if [ ! -f /opt/usersql/etc/config ]; then
    echo "Config missing!"
    exit 1
fi


#loads the config
source config


#establishes the paramenter
options=$(getopt -o p --long user: -- "$@")
[ $? -eq 0 ] || { 
   echo "Incorrect options provided"
   exit 1
}

eval set -- "$options"
while true; do
    case "$1" in
    --user)
        shift
        EMAIL=$1
        ;;
    --) 
        shift
        break
        ;;
    esac
    shift
done


#if no parameter provided...
if [ -z $EMAIL ]; then
  psql -tc "SELECT email_adress FROM users" | tr -d ' '| jq -R -s 'split("\n")[:-2]'
#if a parameter was provided...
else
  #if the email provided matches one in the table... (then list info)
  if ( psql -c "SELECT email_adress FROM users" | grep -w $EMAIL ); then

       psql -c "\copy (SELECT * FROM users WHERE email_adress = '$EMAIL') to /tmp/usert.csv csv header" >&-
	     mlr --c2j --jlistwrap cat /tmp/usert.csv
  
       A=`mlr --c2j --jlistwrap cat /tmp/usert.csv | jq '.[0]' | jq '.id'`

       psql -c "\copy (SELECT * FROM user_preferences WHERE user_id = '$A') to '/tmp/usert.csv' csv header" >&-
       mlr --c2j --jlistwrap cat /tmp/usert.csv

       psql -c "\copy (SELECT * FROM tasks WHERE user_id = '$A') to '/tmp/usert.csv' csv header" >&-
	     mlr --c2j --jlistwrap cat /tmp/usert.csv

       rm /tmp/usert.csv
   #if the email provided is not a match
	 else
       echo "No such email in the table."
	 fi
fi
exit 0;

