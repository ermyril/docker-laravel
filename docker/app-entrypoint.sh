#!/bin/sh -e

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

   composer create-project --prefer-dist laravel/laravel /tmp/laravel

   # moving framework to our working directory
   for x in /tmp/laravel/* /tmp/laravel/.[!.]* /tmp/laravel/..?*; do
       if [ -e "$x" ]; then mv -- "$x" /app/; fi
   done

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


if [ "${1}" == "php" -a "$2" == "artisan" -a "$3" == "serve" ]; then

  # if app doesn't exist - install fresh copy of laravel framework
  if  ! app_present ; then
    echo "Creating laravel application"
    install_laravel
  fi


  echo "Installing/Updating Laravel dependencies (composer)"
  if  ! vendor_present ; then
    composer install
    echo "Dependencies installed"
  else
    composer update
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


exec tini -- "$@"
