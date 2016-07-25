#!/bin/bash
#
# Initialize the cscope files

P=$(mdk info -v path)

if [[ $P == "None" ]]; then
    echo >&2 "Unexpected path returned by mdk info. Aborting."
    exit 2
fi

if [[ ! -d "$P" ]]; then
    echo "Invalid path returned by mdk info. This is weird. Aborting."
    exit 3
fi

echo "Generating test courses ..."

cd "$P"
sudo -u apache php admin/tool/generator/cli/maketestcourse.php --shortname="C001-S" --size=S
sudo -u apache php admin/tool/generator/cli/maketestcourse.php --shortname="C002-L" --size=L
