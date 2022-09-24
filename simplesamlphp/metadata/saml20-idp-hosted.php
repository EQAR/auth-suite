<?php

include('getenv-docker.php');

$metadata[getenv_docker('SSP_BASE_URL')] = [
    /*
     * The hostname for this IdP. This makes it possible to run multiple
     * IdPs from the same configuration. '__DEFAULT__' means that this one
     * should be used by default.
     */
    'host' => '__DEFAULT__',

    /*
     * The private key and certificate to use when signing responses.
     * These are stored in the cert-directory.
     */
    'privatekey' => 'docker-saml.pem',
    'certificate' => 'docker-saml.crt',

    'OrganizationName' => getenv_docker('SSP_ORG_NAME', '[OrganizationName]'),
    'OrganizationDisplayName' => getenv_docker('SSP_ORG_DISPLAY', '[OrganizationDisplayName'),
    'OrganizationURL' => getenv_docker('SSP_ORG_URL', '[OrganizationURL]'),

    'SingleSignOnServiceBinding' => [
        'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect',
        'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
    ],
    'SingleLogoutServiceBinding' => [
        'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect',
        'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
    ],

    /*
     * The authentication source which should be used to authenticate the
     * user. This must match one of the entries in config/authsources.php.
     */
    'auth' => 'docker-ldap',

    /* unique ID for when needed */
    'userid.attribute' => 'uidNumber',

    'NameIDFormat' => 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',

    'attributes.NameFormat' => 'urn:oasis:names:tc:SAML:2.0:attrname-format:uri',

    'authproc' => [
        // Convert LDAP names to oids.
        100 => [
            'class' => 'core:AttributeMap',
            'name2oid'
        ],
    ],
];

