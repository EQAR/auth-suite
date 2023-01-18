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
wait_for_file /var/lib/krb5kdc/principal ${KRB_MAXWAIT:-1800} 15

exec "$@"

