<?php
// This file is part of mdk custom scripts.

/**
 * Display the list of all capabilities in the current Moodle instance.
 */

define('CLI_SCRIPT', true);

require(__DIR__.'/config.php');

foreach ($DB->get_records('capabilities', null, 'name', '*') as $cap) {
    echo "$cap->name\t$cap->captype\t$cap->contextlevel\t$cap->riskbitmask".PHP_EOL;
}
