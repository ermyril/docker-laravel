#!/bin/sh

# current script directory
DIR=$(dirname "$(readlink -f "$0")")

# get value of specific parameter from .env file
getenv(){
    param=$1
    echo $(cat .env | grep -m 1 -Ei $param | awk -F '=' '{print $2}')
}

getcontainerid(){
    container=$1 # db or app
    echo $(docker ps | grep $( echo $DIR | awk -F \/ '{print $NF}' | sed 's/\.//g')_$container | awk '{print $1}')
}



##mysqldump -u $(getenv db_username) \
##    -p$(getenv db_password) \
##    $(getenv db_database) \
##    -r $(getenv app_name)$(date +'_%d-%m-%Y.sql')

# docker exec $(getcontainerid db) mysqldump -u $(getenv db_username) \
#     -p$(getenv db_password) \
#     $(getenv db_database) > $DIR/database/backups/$(getenv app_name)$(date +'_%d-%m-%Y.sql')

## get containerid for a current project
# docker ps | grep $(echo $DIR | awk -F \/ '{print $NF}' | sed 's/\.//g')_db | awk '{print $1}'

# restore backup to the container
# cat dump.sql | docker exec -i $(getcontainerid db) mysql -u $(getenv db_username) -p$(getenv db_password) $(getenv db_database)


# apply migrations
#docker exec -i $(getcontainerid app) php artisan migrate

