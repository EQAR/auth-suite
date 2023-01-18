#!/bin/sh
#
# entrypoint.kprop.sh - setup periodic propagation to replicas
#

. /bin/entrypoint.common.sh

# generate Kerberos config
check_if_realm_in_env
generate_config

echo -n "Creating crontab for kprop..."

crontab -u root -r
crontab -u root - << EOF
${KPROP_CRON} /usr/sbin/do-kprop.sh
EOF

echo " done."

# if needed, wait for some time so kadmin can initialise the DB
MAXWAIT=${KRB_MAXWAIT:-1800}
INTERVAL=15
WAITED=0
while [ ! -f /var/lib/krb5kdc/principal ]; do
    if [ $WAITED -ge $MAXWAIT ]; then
        echo "FATAL: database not found after $MAXWAIT seconds, quitting."
        exit 1
    fi
    echo "Kerberos database not initialised yet, sleeping $INTERVAL seconds..."
    sleep $INTERVAL
    WAITED=$(( WAITED+INTERVAL ))
done

exec "$@"

