FROM php:5.6-apache
MAINTAINER Scott van Brug <svanbrug@ebay.com>

# Install requirements for Magento 2, composer, and some helpful tools.
RUN apt-get update && apt-get install -qqy \
        apt-utils \
        g++ \
        git \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
        libxslt-dev \
        mysql-client \
        re2c \
        wget \
    && docker-php-ext-configure gd \
        --with-freetype-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install \
        bcmath \
        gd \
        intl \
        mbstring \
        mcrypt \
        mysql \
        pdo_mysql \
        pcntl \
        xsl \
        zip \
    && apt-get autoremove -qqy

# Install XDebug
RUN cd /tmp/ \
    && wget http://xdebug.org/files/xdebug-2.3.2.tgz \
    && tar zxvf xdebug-2.3.2.tgz \
    && cd /tmp/xdebug-2.3.2/ \
    && phpize \
    && ./configure \
    && make \
    && cp modules/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-20131226 \
    && echo \
        "zend_extension = /usr/local/lib/php/extensions/no-debug-non-zts-20131226/xdebug.so" \
        > /usr/local/etc/php/php.ini

# Install composer
WORKDIR /usr/local/bin
RUN curl -sS https://getcomposer.org/installer | php \
    && chmod +x composer.phar \
    && ln -s composer.phar composer

# Setup Apache dirs and configuration.

# Create a "default" user. Any volume mounted files should be owned by this
# user, so web source files can be shared via a volume mount. Apache will be run
# as this user by `apache_safe_start_perms` to have the necessary permissions
# on any volume mounted files and directories.
RUN adduser --system --uid=1000 default

# Extension repo should be mounted to /var/www/code. Magento 2 will be built
# and served from /var/www/code/build/magento.
RUN mkdir -p /var/www/code/build/magento && chown -R default /var/www/code
ENV MAGENTO_ROOT_DIR /var/www/code/build/magento
WORKDIR /var/www/code

# Add apache configuration and enable mod_rewrite
COPY dockerenv/config/apache2.conf /etc/apache2/apache2.conf
RUN a2enmod rewrite

VOLUME /var/www/code

COPY dockerenv/bin/* /usr/local/bin/

# `apache_safe_start_perms` will start apache as the "default" user.
CMD ["apache_safe_start_perms", "-DFOREGROUND"]
