#!/bin/bash

set -e

AMOSCLI="/home/mudrd8mz/www/html/langmoodleorg/local/amos/cli"
ENFIXROOT="/home/mudrd8mz/tmp/export-enfix"
DIRROOT=$(mdk info -v path)
BRANCH=$(php -r 'define("MOODLE_INTERNAL", 1); @require("version.php"); echo $branch;')
TMPDIR=tmp
PHP=/usr/bin/php
LOG=enfix.log

cd ${DIRROOT}/
${PHP} ${AMOSCLI}/enfix-merge.php --symlinksdir=${DIRROOT}/${TMPDIR} --enfixdir=${ENFIXROOT}/${BRANCH} | tee ${LOG}
