#!/bin/bash

. /bin/entrypoint.common.sh

# generate necessary config files
check_if_realm_in_env
check_if_suffix_in_env
generate_config '$LDAP_SUFFIX $KRB_REALM $LDAPCHERRY_URL $LDAPCHERRY_MAILFROM'

exec "$@"

