#!/bin/bash -e
#
# Execute the 'Precheck remote branch' CI job against the current branch
# in our public Git repository.
#

# Where the branch is supposed to be available (this must be a public
# repository so that the Jenkins can fetch from it).
CIREMOTE=$(mdk config show repositoryUrl)

# The name of the branch. Assume the current branch is the one to be checked.
CIBRANCH=$(git symbolic-ref -q HEAD)
CIBRANCH=${CIBRANCH##refs/heads/}

if [ -z "$CIBRANCH" ]; then
    echo "error: unable to determine the current branch"
    exit 1
fi

# The Moodle branch we are based on.
CIINTEGRATETO=$(git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD))
CIINTEGRATETO=${CIINTEGRATETO##origin/}

if [ -z "$CIINTEGRATETO" ]; then
    echo "error: unable to determine the upstream branch (try to rebase)"
    exit 1
fi

# Attempt to guess the tracker issue number from the last commit message.
CIISSUE=$(git show -s --format=%s HEAD)
CIISSUE=${CIISSUE%% *}

# Ask for the confirmation.
echo
echo "Repository:   $CIREMOTE"
echo "Branch:       $CIBRANCH"
echo "Integrate to: $CIINTEGRATETO"
echo "Issue:        $CIISSUE"
echo

read -p "Perform the CI precheck with these parameters? [y/n]" -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit
fi

# CI server performing the precheck.
CIHOST="http://integration.moodle.org"
#CIHOST="http://ci.stronk7.com"
CIJOB="Precheck%20remote%20branch"
CITOKEN="we01allow02tobuild04this05from06remote07scripts08didnt09you10know"

# Ask Jenkins to schedule a new job build.
echo -n "Scheduling a new job build ... "
curlresult=$(curl --silent --request POST --dump-header - --data-urlencode token=${CITOKEN} --data-urlencode remote=${CIREMOTE} --data-urlencode branch=${CIBRANCH} --data-urlencode integrateto=${CIINTEGRATETO} --data-urlencode issue=${CIISSUE} --data-urlencode filter=true ${CIHOST}/job/${CIJOB}/buildWithParameters)

# The successful queueing will result in 201 status code
# with Location HTTP header pointing the URL of the item in the queue.
if [[ $(echo "$curlresult" | head -n 1 | tr -d '\n\r') != "HTTP/1.1 201 Created" ]]; then
    echo "Unexpected cURL result:"
    echo "-----------------------"
    echo "$curlresult"
    echo "-----------------------"
    exit 1;
fi

# Get the URL of the queue item.
location=$(echo "$curlresult" | grep '^Location: ' | cut -c 11- | tr -d '\n\r')
echo "OK [${location}api/xml]"

# Poll the queue item to track the status of the queued task.
echo -n "Waiting for the build start "
while true; do
    echo -n .
    sleep 5
    curlresult=$(curl --silent --include --data-urlencode xpath='/leftItem/executable[last()]/url' ${location}api/xml)
    if [[ $(echo "$curlresult" | head -n 1 | tr -d '\n\r') == "HTTP/1.1 200 OK" ]]; then
        break
    fi
done

buildurl=$(echo "$curlresult" | grep '^<url>' | tr -d '\n\r' | cut -c 6- | rev | cut -c 7- | rev)
echo "OK [${buildurl}]"
echo "-----------------------"

# Bytes offset of the raw log file
textsize=0

while true; do
    headers=$(curl --dump-header /dev/stderr --data start=${textsize} {$buildurl}logText/progressiveText 2>&1 >/dev/tty)
    textsize=$(echo "${headers}" | grep 'X-Text-Size: ' | tr -d '\n\r')
    textsize=${textsize##X-Text-Size: }
    moredata=$(echo "${headers}" | grep 'X-More-Data: true' | tr -d '\n\r')

    if [ -z "$moredata" ]; then
        break
    fi

    sleep 5
done
echo "-----------------------"
echo
echo "Status:           ${buildurl}"
echo "Console Output:   ${buildurl}console"
echo "Parameters:       ${buildurl}parameters"
echo "Build Artifacts:  ${buildurl}artifact/work/"
echo "smurf.html:       ${buildurl}artifact/work/smurf.html"
