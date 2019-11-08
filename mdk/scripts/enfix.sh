#!/bin/bash

function yesno {
    read -p "${1:-Continue?} [y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
}

if [[ -f "tmp" || -f "enfix.log" ]]; then
    echo "Traces of the previous execution found. Clean up them first please. Hint:"
    echo " rm -rf ./tmp enfix.log"
    exit 0
fi

yesno "Run enfix-symlinks to prepare the symlinks?"
mdk run enfix-symlinks.sh

yesno "Run enfix-merge to update the string files?"
mdk run enfix-merge.sh

yesno "Display the diff"
git diff

yesno "Grep for errors in the enfix.log"
grep --before-context=1 -E '\[ERR\]|\[WRN\]' enfix.log

yesno "Searching for syntax errors"
for f in ./tmp/*.php; do php -l $f; done | grep -v '^No syntax errors detected in'

yesno "Commit the changes"
MDL=$(git symbolic-ref --short HEAD | cut -d- -f 1-2)
git commit -a --author="Helen Foster <helen@moodle.org>" -e -m "${MDL} lang: Import fixed English strings (en_fix)"

yesno "Run enfix-check to auto-detect Behat regressions?"
mdk run enfix-check.sh

yesno "Push changes to the Github and the tracker?"
mdk push -t
