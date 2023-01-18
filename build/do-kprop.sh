#!/bin/sh

cd /var/lib/krb5kdc

echo -n "Dumping Kerberos database:"
kdb5_util dump ./replica_datatrans && echo " OK". || echo " Failure."

echo -n "Propagating to replicas:"
for HOST in ${KPROP_REPLICAS} ; do
    echo -n " ${HOST}"
    kprop -f ./replica_datatrans -s /etc/krb5keytab/kprop.keytab ${HOST}
done
echo

