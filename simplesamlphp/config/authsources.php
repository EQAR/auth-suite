<?php

include('getenv-docker.php');

$config = array(

    // This is a authentication source which handles admin authentication.
    'admin' => array(
        // The default is to use core:AdminPassword, but it can be replaced with
        // any authentication source.

        'core:AdminPassword',
    ),


    // An authentication source which can authenticate against both SAML 2.0
    // and Shibboleth 1.3 IdPs.
    'docker-sp' => array(
        'saml:SP',

        // The entity ID of this SP.
        // Can be NULL/unset, in which case an entity ID is generated based on the metadata URL.
        'entityID' => null,

        // The entity ID of the IdP this should SP should contact.
        // Can be NULL/unset, in which case the user will be shown a list of available IdPs.
        'idp' => getenv_docker('SSP_BASE_URL'),

        // The URL to the discovery service.
        // Can be NULL/unset, in which case a builtin discovery service will be used.
        'discoURL' => null,

        /*
         * The attributes parameter must contain an array of desired attributes by the SP.
         * The attributes can be expressed as an array of names or as an associative array
         * in the form of 'friendlyName' => 'name'. This feature requires 'name' to be set.
         * The metadata will then be created as follows:
         * <md:RequestedAttribute FriendlyName="friendlyName" Name="name" />
         */
        /*'name' => array(
             'en' => 'A service',
             'no' => 'En tjeneste',
          ),

          'attributes' => array(
            'attrname' => 'urn:oid:x.x.x.x',
        ),*/
        /*'attributes.required' => array (
            'urn:oid:x.x.x.x',
        ),*/
    ),

    // Example of a LDAP authentication source.
    'docker-ldap' => array(
        'ldap:LDAP',

        // Give the user an option to save their username for future login attempts
        // And when enabled, what should the default be, to save the username or not
        //'remember.username.enabled' => FALSE,
        //'remember.username.checked' => FALSE,

        // The hostname of the LDAP server.
        'hostname' => 'slapd',

        // Whether SSL/TLS should be used when contacting the LDAP server.
        'enable_tls' => FALSE,

        // Whether debug output from the LDAP library should be enabled.
        // Default is FALSE.
        'debug' => FALSE,

        // The timeout for accessing the LDAP server, in seconds.
        // The default is 0, which means no timeout.
        'timeout' => 0,

        // The port used when accessing the LDAP server.
        // The default is 389.
        'port' => 389,

        // Set whether to follow referrals. AD Controllers may require FALSE to function.
        'referrals' => TRUE,

        // Which attributes should be retrieved from the LDAP server.
        // This can be an array of attribute names, or NULL, in which case
        // all attributes are fetched.
        'attributes' => NULL,

        // The pattern which should be used to create the users DN given the username.
        // %username% in this pattern will be replaced with the users username.
        //
        // This option is not used if the search.enable option is set to TRUE.
        'dnpattern' => NULL,

        // As an alternative to specifying a pattern for the users DN, it is possible to
        // search for the username in a set of attributes. This is enabled by this option.
        'search.enable' => TRUE,

        // The DN which will be used as a base for the search.
        // This can be a single string, in which case only that DN is searched, or an
        // array of strings, in which case they will be searched in the order given.
        'search.base' => getenv_docker('LDAP_SUFFIX'),

        // The attribute(s) the username should match against.
        //
        // This is an array with one or more attribute names. Any of the attributes in
        // the array may match the value the username.
        'search.attributes' => array('uid', 'mail'),

        // Additional LDAP filters appended to the search attributes
        'search.filter' => '(|(objectclass=posixAccount)(objectclass=inetOrgPerson))',

        // The username & password the SimpleSAMLphp should bind to before searching. If
        // this is left as NULL, no bind will be performed before searching.
        'search.username' => NULL,
        'search.password' => NULL,

        // If the directory uses privilege separation,
        // the authenticated user may not be able to retrieve
        // all required attribures, a privileged entity is required
        // to get them. This is enabled with this option.
        'priv.read' => FALSE,

        // The DN & password the SimpleSAMLphp should bind to before
        // retrieving attributes. These options are required if
        // 'priv.read' is set to TRUE.
        'priv.username' => NULL,
        'priv.password' => NULL,

    ),

);
