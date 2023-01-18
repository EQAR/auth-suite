#!/bin/sh

. /bin/entrypoint.common.sh

# generate Kerberos config
check_if_realm_in_env
generate_config

# if needed, wait for some time so kadmin (or kpropd) can initialise the DB
wait_for_file /var/lib/krb5kdc/principal ${KRB_MAXWAIT:-1800} 15

exec "$@"

