#!/bin/sh

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

# create LDAP config if needed
# (can be persisted on a volume to make manual changes, or auto-generated on every container start)
if [ ! -f "/etc/ldap/slapd.d/cn=config.ldif" ]; then
    echo -n "Generating slapd configuration with schemata:"
    slapadd -n0 -F /etc/ldap/slapd.d -l /etc/ldap/config_pre.ldif
    for i in ${LDAP_SCHEMA} ; do
        echo -n " (dist)${i}"
        slapadd -n0 -F /etc/ldap/slapd.d -l "/etc/ldap/schema/${i}.ldif"
    done
    if [ -d /usr/local/share/ldap-schema.d ]; then
        for i in /usr/local/share/ldap-schema.d/*.ldif ; do
            echo -n " (image)$(basename ${i})"
            slapadd -n0 -F /etc/ldap/slapd.d -l "${i}"
        done
    fi
    if [ -d /initschema.d ]; then
        for i in /initschema.d/*.ldif ; do
            echo -n " (initschema.d)$(basename ${i})"
            slapadd -n0 -F /etc/ldap/slapd.d -l "${i}"
        done
    fi
    slapadd -n0 -F /etc/ldap/slapd.d -l /etc/ldap/config_post.ldif
    echo
    if [ -d /initolc.d ]; then
        echo -n "Applying slapd configuration modifications:"
        for i in /initolc.d/*.ldif ; do
            echo -n " (initolc.d)$(basename ${i})"
            slapmodify -n0 -F /etc/ldap/slapd.d -l "${i}"
        done
        echo
    fi
else
    slaptest -F /etc/ldap/slapd.d || echo "WARNING: slaptest failed, consider deleting the config volume to re-generate" 1>&2
fi

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

exec "$@"

