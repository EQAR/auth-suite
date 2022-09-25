# work starts here
FROM php:8-fpm-alpine

# install Debian packagesa and required PHP extensions
RUN apk add --no-cache wget libldap openldap-dev \
    && docker-php-ext-install ldap

COPY getenv-docker.php /usr/local/lib/php

# get SimpleSAMLphp
ARG SIMPLE_SAML_PHP_VERSION=1.19.6
ARG SIMPLE_SAML_PHP_HASH=834bb4a89d63d7498e77cceb49e01b919d1c0a6a3d38a992f905810dad424b7c

RUN cd /tmp \
    && wget https://github.com/simplesamlphp/simplesamlphp/releases/download/v$SIMPLE_SAML_PHP_VERSION/simplesamlphp-$SIMPLE_SAML_PHP_VERSION.tar.gz \
    && echo "$SIMPLE_SAML_PHP_HASH  simplesamlphp-$SIMPLE_SAML_PHP_VERSION.tar.gz" | sha256sum -c - \
    && cd /opt \
    && tar xzf /tmp/simplesamlphp-$SIMPLE_SAML_PHP_VERSION.tar.gz \
    && mv simplesamlphp-$SIMPLE_SAML_PHP_VERSION simplesamlphp

# add adapted config & metadata files
COPY config/* /etc/simplesamlphp/config/
COPY metadata/* /etc/simplesamlphp/metadata/

WORKDIR /opt/simplesamlphp
RUN rm -rf config metadata cert data \
	&& mkdir -p /var/lib/simplesamlphp/cert /var/lib/simplesamlphp/data /var/log/simplesamlphp \
    && chown www-data.www-data /var/log/simplesamlphp \
	&& ln -sf /etc/simplesamlphp/config \
	&& ln -sf /etc/simplesamlphp/metadata \
	&& ln -sf /var/lib/simplesamlphp/cert \
	&& ln -sf /var/lib/simplesamlphp/data

COPY entrypoint.simplesamlphp.sh /bin/entrypoint.sh

ENTRYPOINT [ "/bin/entrypoint.sh" ]

CMD [ "php-fpm" ]

