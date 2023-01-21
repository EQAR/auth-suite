#!/bin/sh

. /bin/entrypoint.common.sh

# generate necessary Kerberos config
check_if_realm_in_env
generate_config

# wait for KDC to be up
wait_for_host kdc 88

# check for keytab
if [ ! -f /etc/krb5keytab/saslauthd.keytab ]; then
    if [ -d /initdb.d ] && [ -f /initdb.d/saslauthd.keytab ]; then
        echo -n "Copying keytab from /initdb.d: "
        cp /initdb.d/saslauthd.keytab /etc/krb5keytab
        echo "Done."
    else
        echo "Error: no keytab present in volume or /initdb.d."
        echo "-> mount saslauthd.keytab into /initdb.d to load"
        echo
        exit 10
    fi
fi

exec "$@"

