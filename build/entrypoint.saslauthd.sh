#!/bin/sh

. /bin/entrypoint.common.sh

# generate necessary Kerberos config
check_if_realm_in_env
generate_config

exec "$@"

