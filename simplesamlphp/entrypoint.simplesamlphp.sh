#!/bin/bash
#
# entrypoint.simplesamlphp.sh - generate cert for SAML if needed
#

REALM_NAME="${REALM_NAME:-Example Inc.}"

CERT_DIR=/var/lib/simplesamlphp/cert
CERT_SUBJECT="${SSP_SAML_CERT_SUBJECT:-/C=BE/ST=Brussels/L=Brussels/O=${REALM_NAME}/OU=Users/CN=${REALM_NAME}}"

(
    if [ ! -d "$CERT_DIR" ]; then
        mkdir -p "$CERT_DIR"
    fi
    cd $CERT_DIR
    if [ -f docker-saml.pem ]; then
        echo "Certificate is present."
    else
        echo "Generating new certificate."
        openssl req -subj "$CERT_SUBJECT" -newkey rsa:3072 -new -x509 -days 3652 -nodes -out docker-saml.crt -keyout docker-saml.pem
    fi
    # fix permissions
    chgrp www-data docker-saml.pem
    chmod g+r docker-saml.pem
)

exec /usr/local/bin/docker-php-entrypoint "$@"

