#!/bin/sh

if [ -z "$2" ]; then
    echo "Usage: $0 <clair-url> <registry> [user:password]" >&2
    exit 1
fi

clair_url=$1
registry=$2
auth=$3

[ ! -z "$auth" ] && auth="-u '$auth'"

alias curl="curl -s $auth"

curl https://$registry/v2/_catalog | jq -r '.repositories[]' | sort | uniq | while read name; do
    team=$(echo $name | cut -d'/' -f1)
    artifact=$(echo $name | cut -d'/' -f2)

    version=$(pierone latest --url https://$registry $team $artifact)

    echo "[$team/$artifact:$version]"
    ./index-image.sh $clair_url $registry $team $artifact $version $auth
done
