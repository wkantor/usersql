#!/bin/bash

#check if config exists
if [ ! -f /opt/usersql/etc/config ]; then
    echo "Config missing!"
    exit 1
fi




source /opt/usersql/etc/config

#checks if the database exists. if not, creates it.
psql -tc "SELECT 1 FROM pg_database WHERE datname = '$MYDB'" | grep -q 1 || psql -c "CREATE DATABASE $MYDB" >&-

#checks for the tables, if they don't exist, creates them
psql -c "CREATE TABLE IF NOT EXISTS users (id serial PRIMARY KEY, first_name VARCHAR (50) NOT NULL, last_name VARCHAR (50) NOT NULL, email_adress VARCHAR (250) NOT NULL, active bool NOT NULL);
CREATE TABLE IF NOT EXISTS user_preferences (id serial PRIMARY KEY, user_id integer NOT NULL, key TEXT NOT NULL, value integer NOT NULL); 
CREATE TABLE IF NOT EXISTS tasks (id serial PRIMARY KEY, user_id integer NOT NULL, task text NOT NULL)" >&-

#checks for data_users
if [ ! -f "/opt/usersql/data_users.csv" ]; then
       echo "Data_users.csv is missing from set directory!"
#fills in the data
else
       psql -c "\copy users (first_name, last_name, email_adress, active) FROM '/opt/usersql/data_users.csv' DELIMITER ',' CSV HEADER;" >&-
fi

#checks for data_tasks
if [ ! -f "/opt/usersql/data_tasks.csv" ]; then
       echo "Data_tasks.csv is missing from set directory!"
#fills in the data
else
       psql -c "\copy user_preferences (user_id, key, value) FROM '/opt/usersql/data_user_preferences.csv' DELIMITER ',' CSV HEADER;" >&-
fi

#checks for data_user_preferences
if [ ! -f "/opt/usersql/data_user_preferences.csv" ]; then
       echo "Data_user_preferences.csv is missing from set directory!"
#fills in the data
else
       psql -c "\copy tasks (user_id, task) FROM '/opt/usersql/data_tasks.csv' DELIMITER ',' CSV HEADER;" >&-
fi



options=$(getopt -o p --long addtextexternalidfromfile: -- "$@")
[ $? -eq 0 ] || {
    echo "Incorrect options provided"
    exit 1
}

eval set -- "$options"
while true; do
    case "$1" in
    --addtextexternalidfromfile)
        shift
        DATA=$1
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

if [ -z $DATA ]; then
  exit 0
else
  WTD= cat $DATA | sed 's/://g' tst| mlr --x2c cut -f uid  | grep -v 'uid' > /tmp/wtd
  psql -c "ALTER TABLE users ADD COLUMN IF NOT EXISTS external_id text" >&-
  psql -c "CREATE TABLE tmp (id serial PRIMARY KEY, external text);" >&-
  psql -c "\copy tmp (external) FROM /tmp/wtd DELIMITER ',' " >&-
  psql -c "UPDATE users SET external_id = tmp.external FROM tmp WHERE users.id = tmp.id" >&-
  psql -c "DROP TABLE tmp" >&-
fi
exit 0


