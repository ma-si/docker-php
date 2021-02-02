ARG PHP_VER=7.4

################################################################################
FROM php:${PHP_VER}-cli AS php-cli-base

RUN apt-get update \
 && apt-get install -y \
    git \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libxslt-dev \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    libldap2-dev \
    libonig-dev \
    zip \
    unzip \
    libicu-dev

RUN docker-php-ext-install \
    zip \
    dom \
    ctype \
    bcmath \
    pdo_mysql \
    mysqli \
    mbstring \
    opcache \
    soap \
    xmlwriter \
    simplexml \
    json \
    session \
    tokenizer \
    xml
RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install ldap
RUN docker-php-ext-configure gd && \
    docker-php-ext-install gd

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
########################################################################################################################
FROM php-cli-base AS php-cli-test
ARG COMPOSER_VERSIOM=2.0.9
ARG GROUP_ID=1000
ARG USER_ID=1000

RUN groupadd -g ${GROUP_ID} composer && \
    useradd composer -u ${USER_ID} -g composer -ms /bin/bash

# Create directories for cache volumes
RUN mkdir /home/composer/.composer && \
    chown composer:composer /home/composer/.composer

RUN yes | pecl install xdebug
#RUN yes | pecl install xdebug \
#    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini

# COMPOSER
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer --version=${COMPOSER_VERSIOM}

USER composer

WORKDIR /app
########################################################################################################################
FROM php:${PHP_VER}-apache AS php-apache-base

RUN apt-get update

# compression
RUN apt-get install -y \
    libzip-dev \
    zip \
    libbz2-dev \
 && docker-php-ext-install \
    zip \
    bz2

# yaml
RUN apt-get install -y \
    libyaml-dev \
 && pecl install \
    yaml \
 && docker-php-ext-enable yaml

# intl
RUN apt-get install -y \
    libicu-dev \
 && docker-php-ext-install \
    intl

# jwt
#RUN apt-get install libssl-dev -y \
# && cd /usr/src/php/ext/jwt \
# && git clone https://github.com/cdoco/php-jwt.git \
# && cd jwt \
# && phpize && ./configure --with-openssl=/usr/local/ssl \
# && make && make install



#imagemagick
#RUN apt-get install -y \
#    libmagickwand-dev --no-install-recommends \
# && pecl install \
#    imagick \
# && docker-php-ext-enable \
#    imagick

# bcmath
RUN docker-php-ext-install \
    bcmath

# pgsql
RUN apt-get install -y \
    libpq-dev
RUN docker-php-ext-install \
    pdo_pgsql

# mongodb
#RUN pecl install \
#    mongodb \
# && docker-php-ext-enable \
#    mongodb

# mysql
RUN docker-php-ext-install \
    pdo_mysql

# mysqli
RUN docker-php-ext-install \
    mysqli

# redis
RUN pecl install \
    redis \
 && docker-php-ext-enable \
    redis

# rabbitmq
RUN apt-get install -y \
    # rabbit mq
    librabbitmq-dev \
    # zero mq
    libsodium-dev \
 && pecl install \
    amqp

# gmp
RUN apt-get install -y \
    libgmp-dev \
 && docker-php-ext-install \
    gmp

# apcu
RUN pecl install \
    apcu \
 && docker-php-ext-enable \
    apcu


RUN rm -r /var/lib/apt/lists/*



# APACHE
RUN a2enmod rewrite \
 && sed -i 's!/var/www/html!/var/www/public!g' /etc/apache2/sites-available/000-default.conf \
 && mv /var/www/html /var/www/public \
 && echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Memory Limit
RUN echo "memory_limit=-1" > $PHP_INI_DIR/conf.d/memory-limit.ini

# Time Zone
RUN echo "date.timezone=${PHP_TIMEZONE:-UTC}" > $PHP_INI_DIR/conf.d/date_timezone.ini

WORKDIR /var/www
########################################################################################################################
FROM php-apache-base AS php-apache-test
ARG COMPOSER_VERSIOM=2.0.9
ARG GROUP_ID=1000
ARG USER_ID=1000

RUN groupadd -g ${GROUP_ID} composer && \
    useradd composer -u ${USER_ID} -g composer -ms /bin/bash

RUN apt-get update \
 && apt-get install -y git

# Create directories for cache volumes
RUN mkdir /home/composer/.composer && \
    chown composer:composer /home/composer/.composer

RUN yes | pecl install xdebug
#RUN yes | pecl install xdebug \
#    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini

# COMPOSER
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer --version=${COMPOSER_VERSIOM}

USER composer

WORKDIR /var/www
########################################################################################################################
