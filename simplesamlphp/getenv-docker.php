<?php

// from https://github.com/docker-library/wordpress/blob/master/latest/php7.4/apache/wp-config-docker.php

// avoid an error if this file is required/included more than once
if (!function_exists('getenv_docker')) {
    // a helper function to lookup "env_FILE", "env", then fallback
    function getenv_docker($env, $default = null) {
        if ($fileEnv = getenv($env . '_FILE')) {
            return rtrim(file_get_contents($fileEnv), "\r\n");
        }
        else if (($val = getenv($env)) !== false) {
            return $val;
        }
        else {
            return $default;
        }
    }
}

?>
