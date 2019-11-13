#!/bin/sh
set -e # Exit immediately if a command exits with a non-zero status.


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
        # this shit is just choking on bitrix, perform it manually if necessary
       #find /app/ -type d ! -path '/app/docker*' -exec chown $UID:$GID {} +
       #find /app/ -type f ! -path '/app/docker*' -exec chown $UID:$GID {} +
    fi


}


if [ "${1}" == "php-fpm" -a "$2" == "" ]; then
  create_user
fi

# idk if we're really need whole stepping down from root thingy anymore
# as php-fpm does that for us
#exec su-exec alpine:alpine tini -- "$@"
exec tini -- "$@"
