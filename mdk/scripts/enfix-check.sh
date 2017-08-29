#!/bin/bash

# Find uses in .feature files corresponding to deleted strings for a given commit.
# Far from ideal for multiline strings, but does its work for 1 line ones.

# Usage: within a git repo: check_lang_string_uses.sh <commit>. Look for ERROR @ output.

commit=${1:-HEAD}
count=0
retcode=0
pushd "$(git rev-parse --show-toplevel)" > /dev/null
echo "Checking commit ${commit}"

while read -r line; do
    if [[ ${line} =~ ^-\$string\[.*=\ *\'(.+)\'\; ]]; then
        ((count++))
        search=${BASH_REMATCH[1]}

        # normalize placeholders
        search=$(echo "${search}" | sed 's/{[^}]*}/.*/g')

        # normalize backslashes
        search=$(echo "${search}" | sed 's/\\//g')

        # get rid of tags
        search=$(echo "${search}" | sed 's/<[^>]*>//g')

        while read -r error; do
            echo "ERROR: Commit removes '${search}' still used in '${error}'"
            retcode=1
        done < <(find . -name "*.feature" | xargs grep "${search}")
    fi
done < <(git show ${commit})

popd > /dev/null

echo "${count} strings processed"

if [[ ${retcode} = 0 ]]; then
    echo "Seems ok"
fi

exit ${retcode}