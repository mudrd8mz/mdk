#!/bin/bash

set -e

AMOSCLI="/home/mudrd8mz/www/html/langmoodleorg/local/amos/cli"
ENFIXROOT="/home/mudrd8mz/tmp/export-enfix"
DIRROOT=$(mdk info -v path)
RELEASE=$(mdk info -v release)
TMPDIR=tmp
PHP=/usr/bin/php
LOG=enfix.log

cd ${DIRROOT}/
${PHP} ${AMOSCLI}/enfix-merge.php --symlinksdir=${DIRROOT}/${TMPDIR} --enfixdir=${ENFIXROOT}/${RELEASE:0:3} | tee ${LOG}
