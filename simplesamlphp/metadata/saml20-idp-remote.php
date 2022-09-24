<?php

include('getenv-docker.php');

$metadata[getenv_docker('SSP_BASE_URL')] = [
    'SingleSignOnService'   => getenv_docker('SSP_BASE_URL') . '/saml2/idp/SSOService.php',
    'SingleLogoutService'   => getenv_docker('SSP_BASE_URL') . '/saml2/idp/SingleLogoutService.php',
    'certificate'           => 'docker-saml.crt',
    'name'                  => getenv_docker('SSP_ORG_DISPLAY', 'Local IdP'),
];

