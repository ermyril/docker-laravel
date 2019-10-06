FROM php:7.3-fpm-alpine

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
#RUN addgroup -S alpine && adduser -S -G alpine alpine

#ARG uid=1000
#ARG gid=1000

#RUN addgroup -g $gid -S alpine
#RUN adduser  -u $uid -S alpine -G alpine

RUN apk update

# Basic packages - php and all the nessessary stuff
RUN set -ex && \
    apk add --no-cache freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev \
    libwebp-dev \
    libxpm-dev \
    zlib-dev \
    openssl \
    libzip-dev \
    zip \
    unzip \
    git  \
    && docker-php-ext-configure gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure zip \
        --with-zlib-dir=/usr/ \
    && docker-php-ext-install gd zip pdo pdo_mysql mbstring
   # && apk del --no-cache freetype-dev libpng-dev libjpeg-turbo-dev
   #


#RUN apk add --no-cache tini # tiny init for containers
# RUN apk add --no-cache busybox-suid # fixing su in busybox - well, we don't really need it, right?

RUN apk add --no-cache \
# grab su-exec for easy step-down from root
	    'su-exec>=0.2' \
# tiny init for containers
	    tini

# project dependencies



## INSTALL COMPOSER

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


## CONFIGURING LOCALES
# https://gist.github.com/Herz3h/0ffc2198cb63949a20ef61c1d2086cc0
# Install language pack
RUN apk --no-cache add ca-certificates wget && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-2.25-r0.apk && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-bin-2.25-r0.apk && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-i18n-2.25-r0.apk && \
    apk add glibc-bin-2.25-r0.apk glibc-i18n-2.25-r0.apk glibc-2.25-r0.apk

# Iterate through all locale and install it
# Note that locale -a is not available in alpine linux, use `/usr/glibc-compat/bin/locale -a` instead
COPY ./locale.md /locale.md
RUN cat /locale.md | xargs -i /usr/glibc-compat/bin/localedef -i {} -f UTF-8 {}.UTF-8

# Set the lang, you can also specify it as as environment variable through docker-compose.yml
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8




# Configs

COPY ./config/php.ini /usr/local/etc/php/php.ini
COPY ./config/www.conf /usr/local/etc/php-fpm.d/www.conf



COPY app-entrypoint.sh /app-entrypoint.sh

#RUN addgroup -g 1000 -S alpine
#RUN adduser  -u 1000 -S alpine -G alpine

RUN mkdir /app
#RUN chown alpine:alpine /app
WORKDIR /app

#USER alpine

#COPY . /app
#RUN composer install


ENTRYPOINT [ "/app-entrypoint.sh" ]
#CMD [ "php", "artisan", "serve", "--host=0.0.0.0", "--port=8000" ]
CMD ["php-fpm"]
EXPOSE 8000 9000





