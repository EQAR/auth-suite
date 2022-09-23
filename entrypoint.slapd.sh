#!/bin/bash

. /bin/entrypoint.common.sh

# check required environment variables
check_if_realm_in_env
check_if_suffix_in_env
if [ ! -f /var/lib/ldap/data.mdb ] && [ ! -d /initdb.d ]; then
    # if a new database needs to be initialised, we need to assure that LDAP_SUFFIX is an o or ou object
    LDAP_ROOT_ATTRIBUTE="$(echo $LDAP_SUFFIX | cut -d, -f1 | cut -d= -f1)"
    LDAP_ROOT_VALUE="$(echo $LDAP_SUFFIX | cut -d, -f1 | cut -d= -f2)"
    case $LDAP_ROOT_ATTRIBUTE in
        o)  LDAP_OBJECTCLASS="organization"
            ;;
        ou) LDAP_OBJECTCLASS="organizationalUnit"
            ;;
        *)  echo "FATAL: for creating empty database, LDAP_SUFFIX should start with o= or ou="
            exit 2
    esac
    export LDAP_ROOT_ATTRIBUTE LDAP_ROOT_VALUE LDAP_OBJECTCLASS
fi
# generate necessary config files
generate_config

# set default schema to include
LDAP_SCHEMA="${LDAP_SCHEMA:-core cosine nis inetorgperson}"

# create LDAP config
echo -n "Generating slapd configuration with schemata:"
slapadd -n0 -F /etc/ldap/slapd.d -l /etc/ldap/config_pre.ldif
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
slapadd -n0 -F /etc/ldap/slapd.d -l /etc/ldap/config_post.ldif
echo

# if LDAP database is empty, prime with data
if [ ! -f /var/lib/ldap/data.mdb ]; then
    if [ -d /initdb.d ] &&  [ -n "$(find /initdb.d -name '*.ldif')" ]; then
        echo -n "Initializing LDAP database from /initdb.d: "
        for i in /initdb.d/*.ldif ; do
            echo -n " $(basename ${i})"
            slapadd -b "${LDAP_SUFFIX}" -F /etc/ldap/slapd.d -l "${i}"
        done
        echo
    else
        echo -n "Initializing empty LDAP database for ${LDAP_SUFFIX}: "
        slapadd -b "${LDAP_SUFFIX}" -F /etc/ldap/slapd.d -l /etc/ldap/base-data.ldif
        echo "Done."
    fi
fi

# fix LDAP database + saslauthd socket permissions
chown -R openldap.openldap /etc/ldap/slapd.d /var/lib/ldap /etc/krb5keytab/slapd.keytab
chgrp openldap /var/run/saslauthd

# export variables
export KRB5_KTNAME=/etc/krb5keytab/slapd.keytab

exec "$@"

