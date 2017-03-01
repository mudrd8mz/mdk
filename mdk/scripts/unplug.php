<?php

// unplug.php - uninstalls all additional plugins from this moodle
//
// This version has very dump way of dealing with dependencies but it can help
// a lot as-is during plugins reviews.

define('CLI_SCRIPT', true);

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
        array_push($del, $plugin->component);
    } else {
        foreach ($pluginman->other_plugins_that_require($plugin->component) as $dependency) {
            if ($pluginman->can_uninstall_plugin($dependency)) {
                array_unshift($del, $dependency);
            } else {
                die('Unable to uninstall '.$dependency);
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

// And finally attempt to uninstall and delete the plugins.
$man = [];
foreach ($del as $plugin) {
    cli_writeln('Uninstalling '.$plugin);
	$progress = new progress_trace_buffer(new text_progress_trace());
	$pluginman->uninstall_plugin($plugin, $progress);
	$progress->finished();

    try {
        $pluginman->remove_plugin_folder($contribs[$plugin]);
    } catch (moodle_exception $e) {
        if ($e->errorcode === 'err_removing_unremovable_folder') {
            $man[] = $e->a['rootdir'];
        } else {
            throw $e;
        }
    }

	if (function_exists('opcache_reset')) {
		opcache_reset();
	}
}

if (!empty($man)) {
    cli_heading('Some plugin folders must be deleted manually');
    foreach ($man as $dir) {
        cli_writeln('rm -rf '.$dir);
   }
}
