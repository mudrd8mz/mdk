#!/bin/bash

set -e

AMOSCLI=/home/mudrd8mz/www/html/langmoodleorg/local/amos/cli
DIRROOT=$(mdk info -v path)
TMPDIR=tmp

cd ${DIRROOT}/
mkdir -p ${TMPDIR}
${AMOSCLI}/enfix-symlinks.sh ${DIRROOT} ${TMPDIR}
