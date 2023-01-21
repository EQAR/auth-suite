#!/bin/sh
#
# entrypoint.kpropd.sh - generate configuration, check keytab and stash
#

. /bin/entrypoint.common.sh

# generate Kerberos config
check_if_realm_in_env
generate_config

# initialize database if needed
if [ -f /var/lib/krb5kdc/principal ]; then
    echo "Database present."
elif [ -d /initdb.d ] && [ -f /initdb.d/krb5_stash ] && [ -f /initdb.d/kpropd.keytab ]; then
    echo -n "Copying stash file and keytab from /initdb.d: "
    cp /initdb.d/krb5_stash /var/lib/krb5kdc/stash
    cp /initdb.d/kpropd.keytab /etc/krb5keytab
    echo "Done."
else
    echo "Error: no database present and required files not in /initdb.d."
    echo
    echo "Files to mount into /initdb.d:"
    echo "- krb5_stash    : stash file from primary KDC/kadmin instance"
    echo "- kpropd.keytab : keytab for this replica"
    echo
    exit 10
fi

# link kpropd.acl
ln -sf /etc/krb5kdc/kpropd.acl /var/lib/krb5kdc

exec "$@"

