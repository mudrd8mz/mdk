<?php

// unplug.php - uninstalls all additional plugins from this moodle
//
// This version has very dump way of dealing with dependencies but it can help
// a lot as-is during plugins reviews.

define('CLI_SCRIPT', true);
define('IGNORE_COMPONENT_CACHE', true);

require(__DIR__.'/config.php');
require_once($CFG->libdir.'/adminlib.php');
require_once($CFG->libdir.'/clilib.php');

// Get plugin manager instance.
$pluginman = core_plugin_manager::instance();

// Get the list of all plugins.
$plugininfo = $pluginman->get_plugins();

// Filter non-standard plugins only.
$contribs = [];
foreach ($plugininfo as $plugintype => $pluginnames) {
    foreach ($pluginnames as $pluginname => $pluginfo) {
        if (!$pluginfo->is_standard()) {
            $contribs[$pluginfo->component] = $pluginfo;
        }
    }
}

if (empty($contribs)) {
    cli_writeln('No additional plugins found, nothing to uninstall.');
    exit(0);
}

// List of plugins to be deleted, in order.
$del = [];

// This is a simple algorithm for trivial dealing of dependencies on one level.
// No nested dependencies, no circular dependencies etc.
foreach ($contribs as $plugin) {
    if ($pluginman->can_uninstall_plugin($plugin->component)) {
        // Seems like it has no dependencies and be uninstalled anytime.
        mtrace('easy to uninstall '.$plugin->component);
        array_push($del, $plugin->component);
    } else {
        mtrace('cannot uninstall '.$plugin->component.' - checking dependencies');
        foreach ($pluginman->other_plugins_that_require($plugin->component) as $dependent) {
            if (!isset($contribs[$dependent])) {
                cli_error('Unexpected dependency - standard plugin '.$dependent.' depends on a non-standard '.$plugin->component);
            } else {
                $depinfo = $contribs[$dependent];
            }
            if ($depinfo->get_status() === core_plugin_manager::PLUGIN_STATUS_NEW) {
                mtrace(' ... is required by not yet installed '.$dependent);
                array_unshift($del, $dependent);
            } else if ($pluginman->can_uninstall_plugin($dependent)) {
                mtrace(' ... is required by '.$dependent.' that can be uninstalled easily');
                array_unshift($del, $dependent);
            } else {
                mtrace(' ... is required by '.$dependent.' that cannot be uninstalled easily!');
                array_unshift($del, $dependent);
            }
        }
        array_push($del, $plugin->component);
    }
}
$del = array_unique($del);

// Ask for confirmation.
cli_heading('List of plugins to be uninstalled and removed from the disk');
cli_writeln(implode(PHP_EOL, $del));
if ('y' !== cli_input('Uninstall and remove these plugins? [y/n]')) {
    exit(1);
}

// Attempt to uninstall the plugins.
foreach ($del as $plugin) {
    cli_writeln('Uninstalling '.$plugin);
    $progress = new progress_trace_buffer(new text_progress_trace());
    $pluginman->uninstall_plugin($plugin, $progress);
    $progress->finished();
}

$man = [];

// Delete the plugin folders.
foreach ($del as $plugin) {
    try {
        $pluginman->remove_plugin_folder($contribs[$plugin]);
    } catch (moodle_exception $e) {
        if ($e->errorcode === 'err_removing_unremovable_folder') {
            $man[] = $e->a['rootdir'];
        } else {
            throw $e;
        }
    }
}

clearstatcache();

if (function_exists('opcache_reset')) {
    opcache_reset();
}

core_plugin_manager::reset_caches();

if (!empty($man)) {
    cli_heading('Some plugin folders must be deleted manually');
    foreach ($man as $dir) {
        cli_writeln('rm -rf '.$dir);
   }
}
