#!/bin/sh
set -e # Exit immediately if a command exits with a non-zero status.


INIT_SEM=/tmp/initialized.sem



fresh_container() {
  [ ! -f $INIT_SEM ]
}

app_present() {
  [ -f /app/config/database.php ]
}

vendor_present() {
  [ -f /app/vendor ]
}


install_laravel() {

   rm -rfv /tmp/laravel # just in case there is some files left

   su-exec alpine:alpine composer create-project --prefer-dist laravel/laravel /tmp/laravel

   rm /tmp/laravel/.env # preserving original .env

   echo "moving framework files to our working directory"
   for x in /tmp/laravel/* /tmp/laravel/.[!.]* /tmp/laravel/..?*; do
       if [ -e "$x" ]; then mv -fv -- "$x" /app/; fi
   done

   su-exec alpine:alpine composer require predis/predis
   su-exec alpine:alpine php artisan key:generate

   rm -rfv /tmp/laravel
}

wait_for_db() {
  local db_host="${DB_HOST:-mariadb}"
  local db_port="${DB_PORT:-3306}"
  local db_address=$(getent hosts "$db_host" | awk '{ print $1 }')
  counter=0
  echo "Connecting to mariadb at $db_address"
  while ! curl --silent "$db_address:$db_port" >/dev/null; do
    counter=$((counter+1))
    if [ $counter == 30 ]; then
      echo "Error: Couldn't connect to mariadb."
      exit 1
    fi
    echo "Trying to connect to mariadb at $db_address. Attempt $counter."
    sleep 5
  done
}

setup_db() {
  echo "Configuring the database"
  sed -i "s/utf8mb4/utf8/g" /app/config/database.php
  php artisan migrate --force
}


create_user() {

    if [[ -z "${UID}" ]]; then

        GID=1000
        UID=1000

        echo "Using default GID - $GID"
        echo "Using default UID - $UID"
    fi

    #user_exists=grep -c "^$UID:$GID:" /etc/passwd

    if ! grep "$UID:$GID" /etc/passwd &>/dev/null; then

        echo "user don't exist"

        echo "Creating group with id $GID"
        echo "Creating user with id $UID"

        addgroup -g $GID -S alpine && \
        adduser -u $UID -S alpine -G alpine --shell /bin/ash

        # fixing rights if user was changed, ignoring docker folder or we'll mess up our database
        find /app/ -type d ! -path '/app/docker*' -exec chown $UID:$GID {} +
        find /app/ -type f ! -path '/app/docker*' -exec chown $UID:$GID {} +
    fi


}

# not used as we're running php-fpm from root, natively stepped down to alpine
# left for historical purposes, might actually come handy someday
#   create_pipe_for_stderr() {
#       # Allow `alpine` user to write to /dev/stderr
#       # https://github.com/moby/moby/issues/6880
#       mkfifo -m 600 /tmp/logpipe
#       chown alpine:alpine /tmp/logpipe
#       cat <> /tmp/logpipe 1>&2 &
#   }

if [ "${1}" == "php-fpm" -a "$2" == "" ]; then

  create_user
 #create_pipe_for_stderr

  # if app doesn't exist - install fresh copy of laravel framework
  if  ! app_present ; then
    echo "Creating laravel application"
    install_laravel
  fi


  echo "Installing/Updating Laravel dependencies (composer)"
  if  ! vendor_present ; then
    su-exec alpine:alpine composer install
    echo "Dependencies installed"
  else
    su-exec alpine:alpine composer update
    echo "Dependencies updated"
  fi

   wait_for_db


   # this thing is actually a workaround for a problem with incompatibility of mysql and mariadb
   # https://github.com/laravel/framework/issues/17337
   if ! fresh_container; then
    echo "#########################################################################"
    echo "                                                                         "
    echo " App initialization skipped:                                             "
    echo " Delete the file $INIT_SEM and restart the container to reinitialize     "
    echo " You can alternatively run specific commands using docker-compose exec   "
    echo " e.g docker-compose exec myapp php artisan make:console FooCommand       "
    echo "                                                                         "
    echo "#########################################################################"
  else
    setup_db
    echo "Initialization finished"
    touch $INIT_SEM
  fi

fi

# idk if we're really need whole stepping down from root thingy anymore
# as php-fpm does that for us
#exec su-exec alpine:alpine tini -- "$@"
exec tini -- "$@"
