# Docker-Laravel
Laravel development container

It was heavily inspired by the similar project from [bitnami](https://github.com/bitnami/bitnami-docker-laravel)


To get it up and running:

### The simplest way - use a prebuilt image

```
$ mkdir ~/myapp && cd ~/myapp
$ curl -LO https://raw.githubusercontent.com/ermyril/docker-laravel/master/docker-compose.yml
$ docker-compose up
```


###  Advanced configuration - use this repo as a base to be able to customize your environment

Clone this repo

```
$ git clone https://github.com/ermyril/docker-laravel && cd docker-laravel
```

Uncomment build parameter in docker-compose.yml file

```
$ sed -i 's/#build/ build/' docker-compose.yml
```

Build an image and start containers
```
$ docker-compose build
$ docker-compose up
```


*Note that because of a database that being persisted via shared volumes, and which is not using rootless container - you'll get a permission denied error when trying to build container again, so you can remove database data ```rm -rf docker/data```, fix permissions on your local machine, or just build image from root ```sudo docker-compose build```*


**Also do not forget to add docker/data to .gitignore**

## Details

### Users
Application container starts its services from user with **UID - 1000** and **GID - 1000**, you can change them via docker-compose.yml by setting an environment variables.

```
version: '2'
services:
  app:
    ...
    environment:
      - ...
      - UID={your uid}
      - GID={your gid}
```

Or by adding them to .env file to be able to have cross-environment configuration, uncomment env_file parameter in docker-compose file for that
```
$ sed -i 's/#env_file/ env_file/' docker-compose.yml
```

**WARNING:** when you change UID/GID, container will run chown in a mounted /app/ directory, that is potentially dangerous, so be aware of it please.

### ldht.sh - laravel docker helper tool
It is a simple script with a few nice (in my opinion) helpers that make routine operations ( such as backing up/restoring ) easier.


```
$ bash ldht.sh help

Commands:

backup      - creates a backup for a current date (in a database/backup directory
restore     - prints list of an available database backups and restores selected backup
post-deploy - executes a bunch of commands in a container ( migrate, config:clear, etc. edit scripts.sh file to add your custom commands there )

```


### TODO: 
1. add ldht to image
2. add skipping db check to shorten docker-compose.yml (default .env ?)
3. leave chown on behalf of a user (?)
