#!/bin/sh

. /bin/entrypoint.common.sh

# generate necessary config files
check_if_realm_in_env
check_if_suffix_in_env

# set default values
set -a
if [ -z "${LDAPCHERRY_PARENT_DN}" ]; then
    # create default parent DN list
    LDAPCHERRY_PARENT_DN="[ '${LDAP_SUFFIX}' ]"
fi
if [ -z "${LDAPCHERRY_ADMIN_GROUP_DN}" ]; then
    # set default admin group DN
    LDAPCHERRY_ADMIN_GROUP_DN="cn=admin,${LDAP_SUFFIX}"
fi
LDAPCHERRY_LOGLEVEL=${LDAPCHERRY_LOGLEVEL:-info}
set +a

generate_config \
    LDAP_SUFFIX \
    KRB_REALM \
    KRB_FORWARDABLE \
    KRB_PROXIABLE \
    KRB_MAX_LIFE \
    KRB_MAX_RENEWABLE_LIFE \
    REALM_NAME \
    LDAPCHERRY_URL \
    LDAPCHERRY_MAILFROM \
    LDAPCHERRY_PARENT_DN \
    LDAPCHERRY_ADMIN_GROUP_DN \
    LDAPCHERRY_LOGLEVEL \
    SMTP_HOST \
    SMTP_PORT

chmod 0600 /etc/mstmprc

wait_for_host slapd 389

exec "$@"

