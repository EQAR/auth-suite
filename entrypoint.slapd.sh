#!/bin/bash

. /bin/entrypoint.common.sh

# generate necessary config files
check_if_realm_in_env
check_if_suffix_in_env
generate_config

# set default schema to include
LDAP_SCHEMA="${LDAP_SCHEMA:-core cosine nis inetorgperson}"

# create LDAP config
echo -n "Generating slapd configuration with schemata:"
slapadd -n0 -F /etc/ldap/slapd.d -l /etc/ldap/config_pre.ldif #|| true
for i in ${LDAP_SCHEMA} ; do
    echo -n " ${i}"
    slapadd -n0 -F /etc/ldap/slapd.d -l "/etc/ldap/schema/${i}.ldif"
done
if [ -d /ldap-add-schema.d ]; then
    for i in /ldap-add-schema.d/*.ldif ; do
        echo -n " $(basename ${i})"
        slapadd -n0 -F /etc/ldap/slapd.d -l "${i}"
    done
fi
slapadd -n0 -F /etc/ldap/slapd.d -l /etc/ldap/config_post.ldif #|| true

# if LDAP database is empty, prime with data
if [ ! -f /var/lib/ldap/data.mdb ]; then
    slapadd -b "ou=users,${LDAP_SUFFIX}" -F /etc/ldap/slapd.d -l /etc/ldap/base-data.ldif
fi

# fix LDAP database + saslauthd socket permissions
chown -R openldap.openldap /etc/ldap/slapd.d /var/lib/ldap /etc/krb5keytab/slapd.keytab
chgrp openldap /var/run/saslauthd

# export variables
export KRB5_KTNAME=/etc/krb5keytab/slapd.keytab

exec "$@"

