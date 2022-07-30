#!/bin/bash

. /bin/entrypoint.common.sh

# generate Kerberos config
check_if_realm_in_env
generate_config

# if needed, wait for some time so kadmin can initialise the DB
MAXWAIT=30
INTERVAL=5
WAITED=0
while [ ! -f /var/lib/krb5kdc/principal ]; do
    if [ $WAITED -ge $MAXWAIT ]; then
        echo "FATAL: database not found after $MAXWAIT seconds, quitting."
        exit 1
    fi
    echo "Kerberos database not initialised yet, sleeping $INTERVAL seconds..."
    sleep $INTERVAL
    WAITED=$[WAITED+INTERVAL]
done

exec "$@"

