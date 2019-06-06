#!/bin/sh

COMMAND=$1

if [ ! $COMMAND ] || [ $COMMAND = 'help' ] || [ $COMMAND = '--help' ]; then
    echo '
Laravel docker helper tool

Commands:

backup      - creates a backup for a current date (in a database/backup directory
restore     - prints list of an available database backups and restores selected backup
post-deploy - executes a bunch of commands in a container ( migrate, config:clear, etc. edit scripts.sh file to add your custom commands there )

          '
fi

# current script directory
DIR=$(dirname "$(readlink -f "$0")")

## get value of specific parameter from .env file
getenv(){
    param=$1
    echo $(cat .env | grep -m 1 -Ei $param | awk -F '=' '{print $2}')
}

## get containerid for a current project
getcontainerid(){
    container=$1 # db or app
    echo $(docker ps | grep $( echo $DIR | awk -F \/ '{print $NF}' | sed 's/\.//g')_$container | awk '{print $1}')
}



## creating backup
if [[ $COMMAND = 'backup' ]]; then

    if [[ ! -f $DIR/database/backup ]]; then
        mkdir -p $DIR/database/backup
    fi

    docker exec $(getcontainerid db) mysqldump -u $(getenv db_username) \
         -p$(getenv db_password) \
         $(getenv db_database) > $DIR/database/backup/$(getenv app_name)$(date +'_%d-%m-%Y.sql')
fi


# restore backup to the container
if [[ $COMMAND = 'restore' ]]; then

    select dump in $DIR/database/backup/*; do
         test -n "$dump" && break;
         echo ">>> Invalid Selection";
    done

    cat $dump | docker exec -i $(getcontainerid db) mysql -u $(getenv db_username) -p$(getenv db_password) $(getenv db_database)

fi


# execute following commands in the container
# this is used for applying migrations after deployment
if [[ $COMMAND = 'post-deploy' ]]; then

    # add your custom commands
    docker exec -i $(getcontainerid app) php artisan config:clear
    docker exec -i $(getcontainerid app) php artisan cache:clear
    docker exec -i $(getcontainerid app) php artisan view:clear
    docker exec -i $(getcontainerid app) php artisan migrate

fi



##mysqldump -u $(getenv db_username) \
##    -p$(getenv db_password) \
##    $(getenv db_database) \
##    -r $(getenv app_name)$(date +'_%d-%m-%Y.sql')




