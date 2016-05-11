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

    echo -n "$team/$artifact ($version):  "

    # a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4 is the 0-byte layer of only metadata, no need to look at it

    # try v1
    top_layer=$(curl "https://$registry/v2/$team/$artifact/manifests/$version" | jq -r '.fsLayers[].blobSum' 2>/dev/null | grep -v 'a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4' | head -n 1)
    # try v2
    [ -z "$top_layer" ] && top_layer=$(curl "https://$registry/v2/$team/$artifact/manifests/$version" | jq -r '.layers[].digest' 2>/dev/null | grep -v 'a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4' | tail -n 1)

    if [ -z "$top_layer" ]; then
        # this is too old and doesn't even provide the "new" Docker manifests; assume that this is vulnerable if its that old
        echo "VULNERABLE*"
        continue
    fi

    fixes=$(curl "$clair_url/v1/layers/$top_layer?vulnerabilities" | jq -c '.Layer.Features[]?.Vulnerabilities[]?.FixedBy?' | grep -v "null")
    if [ -z "$fixes" ]; then
        echo "ok"
    else
        echo "VULNERABLE"
    fi
done
