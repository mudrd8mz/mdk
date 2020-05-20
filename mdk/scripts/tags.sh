#!/bin/bash
#
# Generates the files needed for the ctags and cscope support
#
# by David Mudrak <david@moodle.com>

P=$(mdk info -v path)

if [[ $P == "None" ]]; then
    echo >&2 "Unexpected path returned by mdk info. Aborting."
    exit 2
fi

if [[ ! -d "$P" ]]; then
    echo "Invalid path returned by mdk info. This is weird. Aborting."
    exit 3
fi

hash cscope &> /dev/null

if [ $? -eq 1 ]; then
    echo >&2 "Cscope not found."
    exit 1
else
    echo "Generating the cscope tags ..."
    cd "$P"
    find $P -path $P'/moodledata*' -prune -o -type f -name '*.php' -exec echo \"{}\" \; > cscope.files
    cscope -b
fi


hash ctags &> /dev/null
if [ $? -eq 1 ]; then
    echo >&2 "Ctags not found."
    exit 1
else
    echo "Generating the ctags ..."
    cd "$P"
    ctags -R --fields=+aimS --php-kinds=cdfint --languages=php --extras=+q --tag-relative=yes --output-format=e-ctags \
        --exclude=".git" --exclude="vendor" --exclude="node_modules" --exclude="composer.phar" --totals=yes
fi
