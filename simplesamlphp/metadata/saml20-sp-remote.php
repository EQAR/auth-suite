<?php

/* local SP : used for testing */
$metadata[getenv_docker('SSP_BASE_URL').'/module.php/saml/sp/metadata.php/docker-sp'] = [
    'AssertionConsumerService' =>   getenv_docker('SSP_BASE_URL').'/module.php/saml/sp/saml2-acs.php/docker-sp',
    'SingleLogoutService' =>        getenv_docker('SSP_BASE_URL').'/module.php/saml/sp/saml2-logout.php/docker-sp',

    'name' =>   'Local SP',

    'attributes.NameFormat' =>      'urn:oasis:names:tc:SAML:2.0:attrname-format:uri',

];

