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

generate_config '$LDAP_SUFFIX $KRB_REALM $LDAPCHERRY_URL $LDAPCHERRY_MAILFROM $LDAPCHERRY_PARENT_DN $LDAPCHERRY_ADMIN_GROUP_DN'

exec "$@"

