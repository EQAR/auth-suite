#!/bin/sh

. /bin/entrypoint.common.sh

# check required environment variables
check_if_realm_in_env
check_if_suffix_in_env

if [ ! -f /var/lib/openldap/data.mdb ] && [ ! -d /initdb.d ] && [ -z "${LDAP_SYNCREPL_PROVIDER}" ]; then
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
if [ ! -f "/etc/openldap/slapd.d/cn=config.ldif" ]; then
    echo -n "Generating slapd configuration with schemata:"
    slapadd -n0 -F /etc/openldap/slapd.d -l /etc/openldap/config_pre.ldif
    for i in ${LDAP_SCHEMA} ; do
        echo -n " (dist)${i}"
        slapadd -n0 -F /etc/openldap/slapd.d -l "/etc/openldap/schema/${i}.ldif"
    done
    if [ -d /usr/local/share/ldap-schema.d ]; then
        for i in /usr/local/share/ldap-schema.d/*.ldif ; do
            echo -n " (image)$(basename ${i})"
            slapadd -n0 -F /etc/openldap/slapd.d -l "${i}"
        done
    fi
    if [ -d /initschema.d ]; then
        for i in /initschema.d/*.ldif ; do
            echo -n " (initschema.d)$(basename ${i})"
            slapadd -n0 -F /etc/openldap/slapd.d -l "${i}"
        done
    fi
    slapadd -n0 -F /etc/openldap/slapd.d -l /etc/openldap/config_post.ldif
    echo
    if [ -z "${LDAP_SYNCREPL_PROVIDER}" ]; then
        # this is a main instance
        if [ -n "${LDAP_REPLICAS}" ]; then
            # activate syncprov overlay if replication needed
            echo -n "Main instance, adding syncrepl overlay:"
            slapadd -n0 -F /etc/openldap/slapd.d -l /etc/openldap/config_syncprov_main.ldif
            echo " OK."
        fi
    else
        # this is a replica instance - add replication config
        echo -n "Replica instance, adding syncrepl client config:"
        slapmodify -n0 -F /etc/openldap/slapd.d -l /etc/openldap/config_syncprov_replica.ldif
        echo " OK."
    fi
    if [ -d /initolc.d ]; then
        echo -n "Applying slapd configuration modifications:"
        for i in /initolc.d/*.ldif ; do
            echo -n " (initolc.d)$(basename ${i})"
            slapmodify -n0 -F /etc/openldap/slapd.d -l "${i}"
        done
        echo
    fi
else
    slaptest -F /etc/openldap/slapd.d || echo "WARNING: slaptest failed, consider deleting the config volume to re-generate" 1>&2
fi

# if LDAP database is empty, prime with data
# (but only if we are solo/main instance)
if [ ! -f /var/lib/openldap/data.mdb ] && [ -z "${LDAP_SYNCREPL_PROVIDER}" ]; then
    if [ -d /initdb.d ] &&  [ -n "$(find /initdb.d -name '*.ldif')" ]; then
        echo -n "Initializing LDAP database from /initdb.d: "
        for i in /initdb.d/*.ldif ; do
            echo -n " $(basename ${i})"
            slapadd -b "${LDAP_SUFFIX}" -F /etc/openldap/slapd.d -l "${i}"
        done
        echo
    else
        echo -n "Initializing empty LDAP database for ${LDAP_SUFFIX}: "
        slapadd -b "${LDAP_SUFFIX}" -F /etc/openldap/slapd.d -l /etc/openldap/base-data.ldif
        echo "Done."
    fi
fi

# fix LDAP database + saslauthd socket permissions
chown -R ldap.ldap \
    /etc/openldap/slapd.d \
    /var/lib/openldap \
    /etc/krb5keytab/slapd.keytab \
    /var/run/slapd

chgrp ldap /var/run/saslauthd

# wait for KDC to be up
wait_for_host kdc 88

# check for keytab
if [ ! -f /etc/krb5keytab/slapd.keytab ]; then
    if [ -d /initdb.d ] && [ -f /initdb.d/slapd.keytab ]; then
        echo -n "Copying keytab from /initdb.d: "
        cp /initdb.d/slapd.keytab /etc/krb5keytab
        echo "Done."
    else
        echo "Error: no keytab present in volume or /initdb.d."
        echo "-> mount slapd.keytab into /initdb.d to load"
        echo
        exit 10
    fi
fi

# replica needs to get and periodically renew a ticket to authenticate to main slapd
if [ -n "${LDAP_SYNCREPL_PROVIDER}" ]; then
    su -s /bin/sh -c "kinit -k -t /etc/krb5keytab/slapd.keytab ldap/${MY_FQDN}" ldap || echo "ERROR: kinit failed." 1>&2
    crontab -u root -r
    crontab -u ldap -r
    echo "${LDAP_KINIT_CRON} kinit -k -t /etc/krb5keytab/slapd.keytab ldap/${MY_FQDN}" | crontab -u ldap -
    crond -f -d6 &
fi

exec "$@"

