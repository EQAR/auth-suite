#!/bin/bash

. /bin/entrypoint.common.sh

# generate necessary Kerberos config
check_if_realm_in_env
generate_config

# export variables
export KRB5_KTNAME=/etc/krb5keytab/saslauthd.keytab

exec "$@"

