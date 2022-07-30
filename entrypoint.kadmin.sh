#!/bin/bash
#
# entrypoint.kadmin.sh - generate configuration and inititalise database
#

. /bin/entrypoint.common.sh

# generate Kerberos config
check_if_realm_in_env
generate_config

# initialize database if needed
if [ -f /var/lib/krb5kdc/principal ]; then
    echo "Database present."
else
    echo "No database present, initializing:"
    if [ -z "${KRB_MASTER_PASSWORD}" ]; then
        KRB_MASTER_PASSWORD=$(rand_password)
        echo "- random Kerberos master password: ${KRB_MASTER_PASSWORD}"
    fi
    echo -n "- creating new database: "
    kdb5_util -r ${KRB_REALM} -P "${KRB_MASTER_PASSWORD}" create -s && echo "OK." || echo "Failed."
    if [ -z "${KRB_ADMIN_PASSWORD}" ]; then
        KRB_ADMIN_PASSWORD=$(rand_password)
        echo "- random password for admin principal: ${KRB_ADMIN_PASSWORD}"
    fi
    echo -n "- creating principal ${KRB_DEFAULT_ADMIN}@${KRB_REALM}: "
    kadmin.local addprinc -pw "${KRB_ADMIN_PASSWORD}" "${KRB_DEFAULT_ADMIN}" && echo "OK." || echo "Failed."
fi

echo "Checking for required principals and keytabs:"
# check if principals exist & generate keytabs
check_principal_keytab host/saslauthd._docker saslauthd.keytab
check_principal_keytab ldap/${LDAP_HOSTNAME:-slapd._docker} slapd.keytab
check_principal_keytab ldapcherry ldapcherry.keytab

exec "$@"

