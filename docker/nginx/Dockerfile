FROM nginx:stable-alpine


# Configs

COPY ./config/default.conf /etc/nginx/conf.d/default.conf

RUN mkdir /app
#RUN chown alpine:alpine /app
WORKDIR /app

EXPOSE 80 443
