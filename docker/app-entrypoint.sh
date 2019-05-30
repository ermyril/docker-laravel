#!/bin/sh -e

echo 'initialized'

# if app doesn't exist - install fresh copy of laravel framework

if [ ! -d "/app/app" ]; then

   echo 'Installing Laravel'

   rm -rfv /tmp/laravel # just in case

   composer create-project --prefer-dist laravel/laravel /tmp/laravel
   #mv {/tmp/laravel/*,/tmp/laravel/.*} /app/

   for x in /tmp/laravel/* /tmp/laravel/.[!.]* /tmp/laravel/..?*; do
       if [ -e "$x" ]; then mv -- "$x" /app/; fi
   done

   rm -rfv /tmp/laravel

fi


exec tini -- "$@"
