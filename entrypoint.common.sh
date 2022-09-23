#
# entrypoint.common.sh - defaults and configuration common to kadmin & kdc
#

# configuration defaults (because envsubst doesn't support default values)
set -a
KRB_KDC_PORTS="${KRB_KDC_PORTS:-750,88}"
KRB_DEFAULT_PRINCIPAL_FLAGS="${KRB_DEFAULT_PRINCIPAL_FLAGS:-+preauth}"
KRB_MAX_LIFE="${KRB_MAX_LIFE:-10h 0m 0s}"
KRB_MAX_RENEWABLE_LIFE="${KRB_MAX_RENEWABLE_LIFE:-7d 0h 0m 0s}"
KRB_FORWARDABLE="${KRB_FORWARDABLE:-true}"
KRB_PROXIABLE="${KRB_PROXIABLE:-true}"
KRB_DEFAULT_ADMIN="${KRB_DEFAULT_ADMIN:-admin/admin}"
set +a

# helper: generate random password
rand_password() {
    ALPHABET="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    for i in $(seq 1 16) ; do
        echo -n ${ALPHABET:RANDOM%${#ALPHABET}:1}
    done
}

principal_exists() {
    kadmin.local getprinc "$1" > /dev/null 2>&1 && return 0 || return $?
}

check_if_realm_in_env() {
    # only mandatory variable: realm name
    if [ -z "${KRB_REALM}" ]; then
        echo "FATAL: Kerberos realm must be specified in KRB_REALM."
        exit 10
    fi
    return 0
}

check_if_suffix_in_env() {
    # only mandatory variable for LDAP: suffix
    if [ -z "${LDAP_SUFFIX}" ]; then
        echo "FATAL: LDAP suffix must be specified in LDAP_SUFFIX."
        exit 20
    fi
    return 0
}

generate_config() {
    # generate configs
    echo -n "Generating /etc files:"
    for f in $(cd /usr/local/share/etc-templates ; find . -type f | sed 's/^.\///') ; do
        echo -n " $f"
        if [ -z "$1" ]; then
            envsubst < "/usr/local/share/etc-templates/$f" > "/etc/$f"
        else
            envsubst "$1" < "/usr/local/share/etc-templates/$f" > "/etc/$f"
        fi
    done
    echo
}

check_principal_keytab() {
    if ! principal_exists "$1" ; then
        echo -n "- creating principal $1@${KRB_REALM}: "
        kadmin.local addprinc -randkey "$1" > /dev/null && echo "OK." || echo "Failed."
        kadmin.local ktadd -k "/etc/krb5keytab/$2" "$1" > /dev/null && echo "OK." || echo "Failed."
    elif [ ! -f "/etc/krb5keytab/$2" ]; then
        echo -n "- saving $1@${KRB_REALM} to /etc/krb5keytab/$2: "
        kadmin.local ktadd -k "/etc/krb5keytab/$2" "$1" > /dev/null && echo "OK." || echo "Failed."
    fi
}

