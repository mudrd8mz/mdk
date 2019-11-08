<?php
// This file is part of mdk custom scripts.

/**
 * Display the list of all capabilities in the current Moodle instance.
 */

define('CLI_SCRIPT', true);

require(__DIR__.'/config.php');

foreach ($DB->get_records('capabilities', null, 'name', 'id, name') as $cap) {
    echo $cap->name.PHP_EOL;
}
